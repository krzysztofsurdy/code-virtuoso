# Database Optimization

## Contents

- [Query optimization](#query-optimization)
- [N+1 query detection and prevention](#n1-query-detection-and-prevention)
- [Connection pooling](#connection-pooling)
- [Read replicas and query routing](#read-replicas-and-query-routing)
- [Batch operations](#batch-operations)

## Query optimization

### Using explain plans

Every database can show how it executes a query. Check the explain plan before optimizing: it shows whether indexes are used, how tables are joined, and where time is spent.

**Key things to look for in explain output:**
- **Full table scans** on large tables (sequential scan where an index scan is expected)
- **Sort operations** that spill to disk instead of using an index
- **Nested loops** with high row counts on the inner table
- **Estimated vs actual row counts**: large gaps indicate stale statistics

### Index strategies

| Index type | Purpose | Example |
|---|---|---|
| **Single-column** | Speed up queries filtering on one column | Index on `email` for user lookup |
| **Composite** | Match multi-column filters following the leftmost prefix rule | Index on `(tenant_id, created_at)` for tenant-scoped date ranges |
| **Covering** | Include all columns the query needs, so no table lookup is required | Index on `(status, created_at) INCLUDE (total)` for dashboard queries |
| **Partial/Filtered** | Index only rows matching a condition, reducing index size | Index on `status` WHERE `status = 'pending'` for queue processing |
| **Full-text** | Support text search queries | Full-text index on `title, description` for search features |

**Index maintenance rules:**
- Drop indexes that no query uses, since they slow writes and waste storage
- Rebuild fragmented indexes periodically in high-churn tables
- Avoid indexing columns with low cardinality (e.g., boolean flags) unless combined with selective columns

---

## N+1 query detection and prevention

### The problem

The application fetches a list, then queries each item individually. Instead of one or two queries, it issues N+1.

```
-- 1 query to fetch orders
SELECT * FROM orders WHERE user_id = 42;
-- N queries to fetch each order's items (one per order)
SELECT * FROM order_items WHERE order_id = 101;
SELECT * FROM order_items WHERE order_id = 102;
SELECT * FROM order_items WHERE order_id = 103;
... (repeated for every order)
```

### Prevention: eager loading

Fetch related data up front in a single query or a few queries.

**PHP - Doctrine eager loading:**
```php
// N+1: lazy loading triggers a query per order
$orders = $orderRepository->findBy(['user' => $user]);
foreach ($orders as $order) {
    $order->getItems(); // triggers SELECT for each order
}

// Fixed: explicit JOIN fetch
$query = $em->createQuery(
    'SELECT o, i FROM App\Entity\Order o JOIN o.items i WHERE o.user = :user'
);
$query->setParameter('user', $user);
$orders = $query->getResult();
```

**Python - SQLAlchemy joinedload:**
```python
# N+1: accessing items triggers lazy load per order
orders = session.query(Order).filter_by(user_id=42).all()
for order in orders:
    print(order.items)  # triggers query per order

# Fixed: eager load with joinedload
from sqlalchemy.orm import joinedload

orders = (
    session.query(Order)
    .options(joinedload(Order.items))
    .filter_by(user_id=42)
    .all()
)
```

**TypeScript - TypeORM relations:**
```typescript
// N+1: accessing items triggers lazy load
const orders = await orderRepo.find({ where: { userId: 42 } });
for (const order of orders) {
  const items = await order.items; // query per order
}

// Fixed: eager load with relations
const orders = await orderRepo.find({
  where: { userId: 42 },
  relations: ["items"],
});
```

**Java - JPA EntityGraph:**
```java
// N+1: default lazy fetch triggers query per order
List<Order> orders = orderRepository.findByUserId(42L);
orders.forEach(o -> o.getItems().size()); // N queries

// Fixed: EntityGraph to fetch items eagerly
@EntityGraph(attributePaths = {"items"})
List<Order> findWithItemsByUserId(Long userId);
```

### Prevention: batch loading (DataLoader pattern)

Collect all IDs needed during a request, then fetch all related records in a single query. This is especially useful in GraphQL resolvers.

**TypeScript - DataLoader:**
```typescript
const itemLoader = new DataLoader<number, OrderItem[]>(async (orderIds) => {
  const items = await itemRepo.find({
    where: { orderId: In([...orderIds]) },
  });
  const grouped = groupBy(items, "orderId");
  return orderIds.map((id) => grouped[id] ?? []);
});

// Each resolve call is batched
const items = await itemLoader.load(order.id);
```

**Python - batch loading function:**
```python
def load_items_for_orders(order_ids: list[int]) -> dict[int, list[OrderItem]]:
    items = OrderItem.query.filter(OrderItem.order_id.in_(order_ids)).all()
    grouped: dict[int, list[OrderItem]] = {}
    for item in items:
        grouped.setdefault(item.order_id, []).append(item)
    return {oid: grouped.get(oid, []) for oid in order_ids}
```

---

## Connection pooling

### Why pooling matters

Creating a database connection involves a TCP handshake, TLS negotiation, and authentication. This can take 20-100ms per connection. A pool keeps connections open and lends them to requests on demand.

### Configuration guidelines

| Parameter | Guidance |
|---|---|
| **Minimum pool size** | Set to the baseline concurrency so connections are ready immediately |
| **Maximum pool size** | Cap at what the database can handle; a common starting point is `(2 * CPU cores) + disk spindles` |
| **Idle timeout** | Reclaim connections idle for too long (e.g., 10 minutes) |
| **Connection max lifetime** | Rotate connections periodically to pick up DNS changes and server restarts |
| **Validation on borrow** | Test connection health before handing it to the application |

**PHP:** Use `PDO::ATTR_PERSISTENT => true` for persistent connections, or an external pooler like PgBouncer for long-running workers.

**Python - SQLAlchemy:**
```python
engine = create_engine(
    "postgresql://user:pass@host/db",
    pool_size=10, max_overflow=20,
    pool_timeout=30, pool_recycle=1800, pool_pre_ping=True,
)
```

**Java:** HikariCP: set `maximumPoolSize`, `minimumIdle`, `idleTimeout`, `maxLifetime`, and `connectionTimeout`.

**TypeScript - pg pool:**
```typescript
const pool = new Pool({ max: 20, idleTimeoutMillis: 600000, connectionTimeoutMillis: 30000 });
const result = await pool.query("SELECT * FROM users WHERE id = $1", [userId]);
```

---

## Read replicas and query routing

For read-heavy workloads, route read queries to replicas and writes to the primary.

**Routing rules:**
- All INSERT, UPDATE, DELETE go to the primary
- SELECT queries go to a replica by default
- Reads that must see the latest write (read-your-writes consistency) go to the primary
- Replication lag monitoring determines whether a replica is safe to query

**PHP - Doctrine primary/replica configuration:**
```php
'primary' => ['url' => 'postgresql://primary-host/db'],
'replica' => [
    'replica1' => ['url' => 'postgresql://replica1-host/db'],
    'replica2' => ['url' => 'postgresql://replica2-host/db'],
],
'wrapperClass' => PrimaryReadReplicaConnection::class,
```

---

## Batch operations

### Insert batching

Instead of inserting rows one at a time, batch them.

**PHP - Doctrine batch insert (flush every N entities):**
```php
foreach ($records as $i => $data) {
    $em->persist(new Product($data['name'], $data['price']));
    if (($i + 1) % 100 === 0) { $em->flush(); $em->clear(); }
}
$em->flush();
```

**Python:** `cursor.executemany("INSERT INTO products (name, price) VALUES (%s, %s)", rows)`. **TypeScript:** `queryBuilder.insert().into(Product).values(records).execute()`. **Java:** `PreparedStatement.addBatch()` in a loop, then `executeBatch()`.

### Update batching

Use CASE expressions or temp tables for bulk updates instead of updating rows one at a time.

```sql
UPDATE products
SET price = CASE id
    WHEN 1 THEN 19.99
    WHEN 2 THEN 29.99
    WHEN 3 THEN 39.99
END
WHERE id IN (1, 2, 3);
```

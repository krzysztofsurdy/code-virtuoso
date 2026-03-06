# Indexing Strategies

## Index Types in Detail

### B-tree

The default index type in most relational databases. Stores keys in a balanced tree structure, enabling efficient equality and range lookups.

```sql
-- Supports: =, <, >, <=, >=, BETWEEN, IN, IS NULL, ORDER BY
CREATE INDEX idx_orders_created_at ON orders (created_at);

-- Range query uses B-tree efficiently
SELECT * FROM orders WHERE created_at BETWEEN '2025-01-01' AND '2025-03-31';
```

Use B-tree for general-purpose indexing. It handles equality, range, sorting, and prefix matching on text columns.

### Hash

Optimized exclusively for equality comparisons. Faster than B-tree for exact lookups but supports nothing else.

```sql
-- PostgreSQL hash index
CREATE INDEX idx_sessions_token ON sessions USING HASH (token);

-- Only supports exact equality
SELECT * FROM sessions WHERE token = 'abc123';
```

Limited use cases. B-tree handles equality nearly as well and also supports ranges. Hash indexes do not support ordering or range scans.

### GiST (Generalized Search Tree)

A framework for building balanced tree indexes over non-linear data types. Supports spatial data, range types, and nearest-neighbor queries.

```sql
-- Spatial index for PostGIS geometry columns
CREATE INDEX idx_locations_geom ON locations USING GIST (geom);

-- Find locations within 5km of a point
SELECT * FROM locations
WHERE ST_DWithin(geom, ST_MakePoint(-73.9857, 40.7484)::geography, 5000);

-- Range type indexing
CREATE INDEX idx_reservations_period ON reservations USING GIST (tsrange(start_at, end_at));
```

GiST indexes are lossy for some data types -- the database may need to recheck the actual row to confirm a match.

### GIN (Generalized Inverted Index)

Designed for values that contain multiple elements -- arrays, JSONB, full-text search vectors.

```sql
-- Full-text search index
CREATE INDEX idx_articles_search ON articles USING GIN (to_tsvector('english', title || ' ' || body));

SELECT * FROM articles
WHERE to_tsvector('english', title || ' ' || body) @@ to_tsquery('database & design');

-- JSONB containment index
CREATE INDEX idx_products_attrs ON products USING GIN (attributes);

SELECT * FROM products WHERE attributes @> '{"color": "red", "size": "L"}';

-- Array element index
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);

SELECT * FROM posts WHERE tags @> ARRAY['postgresql'];
```

GIN indexes are slower to build and update than B-tree but provide fast lookups for multi-valued data. Best for read-heavy workloads on complex data types.

### BRIN (Block Range Index)

Stores summary information (min/max) for ranges of physical table blocks. Extremely compact -- orders of magnitude smaller than B-tree for large tables.

```sql
-- Ideal for append-only tables with naturally ordered data
CREATE INDEX idx_events_created_at ON events USING BRIN (created_at);
```

BRIN works well only when the physical order of rows correlates with the indexed column values. If rows are inserted out of order or heavily updated, BRIN becomes ineffective.

---

## Composite Index Design

### Column Order Matters

```sql
-- Index on (status, created_at)
CREATE INDEX idx_orders_status_created ON orders (status, created_at);

-- These queries USE the index:
SELECT * FROM orders WHERE status = 'pending';                           -- uses leftmost prefix
SELECT * FROM orders WHERE status = 'pending' AND created_at > '2025-01-01'; -- uses both columns
SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at;       -- uses index for filter + sort

-- This query CANNOT use the index:
SELECT * FROM orders WHERE created_at > '2025-01-01';  -- skips the leftmost column
```

### Equality Before Range

Place columns used with `=` before columns used with `>`, `<`, or `BETWEEN`:

```sql
-- Good: equality column first, range column second
CREATE INDEX idx_orders_tenant_date ON orders (tenant_id, created_at);

-- Supports the common query:
SELECT * FROM orders WHERE tenant_id = 5 AND created_at >= '2025-01-01';
```

---

## Covering Indexes

A covering index includes all columns a query needs, so the database reads only the index without touching the table (an "index-only scan").

```sql
-- PostgreSQL: INCLUDE adds non-key columns to the index leaf pages
CREATE INDEX idx_orders_status_covering
ON orders (status, created_at)
INCLUDE (total_amount, customer_id);

-- This query is satisfied entirely from the index
SELECT total_amount, customer_id
FROM orders
WHERE status = 'shipped' AND created_at > '2025-01-01';
```

Covering indexes trade extra index storage for eliminated table lookups. Most beneficial for frequently-run queries on large tables where the table itself is much wider than the index.

---

## Partial Indexes

Index only the rows that matter, reducing index size and write overhead.

```sql
-- Only index pending orders (small subset of a large table)
CREATE INDEX idx_orders_pending ON orders (created_at) WHERE status = 'pending';

-- Only index active users
CREATE INDEX idx_users_active_email ON users (email) WHERE deleted_at IS NULL;

-- Unique constraint for active records only (allows duplicate emails among soft-deleted)
CREATE UNIQUE INDEX uq_users_email_active ON users (email) WHERE deleted_at IS NULL;
```

Partial indexes are powerful for queue-like patterns, soft-delete tables, and any scenario where queries consistently filter on a fixed condition.

---

## Reading EXPLAIN Output

### PostgreSQL EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT o.id, o.total_amount, c.name
FROM orders o
JOIN customers c ON c.id = o.customer_id
WHERE o.status = 'pending' AND o.created_at > '2025-01-01';
```

**Key fields to examine:**

| Field | What It Tells You |
|---|---|
| **Seq Scan** | Full table scan -- often means a missing or unused index |
| **Index Scan** | Index used to find rows, then table accessed for remaining columns |
| **Index Only Scan** | All data served from the index -- the best case for covered queries |
| **Bitmap Index Scan** | Multiple index entries collected, then table pages read in bulk -- common with OR conditions or low-selectivity indexes |
| **Nested Loop** | For each row from the outer table, scans the inner table -- fast for small inner sets, slow for large ones |
| **Hash Join** | Builds a hash table from one side, probes with the other -- good for large unsorted joins |
| **Sort** | Explicit sort step -- check if it spills to disk (`Sort Method: external merge`) |
| **actual time** | Real execution time in milliseconds -- compare with the estimate |
| **rows** | Estimated vs actual row count -- large discrepancies mean stale statistics |

### MySQL EXPLAIN

```sql
EXPLAIN SELECT * FROM orders WHERE status = 'pending' AND created_at > '2025-01-01';
```

**Key columns:**

| Column | What to Check |
|---|---|
| **type** | `ALL` = full scan (bad), `ref` = index lookup (good), `range` = index range scan (good) |
| **key** | Which index is actually used (NULL means no index) |
| **rows** | Estimated rows examined -- lower is better |
| **Extra** | `Using index` = covering index, `Using filesort` = extra sort step, `Using temporary` = temp table created |

---

## Index Anti-Patterns

| Anti-Pattern | Why It Hurts | What to Do Instead |
|---|---|---|
| **Indexing every column** | Slows writes, wastes storage, confuses the query planner | Index only columns used in WHERE, JOIN, ORDER BY of actual queries |
| **Redundant indexes** | `(a)` is redundant when `(a, b)` exists | Audit indexes periodically and drop subsets |
| **Functions on indexed columns** | `WHERE UPPER(email) = 'FOO'` bypasses the index on `email` | Create an expression index: `CREATE INDEX ON users (UPPER(email))` |
| **Implicit type casts** | `WHERE varchar_col = 123` forces a cast, skipping the index | Match types in queries to column types |
| **Over-indexing low-cardinality columns** | Boolean or status columns alone have poor selectivity | Combine with selective columns in a composite index, or use partial indexes |
| **Never analyzing tables** | Stale statistics lead the planner to choose bad plans | Run ANALYZE regularly, especially after bulk loads |
| **Ignoring index bloat** | Dead tuples inflate the index without contributing to lookups | REINDEX periodically on high-churn tables (or use pg_repack) |

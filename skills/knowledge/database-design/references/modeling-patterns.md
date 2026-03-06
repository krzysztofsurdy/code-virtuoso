# Modeling Patterns

## Polymorphic Associations

When different entity types share a common relationship, there are three inheritance mapping strategies. Each trades query simplicity against schema cleanliness.

### Single Table Inheritance (STI)

All subtypes share one table. A discriminator column identifies the type. Unused columns for other subtypes are NULL.

```sql
CREATE TABLE payments (
    id BIGINT PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    card_last_four CHAR(4),      -- credit card only
    card_brand VARCHAR(20),       -- credit card only
    bank_name VARCHAR(100),       -- bank transfer only
    paypal_email VARCHAR(255),    -- paypal only
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

**PHP/Doctrine:**
```php
#[Entity]
#[InheritanceType('SINGLE_TABLE')]
#[DiscriminatorColumn(name: 'type', type: 'string')]
#[DiscriminatorMap(['credit_card' => CreditCardPayment::class, 'bank_transfer' => BankTransferPayment::class])]
abstract class Payment { /* shared fields */ }
```

**Python/SQLAlchemy:**
```python
class Payment(Base):
    __tablename__ = "payments"
    id = Column(BigInteger, primary_key=True)
    type = Column(String(20), nullable=False)
    amount = Column(Numeric(10, 2), nullable=False)
    __mapper_args__ = {"polymorphic_on": type, "polymorphic_identity": "payment"}

class CreditCardPayment(Payment):
    card_last_four = Column(String(4))
    __mapper_args__ = {"polymorphic_identity": "credit_card"}
```

**Best for:** Few subtypes with mostly shared columns. Simple queries, no JOINs needed.
**Avoid when:** Subtypes diverge significantly -- the table accumulates many nullable columns.

### Class Table Inheritance (CTI)

A shared base table holds common columns. Each subtype has its own table with a foreign key to the base.

```sql
CREATE TABLE payments (id BIGINT PRIMARY KEY, amount DECIMAL(10,2) NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE credit_card_payments (id BIGINT PRIMARY KEY REFERENCES payments(id), card_last_four CHAR(4) NOT NULL);
CREATE TABLE bank_transfer_payments (id BIGINT PRIMARY KEY REFERENCES payments(id), bank_name VARCHAR(100) NOT NULL);
```

**Java/JPA:**
```java
@Entity @Inheritance(strategy = InheritanceType.JOINED)
public abstract class Payment { @Id @GeneratedValue private Long id; private BigDecimal amount; }

@Entity @Table(name = "credit_card_payments")
public class CreditCardPayment extends Payment { private String cardLastFour; }
```

**Best for:** Subtypes with many unique columns. Enforces NOT NULL on subtype-specific fields.
**Avoid when:** Queries frequently need all payment types at once -- requires JOINs across subtype tables.

### Table Per Type (Concrete Table Inheritance)

Each subtype is a fully independent table with no shared base table. Common columns are duplicated.

**Best for:** Subtypes queried independently, rarely queried together.
**Avoid when:** You need to query across all types or enforce cross-type uniqueness.

---

## Soft Deletes

Soft deletes mark records as deleted without removing them from the database. A `deleted_at` timestamp column distinguishes active from deleted rows.

```sql
ALTER TABLE users ADD COLUMN deleted_at TIMESTAMP NULL;
CREATE INDEX idx_users_active ON users (id) WHERE deleted_at IS NULL;
```

**PHP/Doctrine (custom filter):**
```php
class SoftDeleteFilter extends SQLFilter
{
    public function addFilterConstraint(ClassMetadata $metadata, string $alias): string
    {
        if ($metadata->reflClass->implementsInterface(SoftDeletable::class)) {
            return sprintf('%s.deleted_at IS NULL', $alias);
        }
        return '';
    }
}
```

**Trade-offs:**

| Benefit | Cost |
|---|---|
| Easy undo/restore | Every query must filter on `deleted_at IS NULL` |
| Audit trail of when records were deleted | Unique constraints must account for soft-deleted rows |
| Foreign key relationships remain intact | Storage grows indefinitely without periodic purging |

**Mitigation:** Use database-level default filters (Doctrine filters, SQLAlchemy events, Prisma middleware) so developers cannot accidentally query deleted rows.

---

## Audit Trails

### Dedicated Audit Table

A separate table records every change to audited entities. Each row captures who changed what, when, and what the values were.

```sql
CREATE TABLE audit_log (
    id BIGINT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT NOT NULL,
    action VARCHAR(10) NOT NULL, -- 'INSERT', 'UPDATE', 'DELETE'
    changed_by VARCHAR(100),
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_values JSONB,
    new_values JSONB
);

CREATE INDEX idx_audit_log_record ON audit_log (table_name, record_id);
CREATE INDEX idx_audit_log_time ON audit_log (changed_at);
```

**Considerations:**
- Partition audit tables by time and define a retention policy
- Store both old and new values to reconstruct state at any point
- Record the actor (user ID, API key, system process) alongside every change
- For high-volume systems, write audit events asynchronously via a message queue

---

## Temporal Data

### Valid-Time Tables

Track when a fact is true in the real world, independent of when the database recorded it.

```sql
CREATE TABLE product_prices (
    product_id BIGINT NOT NULL REFERENCES products(id),
    price DECIMAL(10, 2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE, -- NULL means currently valid
    PRIMARY KEY (product_id, valid_from),
    CONSTRAINT no_overlap CHECK (valid_to IS NULL OR valid_to > valid_from)
);

-- Query: what was the price on a specific date?
SELECT price FROM product_prices
WHERE product_id = 42
  AND valid_from <= '2025-06-15'
  AND (valid_to IS NULL OR valid_to > '2025-06-15');
```

### Bitemporal Tables

Combine valid time (when the fact is true) with transaction time (when the database recorded it). This supports both historical queries and rollback/correction scenarios.

```sql
CREATE TABLE employee_salaries (
    employee_id BIGINT NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    valid_from DATE NOT NULL,
    valid_to DATE,
    recorded_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    superseded_at TIMESTAMP, -- NULL means current record
    PRIMARY KEY (employee_id, valid_from, recorded_at)
);
```

**Use cases:** Financial corrections, insurance policy amendments, regulatory compliance where you must answer both "what was true then" and "what did we believe at that time."

---

## Self-Referential Relationships

| Pattern | How It Works | Trade-off |
|---|---|---|
| **Adjacency list** | Each row has `parent_id` referencing the same table | Simple inserts/moves; subtree queries need recursive CTEs |
| **Materialized path** | Store full path as string (`/1/5/12/`) | Fast subtree queries via LIKE; moving nodes requires updating all descendants |
| **Closure table** | Separate table with every ancestor-descendant pair and depth | Fast reads for any tree query; more storage and write overhead |

```sql
-- Adjacency list
CREATE TABLE categories (id BIGINT PRIMARY KEY, name VARCHAR(100) NOT NULL, parent_id BIGINT REFERENCES categories(id));

-- Closure table
CREATE TABLE category_tree (ancestor_id BIGINT REFERENCES categories(id), descendant_id BIGINT REFERENCES categories(id), depth INT NOT NULL, PRIMARY KEY (ancestor_id, descendant_id));
```

---

## JSON Columns

Modern relational databases (PostgreSQL JSONB, MySQL JSON) support structured data inside a column.

**When JSON columns are appropriate:**
- Schema-less metadata that varies per row (user preferences, feature flags)
- Storing external API payloads that the application does not query internally
- Attributes that belong to the entity but have no relational meaning

**When JSON columns are harmful:**
- Data you JOIN on, filter by frequently, or need referential integrity for
- Replacing proper normalization to avoid creating tables
- Deeply nested structures that become difficult to query and validate

```sql
ALTER TABLE products ADD COLUMN metadata JSONB DEFAULT '{}';
CREATE INDEX idx_products_metadata ON products USING GIN (metadata);
SELECT * FROM products WHERE metadata @> '{"color": "red"}';
```

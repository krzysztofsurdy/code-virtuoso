# Data Modeling Guide

Practical guidance for designing data models in backend applications using an ORM. Covers entity design, relationships, normalization decisions, and migration patterns.

---

## Entity Design Principles

| Principle | Meaning |
|---|---|
| Entities represent domain concepts | An entity maps to a real thing in the business domain, not a UI element or API shape |
| Identity matters | Entities have identity (ID). If two objects with the same data are different things, it is an entity |
| Value Objects for the rest | If identity does not matter and equality is based on values, use a Value Object (embedded/composite type) |
| Encapsulate invariants | The entity enforces its own business rules. Invalid state should be impossible to construct |
| Slim entities | Entities hold state and enforce invariants. Complex business logic belongs in services |

---

## Entity Structure

### Standard Entity Template (Pseudocode)

```
class Product:
    id: UUID            # Primary key
    name: string(255)
    sku: string(64)     # Unique
    priceInCents: integer
    status: string(20)
    createdAt: datetime  # Immutable
    updatedAt: datetime

    constructor(name, sku, priceInCents):
        this.id = UUID.v7()
        this.name = name
        this.sku = sku
        this.priceInCents = priceInCents
        this.status = "draft"
        this.createdAt = now()
        this.updatedAt = now()

    indexes:
        - idx_product_status on (status)
    unique_constraints:
        - uniq_product_sku on (sku)
```

### Key Decisions

| Decision | Guidance |
|---|---|
| **ID strategy** | Use UUID v7 for new projects (sortable, no sequence contention). Use auto-increment if the project already uses it. |
| **Timestamps** | Use immutable datetime types for all date/time fields. Add `createdAt` and `updatedAt` to all entities. |
| **Money** | Store as integer cents. Never use float for money. |
| **Status fields** | Use language-native enums backed by strings for type safety. Store as string column. |
| **Soft delete** | Prefer a `deletedAt` nullable datetime over boolean `isDeleted`. Enables "when was it deleted" queries. |

---

## Relationships

### Relationship Types

| Type | ORM Mapping | When to Use |
|---|---|---|
| Many-to-One | Foreign key on the child table | Child references parent (Order has many LineItems, each LineItem references one Order) |
| One-to-Many | Inverse side of Many-to-One | Parent holds collection of children. Always the inverse side of Many-to-One. |
| Many-to-Many | Join table | Avoid where possible. Use a join entity with its own attributes instead. |
| One-to-One | Shared primary key or foreign key | Rare. Consider embedding or merging into one entity. |

### Relationship Configuration (Pseudocode)

```
# Owning side (LineItem)
class LineItem:
    order: ManyToOne(Order, inverse="lineItems", nullable=false, onDelete="CASCADE")

# Inverse side (Order)
class Order:
    lineItems: OneToMany(LineItem, mapped_by="order", cascade=["persist", "remove"])
```

### Relationship Checklist

| # | Check |
|---|---|
| 1 | Owning side is on the "many" side of the relationship |
| 2 | Nullability is explicitly set on foreign key columns (do not rely on defaults) |
| 3 | On-delete behavior is specified (CASCADE, SET NULL, or RESTRICT) |
| 4 | Cascade operations are set deliberately, not copied from examples |
| 5 | Eager loading is used only when the relationship is always needed |
| 6 | Bidirectional relationships have both sides configured consistently |
| 7 | Collections are initialized in the constructor |

### Cascade Operations

| Cascade | Effect | Use When |
|---|---|---|
| `persist` | Persisting the parent persists new children automatically | Parent and children are always created together |
| `remove` | Removing the parent removes children | Children have no meaning without the parent |
| None | Each entity is persisted/removed independently | Entities have independent lifecycles |

**Rule of thumb**: Only use cascade when the child entity has no meaning without the parent. When in doubt, manage persistence explicitly.

---

## Embeddables (Value Objects)

Use embedded/composite types for groups of fields that belong together conceptually but do not need their own identity.

```
# Value Object definition (pseudocode)
class Address:
    street: string(255)
    city: string(100)
    postalCode: string(10)
    countryCode: string(2)

# Usage in entity
class Customer:
    billingAddress: embedded(Address)
```

### When to Use Embeddables

| Use Embeddable | Use Separate Entity |
|---|---|
| No independent identity needed | Needs its own ID and lifecycle |
| Always loaded with the parent | May be loaded independently |
| 1-5 fields | Many fields or complex relationships |
| Examples: Address, Money, DateRange, Coordinates | Examples: User, Order, Product |

---

## Normalization Decisions

### When to Normalize (Separate Tables)

- Data has its own identity and lifecycle
- Data is referenced by multiple entities
- Data changes independently of the parent
- You need to query or filter on the data independently

### When to Denormalize (Same Table or JSON Column)

- Data is always read and written with the parent
- Data does not need independent querying
- Performance of joins is a concern for high-frequency reads
- Data structure is flexible or varies between records

### JSON Columns

Use JSON columns for semi-structured data that does not need relational querying.

| Appropriate for JSON | Not Appropriate for JSON |
|---|---|
| Configuration blobs | Data you need to filter or sort by |
| Audit trail details | Data referenced by foreign keys |
| Flexible attributes that vary per record | Data with strict schema requirements |
| Import/export metadata | Data that participates in joins |

---

## Indexing Strategy

### Index Decision Guide

| Query Pattern | Index Type |
|---|---|
| `WHERE status = ?` | Single column index |
| `WHERE status = ? AND createdAt > ?` | Composite index (status, createdAt) |
| `WHERE email = ?` (must be unique) | Unique index |
| `ORDER BY createdAt DESC LIMIT 25` | Index on createdAt |
| Full-text search | Full-text index or external search engine |
| `WHERE json_field->>'key' = ?` | Consider extracting to a column instead |

### Indexing Checklist

| # | Check |
|---|---|
| 1 | Every foreign key column has an index |
| 2 | Columns used in WHERE clauses of frequent queries have indexes |
| 3 | Composite indexes match the query column order (leftmost prefix rule) |
| 4 | Unique constraints are defined at the database level, not just application level |
| 5 | Indexes are not created speculatively - each index has a known query pattern |

---

## Migration Patterns

### Safe Migration Workflow

For changes to existing tables with production data:

| Step | Action | Rollback Safe |
|---|---|---|
| 1 | Add new column as nullable (no default required) | Yes - drop column |
| 2 | Deploy code that writes to both old and new columns | Yes - code reads old column |
| 3 | Backfill new column with data from old column | Yes - data still in old column |
| 4 | Deploy code that reads from new column | Yes - old column still populated |
| 5 | Drop old column | No - point of no return |

### Migration Checklist

| # | Check |
|---|---|
| 1 | Migration is generated using the ORM's migration tool, not written by hand |
| 2 | Generated SQL is reviewed before execution |
| 3 | Migration has a rollback/down method that reverses the change (where possible) |
| 4 | Adding a NOT NULL column includes a DEFAULT value or is done in the multi-step pattern above |
| 5 | Renaming a column uses the add/copy/drop pattern, not a direct rename |
| 6 | Dropping a column is the last step after all code references are removed |
| 7 | Large table changes (adding indexes, altering columns) are tested against production-scale data |
| 8 | Migration runs within an acceptable time window for the table size |

### Dangerous Operations

| Operation | Risk | Mitigation |
|---|---|---|
| Adding NOT NULL column without default | Fails if table has existing rows | Add as nullable first, backfill, then alter to NOT NULL |
| Adding index on large table | Locks table during creation | Use `CREATE INDEX CONCURRENTLY` (PostgreSQL) or online DDL |
| Dropping column | Data loss, code may still reference it | Remove all code references first, then drop |
| Renaming table | Breaks all queries referencing old name | Use add-new/migrate-data/drop-old pattern |
| Changing column type | May lose data or precision | Create new column, copy data with conversion, drop old |

---

## Common Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|---|---|---|
| God entity with 30+ fields | Hard to understand, test, and maintain | Split into focused entities or extract embeddables |
| Storing enums as integers | Unreadable in database, brittle if values change | Use string-backed enums |
| Missing unique constraints | Duplicate data creeps in at scale | Define unique constraints at the database level |
| Bidirectional relationships everywhere | Increases coupling between entities | Use unidirectional unless the inverse side is truly needed |
| Cascade remove on everything | Accidental data deletion | Use cascade only when children are meaningless without parent |
| Float for money | Rounding errors in calculations | Integer cents or a Money value object |
| Relying on application-level validation only | Database can still contain invalid data | Enforce constraints at both application and database levels |

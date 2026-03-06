---
name: database-design
description: Database design patterns and data modeling — normalization, indexing strategies, schema evolution, migration patterns, temporal data, audit trails, and partitioning. Use when designing schemas, planning migrations, or optimizing data access patterns.
user-invocable: false
---

# Database Design

Good database design determines the long-term maintainability, performance, and correctness of any data-driven application. Schema decisions made early are expensive to reverse later. Every table, column, index, and constraint should exist for a reason backed by access patterns and business rules.

## Data Modeling Principles

### Start from Access Patterns

Design tables around how the application reads and writes data, not around how entities look in a domain model. Two questions drive every schema decision:

1. **What queries will run most frequently?** -- these determine table structure, indexes, and denormalization choices
2. **What consistency guarantees does the data need?** -- these determine normalization level, constraints, and transaction boundaries

### Entity Relationships

| Relationship | Implementation | When to Use |
|---|---|---|
| **One-to-one** | Foreign key with UNIQUE constraint on the child table | Splitting rarely-accessed columns into a separate table, or enforcing exactly-one semantics |
| **One-to-many** | Foreign key on the child table referencing the parent | Orders to order items, users to addresses |
| **Many-to-many** | Join table with composite primary key | Tags to articles, students to courses |
| **Many-to-many with attributes** | Join table with its own columns beyond the two foreign keys | Enrollment with grade, membership with role |
| **Self-referential** | Foreign key referencing the same table | Org charts, category trees, threaded comments |

### Naming Conventions

Consistent naming prevents confusion across teams and tools:

- **Tables**: plural nouns in snake_case (`order_items`, `user_addresses`)
- **Columns**: singular snake_case describing the value (`created_at`, `total_amount`)
- **Foreign keys**: `<referenced_table_singular>_id` (`user_id`, `order_id`)
- **Indexes**: `idx_<table>_<columns>` (`idx_orders_user_id_created_at`)
- **Constraints**: `chk_<table>_<rule>`, `uq_<table>_<columns>`, `fk_<table>_<referenced>`

---

## Normalization vs Denormalization

### Normal Forms

| Form | Rule | Violation Example |
|---|---|---|
| **1NF** | Every column holds atomic values; no repeating groups | Storing comma-separated tags in a single column |
| **2NF** | Every non-key column depends on the entire primary key | In a composite-key table, a column depending on only part of the key |
| **3NF** | No non-key column depends on another non-key column | Storing both `city` and `zip_code` when zip determines city |
| **BCNF** | Every determinant is a candidate key | A scheduling table where room determines building but room is not a key |

### When to Denormalize

Normalization prevents anomalies but adds JOINs. Denormalize selectively when:

- **Read-heavy workloads** dominate and JOIN cost is measurable in profiling
- **Reporting tables** need pre-aggregated data that would otherwise require expensive queries
- **Caching a computed value** avoids recalculating on every read (e.g., `order_total` stored on the order row)
- **Document-oriented access** retrieves an entire aggregate in one read

**Rules for safe denormalization:**

1. Always keep the normalized source of truth -- denormalized data is a derived cache
2. Define how and when the denormalized copy is updated (trigger, application event, batch job)
3. Monitor for drift between the source and the copy
4. Document why the denormalization exists and what access pattern it serves

---

## Choosing a Database Type

| Type | Strengths | Fits When |
|---|---|---|
| **Relational (PostgreSQL, MySQL)** | ACID transactions, complex queries, mature tooling, JOINs | Structured data with relationships, transactional workloads, most CRUD applications |
| **Document (MongoDB, DynamoDB)** | Flexible schema, nested data, horizontal scaling | Aggregates accessed as a unit, rapidly evolving schemas, per-tenant isolation |
| **Key-value (Redis, Memcached)** | Sub-millisecond reads, simple data model | Session storage, caching, counters, rate limiting |
| **Column-family (Cassandra, ScyllaDB)** | High write throughput, wide rows, linear scaling | Time-series, IoT telemetry, append-heavy workloads |
| **Graph (Neo4j, Neptune)** | Traversal queries, relationship-centric data | Social networks, recommendation engines, fraud detection |
| **Time-series (TimescaleDB, InfluxDB)** | Optimized for time-stamped data, automatic partitioning | Metrics, monitoring, financial tick data |

Polyglot persistence -- using different databases for different parts of the same system -- is valid when access patterns genuinely differ. It is not valid as a way to avoid learning one database well.

---

## Indexing Fundamentals

Indexes accelerate reads at the cost of slower writes and additional storage. Every index must justify its existence through query patterns.

### Index Types

| Type | Structure | Best For |
|---|---|---|
| **B-tree** | Balanced tree, sorted data | Equality and range queries, ORDER BY, most general-purpose indexing |
| **Hash** | Hash table | Exact equality lookups only; no range support |
| **GiST** | Generalized search tree | Spatial data, geometric queries, range types, nearest-neighbor |
| **GIN** | Generalized inverted index | Full-text search, JSONB containment, array membership |
| **BRIN** | Block range index | Large tables with naturally ordered data (timestamps, sequential IDs) |

### Composite Index Design

The order of columns in a composite index matters. The **leftmost prefix rule** means a composite index on `(a, b, c)` supports queries filtering on `(a)`, `(a, b)`, or `(a, b, c)`, but not `(b, c)` alone.

**Column ordering guidelines:**

1. Equality conditions first -- columns compared with `=`
2. Range conditions last -- columns compared with `>`, `<`, `BETWEEN`
3. Most selective column first among equals

### Covering and Partial Indexes

- **Covering index**: includes all columns the query needs, so the database reads only the index. Use `INCLUDE` (PostgreSQL) or just add columns to the index key.
- **Partial index**: indexes only rows matching a condition, reducing size and write overhead. Ideal for querying a small subset of a large table (e.g., `WHERE status = 'pending'`).

See [Indexing Strategies Reference](references/indexing-strategies.md) for detailed index types, EXPLAIN analysis, and anti-patterns.

---

## Schema Evolution

Schema changes are inevitable. The question is whether they break running applications.

### Backward-Compatible Changes (Safe)

- Adding a new nullable column
- Adding a new table
- Adding a new index (may lock briefly on some engines)
- Widening a column type (e.g., `VARCHAR(50)` to `VARCHAR(100)`)

### Breaking Changes (Require Migration Strategy)

- Renaming or removing a column
- Changing a column type in incompatible ways
- Adding a NOT NULL constraint to an existing column with null data
- Splitting or merging tables

### The Expand-Contract Pattern

For breaking changes in production with zero downtime:

1. **Expand** -- add the new structure alongside the old one
2. **Migrate** -- backfill data from old to new, dual-write during transition
3. **Switch** -- update application code to use the new structure
4. **Contract** -- remove the old structure once nothing references it

See [Migration Patterns Reference](references/migration-patterns.md) for zero-downtime strategies, rollback techniques, and multi-tool examples.

---

## Partitioning and Sharding

### Table Partitioning (Single Database)

| Strategy | How It Works | Use Case |
|---|---|---|
| **Range** | Rows split by value ranges (e.g., by month) | Time-series data, log tables, archival |
| **List** | Rows split by discrete values (e.g., by region) | Multi-tenant data, geographic segmentation |
| **Hash** | Rows distributed by hash of a column | Even distribution when no natural range exists |

### Sharding (Multiple Databases)

Sharding distributes data across separate database instances. Use it only after single-instance optimizations (indexing, caching, read replicas) are exhausted.

**Shard key selection criteria:**

- High cardinality -- many distinct values to distribute evenly
- Present in most queries -- avoids scatter-gather across all shards
- Stable -- values that do not change after creation
- Avoid hotspots -- do not shard by a value that concentrates writes (e.g., current date)

---

## Quick Reference: Common Design Mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| No foreign key constraints | Orphaned rows, inconsistent data | Always define foreign keys unless there is a documented reason not to |
| Over-indexing | Slow writes, wasted storage | Index only columns used in WHERE, JOIN, ORDER BY of actual queries |
| Storing computed values without a refresh strategy | Stale data, silent bugs | Define update triggers, events, or batch jobs alongside any denormalization |
| Using ENUM types for values that change | Schema migration for every new value | Use a lookup table with a foreign key instead |
| Storing money as floating-point | Rounding errors | Use DECIMAL/NUMERIC or store as integer cents |
| Missing created_at / updated_at timestamps | No auditability, difficult debugging | Add timestamp columns to every table by default |
| Generic `type` + `type_id` polymorphism everywhere | No referential integrity, complex queries | Evaluate STI, CTI, or separate tables first |

---

## Reference Files

| Reference | Contents |
|---|---|
| [Modeling Patterns](references/modeling-patterns.md) | Polymorphic associations (STI/CTI/TPT), soft deletes, audit trails, temporal data, self-referential trees, JSON columns |
| [Indexing Strategies](references/indexing-strategies.md) | B-tree/hash/GiST/GIN details, composite index design, covering and partial indexes, EXPLAIN analysis, anti-patterns |
| [Migration Patterns](references/migration-patterns.md) | Version-based vs state-based migrations, expand-contract, data migrations, rollback strategies, multi-tool examples |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Optimizing query performance and caching | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for performance optimization patterns |
| Designing domain models and aggregates | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for clean architecture and DDD guidance |
| Building APIs that expose database-backed resources | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design principles |
| Testing database interactions | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies |

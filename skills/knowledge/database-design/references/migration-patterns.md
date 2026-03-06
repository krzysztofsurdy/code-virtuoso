# Migration Patterns

## Migration Approaches

### Version-Based Migrations

Each migration is a numbered script that runs in order. The database tracks which migrations have been applied. New changes are always additive -- you write a new migration file rather than editing an existing one.

**Advantages:** Explicit ordering, deterministic replay, easy to reason about history.
**Tools:** Doctrine Migrations, Alembic, Prisma Migrate, Flyway, Liquibase.

### State-Based Migrations

You declare the desired schema state. The tool compares the current database schema against the desired state and generates the necessary DDL to reconcile them.

**Advantages:** No migration files to manage, schema is always visible as a declaration.
**Tools:** Prisma (schema push), Atlas, Redgate SQL Compare, TypeORM synchronize (development only).

### Choosing Between Them

| Factor | Version-Based | State-Based |
|---|---|---|
| Production safety | Explicit control over every change | Generated DDL needs careful review |
| Team workflows | Each developer creates discrete migration files | Merge conflicts happen in the schema declaration |
| Rollback | Write explicit down migrations | Tool generates reverse DDL (not always safe) |
| Data migrations | Naturally fit alongside schema changes | Require a separate mechanism |

Most production systems use version-based migrations. State-based tools work well for rapid prototyping and development environments.

---

## Zero-Downtime Migrations

### The Expand-Contract Pattern

Split dangerous schema changes into safe, incremental steps. At every point during the process, both old and new application code can run against the database.

**Example: Renaming a column from `name` to `full_name`**

**Step 1 -- Expand (add new column):**
```sql
ALTER TABLE users ADD COLUMN full_name VARCHAR(255);
```

**Step 2 -- Backfill (copy existing data):**
```sql
UPDATE users SET full_name = name WHERE full_name IS NULL;
```

For large tables, batch the backfill to avoid long-running transactions:

```sql
-- Process in batches of 10,000
UPDATE users SET full_name = name
WHERE full_name IS NULL AND id BETWEEN 1 AND 10000;
```

**Step 3 -- Dual-write (application writes to both columns):**

```php
// PHP/Doctrine: write to both columns during transition
$user->setName($value);
$user->setFullName($value);
```

```python
# Python/SQLAlchemy: dual-write in the model
class User(Base):
    def set_name(self, value: str) -> None:
        self.name = value
        self.full_name = value
```

**Step 4 -- Switch (application reads from new column):**
Deploy application code that reads `full_name` instead of `name`.

**Step 5 -- Contract (remove old column):**
```sql
ALTER TABLE users DROP COLUMN name;
```

### Operations That Lock Tables

Some DDL operations acquire locks that block reads or writes. Know which ones are dangerous:

| Operation | PostgreSQL | MySQL |
|---|---|---|
| Add nullable column | No lock | Instant (8.0+) |
| Add column with default | No lock (11+) | Instant (8.0+) |
| Add NOT NULL constraint | ACCESS EXCLUSIVE lock during validation | Table rebuild (use ALGORITHM=INSTANT where possible) |
| Drop column | Brief ACCESS EXCLUSIVE | Table rebuild |
| Add index | `CREATE INDEX CONCURRENTLY` avoids lock | `ALTER TABLE ... ALGORITHM=INPLACE, LOCK=NONE` |
| Change column type | Table rewrite, full lock | Table rebuild |

**Rule:** In production, always use concurrent/online DDL options when available. For operations that require locks, schedule during low-traffic windows or use the expand-contract pattern to avoid them entirely.

---

## Data Migrations vs Schema Migrations

### Schema Migrations

Change the database structure: adding tables, columns, indexes, constraints.

### Data Migrations

Transform existing data to fit a new schema or business rule. These are often the riskier part of a migration.

**Guidelines for data migrations:**

1. **Run separately from schema changes** -- deploy the schema first, then run the data migration
2. **Make them idempotent** -- safe to run multiple times without side effects
3. **Batch large updates** -- avoid locking entire tables with single massive UPDATE statements
4. **Log progress** -- for long-running migrations, record how far you have gotten so you can resume
5. **Test on production-sized data** -- a migration that runs in 2 seconds on dev data may take 4 hours in production

**PHP/Doctrine (batched data migration):**
```php
$batchSize = 1000;
$offset = 0;

do {
    $records = $connection->executeQuery(
        'SELECT id, name FROM users WHERE full_name IS NULL LIMIT ? OFFSET ?',
        [$batchSize, $offset]
    )->fetchAllAssociative();

    foreach ($records as $record) {
        $connection->executeStatement(
            'UPDATE users SET full_name = ? WHERE id = ?',
            [$record['name'], $record['id']]
        );
    }

    $offset += $batchSize;
} while (count($records) === $batchSize);
```

**Python/Alembic (data migration in a revision):**
```python
def upgrade():
    op.execute("""
        UPDATE users
        SET full_name = name
        WHERE full_name IS NULL
    """)

def downgrade():
    op.execute("""
        UPDATE users
        SET name = full_name
        WHERE name IS NULL
    """)
```

---

## Backward Compatibility

### The Two-Version Rule

At any point during a deployment, both the current version and the previous version of the application may be running simultaneously (rolling deploys, canary releases). Every migration must be compatible with at least two application versions.

**What this means in practice:**

- Never rename a column in a single migration -- use expand-contract
- Never add a NOT NULL column without a default -- old code does not know to populate it
- Never remove a column that old code still reads -- deploy the code change first, then remove the column
- Never change a column type in a way that breaks existing queries

### Migration Ordering

```
Deploy sequence for a breaking change:

1. Deploy migration: ADD new column (nullable)
2. Deploy app v2: writes to both old + new columns, reads from old
3. Run data migration: backfill new column
4. Deploy app v3: reads from new column, still writes to both
5. Deploy migration: DROP old column
6. Deploy app v4: remove references to old column
```

---

## Rollback Strategies

### Forward-Only Migrations

Some teams never roll back migrations. Instead, they fix problems by deploying a new forward migration. This avoids the complexity of maintaining and testing down migrations.

**When forward-only works:** When the expand-contract pattern is used consistently, there is always a safe forward path.

### Reversible Migrations

Each migration includes an `up` and a `down` function. The down function undoes the up function.

### What Cannot Be Rolled Back

- Dropped columns (data is gone unless backed up)
- Irreversible data transformations (hashing, truncation)
- Dropped tables without a backup

**Rule:** Before running any destructive migration in production, create a backup of the affected data. Store it in a temporary table or export it.

---

## Multi-Tool Reference

| Tool | Generate | Apply | Rollback |
|---|---|---|---|
| **Doctrine (PHP)** | `doctrine:migrations:diff` | `doctrine:migrations:migrate` | `doctrine:migrations:migrate prev` |
| **Alembic (Python)** | `alembic revision --autogenerate -m "msg"` | `alembic upgrade head` | `alembic downgrade -1` |
| **Prisma (TypeScript)** | `prisma migrate dev --name msg` | `prisma migrate deploy` | Revert schema, run `prisma migrate dev` |
| **Flyway (Java)** | Manual SQL files (`V1__desc.sql`) | `flyway migrate` | `flyway undo` (Teams edition) |

### Common Pitfalls

| Pitfall | Consequence | Prevention |
|---|---|---|
| Running migrations during peak traffic | Lock contention, timeouts, downtime | Schedule during low-traffic windows or use online DDL |
| Not testing migrations on production-sized data | Migration takes hours instead of seconds | Always test with a production data snapshot |
| Mixing schema and data changes in one migration | Cannot roll back schema without also rolling back data | Separate schema and data migrations into distinct steps |
| Missing down migrations | Cannot roll back when a deployment fails | Write and test both directions, or commit to forward-only |
| Not coordinating migration order across services | Service A depends on a column Service B has not added yet | Define cross-service migration dependencies explicitly |

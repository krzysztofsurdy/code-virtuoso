# Migrations

## Contents

- [The rule behind the order](#the-rule-behind-the-order)
- [Ordering by change type](#ordering-by-change-type)
- [Rollback](#rollback)
- [Never edit an applied migration](#never-edit-an-applied-migration)
- [Transactions and DDL](#transactions-and-ddl)
- [Reviewing a generated migration](#reviewing-a-generated-migration)
- [Commands and config](#commands-and-config)
- [Sources](#sources)

## The rule behind the order

During a rolling or blue/green deploy, old and new code run against the same database for a while. Every schema state must work for both. This is the expand, migrate, contract pattern (parallel change), applied to the schema.

Stated as reasoning, not as a Doctrine feature: an entity mapping makes the ORM select every mapped column and insert every mapped column. So old code breaks when a column it maps disappears, and old inserts break when a new NOT NULL column has no default.

Release order for any change that touches data in use:

1. Release A, expand: a migration that only adds. Old code ignores it. New code may use it.
2. Release A or B, code: write both shapes, read the new one.
3. Backfill: a separate, batched, restartable step (a command or its own migration), after the expand and before the contract.
4. Release C, contract: remove the old shape once no running code maps it.

## Ordering by change type

| Change | Expand | Code | Contract |
|---|---|---|---|
| Add a column | Add it nullable or with a default | Start writing it | Optional: make it NOT NULL after the backfill and after all code writes it |
| Add a table | Create it | Start using it | None |
| Rename a column or table | Add the new one, keep the old | Write both, then read the new one | Drop the old in a later release |
| Change a column type | Add a new column of the new type | Write both, read the new one | Drop the old in a later release |
| Drop a column or table | None | Stop mapping and reading it, deploy | Drop it in the next release |
| Add an index | Online DDL where the engine has it. On PostgreSQL use `CREATE INDEX CONCURRENTLY` | None | None |
| Add a unique constraint or foreign key | Check existing data first. It can lock or fail on dirty rows | Code already respects it | None |

Do not accept a generated single `ALTER ... CHANGE old new` as a rename. A rename in one step breaks the old code that is still running.

PostgreSQL `CREATE INDEX CONCURRENTLY` cannot run in a transaction block, and a failed build leaves an INVALID index that still costs writes. Put it in its own migration with `isTransactional(): false`, and on failure drop the invalid index before retrying:

```php
final class Version20260101000000 extends AbstractMigration
{
    public function isTransactional(): bool
    {
        return false;
    }

    public function up(Schema $schema): void
    {
        $this->addSql('CREATE INDEX CONCURRENTLY idx_order_status ON orders (status)');
    }

    public function down(Schema $schema): void
    {
        $this->addSql('DROP INDEX idx_order_status');
    }
}
```

## Rollback

| Tool | Use |
|---|---|
| `doctrine:migrations:migrate prev` | Roll back the last migration, runs `down()` |
| `doctrine:migrations:execute 'FQCN' --down` | Run one migration's `down()` |
| `throwIrreversibleMigrationException()` in `down()` | Say plainly that it cannot be undone |

Rules:

- Write a real `down()` for every expand step. A `down()` that drops a column loses its data, so say so in the review.
- Prefer rolling the code back and leaving the expanded schema in place. Expand steps are harmless to old code by design.
- Contract steps cannot be undone. That is why they ship last, in their own release, after the new code has proved itself.
- A failed migration on MySQL or Oracle may be half applied (see below). Check the schema before running `down()`.

## Never edit an applied migration

The bundle tracks executed versions in the `doctrine_migration_versions` table and `migrate` runs only versions not recorded there. An edit to an applied migration therefore never runs on the databases that already recorded it. Staging, production and new developer databases end up with different schemas.

- Fix forward with a new migration.
- Editing a migration that has not been applied outside your branch is fine.
- Do not delete a version file that another environment has applied. Check `status` on every environment first.
- To mark a migration as applied without running it, use `doctrine:migrations:version 'FQCN' --add` (quote the class name).

## Transactions and DDL

- `transactional` (default true) wraps each migration in a transaction. `all_or_nothing` (default false) wraps all pending ones in one.
- MySQL and Oracle commit implicitly on DDL such as `CREATE TABLE` and `ALTER TABLE`. A migration that mixes DML and DDL can run its DML in a transaction that is already committed, then fail on commit.
- So: one DDL change per migration, and DML in its own migration. Override `isTransactional(): false` on a DDL-only migration if the platform complains.
- `all_or_nothing` helps only where DDL is transactional, for example PostgreSQL.
- A data backfill does not belong in a `diff`-generated schema migration: the next diff regenerates files, and the backfill cannot be retried alone.

## Reviewing a generated migration

`make:migration` and `doctrine:migrations:diff` compare the mapping to the current database. They do not know about your deploy.

1. Read every `addSql()` line. Look for drops, retypes, `NOT NULL` without a default, and index churn.
2. Check that the migration is additive, or that it is the contract step for a release already out.
3. Check `down()` exists and does what it says.
4. Run `--dry-run` and read the SQL.
5. Check the other environments. With several entity managers pass `--em` to every command. Foreign tables you do not want diffed need a `schema_filter` in `doctrine.yaml`.

## Commands and config

| Command | Purpose |
|---|---|
| `doctrine:migrations:status` | Current and pending versions |
| `doctrine:migrations:migrate --dry-run` | Preview the SQL |
| `doctrine:migrations:migrate` | Apply pending versions. Run it on deploy |
| `doctrine:migrations:migrate prev` | Roll back one |
| `doctrine:migrations:execute 'FQCN' --down` | Roll back a single version |
| `doctrine:migrations:list` | All versions and their state |
| `doctrine:migrations:sync-metadata-storage` | Bring the tracking table up to date |

Config keys under `doctrine_migrations` (check the bundle page for the installed version): `migrations_paths`, `transactional`, `all_or_nothing`, `check_database_platform`, `enable_service_migrations`, `storage.table_storage`, `em` or `connection`.

## Sources

- https://symfony.com/bundles/DoctrineMigrationsBundle/current/index.html (commands, config keys, tracking table, deploy advice)
- https://www.doctrine-project.org/projects/doctrine-migrations/en/3.9/reference/migration-classes.html (`isTransactional`, irreversible)
- https://www.doctrine-project.org/projects/doctrine-migrations/en/3.9/reference/configuration.html (`transactional`, `all_or_nothing`)
- https://www.doctrine-project.org/projects/doctrine-migrations/en/3.9/explanation/implicit-commits.html
- https://www.doctrine-project.org/projects/doctrine-migrations/en/3.9/reference/managing-migrations.html (`prev`, `execute --down`, `--dry-run`)
- https://martinfowler.com/bliki/ParallelChange.html (expand, migrate, contract)
- https://www.postgresql.org/docs/current/sql-createindex.html (`CONCURRENTLY`)

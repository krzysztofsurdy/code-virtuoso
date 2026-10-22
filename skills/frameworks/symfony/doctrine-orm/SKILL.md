---
name: doctrine-orm
description: 'Doctrine ORM 3 and DBAL 4 in Symfony, with version facts and pitfalls. Use when fixing N+1 or slow Doctrine pages, choosing LAZY, EAGER or fetch joins, ordering migrations, hitting "EntityManager is closed", locking rows, batch imports, or Messenger workers that lose the database connection.'
user-invocable: false
allowed-tools: Read Grep Glob Bash
---

# Doctrine ORM and DBAL

Doctrine advice from memory goes wrong in a few repeatable ways: it mixes ORM 2 and 3, it "fixes" N+1 with EAGER mappings, it trusts a migration that is only safe on a stopped site, and it forgets that an exception closes the EntityManager. This skill gives the version facts and the decision rules. It does not restate the API: fetch the page for the installed version through docs-lookup, and use the official Doctrine and Symfony docs listed under each reference.

## Step 1: find the installed versions

Read `composer.lock`, not the constraints in `composer.json`.

```bash
jq -r '.packages[] | select(.name|test("^doctrine/(orm|dbal|doctrine-bundle|doctrine-migrations-bundle|migrations)$")) | .name+" "+.version' composer.lock
php -r 'echo PHP_VERSION, "\n";'
```

PHP 8.4 or newer changes the answer for lazy loading and partial objects (see below).

## Version matrix

Verified 2026-10-22 against https://www.doctrine-project.org/projects/orm.html, https://www.doctrine-project.org/projects/dbal.html, https://symfony.com/releases and the `composer.json` of each package.

| Stack | DoctrineBundle | ORM | DBAL | MigrationsBundle |
|---|---|---|---|---|
| Symfony 8.1, PHP 8.4+ | 3.3 (needs PHP 8.4) | 3.7 | 4.5 | 4.0 (needs PHP 8.4 and bundle 3) |
| Symfony 7.4, PHP 8.4+ | 3.3 | 3.7 | 4.5 | 4.0 |
| Symfony 7.4, PHP 8.2 or 8.3 | 2.19 (Symfony 6.4 and 7.x only) | 3.7 | 4.5 | 3.8 |

ORM 3.7 runs on PHP 8.1+ and DBAL 4.5 on PHP 8.2+. DoctrineBundle 3 refuses ORM 2. The migrations library is on 3.9 in every row.

Doctrine ORM docs under `/en/latest/` describe the unreleased 4.0. Read `https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/` (and `doctrine-migrations/en/3.9/`) for the installed line.

What changed that affects daily code:

| Change | Since | Do this instead |
|---|---|---|
| `EntityManager::transactional()` removed | ORM 3.0 | `wrapInTransaction()` |
| `Query::iterate()` removed | ORM 3.0 | `toIterable()` (yields the entity, not an array) |
| `PARTIAL` DQL removed, then back for array hydration in 3.2 and objects in 3.3 | ORM 3.0 to 3.3 | `SELECT NEW` DTO, or `PARTIAL` on 3.3+ |
| Native lazy objects on PHP 8.4+ (recommended, deprecated to leave off) | ORM 3.5 | DoctrineBundle 3 always enables them. Partial objects then load missing fields on first access |
| `LockMode::NONE` is a no-op, `Paginator` deprecated for `OffsetPaginator` | ORM 3.7 | Call `refresh()` when you need a reload |
| `Connection::query()`, `exec()`, `executeUpdate()`, `Result::fetchAll()` removed | DBAL 4.0 | `executeQuery()`, `executeStatement()`, `fetchAllAssociative()` |
| `SQLLogger` removed | DBAL 4.0 | DBAL logging middleware |
| Nested transactions always use savepoints | DBAL 4.0 | Nothing, but expect savepoint SQL |

## Fetch strategy

Pick per use case, in the repository method that serves it. A mapping is global, so it cannot know the use case.

| Need | Use |
|---|---|
| Show or traverse a relation of many rows | Fetch join: `addSelect('x')` plus `leftJoin`. One query |
| A list that needs a few columns | `SELECT NEW` DTO. Not managed, never flush it |
| Second or third level to-one relation, a join would multiply rows | `setFetchMode(Entity::class, 'rel', ClassMetadata::FETCH_EAGER)` on that query: one extra `IN (...)` query |
| Count, check or page a huge collection | `fetch: 'EXTRA_LAZY'` on that collection, then `count()` and `slice()` |
| Rarely traversed relation | Leave it LAZY |

When mapping-level EAGER is acceptable: a small to-one target that every use of the owner reads. Never on a to-many, never on a large or rarely read target. Every load of the owner pays for it, including `find()` of a single row, and chains of EAGER mappings load transitively. Measured numbers are in [fetch-and-n-plus-one.md](references/fetch-and-n-plus-one.md).

EXTRA_LAZY only covers `contains`, `containsKey` and `get` (with `indexBy`), `count`, `first`, `isEmpty`, `slice`, plus `add`. Each such call on an unloaded collection runs its own SELECT. Anything else loads the whole collection.

Fetch-joining a to-many and calling `setMaxResults()` limits rows, not entities. Page those with the paginator.

## N+1: measure first

1. Count queries before changing anything: profiler panel, or in a test `$client->enableProfiler()` then `$profile->getCollector('db')->getQueryCount()`. Test collection is off by default, so the call is required.
2. Group similar statements. Same SQL with different ids, repeated per row, is the N+1 signature. Same SQL with the same params twice is a duplicate, not N+1.
3. Fix with the table above, then assert the count in a test with realistic row counts.

Not N+1, do not "fix": a to-one relation touched in a loop costs one query per distinct target, not per row (15 orders over 5 customers is 5 queries). `count()` on a loaded collection costs nothing. `find()` on an id already in the EntityManager costs nothing. A fixed small set read once at boot is fine.

Details, test snippet and hot spots (Twig, serializer, voters, form choice labels): [fetch-and-n-plus-one.md](references/fetch-and-n-plus-one.md).

## Migrations

The schema must work for the old code and the new code at the same time, because a rolling or blue/green deploy runs both. That gives the order: expand, deploy code, backfill, contract in a later release.

- Additive and nullable (or defaulted) first. Tighten with NOT NULL only after code writes the column and data is backfilled.
- Never rename or retype in one step. Add the new column, write both, backfill, switch reads, drop the old one a release later.
- Drop a column only after no running code maps it. The ORM selects every mapped column, so old code breaks on a missing one.
- Never edit an applied migration. The tracking table records the version, an edit does not rerun, and environments drift. Add a new one. Editing a migration that has not left your branch is fine.
- Write a real `down()` or call `throwIrreversibleMigrationException()`. Prefer rolling code back and moving the schema forward. Contract steps are the only ones you cannot undo, so they ship last.
- MySQL and Oracle commit DDL implicitly, so a failed migration can leave half the schema. One DDL change per migration, DML in a separate one. `all_or_nothing` only helps on databases with transactional DDL.
- Read every generated statement. Run `--dry-run` first. Long locks on big tables need online DDL, and PostgreSQL `CREATE INDEX CONCURRENTLY` needs `isTransactional(): false`.

Ordering table, config keys and commands: [migrations.md](references/migrations.md).

## Transactions and locking

| Situation | Use |
|---|---|
| One unit of work through the ORM | `persist` then one `flush()`. It is already one transaction |
| Several writes, or ORM plus DBAL in one unit | `$em->wrapInTransaction(fn () => ...)`. Flushes, commits, closes the EM on exception |
| Messenger handler | `doctrine_transaction` middleware. No `flush()`, no own transaction, do not swallow exceptions |
| Concurrent edits across requests (forms) | Optimistic: `#[Version, Column(type: 'integer')]`, carry the version from the form |
| Short critical section on contended rows | Pessimistic write inside `wrapInTransaction`, lock rows in a fixed order |

- An exception in `flush()` or `wrapInTransaction()` rolls back and closes the EntityManager. `clear()` does not reopen it. Reads still work, writes throw `EntityManagerClosed`. Continue only with a fresh EntityManager, and do not reuse the old entities.
- `Connection::transactional()` neither flushes the EM nor closes it. Use `wrapInTransaction` when ORM changes are inside.
- Optimistic locking only protects if you compare the version the user saw. Re-reading the row in the POST and flushing gives lost updates.
- `OptimisticLockException` at flush also closes the EM, so a retry needs a fresh one. Deadlock and lock wait timeout exceptions implement `RetryableException`: retry the whole transaction, bounded.
- Pessimistic locks throw `TransactionRequiredException` outside a transaction. `find(..., PESSIMISTIC_WRITE)` refreshes a managed entity under the lock. `lock()` only locks the row.
- DQL `UPDATE` skips locking, events and the version column.

More in [transactions-and-locking.md](references/transactions-and-locking.md).

## Batch processing

| Task | Use |
|---|---|
| Change or delete many rows by a rule | DQL `UPDATE` or `DELETE`, or DBAL. No hydration |
| Per-row PHP logic over a large table | `toIterable()`, `flush()` and `clear()` every N rows (the Doctrine example uses 20, measure for your rows) |
| Very large or restartable run | Keyset pagination: `WHERE id > :last ORDER BY id LIMIT n`, then `clear()` |

- `clear()` detaches everything. Entities you still hold are detached, and edits to them are silently not saved. Re-fetch parents after a clear.
- `toIterable()` rejects fetch-joined collections. To-one fetch joins are fine.
- The database client can buffer the whole result outside PHP's memory view.
- Run batch commands with debug and profiling off (`APP_DEBUG=0`). The docs warn that an SQL logger costs speed and memory in batches.
- Bulk DQL and DBAL skip lifecycle events and listeners. Check what relied on them.

More in [batch-and-workers.md](references/batch-and-workers.md).

## Long-running workers

In a Messenger worker the EntityManager and its connection live across messages. Put these on the bus that handlers use:

```yaml
framework:
    messenger:
        buses:
            command_bus:
                middleware:
                    - doctrine_ping_connection
                    - doctrine_close_connection
                    - doctrine_open_transaction_logger
                    - doctrine_transaction
```

- `dispatch_after_current_bus` must come before `doctrine_transaction`. It is on by default, so only a hand-written list can get it wrong.
- `doctrine_ping_connection` pings before each worker-consumed message, reconnects, and resets the manager if it was closed. This is what recovers a worker after a failed flush.
- There is no `doctrine_clear_entity_manager` middleware. Clearing after each message is done by a worker event subscriber that DoctrineBundle registers when Messenger is installed. Do not add your own `clear()` for that.
- Messages carry ids, not entities. The handler re-fetches.
- Bound every worker (`--limit`, `--memory-limit`, `--time-limit`) and restart on deploy.
- Inside one long handler the identity map still grows. Clear in batches there too.

## Identity map pitfalls

- One instance per id per EntityManager. A query never overwrites the in-memory state of an entity it already manages, so after a DQL `UPDATE` or another process's write you read stale data until `refresh()` or `clear()`.
- `find()` on a known id costs no query. `findOneBy(['id' => ...])` always does.
- `getReference()` costs no query until you read a field other than the id.
- The identity map plus change tracking makes `flush()` slower as the unit of work grows. Clear in batches, or mark entities read only.
- Entities held across a `clear()` or a closed EM are stale or detached: re-fetch, do not patch.

## Reference files

| Reference | Open when |
|---|---|
| [fetch-and-n-plus-one.md](references/fetch-and-n-plus-one.md) | Choosing a fetch mode, measuring N+1, writing a query count test, judging a "slow page" report |
| [migrations.md](references/migrations.md) | Reviewing or ordering a migration, planning a rename or drop, rollback questions |
| [transactions-and-locking.md](references/transactions-and-locking.md) | Locking, lost updates, closed EntityManager, retry on deadlock |
| [batch-and-workers.md](references/batch-and-workers.md) | Imports, backfills, Messenger worker setup and recovery |
| [research-notes](references/research-notes.md) | Research: prior-art table, fact ledger with sources and dates, unconfirmed items |

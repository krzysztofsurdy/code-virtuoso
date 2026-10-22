# Research notes: doctrine-orm skill

Date: 2026-10-22
Depth: standard
Research skill used: no (inline, WebFetch plus gh api plus a local PHP sandbox)
Prior-art search: done

Confirmation gates: approved by the maintainer in the build brief.

## Scope

Covers Doctrine ORM 3.x and DBAL 4 in Symfony 7.4 and 8.x: version matrix, fetch strategy, N+1 detection and false positives, migrations (expand and contract, rollback, never edit applied), transactions and locking, batch processing, long-running Messenger workers, identity map pitfalls. Does not restate the API reference (points to docs-lookup and the official docs).

Questions answered: which versions pair up; what EAGER and EXTRA_LAZY really do; what count() does in a loop; what the Messenger Doctrine pieces are called and do; what happens to the EntityManager after an exception; what the docs say versus what 3.7.5 does.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/transactions-and-concurrency.html | official | Doctrine | n/a | 2026-10-22 |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/batch-processing.html | official | Doctrine | n/a | 2026-10-22 |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/working-with-objects.html | official | Doctrine | n/a | 2026-10-22 |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/dql-doctrine-query-language.html | official | Doctrine | n/a | 2026-10-22 (read as rst, branch 3.7.x) |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/unitofwork.html | official | Doctrine | n/a | 2026-10-22 (rst) |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/partial-objects.html | official | Doctrine | n/a | 2026-10-22 (rst) |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/advanced-configuration.html | official | Doctrine | n/a | 2026-10-22 (rst) |
| https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/tutorials/extra-lazy-associations.html | official | Doctrine | n/a | 2026-10-22 (rst; the `/en/latest/` rendered pages are ORM 4.0, unreleased, so every cited URL uses `/en/3.7/`, all 200) |
| https://github.com/doctrine/orm/blob/3.7.x/UPGRADE.md | official | Doctrine | n/a | 2026-10-22 |
| https://github.com/doctrine/dbal/blob/4.5.x/UPGRADE.md | official | Doctrine | n/a | 2026-10-22 |
| https://www.doctrine-project.org/projects/orm.html and /dbal.html | official | Doctrine | n/a | 2026-10-22 |
| https://www.doctrine-project.org/projects/doctrine-migrations/en/3.9/reference/migration-classes.html, configuration.html, managing-migrations.html, explanation/implicit-commits.html | official | Doctrine | n/a | 2026-10-22 (rst, branch 3.9.x) |
| https://symfony.com/bundles/DoctrineMigrationsBundle/current/index.html | official | Symfony | n/a | 2026-10-22 |
| https://symfony.com/doc/current/messenger.html (Middleware for Doctrine, Deploying to Production, dispatch_after_current_bus) | official | Symfony | n/a | 2026-10-22 |
| https://symfony.com/doc/current/doctrine.html, /doctrine/associations.html | official | Symfony | n/a | 2026-10-22 |
| https://symfony.com/doc/current/testing/profiling.html, /testing.html | official | Symfony | n/a | 2026-10-22 |
| https://symfony.com/releases | official | Symfony | n/a | 2026-10-22 |
| Symfony source: src/Symfony/Bridge/Doctrine/Messenger/*.php (branch 7.4) | source | Symfony | n/a | 2026-10-22 |
| DoctrineBundle source: config/messenger.php, src/DependencyInjection/Configuration.php, UPGRADE-3.0.md | source | Doctrine | n/a | 2026-10-22 |
| ORM 3.7.x source: EntityManager.php, UnitOfWork.php, PersistentCollection.php, AbstractQuery.php | source | Doctrine | n/a | 2026-10-22 |
| https://repo.packagist.org/p2/doctrine/orm.json (and dbal, doctrine-bundle, doctrine-migrations-bundle, migrations) | registry | Packagist | n/a | 2026-10-22 (release numbers; constraints cross-checked in composer.json on the GitHub branches) |
| https://www.postgresql.org/docs/current/sql-createindex.html | vendor | PostgreSQL | n/a | 2026-10-22 |
| https://martinfowler.com/bliki/ParallelChange.html | practitioner | Martin Fowler | n/a | 2026-10-22 |
| https://symfonycasts.com/screencast/ansistrano/safe-migrations | practitioner (lead only) | SymfonyCasts | n/a | seen in search results 2026-10-22, not opened |
| Local sandbox: PHP 8.5.10, doctrine/orm 3.7.5, doctrine/dbal 4.5.0, SQLite, DBAL logging middleware as a query counter | reproduction | this run | n/a | 2026-10-22 |

## Prior art

Queries run:
- `gh api repos/dev-toolings/superpowers-symfony` (226 stars, MIT, pushed 2026-10-05) and `gh api .../git/trees/HEAD?recursive=1 | grep -iE 'doctrine|transact|batch|migrat'`
- read `content/skills/doctrine-fetch-modes`, `doctrine-migrations`, `doctrine-transactions`, `doctrine-batch-processing` (SKILL.md and reference.md), `symfony-messenger`, `messenger-retry-failures`, `content/agents/doctrine-performance-optimizer.md`
- read installed `~/.agents/skills/detect-n-plus-one/SKILL.md` and `~/.agents/skills/database-migration/SKILL.md`
- `npx skills find "doctrine orm"` (could not complete: `timeout` command missing on this machine, not retried; the GitHub and installed-set tiers were covered)
- local repo: `skills/frameworks/symfony/symfony-components` (N+1 and Messenger pitfall lines), `skills/knowledge/docs-lookup`

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| dev-toolings/superpowers-symfony@doctrine-fetch-modes | https://github.com/dev-toolings/superpowers-symfony/blob/main/content/skills/doctrine-fetch-modes/SKILL.md | community | 226 stars, repo pushed 2026-10-05 | LAZY/EAGER/EXTRA_LAZY, fetch join, SELECT NEW, PARTIAL version gating, DBAL 4 method names | Correct version gating of PARTIAL (3.0 to 3.2 absent, back in 3.3), clear guardrails, DTO advice | No N+1 false positives, no query count test, no EAGER batching facts, says "avoid EAGER" without the per-query setFetchMode case, no count() semantics | MIT per repo |
| dev-toolings/superpowers-symfony@doctrine-migrations | .../doctrine-migrations/SKILL.md | community | same repo | make:migration, review, down(), status, dry-run, all_or_nothing | Short, correct guardrails, never edit applied | No expand and contract ordering, no rolling deploy reasoning, no CONCURRENTLY or isTransactional case, no rollback limits | MIT per repo |
| dev-toolings/superpowers-symfony@doctrine-transactions | .../doctrine-transactions/SKILL.md | community | same repo | wrapInTransaction, optimistic, pessimistic, clear after rollback | Correct `transactional()` removal note, single flush rule | Says "clear the EntityManager after a rollback" but wrapInTransaction closes it (clear does not reopen it), no worker recovery, no lost-update-by-refetch pitfall | MIT per repo |
| dev-toolings/superpowers-symfony@doctrine-batch-processing | .../doctrine-batch-processing/SKILL.md | community | same repo | toIterable, flush/clear, keyset pagination, DQL and DBAL bulk | Good: Query::iterate removal, keyset over offset, bulk bypasses events | Does not say toIterable rejects fetch-joined collections, no stale-entity-after-DQL-UPDATE detail, no profiler or logger memory note | MIT per repo |
| dev-toolings/superpowers-symfony@symfony-messenger (and messenger-retry-failures) | .../symfony-messenger/SKILL.md | community | same repo | transports, workers, retries | Entity IDs in messages | Nothing on doctrine_ping_connection, doctrine_transaction, the clear subscriber, closed EntityManager in a worker | MIT per repo |
| ~/.agents/skills/detect-n-plus-one | local installed skill | unknown | local | N+1 detection patterns incl. Doctrine | Grep patterns, false positive list | Contains both wrong claims: says `count()` in a loop queries each time, and recommends `fetch: 'EAGER'` as the fix | none stated |

Decision: write a new skill. dev-toolings covers fetch modes, transactions, batch and migrations basics correctly in four short skills, so users who want those can install it. It does not cover expand and contract ordering, N+1 false positives and query count assertions, the Messenger Doctrine middleware and clear subscriber, the closed EntityManager in workers, identity map pitfalls, or a Symfony 7.4/8.x version matrix. The installed detect-n-plus-one carries the two wrong claims this skill must correct. Recommendation to the user: installing dev-toolings alongside ours is reasonable; ours does not duplicate its API snippets.

Strengths adopted (ideas only, no text copied): dev-toolings' PARTIAL version gating and DTO-first advice (doctrine-fetch-modes); keyset pagination over offset and the bulk-bypasses-events warning (doctrine-batch-processing); "never edit an applied migration" and one concern per migration (doctrine-migrations); the `transactional()` removal note (doctrine-transactions). Credit: https://github.com/dev-toolings/superpowers-symfony (MIT). Weaknesses avoided: unmeasured N+1 advice, a blanket "avoid EAGER", clear-after-rollback wording, no worker coverage. Gap filled: the list above.

## Baseline (phase 1)

No user to ask, so the baseline is evidence-based:
- The brief itself carried one wrong name: `doctrine_clear_entity_manager` as a Messenger middleware. It is not a middleware: zero hits in symfony/symfony. It is the service id `doctrine.orm.messenger.event_subscriber.doctrine_clear_entity_manager` of `DoctrineClearEntityManagerWorkerSubscriber`, registered by DoctrineBundle when Messenger is installed. A model working from memory repeats this name.
- The installed detect-n-plus-one skill and (before this work) the common advice say EAGER fixes N+1 and count() in a loop always queries. Both are wrong or incomplete (measured below).
- The Doctrine ORM docs themselves disagree with ORM 3.7.5 on one point (see "Docs versus behaviour").
Purpose, triggers and non-goals follow the brief: fires on N+1, fetch strategy, migrations, locking, batch, worker connection loss; near miss is a plain SQL tuning or non-Doctrine question.

## Fact ledger

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | Stable ORM 3.7.5; 3.6.9 unmaintained; upcoming 3.8 and 4.0 | https://www.doctrine-project.org/projects/orm.html | 2026-10-22 | 3.7.5 | confirmed | page read plus packagist (3.7.5 released 2026-10-09) |
| 2 | Stable DBAL 4.5.0; 4.4.5 and older 4.x unmaintained; 3.10.6 stable | https://www.doctrine-project.org/projects/dbal.html | 2026-10-22 | 4.5.0 | confirmed | page read plus packagist |
| 3 | ORM 3.7 requires PHP ^8.1 and DBAL ^3.8.2 or ^4; DBAL 4.5 requires PHP ^8.2 | https://github.com/doctrine/orm/blob/3.7.x/composer.json, https://github.com/doctrine/dbal/blob/4.5.x/composer.json | 2026-10-22 | 3.7, 4.5 | confirmed | composer.json read, packagist |
| 4 | DoctrineBundle 3.3 requires PHP ^8.4, DBAL ^4, ORM conflict <3.0 or >=4.0, Symfony ^6.4 or ^7.0 or ^8.0; docs at v3.3 | https://github.com/doctrine/DoctrineBundle/blob/3.3.x/composer.json | 2026-10-22 | 3.3.x | confirmed | composer.json, packagist 3.3.2, doctrine-project.org/projects/orm.html shows bundle docs v3.3 |
| 5 | DoctrineBundle 2.19 requires PHP ^8.1, DBAL ^3.7 or ^4, Symfony ^6.4 or ^7.0, ORM conflict <2.17 or >=4.0 (so ORM 3.x allowed) | https://github.com/doctrine/DoctrineBundle/blob/2.19.x/composer.json | 2026-10-22 | 2.19.x | confirmed | composer.json (2.19.x has no Symfony 8) |
| 6 | DoctrineMigrationsBundle 4.0 requires PHP ^8.4, DoctrineBundle ^3, migrations library ^3.2; 3.8/3.7 allow PHP 7.2+, bundle ^2.4 or ^3 | https://github.com/doctrine/DoctrineMigrationsBundle/blob/4.0.x/composer.json | 2026-10-22 | 4.0.x, 3.8.x | confirmed | composer.json, packagist 4.0.1 and 3.7.1; Symfony page shows 4.0.x as current |
| 7 | doctrine/migrations library current line is 3.9 (3.9.8); a 4.0 branch exists unreleased | https://repo.packagist.org/p2/doctrine/migrations.json | 2026-10-22 | 3.9.8 | likely | packagist plus branch list (3.10.x, 4.0.x exist) |
| 8 | Symfony 7.4 LTS (PHP 8.2+), 8.1 current stable (PHP 8.4+), 8.0 ended, 6.4 LTS ends bug fixes Nov 2026, 8.2 planned Nov 2026 | https://symfony.com/releases | 2026-10-22 | n/a | confirmed | page read |
| 9 | `EntityManager::transactional()` removed in ORM 3, use `wrapInTransaction()`; `Query::iterate()` removed, use `toIterable()` | https://github.com/doctrine/orm/blob/3.7.x/UPGRADE.md | 2026-10-22 | 3.0 | confirmed | UPGRADE.md read; sandbox: `method_exists` false for both |
| 10 | PARTIAL DQL removed in 3.0, back for array hydration in 3.2, for objects in 3.3 | UPGRADE.md (same) | 2026-10-22 | 3.2, 3.3 | confirmed | UPGRADE.md; dev-toolings states the same; sandbox 3.7.5 object hydration works |
| 11 | With PHP 8.4 native lazy objects, unselected fields of a PARTIAL object load on first access; otherwise partial objects are tricky | https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/partial-objects.html | 2026-10-22 | 3.7 | confirmed | rst read; sandbox PHP 8.5: `name` of PARTIAL c.{id} read as 'c1' |
| 12 | Native lazy objects: recommended on PHP 8.4, not enabling them on 8.4+ is deprecated since 3.5, ORM 4 requires PHP 8.4; DoctrineBundle 3.x always enables them (option deprecated since bundle 3.1) | advanced-configuration.rst, UPGRADE.md (3.5), DoctrineBundle Configuration.php | 2026-10-22 | ORM 3.5+, bundle 3.1+ | confirmed | three sources |
| 13 | DBAL 4 removed `Connection::query()`, `exec()`, `executeUpdate()`, `Result::fetch()`/`fetchAll()`; removed `SQLLogger` (use middleware); nested transactions always use savepoints | https://github.com/doctrine/dbal/blob/4.5.x/UPGRADE.md | 2026-10-22 | 4.0 | confirmed | UPGRADE.md read |
| 14 | EXTRA_LAZY methods that avoid a full load: contains, containsKey (indexBy), count, first, get (indexBy), isEmpty, slice; unloaded collection gets a plain SELECT per call; already-loaded collection falls back to normal behaviour; add() and offsetSet without key do not load | https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/tutorials/extra-lazy-associations.html | 2026-10-22 | 3.7 | confirmed | rst read plus PersistentCollection.php source plus sandbox A3/A5 |
| 15 | count() on a default LAZY collection loads it once, later calls cost nothing; on a fetch-joined collection costs nothing; on an unloaded EXTRA_LAZY collection issues one COUNT per call | PersistentCollection.php (3.7.x) | 2026-10-22 | 3.7.5 | confirmed | source plus sandbox: A2 2 queries, A3 4 queries (3 COUNT), A4 1 query |
| 16 | Lazy loading in a loop on a to-one relation costs one query per distinct target, not per row (identity map) | working-with-objects.html (identity map) | 2026-10-22 | 3.7.5 | confirmed | sandbox B1: 15 orders over 5 customers = 6 queries; B2 fetch join = 1 |
| 17 | A join is a fetch join when the joined entity's fields are in SELECT outside an aggregate; fetch joins are the documented fix for lazy-loading query volume | dql-doctrine-query-language.html (Fetch Joins) | 2026-10-22 | 3.7 | confirmed | rst read; sandbox B2 |
| 18 | Per-query `setFetchMode(class, assoc, FETCH_EAGER)` batches to-one loads into one `WHERE id IN (...)` query | dql-doctrine-query-language.html (Temporarily change fetch mode) | 2026-10-22 | 3.7 | confirmed | rst; sandbox B3: 2 queries |
| 19 | Mapping-level EAGER on a one-to-many adds a query every time the owner loads, batched by `Configuration::setEagerFetchBatchSize()` (default 100) | working-with-objects.html (By Eager Loading), UnitOfWork.php source | 2026-10-22 | 3.7.5 | confirmed | sandbox C1: 250 owners = 1 + 3 queries; C2: find() of one owner = 2 queries |
| 20 | Fetch-joining a collection with setMaxResults limits rows, not root entities | dql-doctrine-query-language.html (First and Max Result Items) | 2026-10-22 | 3.7 | confirmed | rst read |
| 21 | `toIterable()` is not possible with queries that fetch-join a collection-valued association; client may buffer full results | batch-processing.html | 2026-10-22 | 3.7 | confirmed | rst; sandbox F1 throws QueryException, F3 to-one fetch join works |
| 22 | `toIterable()` yields the entity itself, `iterate()` wrapped it in an array; the batch doc's `detach($row[0])` example is stale | UPGRADE.md (2.x iterate deprecation), batch-processing.rst line 189 | 2026-10-22 | 3.7 | likely | UPGRADE text plus doc text; not run |
| 23 | SELECT NEW returns DTOs that are not managed, needs no mapped entity, constructor must match | dql-doctrine-query-language.html ("NEW" Operator Syntax) | 2026-10-22 | 3.7 | confirmed | rst; sandbox G1 managed=false |
| 24 | `wrapInTransaction()` flushes before commit and closes the EntityManager on exception; `Connection::transactional()` does neither | transactions-and-concurrency.html, EntityManager.php | 2026-10-22 | 3.7.5 | confirmed | doc, source, sandbox N1 (no flush) and N2 (flush), D2 (closed) |
| 25 | A failed flush (including OptimisticLockException at flush) rolls back and closes the EntityManager; `clear()` does not reopen it; reads still work on a closed EM, writes throw `EntityManagerClosed` | transactions-and-concurrency.html (Exception Handling), UnitOfWork.php | 2026-10-22 | 3.7.5 | confirmed | sandbox D2 to D6, H4, K1 to K7 |
| 26 | Optimistic locking: `#[Version, Column(type: 'integer')]`; compare the version read at GET time via `find($class, $id, LockMode::OPTIMISTIC, $expected)`; re-reading then flushing allows lost updates | transactions-and-concurrency.html | 2026-10-22 | 3.7 | confirmed | doc; sandbox: `#[Version]` with an untyped Column throws a TypeError in MappingException (type must be explicit); H2, H3 |
| 27 | Pessimistic locks need an open transaction (`TransactionRequiredException`); modes PESSIMISTIC_READ and PESSIMISTIC_WRITE; usable with find, lock, refresh, `Query::setLockMode` | transactions-and-concurrency.html | 2026-10-22 | 3.7 | confirmed | doc; sandbox I1, I2 |
| 28 | `find()` with a pessimistic mode on an already-managed entity refreshes it under the lock; `lock()` only locks the row | EntityManager.php find(), UnitOfWork.php lock() | 2026-10-22 | 3.7.5 | confirmed | source read (not run: SQLite has no row locks) |
| 29 | DBAL deadlock and lock wait timeout exceptions implement `RetryableException` ("retrying the transaction makes sense") | https://github.com/doctrine/dbal/blob/4.5.x/src/Exception/RetryableException.php | 2026-10-22 | 4.5 | confirmed | source read |
| 30 | DBAL 4.5 QueryBuilder `forUpdate(ConflictResolutionMode::SKIP_LOCKED)` exists; no NOWAIT case | vendor/doctrine/dbal/src/Query/ForUpdate/ConflictResolutionMode.php | 2026-10-22 | 4.5.0 | confirmed | read in sandbox |
| 31 | DQL UPDATE/DELETE bypass locking, events, do not bump the version column, and leave loaded entities stale | dql-doctrine-query-language.html (UPDATE queries) | 2026-10-22 | 3.7 | confirmed | rst; sandbox E1, E2, E4 |
| 32 | A query does not overwrite changed state of an already-managed entity; one instance per id per EntityManager; `clear()` detaches everything; `find()` hits the identity map, `findOneBy` does not | working-with-objects.html, unitofwork.html | 2026-10-22 | 3.7.5 | confirmed | docs; sandbox E3, E6, O1 (0 queries), O2 (1 query) |
| 33 | Changes to an entity detached by `clear()` are silently not persisted | working-with-objects.html (clear detaches) | 2026-10-22 | 3.7.5 | confirmed | sandbox L1 |
| 34 | flush() cost grows with the size of the UnitOfWork; read-only entities and `markReadOnly()` reduce it | unitofwork.html | 2026-10-22 | 3.7 | confirmed | rst read |
| 35 | Messenger Doctrine middleware ids: `doctrine_ping_connection`, `doctrine_close_connection`, `doctrine_open_transaction_logger`, `doctrine_transaction` (takes an EM name argument) | https://symfony.com/doc/current/messenger.html#middleware-for-doctrine | 2026-10-22 | 8.1 docs | confirmed | page read, DoctrineBundle config/messenger.php |
| 36 | Ping middleware pings only for messages consumed by a worker, reconnects on failure and calls `ManagerRegistry::resetManager()` when the EM is closed; close middleware closes the connection after a worker-consumed message | Symfony 7.4 Bridge/Doctrine/Messenger source | 2026-10-22 | 7.4 | confirmed | source read; same files exist on 8.0 |
| 37 | Clearing the EM after each message is done by `DoctrineClearEntityManagerWorkerSubscriber` (on WorkerMessageHandled and Failed), registered by DoctrineBundle when Messenger is installed. There is no `doctrine_clear_entity_manager` middleware | DoctrineBundle config/messenger.php, DoctrineExtension.php | 2026-10-22 | bundle 3.x | confirmed | source read; `gh search code` for the middleware name in symfony/symfony returned no hits |
| 38 | `dispatch_after_current_bus` must be registered before `doctrine_transaction` | https://symfony.com/doc/current/messenger.html | 2026-10-22 | 8.1 docs | confirmed | page read |
| 39 | Pass the entity id, not the entity, in a message | symfony-docs messenger.rst ("Doctrine Entities in Messages") | 2026-10-22 | 8.1 docs | confirmed | rst read |
| 40 | Workers: `--limit`, `--memory-limit`, `--time-limit`, `--failure-limit`; the docs name the Doctrine EM as a service that grows | https://symfony.com/doc/current/messenger.html (Deploying to Production) | 2026-10-22 | 8.1 docs | confirmed | page read |
| 41 | Profiler: `$client->enableProfiler()`, then `$profile->getCollector('db')->getQueryCount()`; collection is off by default in the test env (`collect: false`) | https://symfony.com/doc/current/testing/profiling.html | 2026-10-22 | 8.1 docs | confirmed | page read |
| 42 | Doctrine profiler panel offers "Group similar statements" (default grouping when over 100 queries) | DoctrineBundle templates/Collector/db.html.twig | 2026-10-22 | bundle 3.x | likely | template source read; not rendered |
| 43 | DoctrineBundle `profiling` defaults to `%kernel.debug%`; the batch doc warns an enabled SQL logger hurts batch performance and memory | DoctrineBundle Configuration.php, batch-processing.html | 2026-10-22 | bundle 3.x | confirmed | source and doc |
| 44 | Migrations: executed versions are tracked in `doctrine_migration_versions`; `migrate` runs only versions not yet recorded | https://symfony.com/bundles/DoctrineMigrationsBundle/current/index.html | 2026-10-22 | bundle 4.0 | confirmed | page read |
| 45 | `transactional` defaults true, `all_or_nothing` false and "only works if your database supports transactions for DDL"; MySQL and Oracle commit implicitly on DDL; split DML and DDL into separate migrations; `isTransactional()` override | migrations docs (configuration, migration-classes, implicit-commits) | 2026-10-22 | library 3.9 | confirmed | rst read |
| 46 | `down()` can call `throwIrreversibleMigrationException()`; `migrate prev` and `execute --down` roll back; `--dry-run` previews | migration-classes and managing-migrations docs | 2026-10-22 | library 3.9 | confirmed | rst read |
| 47 | PostgreSQL `CREATE INDEX CONCURRENTLY` cannot run inside a transaction block; a failed build leaves an INVALID index | https://www.postgresql.org/docs/current/sql-createindex.html | 2026-10-22 | current | confirmed | page read |
| 48 | Expand, migrate, contract (parallel change) | https://martinfowler.com/bliki/ParallelChange.html | 2026-10-22 | n/a | confirmed | page read |
| 49 | A rolling or blue/green deploy runs old code against the new schema, so a schema step must work for both code versions | reasoning from #48 plus ORM selecting every mapped column | 2026-10-22 | n/a | single-source (reasoned) | stated as reasoning, not as a Doctrine fact |

## Docs versus behaviour (kept in the skill as a "measure it" note)

The DQL doc note says that changing a one-to-many to EAGER "will cause to execute one query for every root entity loaded". On ORM 3.7.5 an EAGER inverse one-to-many is batched (UnitOfWork `eagerLoadCollections`, chunked by `getEagerFetchBatchSize()`); measured 4 queries for 250 owners. Many-to-many still costs one query per collection (working-with-objects doc). The skill states the measured behaviour and tells the reader to check the profiler.

## URL note

`/projects/doctrine-orm/en/latest/` serves the unreleased ORM 4.0 docs (the Extra Lazy page says so when fetched). The skill therefore links `/en/3.7/` pages and `/projects/doctrine-migrations/en/3.9/` pages. `/doctrine-migrations/en/latest/reference/*.html` returns 404. All cited URLs were requested on 2026-10-22 and returned 200 (curl).

## Not confirmed

- Symfony Doctrine panel "Group similar statements" label and default: read from the Twig source, not rendered (row 42). Kept, marked likely in the reference.
- `$em->detach($row)` in a `toIterable()` loop: derived from the UPGRADE text, not run (row 22). The skill uses `clear()` per batch instead of detach.
- Pessimistic lock row behaviour: SQLite has no row locks, so only the transaction requirement was run (row 28).
- Whether DBAL diff emits a rename as `CHANGE` or drop plus add: single practitioner lead (SymfonyCasts), not opened. Cut from the skill; the skill says "read every generated statement" only.
- `ManagerRegistry::resetManager()` use outside Messenger: seen in the ping middleware source only. The skill names it with that source and does not give a full retry snippet.
- `npx skills find` did not run (no `timeout` binary). Prior art rests on GitHub and installed tiers.
- No Symfony app was booted, so the Messenger YAML and middleware order are from the docs, not executed.

## Left out

- Second-level cache, filters, events, Gedmo behaviours: off scope.
- Full DQL and QueryBuilder API, mapping reference: the model knows it, docs change. Pointer to docs-lookup.
- DBAL schema introspection changes in 4.x: not part of the stated scope.
- Pagination mechanics beyond the one-line row-limit warning and the 3.7 OffsetPaginator pointer.
- ORM 2 to 3 upgrade steps: belong in symfony-upgrade or a future skill; only the facts that change daily code are in the matrix.

## Addendum: verification of snippets and links (phase 4)

| # | Claim | Source | Retrieved | Confidence | Verified by |
|---|---|---|---|---|---|
| 50 | Dispatch with `DispatchAfterCurrentBusStamp` so the event handlers run after the command handler's transaction | https://symfony.com/doc/current/messenger.html (Transactional Messages) | 2026-10-22 | confirmed | rst read |
| 51 | Inner `wrapInTransaction` failure inside an outer transaction: nesting level back to 1, EM closed | sandbox t6.php | 2026-10-22 | confirmed | ran |
| 52 | Retry loop with `RetryableException` and `ManagerRegistry::resetManager()` ends with a fresh open EM and the row written | sandbox t5.php (minimal `AbstractManagerRegistry` subclass, a stub exception implementing the marker interface; a real deadlock was not produced) | 2026-10-22 | likely | ran with a stub |
| 53 | Flush and clear loop, keyset loop, QueryBuilder fetch join, `OffsetPaginator` exists, eager batch size default 100, `exec`/`query`/`executeUpdate` removed, `fetchAllAssociative` present | sandbox t4.php | 2026-10-22 | confirmed | ran |
| 54 | Every external URL in the skill returned 200 via curl | see URL note | 2026-10-22 | confirmed | curl |

Sandbox: a local sandbox (not committed) (t1.php to t6.php, src/Entities.php, src/bootstrap.php). Not in the repo.

Not run: the Messenger YAML, the profiler test snippet (needs a Symfony app), real row locks, MySQL implicit commit behavior.

Evals: `evals/run.sh check` passes ("all cases load"). The trigger cases were not run for real (cost, and the skill is not in marketplace.json yet, so `stage.sh` does not stage it). Run `evals/run.sh triggers --case 'doctrine-orm-*'` after registration.

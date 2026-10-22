# Fetch strategy and N+1

## Contents

- [What each fetch mode does](#what-each-fetch-mode-does)
- [Measured query counts](#measured-query-counts)
- [Fetch join, DTO or partial](#fetch-join-dto-or-partial)
- [Detecting N+1](#detecting-n1)
- [Asserting the query count in a test](#asserting-the-query-count-in-a-test)
- [False positives](#false-positives)
- [Where N+1 hides](#where-n1-hides)
- [Sources](#sources)

## What each fetch mode does

| Mode | Behavior | Use |
|---|---|---|
| `LAZY` (default) | A proxy or an uninitialized collection. The first access loads it. A collection loads in full | Most relations |
| `EXTRA_LAZY` | Like LAZY, but `count`, `contains`, `isEmpty`, `first`, `slice` (and `get`, `containsKey` with `indexBy`) run a targeted SELECT while the collection is unloaded | Very large collections you count or page |
| `EAGER` (mapping) | Loaded with the owner on every load. To-one targets come by join or a second query, inverse one-to-many by batched `IN (...)` queries | A small to-one that every use of the owner reads |
| `EAGER` (per query) | `$query->setFetchMode(Owner::class, 'assoc', ClassMetadata::FETCH_EAGER)`: one batched `IN` query for that association on that query only | Deep to-one levels where a join would multiply rows |

Once an EXTRA_LAZY collection is loaded (by a fetch join, an iteration, `getValues()`), later calls fall back to normal in-memory behavior.

## Measured query counts

Reproduced on ORM 3.7.5, DBAL 4.5.0, PHP 8.5, SQLite, with a DBAL logging middleware as the counter. Five customers with three orders each unless noted.

| Case | Queries |
|---|---|
| LAZY: list customers, `->orders->count()` on each | 6 (1 list plus 5 collection loads) |
| LAZY: one customer, `->orders->count()` three times | 2 (the collection loads once) |
| EXTRA_LAZY: one customer, `->orders->count()` three times | 4 (one COUNT per call) |
| Fetch join of orders, then `count()` on each customer | 1 |
| 15 orders over 5 customers, read `->customer->name` | 6 (one per distinct customer, not 16) |
| Same with `JOIN o.customer c` and `SELECT o, c` | 1 |
| Same with per-query `FETCH_EAGER` on `customer` | 2 |
| 250 owners with a mapping-level EAGER one-to-many, no access | 4 (1 plus 3 batches of 100) |
| `find()` of one owner with that mapping | 2 |

Read these as proof that the two common claims are wrong:

- "Use fetch EAGER to fix N+1" trades a visible N+1 for an invisible query on every load of the owner. A fetch join in the repository method serves one use case with one query. Mapping-level EAGER stays only for a small to-one that every use reads.
- "`count()` in a loop always queries" is false. It queries once per distinct unloaded collection (so N parents still cost N), never when the collection is already loaded or fetch-joined, and repeated calls on the same LAZY collection cost nothing. The repeated-query case is EXTRA_LAZY, where each call on an unloaded collection issues its own COUNT.

One docs note disagrees with 3.7.5. The DQL page says an eager one-to-many causes one query per root entity. The measured behavior is batched (default batch size 100, `Configuration::setEagerFetchBatchSize()`), and many-to-many still costs one query per collection. Trust the profiler on your version over either page.

## Fetch join, DTO or partial

Fetch join in a repository method:

```php
return $this->createQueryBuilder('o')
    ->addSelect('c')
    ->leftJoin('o.customer', 'c')
    ->andWhere('o.status = :status')
    ->setParameter('status', $status)
    ->getQuery()
    ->getResult();
```

A join is a fetch join when fields of the joined entity are in the SELECT outside an aggregate. There is no keyword.

Rules:

- Fetch-join one to-many per query. Several multiply rows, so fetch the second with a follow-up `WHERE x IN (:ids)` query.
- With a fetch-joined collection, `setMaxResults()` limits rows, not entities. Use the paginator (`Paginator` with fetch-join collection on 3.x, `OffsetPaginator` from 3.7).
- `toIterable()` does not accept a fetch-joined collection.

Read-only list, few columns: `SELECT NEW App\Dto\OrderRow(o.id, c.name) FROM App\Entity\Order o JOIN o.customer c`. The constructor arguments must match the list. The result is not managed, so it never reaches `flush()`. It needs no mapped entity.

`PARTIAL` is available on ORM 3.3 and newer for objects. On PHP 8.4 with native lazy objects (always on in DoctrineBundle 3) the fields you left out load on first access, so the object stays valid. Before that, a partial object has fields the UnitOfWork will not update, so prefer a DTO.

## Detecting N+1

1. Reproduce with realistic row counts. An N+1 on 3 rows is invisible.
2. Open the Symfony profiler Doctrine panel for the request. Use "Group similar statements": the same SQL shape repeated N times with different ids is the signature.
3. Trace the repeated statement to its caller with the query's backtrace (profiler setting `profiling_collect_backtrace` in DoctrineBundle) or by searching for the relation getter in the loop.
4. Fix by the table in the skill, then re-measure. If the count did not drop, you fixed the wrong thing.

## Asserting the query count in a test

Symfony's functional test client exposes the profiler. Collection is off by default in the test environment, so `enableProfiler()` is required, and the profiler itself must be enabled in configuration.

```php
$client->enableProfiler();
$client->request('GET', '/orders');

if ($profile = $client->getProfile()) {
    $this->assertLessThan(
        10,
        $profile->getCollector('db')->getQueryCount(),
        sprintf('Too many queries (token %s)', $profile->getToken()),
    );
}
```

Seed enough rows that an N+1 would blow the limit (50 rows against a limit of 10), or the test passes on a broken query. Collecting costs time, so enable it only in the tests that assert counts.

Outside HTTP (a service or command test), count statements with a DBAL logging middleware that appends to an array, as in the reproduction above.

## False positives

| Looks like N+1 | Why it is not |
|---|---|
| To-one getter in a loop over rows that share targets | One query per distinct target, then the identity map answers |
| `count()`, `isEmpty()`, `contains()` in a loop on loaded collections | In-memory, no SQL |
| `find($id)` in a loop over ids already loaded | Identity map hit. `findOneBy` is different: it always queries |
| `getReference($id)` in a loop | No query until a field other than the id is read |
| Same SQL twice with the same parameters | A duplicate (cache or reuse it), not N+1 |
| Fixed, config-sized loop of 3 items | Cheaper than a join that multiplies rows |
| Transaction, savepoint, session, Messenger polling statements | Infrastructure, not your relations |

## Where N+1 hides

- Twig: `{{ order.items|length }}`, `{% for i in order.items %}` in a list template.
- Serializer: normalizing an entity graph, or an API resource that exposes relations.
- Security voters and form choice labels (`__toString()` of a related entity).
- Entity getters that traverse a relation ("total" computed from lines).
- Listeners and validators that call a repository per entity.

## Sources

- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/dql-doctrine-query-language.html (fetch joins, `NEW`, temporary fetch mode, result limits)
- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/tutorials/extra-lazy-associations.html
- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/working-with-objects.html (identity map, eager loading, batch size)
- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/partial-objects.html
- https://symfony.com/doc/current/testing/profiling.html
- https://symfony.com/doc/current/doctrine/associations.html (joins to avoid the second query)

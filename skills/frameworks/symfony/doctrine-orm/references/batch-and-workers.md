# Batch processing and long-running workers

## Contents

- [Choosing a batch method](#choosing-a-batch-method)
- [The flush and clear loop](#the-flush-and-clear-loop)
- [Keyset pagination](#keyset-pagination)
- [Batch pitfalls](#batch-pitfalls)
- [Messenger Doctrine pieces](#messenger-doctrine-pieces)
- [Worker setup](#worker-setup)
- [What goes wrong in a worker](#what-goes-wrong-in-a-worker)
- [Sources](#sources)

## Choosing a batch method

| Task | Method | Costs |
|---|---|---|
| Same change to rows chosen by a condition | DQL `UPDATE` or `DELETE`, or DBAL `executeStatement()` | No hydration, fastest. Skips events, listeners, locking and the version column. Loaded entities go stale |
| Per-row PHP logic over a large table | `toIterable()` plus `flush()` and `clear()` every N rows | Memory stays flat. Slower than bulk SQL |
| Millions of rows, or a run that must resume | Keyset pagination plus `clear()` | Restartable from the last id |
| Huge one-off load | The database's own bulk tool | The ORM docs recommend it when the options above are not enough |

## The flush and clear loop

```php
$batchSize = 20;
$i = 0;

foreach ($em->createQuery('SELECT o FROM App\Entity\Order o')->toIterable() as $order) {
    $order->markExported();

    if (0 === ++$i % $batchSize) {
        $em->flush();
        $em->clear();
    }
}

$em->flush();
$em->clear();
```

The Doctrine example uses 20. Larger batches reuse prepared statements but make each `flush()` do more work. Measure on realistic rows.

Why `clear()`: every managed entity stays in the identity map and is compared with its snapshot at each `flush()`, so memory and flush time grow with the unit of work. `clear()` empties both.

`toIterable()` yields the entity directly (the removed `iterate()` wrapped each one in an array). The ORM docs still show `detach($row[0])` in the read-only example, which belongs to the old shape. Prefer `clear()` per batch.

## Keyset pagination

For very large tables, or runs that must be resumable, page on the primary key instead of an offset. An offset gets slower with depth and skips or repeats rows when the data under it changes.

```php
$last = 0;

while (true) {
    $orders = $em->createQuery('SELECT o FROM App\Entity\Order o WHERE o.id > :last ORDER BY o.id')
        ->setParameter('last', $last)
        ->setMaxResults(100)
        ->getResult();

    if ([] === $orders) {
        break;
    }

    foreach ($orders as $order) {
        $order->markExported();
        $last = $order->getId();
    }

    $em->flush();
    $em->clear();
}
```

Log `$last` so a crashed run restarts from there.

## Batch pitfalls

- `clear()` detaches everything, including entities you still hold in variables. Edits to a detached entity are silently not saved (reproduced). Re-fetch any parent you still need after a `clear()`.
- `toIterable()` is not possible with a fetch-joined collection. A to-one fetch join works.
- The database client can buffer the full result set outside PHP's memory accounting. A huge `toIterable()` can still kill the process.
- A DQL `UPDATE` leaves already loaded entities stale and does not bump the version column. `clear()` and re-fetch if you keep working with them.
- Bulk DQL and DBAL skip lifecycle events and listeners. Anything that depended on them (audit log, search index, cache invalidation) must be done by hand.
- An enabled SQL logger costs speed and memory in a batch. DoctrineBundle's profiling follows the kernel debug flag, so run batch commands with `APP_DEBUG=0` (or in `prod`).
- Do not call `flush()` per row. Each flush is a transaction.

## Messenger Doctrine pieces

All four middleware ids and the subscriber come from the Doctrine bridge and DoctrineBundle, so DoctrineBundle with Messenger installed is enough.

| Piece | Type | What it does |
|---|---|---|
| `doctrine_ping_connection` | middleware | Before each message consumed by a worker: run a dummy query, reconnect if it fails, and reset the manager if it is closed |
| `doctrine_close_connection` | middleware | After each worker-consumed message: close the connection, so idle workers hold no connection |
| `doctrine_open_transaction_logger` | middleware | Logs an error when a handler opened a transaction and did not close it |
| `doctrine_transaction` | middleware | One transaction around all handlers of the message. Flushes at the end, rolls back on error. Handlers do not call `flush()`. Takes an entity manager name as an argument |
| `DoctrineClearEntityManagerWorkerSubscriber` | event subscriber | Clears every manager after a message is handled and after it fails. Registered as `doctrine.orm.messenger.event_subscriber.doctrine_clear_entity_manager` |

There is no `doctrine_clear_entity_manager` middleware. DoctrineBundle defines abstract middleware services for the four ids above only. The string is the tail of the subscriber's service id.

The ping and close middleware act only on messages consumed by a worker (they check for the worker stamp), so they do nothing for `sync` dispatches in a web request.

## Worker setup

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

- If the middleware list is written by hand, `dispatch_after_current_bus` goes before `doctrine_transaction`, and it must be loaded on every bus in use. It is on by default.
- To use another entity manager: `- doctrine_transaction: ['custom']`.
- Run the consumer bounded, under a process manager: `messenger:consume async --limit=... --memory-limit=128M --time-limit=3600`, and `--failure-limit` to quit after repeated errors. The docs name the Doctrine EntityManager as a service that grows over time.
- Restart workers on deploy with `messenger:stop-workers`.
- Messages carry ids and simple data. Passing an entity gives errors related to the EntityManager.

## What goes wrong in a worker

| Symptom | Cause | Fix |
|---|---|---|
| `EntityManagerClosed` on every message after one failure | A failed flush closed the manager and nothing reset it | `doctrine_ping_connection` on the bus. Check it is listed on the bus the worker consumes |
| "MySQL server has gone away" or a lost connection after idle time | The connection died between messages | `doctrine_ping_connection`. Keep `doctrine_close_connection` if workers idle for long |
| A handler sees old data for a row another process changed | The manager is cleared between messages, but a long handler or a loop inside one message keeps its identity map | `refresh()` the entity, or `clear()` inside the loop |
| Memory grows until the worker is killed | A big identity map inside one handler, or stateful services | Clear in batches. Services with state implement `ResetInterface`. Keep `--memory-limit` as the backstop |
| After a retry, a handler that already succeeded runs again | One handler failed and `doctrine_transaction` rolled all handlers back, then removed the handled stamps so the retry runs them all | Expected. Keep handlers idempotent |
| Welcome mail sent although the user insert rolled back | A side effect ran inside the transaction | Dispatch it with `DispatchAfterCurrentBusStamp` (the `dispatch_after_current_bus` middleware is on by default) so it runs after the transaction commits |

## Sources

- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/batch-processing.html
- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/unitofwork.html (flush cost, read-only entities)
- https://github.com/doctrine/orm/blob/3.7.x/UPGRADE.md (`iterate()` removed, `toIterable()` yields entities)
- https://symfony.com/doc/current/messenger.html (Middleware for Doctrine, Deploying to Production, `dispatch_after_current_bus`)
- Symfony source `src/Symfony/Bridge/Doctrine/Messenger/` (branches 7.4 and 8.0) and DoctrineBundle `config/messenger.php` (what each piece does, the subscriber id)

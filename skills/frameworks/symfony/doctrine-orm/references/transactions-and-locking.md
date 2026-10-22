# Transactions and locking

## Contents

- [Who owns the transaction](#who-owns-the-transaction)
- [After an exception](#after-an-exception)
- [Retrying a deadlock](#retrying-a-deadlock)
- [Optimistic locking](#optimistic-locking)
- [Pessimistic locking](#pessimistic-locking)
- [Choosing a strategy](#choosing-a-strategy)
- [Sources](#sources)

## Who owns the transaction

| Call | Flushes the EM | Closes the EM on exception | Notes |
|---|---|---|---|
| `$em->flush()` alone | yes | yes | Wraps all queued writes in one transaction. Enough when everything goes through the ORM |
| `$em->wrapInTransaction($fn)` | yes, before commit | yes | The callback receives the EM and its return value is returned. Use for ORM plus DBAL work in one unit |
| `$connection->transactional($fn)` | no | no | Plain DBAL. ORM changes made inside stay unflushed unless you flush yourself |
| Messenger `doctrine_transaction` | yes | no (flush failure still closes it) | Wraps all handlers of one message. Handlers do not flush |

`EntityManager::transactional()` no longer exists on ORM 3.

Keep transactions short. No HTTP calls, mail or queue publishes inside, because a rollback cannot undo them. For work that must happen only after commit, dispatch it after the transaction. In Messenger, dispatch with `DispatchAfterCurrentBusStamp`.

DBAL 4 nests transactions with savepoints. An inner `wrapInTransaction` therefore rolls back only to its savepoint, but the failed inner call has still closed the EntityManager.

## After an exception

Reproduced on ORM 3.7.5:

| Event | EntityManager state |
|---|---|
| Exception inside `wrapInTransaction` | closed, transaction rolled back |
| Failed `flush()` (constraint violation, `OptimisticLockException` at flush) | closed, transaction rolled back |
| `$em->clear()` on a closed EM | still closed |
| `find()`, `createQuery()`, repository reads on a closed EM | still work |
| `persist()`, `flush()`, `wrapInTransaction()` on a closed EM | throw `EntityManagerClosed` |
| `find($class, $id, LockMode::OPTIMISTIC, $wrongVersion)` mismatch | throws, EM stays open |

The silent part is that reads keep working, so the bug shows up later as a failed write. Rules:

- After a rollback, discard the EntityManager and every entity it managed. Their state is not rolled back and may not match the database.
- Get a fresh manager with `ManagerRegistry::resetManager()`, then `getManager()` again. Messenger's `doctrine_ping_connection` does exactly this when it finds a closed manager.
- Catch narrowly. If you catch `\Throwable` to log, rethrow. Swallowing the exception leaves a closed EM in a worker.
- In a request, let the exception reach the error handler: the process ends and the next request starts clean.

## Retrying a deadlock

DBAL's `DeadlockException` and `LockWaitTimeoutException` implement the marker `Doctrine\DBAL\Exception\RetryableException`: the whole transaction can be retried. Retry the whole unit, not the failed statement, and bound the attempts.

```php
for ($attempt = 1; ; ++$attempt) {
    try {
        $registry->getManager()->wrapInTransaction(function (EntityManagerInterface $em): void {
            // load, change, persist
        });

        break;
    } catch (RetryableException $e) {
        $registry->resetManager();

        if ($attempt >= 3) {
            throw $e;
        }
    }
}
```

Inside a Messenger handler do not loop: let the exception propagate and the retry strategy of the transport redelivers the message. The handler must be idempotent.

## Optimistic locking

Map a version column. The type must be explicit: `#[Version, Column]` with no type fails at mapping load on ORM 3.7.5 with a `TypeError` from `MappingException`.

```php
#[ORM\Version, ORM\Column(type: 'integer')]
private int $version = 1;
```

The pitfall is comparing the wrong version. Doctrine compares the version the entity was loaded with to the database at flush. If the POST handler re-reads the row and flushes, it compares the fresh version to itself and a concurrent edit is overwritten.

Correct flow:

1. GET: render the entity's current version into the form (hidden field or session).
2. POST: `$em->find(Post::class, $id, LockMode::OPTIMISTIC, $versionFromForm)`. A mismatch throws `OptimisticLockException` at once.
3. Change the entity and `flush()`. A conflict at flush also throws `OptimisticLockException` and closes the EM.
4. On conflict, show the user both versions or reload in a fresh EM and retry.

Reproduced: `find` with version 0 against stored version 1 throws immediately (EM stays open). A flush after another writer bumped the version throws and the EM is closed.

DQL `UPDATE` does not increment the version column and skips locking, so a bulk update defeats optimistic locking for those rows.

## Pessimistic locking

Needs a transaction. Outside one, `find(..., LockMode::PESSIMISTIC_WRITE)` throws `TransactionRequiredException`.

```php
$em->wrapInTransaction(function (EntityManagerInterface $em) use ($id): void {
    $account = $em->find(Account::class, $id, LockMode::PESSIMISTIC_WRITE);
    $account->debit(100);
});
```

| Mode | Effect |
|---|---|
| `PESSIMISTIC_WRITE` | Locks the rows against concurrent read and write operations |
| `PESSIMISTIC_READ` | Blocks others from updating or write-locking the rows |

Usable with `find()`, `lock()`, `refresh()` and `Query::setLockMode()`.

- `find()` with a pessimistic mode on an entity already in the identity map refreshes it under the lock, so you read current data. `lock($entity, PESSIMISTIC_WRITE)` only locks the row: the entity keeps whatever state it had. If you loaded it earlier, call `refresh($entity, LockMode::PESSIMISTIC_WRITE)` or `find` with the mode.
- Lock rows in a fixed order (by id) across code paths. Opposite orders cause deadlocks.
- For queue-like work, DBAL 4.5 has `QueryBuilder::forUpdate(ConflictResolutionMode::SKIP_LOCKED)`. It has no NOWAIT mode. Doctrine's own lock modes cover only read and write.
- SQLite ignores row locks, so a local test on SQLite proves only the transaction requirement. Test lock behavior on the production engine.

## Choosing a strategy

| Situation | Choose |
|---|---|
| Edit forms, user think time, conflicts are rare | Optimistic with a version carried from the form |
| Read, decide, write inside one short transaction on a hot row (balance, stock) | Pessimistic write |
| Many workers claiming rows from a table | `SKIP_LOCKED` through DBAL |
| Counter or total updated from many places | A single `UPDATE ... SET n = n + 1` through DBAL or DQL (remember the version column is skipped) |

## Sources

- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/transactions-and-concurrency.html
- https://www.doctrine-project.org/projects/doctrine-orm/en/3.7/reference/dql-doctrine-query-language.html (DQL `UPDATE` warning)
- https://github.com/doctrine/orm/blob/3.7.x/UPGRADE.md (`transactional()` removal, `LockMode::NONE`)
- https://github.com/doctrine/dbal/blob/4.5.x/UPGRADE.md (savepoint nesting)
- https://github.com/doctrine/dbal/blob/4.5.x/src/Exception/RetryableException.php
- https://symfony.com/doc/current/messenger.html (`doctrine_transaction`, `doctrine_ping_connection`, `dispatch_after_current_bus`)

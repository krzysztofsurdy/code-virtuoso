# Symfony Lock Component

The Lock component creates and manages locks that give exclusive access to a shared resource. Use it to stop an operation from running at the same time in several processes or on several servers, which prevents race conditions and resource conflicts.

## Contents

- [Installation](#installation)
- [Core concepts](#core-concepts)
- [Lock acquisition methods](#lock-acquisition-methods)
- [Expiring locks (TTL)](#expiring-locks-ttl)
- [Shared (read-write) locks](#shared-read-write-locks)
- [Checking lock status](#checking-lock-status)
- [Serializing locks](#serializing-locks)
- [Auto-release](#auto-release)
- [Available lock stores](#available-lock-stores)
- [Store configuration](#store-configuration)
- [Common use cases](#common-use-cases)
- [Reliability](#reliability)
- [Key interfaces and classes](#key-interfaces-and-classes)

## Installation

```bash
composer require symfony/lock
```

## Core concepts

### Lock factory and stores

Create locks with `LockFactory` and a store backend:

```php
use Symfony\Component\Lock\LockFactory;
use Symfony\Component\Lock\Store\SemaphoreStore;

$store = new SemaphoreStore();
$factory = new LockFactory($store);
```

### Basic lock operations

```php
$lock = $factory->createLock('pdf-creation');

if ($lock->acquire()) {
    try {
        // Perform critical operation
    } finally {
        $lock->release();
    }
}
```

## Lock acquisition methods

### Non-blocking acquisition

Returns immediately: true if the lock was acquired, false otherwise.

```php
if ($lock->acquire()) {
    // Lock acquired
} else {
    // Could not acquire lock
}
```

### Blocking acquisition

Waits until the lock is available, with no timeout:

```php
$lock->acquire(true);  // Blocks until acquired
// Lock is now held
```

## Expiring locks (TTL)

A time to live (TTL) releases the lock automatically after a timeout, which prevents deadlocks:

```php
$lock = $factory->createLock('pdf-creation', ttl: 30);

if ($lock->acquire()) {
    try {
        // Must complete within 30 seconds
    } finally {
        $lock->release();
    }
}
```

### Refreshing locks

Extend the TTL for long-running tasks:

```php
$lock->refresh();        // Reset to original TTL
$lock->refresh(600);     // Reset to custom TTL (600 seconds)
```

### Checking the remaining lifetime

```php
$remaining = $lock->getRemainingLifetime();  // Returns float in seconds

if ($lock->getRemainingLifetime() <= 5) {
    if ($lock->isExpired()) {
        throw new RuntimeException('Lock lost during process');
    }
    $lock->refresh();
}
```

## Shared (read-write) locks

Many readers can hold the lock at once, while a writer gets exclusive access:

```php
$lock = $factory->createLock('user-'.$userId);

// Acquire read lock (multiple concurrent readers allowed)
if ($lock->acquireRead()) {
    try {
        // Read operation
    } finally {
        $lock->release();
    }
}

// Promote read lock to write lock (exclusive access)
$lock->acquire(true);
```

## Checking lock status

```php
if ($lock->isAcquired()) {
    // Current process still owns the lock
}

if ($lock->isExpired()) {
    // Lock has expired
}

$remaining = $lock->getRemainingLifetime();  // null if no TTL
```

## Serializing locks

Share a lock across processes with the `Key` object:

```php
use Symfony\Component\Lock\Key;

$key = new Key('article.'.$article->getId());
$lock = $factory->createLockFromKey($key, 300, false);

$lock->acquire(true);

// Dispatch to another process with the serialized key
$this->bus->dispatch(new RefreshTaxonomy($article, $key));
```

## Auto-release

By default, a lock is released when the object is destroyed. Disable this for locks that must outlive the request:

```php
$lock = $factory->createLock('resource', 3600, false);  // autoRelease=false
```

## Available lock stores

| Store | Type | Blocking | Expiring | Sharing | Serialization |
|-------|------|----------|----------|---------|---------------|
| FlockStore | Local | Yes | No | Yes | No |
| SemaphoreStore | Local | Yes | No | No | No |
| RedisStore | Remote | Retry | Yes | Yes | Yes |
| PostgreSqlStore | Remote | Yes | No | Yes | No |
| PdoStore | Remote | Retry | Yes | No | Yes |
| MemcachedStore | Remote | Retry | Yes | No | Yes |
| DoctrineDbalStore | Remote | Retry | Yes | No | Yes |
| MongoDbStore | Remote | Retry | Yes | No | Yes |
| ZookeeperStore | Remote | Retry | No | No | No |
| DynamoDbStore | Remote | Retry | Yes | No | Yes |
| CombinedStore | Remote | Varies | Yes | Yes | Yes |

## Store configuration

### FlockStore (file-based)

Uses the local filesystem:

```php
use Symfony\Component\Lock\Store\FlockStore;

$store = new FlockStore('/var/stores');
$factory = new LockFactory($store);
```

### SemaphoreStore (semaphore-based)

Uses System V IPC semaphores:

```php
use Symfony\Component\Lock\Store\SemaphoreStore;

$store = new SemaphoreStore();
```

### RedisStore

Remote locks in Redis:

```php
use Symfony\Component\Lock\Store\RedisStore;

$redis = new \Redis();
$redis->connect('localhost', 6379);
$store = new RedisStore($redis);
```

### PostgreSqlStore

Uses PostgreSQL advisory locks:

```php
use Symfony\Component\Lock\Store\PostgreSqlStore;

$store = new PostgreSqlStore('pgsql:host=localhost;dbname=app', [
    'db_username' => 'user',
    'db_password' => 'pass'
]);
```

### PdoStore

Works with any PDO-supported database:

```php
use Symfony\Component\Lock\Store\PdoStore;

$store = new PdoStore('mysql:host=127.0.0.1;dbname=app', [
    'db_username' => 'user',
    'db_password' => 'pass'
]);
```

### MemcachedStore

Remote locks in Memcached:

```php
use Symfony\Component\Lock\Store\MemcachedStore;

$memcached = new \Memcached();
$memcached->addServer('localhost', 11211);
$store = new MemcachedStore($memcached);
```

### CombinedStore (high availability)

Applies a consensus strategy across several stores:

```php
use Symfony\Component\Lock\Store\CombinedStore;
use Symfony\Component\Lock\Strategy\ConsensusStrategy;

$stores = [];
foreach (['server1', 'server2', 'server3'] as $server) {
    $redis = new \Redis();
    $redis->connect($server);
    $stores[] = new RedisStore($redis);
}

$store = new CombinedStore($stores, new ConsensusStrategy());
$factory = new LockFactory($store);
```

## Common use cases

### Background jobs

Prevent a job from running twice at once:

```php
$lock = $factory->createLock('send-emails', ttl: 300);

if (!$lock->acquire()) {
    return;  // Another process is already running
}

try {
    while ($hasMoreEmails) {
        if ($lock->getRemainingLifetime() <= 30) {
            $lock->refresh();
        }
        sendEmailBatch();
    }
} finally {
    $lock->release();
}
```

### Synchronizing resource updates

Make a resource update atomic:

```php
$lock = $factory->createLock('user-profile-'.$userId, ttl: 10);

if ($lock->acquire()) {
    try {
        $user = getUserFromDatabase($userId);
        $user->updateLastSeen();
        saveUserToDatabase($user);
    } finally {
        $lock->release();
    }
}
```

### Read-write operations

Many readers, one exclusive writer:

```php
$cacheLock = $factory->createLock('article-cache-'.$articleId);

// Reader process
if ($cacheLock->acquireRead()) {
    try {
        $cached = getCachedArticle($articleId);
    } finally {
        $cacheLock->release();
    }
}

// Writer process
if ($cacheLock->acquire(true)) {
    try {
        cacheArticle($articleId, $article);
    } finally {
        $cacheLock->release();
    }
}
```

## Reliability

### Clock synchronization

When expiring locks are used across several servers, keep all nodes' clocks synchronized (for example with NTP).

### Token-based ownership

Remote stores use unique tokens to verify who owns a lock, so a process cannot release a lock it does not hold.

### Store-specific behavior

- **FlockStore**: all processes must use the same physical filesystem.
- **Redis/Memcached**: in-memory, so locks are lost on restart.
- **PostgreSQL**: locks are released when the session ends.
- **Database stores**: need network connectivity, so handle connection failures.
- **CombinedStore**: needs consensus between its stores.

### Long-running operations

Check the remaining lifetime and refresh the lock before it expires:

```php
$lock = $factory->createLock('process', ttl: 60);

if (!$lock->acquire()) {
    return;
}

try {
    while (!$finished) {
        // Leave 10-second buffer for refresh
        if ($lock->getRemainingLifetime() <= 10) {
            if ($lock->isExpired()) {
                throw new RuntimeException('Lost lock during operation');
            }
            $lock->refresh();
        }

        // Perform work
        doWork();
    }
} finally {
    $lock->release();
}
```

## Key interfaces and classes

- **LockFactory**: creates locks from stores
- **LockInterface**: defines lock operations
- **StoreInterface**: the lock storage backend
- **Key**: serializable lock identifier
- **SharedLockInterface**: extends `LockInterface` with shared locks
- **BlockingStoreInterface**: marks a store that supports blocking
- **ExpiringStoreInterface**: marks a store that supports TTL

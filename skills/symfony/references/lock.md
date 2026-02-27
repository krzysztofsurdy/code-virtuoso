# Symfony Lock Component

Create and manage locks to provide exclusive access to shared resources. Useful for ensuring operations don't execute simultaneously across multiple processes or servers, preventing race conditions and resource conflicts.

## Installation

```bash
composer require symfony/lock
```

## Core Concepts

### Lock Factory and Stores

Create locks using `LockFactory` with a store backend:

```php
use Symfony\Component\Lock\LockFactory;
use Symfony\Component\Lock\Store\SemaphoreStore;

$store = new SemaphoreStore();
$factory = new LockFactory($store);
```

### Basic Lock Operations

Acquire and release locks:

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

## Lock Acquisition Methods

### Non-Blocking Acquisition

Returns immediately (true if acquired, false otherwise):

```php
if ($lock->acquire()) {
    // Lock acquired
} else {
    // Could not acquire lock
}
```

### Blocking Acquisition

Waits indefinitely until lock is available:

```php
$lock->acquire(true);  // Blocks until acquired
// Lock is now held
```

## Expiring Locks (TTL)

Set Time To Live to automatically release locks after a timeout, preventing deadlocks:

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

### Refreshing Locks

Extend TTL for long-running tasks:

```php
$lock->refresh();        // Reset to original TTL
$lock->refresh(600);     // Reset to custom TTL (600 seconds)
```

### Checking Remaining Lifetime

```php
$remaining = $lock->getRemainingLifetime();  // Returns float in seconds

if ($lock->getRemainingLifetime() <= 5) {
    if ($lock->isExpired()) {
        throw new RuntimeException('Lock lost during process');
    }
    $lock->refresh();
}
```

## Shared/Read-Write Locks

Allow multiple concurrent readers with exclusive write access:

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

## Lock Status Checking

```php
if ($lock->isAcquired()) {
    // Current process still owns the lock
}

if ($lock->isExpired()) {
    // Lock has expired
}

$remaining = $lock->getRemainingLifetime();  // null if no TTL
```

## Serializing Locks

Share locks across processes using the `Key` object:

```php
use Symfony\Component\Lock\Key;

$key = new Key('article.'.$article->getId());
$lock = $factory->createLockFromKey($key, 300, false);

$lock->acquire(true);

// Dispatch to another process with the serialized key
$this->bus->dispatch(new RefreshTaxonomy($article, $key));
```

## Auto-Release Control

By default, locks auto-release when destroyed. Disable for cross-request locks:

```php
$lock = $factory->createLock('resource', 3600, false);  // autoRelease=false
```

## Available Lock Stores

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

## Store Configuration

### FlockStore (File-Based)

Uses filesystem for local locks:

```php
use Symfony\Component\Lock\Store\FlockStore;

$store = new FlockStore('/var/stores');
$factory = new LockFactory($store);
```

### SemaphoreStore (Semaphore-Based)

Uses System V IPC semaphores:

```php
use Symfony\Component\Lock\Store\SemaphoreStore;

$store = new SemaphoreStore();
```

### RedisStore

Remote locks using Redis:

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

Uses any PDO-compatible database:

```php
use Symfony\Component\Lock\Store\PdoStore;

$store = new PdoStore('mysql:host=127.0.0.1;dbname=app', [
    'db_username' => 'user',
    'db_password' => 'pass'
]);
```

### MemcachedStore

Remote locks using Memcached:

```php
use Symfony\Component\Lock\Store\MemcachedStore;

$memcached = new \Memcached();
$memcached->addServer('localhost', 11211);
$store = new MemcachedStore($memcached);
```

### CombinedStore (High Availability)

Uses consensus strategy across multiple stores:

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

## Common Use Cases

### Background Job Execution

Prevent duplicate job execution:

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

### Resource Update Synchronization

Ensure atomic resource updates:

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

### Read-Write Operations

Multiple readers, exclusive writer:

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

## Reliability Considerations

### Clock Synchronization

When using expiring locks with multiple servers, ensure all nodes have synchronized clocks (use NTP).

### Token-Based Ownership

Remote stores use unique tokens to verify true lock ownership, preventing unauthorized releases.

### Store-Specific Behaviors

- **FlockStore**: All processes must access the same physical filesystem
- **Redis/Memcached**: In-memory; locks lost on restart
- **PostgreSQL**: Locks auto-release on session end
- **Database Stores**: Require network connectivity; handle gracefully
- **CombinedStore**: Requires consensus between stores for reliability

### Long-Running Operations

Monitor lock lifetime and refresh proactively:

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

## Key Interfaces and Classes

- **LockFactory**: Creates locks from stores
- **LockInterface**: Defines lock operations
- **StoreInterface**: Implements lock storage backend
- **Key**: Serializable lock identifier
- **SharedLockInterface**: Extends LockInterface for shared locks
- **BlockingStoreInterface**: Indicates store supports blocking
- **ExpiringStoreInterface**: Indicates store supports TTL

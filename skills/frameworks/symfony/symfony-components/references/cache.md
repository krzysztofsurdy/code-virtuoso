# Symfony Cache Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Two caching approaches](#two-caching-approaches)
- [Cache adapters](#cache-adapters)
- [Cache items](#cache-items)
- [Cache invalidation](#cache-invalidation)
- [Stampede prevention](#stampede-prevention)
- [PSR-6/PSR-16 interoperability](#psr-6psr-16-interoperability)
- [Marshalling (serialization)](#marshalling-serialization)
- [Sub-namespaces](#sub-namespaces)
- [Console commands](#console-commands)
- [Common use cases](#common-use-cases)
- [Best practices](#best-practices)

## Overview

The Cache component implements PSR-6 and also provides the simpler Cache Contracts API, which has built-in stampede prevention. It supports several backends (filesystem, Redis, Memcached, APCu, PDO, and more) and offers tag-based invalidation.

## Installation

```bash
composer require symfony/cache
```

## Two caching approaches

### Cache Contracts (recommended)

A smaller API with automatic stampede prevention:

```php
use Symfony\Component\Cache\Adapter\FilesystemAdapter;
use Symfony\Contracts\Cache\ItemInterface;

$cache = new FilesystemAdapter();

$value = $cache->get('my_cache_key', function (ItemInterface $item): string {
    $item->expiresAfter(3600);
    return 'computed_value';
});

$cache->delete('my_cache_key');
```

**Features:**
- Only two methods: `get()` and `delete()`
- Automatic cache stampede prevention via locking
- Probabilistic early expiration support (beta parameter)
- Less boilerplate

### PSR-6 interface

Explicit item and pool management:

```php
use Symfony\Component\Cache\Adapter\FilesystemAdapter;

$cache = new FilesystemAdapter();

$item = $cache->getItem('stats.products_count');
if (!$item->isHit()) {
    $item->set(4711);
    $cache->save($item);
}

$cache->deleteItem('stats.products_count');
$cache->deleteItems(['key1', 'key2']);
$cache->clear();
```

## Cache adapters

### APCu adapter

Shared memory cache (in-process):

```php
use Symfony\Component\Cache\Adapter\ApcuAdapter;

$cache = new ApcuAdapter(
    $namespace = '',
    $defaultLifetime = 0,
    $version = null
);
```

**Pros:** Fastest cache, no external dependencies
**Cons:** Single server only, write-heavy workloads cause fragmentation, SAPI-dependent (CLI vs FPM)

### Filesystem adapter

File-based caching:

```php
use Symfony\Component\Cache\Adapter\FilesystemAdapter;

$cache = new FilesystemAdapter(
    $namespace = '',
    $defaultLifetime = 0,
    $directory = null  // Defaults to system temp directory
);

// Manual pruning of expired items
$cache->prune();
```

**Pros:** No external dependencies, simple to set up
**Cons:** Slower IO, not suitable for high-throughput scenarios

### Redis adapter

Distributed in-memory caching:

```php
use Symfony\Component\Cache\Adapter\RedisAdapter;

$client = RedisAdapter::createConnection('redis://localhost:6379');
$cache = new RedisAdapter($client, $namespace = '', $defaultLifetime = 0);
```

**DSN examples:**
```
redis://localhost:6379
redis://pass@localhost:6379/5
redis:?host[localhost]&host[localhost:6379]&redis_cluster=1
redis:?host[sentinel1:26379]&redis_sentinel=mymaster
```

**Features:** Tag-aware adapter available, marshalling options, cluster/sentinel support

**Redis configuration:**
```
maxmemory 100mb
maxmemory-policy allkeys-lru
```

### Memcached adapter

Distributed memory caching across several servers:

```php
use Symfony\Component\Cache\Adapter\MemcachedAdapter;

$client = MemcachedAdapter::createConnection('memcached://localhost');
$cache = new MemcachedAdapter($client, $namespace = '', $defaultLifetime = 0);

// Multiple servers
$client = MemcachedAdapter::createConnection([
    'memcached://server1',
    'memcached://server2',
]);
```

**Options:** `libketama_compatible`, `serializer` (php/igbinary), `hash`, `distribution`, `connect_timeout`

### PDO adapter

SQL database-backed caching:

```php
use Symfony\Component\Cache\Adapter\PdoAdapter;

$cache = new PdoAdapter(
    'sqlite:///var/cache.db',  // or PDO instance
    $namespace = '',
    $defaultLifetime = 0,
    $options = []
);

$cache->createTable();  // Create table explicitly
$cache->prune();        // Remove expired entries
```

### Chain adapter

Combine several adapters in layers:

```php
use Symfony\Component\Cache\Adapter\{ChainAdapter, ApcuAdapter, FilesystemAdapter};

$cache = new ChainAdapter([
    new ApcuAdapter(),        // Fast layer (in-memory)
    new FilesystemAdapter(),  // Slow layer (fallback)
]);

// Automatically propagates missing items from lower to upper adapters
```

### Other adapters

- **Array Adapter:** In-memory array (request-scoped)
- **Proxy Adapter:** Wrapper for custom implementations
- **Couchbase Adapters:** Couchbase bucket and collection backends

## Cache items

### Item keys and values

**Keys:** Alphanumeric, underscore, period only (A-Z, a-z, 0-9, _, .)

**Values:** Any PHP-serializable type (strings, objects, arrays, scalars)

### Item configuration

```php
use Symfony\Contracts\Cache\ItemInterface;

$value = $cache->get('key', function (ItemInterface $item): mixed {
    // Set expiration duration (seconds)
    $item->expiresAfter(3600);

    // Or set exact expiration time
    $item->expiresAt(new \DateTime('tomorrow'));

    // Add tags for batch invalidation
    $item->tag('products');
    $item->tag(['users', 'dashboard']);

    return 'computed_value';
});
```

### Cache hits and misses

```php
$item = $cache->getItem('latest_news');

if (!$item->isHit()) {
    // Cache miss - compute value
    $item->set('fresh_news');
    $cache->save($item);
} else {
    // Cache hit - retrieve value
    $value = $item->get();
}
```

## Cache invalidation

### Tag-based invalidation

Invalidate several cache entries at once using tags:

```php
$cache->get('products_1', function (ItemInterface $item) {
    $item->tag('products');
    return [...];
});

$cache->get('products_2', function (ItemInterface $item) {
    $item->tag('products');
    return [...];
});

// Invalidate all items with 'products' tag
$cache->invalidateTags(['products']);
```

### Tag-aware adapters

Use a tag-aware wrapper or an adapter built for tags:

```php
use Symfony\Component\Cache\Adapter\{FilesystemAdapter, RedisAdapter, TagAwareAdapter};

// General tag-aware wrapper
$cache = new TagAwareAdapter(
    new FilesystemAdapter(),  // Items storage
    new RedisAdapter(...)     // Tags storage (optional)
);

// Optimized implementations
$cache = new FilesystemTagAwareAdapter();
$cache = new RedisTagAwareAdapter($redisClient);

// Manual pruning
$cache->prune();
```

### Expiration-based invalidation

Set a TTL so items expire automatically:

```php
$item->expiresAfter(3600);     // 1 hour
$item->expiresAt($dateTime);   // Specific date
```

## Stampede prevention

A cache stampede happens when many requests hit an expired entry at the same time. Cache Contracts prevent it automatically:

```php
use Symfony\Contracts\Cache\ItemInterface;

// Beta parameter controls early recomputation
$value = $cache->get('expensive_data', function (ItemInterface $item) {
    $item->expiresAfter(3600);
    return compute_expensive_value();
}, $beta = 1.0);
```

**How it works:**
- Locking prevents simultaneous recomputation
- Beta parameter enables probabilistic early expiration
- Higher beta = earlier recomputation window

## PSR-6/PSR-16 Interoperability

Convert between PSR-6 and PSR-16:

```php
use Symfony\Component\Cache\Adapter\{Psr16Adapter, FilesystemAdapter};
use Symfony\Component\Cache\Psr16Cache;

// PSR-16 to PSR-6
$psr6Cache = new Psr16Adapter($psr16Cache);

// PSR-6 to PSR-16
$psr6Cache = new FilesystemAdapter();
$psr16Cache = new Psr16Cache($psr6Cache);
```

## Marshalling (serialization)

Control how data is serialized before storage:

```php
use Symfony\Component\Cache\Adapter\RedisAdapter;
use Symfony\Component\Cache\{DefaultMarshaller, DeflateMarshaller, SodiumMarshaller};

$cache = new RedisAdapter(
    $redisClient,
    'namespace',
    0,
    new DeflateMarshaller(new DefaultMarshaller())
);
```

**Available marshallers:**
- `DefaultMarshaller`: PHP serialization or Igbinary
- `DeflateMarshaller`: Compression wrapper
- `SodiumMarshaller`: Encryption wrapper
- `TagAwareMarshaller`: For tag-aware caching

## Sub-namespaces

Create cache variations that depend on context:

```php
$userCache = $cache->withSubNamespace(sprintf('user-%d', $userId));

$userCache->get('dashboard', function (ItemInterface $item) {
    return user_dashboard_data();
});
```

## Console commands

```bash
# Delete specific cache item
php bin/console cache:pool:delete cache.app my_key

# Clear specific cache pool(s)
php bin/console cache:pool:clear cache.app

# Prune expired entries
php bin/console cache:pool:prune
```

## Common use cases

### Query result caching

```php
$results = $cache->get('products_query', function (ItemInterface $item) {
    $item->expiresAfter(3600);
    $item->tag('products');
    return $this->db->query('SELECT * FROM products');
});
```

### Configuration caching

```php
$config = $cache->get('app_config', function (ItemInterface $item) {
    $item->expiresAfter(86400);
    return load_config_files();
});
```

### API response caching

```php
$data = $cache->get('external_api_' . md5($url), function (ItemInterface $item) {
    $item->expiresAfter(7200);
    $item->tag('external_apis');
    return fetch_api_data($url);
});
```

## Best practices

1. **Prefer Cache Contracts** over PSR-6: simpler code and built-in stampede prevention
2. **Use tags** to manage cache dependencies
3. **Set TTLs** that match how fresh the data must be
4. **Chain adapters** for a fast layer plus a fallback
5. **Use namespaces** to isolate cache contexts
6. **Prune regularly** for adapters that do not expire items on their own
7. **Monitor memory** in APCu and Redis, and set eviction policies
8. **Test hit and miss scenarios**
9. **Avoid write-heavy workloads** on APCu (fragmentation)
10. **Use marshalling** for encryption or compression

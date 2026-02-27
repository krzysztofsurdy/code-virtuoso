# Symfony Cache Component

## Overview

The Cache component is a powerful, standards-compliant caching framework implementing PSR-6 and providing the simpler Cache Contracts API with built-in stampede prevention. It supports multiple backends (filesystem, Redis, Memcached, APCu, PDO, and more) and enables efficient cache management with tag-based invalidation.

## Installation

```bash
composer require symfony/cache
```

## Two Caching Approaches

### Cache Contracts (Recommended)

Simpler, more powerful API with automatic stampede prevention:

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
- Less boilerplate code

### PSR-6 Interface

Explicit item/pool management:

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

## Cache Adapters

### APCu Adapter

High-performance shared memory cache (in-process):

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

### Filesystem Adapter

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

### Redis Adapter

Distributed in-memory caching:

```php
use Symfony\Component\Cache\Adapter\RedisAdapter;

$client = RedisAdapter::createConnection('redis://localhost:6379');
$cache = new RedisAdapter($client, $namespace = '', $defaultLifetime = 0);
```

**DSN Examples:**
```
redis://localhost:6379
redis://pass@localhost:6379/5
redis:?host[localhost]&host[localhost:6379]&redis_cluster=1
redis:?host[sentinel1:26379]&redis_sentinel=mymaster
```

**Features:** Tag-aware adapter available, marshalling options, cluster/sentinel support

**Redis Configuration:**
```
maxmemory 100mb
maxmemory-policy allkeys-lru
```

### Memcached Adapter

Distributed memory caching across multiple servers:

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

### PDO Adapter

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

### Chain Adapter

Combine multiple adapters in layered order:

```php
use Symfony\Component\Cache\Adapter\{ChainAdapter, ApcuAdapter, FilesystemAdapter};

$cache = new ChainAdapter([
    new ApcuAdapter(),        // Fast layer (in-memory)
    new FilesystemAdapter(),  // Slow layer (fallback)
]);

// Automatically propagates missing items from lower to upper adapters
```

### Other Adapters

- **Array Adapter:** In-memory array (request-scoped)
- **Proxy Adapter:** Wrapper for custom implementations
- **Couchbase Adapters:** Couchbase bucket and collection backends

## Cache Items

### Item Keys and Values

**Keys:** Alphanumeric, underscore, period only (A-Z, a-z, 0-9, _, .)

**Values:** Any PHP-serializable type (strings, objects, arrays, scalars)

### Item Configuration

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

### Cache Hits and Misses

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

## Cache Invalidation

### Tag-Based Invalidation

Invalidate multiple cache entries using tags:

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

### Tag-Aware Adapters

Use optimized tag-aware implementations:

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

### Expiration-Based Invalidation

Set TTL for automatic expiration:

```php
$item->expiresAfter(3600);     // 1 hour
$item->expiresAt($dateTime);   // Specific date
```

## Stampede Prevention

Cache stampede occurs when many requests hit expired cache simultaneously. Symfony prevents this automatically:

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

## Marshalling (Serialization)

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

**Available Marshallers:**
- `DefaultMarshaller`: PHP serialization or Igbinary
- `DeflateMarshaller`: Compression wrapper
- `SodiumMarshaller`: Encryption wrapper
- `TagAwareMarshaller`: For tag-aware caching

## Sub-Namespaces

Create context-dependent cache variations:

```php
$userCache = $cache->withSubNamespace(sprintf('user-%d', $userId));

$userCache->get('dashboard', function (ItemInterface $item) {
    return user_dashboard_data();
});
```

## Console Commands

```bash
# Delete specific cache item
php bin/console cache:pool:delete cache.app my_key

# Clear specific cache pool(s)
php bin/console cache:pool:clear cache.app

# Prune expired entries
php bin/console cache:pool:prune
```

## Common Use Cases

### Query Result Caching

```php
$results = $cache->get('products_query', function (ItemInterface $item) {
    $item->expiresAfter(3600);
    $item->tag('products');
    return $this->db->query('SELECT * FROM products');
});
```

### Configuration Caching

```php
$config = $cache->get('app_config', function (ItemInterface $item) {
    $item->expiresAfter(86400);
    return load_config_files();
});
```

### API Response Caching

```php
$data = $cache->get('external_api_' . md5($url), function (ItemInterface $item) {
    $item->expiresAfter(7200);
    $item->tag('external_apis');
    return fetch_api_data($url);
});
```

## Best Practices

1. **Prefer Cache Contracts** over PSR-6 for simpler code and built-in stampede prevention
2. **Use Tags** when managing complex cache dependencies
3. **Set Appropriate TTLs** based on data freshness requirements
4. **Chain Adapters** for optimal performance (fast + fallback)
5. **Use Namespaces** to isolate cache contexts
6. **Prune Regularly** for adapters that don't auto-expire
7. **Monitor Memory** in APCu/Redis with appropriate policies
8. **Test Cache** hit/miss scenarios in tests
9. **Avoid Write-Heavy** operations with APCu (fragmentation)
10. **Use Marshalling** for security or compression needs

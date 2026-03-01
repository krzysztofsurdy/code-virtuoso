# Caching Strategies

## Cache Layers in Depth

### L1: In-Process Cache

The fastest cache is memory within your own process. No network round-trip, no serialization. Use it for data that is read many times within a single request or a short time window.

**PHP:** `static array` property with null-check memoization. **Python:** `@functools.lru_cache(maxsize=N)` decorator. **TypeScript:** `Map<string, T>` with has/get/set pattern. **Java:** `ConcurrentHashMap.computeIfAbsent()` for thread-safe memoization.

**Pitfall:** In-process caches are per-instance. In a multi-server deployment, each instance has its own copy. Use L2 for shared data.

---

### L2: Distributed Cache

A shared cache accessible by all application instances. Redis and Memcached are the most common choices.

**PHP -- Symfony Cache with Redis:**
```php
$rate = $cache->get('exchange_rate_' . $currency, function (ItemInterface $item) use ($currency) {
    $item->expiresAfter(3600);
    return $this->exchangeApi->fetchRate($currency);
});
```

**Python -- Redis caching:**
```python
def get_rate(currency: str) -> float:
    cached = redis_client.get(f"exchange_rate:{currency}")
    if cached is not None:
        return float(cached)
    rate = fetch_from_api(currency)
    redis_client.setex(f"exchange_rate:{currency}", 3600, str(rate))
    return rate
```

**TypeScript:** Use `ioredis` with `get`/`setex` pattern. **Java:** Use `@Cacheable(value = "rates", key = "#currency")` with Spring Cache abstraction backed by Redis.

---

### HTTP Caching

HTTP caching prevents the request from reaching your server at all. Use `Cache-Control` headers to instruct browsers and proxies.

| Header | Purpose | Example |
|---|---|---|
| `Cache-Control: max-age=3600` | Browser caches for 1 hour | Static assets, public API data |
| `Cache-Control: no-cache` | Browser must revalidate every time | Dynamic content that changes frequently |
| `Cache-Control: private` | Only browser can cache, not shared proxies | User-specific data |
| `ETag` + `If-None-Match` | Conditional request -- server returns 304 if unchanged | Any cacheable resource |
| `Vary: Accept-Encoding` | Cache separate versions per encoding | Compressed vs uncompressed responses |

---

## Cache Invalidation Patterns

### TTL-Based Expiration

Set an expiration time and accept that data may be stale within that window. Simple and effective when perfect freshness is not required.

**Choosing TTL values:**
- Configuration data: minutes to hours (changes infrequently)
- User session data: match session timeout
- API response caches: seconds to minutes (depends on freshness requirements)
- Static assets: days to years (use versioned URLs for busting)

### Event-Based Invalidation

Clear or update the cache whenever the source data changes. More complex but ensures freshness.

**PHP:**
```php
public function updateProduct(Product $product): void
{
    $this->repository->save($product);
    $this->cache->delete('product_' . $product->getId());
    $this->cache->delete('product_list');
}
```

**Python:** Delete keys after save: `cache.delete(f"product:{product.id}")`. **TypeScript:** Same pattern with `await cache.del(key)`. **Java:** Use `@CacheEvict(value = "product", key = "#product.id")` annotation.

### Write-Through Cache

Every write updates both the cache and the database. Readers always get fresh data from cache.

Best for read-heavy workloads where consistency matters. Adds latency to writes since both stores must be updated.

### Write-Behind (Write-Back) Cache

Writes update the cache immediately. The backing store is updated asynchronously, often in batches. Gives fast write performance but risks data loss if the cache fails before flushing to the store.

---

## Cache Stampede Prevention

### Locking Approach

Only one request regenerates the expired value. Others either wait for the result or serve stale data.

**PHP -- Symfony lock-based approach:**
```php
$value = $cache->get('expensive_data', function (ItemInterface $item) {
    $item->expiresAfter(300);
    // Symfony's cache component handles stampede protection
    // internally using locking when beta parameter is set
    return $this->computeExpensiveData();
});
```

**Python -- Redis lock for cache regeneration:**
```python
def get_with_lock(key: str, compute_fn, ttl: int = 300) -> Any:
    value = cache.get(key)
    if value is not None:
        return value

    lock_key = f"lock:{key}"
    if cache.set(lock_key, "1", nx=True, ex=30):
        try:
            value = compute_fn()
            cache.setex(key, ttl, serialize(value))
            return value
        finally:
            cache.delete(lock_key)

    # Another process holds the lock -- wait briefly and retry
    time.sleep(0.1)
    return cache.get(key) or compute_fn()
```

### Probabilistic Early Recomputation

Each request approaching cache expiry independently decides whether to refresh early. The probability increases as expiry approaches, spreading regeneration across time and preventing a thundering herd.

**Pseudocode for the XFetch algorithm:**
```
function get_with_early_recompute(key, compute_fn, ttl, beta=1.0):
    value, expiry, compute_time = cache.get_with_metadata(key)

    if value is None or time_now() - (beta * compute_time * ln(random())) >= expiry:
        start = time_now()
        value = compute_fn()
        compute_time = time_now() - start
        cache.set(key, value, expiry=time_now() + ttl, compute_time=compute_time)

    return value
```

The `beta` parameter controls how aggressively early recomputation triggers. Higher values mean earlier recomputation, reducing stampede risk but increasing total recomputation work.

### Request Coalescing

Multiple concurrent requests for the same key are collapsed into a single backend call. The first request does the work; all others wait for and share the result.

**TypeScript -- Promise-based coalescing:**
```typescript
class CoalescingCache {
  private inflight = new Map<string, Promise<unknown>>();

  async get<T>(key: string, compute: () => Promise<T>): Promise<T> {
    const existing = this.inflight.get(key);
    if (existing) return existing as Promise<T>;

    const promise = compute().finally(() => this.inflight.delete(key));
    this.inflight.set(key, promise);
    return promise;
  }
}
```

**Java -- CompletableFuture coalescing:**
```java
public class CoalescingCache {
    private final ConcurrentHashMap<String, CompletableFuture<?>> inflight =
        new ConcurrentHashMap<>();

    @SuppressWarnings("unchecked")
    public <T> CompletableFuture<T> get(String key, Supplier<T> compute) {
        return (CompletableFuture<T>) inflight.computeIfAbsent(key, k ->
            CompletableFuture.supplyAsync(compute)
                .whenComplete((result, error) -> inflight.remove(k))
        );
    }
}
```

---

## Choosing a Strategy

| Scenario | Recommended Approach |
|---|---|
| Data changes rarely, staleness is OK | TTL-based expiration with L2 distributed cache |
| Data must be fresh after writes | Event-based invalidation on write operations |
| Single hot key with high concurrency | Locking or request coalescing to prevent stampedes |
| Predictable traffic, popular keys | Probabilistic early recomputation |
| User-specific data | L1 in-process cache scoped to the request, with L2 for cross-request sharing |
| Static assets | CDN with long TTL and versioned URLs for cache busting |
| API responses | HTTP caching with ETag and Cache-Control headers |

---
name: performance
description: Application performance optimization patterns — profiling strategies, caching layers, database query optimization, memory management, lazy loading, connection pooling, and N+1 prevention. Use when optimizing application speed, reducing latency, or diagnosing performance bottlenecks.
user-invocable: false
---

# Performance Optimization

Performance work follows one rule above all others: measure before you change anything. Intuition about bottlenecks is wrong more often than it is right. Every optimization should start with profiling, produce a hypothesis, apply a targeted fix, and verify with another measurement.

## Core Principles

| Principle | Meaning |
|---|---|
| **Measure first** | Never optimize without profiling data -- gut feelings about bottlenecks are unreliable |
| **Optimize the critical path** | Focus on the code that runs most frequently or blocks user-visible latency |
| **Set budgets** | Define acceptable latency, throughput, and resource usage before you start |
| **Avoid premature optimization** | Readable, correct code first -- optimize only when measurements show a real problem |
| **Know your tradeoffs** | Every optimization trades something (memory for speed, complexity for throughput, freshness for latency) |

---

## Profiling and Benchmarking

Profiling identifies where time and resources are spent. Without it, you are guessing.

### Types of Profiling

| Type | What It Reveals | When to Use |
|---|---|---|
| **CPU profiling** | Hot functions, call frequency, execution time distribution | Slow request handling, high CPU usage |
| **Memory profiling** | Allocation rates, heap size, object retention, leaks | Growing memory usage, OOM errors, GC pressure |
| **I/O profiling** | Disk reads/writes, network calls, blocking waits | Slow file operations, external service latency |
| **Database profiling** | Query execution time, query count per request, slow queries | High DB load, N+1 patterns, missing indexes |

### The Profiling Workflow

1. **Baseline** -- Capture metrics under normal conditions before any changes
2. **Identify** -- Find the hotspot consuming the most time or resources
3. **Hypothesize** -- Form a specific theory about why it is slow
4. **Fix** -- Apply a single, targeted change
5. **Verify** -- Measure again to confirm improvement and check for regressions

### Performance Budgets

Define limits that trigger action when exceeded:

- **Response time**: P50, P95, P99 latency targets per endpoint
- **Throughput**: Minimum requests per second under expected load
- **Resource usage**: CPU, memory, and connection limits per service
- **Page weight**: Maximum transfer size for frontend assets

See [Profiling Patterns Reference](references/profiling-patterns.md) for detailed profiling workflows, bottleneck signatures, and load testing strategies.

---

## Caching Strategies

Caching eliminates redundant computation and data fetching by storing results closer to where they are needed.

### Cache Layers

| Layer | Location | Latency | Use Case |
|---|---|---|---|
| **L1 -- In-process** | Application memory (object cache, memoization) | Nanoseconds | Hot data accessed many times per request |
| **L2 -- Distributed** | Redis, Memcached, shared cache | Sub-millisecond to low milliseconds | Data shared across application instances |
| **HTTP cache** | Browser, reverse proxy (Varnish, Nginx) | Zero network round-trip for client cache | Static assets, cacheable API responses |
| **CDN** | Edge servers worldwide | Low latency from geographic proximity | Static files, pre-rendered pages, media |
| **Database cache** | Query result cache, buffer pool | Varies | Repeated identical queries |

### Invalidation Approaches

| Strategy | How It Works | Best For |
|---|---|---|
| **TTL-based** | Cache entries expire after a fixed duration | Data that tolerates bounded staleness |
| **Event-based** | Cache is cleared when the source data changes | Data that must stay fresh after writes |
| **Write-through** | Writes update both the cache and the backing store simultaneously | Read-heavy workloads needing strong consistency |
| **Write-behind** | Writes update the cache immediately; backing store is updated asynchronously | High write throughput where eventual consistency is acceptable |

### Cache Stampede Prevention

When a popular cache key expires, many concurrent requests may all try to regenerate it at once, overwhelming the backend. Three approaches prevent this:

- **Locking** -- Only one request regenerates; others wait or serve stale data
- **Probabilistic early recomputation** -- Requests randomly refresh the cache before expiration, spreading regeneration over time
- **Request coalescing** -- Duplicate in-flight requests are collapsed into a single backend call

See [Caching Strategies Reference](references/caching-strategies.md) for implementation patterns with multi-language examples.

---

## Database Optimization

Database queries are the most common performance bottleneck in web applications.

### Index Strategy

- Create indexes on columns used in WHERE, JOIN, and ORDER BY clauses
- Use composite indexes that match your most frequent query patterns (leftmost prefix rule)
- Covering indexes include all columns a query needs, avoiding table lookups entirely
- Monitor unused indexes -- they slow down writes without helping reads

### N+1 Query Prevention

The N+1 problem occurs when code fetches a list of N records, then issues one additional query per record to load related data. Instead of 1 query, you execute N+1.

**Detection signals:**
- Query count scales linearly with result set size
- Many nearly identical queries differing only in a single parameter
- Profiler shows dozens or hundreds of queries for a single page load

**Prevention strategies:**
- Eager loading (JOIN or separate batch query upfront)
- Batch loading (collect IDs, fetch all related records in one query)
- DataLoader pattern (automatic batching and deduplication within a request)

### Connection Pooling

Opening a database connection is expensive (TCP handshake, authentication, TLS negotiation). Connection pools maintain a set of reusable connections:

- Size the pool based on expected concurrency -- too small causes queueing, too large overwhelms the database
- Always return connections to the pool promptly -- leaked connections exhaust the pool
- Set idle timeouts to reclaim unused connections
- Use external poolers (like PgBouncer for PostgreSQL) when application-level pooling is insufficient

See [Database Optimization Reference](references/database-optimization.md) for query patterns, explain plan analysis, and multi-language examples.

---

## Memory and Resource Management

### Memory Optimization Patterns

| Pattern | Description |
|---|---|
| **Object pooling** | Reuse expensive objects instead of allocating and discarding them |
| **Streaming** | Process large datasets as streams instead of loading everything into memory |
| **Lazy initialization** | Defer creation of expensive objects until they are actually needed |
| **Weak references** | Hold references that do not prevent garbage collection |
| **Buffer reuse** | Allocate buffers once and reuse them across operations |

### Lazy Loading

Lazy loading defers work until the result is actually needed. It reduces startup time and memory usage but adds complexity and can cause unexpected latency later.

**Where lazy loading helps:**
- Loading related database records only when accessed
- Initializing expensive service connections on first use
- Loading UI components or assets only when they become visible

**Where lazy loading hurts:**
- When the deferred work always happens anyway (just adds overhead)
- When it moves latency from a predictable startup phase to unpredictable user interactions
- When it creates N+1 query patterns (see Database Optimization above)

### Batch Operations

Replace individual operations with batch alternatives wherever possible:

- Batch inserts instead of inserting one row at a time
- Batch API calls instead of calling an external service N times
- Bulk file operations instead of processing files individually

---

## Quick Reference: Common Bottleneck Patterns

| Symptom | Likely Cause | First Investigation Step |
|---|---|---|
| Slow response times, low CPU | I/O waits (database, network, disk) | Profile I/O and check query logs |
| High CPU, normal response times | Inefficient algorithms or excessive computation | CPU profile to find hot functions |
| Growing memory over time | Memory leak (unreleased references, unbounded caches) | Heap dump comparison over time |
| Intermittent slowness under load | Resource contention (locks, connection pool exhaustion) | Check pool sizes and lock wait times |
| Fast locally, slow in production | Network latency, missing caches, different data volumes | Compare profiling data between environments |

---

## Reference Files

| Reference | Contents |
|---|---|
| [Caching Strategies](references/caching-strategies.md) | Cache layers, invalidation patterns, stampede prevention with multi-language examples |
| [Database Optimization](references/database-optimization.md) | Query optimization, N+1 prevention, connection pooling, batch operations with multi-language examples |
| [Profiling Patterns](references/profiling-patterns.md) | Profiling workflows, bottleneck signatures, performance budgets, load testing strategies |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Performance issues caused by poor architecture | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for clean architecture guidance |
| Need to refactor slow code paths | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for refactoring techniques |
| API response time optimization | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design principles |
| Database schema and query design | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies to verify optimizations |

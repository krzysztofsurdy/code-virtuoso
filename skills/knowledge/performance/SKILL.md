---
name: performance
description: "Profiling-driven performance optimization: caching, query tuning, N+1 fixes, memory, and load testing. Use to diagnose a bottleneck or set performance budgets."
allowed-tools: Read Grep Glob Bash
user-invocable: true
disable-model-invocation: true
---

# Performance Optimization

Performance work follows one rule: measure before you change anything. Intuition about bottlenecks is wrong more often than right. Every optimization starts with profiling, forms a hypothesis, applies a targeted fix, and ends with another measurement.

## Core principles

| Principle | Meaning |
|---|---|
| **Measure first** | Never optimize without profiling data. Gut feelings about bottlenecks are unreliable |
| **Optimize the critical path** | Focus on the code that runs most often or blocks user-visible latency |
| **Set budgets** | Define acceptable latency, throughput, and resource usage before you start |
| **Avoid premature optimization** | Write readable, correct code first. Optimize only when measurements show a real problem |
| **Know the tradeoffs** | Every optimization costs something (memory for speed, complexity for throughput, freshness for latency) |

---

## Profiling and benchmarking

Profiling shows where time and resources go. Without it you are guessing.

### Types of profiling

| Type | What it reveals | When to use |
|---|---|---|
| **CPU profiling** | Hot functions, call frequency, execution time distribution | Slow request handling, high CPU usage |
| **Memory profiling** | Allocation rates, heap size, object retention, leaks | Growing memory usage, OOM errors, GC pressure |
| **I/O profiling** | Disk reads/writes, network calls, blocking waits | Slow file operations, external service latency |
| **Database profiling** | Query execution time, query count per request, slow queries | High DB load, N+1 patterns, missing indexes |

### The profiling workflow

1. **Baseline**: capture metrics under normal conditions before any changes
2. **Identify**: find the hotspot using the most time or resources
3. **Hypothesize**: form a specific theory about why it is slow
4. **Fix**: apply a single, targeted change
5. **Verify**: measure again to confirm the improvement and check for regressions

### Performance budgets

Define limits that trigger action when exceeded:

- **Response time**: P50, P95, P99 latency targets per endpoint
- **Throughput**: Minimum requests per second under expected load
- **Resource usage**: CPU, memory, and connection limits per service
- **Page weight**: Maximum transfer size for frontend assets

See [Profiling Patterns Reference](references/profiling-patterns.md) for profiling workflows, bottleneck signatures, and load testing strategies.

---

## Caching strategies

Caching removes redundant computation and data fetching by storing results closer to where they are needed.

### Cache layers

| Layer | Location | Latency | Use case |
|---|---|---|---|
| **L1 - In-process** | Application memory (object cache, memoization) | Nanoseconds | Hot data accessed many times per request |
| **L2 - Distributed** | Redis, Memcached, shared cache | Sub-millisecond to low milliseconds | Data shared across application instances |
| **HTTP cache** | Browser, reverse proxy (Varnish, Nginx) | Zero network round-trip for client cache | Static assets, cacheable API responses |
| **CDN** | Edge servers worldwide | Low latency from geographic proximity | Static files, pre-rendered pages, media |
| **Database cache** | Query result cache, buffer pool | Varies | Repeated identical queries |

### Invalidation approaches

| Strategy | How it works | Best for |
|---|---|---|
| **TTL-based** | Cache entries expire after a fixed duration | Data that tolerates bounded staleness |
| **Event-based** | Cache is cleared when the source data changes | Data that must stay fresh after writes |
| **Write-through** | Writes update both the cache and the backing store at the same time | Read-heavy workloads needing strong consistency |
| **Write-behind** | Writes update the cache immediately; backing store is updated asynchronously | High write throughput where eventual consistency is acceptable |

### Cache stampede prevention

When a popular cache key expires, many concurrent requests may all try to regenerate it at once and overwhelm the backend. Three approaches prevent this:

- **Locking**: only one request regenerates; others wait or serve stale data
- **Probabilistic early recomputation**: requests randomly refresh the cache before expiration, spreading regeneration over time
- **Request coalescing**: duplicate in-flight requests are collapsed into a single backend call

See [Caching Strategies Reference](references/caching-strategies.md) for implementation patterns with multi-language examples.

---

## Database optimization

Database queries are the most common performance bottleneck in web applications.

### Index strategy

- Create indexes on columns used in WHERE, JOIN, and ORDER BY clauses
- Use composite indexes that match the most frequent query patterns (leftmost prefix rule)
- Covering indexes include all columns a query needs, so no table lookup is required
- Monitor unused indexes, since they slow down writes without helping reads

### N+1 query prevention

The N+1 problem occurs when code fetches a list of N records and then runs one more query per record to load related data. Instead of 1 query, it runs N+1.

**Detection signals:**
- Query count scales linearly with result set size
- Many nearly identical queries differing only in a single parameter
- Profiler shows dozens or hundreds of queries for a single page load

**Prevention strategies:**
- Eager loading (JOIN or separate batch query upfront)
- Batch loading (collect IDs, fetch all related records in one query)
- DataLoader pattern (batching and deduplication within a request)

### Connection pooling

Opening a database connection is expensive (TCP handshake, authentication, TLS negotiation). A connection pool keeps a set of reusable connections:

- Size the pool for expected concurrency: too small causes queueing, too large overwhelms the database
- Return connections to the pool as soon as the work is done, because leaked connections exhaust the pool
- Set idle timeouts to reclaim unused connections
- Use external poolers (like PgBouncer for PostgreSQL) when application-level pooling is not enough

See [Database Optimization Reference](references/database-optimization.md) for query patterns, explain plan analysis, and multi-language examples.

---

## Memory and resource management

### Memory optimization patterns

| Pattern | Description |
|---|---|
| **Object pooling** | Reuse expensive objects instead of allocating and discarding them |
| **Streaming** | Process large datasets as streams instead of loading everything into memory |
| **Lazy initialization** | Defer creation of expensive objects until they are needed |
| **Weak references** | Hold references that do not prevent garbage collection |
| **Buffer reuse** | Allocate buffers once and reuse them across operations |

### Lazy loading

Lazy loading defers work until the result is needed. It reduces startup time and memory use, but adds complexity and can cause surprise latency later.

**Where lazy loading helps:**
- Loading related database records only when accessed
- Initializing expensive service connections on first use
- Loading UI components or assets only when they become visible

**Where lazy loading hurts:**
- When the deferred work always happens anyway (it only adds overhead)
- When it moves latency from a predictable startup phase to unpredictable user interactions
- When it creates N+1 query patterns (see Database Optimization above)

### Batch operations

Replace individual operations with batch alternatives where possible:

- Batch inserts instead of inserting one row at a time
- Batch API calls instead of calling an external service N times
- Bulk file operations instead of processing files individually

---

## Quick reference: common bottleneck patterns

| Symptom | Likely cause | First investigation step |
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
| [Caching Strategies](references/caching-strategies.md) | Cache layers, invalidation patterns, stampede prevention, with multi-language examples |
| [Database Optimization](references/database-optimization.md) | Query optimization, N+1 prevention, connection pooling, batch operations, with multi-language examples |
| [Profiling Patterns](references/profiling-patterns.md) | Profiling workflows, bottleneck signatures, performance budgets, load testing strategies |

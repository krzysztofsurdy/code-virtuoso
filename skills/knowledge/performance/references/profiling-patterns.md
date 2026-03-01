# Profiling Patterns

## Types of Profiling

### CPU Profiling

Identifies which functions consume the most processing time. Look for hot paths -- functions called frequently or with high per-call cost.

**Common tools by language:**
- **PHP**: Xdebug (trace/profiling mode), SPX, Blackfire
- **Python**: cProfile, py-spy (sampling profiler), scalene
- **TypeScript/Node.js**: built-in `--prof` flag, clinic.js, 0x
- **Java**: JFR (Java Flight Recorder), async-profiler, VisualVM

**What to look for:**
- Functions that appear at the top of "self time" rankings
- Unexpected recursion or deeply nested call stacks
- Repeated computation that could be memoized
- String concatenation in tight loops (use builders instead)

### Memory Profiling

Tracks allocations, heap size, and object retention to find leaks and excessive memory use.

**PHP -- tracking memory within a process:**
```php
$before = memory_get_usage(true);
$result = $this->processLargeDataset($data);
$after = memory_get_usage(true);
$consumed = ($after - $before) / 1024 / 1024;
// Log if consumed exceeds threshold
```

**Python -- tracemalloc for allocation tracking:**
```python
import tracemalloc

tracemalloc.start()
process_large_dataset(data)
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics("lineno")
for stat in top_stats[:10]:
    print(stat)
```

**TypeScript -- Node.js heap snapshot:**
```typescript
import v8 from "node:v8";
import fs from "node:fs";

const snapshotPath = `/tmp/heap-${Date.now()}.heapsnapshot`;
v8.writeHeapSnapshot(snapshotPath);
// Load in Chrome DevTools for analysis
```

**Java -- programmatic heap info:**
```java
MemoryMXBean memoryBean = ManagementFactory.getMemoryMXBean();
MemoryUsage heapUsage = memoryBean.getHeapMemoryUsage();
long usedMb = heapUsage.getUsed() / (1024 * 1024);
```

**Memory leak indicators:**
- Memory usage grows steadily over time without leveling off
- Garbage collection runs more frequently but reclaims less
- Objects in heap dumps that should have been freed are still referenced
- Unbounded caches or collections that grow without eviction

### I/O Profiling

Measures time spent waiting on external resources: disk, network, database, APIs.

**Key metrics:**
- Time waiting for database query responses
- Time waiting for HTTP calls to external services
- Disk read/write latency and throughput
- DNS resolution time and TCP connection setup time

**Detection approach:**
- Wrap external calls with timing instrumentation
- Use distributed tracing (OpenTelemetry, Jaeger) to visualize where time is spent
- Look for sequential calls that could be parallelized

---

## The Profiling Workflow

### Step 1: Establish a Baseline

Before changing anything, measure current performance under realistic conditions.

**Baseline checklist:**
- Record response time percentiles (P50, P95, P99) for key endpoints
- Measure throughput (requests per second) at current load
- Capture resource usage (CPU, memory, connections) during normal operation
- Document query counts and external call counts per request
- Use production-like data volumes -- performance on 100 rows does not predict performance on 10 million

### Step 2: Identify the Bottleneck

Use profiling data to find the single largest contributor to latency or resource usage.

**The 80/20 rule applies:** A small number of code paths usually account for the majority of time. Focus on the biggest contributor first.

**Common identification techniques:**
- Sort functions by cumulative time in CPU profiles
- Look at flame graphs for wide (time-consuming) bars
- Check slow query logs for database bottlenecks
- Review trace waterfalls for long spans in distributed systems

### Step 3: Form a Hypothesis

Before writing code, state what you expect will improve and by how much. This forces clarity and makes verification possible.

Example: "The product listing page makes 47 queries per request due to N+1 loading. Switching to eager loading should reduce this to 2 queries and cut response time from 340ms to under 100ms."

### Step 4: Apply a Targeted Fix

Change one thing at a time. If you change multiple things simultaneously, you cannot attribute improvement to a specific change.

### Step 5: Verify Improvement

Measure again using the same methodology as the baseline. Confirm that:
- The target metric improved as expected
- No other metrics regressed
- The fix works under load, not just for a single request

---

## Common Bottleneck Signatures

| Signature | Likely Cause | Verification |
|---|---|---|
| CPU usage maxed, response time increases linearly with load | CPU-bound computation (inefficient algorithm, excessive serialization) | CPU profile shows a single hot function |
| Low CPU, high response time, many idle threads | I/O-bound (waiting on database, network, disk) | Trace shows long waits on external calls |
| Response time spikes periodically | Garbage collection pauses or scheduled background tasks | GC logs show long stop-the-world pauses |
| Latency increases suddenly at a specific load level | Resource exhaustion (connection pool, thread pool, file descriptors) | Pool metrics show full utilization and queuing |
| Memory grows until the process crashes | Memory leak (event listeners not removed, unbounded caches, circular references) | Heap comparison shows growing object counts |
| First request slow, subsequent requests fast | Cold start (JIT compilation, lazy initialization, empty caches) | Profile first vs subsequent request |

---

## Performance Budgets and SLOs

### Defining Performance Budgets

A performance budget is a threshold that triggers investigation or blocks deployment when exceeded.

| Budget Type | Example Threshold | Action When Exceeded |
|---|---|---|
| **API response time** | P95 < 200ms, P99 < 500ms | Investigate before deploying |
| **Page load time** | First Contentful Paint < 1.5s | Block deployment, optimize assets |
| **Bundle size** | JavaScript bundle < 200KB gzipped | Analyze imports, code-split |
| **Query count** | Max 10 queries per API request | Check for N+1, add eager loading |
| **Memory per request** | Peak < 128MB per PHP worker | Profile allocations, use streaming |

### Service Level Objectives (SLOs)

SLOs define the performance contract with your users. They are more formal than budgets and typically tracked over time windows.

**Structure:** `[metric] will be [threshold] for [percentage] of requests over [time window]`

**Examples:**
- "API latency P99 will be under 500ms for 99.9% of requests over any 30-day window"
- "Homepage load time will be under 2 seconds for 95% of users over any 7-day window"
- "Database query time will be under 100ms for 99% of queries over any 24-hour window"

**Error budgets:** If your SLO is 99.9% availability, you have a 0.1% error budget per month (~43 minutes of downtime). When the error budget is consumed, prioritize reliability work over features.

---

## Load Testing Strategies

### Types of Load Tests

| Test Type | Purpose | Duration |
|---|---|---|
| **Smoke test** | Verify the system works under minimal load | Minutes |
| **Load test** | Validate behavior at expected traffic levels | 15-60 minutes |
| **Stress test** | Find the breaking point by increasing load until failure | Until failure |
| **Soak test** | Detect memory leaks and degradation over extended operation | Hours to days |
| **Spike test** | Test response to sudden traffic bursts | Short bursts repeated |

### Load Testing Principles

1. **Test with production-like data** -- empty databases perform differently than full ones
2. **Ramp up gradually** -- sudden load does not reveal where the system starts struggling
3. **Monitor everything during the test** -- CPU, memory, connections, queue depths, error rates
4. **Test the whole path** -- include load balancers, caches, databases, and external services
5. **Automate and run regularly** -- performance regressions creep in between releases
6. **Establish pass/fail criteria before running** -- define what "acceptable" means in advance

### Interpreting Results

Look for these patterns in load test data:

- **Linear response time growth** with increasing load indicates a CPU or I/O bottleneck
- **Hockey stick curve** (flat then sudden spike) indicates resource exhaustion at a specific threshold
- **Gradual degradation over time at constant load** indicates a memory leak or connection leak
- **Error rate spike at a specific concurrency level** indicates pool or thread exhaustion

Compare results against your performance budgets and SLOs. If results are within budget, the system passes. If not, use the profiling workflow to investigate.

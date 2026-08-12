# Resilience Patterns

## Contents

- [Circuit Breaker](#circuit-breaker)
- [Bulkhead Pattern](#bulkhead-pattern)
- [Retry with exponential backoff and jitter](#retry-with-exponential-backoff-and-jitter)
- [Timeout patterns](#timeout-patterns)
- [Fallback strategies](#fallback-strategies)
- [Health checks and readiness probes](#health-checks-and-readiness-probes)

## Circuit Breaker

A circuit breaker monitors calls to a dependency and prevents further calls when failures exceed a threshold. It works like a switch that "trips" to protect both the caller and the failing dependency.

### States

| State | Behavior |
|---|---|
| **Closed** | Requests flow normally. Failures are counted. When the failure threshold is reached, the breaker transitions to Open. |
| **Open** | All requests fail immediately without calling the dependency. After a configured timeout, the breaker transitions to Half-Open. |
| **Half-Open** | A limited number of probe requests are allowed through. If they succeed, the breaker resets to Closed. If they fail, it returns to Open. |

### Configuration parameters

- **Failure threshold**: number or percentage of failures before opening (e.g., 5 failures in 60 seconds)
- **Reset timeout**: how long to wait in Open state before trying Half-Open (e.g., 30 seconds)
- **Probe count**: how many requests to allow in Half-Open state (e.g., 3)
- **Monitored exceptions**: which failure types count toward the threshold (not all errors should trip the breaker)

**PHP:**
```php
declare(strict_types=1);

final class CircuitBreaker
{
    private int $failures = 0;
    private string $state = 'closed';
    private float $lastFailureTime = 0;

    public function __construct(
        private int $threshold = 5,
        private int $resetTimeoutSeconds = 30,
    ) {}

    public function call(callable $operation): mixed
    {
        if ($this->state === 'open') {
            if (microtime(true) - $this->lastFailureTime < $this->resetTimeoutSeconds) {
                throw new CircuitOpenException('Circuit is open');
            }
            $this->state = 'half-open';
        }

        try {
            $result = $operation();
            $this->reset();
            return $result;
        } catch (\Throwable $e) {
            $this->recordFailure();
            throw $e;
        }
    }

    private function recordFailure(): void
    {
        $this->failures++;
        $this->lastFailureTime = microtime(true);
        if ($this->failures >= $this->threshold) {
            $this->state = 'open';
        }
    }

    private function reset(): void
    {
        $this->failures = 0;
        $this->state = 'closed';
    }
}
```

**Python:** Same structure using `time.monotonic()` for timing, `_state`/`_failures`/`_last_failure_time` fields, raising `CircuitOpenError` when open and timeout has not elapsed. **TypeScript:** Async `call<T>()` method with `Date.now()` for timing, same state machine logic with `recordFailure()` and `reset()` private methods. **Java:** Generic `call(Supplier<T>)` method using `System.currentTimeMillis()`, same three-state machine with `recordFailure()` and `reset()` methods.

---

## Bulkhead Pattern

The bulkhead pattern isolates components so that a failure in one does not drain resources from the others. It is named after the watertight compartments in a ship hull: one flooded compartment should not sink the vessel.

### Isolation strategies

| Strategy | Mechanism | Trade-off |
|---|---|---|
| **Thread pool isolation** | Each dependency gets its own thread pool with a fixed size | Strong isolation, but many thread pools add resource overhead |
| **Semaphore isolation** | Each dependency gets a concurrency semaphore limiting concurrent calls | Lightweight, but it shares the caller's thread, so a slow call still ties up a thread |
| **Process isolation** | Run dependencies in separate processes or containers | Strongest isolation but highest operational cost |

### Sizing considerations

- Set pool size based on expected concurrency for that dependency, not the overall system capacity
- Monitor rejection rates: a pool that is too small rejects legitimate traffic, and one that is too large gives weak isolation
- Combine with circuit breakers: the bulkhead limits concurrency while the circuit breaker detects systemic failures

---

## Retry with exponential backoff and jitter

Transient failures (network blips, brief overloads) often resolve on their own, and retrying after a short delay can hide them. Naive retries (immediate, fixed-interval) can make things worse by flooding a struggling dependency with more traffic.

### Exponential backoff

Each successive retry waits longer: `delay = base * 2^attempt`. This gives the dependency more time to recover with each attempt.

### The thundering herd problem

If many clients hit the same failure at the same time, they all retry on the same exponential schedule and reach the dependency in synchronized waves. Random jitter breaks the synchronization.

### Jitter strategies

| Strategy | Formula | Behavior |
|---|---|---|
| **Full jitter** | `random(0, base * 2^attempt)` | Maximum spread, lowest collision probability |
| **Equal jitter** | `(base * 2^attempt) / 2 + random(0, (base * 2^attempt) / 2)` | Guarantees a minimum delay, with randomization on top |
| **Decorrelated jitter** | `random(base, previous_delay * 3)` | Each delay is based on the previous one, which decorrelates clients |

**PHP:**
```php
declare(strict_types=1);

function retryWithBackoff(callable $operation, int $maxAttempts = 3, int $baseDelayMs = 100): mixed
{
    $lastException = null;

    for ($attempt = 0; $attempt < $maxAttempts; $attempt++) {
        try {
            return $operation();
        } catch (\Throwable $e) {
            $lastException = $e;
            if ($attempt < $maxAttempts - 1) {
                $maxDelay = $baseDelayMs * (2 ** $attempt);
                $delay = random_int(0, $maxDelay);
                usleep($delay * 1000);
            }
        }
    }

    throw $lastException;
}
```

**Python:** Same loop structure using `random.uniform(0, max_delay)` and `time.sleep()`. **TypeScript:** Async function with `Math.random() * maxDelay` passed to `setTimeout` via a Promise wrapper. **Java:** Loop with `ThreadLocalRandom.current().nextLong(0, maxDelay)` and `Thread.sleep(delay)`, accepting `Supplier<T>`.

---

## Timeout patterns

Every outbound call must have a timeout. Without one, a hung dependency can tie up the caller's resources indefinitely.

### Guidelines

- **Set timeouts on every external call**: HTTP requests, database queries, message broker operations
- **Use shorter timeouts for user-facing paths**: a user waiting 30 seconds for a page load will leave
- **Propagate deadline context**: pass a remaining-time budget through the call chain so downstream services know how much time is left
- **Distinguish connect timeout from read timeout**: a fast connect with a slow response points to a different problem than a refused connection

---

## Fallback strategies

When a dependency fails and cannot be retried, provide a reduced but working response instead of an error.

| Strategy | Example |
|---|---|
| **Cached fallback** | Return the last known good value from a local cache |
| **Default value** | Return a sensible default (e.g., default currency rate, empty recommendations list) |
| **Graceful degradation** | Disable the affected feature but keep the rest of the application running |
| **Queue for later** | Accept the request and process it asynchronously when the dependency recovers |

Fallbacks should be simple and not depend on the same failing resource. A fallback that calls another fragile dependency only moves the problem.

---

## Health checks and readiness probes

Container orchestrators and load balancers need to know whether a service instance is alive and ready to serve traffic.

| Check type | Purpose | What it verifies |
|---|---|---|
| **Liveness** | Is the process running and not deadlocked? | Basic health: responds to a ping, not stuck in an infinite loop |
| **Readiness** | Can this instance serve traffic right now? | Deeper health: database connection is live, caches are warm, dependencies are reachable |
| **Startup** | Has the service finished initializing? | One-time check: blocks traffic until initialization completes |

### Design principles

- Keep liveness checks lightweight: they run often and should not do expensive work
- Readiness checks should verify critical dependencies but have their own timeouts
- Never make a liveness check depend on an external service: if the database is down, the service is alive but not ready
- Return structured responses with individual component status so operators can diagnose partial failures

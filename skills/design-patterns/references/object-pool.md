# Object Pool Pattern

## Overview

The Object Pool pattern is a behavioral design pattern that improves performance by reusing objects instead of creating and destroying them repeatedly. Objects are created once and placed in a "pool" where they can be requested, used, and returned for reuse. This is especially valuable when instantiation is expensive, such as with database connections, thread pools, or large data structures.

## Intent

- Improve performance by reusing existing objects instead of creating new ones
- Reduce the overhead of object creation and garbage collection
- Maintain a collection of reusable objects that clients can acquire and return
- Control the number of active objects in the system
- Ensure efficient resource management in performance-critical applications

## Problem & Solution

### Problem

Creating objects can be expensive in terms of:

1. **CPU Overhead**: Instantiation requires time and processing power
2. **Memory Usage**: Creating many objects increases memory consumption and garbage collection pressure
3. **Connection Limits**: Systems like databases have finite connection pools
4. **Initialization Cost**: Some objects require complex initialization or setup
5. **Performance Bottlenecks**: In high-throughput scenarios, constant object creation becomes a bottleneck

### Solution

Maintain a pool of pre-created, reusable objects. When a client needs an object, instead of creating a new one, it requests an available object from the pool. After use, the object is returned to the pool for another client to use, reducing creation overhead.

## Structure

```
ObjectPool (manages the pool)
├── acquireObject(): ReusableObject
├── releaseObject(object: ReusableObject): void
└── objects: List<ReusableObject>

ReusableObject (the pooled object)
├── reset(): void
└── doWork(): void
```

## When to Use

- Object creation is expensive (database connections, thread pools, socket connections)
- Objects are frequently created and destroyed in your application
- You have performance-sensitive code where garbage collection pauses matter
- A limited number of objects can handle the system's workload
- Objects can be reset to a clean state for reuse
- You want to control resource consumption limits
- Working in multi-threaded environments where object reuse improves efficiency

## Implementation

### PHP 8.3+ Example: Database Connection Pool

```php
<?php
declare(strict_types=1);

// The reusable object
interface PoolableConnection {
    public function execute(string $sql): array;
    public function reset(): void;
    public function isAvailable(): bool;
}

class DatabaseConnection implements PoolableConnection {
    private bool $available = true;
    private string $lastQuery = '';

    public function __construct(private string $dsn) {}

    public function execute(string $sql): array {
        $this->available = false;
        $this->lastQuery = $sql;
        // Simulate database execution
        return ["Query executed: {$sql}"];
    }

    public function reset(): void {
        $this->available = true;
        $this->lastQuery = '';
    }

    public function isAvailable(): bool {
        return $this->available;
    }

    public function getDSN(): string {
        return $this->dsn;
    }
}

// The Object Pool
class ConnectionPool {
    /** @var array<PoolableConnection> */
    private array $available = [];
    /** @var array<PoolableConnection> */
    private array $inUse = [];
    private int $poolSize;
    private string $dsn;

    public function __construct(int $poolSize, string $dsn) {
        $this->poolSize = $poolSize;
        $this->dsn = $dsn;
        $this->initialize();
    }

    private function initialize(): void {
        for ($i = 0; $i < $this->poolSize; $i++) {
            $this->available[] = new DatabaseConnection($this->dsn);
        }
    }

    public function acquire(): PoolableConnection {
        if (empty($this->available)) {
            throw new RuntimeException('No connections available in pool');
        }

        $connection = array_pop($this->available);
        $this->inUse[spl_object_hash($connection)] = $connection;

        return $connection;
    }

    public function release(PoolableConnection $connection): void {
        $hash = spl_object_hash($connection);

        if (!isset($this->inUse[$hash])) {
            throw new RuntimeException('Connection not from this pool');
        }

        $connection->reset();
        unset($this->inUse[$hash]);
        $this->available[] = $connection;
    }

    public function getPoolStats(): array {
        return [
            'total' => $this->poolSize,
            'available' => count($this->available),
            'inUse' => count($this->inUse),
        ];
    }
}

// Usage
$pool = new ConnectionPool(5, 'postgresql://localhost/mydb');

try {
    $conn1 = $pool->acquire();
    $conn2 = $pool->acquire();

    echo implode(',', $conn1->execute('SELECT * FROM users')) . "\n";
    echo implode(',', $conn2->execute('SELECT * FROM posts')) . "\n";

    print_r($pool->getPoolStats()); // Shows 3 available, 2 in use

    $pool->release($conn1);
    $pool->release($conn2);

    print_r($pool->getPoolStats()); // Shows 5 available, 0 in use
} catch (RuntimeException $e) {
    echo "Error: " . $e->getMessage();
}
```

### Thread/Worker Pool Example

```php
<?php
declare(strict_types=1);

interface Worker {
    public function doWork(string $task): string;
    public function reset(): void;
}

class ThreadWorker implements Worker {
    private string $lastTask = '';

    public function doWork(string $task): string {
        $this->lastTask = $task;
        return "Completed: {$task}";
    }

    public function reset(): void {
        $this->lastTask = '';
    }
}

class WorkerPool {
    /** @var array<Worker> */
    private array $available = [];
    /** @var array<Worker> */
    private array $inUse = [];

    public function __construct(int $size) {
        for ($i = 0; $i < $size; $i++) {
            $this->available[] = new ThreadWorker();
        }
    }

    public function getWorker(): Worker {
        if (empty($this->available)) {
            throw new RuntimeException('No workers available');
        }
        $worker = array_pop($this->available);
        $this->inUse[spl_object_hash($worker)] = $worker;
        return $worker;
    }

    public function releaseWorker(Worker $worker): void {
        $hash = spl_object_hash($worker);
        if (isset($this->inUse[$hash])) {
            $worker->reset();
            unset($this->inUse[$hash]);
            $this->available[] = $worker;
        }
    }
}

// Usage
$pool = new WorkerPool(3);

$worker = $pool->getWorker();
echo $worker->doWork('process_image.jpg') . "\n";
$pool->releaseWorker($worker);
```

## Real-World Analogies

**Library Books**: A library maintains a pool of books. Instead of buying a new book each time someone wants to read, the library checks out existing books. Books are returned to the shelf for the next reader. This is more efficient than creating a new copy for each person.

**Car Rental Fleet**: A car rental company maintains a fleet of cars. Customers reserve available cars, use them, and return them. Creating a new car for each rental would be impractical; reusing cars is efficient.

**Swimming Pool Changing Rooms**: A swimming facility has a limited number of changing rooms. Visitors use a room, exit, and it's cleaned for the next visitor. Having one room per person would be wasteful.

## Pros and Cons

### Advantages
- **Performance Improvement**: Eliminates expensive object creation overhead
- **Memory Efficiency**: Reduces garbage collection pressure and memory consumption
- **Resource Control**: Limits the number of objects and resources in use
- **Predictable Behavior**: Pool size provides capacity guarantees
- **Reduced Latency**: Objects are ready to use immediately without initialization
- **Scalability**: Handles high-throughput scenarios effectively

### Disadvantages
- **Complexity**: More code to manage pool lifecycle and object reuse
- **Thread Safety**: Requires careful synchronization in multi-threaded environments
- **State Management**: Objects must be properly reset between uses
- **Memory Footprint**: Maintains all objects in memory even when unused
- **Debugging Difficulty**: Harder to diagnose issues with reused objects
- **Resource Leaks**: Forgetting to return objects can exhaust the pool

## Relations with Other Patterns

- **Singleton**: Pool managers are often implemented as Singletons
- **Factory Method**: Used to create objects initially for the pool
- **Strategy**: Pool implementations can vary (eager loading, lazy loading)
- **Flyweight**: Similar goal of sharing objects, but focuses on intrinsic/extrinsic state
- **Proxy**: Can wrap pooled objects to track acquisition and release
- **Observer**: Notify listeners when pool availability changes

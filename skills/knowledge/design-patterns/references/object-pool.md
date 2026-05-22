# Object Pool Pattern

## Overview

The Object Pool pattern is a creational design pattern that avoids the cost of repeated object construction and destruction by maintaining a reservoir of pre-built, reusable instances. When a client needs an object, it borrows one from the pool; when finished, it returns the object so the next client can use it. This recycling approach pays off most when instantiation is expensive - database connections, network sockets, heavyweight data structures, or thread handles.

## Intent

- Eliminate repeated construction and teardown costs by recycling existing instances
- Lower garbage-collection pressure by keeping a stable set of long-lived objects
- Provide a checkout/return lifecycle that lets clients share a bounded set of resources
- Cap the number of concurrently active instances to stay within system resource limits
- Deliver predictable latency by pre-allocating objects rather than building them on demand

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

- Construction cost is high (database connections, thread handles, socket connections)
- Objects are created and discarded at a high rate throughout the application's lifetime
- Garbage-collection pauses are unacceptable in latency-sensitive code
- A bounded number of instances is sufficient to serve the entire workload
- Objects can be cleanly reset to a neutral state between uses
- You need an upper bound on resource consumption
- Multi-threaded workloads benefit from sharing a fixed set of pre-warmed instances

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

**Tool Crib at a Factory**: A manufacturing plant keeps a shared inventory of expensive power tools. Workers check out the tool they need, use it, and return it to the crib for the next person. Buying a new tool for every task would be wasteful; sharing a finite set keeps costs down.

**City Bike-Share Program**: A network of docking stations holds bicycles that anyone can unlock, ride, and return. The system does not build a new bike per trip - it recycles a fixed fleet, rebalancing stations as needed to meet demand.

**Hotel Laundry Service**: A hotel owns a set number of towels and linens. Used items are collected, washed, and returned to the supply closet rather than discarded. The pool size is tuned so that clean inventory is always available without over-purchasing.

## Pros and Cons

### Advantages
- **Faster acquisition**: Borrowing a ready-made object is far cheaper than constructing one from scratch
- **Lower memory churn**: A stable pool reduces allocation and deallocation traffic, easing garbage-collection load
- **Bounded resource use**: The pool enforces a hard cap on how many instances exist at any time
- **Predictable capacity**: Pre-allocation guarantees that peak demand can be served without construction delays
- **Reduced startup latency**: Objects are warmed up once and ready to go on first request
- **Throughput-friendly**: High-volume workloads avoid the serialization bottleneck of repeated instantiation

### Disadvantages
- **Management overhead**: Pool lifecycle, validation, and eviction logic add code complexity
- **Concurrency hazards**: Multi-threaded access requires synchronization to avoid double-checkouts
- **Reset discipline**: Every returned object must be scrubbed to a clean state or stale data leaks between clients
- **Idle memory cost**: All pooled objects occupy memory even during low-traffic periods
- **Harder debugging**: Shared, recycled instances make it trickier to trace which client caused a problem
- **Leak risk**: A client that forgets to return an object silently drains the pool until it is exhausted

## Relations with Other Patterns

- **Singleton**: The pool manager itself is frequently a singleton to ensure one global pool
- **Factory Method**: The pool uses a factory to create the initial batch of objects
- **Strategy**: Eagerly pre-allocating versus lazily creating on demand are two pool strategies that can be swapped
- **Flyweight**: Both share objects, but Flyweight shares immutable intrinsic state while Object Pool lends mutable instances
- **Proxy**: A proxy can wrap pooled objects to automatically track acquisition and return
- **Observer**: Interested parties can subscribe to pool events like exhaustion or replenishment

## Examples in Other Languages

### Java

```java
public abstract class ObjectPool<T> {
  private long expirationTime;
  private Hashtable<T, Long> locked, unlocked;

  public ObjectPool() {
    expirationTime = 30000; // 30 seconds
    locked = new Hashtable<T, Long>();
    unlocked = new Hashtable<T, Long>();
  }

  protected abstract T create();
  public abstract boolean validate(T o);
  public abstract void expire(T o);

  public synchronized T checkOut() {
    long now = System.currentTimeMillis();
    T t;
    if (unlocked.size() > 0) {
      Enumeration<T> e = unlocked.keys();
      while (e.hasMoreElements()) {
        t = e.nextElement();
        if ((now - unlocked.get(t)) > expirationTime) {
          unlocked.remove(t);
          expire(t);
          t = null;
        } else {
          if (validate(t)) {
            unlocked.remove(t);
            locked.put(t, now);
            return (t);
          } else {
            unlocked.remove(t);
            expire(t);
            t = null;
          }
        }
      }
    }
    t = create();
    locked.put(t, now);
    return (t);
  }

  public synchronized void checkIn(T t) {
    locked.remove(t);
    unlocked.put(t, System.currentTimeMillis());
  }
}

public class JDBCConnectionPool extends ObjectPool<Connection> {
  private String dsn, usr, pwd;

  public JDBCConnectionPool(String driver, String dsn, String usr, String pwd) {
    super();
    try {
      Class.forName(driver).newInstance();
    } catch (Exception e) {
      e.printStackTrace();
    }
    this.dsn = dsn;
    this.usr = usr;
    this.pwd = pwd;
  }

  @Override
  protected Connection create() {
    try {
      return (DriverManager.getConnection(dsn, usr, pwd));
    } catch (SQLException e) {
      e.printStackTrace();
      return (null);
    }
  }

  @Override
  public void expire(Connection o) {
    try {
      ((Connection) o).close();
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }

  @Override
  public boolean validate(Connection o) {
    try {
      return (!((Connection) o).isClosed());
    } catch (SQLException e) {
      e.printStackTrace();
      return (false);
    }
  }
}

public class Main {
  public static void main(String args[]) {
    JDBCConnectionPool pool = new JDBCConnectionPool(
      "org.hsqldb.jdbcDriver", "jdbc:hsqldb://localhost/mydb",
      "sa", "secret");

    Connection con = pool.checkOut();
    // Use the connection
    pool.checkIn(con);
  }
}
```

### C++

```cpp
#include <string>
#include <iostream>
#include <list>

class Resource {
    int value;
    public:
        Resource() {
            value = 0;
        }
        void reset() {
            value = 0;
        }
        int getValue() {
            return value;
        }
        void setValue(int number) {
            value = number;
        }
};

/* Note, that this class is a singleton. */
class ObjectPool {
    private:
        std::list<Resource*> resources;
        static ObjectPool* instance;
        ObjectPool() {}
    public:
        static ObjectPool* getInstance() {
            if (instance == 0) {
                instance = new ObjectPool;
            }
            return instance;
        }

        Resource* getResource() {
            if (resources.empty()) {
                std::cout << "Creating new." << std::endl;
                return new Resource;
            } else {
                std::cout << "Reusing existing." << std::endl;
                Resource* resource = resources.front();
                resources.pop_front();
                return resource;
            }
        }

        void returnResource(Resource* object) {
            object->reset();
            resources.push_back(object);
        }
};

ObjectPool* ObjectPool::instance = 0;

int main() {
    ObjectPool* pool = ObjectPool::getInstance();
    Resource* one;
    Resource* two;

    one = pool->getResource();
    one->setValue(10);
    std::cout << "one = " << one->getValue() << " [" << one << "]" << std::endl;

    two = pool->getResource();
    two->setValue(20);
    std::cout << "two = " << two->getValue() << " [" << two << "]" << std::endl;

    pool->returnResource(one);
    pool->returnResource(two);

    one = pool->getResource();
    std::cout << "one = " << one->getValue() << " [" << one << "]" << std::endl;

    two = pool->getResource();
    std::cout << "two = " << two->getValue() << " [" << two << "]" << std::endl;

    return 0;
}
```

### Python

```python
class ReusablePool:
    """
    Manage Reusable objects for use by Client objects.
    """

    def __init__(self, size):
        self._reusables = [Reusable() for _ in range(size)]

    def acquire(self):
        return self._reusables.pop()

    def release(self, reusable):
        self._reusables.append(reusable)


class Reusable:
    """
    Collaborate with other objects for a limited amount of time, then
    they are no longer needed for that collaboration.
    """
    pass


def main():
    reusable_pool = ReusablePool(10)
    reusable = reusable_pool.acquire()
    reusable_pool.release(reusable)


if __name__ == "__main__":
    main()
```

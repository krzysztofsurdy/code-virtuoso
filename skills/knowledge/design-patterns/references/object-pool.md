# Object Pool Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Object Pool is a creational design pattern that avoids the cost of repeated object construction and destruction by keeping a reservoir of pre-built, reusable instances. A client borrows an object from the pool and returns it when finished so the next client can use it. This pays off most when instantiation is expensive: database connections, network sockets, heavy data structures, or thread handles.

## Intent

- Avoid repeated construction and teardown costs by recycling existing instances
- Lower garbage-collection pressure by keeping a stable set of long-lived objects
- Provide a checkout/return lifecycle so clients can share a bounded set of resources
- Cap the number of concurrently active instances to stay within system resource limits
- Give predictable latency by pre-allocating objects instead of building them on demand

## Problem and solution

### Problem

Creating objects can be expensive in several ways:

1. **CPU overhead**: instantiation takes time and processing power
2. **Memory usage**: creating many objects raises memory consumption and garbage-collection pressure
3. **Connection limits**: systems such as databases have a finite number of connections
4. **Initialization cost**: some objects need complex setup
5. **Bottlenecks**: in high-throughput scenarios, constant object creation becomes the limiting factor

### Solution

Maintain a pool of pre-created, reusable objects. A client requests an available object from the pool instead of creating a new one, and returns it after use for another client to take. This removes the creation overhead.

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

## When to use

- Construction cost is high (database connections, thread handles, socket connections)
- Objects are created and discarded at a high rate
- Garbage-collection pauses are unacceptable in latency-sensitive code
- A bounded number of instances can serve the whole workload
- Objects can be reset cleanly to a neutral state between uses
- You need an upper bound on resource consumption
- Multi-threaded workloads benefit from sharing a fixed set of pre-warmed instances

## Implementation

### PHP 8.3+ example: database connection pool

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

### Thread/worker pool example

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

## Real-world analogies

**Tool crib at a factory**: a manufacturing plant keeps a shared inventory of expensive power tools. Workers check out the tool they need, use it, and return it to the crib for the next person. Buying a new tool for every task would be wasteful, so a finite set is shared.

**City bike-share program**: docking stations hold bicycles that anyone can unlock, ride, and return. The system does not build a new bike per trip. It recycles a fixed fleet and rebalances stations to meet demand.

**Hotel laundry service**: a hotel owns a set number of towels and linens. Used items are collected, washed, and returned to the supply closet instead of being thrown away. The pool size is tuned so clean inventory is always available without over-buying.

## Pros and cons

### Advantages

- **Faster acquisition**: borrowing a ready-made object is far cheaper than constructing one
- **Lower memory churn**: a stable pool reduces allocation and deallocation traffic, which eases garbage-collection load
- **Bounded resource use**: the pool enforces a hard cap on how many instances exist
- **Predictable capacity**: pre-allocation means peak demand can be served without construction delays
- **Lower startup latency**: objects are warmed up once and ready on the first request
- **Throughput**: high-volume workloads avoid the bottleneck of repeated instantiation

### Disadvantages

- **Management overhead**: pool lifecycle, validation, and eviction logic add code
- **Concurrency hazards**: multi-threaded access needs synchronization to avoid double checkouts
- **Reset discipline**: every returned object must be reset to a clean state, or stale data leaks between clients
- **Idle memory cost**: pooled objects occupy memory even during low traffic
- **Harder debugging**: shared, recycled instances make it harder to trace which client caused a problem
- **Leak risk**: a client that forgets to return an object silently drains the pool until it is exhausted

## Relations with other patterns

- **Singleton**: the pool manager is often a singleton so there is one global pool
- **Factory Method**: the pool uses a factory to create the initial batch of objects
- **Strategy**: eager pre-allocation and lazy creation on demand are two pool strategies that can be swapped
- **Flyweight**: both share objects, but Flyweight shares immutable intrinsic state while Object Pool lends mutable instances
- **Proxy**: a proxy can wrap pooled objects to track acquisition and return automatically
- **Observer**: interested parties can subscribe to pool events such as exhaustion or replenishment

## Examples in other languages

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

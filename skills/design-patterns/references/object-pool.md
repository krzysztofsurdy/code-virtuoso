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

*Source: [sourcemaking.com/design_patterns/object_pool](https://sourcemaking.com/design_patterns/object_pool)*

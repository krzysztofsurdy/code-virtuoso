# Singleton Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem & solution](#problem--solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Singleton is a creational design pattern that restricts a class to exactly one instance and gives it a well-known access point. It combines instantiation control with global access, so one object of the class exists for the lifetime of the application.

## Intent

- Guarantee that only one instance of a class is ever created
- Provide a single, globally accessible entry point to that instance
- Manage a shared resource in one place behind controlled instantiation
- Defer creation of expensive resources until first use
- Prevent duplicate instances

## Problem & solution

### Problem

Some application resources must exist as a single shared object:

1. **Uncontrolled instantiation**: without safeguards, any code can create new instances, leading to conflicting state
2. **Resource waste**: duplicating expensive objects such as database connections or loggers wastes memory and handles
3. **State inconsistency**: when modules hold separate instances, their state drifts apart and causes subtle synchronization bugs
4. **Scattered access**: without a central accessor, the shared resource has to be passed through constructors and method signatures everywhere

### Solution

Make the class manage its own instantiation:
1. Make the constructor private so external code cannot call `new`
2. Store a static reference to the sole instance inside the class
3. Provide a public static method that returns this reference, creating it on the first call
4. Optionally use lazy initialization so construction waits until first access

## Structure

```
Client Code
    ↓
    getInstance() (static method)
    ↓
Singleton
├── static instance: Singleton
├── private constructor
└── static getInstance(): Singleton
```

## When to use

- **Logging frameworks**: a single logger shared by every component
- **Database connections**: one connection pool or primary connection managed centrally
- **Configuration managers**: application-wide settings served from a single source
- **Caching systems**: one cache that all consumers read from and write to
- **Session managers**: session tracking in one place across the request lifecycle
- **Thread pools/executors**: one pool scheduling all asynchronous tasks
- **Resource pools**: controlled allocation of scarce resources such as file handles or network sockets

## Implementation

### PHP 8.3+ example: database connection Singleton

```php
<?php
declare(strict_types=1);

class DatabaseConnection {
    private static ?self $instance = null;
    private readonly PDO $connection;

    // Private constructor prevents external instantiation
    private function __construct() {
        $this->connection = new PDO(
            'mysql:host=localhost;dbname=app',
            'user',
            'password'
        );
    }

    // Global access point to the single instance
    public static function getInstance(): self {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    // Prevent cloning
    private function __clone(): void {}

    // Prevent unserialization
    public function __wakeup(): void {
        throw new Error('Cannot unserialize a Singleton instance');
    }

    public function query(string $sql): array {
        return $this->connection->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    public function execute(string $sql, array $params = []): bool {
        $stmt = $this->connection->prepare($sql);
        return $stmt->execute($params);
    }
}

// Usage
$db1 = DatabaseConnection::getInstance();
$db2 = DatabaseConnection::getInstance();
// $db1 === $db2 (same instance)

$results = $db1->query('SELECT * FROM users');
```

### Logger Singleton with static factory

```php
<?php
declare(strict_types=1);

class Logger {
    private static ?self $instance = null;
    private readonly string $logFile;

    private function __construct() {
        $this->logFile = dirname(__DIR__) . '/logs/app.log';
        if (!is_dir(dirname($this->logFile))) {
            mkdir(dirname($this->logFile), 0755, true);
        }
    }

    public static function getInstance(): self {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function __clone(): void {}
    public function __wakeup(): void {
        throw new Error('Cannot unserialize Logger');
    }

    public function log(string $message, string $level = 'INFO'): void {
        $timestamp = date('Y-m-d H:i:s');
        $logEntry = "[$timestamp] $level: $message\n";
        error_log($logEntry, 3, $this->logFile);
    }

    public function info(string $message): void {
        $this->log($message, 'INFO');
    }

    public function error(string $message): void {
        $this->log($message, 'ERROR');
    }

    public function warning(string $message): void {
        $this->log($message, 'WARNING');
    }
}

// Usage across the application
Logger::getInstance()->info('Application started');
Logger::getInstance()->error('An error occurred');
```

### Thread-safe Singleton with early initialization

```php
<?php
declare(strict_types=1);

class ConfigurationManager {
    private static self $instance;
    private array $config;

    private function __construct() {
        $this->config = $this->loadConfiguration();
    }

    // Static initializer (eager singleton)
    public static function init(): void {
        if (!isset(self::$instance)) {
            self::$instance = new self();
        }
    }

    public static function getInstance(): self {
        if (!isset(self::$instance)) {
            self::init();
        }
        return self::$instance;
    }

    private function __clone(): void {}
    public function __wakeup(): void {
        throw new Error('Cannot unserialize ConfigurationManager');
    }

    private function loadConfiguration(): array {
        return require dirname(__DIR__) . '/config/app.php';
    }

    public function get(string $key, mixed $default = null): mixed {
        return $this->config[$key] ?? $default;
    }

    public function set(string $key, mixed $value): void {
        $this->config[$key] = $value;
    }

    public function all(): array {
        return $this->config;
    }
}

// Initialization
ConfigurationManager::init();

// Usage
$dbHost = ConfigurationManager::getInstance()->get('database.host');
```

## Real-world analogies

**Government**: A nation has one government as its central authority. Citizens do not create alternative governments; they deal with the existing one through official channels.

**Company CEO**: An organization usually has a single chief executive. Strategic decisions go through that one person instead of competing leaders.

**Printer spooler**: An operating system runs one print spooler that queues jobs from every application. Programs submit work to the shared spooler instead of each starting their own.

**Bank account registry**: A bank keeps one master ledger of accounts. Every transaction refers to this single registry, so balances stay consistent.

## Pros and cons

### Advantages
- **Controlled instance count**: exactly one object, which simplifies shared-resource management
- **Convenient global access**: a well-known entry point, no need to pass references around
- **Lazy initialization**: the instance is created only when first requested
- **Thread safety**: can be implemented with synchronization primitives for concurrent environments
- **Centralized control**: one place controls instance creation and lifecycle
- **Memory efficiency**: one instance occupies memory, however many consumers exist

### Disadvantages
- **Global state**: introduces hidden global state, which complicates testing and debugging
- **Implicit dependencies**: consumers depend on the singleton without showing it in their signatures
- **Testability barriers**: hard to replace with mocks or stubs unless the design allows for it
- **Concurrency pitfalls**: needs careful locking in multi-threaded contexts to avoid race conditions
- **Mixed responsibilities**: the class handles both its domain logic and its own lifecycle
- **Tight coupling**: client code is bound to the concrete singleton class instead of an abstraction

## Relations with other patterns

- **Facade**: Facades often use singletons to present a unified interface to subsystems
- **Factory Method**: A factory method can return a singleton as the sole product instance
- **Abstract Factory**: Concrete factory classes are often implemented as singletons
- **Observer**: Singleton registries often manage the list of registered observers
- **Service Locator**: This anti-pattern usually relies on a singleton to locate and return services
- **Dependency Injection**: The preferred alternative: inject the single instance through constructors instead of accessing it globally

## Examples in other languages

### Java

```java
public class Singleton {
    private Singleton() {}

    private static class SingletonHolder {
        private static final Singleton INSTANCE = new Singleton();
    }

    public static Singleton getInstance() {
        return SingletonHolder.INSTANCE;
    }
}
```

### C++

**Before: manual global pointer management**

```cpp
class GlobalClass {
    int m_value;
  public:
    GlobalClass(int v = 0) {
        m_value = v;
    }
    int get_value() {
        return m_value;
    }
    void set_value(int v) {
        m_value = v;
    }
};

GlobalClass *global_ptr = 0;

void foo(void) {
  if (!global_ptr)
    global_ptr = new GlobalClass;
  global_ptr->set_value(1);
  cout << "foo: global_ptr is " << global_ptr->get_value() << '\n';
}

void bar(void) {
  if (!global_ptr)
    global_ptr = new GlobalClass;
  global_ptr->set_value(2);
  cout << "bar: global_ptr is " << global_ptr->get_value() << '\n';
}

int main() {
  if (!global_ptr)
    global_ptr = new GlobalClass;
  cout << "main: global_ptr is " << global_ptr->get_value() << '\n';
  foo();
  bar();
}
```

**After: Singleton pattern with controlled access**

```cpp
class GlobalClass {
    int m_value;
    static GlobalClass *s_instance;
    GlobalClass(int v = 0) {
        m_value = v;
    }
  public:
    int get_value() {
        return m_value;
    }
    void set_value(int v) {
        m_value = v;
    }
    static GlobalClass *instance() {
        if (!s_instance)
          s_instance = new GlobalClass;
        return s_instance;
    }
};

GlobalClass *GlobalClass::s_instance = 0;

void foo(void) {
  GlobalClass::instance()->set_value(1);
  cout << "foo: global_ptr is " << GlobalClass::instance()->get_value() << '\n';
}

void bar(void) {
  GlobalClass::instance()->set_value(2);
  cout << "bar: global_ptr is " << GlobalClass::instance()->get_value() << '\n';
}

int main() {
  cout << "main: global_ptr is " << GlobalClass::instance()->get_value() << '\n';
  foo();
  bar();
}
```

### Python

```python
class Singleton(type):
    """
    Define an Instance operation that lets clients access its unique
    instance.
    """

    def __init__(cls, name, bases, attrs, **kwargs):
        super().__init__(name, bases, attrs)
        cls._instance = None

    def __call__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__call__(*args, **kwargs)
        return cls._instance

class MyClass(metaclass=Singleton):
    """
    Example class.
    """
    pass

def main():
    m1 = MyClass()
    m2 = MyClass()
    assert m1 is m2

if __name__ == "__main__":
    main()
```

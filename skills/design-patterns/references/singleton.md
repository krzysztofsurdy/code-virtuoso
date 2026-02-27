# Singleton Pattern

## Overview

The Singleton pattern is a creational design pattern that ensures a class has only one instance and provides a global point of access to it. It combines object creation with instance control, guaranteeing that throughout the application's lifetime, only one object of that class exists.

## Intent

- Ensure that a class has only one instance
- Provide a global point of access to this single instance
- Control the instantiation of a class to manage a shared resource
- Lazy-initialize expensive resources on first use
- Prevent uncontrolled creation of multiple instances

## Problem & Solution

### Problem

Many applications need a single, globally accessible resource:

1. **Uncontrolled Instantiation**: Without constraints, code can create multiple instances of a class, leading to inconsistent state
2. **Resource Waste**: Multiple instances of expensive objects (database connections, loggers) consume unnecessary resources
3. **State Inconsistency**: Different parts of the application may work with different instances, causing synchronization issues
4. **Global Access Challenges**: Without a controlled mechanism, accessing shared resources becomes difficult and scattered throughout code

### Solution

Create a class that controls its own instantiation by:
1. Making the constructor private to prevent external instantiation
2. Creating a static instance stored within the class
3. Providing a public static method to access the single instance
4. Optionally implementing lazy initialization to defer creation until first use

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

## When to Use

- **Logging Frameworks**: Single logger instance shared across the entire application
- **Database Connections**: Manage a single connection pool or primary database connection
- **Configuration Managers**: Access application settings from one centralized instance
- **Caching Systems**: Single cache instance to store and retrieve cached data
- **Session Managers**: Manage user sessions across the application
- **Thread Pools/Executors**: Single execution service for asynchronous tasks
- **Resource Pools**: Manage limited resources like thread pools or connection pools

## Implementation

### PHP 8.3+ Example: Database Connection Singleton

```php
<?php
declare(strict_types=1);

readonly class DatabaseConnection {
    private static ?self $instance = null;
    private PDO $connection;

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

### Logger Singleton with Static Factory

```php
<?php
declare(strict_types=1);

readonly class Logger {
    private static ?self $instance = null;
    private string $logFile;

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

### Thread-Safe Singleton with Early Initialization

```php
<?php
declare(strict_types=1);

readonly class ConfigurationManager {
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
            self::$init();
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

## Real-World Analogies

**Government**: Each country has one government that serves as the central authority. You don't create new governments; you access the existing one through established channels.

**Company CEO**: A company typically has one CEO who is the ultimate decision-maker. All requests for executive decisions go through this single person, not multiple CEOs.

**Printer Spooler**: A computer has one printer spooler service that manages all print jobs. Multiple applications send jobs to the same spooler, not create separate printers.

**Bank Account Registry**: A bank has one central registry of all accounts. All transactions reference this single registry, ensuring data consistency.

## Pros and Cons

### Advantages
- **Single Responsibility**: Ensures only one instance exists, simplifying resource management
- **Global Access**: Provides a convenient global access point without passing references everywhere
- **Lazy Initialization**: Expensive resources are created only when first needed
- **Thread Safety**: Can be implemented to be thread-safe
- **Controlled Access**: Single point of control over instance creation and behavior
- **Memory Efficient**: Only one instance exists, reducing memory overhead

### Disadvantages
- **Global State**: Creates a form of global variable, making testing and debugging harder
- **Hidden Dependencies**: Classes depend on the Singleton implicitly, making relationships unclear
- **Difficult to Test**: Hard to mock or replace in unit tests without additional refactoring
- **Concurrency Issues**: Requires careful synchronization in multi-threaded environments
- **Violates Single Responsibility**: Class must manage both business logic and instance control
- **Tight Coupling**: Clients become tightly coupled to the Singleton class itself

## Relations with Other Patterns

- **Facade**: Often uses Singletons to provide unified interface to subsystems
- **Factory Method**: Can create Singletons as the single instance it returns
- **Abstract Factory**: Concrete factories are often implemented as Singletons
- **Observer**: Singleton registries can manage observer lists
- **Service Locator**: Anti-pattern that often uses Singletons to locate services
- **Dependency Injection**: Modern alternative that reduces Singleton dependency through constructor injection

## Examples in Other Languages

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

*Source: [sourcemaking.com/design_patterns/singleton](https://sourcemaking.com/design_patterns/singleton)*

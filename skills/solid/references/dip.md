# Dependency Inversion Principle (DIP)

## Definition

1. High-level modules should not depend on low-level modules. Both should depend on abstractions.
2. Abstractions should not depend on details. Details should depend on abstractions.

Robert C. Martin's DIP reverses the traditional dependency direction in software. Instead of business logic importing database drivers and HTTP libraries directly, it defines interfaces that infrastructure code must satisfy.

## Why It Matters

Without DIP, high-level business rules become entangled with low-level infrastructure. Changing your database from MySQL to PostgreSQL shouldn't require rewriting your order processing logic. DIP creates a boundary:

- **Business logic stays pure** — no framework or infrastructure imports in domain code
- **Infrastructure is swappable** — change databases, message queues, or APIs without touching business rules
- **Testing is trivial** — inject test doubles instead of real infrastructure
- **Deployment flexibility** — deploy the same business logic with different infrastructure configurations
- **Team independence** — domain team and infrastructure team work on different sides of the interface

## Detecting Violations

Signs of missing dependency inversion:

- **Direct `new` of infrastructure classes inside business logic** — `new MySqlConnection()` in a service class
- **Import statements pointing downward** — domain code importing from `Infrastructure\` or `vendor\` namespaces
- **Hard-coded file paths, URLs, or connection strings** — configuration baked into logic
- **"I can't test this without a database"** — if unit tests need external systems, DIP is violated
- **Constructor creates its own dependencies** — instead of receiving them via injection

## Before/After — PHP 8.3+

### Before: Business logic directly depends on infrastructure

```php
<?php

declare(strict_types=1);

final class OrderProcessor
{
    public function process(int $orderId): void
    {
        // Direct dependency on MySQL
        $pdo = new PDO('mysql:host=localhost;dbname=shop', 'root', 'secret');
        $stmt = $pdo->prepare('SELECT * FROM orders WHERE id = ?');
        $stmt->execute([$orderId]);
        $order = $stmt->fetch();

        if ($order['total'] > 100) {
            // Direct dependency on specific email library
            $mailer = new SendGridMailer('api-key-here');
            $mailer->send($order['email'], 'Order confirmed', 'Your order is being processed');
        }

        // Direct dependency on specific logging implementation
        $logger = new FileLogger('/var/log/orders.log');
        $logger->info("Processed order $orderId");
    }
}
```

This class cannot be tested without MySQL, SendGrid, and a writable filesystem. Changing any infrastructure component requires editing business logic.

### After: Business logic depends on abstractions

```php
<?php

declare(strict_types=1);

// Abstractions defined by the business logic layer
interface OrderRepository
{
    public function findById(int $id): Order;
}

interface CustomerNotifier
{
    public function notifyOrderConfirmed(Order $order): void;
}

interface OrderLogger
{
    public function orderProcessed(int $orderId): void;
}

// Business logic depends only on abstractions
final readonly class OrderProcessor
{
    public function __construct(
        private OrderRepository $orders,
        private CustomerNotifier $notifier,
        private OrderLogger $logger,
    ) {}

    public function process(int $orderId): void
    {
        $order = $this->orders->findById($orderId);

        if ($order->total > 100) {
            $this->notifier->notifyOrderConfirmed($order);
        }

        $this->logger->orderProcessed($orderId);
    }
}

// Infrastructure implements the abstractions
final readonly class MysqlOrderRepository implements OrderRepository
{
    public function __construct(private PDO $pdo) {}

    public function findById(int $id): Order
    {
        $stmt = $this->pdo->prepare('SELECT * FROM orders WHERE id = ?');
        $stmt->execute([$id]);
        $row = $stmt->fetch();

        return new Order(
            id: $row['id'],
            email: $row['email'],
            total: (float) $row['total'],
        );
    }
}

final readonly class EmailCustomerNotifier implements CustomerNotifier
{
    public function __construct(private MailerInterface $mailer) {}

    public function notifyOrderConfirmed(Order $order): void
    {
        $this->mailer->send($order->email, 'Order confirmed', 'Your order is being processed');
    }
}
```

Now the business logic is testable with simple in-memory fakes, and infrastructure can be swapped freely.

### Dependency Direction Diagram

```
WITHOUT DIP:
  OrderProcessor → MySqlConnection
  OrderProcessor → SendGridMailer
  OrderProcessor → FileLogger
  (High-level depends on low-level)

WITH DIP:
  OrderProcessor → OrderRepository ← MysqlOrderRepository
  OrderProcessor → CustomerNotifier ← EmailCustomerNotifier
  OrderProcessor → OrderLogger ← FileOrderLogger
  (Both depend on abstractions; arrows point toward abstractions)
```

## Examples in Other Languages

### Java

**Before:**

```java
public class WeatherDashboard {
    public String getWeatherReport(String city) {
        // Direct dependency on specific API
        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
            .uri(URI.create("https://api.weather.com/v1/" + city))
            .build();
        HttpResponse<String> response = client.send(request, BodyHandlers.ofString());

        // Direct dependency on specific parser
        JSONObject json = new JSONObject(response.body());
        double temp = json.getDouble("temperature");

        return String.format("Temperature in %s: %.1f°C", city, temp);
    }
}
```

**After:**

```java
public interface WeatherProvider {
    WeatherData fetch(String city);
}

public record WeatherData(String city, double temperature, String condition) {}

public class WeatherDashboard {
    private final WeatherProvider provider;

    public WeatherDashboard(WeatherProvider provider) {
        this.provider = provider;
    }

    public String getWeatherReport(String city) {
        WeatherData data = provider.fetch(city);
        return String.format("Temperature in %s: %.1f°C", data.city(), data.temperature());
    }
}

// Infrastructure implementation — can be swapped freely
public class OpenWeatherApiProvider implements WeatherProvider {
    private final HttpClient client;
    private final String apiKey;

    public OpenWeatherApiProvider(HttpClient client, String apiKey) {
        this.client = client;
        this.apiKey = apiKey;
    }

    @Override
    public WeatherData fetch(String city) {
        // API-specific logic lives here, not in business layer
    }
}

// Test double — no HTTP calls needed
public class FakeWeatherProvider implements WeatherProvider {
    @Override
    public WeatherData fetch(String city) {
        return new WeatherData(city, 22.5, "Sunny");
    }
}
```

### Python

**Before:**

```python
import redis
import json


class ShoppingCart:
    def __init__(self, user_id: str):
        self.user_id = user_id
        # Direct dependency on Redis
        self.redis = redis.Redis(host="localhost", port=6379)

    def add_item(self, product_id: str, quantity: int) -> None:
        key = f"cart:{self.user_id}"
        cart = json.loads(self.redis.get(key) or "{}")
        cart[product_id] = cart.get(product_id, 0) + quantity
        self.redis.set(key, json.dumps(cart))

    def get_items(self) -> dict:
        key = f"cart:{self.user_id}"
        return json.loads(self.redis.get(key) or "{}")
```

**After:**

```python
from abc import ABC, abstractmethod


class CartStorage(ABC):
    @abstractmethod
    def load(self, user_id: str) -> dict: ...

    @abstractmethod
    def save(self, user_id: str, items: dict) -> None: ...


class ShoppingCart:
    def __init__(self, user_id: str, storage: CartStorage):
        self.user_id = user_id
        self._storage = storage

    def add_item(self, product_id: str, quantity: int) -> None:
        items = self._storage.load(self.user_id)
        items[product_id] = items.get(product_id, 0) + quantity
        self._storage.save(self.user_id, items)

    def get_items(self) -> dict:
        return self._storage.load(self.user_id)


# Redis implementation
class RedisCartStorage(CartStorage):
    def __init__(self, redis_client):
        self._redis = redis_client

    def load(self, user_id: str) -> dict:
        import json
        data = self._redis.get(f"cart:{user_id}")
        return json.loads(data) if data else {}

    def save(self, user_id: str, items: dict) -> None:
        import json
        self._redis.set(f"cart:{user_id}", json.dumps(items))


# In-memory implementation for tests
class InMemoryCartStorage(CartStorage):
    def __init__(self):
        self._data: dict[str, dict] = {}

    def load(self, user_id: str) -> dict:
        return self._data.get(user_id, {}).copy()

    def save(self, user_id: str, items: dict) -> None:
        self._data[user_id] = items
```

### TypeScript

**Before:**

```typescript
import { Pool } from "pg";

class UserService {
  private db = new Pool({
    host: "localhost",
    database: "myapp",
    user: "postgres",
    password: "secret",
  });

  async getUser(id: string): Promise<User> {
    const result = await this.db.query("SELECT * FROM users WHERE id = $1", [
      id,
    ]);
    return result.rows[0] as User;
  }
}
```

**After:**

```typescript
interface UserRepository {
  findById(id: string): Promise<User | null>;
}

class UserService {
  constructor(private readonly users: UserRepository) {}

  async getUser(id: string): Promise<User> {
    const user = await this.users.findById(id);
    if (!user) throw new Error(`User ${id} not found`);
    return user;
  }
}

// PostgreSQL implementation
class PostgresUserRepository implements UserRepository {
  constructor(private readonly pool: Pool) {}

  async findById(id: string): Promise<User | null> {
    const result = await this.pool.query("SELECT * FROM users WHERE id = $1", [
      id,
    ]);
    return (result.rows[0] as User) ?? null;
  }
}

// In-memory implementation for tests
class InMemoryUserRepository implements UserRepository {
  private users = new Map<string, User>();

  async findById(id: string): Promise<User | null> {
    return this.users.get(id) ?? null;
  }

  seed(user: User): void {
    this.users.set(user.id, user);
  }
}
```

### C++

**Before:**

```cpp
#include <iostream>
#include <fstream>

class TemperatureMonitor {
    std::string logPath;
public:
    TemperatureMonitor(const std::string& path) : logPath(path) {}

    void record(double temp) {
        // Direct dependency on file system
        std::ofstream file(logPath, std::ios::app);
        file << "Temperature: " << temp << "\n";

        // Direct dependency on console output
        if (temp > 100.0) {
            std::cout << "WARNING: High temperature: " << temp << "\n";
        }
    }
};
```

**After:**

```cpp
#include <memory>
#include <string>

class TemperatureRecorder {
public:
    virtual ~TemperatureRecorder() = default;
    virtual void record(double temp) = 0;
};

class TemperatureAlert {
public:
    virtual ~TemperatureAlert() = default;
    virtual void check(double temp) = 0;
};

class TemperatureMonitor {
    std::unique_ptr<TemperatureRecorder> recorder;
    std::unique_ptr<TemperatureAlert> alert;
public:
    TemperatureMonitor(
        std::unique_ptr<TemperatureRecorder> rec,
        std::unique_ptr<TemperatureAlert> alert
    ) : recorder(std::move(rec)), alert(std::move(alert)) {}

    void record(double temp) {
        recorder->record(temp);
        alert->check(temp);
    }
};

// File-based implementation
class FileRecorder : public TemperatureRecorder {
    std::string path;
public:
    explicit FileRecorder(std::string path) : path(std::move(path)) {}
    void record(double temp) override {
        std::ofstream file(path, std::ios::app);
        file << "Temperature: " << temp << "\n";
    }
};

class ConsoleAlert : public TemperatureAlert {
    double threshold;
public:
    explicit ConsoleAlert(double threshold) : threshold(threshold) {}
    void check(double temp) override {
        if (temp > threshold) {
            std::cout << "WARNING: " << temp << " exceeds " << threshold << "\n";
        }
    }
};
```

## Who Owns the Abstraction?

A critical detail often missed: **the abstraction belongs to the high-level module**, not the low-level one.

```
WRONG:
  Infrastructure/ defines OrderRepositoryInterface
  Domain/ imports from Infrastructure/

RIGHT:
  Domain/ defines OrderRepository (interface)
  Infrastructure/ implements Domain/OrderRepository
```

The domain layer defines what it needs. Infrastructure adapts to those needs. This is what "inversion" means — the dependency arrow points toward the domain, not away from it.

## Common Pitfalls

- **Interfaces that mirror implementations** — if your `DatabaseOrderRepository` interface has methods like `executeSql()`, you've just wrapped the detail in an abstraction name
- **Single-implementation interfaces** — DIP doesn't mean "create an interface for everything." Only abstract at boundaries where substitution provides value (testing, swappability)
- **Service locator anti-pattern** — `Container::get(OrderRepository::class)` still couples to the container. Use constructor injection instead.
- **Abstracting too early** — wait until you need a second implementation or need testability before introducing the abstraction

## Related Principles

- **Open/Closed (OCP)** — DIP's abstractions are the extension points that OCP requires
- **Interface Segregation (ISP)** — focused interfaces make better abstraction boundaries
- **Clean Architecture** — DIP is the foundation of hexagonal/ports-and-adapters architecture
- **Dependency Injection** — the mechanism (constructor injection, DI containers) that implements DIP

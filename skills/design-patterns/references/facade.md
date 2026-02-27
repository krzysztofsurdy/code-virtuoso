## Overview

The Facade design pattern is a structural pattern that provides a unified, simplified interface to a complex set of classes, libraries, or subsystems. It acts as a wrapper that hides the complexity of the underlying components, allowing client code to interact with a single, easy-to-use interface instead of dealing with multiple interdependent classes.

## Intent

The Facade pattern solves the problem of dealing with complexity in large systems by providing:

- A single entry point to a complex subsystem
- Simplified access to functionality that requires multiple steps
- Decoupling of client code from internal implementation details
- Reduced cognitive load for developers using the subsystem
- A layer of abstraction that shields clients from architectural changes

## Problem and Solution

**Problem:** You have a complex subsystem composed of many interdependent classes. Client code must understand and interact with numerous classes directly, creating tight coupling and making the code difficult to maintain and use.

**Solution:** Create a facade class that provides a simple interface to the complex subsystem. The facade delegates client requests to appropriate objects within the subsystem, encapsulating the complexity and providing a unified entry point.

## Structure

The Facade pattern involves these participants:

- **Facade:** Provides a simplified interface and knows which subsystem classes handle requests
- **Subsystem Classes:** Implement the actual functionality; unaware of the facade's existence
- **Client:** Uses the facade instead of directly accessing subsystem classes

Key characteristics:
- One-way dependency: Facade depends on subsystems, not vice versa
- Facade is optional (subsystems can still be used directly if needed)
- Often reduces the number of classes client needs to know about

## When to Use

Use the Facade pattern when:

- You need to provide a simple interface to a complex subsystem
- You want to decouple clients from a complex set of components
- Multiple clients need similar interactions with a subsystem
- You're building a new system on top of legacy code
- You want to establish boundaries between system layers (presentation, business logic)
- The subsystem's implementation details might change frequently
- You need to organize dependencies between client and subsystem classes

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Structural\Facade;

// Subsystem classes - complex internal implementation
class Database {
    public function connect(): void {
        echo "Connecting to database...\n";
    }

    public function query(string $sql): array {
        echo "Executing query: $sql\n";
        return [['id' => 1, 'name' => 'Example']];
    }
}

class Cache {
    private array $store = [];

    public function set(string $key, mixed $value): void {
        $this->store[$key] = $value;
        echo "Cache set: $key\n";
    }

    public function get(string $key): mixed {
        return $this->store[$key] ?? null;
    }
}

class Logger {
    public function log(string $message): void {
        echo "[LOG] $message\n";
    }
}

// Facade: Simplified interface to the subsystem
class DataRepository {
    public function __construct(
        private readonly Database $db,
        private readonly Cache $cache,
        private readonly Logger $logger
    ) {}

    public function fetchUser(int $userId): ?array {
        $cacheKey = "user_$userId";

        // Try cache first
        $cached = $this->cache->get($cacheKey);
        if ($cached !== null) {
            $this->logger->log("User $userId retrieved from cache");
            return $cached;
        }

        // Fall back to database
        $this->logger->log("Querying database for user $userId");
        $this->db->connect();
        $results = $this->db->query("SELECT * FROM users WHERE id = $userId");

        if (!empty($results)) {
            $this->cache->set($cacheKey, $results[0]);
            return $results[0];
        }

        return null;
    }

    public function saveUser(int $id, string $name): bool {
        $this->logger->log("Saving user $id: $name");
        $this->db->connect();
        $this->db->query("INSERT INTO users (id, name) VALUES ($id, '$name')");
        $this->cache->set("user_$id", ['id' => $id, 'name' => $name]);
        return true;
    }

    public function clearCache(): void {
        $this->logger->log("Clearing all cache entries");
        // Cache clearing logic
    }
}

// Client code - simple interface, no knowledge of subsystems
$db = new Database();
$cache = new Cache();
$logger = new Logger();

$repository = new DataRepository($db, $cache, $logger);

// Just use the facade - no need to orchestrate subsystems
$user = $repository->fetchUser(1);
$repository->saveUser(2, 'John Doe');
$repository->clearCache();
```

## Real-World Analogies

- **Cafe:** When you order coffee, you don't need to know about bean roasting, grinding, brewing equipment. The barista's role is the facade to the complex coffee-making subsystem.
- **Hotel Concierge:** Guests request services through a single interface (concierge) rather than directly contacting separate departments (restaurant, housekeeping, security).
- **Car Dashboard:** Drivers interact with simple controls (steering wheel, pedals, dashboard) instead of managing the complex engine, transmission, and electrical subsystems directly.
- **API Gateway:** A single endpoint that routes requests to multiple backend services, hiding their complexity from clients.

## Pros and Cons

**Pros:**
- Simplicity: Client code is easier to write and understand
- Reduced Coupling: Clients depend on the facade, not internal subsystems
- Flexibility: Change internal implementation without affecting clients
- Abstraction: Hide complex logic behind a simple interface
- Layering: Create clear boundaries between system layers
- Easier Testing: Clients can mock a simpler facade interface

**Cons:**
- God Object Risk: Facade can grow too large and take on too many responsibilities
- Limited Functionality: Simplicity might restrict access to advanced subsystem features
- Over-Abstraction: Simple subsystems don't need a facade
- Maintenance Burden: Facade becomes a central point of change
- Single Point of Failure: If facade breaks, multiple clients are affected
- Learning Curve: New developers must learn both facade and subsystems for advanced use

## Relations with Other Patterns

- **Adapter:** Adapter makes incompatible interfaces work together; Facade simplifies complex ones
- **Decorator:** Similar wrapping structure, but Decorator adds responsibility while Facade simplifies access
- **Strategy:** Can work together - facade might expose different strategies
- **Factory Method:** Can be used within facade to create subsystem objects
- **Singleton:** Facade is often implemented as a singleton for system-wide access
- **Abstract Factory:** Can provide simplified interface to abstract factory subsystems
- **Command:** Can be combined to queue facade operations
- **Observer:** Facade can expose observer patterns from subsystem

## Additional Considerations

**When Designing Facades:**
- Keep the facade interface simple and focused
- Delegate to subsystem classes, don't duplicate logic
- Consider providing multiple facades for different use cases
- Use dependency injection for subsystem components
- Document the facade's interface thoroughly
- Allow direct subsystem access if advanced users need it

**Common Pitfalls:**
- Creating a facade that's as complex as the subsystem it hides
- Tightly coupling the facade to client code
- Making the facade responsible for subsystem creation (use factories instead)
- Preventing clients from accessing subsystem classes when needed
- Over-engineering simple systems with unnecessary facades

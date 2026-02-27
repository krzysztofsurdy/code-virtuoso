# Abstract Factory Pattern

## Overview

The Abstract Factory pattern is a creational design pattern that provides an interface for creating families of related or dependent objects without specifying their concrete classes. It lets a system work with objects from different families without coupling the code to specific implementations.

## Intent

- Define an interface for creating families of related or dependent objects
- Encapsulate the creation of objects in a factory class hierarchy
- Allow client code to remain independent of the concrete products being created
- Ensure that related products work together seamlessly

## Problem & Solution

### Problem

When building a complex system that needs to support multiple variants of related objects, you face several challenges:

1. **Tight Coupling**: Creating objects directly in client code creates dependencies on concrete classes
2. **Inconsistency**: Different clients might create incompatible combinations of related objects
3. **Difficult Maintenance**: Adding new families of products requires changes throughout the codebase

### Solution

Create an abstract factory that defines methods for creating each type of product. Concrete factories implement these methods, encapsulating the creation logic for specific families. Client code works exclusively with abstract interfaces, remaining independent of concrete implementations.

## Structure

```
AbstractFactory (interface)
├── ConcreteFactoryA
├── ConcreteFactoryB
└── ...

AbstractProductA (interface)
├── ConcreteProductA1
└── ConcreteProductA2

AbstractProductB (interface)
├── ConcreteProductB1
└── ConcreteProductB2
```

## When to Use

- Systems need to work with multiple families of related products
- You want to provide a library of products without exposing implementation details
- Product families must be used together and you need to ensure consistency
- Adding new product families in the future without modifying existing code
- You need to isolate concrete product classes from client code

## Implementation

### PHP 8.3+ Example: UI Theme Factory

```php
<?php
declare(strict_types=1);

// Abstract Products
interface Button {
    public function render(): string;
}

interface Checkbox {
    public function render(): string;
}

// Concrete Products - Light Theme
readonly class LightButton implements Button {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<button class='light-theme'>{$this->label}</button>";
    }
}

readonly class LightCheckbox implements Checkbox {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<input type='checkbox' class='light-theme'/><label>{$this->label}</label>";
    }
}

// Concrete Products - Dark Theme
readonly class DarkButton implements Button {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<button class='dark-theme'>{$this->label}</button>";
    }
}

readonly class DarkCheckbox implements Checkbox {
    public function __construct(private string $label) {}

    public function render(): string {
        return "<input type='checkbox' class='dark-theme'/><label>{$this->label}</label>";
    }
}

// Abstract Factory
interface ThemeFactory {
    public function createButton(string $label): Button;
    public function createCheckbox(string $label): Checkbox;
}

// Concrete Factories
class LightThemeFactory implements ThemeFactory {
    public function createButton(string $label): Button {
        return new LightButton($label);
    }

    public function createCheckbox(string $label): Checkbox {
        return new LightCheckbox($label);
    }
}

class DarkThemeFactory implements ThemeFactory {
    public function createButton(string $label): Button {
        return new DarkButton($label);
    }

    public function createCheckbox(string $label): Checkbox {
        return new DarkCheckbox($label);
    }
}

// Client Code
class Application {
    public function __construct(private ThemeFactory $factory) {}

    public function render(): string {
        $button = $this->factory->createButton('Submit');
        $checkbox = $this->factory->createCheckbox('Remember me');

        return $button->render() . '<br>' . $checkbox->render();
    }
}

// Usage
$theme = 'dark'; // Could come from user preferences or config
$factory = match($theme) {
    'light' => new LightThemeFactory(),
    'dark' => new DarkThemeFactory(),
    default => throw new InvalidArgumentException("Unknown theme: $theme"),
};

$app = new Application($factory);
echo $app->render();
```

### Database Connection Factory Example

```php
<?php
declare(strict_types=1);

// Abstract Products
interface DatabaseConnection {
    public function connect(string $dsn): void;
    public function query(string $sql): array;
}

interface DatabaseMigration {
    public function createTable(string $name): string;
}

// Concrete Products - PostgreSQL
class PostgreSQLConnection implements DatabaseConnection {
    public function connect(string $dsn): void {
        // PostgreSQL connection logic
    }

    public function query(string $sql): array {
        return ['postgresql_results'];
    }
}

class PostgreSQLMigration implements DatabaseMigration {
    public function createTable(string $name): string {
        return "CREATE TABLE IF NOT EXISTS {$name} ...";
    }
}

// Concrete Products - MySQL
class MySQLConnection implements DatabaseConnection {
    public function connect(string $dsn): void {
        // MySQL connection logic
    }

    public function query(string $sql): array {
        return ['mysql_results'];
    }
}

class MySQLMigration implements DatabaseMigration {
    public function createTable(string $name): string {
        return "CREATE TABLE IF NOT EXISTS {$name} ...";
    }
}

// Abstract Factory
interface DatabaseFactory {
    public function createConnection(): DatabaseConnection;
    public function createMigration(): DatabaseMigration;
}

// Concrete Factories
class PostgreSQLFactory implements DatabaseFactory {
    public function createConnection(): DatabaseConnection {
        return new PostgreSQLConnection();
    }

    public function createMigration(): DatabaseMigration {
        return new PostgreSQLMigration();
    }
}

class MySQLFactory implements DatabaseFactory {
    public function createConnection(): DatabaseConnection {
        return new MySQLConnection();
    }

    public function createMigration(): DatabaseMigration {
        return new MySQLMigration();
    }
}

// Instantiation
$dbType = getenv('DB_TYPE') ?: 'mysql';
$factory = match($dbType) {
    'postgresql' => new PostgreSQLFactory(),
    'mysql' => new MySQLFactory(),
    default => throw new InvalidArgumentException("Unknown DB type: $dbType"),
};

$connection = $factory->createConnection();
$migration = $factory->createMigration();
```

## Real-World Analogies

**Furniture Store**: A furniture store has different style categories (Modern, Victorian, ArtDeco). Each style factory produces matching chairs, tables, and sofas. A customer selects one style factory, and all furniture comes from that family, ensuring consistency.

**Operating System UI**: An OS provides factories for creating buttons, windows, and dialogs. The Windows factory creates Windows-style components, while the macOS factory creates macOS-style components.

## Pros and Cons

### Advantages
- **Isolates Concrete Classes**: Client code depends only on abstract interfaces
- **Ensures Consistency**: Related products are guaranteed to work together
- **Easy to Add Families**: New product families can be added without modifying existing code
- **Single Responsibility**: Product creation is separated from usage
- **Open/Closed Principle**: System is open for extension but closed for modification

### Disadvantages
- **Increased Complexity**: More classes and interfaces to manage
- **Overkill for Simple Cases**: Can over-engineer if only one family exists
- **Adding New Product Types**: Requires changing all factory implementations
- **Less Flexible Than Builder**: Not ideal when object configuration varies significantly

## Relations with Other Patterns

- **Factory Method**: Abstract Factory is often implemented using Factory Methods
- **Singleton**: Concrete factories are often implemented as Singletons
- **Prototype**: Can be combined to handle object cloning within families
- **Builder**: Alternative pattern when constructing complex objects with many variants
- **Strategy**: Both encapsulate interchangeable alternatives but at different levels

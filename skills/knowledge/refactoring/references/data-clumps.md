# Data Clumps Code Smell

## Overview

Data clumps are groups of variables that repeatedly appear together throughout the codebase - as method parameters, class fields, or local variable sets. They represent a domain concept that has not yet been given its own name or type. A reliable test: remove one variable from the group and ask whether the remaining ones still make sense together. If they do not, the group is a clump and should be consolidated into a dedicated object.

## Why It's a Problem

When related data travels as separate variables instead of a unified object:

- **Weak Cohesion**: The conceptual relationship between the variables remains invisible to readers and tools
- **Scattered Updates**: Changes to the data structure must be propagated to every location where the clump appears
- **Bloated Signatures**: Method parameter lists grow unwieldy as each variable in the clump occupies its own slot
- **Hidden Abstraction**: A meaningful domain concept exists only implicitly, missing the chance to carry behavior alongside data
- **Repeated Patterns**: The same combination of parameters appears across unrelated methods, creating structural duplication

## Signs and Symptoms

- Multiple methods sharing the same parameter combination
- Class fields that are only meaningful when used together
- Identical parameter lists duplicated across different functions
- Long method signatures that would shrink dramatically if parameters were grouped
- Infrastructure details (host, port, username, password) passed as individual arguments
- Related value pairs (latitude/longitude, x/y, start/end) passed separately
- The same set of data assembled from scratch in multiple locations

## Before/After Examples

### Example 1: Database Connection Parameters

**Before** - Individual parameters scattered:

```php
<?php
declare(strict_types=1);

class UserRepository
{
    public function connect(string $host, int $port, string $username, string $password): void
    {
        // Connection logic
    }

    public function query(string $host, int $port, string $username, string $password, string $sql): array
    {
        return [];
    }
}

class ProductRepository
{
    public function connect(string $host, int $port, string $username, string $password): void
    {
        // Connection logic
    }
}
```

**After** - Consolidated into a parameter object:

```php
<?php
declare(strict_types=1);

readonly class DatabaseConnection
{
    public function __construct(
        public string $host,
        public int $port,
        public string $username,
        public string $password,
    ) {}
}

class UserRepository
{
    public function connect(DatabaseConnection $connection): void
    {
        // Connection logic using $connection->host, etc.
    }

    public function query(DatabaseConnection $connection, string $sql): array
    {
        return [];
    }
}

class ProductRepository
{
    public function connect(DatabaseConnection $connection): void
    {
        // Connection logic
    }
}
```

### Example 2: Coordinate Data

**Before** - Related values as individual parameters:

```php
<?php
declare(strict_types=1);

class MapService
{
    public function calculateDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        return sqrt(pow($lat2 - $lat1, 2) + pow($lon2 - $lon1, 2));
    }

    public function displayPoint(float $latitude, float $longitude, string $label): void
    {
        // Display logic
    }
}
```

**After** - Grouped into a value object:

```php
<?php
declare(strict_types=1);

readonly class Coordinate
{
    public function __construct(
        public float $latitude,
        public float $longitude,
    ) {}

    public function distanceTo(self $other): float
    {
        return sqrt(pow($other->latitude - $this->latitude, 2) +
                   pow($other->longitude - $this->longitude, 2));
    }
}

class MapService
{
    public function calculateDistance(Coordinate $point1, Coordinate $point2): float
    {
        return $point1->distanceTo($point2);
    }

    public function displayPoint(Coordinate $coordinate, string $label): void
    {
        // Display logic
    }
}
```

## Recommended Refactorings

### Extract Class
Create a new class that encapsulates the grouped data. This is ideal when the clump represents a meaningful domain concept. Move both data and related operations into this new class.

### Introduce Parameter Object
Combine multiple method parameters into a single parameter object. This simplifies method signatures and makes the relationship between parameters explicit. Use readonly classes for immutable value objects.

### Preserve Whole Object
Instead of extracting individual fields from an object and passing them as separate parameters, pass the entire object. This reduces the parameter count and makes dependencies clearer.

### Extract Methods
Move logic that operates on the data clump into the new class. This consolidates related behavior alongside related data, improving cohesion.

## Exceptions

Data clumps are acceptable when:

- The variables are used independently in different contexts and only sometimes appear together
- The grouping is temporary or specific to a single method
- You're dealing with primitive configuration values that don't warrant a new class
- The clump consists of only 2-3 related values with minimal interdependence

Avoid over-engineering by creating classes for every small group of parameters.

## Related Smells

- **Long Parameter List**: Shares the same core remedies - Introduce Parameter Object and Preserve Whole Object address both smells
- **Primitive Obsession**: Data clumps are often composed entirely of primitives that should be wrapped in value objects
- **Feature Envy**: When a class works heavily with another class's clumped data, the data (and its behavior) may belong in a different location
- **Divergent Change**: Clumps from mixed concerns embedded in one class signal that responsibilities should be separated

Once a data clump is extracted into its own class, look for operations in client code that act on those fields - they likely belong inside the new class too. Consolidating both the data and its associated logic in one place improves organization and shrinks the overall codebase.

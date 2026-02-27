# Data Clumps Code Smell

## Overview

Data clumps occur when the same group of variables appear together in multiple locations throughout your codebase. These are typically related data elements that are passed around as individual parameters, stored in separate fields, or repeated in method signatures. Recognizing and consolidating these clumps improves code organization and maintainability.

The key indicator: if you can remove one variable from a group and the remaining variables no longer make sense together, they form a data clump and should be consolidated into a single cohesive object.

## Why It's a Problem

When related data is scattered across your code as individual variables instead of being grouped together:

- **Reduced Cohesion**: Related data isn't treated as a unified concept, making code harder to understand
- **Maintenance Burden**: Changes to the data structure require updates in multiple locations
- **Parameter Bloat**: Method signatures become cluttered with numerous parameters
- **Missed Abstractions**: The conceptual grouping remains implicit rather than explicit
- **Code Duplication**: The same parameter patterns are repeated throughout the codebase

## Signs and Symptoms

- Multiple methods accepting the same set of parameters
- Classes with fields that are always used together
- Copy-pasted parameter lists across different functions
- Long parameter lists that could be simplified
- Database connection details (host, port, username, password) passed individually
- Coordinate pairs (x, y) or similar related values passed separately
- Complex objects built from scratch in multiple locations with identical data

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

- **Long Parameter List**: Often resolved by the same refactorings as data clumps
- **Primitive Obsession**: Using primitives instead of small value objects (data clumps are a symptom)
- **Feature Envy**: Classes using another object's data heavily (may indicate a data clump in the wrong location)
- **Divergent Change**: When multiple reasons to change the same class, data clumps might be mixed concerns

## Refactoring.guru Guidance

### Signs and Symptoms
Different parts of the code contain identical groups of variables (such as parameters for connecting to a database). These clumps should be turned into their own classes.

### Reasons for the Problem
Repeated data groups frequently arise from inadequate program design or duplicative coding practices. A useful test: remove one data value and check whether the remaining values retain coherence. If not, combining them into a dedicated object is advisable.

### Treatment
- **Extract Class** when data clumps constitute class fields
- **Introduce Parameter Object** for recurring method parameters
- **Preserve Whole Object** to pass complete objects rather than individual fields
- Evaluate relocating code that operates on these fields to the new data class

### Payoff
- Improves understanding and organization of code. Operations on particular data are now gathered in a single place, instead of haphazardly throughout the code
- Reduces code size

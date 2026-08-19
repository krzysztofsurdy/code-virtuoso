# Data Clumps Code Smell

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before and after](#before-and-after)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Data clumps are groups of variables that keep appearing together: as method parameters, class fields, or sets of local variables. They stand for a domain concept that has no name or type yet. A quick test: remove one variable from the group and ask whether the rest still make sense together. If they do not, the group is a clump and belongs in its own object.

## Why it's a problem

When related data travels as separate variables instead of one object:

- **Weak cohesion**: The relationship between the variables is invisible to readers and tools
- **Scattered updates**: A change to the data structure must be repeated everywhere the clump appears
- **Bloated signatures**: Parameter lists grow long because each variable in the clump takes its own slot
- **Hidden abstraction**: A domain concept exists only implicitly and cannot carry behavior next to its data
- **Repeated patterns**: The same combination of parameters appears in unrelated methods, which duplicates structure

## Signs and symptoms

- Multiple methods sharing the same parameter combination
- Class fields that are only meaningful when used together
- Identical parameter lists duplicated across different functions
- Long method signatures that would shrink if the parameters were grouped
- Infrastructure details (host, port, username, password) passed as individual arguments
- Related value pairs (latitude/longitude, x/y, start/end) passed separately
- The same set of data assembled from scratch in several places

## Before and after

### Example 1: Database connection parameters

**Before** - individual parameters:

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

**After** - consolidated into a parameter object:

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

### Example 2: Coordinate data

**Before** - related values as individual parameters:

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

**After** - grouped into a value object:

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

## Recommended refactorings

### Extract Class
Create a new class for the grouped data. This works best when the clump is a real domain concept. Move both the data and its related operations into the new class.

### Introduce Parameter Object
Combine several method parameters into one parameter object. Signatures get shorter and the relationship between the parameters becomes explicit. Use readonly classes for immutable value objects.

### Preserve Whole Object
Instead of extracting individual fields from an object and passing them as separate parameters, pass the entire object. The parameter count drops and dependencies are clearer.

### Extract Method
Move logic that operates on the data clump into the new class. Related behavior then sits next to related data, which improves cohesion.

## Exceptions

Data clumps are acceptable when:

- The variables are used independently in different contexts and only sometimes appear together
- The grouping is temporary or specific to a single method
- The values are primitive configuration values that do not justify a new class
- The clump has only 2-3 related values with little interdependence

Do not create a class for every small group of parameters.

## Related smells

- **Long Parameter List**: Shares the same core remedies: Introduce Parameter Object and Preserve Whole Object address both smells
- **Primitive Obsession**: Data clumps are often composed entirely of primitives that should be wrapped in value objects
- **Feature Envy**: When a class works heavily with another class's clumped data, the data (and its behavior) may belong elsewhere
- **Divergent Change**: Clumps from mixed concerns in one class suggest the responsibilities should be separated

Once a data clump is extracted into its own class, look for operations in client code that act on those fields. They likely belong in the new class too. Keeping the data and its logic together improves organization and shrinks the codebase.

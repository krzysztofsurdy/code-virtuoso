## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before/After](#beforeafter)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related Refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Replace Array with Object converts an array that holds a fixed set of distinct values into a dedicated object with named properties. Arrays are meant for homogeneous collections. When each index has its own meaning, an object with typed properties states that structure directly. It also brings tooling support, validation, and encapsulation.

## Motivation

Positional array indices used as structured data create several hazards:

- **No type enforcement**: Any index can hold any value, which defeats static analysis
- **Opaque access**: `$person[0]` says nothing about what it contains; `$person->name` does
- **Fragile ordering**: Inserting or reordering elements breaks every access site
- **Missing IDE support**: Editors cannot autocomplete or rename array keys the way they can properties
- **No home for behavior**: Arrays cannot have methods, so related logic ends up scattered elsewhere

An object with named, typed properties makes the structure explicit and gives related behavior a place to live.

## Mechanics

1. Create a new class or value object with named properties matching the array indices
2. Add a constructor to initialize the object from array data, if needed
3. Add properties and methods for accessing and manipulating the data
4. Replace all array creation calls with object instantiation
5. Replace all array access (`$arr[0]`) with property access (`$obj->field`)
6. Remove temporary array usage patterns
7. Add type hints and validation as appropriate

## Before/After

### Before: using arrays

```php
// Poor: Magic indices, unclear structure
function getUserInfo($userId): array {
    $user = fetchUserData($userId);
    return [$user['name'], $user['email'], $user['age']];
}

// Unclear what each index means
$info = getUserInfo(42);
echo $info[0]; // Is this the name? No type safety
echo $info[1]; // Email? Confusing

// Brittle: reordering breaks code
function displayUser($data): void {
    echo "Name: " . $data[0];
    echo "Email: " . $data[1];
    echo "Age: " . $data[2];
}
```

### After: using objects (PHP 8.3+)

```php
// Good: Self-documenting, type-safe
final readonly class UserInfo {
    public function __construct(
        public string $name,
        public string $email,
        public int $age,
    ) {}

    public function isAdult(): bool {
        return $this->age >= 18;
    }

    public function getDisplayName(): string {
        return ucfirst($this->name);
    }
}

function getUserInfo($userId): UserInfo {
    $user = fetchUserData($userId);
    return new UserInfo(
        name: $user['name'],
        email: $user['email'],
        age: $user['age'],
    );
}

// Clear, type-safe, refactorable
$info = getUserInfo(42);
echo $info->name; // IDE autocomplete, type checking
echo $info->email;
echo $info->age;

function displayUser(UserInfo $data): void {
    echo "Name: " . $data->getDisplayName();
    echo "Email: " . $data->email;
    if ($data->isAdult()) {
        echo "Age: " . $data->age;
    }
}
```

### Coordinate array example

```php
// Before: Numeric indices
$point = [10, 20, 'red'];
function movePoint(array $point, int $dx, int $dy): array {
    return [$point[0] + $dx, $point[1] + $dy, $point[2]];
}

// After: Semantic object
final readonly class Point {
    public function __construct(
        public int $x,
        public int $y,
        public string $color,
    ) {}

    public function move(int $dx, int $dy): self {
        return new self(
            x: $this->x + $dx,
            y: $this->y + $dy,
            color: $this->color,
        );
    }

    public function distance(Point $other): float {
        return sqrt(
            pow($this->x - $other->x, 2) +
            pow($this->y - $other->y, 2)
        );
    }
}

$point = new Point(x: 10, y: 20, color: 'red');
$moved = $point->move(5, 5);
$dist = $point->distance($moved);
```

## Benefits

- **Type safety**: Type hints catch misassignments before the code runs
- **Readable by default**: Named properties make every access self-documenting
- **Tooling support**: Autocomplete, rename refactoring, and static analysis all work
- **Built-in validation**: Constructors can enforce invariants at creation time
- **Room to grow**: Methods can be added without restructuring callers
- **Easier test setup**: Objects with clear constructors are simple to build in test fixtures
- **Tolerant of change**: Adding a property with a default does not break existing call sites

## When NOT to use

- **Variable-length collections**: Use arrays or `Collection` objects for lists of unknown size
- **Homogeneous data**: Arrays are appropriate for collections of similar items
- **Pure data transport**: Very simple DTOs might be overkill (though typed properties are still recommended)
- **Legacy code**: Refactor gradually, one usage at a time
- **Performance-critical hot paths**: Profile first; modern PHP is fast enough for most use cases

## Related Refactorings

- **Extract Class**: Move related properties into their own class
- **Introduce Parameter Object**: Group method parameters into an object
- **Replace Magic Number with Symbolic Constant**: Use named constants alongside object properties
- **Replace Data Value with Object**: Create immutable objects that represent domain concepts
- **Builder pattern**: Use builders for complex object construction

## Examples in other languages

### Java

**Before:**
```java
String[] row = new String[2];
row[0] = "Liverpool";
row[1] = "15";
```

**After:**
```java
Performance row = new Performance();
row.setName("Liverpool");
row.setWins("15");
```

### C#

**Before:**
```csharp
string[] row = new string[2];
row[0] = "Liverpool";
row[1] = "15";
```

**After:**
```csharp
Performance row = new Performance();
row.SetName("Liverpool");
row.SetWins("15");
```

### Python

**Before:**
```python
row = [None] * 2
row[0] = "Liverpool"
row[1] = "15"
```

**After:**
```python
row = Performance()
row.setName("Liverpool")
row.setWins("15")
```

### TypeScript

**Before:**
```typescript
let row = new Array(2);
row[0] = "Liverpool";
row[1] = "15";
```

**After:**
```typescript
let row = new Performance();
row.setName("Liverpool");
row.setWins("15");
```

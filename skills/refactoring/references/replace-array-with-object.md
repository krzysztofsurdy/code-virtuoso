## Overview

Replace Array with Object is a refactoring technique that converts arrays with a fixed structure and indexed access into proper objects or value objects. This improves code readability, type safety, and maintainability by replacing magic indices with named properties and providing semantic meaning to data structures.

Arrays are designed for homogeneous collections of items accessed by numeric indices. When you use an array to hold a fixed set of values with specific meaning at each position, you're fighting against the structure's intent. Objects with named properties make the code self-documenting and enable IDE support, type checking, and better encapsulation.

## Motivation

Magic numbers and unclear array indices create several problems:

- **Type Safety**: Arrays don't enforce structure; any index can contain any value
- **Readability**: `$person[0]` is unclear; `$person->name` is self-documenting
- **Maintainability**: Adding or reordering fields breaks all array access code
- **IDE Support**: No autocomplete or refactoring support for array indices
- **Validation**: No built-in way to validate object construction
- **Evolution**: Objects can have methods and business logic; arrays cannot

Replacing arrays with objects makes intent explicit and code more resilient to change.

## Mechanics

1. Create a new class or value object with named properties matching array indices
2. Add a constructor to initialize the object from array data (if needed)
3. Add properties and methods for accessing and manipulating data
4. Replace all array creation calls with object instantiation
5. Replace all array access (`$arr[0]`) with property access (`$obj->field`)
6. Remove temporary array usage patterns
7. Add type hints and validation as appropriate

## Before/After

### Before: Using Arrays

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

### After: Using Objects (PHP 8.3+)

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

### Complex Example: Coordinate Array

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

- **Type Safety**: Type hints prevent passing wrong values to wrong properties
- **Self-Documenting**: Code reads naturally without needing comments
- **IDE Support**: Full autocomplete, rename refactoring, and static analysis
- **Encapsulation**: Objects can validate construction and provide methods
- **Evolution**: Add methods without breaking existing code; add properties with defaults
- **Testing**: Easier to create test doubles and mock objects
- **Performance**: Modern PHP optimizes object property access efficiently
- **Maintainability**: Clear intent makes code easier to understand and modify

## When NOT to Use

- **Variable-Length Collections**: Use arrays or `Collection` objects for lists of unknown size
- **Homogeneous Data**: Arrays are appropriate for collections of similar items
- **Pure Data Transport**: Very simple DTOs might be overkill (though typed properties are still recommended)
- **Legacy Code**: Gradual refactoring may be necessary; do this incrementally
- **Performance-Critical Hot Paths**: Profile first; modern PHP is fast enough for most use cases

## Related Refactorings

- **Extract Class**: Move related properties into their own class
- **Introduce Parameter Object**: Group method parameters into an object
- **Replace Magic Numbers**: Use named constants alongside object properties
- **Extract Value Object**: Create immutable objects that represent domain concepts
- **Introduce Builder**: Use builders for complex object construction

## Examples in Other Languages

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
row = [None * 2]
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

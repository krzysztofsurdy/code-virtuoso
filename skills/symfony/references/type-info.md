# Symfony TypeInfo Component

## Overview

The TypeInfo component extracts and manipulates type information from PHP elements like properties, arguments, and return types. It provides a powerful `Type` definition system that handles unions, intersections, generics, and array shapes with the ability to resolve types from PHP elements or raw strings.

## Installation

```bash
composer require symfony/type-info
```

For PHPDoc parsing support, also require:
```bash
composer require phpstan/phpdoc-parser
```

## Core Type Creation

### Static Type Creation

Create types using static factory methods on the `Type` class:

```php
use Symfony\Component\TypeInfo\Type;

// Scalar types
Type::int();
Type::float();
Type::string();
Type::bool();
Type::array();
Type::object(Collection::class);

// Nullable types
Type::nullable(Type::string());

// Generic types with parameters
Type::generic(Type::object(Collection::class), Type::int());
Type::list(Type::bool());

// Unions
Type::union(Type::string(), Type::int());

// Intersections
Type::intersection(
    Type::object(\Stringable::class),
    Type::object(\Iterator::class)
);

// Array shapes
Type::arrayShape([
    'name' => Type::string(),
    'age' => Type::int()
]);

// Unsealed array shapes with typed extras
Type::arrayShape([
    'id' => Type::int(),
], false, Type::string(), Type::bool());
```

### Auto-detect Types from Values

Automatically determine types from PHP values:

```php
Type::fromValue(1.1);           // Type::float()
Type::fromValue('string');      // Type::string()
Type::fromValue(false);         // Type::false()
Type::fromValue(true);          // Type::true()
Type::fromValue([]);            // Type::array()
Type::fromValue(new \stdClass); // Type::object()
```

## Type Resolution

### Resolving from Reflection

Use `TypeResolver` to extract types from PHP reflection elements:

```php
use Symfony\Component\TypeInfo\TypeResolver\TypeResolver;

class Dummy
{
    public function __construct(
        public int $id,
    ) {}

    public function process(string $name): bool {}
}

$typeResolver = TypeResolver::create();

// Resolve property type
$typeResolver->resolve(new \ReflectionProperty(Dummy::class, 'id'));
// Returns: Type::int()

// Resolve method parameter type
$method = new \ReflectionMethod(Dummy::class, 'process');
$typeResolver->resolve($method->getParameters()[0]);
// Returns: Type::string()

// Resolve return type
$typeResolver->resolve($method);
// Returns: Type::bool()
```

### Resolving from Strings

Parse string type definitions:

```php
$typeResolver = TypeResolver::create();

// Simple types
$typeResolver->resolve('bool');           // Type::bool()
$typeResolver->resolve('string|int');     // Union type
$typeResolver->resolve('?string');        // Nullable string

// Array shapes
$typeResolver->resolve('array{id: int, name?: string}');

// Generic types
$typeResolver->resolve('Collection<int>');
$typeResolver->resolve('list<string>');
```

## PHPDoc Type Resolution

Extract types from PHPDoc annotations:

```php
class Dummy
{
    public function __construct(
        public int $id,
        /** @var string[] $tags */
        public array $tags,
    ) {}
}

$typeResolver = TypeResolver::create();
$typeResolver->resolve(new \ReflectionProperty(Dummy::class, 'tags'));
// Resolves to collection type with int keys and string values
```

## Type Aliases

### Define Type Aliases

Create reusable complex type definitions using PHPDoc:

```php
/**
 * @phpstan-type UserData = array{name: string, email: string, age: int}
 */
class UserService
{
    /**
     * @var UserData
     */
    public mixed $userData;

    /**
     * @param UserData $data
     */
    public function process(mixed $data): void {}
}
```

### Import Type Aliases

Import aliases from other classes:

```php
/**
 * @phpstan-import-type Address from Location
 */
class Company
{
    /**
     * @var Address
     */
    public mixed $headquarters;
}
```

### Global Type Alias Configuration

Define reusable aliases in framework configuration (YAML):

```yaml
framework:
    type_info:
        aliases:
            MoneyAmount: int
            Email: string
            UserData: 'array{name: string, email: string, age: int}'
            CustomCollection: 'Collection<Item>'
```

## Array Shapes

### Array Shape Definition

Describe array structures with specific key-value relationships:

```php
/**
 * @var array{name: string, age: int, email?: string}
 */
public array $person;
```

### Sealed vs. Unsealed Arrays

Control whether extra keys are allowed:

```php
// Sealed: only accepts specified keys
// @var array{id: int}

// Unsealed: accepts specified keys plus any extra entries
// @var array{id: int, ...}

// Unsealed with typed extras
// @var array{id: int, ...<string, bool>}
```

### Manual Array Shape Creation

Programmatically create array shapes:

```php
use Symfony\Component\TypeInfo\Type;

// Sealed array shape
$type = Type::arrayShape([
    'name' => Type::string(),
    'age' => Type::int()
]);

// With optional keys
$type = Type::arrayShape([
    'required_id' => Type::int(),
    'optional_name' => ['type' => Type::string(), 'optional' => true],
]);

// Unsealed (allows extra keys)
$type = Type::arrayShape([
    'id' => Type::int(),
], false);

// Unsealed with typed extras (extra keys must be string->bool)
$type = Type::arrayShape([
    'id' => Type::int(),
], false, Type::string(), Type::bool());
```

## Type Identification

### Check Type Identity

Identify types using `TypeIdentifier`:

```php
use Symfony\Component\TypeInfo\TypeIdentifier;

$type = Type::int();
$type->isIdentifiedBy(TypeIdentifier::INT);    // true
$type->isIdentifiedBy(TypeIdentifier::STRING); // false

// For unions, checks if any component matches
$type = Type::union(Type::string(), Type::int());
$type->isIdentifiedBy(TypeIdentifier::INT);    // true
```

### Check Value Acceptance

Validate if values match a type:

```php
$type = Type::int();
$type->accepts(123);      // true
$type->accepts('z');      // false

$stringType = Type::string();
$stringType->accepts('hello');  // true
$stringType->accepts(123);      // false
```

### Check Nullability

Determine if a type accepts null:

```php
$type = Type::nullable(Type::string());
$type->isNullable();  // true

$type = Type::int();
$type->isNullable();  // false
```

## Advanced Type Checking

### Satisfy Custom Predicates

Use callables to validate types against custom logic:

```php
$isNonNullableNumber = function (Type $type): bool {
    if ($type->isNullable()) {
        return false;
    }
    return $type->isIdentifiedBy(TypeIdentifier::INT) ||
           $type->isIdentifiedBy(TypeIdentifier::FLOAT);
};

$integerType = Type::int();
$integerType->isSatisfiedBy($isNonNullableNumber); // true

$nullableInt = Type::nullable(Type::int());
$nullableInt->isSatisfiedBy($isNonNullableNumber); // false
```

## Common Use Cases

### Extract and Validate Reflection Types

```php
$typeResolver = TypeResolver::create();
$property = new \ReflectionProperty(MyClass::class, 'email');
$type = $typeResolver->resolve($property);

if ($type->isIdentifiedBy(TypeIdentifier::STRING)) {
    // Process as string
}
```

### Handle Union and Optional Types

```php
$type = Type::union(Type::string(), Type::int(), Type::null());

if ($type->accepts($value)) {
    // Process accepted value
}
```

### Work with Generic Collections

```php
$listType = Type::list(Type::object(User::class));

// Process list of User objects
```

### Validate Array Structures

```php
$schema = Type::arrayShape([
    'id' => Type::int(),
    'name' => Type::string(),
    'active' => Type::bool(),
]);

if ($schema->accepts($data)) {
    // Data matches schema
}
```

## Type Identifiers

Common type identifiers available via `TypeIdentifier` class:

- `INT` - Integer type
- `FLOAT` - Float type
- `STRING` - String type
- `BOOL` - Boolean type
- `TRUE` - Literal true type
- `FALSE` - Literal false type
- `ARRAY` - Array type
- `OBJECT` - Object type
- `CALLABLE` - Callable type
- `ITERABLE` - Iterable type
- `UNION` - Union type
- `INTERSECTION` - Intersection type
- `NULLABLE` - Nullable type wrapper

# Symfony TypeInfo component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core type creation](#core-type-creation)
- [Type resolution](#type-resolution)
- [PHPDoc type resolution](#phpdoc-type-resolution)
- [Type aliases](#type-aliases)
- [Array shapes](#array-shapes)
- [Type identification](#type-identification)
- [Advanced type checking](#advanced-type-checking)
- [Common use cases](#common-use-cases)
- [Type identifiers](#type-identifiers)

## Overview

The TypeInfo component extracts and manipulates type information from PHP elements such as properties, arguments, and return types. Its `Type` classes cover unions, intersections, generics, and array shapes, and types can be resolved from PHP elements or from raw strings.

## Installation

```bash
composer require symfony/type-info
```

For PHPDoc parsing, also require:

```bash
composer require phpstan/phpdoc-parser
```

## Core type creation

### Static type creation

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

### Detect types from values

Determine types from PHP values:

```php
Type::fromValue(1.1);           // Type::float()
Type::fromValue('string');      // Type::string()
Type::fromValue(false);         // Type::false()
Type::fromValue(true);          // Type::true()
Type::fromValue([]);            // Type::array()
Type::fromValue(new \stdClass); // Type::object()
```

## Type resolution

### Resolving from reflection

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

### Resolving from strings

Parse type definitions written as strings:

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

## PHPDoc type resolution

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

## Type aliases

### Define type aliases

Define reusable complex types with PHPDoc:

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

### Import type aliases

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

### Global type alias configuration

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

## Array shapes

### Array shape definition

Describe array structures with specific key-value relationships:

```php
/**
 * @var array{name: string, age: int, email?: string}
 */
public array $person;
```

### Sealed and unsealed arrays

A sealed shape rejects extra keys; an unsealed shape allows them:

```php
// Sealed: only accepts specified keys
// @var array{id: int}

// Unsealed: accepts specified keys plus any extra entries
// @var array{id: int, ...}

// Unsealed with typed extras
// @var array{id: int, ...<string, bool>}
```

### Manual array shape creation

Build array shapes in code:

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

## Type identification

### Check type identity

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

### Check value acceptance

Check whether a value matches a type:

```php
$type = Type::int();
$type->accepts(123);      // true
$type->accepts('z');      // false

$stringType = Type::string();
$stringType->accepts('hello');  // true
$stringType->accepts(123);      // false
```

### Check nullability

Check whether a type accepts null:

```php
$type = Type::nullable(Type::string());
$type->isNullable();  // true

$type = Type::int();
$type->isNullable();  // false
```

## Advanced type checking

### Satisfy custom predicates

Pass a callable to test a type against custom logic:

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

## Common use cases

### Extract and validate reflection types

```php
$typeResolver = TypeResolver::create();
$property = new \ReflectionProperty(MyClass::class, 'email');
$type = $typeResolver->resolve($property);

if ($type->isIdentifiedBy(TypeIdentifier::STRING)) {
    // Process as string
}
```

### Handle union and optional types

```php
$type = Type::union(Type::string(), Type::int(), Type::null());

if ($type->accepts($value)) {
    // Process accepted value
}
```

### Work with generic collections

```php
$listType = Type::list(Type::object(User::class));

// Process list of User objects
```

### Validate array structures

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

## Type identifiers

Common identifiers on the `TypeIdentifier` class:

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

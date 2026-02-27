# Symfony PropertyInfo Component

## Overview

The PropertyInfo component extracts metadata about class properties from various sources. Unlike PropertyAccess (which reads/writes values), PropertyInfo discovers property types, descriptions, visibility, and accessibility from class definitions. It's essential for building frameworks, serializers, and type-aware tools.

## Installation

```bash
composer require symfony/property-info
```

## Core Setup

Create a PropertyInfoExtractor with appropriate extractors in order of precedence:

```php
use Symfony\Component\PropertyInfo\Extractor\PhpDocExtractor;
use Symfony\Component\PropertyInfo\Extractor\ReflectionExtractor;
use Symfony\Component\PropertyInfo\PropertyInfoExtractor;

$phpDocExtractor = new PhpDocExtractor();
$reflectionExtractor = new ReflectionExtractor();

$propertyInfo = new PropertyInfoExtractor(
    [$reflectionExtractor],                    // List extractors
    [$phpDocExtractor, $reflectionExtractor],  // Type extractors
    [$phpDocExtractor],                        // Description extractors
    [$reflectionExtractor],                    // Access extractors
    [$reflectionExtractor]                     // Initializable extractors
);
```

**Important:** Pass extractors in separate arrays even if they provide multiple information types. The first non-null result is returned.

## Extraction Methods

### List Properties
```php
// Get all property names for a class
$properties = $propertyInfo->getProperties(MyClass::class);
// Returns: ['username', 'email', 'roles', ...]
```

### Type Information
```php
$type = $propertyInfo->getType(MyClass::class, 'username');
if ($type) {
    $type->getBuiltinType();        // 'string', 'int', 'object', 'array', etc.
    $type->isNullable();             // bool
    $type->getClassName();           // 'ClassName' if type is 'object'
    $type->isCollection();           // bool
    $type->getCollectionKeyTypes(); // Type[] for array keys
    $type->getCollectionValueTypes(); // Type[] for array values
}
```

### Descriptions
```php
$title = $propertyInfo->getShortDescription(MyClass::class, 'username');
$paragraph = $propertyInfo->getLongDescription(MyClass::class, 'username');
```

### Access Information
```php
$propertyInfo->isReadable(MyClass::class, 'username');  // bool
$propertyInfo->isWritable(MyClass::class, 'username');  // bool
```

### Initializable Information
```php
// Returns true if constructor parameter matches property name
$propertyInfo->isInitializable(MyClass::class, 'username');
```

## Built-in Types

PropertyInfo supports these built-in types from `Type::getBuiltinType()`:

- `array` - Generic arrays
- `bool` - Boolean values
- `callable` - Functions/methods
- `float` - Floating point numbers
- `int` - Integers
- `iterable` - Iterables (implements Iterator/IteratorAggregate)
- `null` - Null type
- `object` - Class instances
- `resource` - PHP resources
- `string` - Text strings

## Available Extractors

### ReflectionExtractor
Uses PHP reflection for discovering properties, types from typed properties, access information, and initializable information.

```php
$extractor = new ReflectionExtractor();
// Supports: list, type, access, initializable
```

### PhpDocExtractor
Parses @var, @param, and @return PHPDoc annotations for type and description information.

```php
$extractor = new PhpDocExtractor();
// Requires: phpdocumentor/reflection-docblock
// Supports: type, description
```

### PhpStanExtractor
Uses PHPStan parser for @var, @param, and @return annotations with enhanced type support.

```php
$extractor = new PhpStanExtractor();
// Requires: phpstan/phpdoc-parser
// Supports: type, description
// Advantages: Supports union types, intersection types, generics
```

### SerializerExtractor
Extracts property list from Serializer component metadata (groups, context).

```php
$extractor = new SerializerExtractor($classMetadataFactory);
// Supports: list
// Use when: Serializer groups matter
```

### DoctrineExtractor
Uses Doctrine ORM entity mapping for list and type information.

```php
$extractor = new DoctrineExtractor($entityManager);
// Supports: list, type
// Use when: Working with Doctrine entities
```

### ConstructorExtractor
Extracts properties from constructor parameters using PHPStan or Reflection.

```php
$extractor = new ConstructorExtractor([$phpStanExtractor]);
// Supports: constructor argument types
// Use when: Constructor parameters define properties
```

## Type Objects Methods

The `Type` object returned by `getType()` provides six key methods:

| Method | Returns | Purpose |
|--------|---------|---------|
| `getBuiltinType()` | string | The built-in PHP type |
| `isNullable()` | bool | Whether property accepts null values |
| `getClassName()` | string | FQN of class if type is 'object' |
| `isCollection()` | bool | Whether type is a collection (array/iterable) |
| `getCollectionKeyTypes()` | Type[] | Types for collection keys |
| `getCollectionValueTypes()` | Type[] | Types for collection values |

## Type Examples

### Simple Types
```php
class User {
    private string $username;
    private ?int $age;
    private bool $active;
}
// getType() returns Type with:
// - $username: builtin='string', nullable=false
// - $age: builtin='int', nullable=true
// - $active: builtin='bool', nullable=false
```

### Collection Types
```php
class Team {
    /** @var User[] */
    private array $members;
}
// getType() returns Type with:
// - isCollection() = true
// - getCollectionValueTypes() = [Type(object, User)]
```

### Nullable Collections
```php
class Team {
    /** @var User[]|null */
    private ?array $members;
}
// getType() returns Type with:
// - isNullable() = true
// - isCollection() = true
// - getCollectionValueTypes() = [Type(object, User)]
```

## Custom Extractor Implementation

Implement one or more extractor interfaces:

```php
use Symfony\Component\PropertyInfo\PropertyListExtractorInterface;
use Symfony\Component\PropertyInfo\PropertyTypeExtractorInterface;

class CustomExtractor implements
    PropertyListExtractorInterface,
    PropertyTypeExtractorInterface
{
    public function getProperties(string $class, array $context = []): ?array
    {
        // Return array of property names or null
        return ['id', 'name', 'email'];
    }

    public function getType(string $class, string $property, array $context = []): ?Type
    {
        // Return Type object or null
        if ($property === 'id') {
            return new Type('int');
        }
        return null;
    }
}
```

Register with service tags:
- `property_info.list_extractor` - PropertyListExtractorInterface
- `property_info.type_extractor` - PropertyTypeExtractorInterface
- `property_info.description_extractor` - PropertyDescriptionExtractorInterface
- `property_info.access_extractor` - PropertyAccessExtractorInterface
- `property_info.initializable_extractor` - PropertyInitializableExtractorInterface
- `property_info.constructor_extractor` - ConstructorArgumentTypeExtractorInterface

## Framework Integration

### With Serializer
```php
use Symfony\Component\Serializer\Normalizer\ObjectNormalizer;

$normalizer = new ObjectNormalizer(
    classMetadataFactory: $metadataFactory,
    propertyInfo: $propertyInfo  // Pass PropertyInfoExtractor
);
// ObjectNormalizer uses PropertyInfo to understand property types
// for proper denormalization of complex structures
```

### With PropertyAccessor
```php
use Symfony\Component\PropertyAccess\PropertyAccessor;

$accessor = new PropertyAccessor(
    enableMagicCalls: PropertyAccessor::DISALLOW_MAGIC_METHODS,
    throwExceptionOnInvalidPropertyPath: PropertyAccessor::THROW_ON_INVALID_PROPERTY_PATH,
    propertyInfoExtractor: $reflectionExtractor,
);
// PropertyAccessor uses PropertyInfo to discover custom adder/remover methods
```

## Best Practices

### Always Use Class Names
```php
// Good - Pass fully qualified class name
$propertyInfo->getProperties(MyClass::class);
$propertyInfo->getType(MyClass::class, 'property');

// Avoid - Don't pass object instances
// $propertyInfo->getProperties($object);
```

### Order Extractors by Precedence
```php
// More specific extractors first, general fallbacks last
$propertyInfo = new PropertyInfoExtractor(
    [$reflectionExtractor],
    [
        $phpStanExtractor,      // Precise type support
        $phpDocExtractor,       // PHPDoc fallback
        $reflectionExtractor    // Native types fallback
    ],
    [$phpDocExtractor],
    [$reflectionExtractor],
    [$reflectionExtractor]
);
```

### Handle Nullable Returns
```php
// All extraction methods can return null
if ($type = $propertyInfo->getType($class, $property)) {
    // Type information available
} else {
    // Type information not available
}
```

### Leverage Multiple Sources
```php
// Use multiple extractors to get complete information
$propertyInfo = new PropertyInfoExtractor(
    [$reflectionExtractor],
    [$phpDocExtractor, $reflectionExtractor],
    [$phpDocExtractor],      // Descriptions from PHPDoc only
    [$reflectionExtractor],
    [$reflectionExtractor]
);
```

## Common Use Cases

### 1. Build a Form from Class Properties
```php
foreach ($propertyInfo->getProperties(User::class) as $property) {
    $type = $propertyInfo->getType(User::class, $property);
    $writable = $propertyInfo->isWritable(User::class, $property);

    if ($writable) {
        // Add form field based on type
    }
}
```

### 2. Create API Documentation
```php
$properties = $propertyInfo->getProperties(User::class);
foreach ($properties as $property) {
    echo $property . ': ';
    echo $propertyInfo->getShortDescription(User::class, $property);
}
```

### 3. Type-Aware Serialization
```php
$type = $propertyInfo->getType(User::class, 'roles');
if ($type && $type->isCollection()) {
    // Handle as array/collection
    foreach ($type->getCollectionValueTypes() as $valueType) {
        // Process each item's type
    }
}
```

### 4. Constructor Validation
```php
$initializableProps = [];
foreach ($propertyInfo->getProperties(User::class) as $prop) {
    if ($propertyInfo->isInitializable(User::class, $prop)) {
        $initializableProps[] = $prop;
    }
}
```

## Related Components

- **PropertyAccess** - Read/write object values dynamically
- **Serializer** - Normalize/denormalize objects using PropertyInfo for type hints
- **Form** - Build forms leveraging PropertyInfo for field generation
- **Validator** - Validate properties using type information

## Key Interfaces

All interfaces in `Symfony\Component\PropertyInfo`:

- `PropertyInfoExtractorInterface` - Main extractor interface (all methods)
- `PropertyListExtractorInterface` - Extract property names
- `PropertyTypeExtractorInterface` - Extract type information
- `PropertyDescriptionExtractorInterface` - Extract descriptions
- `PropertyAccessExtractorInterface` - Check readability/writability
- `PropertyInitializableExtractorInterface` - Check constructor initialization
- `ConstructorArgumentTypeExtractorInterface` - Extract constructor argument types

## Configuration Notes

- **phpdocumentor/reflection-docblock** - Required for PhpDocExtractor
- **phpstan/phpdoc-parser** - Required for PhpStanExtractor (more precise types)
- **symfony/serializer** - Required for SerializerExtractor
- **symfony/doctrine-bridge** - Required for DoctrineExtractor
- **doctrine/orm** - Required when using Doctrine entities

Install additional extractors as needed:
```bash
composer require phpstan/phpdoc-parser
composer require symfony/serializer
composer require symfony/doctrine-bridge
```

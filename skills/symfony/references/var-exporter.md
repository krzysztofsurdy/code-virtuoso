# Symfony VarExporter Component

## Overview

The VarExporter component serializes PHP data structures to executable PHP code, enabling instantiation and population of objects without invoking their constructors. It provides superior performance over `serialize()` through OPcache optimization while preserving object semantics.

## Installation

Install the component via Composer:

```bash
composer require symfony/var-exporter
```

## Core Features

### 1. Export Variables to PHP Code

Use `VarExporter::export()` to convert any PHP variable to executable PHP code:

```php
use Symfony\Component\VarExporter\VarExporter;

$data = ['key' => 'value', 'numbers' => [1, 2, 3]];
$exported = VarExporter::export($data);

// Store to file
file_put_contents('cache.php', '<?php return ' . $exported . ';');

// Regenerate later
$regenerated = require 'cache.php';
```

**Advantages over `serialize()`:**

- **Performance**: OPcache optimization yields faster, more memory-efficient results than `unserialize()`
- **Semantic Preservation**: Honors `__wakeup()`, `__sleep()`, and `Serializable` interface semantics
- **Reference Integrity**: Preserves references in `SplObjectStorage`, `ArrayObject`, `ArrayIterator`
- **Safe Errors**: Throws `ClassNotFoundException` for missing classes (no incomplete objects)
- **Type Safety**: Rejects unsupported types like `Reflection*`, `IteratorIterator`, `RecursiveIteratorIterator`

### 2. Instantiate Objects Without Constructors

The `Instantiator` class creates objects and sets properties bypassing constructors:

```php
use Symfony\Component\VarExporter\Instantiator;

// Create empty instance
$object = Instantiator::instantiate(MyClass::class);

// Create with public properties
$object = Instantiator::instantiate(MyClass::class, [
    'propertyName' => $propertyValue
]);
```

**Set Parent Class Properties:**

```php
// MyClass extends ParentClass with private properties
$object = Instantiator::instantiate(MyClass::class, [], [
    ParentClass::class => [
        'privateParentProperty' => $value
    ]
]);
```

**Handle Special Collections:**

```php
// SplObjectStorage with object-info associations
$storage = Instantiator::instantiate(SplObjectStorage::class, [
    "\0" => [$object1, $metadata1, $object2, $metadata2]
]);

// ArrayObject with input array
$arrayObj = Instantiator::instantiate(ArrayObject::class, [
    "\0" => [['key' => 'value']]
]);

// ArrayIterator
$iterator = Instantiator::instantiate(ArrayIterator::class, [
    "\0" => [['a' => 1, 'b' => 2]]
]);
```

### 3. Hydrate Existing Objects

The `Hydrator` populates properties of already-instantiated objects:

```php
use Symfony\Component\VarExporter\Hydrator;

$object = new MyClass();

// Populate public properties
Hydrator::hydrate($object, ['propertyName' => $value]);
```

**Set Parent Class Properties:**

```php
// Method 1: Using nested class specification
Hydrator::hydrate($object, [], [
    ParentClass::class => ['privateProperty' => $value]
]);

// Method 2: Using special "\0" syntax
Hydrator::hydrate($object, [
    "\0ParentClass\0privateProperty" => $value
]);
```

**Hydrate Special Collections:**

```php
$storage = new SplObjectStorage();
Hydrator::hydrate($storage, [
    "\0" => [$object1, $info1, $object2, $info2]
]);

$arrayObj = new ArrayObject();
Hydrator::hydrate($arrayObj, [
    "\0" => [['key' => 'value']]
]);
```

### 4. Create Lazy Proxy Objects

Generate lazy proxy decorators for deferred initialization (works with abstracts, interfaces, and internal classes):

```php
use Symfony\Component\VarExporter\ProxyHelper;

// Generate proxy code from reflection
$proxyCode = ProxyHelper::generateLazyProxy(
    new \ReflectionClass(YourInterface::class)
);

// Save to file or eval in development
eval('class ProxyDecorator' . $proxyCode);

// Create lazy instance with custom initializer
$proxy = ProxyDecorator::createLazyProxy(
    initializer: function (): YourInterface {
        // Heavy initialization happens on first property access
        $instance = new HeavyClass($dependency1, $dependency2);
        $instance->setUp(); // Optional configuration

        return $instance;
    }
);
```

**Benefits:**

- Defer expensive object initialization until actually needed
- Works with abstract classes, interfaces, and internal classes
- Transparent proxy behaves like real instance after initialization
- Superior to native PHP 8.4 lazy objects for complex scenarios

## Common Use Cases

### Cache Serialization

```php
use Symfony\Component\VarExporter\VarExporter;

$cacheKey = 'my_config_cache';
$configData = loadExpensiveConfig();

// Export to cache file
$code = VarExporter::export($configData);
file_put_contents("/tmp/$cacheKey.php", '<?php return ' . $code . ';');

// Later: retrieve from cache (OPcache optimized)
$cachedData = require "/tmp/$cacheKey.php";
```

### Dependency Injection Setup

```php
use Symfony\Component\VarExporter\Instantiator;

class ServiceFactory {
    public function create(array $config): Service {
        return Instantiator::instantiate(Service::class, $config);
    }
}
```

### Object Cloning Without Side Effects

```php
use Symfony\Component\VarExporter\VarExporter;
use Symfony\Component\VarExporter\Instantiator;

$original = new MyClass();
$exported = VarExporter::export($original);
$cloned = Instantiator::instantiate(MyClass::class, eval('return ' . $exported . ';'));
```

## Key Classes and Methods

| Class | Method | Purpose |
|-------|--------|---------|
| `VarExporter` | `export($var)` | Export variable to PHP code string |
| `Instantiator` | `instantiate($class, $properties = [], $parentProperties = [])` | Create object without constructor |
| `Hydrator` | `hydrate($object, $properties = [], $parentProperties = [])` | Populate existing object properties |
| `ProxyHelper` | `generateLazyProxy(ReflectionClass $reflectionClass)` | Generate lazy proxy decorator code |

## Property Access Syntax

- **Public properties**: Use property name directly: `['propertyName' => value]`
- **Private/protected**: Use nested class notation: `[ClassName::class => ['propertyName' => value]]`
- **Special values**: Use `"\0"` for internal collection data: `["\0" => [data]]`
- **Parent class private**: Use notation: `"\0ParentClass\0propertyName"`

## Generated Code Characteristics

Exported code is:

- **PSR-2 compliant** for consistency and readability
- **OPcache-compatible** for optimal performance
- **Reference-preserving** across object hierarchies
- **Self-contained** with no external dependencies

Example generated structure:

```php
return \Symfony\Component\VarExporter\Internal\Hydrator::hydrate(
    $o = [clone \Symfony\Component\VarExporter\Internal\Registry::$prototypes[ClassName::class] ??
          \Symfony\Component\VarExporter\Internal\Registry::p(ClassName::class)],
    null,
    [ClassName::class => ['property' => [value]]],
    $o[0],
    []
);
```

## Error Handling

- **`ClassNotFoundException`**: Thrown when exported class doesn't exist on deserialization
- **`ExceptionInterface`**: Check for unsupported types or serialization issues
- Invalid types like `Reflection*` automatically throw exceptions

## Performance Considerations

- **VarExporter** excels with configuration and static data caching
- **OPcache** dramatically improves performance over `unserialize()`
- **Lazy proxies** reduce initialization overhead for heavy objects
- **Instantiator** avoids constructor side effects for faster object creation

## PHP Version Requirements

- Component works with PHP 7.4+
- Lazy proxy features optimized for PHP 8.4+
- No external dependencies beyond autoloading

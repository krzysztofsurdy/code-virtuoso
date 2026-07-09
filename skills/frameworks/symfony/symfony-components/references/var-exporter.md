# Symfony VarExporter component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core features](#core-features)
- [Common use cases](#common-use-cases)
- [Key classes and methods](#key-classes-and-methods)
- [Property access syntax](#property-access-syntax)
- [Generated code](#generated-code)
- [Error handling](#error-handling)
- [Performance](#performance)
- [PHP version requirements](#php-version-requirements)

## Overview

The VarExporter component serializes PHP data structures to executable PHP code and can instantiate and populate objects without calling their constructors. Because the output is plain PHP, OPcache can cache it, which makes loading faster than `unserialize()` while object semantics are preserved.

## Installation

Install the component with Composer:

```bash
composer require symfony/var-exporter
```

## Core features

### 1. Export variables to PHP code

`VarExporter::export()` converts a PHP variable to executable PHP code:

```php
use Symfony\Component\VarExporter\VarExporter;

$data = ['key' => 'value', 'numbers' => [1, 2, 3]];
$exported = VarExporter::export($data);

// Store to file
file_put_contents('cache.php', '<?php return ' . $exported . ';');

// Regenerate later
$regenerated = require 'cache.php';
```

Advantages over `serialize()`:

- **Performance**: OPcache makes loading faster and more memory-efficient than `unserialize()`
- **Semantics**: Honors `__wakeup()`, `__sleep()`, and `Serializable`
- **References**: Preserves references in `SplObjectStorage`, `ArrayObject`, `ArrayIterator`
- **Errors**: Throws `ClassNotFoundException` for missing classes instead of producing incomplete objects
- **Types**: Rejects unsupported types such as `Reflection*`, `IteratorIterator`, `RecursiveIteratorIterator`

### 2. Instantiate objects without constructors

`Instantiator` creates objects and sets their properties without calling the constructor:

```php
use Symfony\Component\VarExporter\Instantiator;

// Create empty instance
$object = Instantiator::instantiate(MyClass::class);

// Create with public properties
$object = Instantiator::instantiate(MyClass::class, [
    'propertyName' => $propertyValue
]);
```

Set parent class properties:

```php
// MyClass extends ParentClass with private properties
$object = Instantiator::instantiate(MyClass::class, [], [
    ParentClass::class => [
        'privateParentProperty' => $value
    ]
]);
```

Handle special collections:

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

### 3. Hydrate existing objects

`Hydrator` populates the properties of objects that already exist:

```php
use Symfony\Component\VarExporter\Hydrator;

$object = new MyClass();

// Populate public properties
Hydrator::hydrate($object, ['propertyName' => $value]);
```

Set parent class properties:

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

Hydrate special collections:

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

### 4. Create lazy proxy objects

Generate lazy proxy decorators for deferred initialization. This works with abstract classes, interfaces, and internal classes:

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

Benefits:

- Expensive initialization is deferred until the object is used
- Works with abstract classes, interfaces, and internal classes
- After initialization the proxy behaves like the real instance
- Handles more complex cases than native PHP 8.4 lazy objects

## Common use cases

### Cache serialization

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

### Dependency injection setup

```php
use Symfony\Component\VarExporter\Instantiator;

class ServiceFactory {
    public function create(array $config): Service {
        return Instantiator::instantiate(Service::class, $config);
    }
}
```

### Object cloning without side effects

```php
use Symfony\Component\VarExporter\VarExporter;
use Symfony\Component\VarExporter\Instantiator;

$original = new MyClass();
$exported = VarExporter::export($original);
$cloned = Instantiator::instantiate(MyClass::class, eval('return ' . $exported . ';'));
```

## Key classes and methods

| Class | Method | Purpose |
|-------|--------|---------|
| `VarExporter` | `export($var)` | Export variable to PHP code string |
| `Instantiator` | `instantiate($class, $properties = [], $parentProperties = [])` | Create object without constructor |
| `Hydrator` | `hydrate($object, $properties = [], $parentProperties = [])` | Populate existing object properties |
| `ProxyHelper` | `generateLazyProxy(ReflectionClass $reflectionClass)` | Generate lazy proxy decorator code |

## Property access syntax

- **Public properties**: use the property name directly: `['propertyName' => value]`
- **Private and protected**: use nested class notation: `[ClassName::class => ['propertyName' => value]]`
- **Special values**: use `"\0"` for internal collection data: `["\0" => [data]]`
- **Parent class private**: use the notation `"\0ParentClass\0propertyName"`

## Generated code

Exported code is:

- PSR-2 compliant
- OPcache-compatible
- Reference-preserving across object hierarchies
- Self-contained, with no external dependencies

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

## Error handling

- `ClassNotFoundException`: thrown when an exported class does not exist at load time
- `ExceptionInterface`: thrown for unsupported types or serialization issues
- Invalid types such as `Reflection*` always throw

## Performance

- VarExporter suits configuration and static data caches
- OPcache makes loading exported code much faster than `unserialize()`
- Lazy proxies cut initialization cost for heavy objects
- `Instantiator` skips constructor side effects, which speeds up object creation

## PHP version requirements

- The component works with PHP 7.4+
- Lazy proxy features are tuned for PHP 8.4+
- No external dependencies beyond autoloading

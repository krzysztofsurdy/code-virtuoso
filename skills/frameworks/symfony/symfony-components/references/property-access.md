# Symfony PropertyAccess Component

## Contents

- [Overview](#overview)
- [Core API](#core-api)
- [Reading values](#reading-values)
- [Writing values](#writing-values)
- [Checking property accessibility](#checking-property-accessibility)
- [Mixing objects and arrays](#mixing-objects-and-arrays)
- [Configuration options](#configuration-options)
- [Exception handling](#exception-handling)
- [Common use cases](#common-use-cases)
- [Key classes](#key-classes)
- [Related components](#related-components)

## Overview

The PropertyAccess component reads and writes values on objects and arrays using a string path. It supports several access mechanisms through reflection and method discovery.

### Installation

```bash
composer require symfony/property-access
```

## Core API

### Creating a PropertyAccessor

```php
use Symfony\Component\PropertyAccess\PropertyAccess;

// Default instance
$accessor = PropertyAccess::createPropertyAccessor();

// With configuration
$accessor = PropertyAccess::createPropertyAccessorBuilder()
    ->enableMagicCall()
    ->enableMagicGet()
    ->enableMagicSet()
    ->enableMagicMethods()  // enables all three
    ->getPropertyAccessor();

// Constructor alternative with flags
$accessor = new PropertyAccessor(
    PropertyAccessor::MAGIC_CALL | PropertyAccessor::MAGIC_SET
);
```

## Reading values

### From arrays

```php
$data = ['first_name' => 'John', 'age' => 30];

// Using bracket notation
$accessor->getValue($data, '[first_name]');  // 'John'
$accessor->getValue($data, '[age]');          // 30

// Multi-dimensional arrays
$accessor->getValue($data, '[address][city]');

// Nullsafe operator prevents null exceptions
$accessor->getValue($data, '[address?][city]');
```

### From objects

The component tries these access patterns in order:

#### 1. Public properties
```php
class Person {
    public $firstName = 'John';
}

$accessor->getValue($person, 'firstName');  // 'John'
```

#### 2. Getters
```php
class Person {
    private string $firstName = 'John';

    public function getFirstName(): string {
        return $this->firstName;
    }
}

// Converts snake_case to camelCase, prefixes with 'get'
$accessor->getValue($person, 'first_name');  // 'John'
```

#### 3. Hassers/issers
```php
class Person {
    private bool $isAuthor = true;

    public function isAuthor(): bool {
        return $this->isAuthor;
    }

    public function hasChildren(): bool {
        return count($this->children) > 0;
    }
}

$accessor->getValue($person, 'author');      // true (calls isAuthor())
$accessor->getValue($person, 'children');    // true (calls hasChildren())
```

#### 4. Magic methods
```php
class Person {
    private $data = [];

    public function __get($name) {
        return $this->data[$name] ?? null;
    }

    public function __isset($name) {
        return isset($this->data[$name]);
    }
}

$accessor->getValue($person, 'customField');  // Uses __get()
```

#### 5. Magic __call()
Enable separately via configuration:

```php
$accessor = PropertyAccess::createPropertyAccessorBuilder()
    ->enableMagicCall()
    ->getPropertyAccessor();

class Service {
    public function __call($method, $args) {
        // Handles custom getter methods
    }
}
```

### Null-safe property paths

```php
// Prevent UnexpectedTypeException when intermediate value is null
$accessor->getValue($comment, 'person?.author?.name');

// Also works with arrays
$accessor->getValue($data, '[person?][name]');
```

## Writing values

### To arrays

```php
$data = [];

$accessor->setValue($data, '[first_name]', 'John');
$accessor->setValue($data, '[address][city]', 'New York');
```

### To objects

#### 1. Setters
```php
class Person {
    private string $firstName;

    public function setFirstName(string $name): void {
        $this->firstName = $name;
    }
}

// Converts snake_case to camelCase, prefixes with 'set'
$accessor->setValue($person, 'first_name', 'John');
```

#### 2. Adders/removers (array properties)

When setting an array property, use adder/remover methods instead of direct setters:

```php
class Person {
    private array $children = [];

    public function addChild(string $name): void {
        $this->children[$name] = $name;
    }

    public function removeChild(string $name): void {
        unset($this->children[$name]);
    }
}

// Automatically uses addChild() for each element
$accessor->setValue($person, 'children', ['alice', 'bob', 'charlie']);

// Removes 'dave' via removeChild() and adds 'eve' via addChild()
$accessor->setValue($person, 'children', ['alice', 'bob', 'eve']);
```

Adder/remover methods have priority over setters.

#### 3. Custom adder/remover methods

Configure non-standard method names via ReflectionExtractor:

```php
$extractor = new ReflectionExtractor(
    null,  // default singular converter
    null,  // default cache
    ['join', 'leave']  // custom prefixes instead of 'add', 'remove'
);

$accessor = new PropertyAccessor(
    PropertyAccessor::MAGIC_CALL,
    $extractor
);

class Team {
    public function joinTeam($member): void { }
    public function leaveTeam($member): void { }
}

$accessor->setValue($team, 'members', ['alice', 'bob']);
```

#### 4. Magic methods
```php
class Person {
    public function __set($name, $value): void {
        // Called when property cannot be set directly
    }
}
```

## Checking property accessibility

### isReadable()

Verify a property can be read before accessing:

```php
if ($accessor->isReadable($person, 'firstName')) {
    $value = $accessor->getValue($person, 'firstName');
}
```

### isWritable()

Verify a property can be written before modifying:

```php
if ($accessor->isWritable($person, 'firstName')) {
    $accessor->setValue($person, 'firstName', 'John');
}
```

## Mixing objects and arrays

Combine object and array access in a single property path:

```php
class Company {
    private array $employees = [];

    public function addEmployee(Person $person): void {
        $this->employees[] = $person;
    }
}

class Person {
    private string $firstName;
    public function setFirstName(string $name): void {
        $this->firstName = $name;
    }
}

$company = new Company();
$accessor->setValue($company, 'employees[0].firstName', 'Alice');
$accessor->setValue($company, 'employees[1].firstName', 'Bob');

$name = $accessor->getValue($company, 'employees[0].firstName');  // 'Alice'
```

## Configuration options

### PropertyAccessorBuilder methods

```php
$builder = PropertyAccess::createPropertyAccessorBuilder();

$builder->enableMagicCall();      // Enable __call() magic method
$builder->enableMagicGet();       // Enable __get() magic method
$builder->enableMagicSet();       // Enable __set() magic method
$builder->enableMagicMethods();   // Enable all three magic methods

// Exception handling
$builder->enableExceptionOnInvalidIndex();      // Throw on missing array key
$builder->disableExceptionOnInvalidPropertyPath();  // Return null instead of exception

$accessor = $builder->getPropertyAccessor();
```

### Check configuration status

```php
$accessor->isMagicCallEnabled();
$accessor->isMagicGetEnabled();
$accessor->isMagicSetEnabled();
```

## Exception handling

### NoSuchIndexException
Thrown when accessing missing array index (if enabled):

```php
$accessor = PropertyAccess::createPropertyAccessorBuilder()
    ->enableExceptionOnInvalidIndex()
    ->getPropertyAccessor();

// Throws NoSuchIndexException
$accessor->getValue(['key' => 'value'], '[missing]');
```

### NoSuchPropertyException
Thrown when accessing non-existent property (default):

```php
// Throws NoSuchPropertyException by default
$accessor->getValue($person, 'nonExistent');

// Disable to return null instead
$accessor = PropertyAccess::createPropertyAccessorBuilder()
    ->disableExceptionOnInvalidPropertyPath()
    ->getPropertyAccessor();

$accessor->getValue($person, 'nonExistent');  // null
```

### UnexpectedTypeException
Thrown when null is encountered without nullsafe operator:

```php
class Comment {
    private ?Person $author = null;
}

// Throws UnexpectedTypeException if $comment->author is null
$accessor->getValue($comment, 'author.firstName');

// Use nullsafe operator to handle null safely
$accessor->getValue($comment, 'author?.firstName');  // null
```

## Common use cases

### Form data binding
Extract and set values from user input:

```php
$formData = $_POST;
$accessor->setValue($person, 'email', $formData['email']);
$accessor->setValue($person, 'profile.bio', $formData['bio']);
```

### Dynamic object hydration
Populate object from array:

```php
$data = $apiResponse;
foreach ($data as $key => $value) {
    if ($accessor->isWritable($entity, $key)) {
        $accessor->setValue($entity, $key, $value);
    }
}
```

### Nested collection handling
Work with deeply nested structures:

```php
$accessor->setValue(
    $company,
    'departments[0].teams[1].members',
    [$employee1, $employee2]
);
```

### Conditional access
Check before reading or writing:

```php
$path = 'user.profile.avatar.url';

if ($accessor->isReadable($data, $path)) {
    $url = $accessor->getValue($data, $path);
} else {
    $url = '/default-avatar.png';
}
```

## Key classes

- **PropertyAccessor**: Main class for reading/writing properties
- **PropertyAccessorBuilder**: Builder for creating configured instances
- **ReflectionExtractor**: Handles property discovery and custom method prefixes
- **PropertyAccessorInterface**: Interface for custom implementations

## Related components

- **String Component**: Used for converting property names (snake_case to camelCase)
- **Form Component**: Uses PropertyAccessor for data binding in forms
- **Validator Component**: Uses PropertyAccessor to access properties for validation

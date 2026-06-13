# Symfony ExpressionLanguage Component

## Contents

- [Installation](#installation)
- [Core concepts](#core-concepts)
- [Basic usage](#basic-usage)
- [Supported literals and data types](#supported-literals-and-data-types)
- [Operators](#operators)
- [Working with objects](#working-with-objects)
- [Working with arrays](#working-with-arrays)
- [Built-in functions](#built-in-functions)
- [Custom functions](#custom-functions)
- [Caching](#caching)
- [Common use cases](#common-use-cases)
- [Key classes and interfaces](#key-classes-and-interfaces)

## Installation

```bash
composer require symfony/expression-language
```

## Core concepts

The ExpressionLanguage component is a sandboxed engine for compiling and evaluating dynamic expressions, typically one-liners that return a value. It has two modes:

- **Evaluation**: runs the expression directly, without compilation
- **Compilation**: converts the expression to PHP code, which can be cached

## Basic usage

### Create an ExpressionLanguage instance

```php
use Symfony\Component\ExpressionLanguage\ExpressionLanguage;

$expressionLanguage = new ExpressionLanguage();
```

### Evaluate expressions

```php
// Simple arithmetic
$result = $expressionLanguage->evaluate('1 + 2'); // 3

// Pass variables
$apple = new Apple();
$apple->variety = 'Honeycrisp';
$result = $expressionLanguage->evaluate('fruit.variety', ['fruit' => $apple]); // Honeycrisp

// String concatenation
$result = $expressionLanguage->evaluate(
    'firstName ~ " " ~ lastName',
    ['firstName' => 'Arthur', 'lastName' => 'Dent']
); // Arthur Dent
```

### Compile expressions

```php
// Compile to PHP code string
$code = $expressionLanguage->compile('1 + 2'); // (1 + 2)

// Compile with variables
$code = $expressionLanguage->compile('fruit.variety', ['fruit']);
```

### Parse and lint expressions

```php
// Parse into AST for inspection
$parsed = $expressionLanguage->parse('1 + 2', []);

// Lint for validity (throws SyntaxError if invalid)
$expressionLanguage->lint('1 + 2', []);

// Lint while ignoring unknown variables/functions
use Symfony\Component\ExpressionLanguage\Parser;
$expressionLanguage->lint(
    'unknown_var + unknown_function()',
    [],
    Parser::IGNORE_UNKNOWN_VARIABLES | Parser::IGNORE_UNKNOWN_FUNCTIONS
);
```

## Supported literals and data types

- **Strings**: `'hello'`, `"world"` (single and double quotes)
- **Numbers**: `103`, `9.95`, `.99`, `1_000_000` (with optional underscores)
- **Exponential**: `1.99E+3`, `1e-2` (scientific notation)
- **Arrays**: `[1, 2, 3]` (JSON-like notation)
- **Hashes**: `{ foo: 'bar', baz: 'qux' }` (JSON-like notation)
- **Booleans**: `true`, `false`
- **Null**: `null`
- **Comments**: `/* this is a comment */`

## Operators

### Arithmetic operators
- `+` (addition), `-` (subtraction), `*` (multiplication), `/` (division), `%` (modulus), `**` (power)

### Comparison operators
- `==` (equal), `===` (identical), `!=` (not equal), `!==` (not identical)
- `<` (less than), `>` (greater than), `<=` (less than or equal), `>=` (greater than or equal)
- `matches` (regex match), `contains`, `starts with`, `ends with`

### Logical operators
- `not` or `!`, `and` or `&&`, `or` or `||`, `xor`

### String operators
- `~` (concatenation): `'Hello' ~ ' ' ~ 'World'`

### Array operators
- `in` (contains), `not in` (does not contain) - strict comparison

### Bitwise operators
- `&` (and), `|` (or), `^` (xor), `~` (not), `<<` (left shift), `>>` (right shift)

### Range operator
- `..` (range): `user.age in 18..45`

### Ternary operators
- `foo ? 'yes' : 'no'` (conditional)
- `foo ?: 'no'` (elvis operator)
- `foo ? 'yes'` (shorthand)

### Null-safe operator
- `?.` (returns null instead of throwing if object is null): `fruit?.color`, `fruit?.getStock()`

### Null-coalescing operator
- `??` (returns right-hand side if left is null): `foo ?? 'default'`

## Working with objects

### Access public properties and methods

```php
$robot = new Robot();
$robot->name = 'T-800';

// Access properties
$expressionLanguage->evaluate('robot.name', ['robot' => $robot]); // T-800

// Call methods
$expressionLanguage->evaluate('robot.sayHi(3)', ['robot' => $robot]); // Hi Hi Hi!

// Null-safe property access
$expressionLanguage->evaluate('fruit?.color', ['fruit' => null]); // null

// Null-safe method calls
$expressionLanguage->evaluate('fruit?.getStock()', ['fruit' => null]); // null
```

## Working with arrays

```php
$data = ['life' => 10, 'universe' => 10, 'everything' => 22];

// Array access
$expressionLanguage->evaluate('data["life"] + data["universe"]', ['data' => $data]); // 20

// Null-coalescing with arrays
$expressionLanguage->evaluate('data[0] ?? "default"', ['data' => $data]); // default

// In operator
$expressionLanguage->evaluate('group in ["hr", "marketing"]', ['group' => 'hr']); // true
```

## Built-in functions

### constant()
Returns PHP constants or class constants:

```php
$expressionLanguage->evaluate('constant("DB_USER")');
$expressionLanguage->evaluate('constant("App\\SomeNamespace\\Foo::API_ENDPOINT")');
```

### enum()
Returns enumeration cases:

```php
$expressionLanguage->evaluate('enum("App\\SomeNamespace\\Status::Active")');
```

### min() and max()
Return lowest or highest value of parameters:

```php
$expressionLanguage->evaluate('min(1, 2, 3)'); // 1
$expressionLanguage->evaluate('max(1, 2, 3)'); // 3
```

## Custom functions

### Register functions directly

```php
$expressionLanguage->register(
    'lowercase',
    // Compiler function (returns PHP code)
    function ($str): string {
        return sprintf('(is_string(%1$s) ? strtolower(%1$s) : %1$s)', $str);
    },
    // Evaluator function (returns actual value)
    function ($arguments, $str): string {
        if (!is_string($str)) {
            return $str;
        }
        return strtolower($str);
    }
);

$expressionLanguage->evaluate('lowercase("HELLO")'); // hello
```

### Using expression providers

Create reusable expression providers by implementing `ExpressionFunctionProviderInterface`:

```php
use Symfony\Component\ExpressionLanguage\ExpressionFunction;
use Symfony\Component\ExpressionLanguage\ExpressionFunctionProviderInterface;

class StringExpressionLanguageProvider implements ExpressionFunctionProviderInterface
{
    public function getFunctions(): array
    {
        return [
            new ExpressionFunction('lowercase', function ($str): string {
                return sprintf('(is_string(%1$s) ? strtolower(%1$s) : %1$s)', $str);
            }, function ($arguments, $str): string {
                return is_string($str) ? strtolower($str) : $str;
            }),
            new ExpressionFunction('uppercase', function ($str): string {
                return sprintf('(is_string(%1$s) ? strtoupper(%1$s) : %1$s)', $str);
            }, function ($arguments, $str): string {
                return is_string($str) ? strtoupper($str) : $str;
            }),
        ];
    }
}
```

### Register providers

```php
// Via constructor
$expressionLanguage = new ExpressionLanguage(null, [
    new StringExpressionLanguageProvider(),
]);

// Or dynamically
$expressionLanguage->registerProvider(new StringExpressionLanguageProvider());
```

### Create functions from existing PHP functions

```php
use Symfony\Component\ExpressionLanguage\ExpressionFunction;

// Simple wrapping
ExpressionFunction::fromPhp('strtoupper');

// With custom expression name
ExpressionFunction::fromPhp('MyNamespace\\customFunction', 'my_function');
```

### Custom ExpressionLanguage class

In libraries, extend `ExpressionLanguage` with default providers:

```php
use Psr\Cache\CacheItemPoolInterface;
use Symfony\Component\ExpressionLanguage\ExpressionLanguage as BaseExpressionLanguage;

class ExpressionLanguage extends BaseExpressionLanguage
{
    public function __construct(?CacheItemPoolInterface $cache = null, array $providers = [])
    {
        // Prepend default provider to allow user overrides
        array_unshift($providers, new StringExpressionLanguageProvider());
        parent::__construct($cache, $providers);
    }
}
```

## Caching

ExpressionLanguage caches parsed expressions, so repeated expressions are not tokenized and parsed again.

### Default caching

```php
// Uses ArrayAdapter for in-memory caching by default
$expressionLanguage = new ExpressionLanguage();
```

### Custom cache configuration

Inject a PSR-6 cache implementation:

```php
use Symfony\Component\Cache\Adapter\RedisAdapter;
use Symfony\Component\Cache\Adapter\FilesystemAdapter;

// Redis cache
$cache = new RedisAdapter(...);
$expressionLanguage = new ExpressionLanguage($cache);

// Filesystem cache
$cache = new FilesystemAdapter();
$expressionLanguage = new ExpressionLanguage($cache);
```

### Manual parsed expression caching

```php
// Cache and reuse ParsedExpression
$expression = $expressionLanguage->parse('1 + 4', []);
$expressionLanguage->evaluate($expression); // 5

// Serialize for persistent caching
use Symfony\Component\ExpressionLanguage\SerializedParsedExpression;

$expression = new SerializedParsedExpression(
    '1 + 4',
    serialize($expressionLanguage->parse('1 + 4', [])->getNodes())
);
$expressionLanguage->evaluate($expression); // 5
```

## Common use cases

### Business rules

```php
// Determine special pricing based on user group
$expression = 'user.getGroup() in ["good_customers", "collaborator"]';
if ($expressionLanguage->evaluate($expression, ['user' => $user])) {
    // Apply special pricing
}
```

### Validation rules

```php
// Validation logic
$expression = 'product.stock < 15 and product.category not in ["discontinued"]';
if ($expressionLanguage->evaluate($expression, ['product' => $product])) {
    // Show warning
}
```

### Content filtering

```php
// Show article if it meets engagement threshold
$expression = 'article.commentCount > 100 and article.rating >= 4.0';
if ($expressionLanguage->evaluate($expression, ['article' => $article])) {
    // Display article
}
```

### Security and access control

```php
// Check user permissions
$expression = 'user.hasRole("ADMIN") or (user.hasRole("EDITOR") and resource.owner == user.id)';
if ($expressionLanguage->evaluate($expression, ['user' => $user, 'resource' => $resource])) {
    // Grant access
}
```

## Key classes and interfaces

- **ExpressionLanguage**: Main class for evaluating and compiling expressions
- **ExpressionFunction**: Represents a custom function with compiler and evaluator callbacks
- **ExpressionFunctionProviderInterface**: Interface for creating reusable function providers
- **ParsedExpression**: Represents a parsed expression for reuse
- **SerializedParsedExpression**: Serializable parsed expression for persistent caching
- **Parser**: Expression parser with constants for lint behavior (IGNORE_UNKNOWN_VARIABLES, IGNORE_UNKNOWN_FUNCTIONS)

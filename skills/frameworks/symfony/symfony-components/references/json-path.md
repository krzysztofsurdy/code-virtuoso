# Symfony JsonPath Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Basic usage](#basic-usage)
- [Query syntax](#query-syntax)
- [Building queries with JsonPath](#building-queries-with-jsonpath)
- [Testing with JsonPathAssertionsTrait](#testing-with-jsonpathassertionstrait)
- [Error handling](#error-handling)
- [Full example](#full-example)
- [When to use JsonPath](#when-to-use-jsonpath)

## Overview

The JsonPath component queries and extracts data from JSON using the RFC 9535 JSONPath standard. `JsonCrawler` runs queries, and the `JsonPath` fluent API builds them programmatically. It is similar to the DomCrawler component, but for JSON documents.

## Installation

```bash
composer require symfony/json-path
```

## Basic usage

### Create a crawler and query JSON

```php
use Symfony\Component\JsonPath\JsonCrawler;

$json = '{"store": {"book": [{"title": "PHP Basics", "price": 15.99}]}}';
$crawler = new JsonCrawler($json);
$results = $crawler->find('$.store.book[0].title');
```

## Query syntax

### Accessing properties

Use dot, bracket, or mixed notation:

```php
// Dot notation
$crawler->find('$.store.book[0].title');

// Bracket notation
$crawler->find('$["store"]["book"][0]["title"]');

// Mixed notation
$crawler->find('$["store"].book[0].title');
```

### Root and recursive selection

```php
// Root element
$data = $crawler->find('$');

// Recursive search for all author values at any depth
$authors = $crawler->find('$..author');
```

### Array access

```php
// First element
$first = $crawler->find('$.books[0]');

// Last element
$last = $crawler->find('$.books[-1]');

// All elements (wildcard)
$all = $crawler->find('$.books[*]');

// Slice from index 1 to 3
$slice = $crawler->find('$.books[1:3]');

// Slice with step (every 2nd element)
$stepped = $crawler->find('$.books[0:4:2]');
```

### Filtering

Filter expressions select the matching elements:

```php
// Books with price less than 20
$cheapBooks = $crawler->find('$.store.book[?(@.price < 20)]');

// Books by specific author
$authorsBooks = $crawler->find('$.books[?(@.author == "John")]');

// Books with price and in stock
$available = $crawler->find('$.books[?(@.price > 10 && @.inStock)]');
```

## Building queries with JsonPath

The `JsonPath` fluent API builds queries dynamically:

```php
use Symfony\Component\JsonPath\JsonPath;

$path = (new JsonPath())
    ->key('store')
    ->key('book')
    ->index(0)
    ->key('title');

$title = $crawler->find($path);
```

### JsonPath methods

| Method | Description | Example |
|--------|-------------|---------|
| `key($name)` | Select a property by name | `->key('store')` |
| `deepScan()` | Add descendant operator (`..`) | `->deepScan()->key('price')` |
| `all()` | Select all elements with wildcard (`[*]`) | `->all()` |
| `index($i)` | Select array element by index | `->index(0)`, `->index(-1)` |
| `first()` | Shortcut for `->index(0)` | `->first()` |
| `last()` | Shortcut for `->index(-1)` | `->last()` |
| `slice($start, $end)` | Array slice `[start:end]` | `->slice(1, 3)` |
| `slice($start, $end, $step)` | Array slice with step `[start:end:step]` | `->slice(0, 4, 2)` |
| `filter($expression)` | Apply filter expression | `->filter('@.price > 20')` |
| `__toString()` | Get JSONPath string representation | `(string)$path` |

### Practical example

```php
$json = '{"users": [{"name": "Alice", "role": "admin"}, {"name": "Bob", "role": "user"}]}';
$crawler = new JsonCrawler($json);

// Build the query with JsonPath
$adminPath = (new JsonPath())
    ->key('users')
    ->all()
    ->filter('@.role == "admin"')
    ->key('name');

$adminNames = $crawler->find($adminPath);
```

## Testing with JsonPathAssertionsTrait

Add `JsonPathAssertionsTrait` to a PHPUnit test class to assert against JSON data:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Component\JsonPath\Test\JsonPathAssertionsTrait;

class ApiResponseTest extends TestCase
{
    use JsonPathAssertionsTrait;

    public function testJsonResponse(): void
    {
        $json = '{"status": "ok", "books": [{"id": 1, "title": "A"}, {"id": 2, "title": "B"}]}';

        // Assert count of matched elements
        self::assertJsonPathCount(2, '$.books[*]', $json);

        // Assert specific value equals
        self::assertJsonPathEquals('ok', '$.status', $json);

        // Assert value found in results
        self::assertJsonPathContains('B', '$.books[*].title', $json);
    }
}
```

### Assertion methods

- `assertJsonPathCount($count, $path, $json)` - Assert exact count of matched elements
- `assertJsonPathEquals($expected, $path, $json)` - Assert result equals expected (type coercion with `==`)
- `assertJsonPathNotEquals($expected, $path, $json)` - Assert result not equals expected (`!=`)
- `assertJsonPathSame($expected, $path, $json)` - Strict equality assertion (`===`)
- `assertJsonPathNotSame($expected, $path, $json)` - Strict inequality assertion (`!==`)
- `assertJsonPathContains($value, $path, $json)` - Assert value found in matched results
- `assertJsonPathNotContains($value, $path, $json)` - Assert value not found in results

## Error handling

The component throws specific exceptions:

```php
use Symfony\Component\JsonPath\JsonCrawler;
use Symfony\Component\JsonPath\Exception\InvalidJsonStringInputException;
use Symfony\Component\JsonPath\Exception\JsonCrawlerException;

try {
    $crawler = new JsonCrawler('{"invalid": }'); // Malformed JSON
} catch (InvalidJsonStringInputException $e) {
    echo "Invalid JSON: " . $e->getMessage();
}

try {
    $crawler = new JsonCrawler('{"data": [1,2,3]}');
    $crawler->find('$.data[?(@.unknownFunc() > 0)]'); // Unknown function
} catch (JsonCrawlerException $e) {
    echo "Invalid JSONPath: " . $e->getMessage();
}
```

### Exception types

- `InvalidArgumentException` - Invalid argument passed to method
- `InvalidJsonStringInputException` - Malformed JSON string provided to JsonCrawler
- `JsonCrawlerException` - Invalid JSONPath expression (unknown functions, syntax errors, etc.)

## Full example

```php
use Symfony\Component\JsonPath\JsonCrawler;
use Symfony\Component\JsonPath\JsonPath;

$json = <<<JSON
{
    "store": {
        "name": "My Store",
        "books": [
            {
                "id": 1,
                "title": "PHP Guide",
                "author": "Jane Doe",
                "price": 29.99,
                "inStock": true
            },
            {
                "id": 2,
                "title": "Symfony Mastery",
                "author": "John Smith",
                "price": 39.99,
                "inStock": false
            }
        ]
    }
}
JSON;

$crawler = new JsonCrawler($json);

// Get all book titles
$titles = $crawler->find('$.store.books[*].title');

// Get books in stock under $35
$available = $crawler->find('$.store.books[?(@.inStock && @.price < 35)]');

// Using JsonPath for dynamic queries
$secondBook = (new JsonPath())
    ->key('store')
    ->key('books')
    ->index(1)
    ->key('title');

$title = $crawler->find($secondBook); // "Symfony Mastery"

// Recursively find all authors
$allAuthors = $crawler->find('$..author');
```

## When to use JsonPath

Use the JsonPath component to:
- Extract data from JSON API responses
- Query nested JSON structures
- Read JSON configuration files
- Test JSON responses in PHPUnit tests
- Validate data in JSON documents dynamically

Alternatives:
- **json_decode()** for simple, flat structures
- **jq** for command-line JSON processing
- **API Platform** for building REST APIs with JSON handling

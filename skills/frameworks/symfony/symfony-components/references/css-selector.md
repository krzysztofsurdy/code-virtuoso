# Symfony CssSelector Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core classes and methods](#core-classes-and-methods)
- [Usage patterns](#usage-patterns)
- [Supported CSS selectors](#supported-css-selectors)
- [Common use cases](#common-use-cases)
- [Error handling](#error-handling)
- [Performance considerations](#performance-considerations)
- [Related components](#related-components)
- [Best practices](#best-practices)

## Overview

The CssSelector component converts CSS selectors to XPath expressions. XPath is the more expressive way to query HTML and XML documents, but it has a steep learning curve, while CSS selectors are familiar to web developers. With this component you write CSS selectors and use them with tools that require XPath.

## Installation

Install the component with Composer:

```bash
composer require symfony/css-selector
```

## Core classes and methods

### CssSelectorConverter

The main class for converting CSS selectors to XPath expressions.

```php
use Symfony\Component\CssSelector\CssSelectorConverter;

$converter = new CssSelectorConverter();

// Convert CSS selector to XPath expression
$xpath = $converter->toXPath('div.item > h4 > a');
// Returns: descendant-or-self::div[@class and contains(concat(' ',normalize-space(@class), ' '), ' item ')]/h4/a
```

#### Key method

- **`toXPath(string $selector): string`** - Convert a CSS selector string to an XPath expression

## Usage patterns

### Basic XPath conversion

Convert a CSS selector to XPath for use with DOM tools:

```php
use Symfony\Component\CssSelector\CssSelectorConverter;
use DOMDocument;
use DOMXPath;

$converter = new CssSelectorConverter();

$doc = new DOMDocument();
$doc->load('page.html');
$xpath = new DOMXPath($doc);

// Convert CSS selector to XPath
$xpathExpr = $converter->toXPath('div.container > p');

// Query using the converted XPath
$results = $xpath->query($xpathExpr);
foreach ($results as $node) {
    echo $node->textContent;
}
```

### Integration with DomCrawler

DomCrawler uses CssSelector under the hood, so you can pass CSS selectors straight to `filter()`:

```php
use Symfony\Component\DomCrawler\Crawler;

// Create crawler from HTML content
$crawler = new Crawler('<html><body><div class="item"><h4><a href="/">Link</a></h4></div></body></html>');

// Use CSS selectors directly with filter() method
$links = $crawler->filter('div.item > h4 > a');
$href = $links->attr('href');
$text = $links->text();
```

### SimpleXML integration

Convert a CSS selector for use with `SimpleXMLElement`:

```php
use Symfony\Component\CssSelector\CssSelectorConverter;

$converter = new CssSelectorConverter();
$xpath = $converter->toXPath('article.featured');

$xml = new SimpleXMLElement(file_get_contents('content.xml'));
$results = $xml->xpath($xpath);

foreach ($results as $article) {
    echo (string) $article;
}
```

## Supported CSS selectors

### Element and class selectors

```php
$converter->toXPath('div');                 // Element selector
$converter->toXPath('div.classname');       // Element with class
$converter->toXPath('.classname');          // Class selector
$converter->toXPath('#id');                 // ID selector
$converter->toXPath('[data-value]');        // Attribute selector
$converter->toXPath('[data-value="test"]'); // Attribute with value
```

### Combinators

```php
$converter->toXPath('div > p');      // Child combinator
$converter->toXPath('div p');        // Descendant combinator
$converter->toXPath('div + p');      // Adjacent sibling combinator
$converter->toXPath('div ~ p');      // General sibling combinator
```

### Pseudo-classes (supported)

```php
$converter->toXPath('input:enabled');       // Enabled form elements
$converter->toXPath('input:disabled');      // Disabled form elements
$converter->toXPath('input:checked');       // Checked checkboxes/radios
$converter->toXPath('input:unchecked');     // Unchecked form elements
$converter->toXPath('li:only-of-type');     // Only element of its type
$converter->toXPath('*:scope');             // Root element
$converter->toXPath(':is(div, p)');         // Matches any selector in list
$converter->toXPath(':where(div, p)');      // Matches any selector (no specificity)
```

### Pseudo-classes (not supported)

- `:link`, `:visited`, `:target` - Link state selectors
- `:hover`, `:focus`, `:active` - User action selectors
- `:invalid`, `:indeterminate` - UI state selectors
- `:before`, `:after`, `:first-line`, `:first-letter` - Pseudo-elements

### Partial support

The following pseudo-classes work with specific element names but not with the universal selector `*`:

- `:first-of-type`, `:last-of-type`, `:nth-of-type()`, `:nth-last-of-type()`

```php
// Supported
$converter->toXPath('p:first-of-type');
$converter->toXPath('li:nth-of-type(2)');

// Not supported
$converter->toXPath('*:first-of-type');  // Will throw exception
```

## Common use cases

### Web scraping

```php
use Symfony\Component\DomCrawler\Crawler;

$html = file_get_contents('https://example.com');
$crawler = new Crawler($html);

// Extract all articles
$articles = $crawler->filter('article.post');
foreach ($articles as $article) {
    $title = $article->querySelector('h2')->textContent;
    $excerpt = $article->querySelector('.excerpt')->textContent;
    echo "$title: $excerpt\n";
}
```

### Form testing

```php
use Symfony\Component\DomCrawler\Crawler;

$crawler = new Crawler($html);

// Find form fields by CSS selector
$emailField = $crawler->filter('input[type="email"]');
$submitButton = $crawler->filter('button[type="submit"]');

// Extract form attributes
$formAction = $crawler->filter('form#login')->attr('action');
```

### DOM navigation and traversal

```php
use Symfony\Component\DomCrawler\Crawler;

$crawler = new Crawler($html);

// Filter to specific elements
$container = $crawler->filter('div.container');

// Navigate within filtered results
$headers = $container->filter('h1, h2, h3');
$links = $container->filter('a');

// Extract data
foreach ($links as $link) {
    echo $link->getAttribute('href');
}
```

### API response parsing

```php
use Symfony\Component\DomCrawler\Crawler;

// Parse HTML response from API
$response = $httpClient->request('GET', '/api/endpoint');
$crawler = new Crawler($response->getContent());

// Extract specific data using CSS selectors
$results = $crawler->filter('.result-item');
$data = [];
foreach ($results as $item) {
    $data[] = [
        'title' => $item->querySelector('.title')->textContent,
        'price' => $item->querySelector('.price')->textContent,
    ];
}
```

## Error handling

`CssSelectorConverter` throws an exception for unsupported selectors:

```php
use Symfony\Component\CssSelector\CssSelectorConverter;
use Symfony\Component\CssSelector\Exception\ParseException;

$converter = new CssSelectorConverter();

try {
    // This will throw an exception - unsupported pseudo-element
    $xpath = $converter->toXPath('p:before');
} catch (ParseException $e) {
    echo "Invalid selector: " . $e->getMessage();
}
```

## Performance considerations

- Reuse a single converter instance instead of creating a new one per call
- Simpler selectors generally perform better than deeply nested ones
- The generated XPath expressions are optimized for common patterns

```php
// Good: Reuse converter instance
$converter = new CssSelectorConverter();
for ($i = 0; $i < 1000; $i++) {
    $xpath = $converter->toXPath('div.item');
}

// Less efficient: Creating new instances
for ($i = 0; $i < 1000; $i++) {
    $xpath = (new CssSelectorConverter())->toXPath('div.item');
}
```

## Related components

- **DomCrawler**: Uses CssSelector internally via the `filter()` method for CSS selector queries
- **HttpClient**: Commonly used to fetch HTML documents for parsing with CssSelector
- **Symfony Functional Tests**: Integrates CssSelector for assertions on response content

## Best practices

1. **Validate selectors**: Check that selectors are valid before using them in production code
2. **Use specific selectors**: They are faster and easier to maintain than broad queries
3. **Combine with DomCrawler**: For HTML parsing, use `filter()` instead of converting to XPath by hand
4. **Document complex selectors**: Add a comment explaining any selector that is not obvious
5. **Catch exceptions**: Wrap selector conversion in try-catch when the input comes from untrusted sources

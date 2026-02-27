# Symfony DomCrawler Component

## Overview

The DomCrawler component provides a powerful API for navigating and querying DOM elements in HTML and XML documents. It's designed for **reading and traversing** DOM content, not for manipulation or re-dumping HTML/XML.

## Installation

```bash
composer require symfony/dom-crawler
```

Optionally install CssSelector component for CSS selector support:

```bash
composer require symfony/css-selector
```

## Core Concepts

### Creating Crawler Instances

Initialize a Crawler with HTML, XML, or DOM content:

```php
use Symfony\Component\DomCrawler\Crawler;

// From HTML string
$crawler = new Crawler('<html><body><p>Hello</p></body></html>');

// From XML string
$crawler = new Crawler('<root><entry>Data</entry></root>', 'http://example.com');

// Add content to existing crawler
$crawler->addHtmlContent($html);
$crawler->addXmlContent($xml);
$crawler->addContent($content, 'text/xml');
$crawler->addDocument($domDocument);
$crawler->addNodeList($nodeList);
```

## Filtering & Selecting

### CSS Selectors

Use CSS selectors for intuitive DOM querying (requires CssSelector component):

```php
$crawler->filter('body > p');
$crawler->filter('div.item > h4 > a');
$crawler->filter('input[type="text"]');
$crawler->filter('p:nth-child(2)');
$crawler->filter('button:enabled');
```

Supported pseudo-classes: `:enabled`, `:disabled`, `:checked`, `:unchecked`, `:only-of-type`, `:scope`, `:is()`, `:where()`

### XPath Expressions

Use XPath for advanced queries:

```php
$crawler->filterXPath('descendant-or-self::body/p');
$crawler->filterXPath('//div[@class="item"]//span[@id]');
$crawler->filterXPath('//a[contains(@href, "/login")]');
```

### Custom Filtering

Reduce results using callback functions:

```php
$crawler->filter('p')->reduce(function (Crawler $node, $i): bool {
    return ($i % 2) === 0; // Keep every other element
});

// Check if node matches selector
$crawler->filter('p')->matches('p.lorem');
```

## DOM Traversal

### Navigation Methods

Move through the DOM tree:

```php
// By position
$crawler->filter('p')->eq(0);      // First matching element
$crawler->filter('p')->first();    // Same as eq(0)
$crawler->filter('p')->last();     // Last matching element

// Horizontal movement
$crawler->filter('p')->siblings();    // All siblings
$crawler->filter('p')->nextAll();     // Following siblings
$crawler->filter('p')->previousAll(); // Preceding siblings

// Vertical movement
$crawler->filter('body')->children();     // Direct children
$crawler->filter('p')->ancestors();       // All ancestors
$crawler->closest('div');                 // Nearest matching parent
```

## Accessing Content

### Text Content

```php
// Get text with optional default value
$text = $crawler->filter('p')->text();
$text = $crawler->filter('p')->text('Default text');

// Get inner text only (no child node text)
$innerText = $crawler->filter('p')->innerText();

// Iterate over multiple nodes
$texts = $crawler->filter('p')->each(function (Crawler $node, $i): string {
    return trim($node->text());
});
```

### Attributes

```php
// Get single attribute
$class = $crawler->filter('p')->attr('class');
$class = $crawler->filter('p')->attr('class', 'default-class');

// Get all attributes
$id = $crawler->filter('p')->id();

// Get node name (HTML tag)
$tag = $crawler->filter('body/*')->nodeName();
```

### HTML Content

```php
// Get inner HTML
$inner = $crawler->filter('div')->html();

// Get complete element including tag
$outer = $crawler->filter('div')->outerHtml();
```

### Batch Extraction

Extract multiple values at once:

```php
$data = $crawler->filterXPath('//p')->extract(['_name', '_text', 'class', 'id']);
// Returns: [['p', 'Content', 'class-name', 'id-value'], ...]

// Custom field mapping
$data = $crawler->filter('article')->extract(['_text' => 'content', 'class' => 'className']);
```

## Working with Links

### Link Selection & Retrieval

```php
use Symfony\Component\DomCrawler\Link;

// Select link by text
$link = $crawler->selectLink('Log in')->link();

// Access link properties
$uri = $link->getUri();        // Absolute URI
$method = $link->getMethod();  // GET, POST, etc.
```

## Working with Images

### Image Selection & Retrieval

```php
use Symfony\Component\DomCrawler\Image;

// Select image by alt text
$image = $crawler->selectImage('Kitten')->image();

// Access image properties
$uri = $image->getUri();
```

## Working with Forms

### Form Selection

```php
// Select form by button text
$form = $crawler->selectButton('Sign in')->form();

// Select by button name
$form = $crawler->selectButton('btnSubmit')->form();
```

### Form Data Manipulation

```php
// Set single value
$form['username']->setValue('symfonyfan');
$form['password']->setValue('anypass');

// Set multiple values
$form->setValues([
    'registration[username]' => 'symfonyfan',
    'registration[email]'    => 'user@example.com',
    'registration[terms]'    => 1,
]);

// Checkbox operations
$form['agree']->tick();    // Check
$form['agree']->untick();  // Uncheck

// Select dropdown options
$form['birthday_year']->select(1984);
$form['category']->select('premium');

// File upload
$form['photo']->upload('/path/to/file.jpg');

// Disable validation for invalid values
$form['field']->disableValidation()->select('Invalid value');
```

### Retrieving Form Data

```php
// Get form submission URI
$uri = $form->getUri();

// Get form method
$method = $form->getMethod();

// Get PHP-formatted values
$values = $form->getPhpValues();

// Get uploaded files
$files = $form->getPhpFiles();
```

## XML & Namespaces

### Automatic Namespace Handling

The component automatically registers common namespace prefixes:

```php
// Using default namespace prefix
$crawler->filterXPath('//default:entry/media:group//yt:aspectRatio');

// Using pipe syntax in CSS
$crawler->filter('default|entry media|group yt|aspectRatio');
```

### Explicit Namespace Registration

```php
$crawler->registerNamespace('m', 'http://search.yahoo.com/mrss/');
$crawler->registerNamespace('yt', 'http://gdata.youtube.com/schemas/2007');

$crawler = $crawler->filterXPath('//m:group//yt:aspectRatio');
```

## URI Resolution

### Resolving Relative URLs

```php
use Symfony\Component\DomCrawler\UriResolver;

// Resolve relative paths to absolute URIs
UriResolver::resolve('/foo', 'http://localhost/bar/foo/');
// Result: 'http://localhost/foo'

UriResolver::resolve('?a=b', 'http://localhost/bar#foo');
// Result: 'http://localhost/bar?a=b'
```

## Expression Evaluation

### XPath Functions

Execute XPath expressions that return non-node results:

```php
// Extract substring
$result = $crawler->evaluate('substring-after(@id, "-")');
// Result: "123" from id="prefix-123"

// Count elements
$count = $crawler->evaluate('count(//span[@class="article"])');
// Result: 5

// Get text content
$text = $crawler->evaluate('string(//h1)');
```

## Integration with BrowserKit

### Making Requests & Parsing Responses

```php
use Symfony\Component\BrowserKit\HttpBrowser;
use Symfony\Component\HttpClient\HttpClient;

$browser = new HttpBrowser(HttpClient::create());

// Make request - returns Crawler instance
$crawler = $browser->request('GET', 'https://github.com/login');

// Parse and interact with response
$form = $crawler->selectButton('Sign in')->form();
$form['login'] = 'symfonyfan';
$form['password'] = 'password123';

// Submit form - returns new Crawler
$crawler = $browser->submit($form);

// Follow links
$link = $crawler->selectLink('Go elsewhere...')->link();
$crawler = $browser->click($link);

// Extract data
$pullRequests = $crawler->filter('.table-list-header-toggle a:nth-child(1)')->text();
```

## Common Use Cases

### Web Scraping

```php
$crawler = new Crawler(file_get_contents('https://example.com'));

$articles = $crawler->filter('article')->each(function (Crawler $article) {
    return [
        'title'   => $article->filter('h2')->text(),
        'content' => $article->filter('.content')->text(),
        'author'  => $article->filter('.author')->attr('data-author'),
    ];
});
```

### Testing HTML Responses

```php
$form = $crawler->selectButton('Submit')->form();
$form['email']->setValue('test@example.com');
$crawler = $client->submit($form);

// Assert response
$this->assertStringContainsString('Success', $crawler->text());
$this->assertEquals(1, $crawler->filter('.success-message')->count());
```

### Parsing XML APIs

```php
$crawler = new Crawler(file_get_contents('https://api.example.com/feed.xml'));
$crawler->registerNamespace('atom', 'http://www.w3.org/2005/Atom');

$entries = $crawler->filterXPath('//atom:entry')->each(function (Crawler $entry) {
    return [
        'id'    => $entry->filterXPath('atom:id')->text(),
        'title' => $entry->filterXPath('atom:title')->text(),
        'link'  => $entry->filterXPath('atom:link')->attr('href'),
    ];
});
```

## Important Behaviors

- **HTML Auto-correction**: Malformed HTML is automatically fixed according to HTML5 specifications
- **Filter Return Type**: All filter methods return new Crawler instances, enabling method chaining
- **Empty Results**: Use `$crawler->count() > 0` to verify if filters returned results
- **Not for Manipulation**: Use `DOMDocument` or `DOMXPath` directly if you need DOM modification
- **Whitespace Handling**: Use `trim()` on text content when extracting

## Performance Tips

- Cache compiled CSS selectors for repeated queries
- Use more specific selectors to reduce DOM traversal
- Combine filters into single expressions when possible
- Use `eq()` instead of `first()` when targeting specific indices for clarity

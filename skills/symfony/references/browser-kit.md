# Symfony BrowserKit Component

The BrowserKit component simulates web browser behavior, enabling programmatic HTTP requests, link clicks, form submissions, cookie management, and browsing history navigation. Use it for functional testing, web scraping, and automated interactions.

## Installation

```bash
composer require symfony/browser-kit
```

## Creating a Client

Extend `AbstractBrowser` and implement `doRequest()`:

```php
use Symfony\Component\BrowserKit\AbstractBrowser;
use Symfony\Component\BrowserKit\Response;

class Client extends AbstractBrowser
{
    protected function doRequest($request): Response
    {
        // Convert request into response
        return new Response($content, $status, $headers);
    }
}
```

Pre-built implementations:
- `HttpBrowser` - HTTP layer requests via HttpClient
- Custom clients extending `AbstractBrowser`

## Making Requests

All request methods return a `Crawler` instance for HTML traversal:

```php
$client = new Client();

// Standard HTTP request
$crawler = $client->request('GET', '/');

// JSON request with auto Content-Type header
$crawler = $client->jsonRequest('GET', '/', ['param' => 'value']);

// AJAX request (sets X-Requested-With header)
$crawler = $client->xmlHttpRequest('GET', '/');
```

### Wrapping Content

For HTML fragments lacking proper context:

```php
$client->wrapContent('<table>%s</table>');
$crawler = $client->xmlHttpRequest('GET', '/fragment');
```

The wrapper MUST contain `%s` placeholder for original content.

## Clicking Links

```php
// Simple click by text
$crawler = $client->clickLink('Go elsewhere...');

// Access link object first
$link = $crawler->selectLink('Go elsewhere...')->link();
$client->click($link);

// With custom headers
$client->clickLink('Go elsewhere...', ['X-Custom-Header' => 'data']);
```

## Submitting Forms

```php
// Simple form submission
$crawler = $client->submitForm('Log in');

// With field overrides
$client->submitForm('Log in', [
    'login' => 'my_user',
    'password' => 'my_pass',
    'file' => '/path/to/file', // file uploads
]);

// With HTTP method and server parameters
$client->submitForm('Submit', $values, 'PUT', ['HTTP_ACCEPT' => 'application/json']);

// Using Form object for control
$form = $crawler->selectButton('Log in')->form();
$form['login'] = 'symfonyfan';
$form['password'] = 'anypass';
$crawler = $client->submit($form);
```

## Cookie Management

### Retrieving Cookies

```php
$cookieJar = $client->getCookieJar();

// Get specific cookie
$cookie = $cookieJar->get('cookie_name');
$name = $cookie->getName();
$value = $cookie->getValue();
$rawValue = $cookie->getRawValue();
$isSecure = $cookie->isSecure();
$isHttpOnly = $cookie->isHttpOnly();
$isExpired = $cookie->isExpired();
$expires = $cookie->getExpiresTime();
$path = $cookie->getPath();
$domain = $cookie->getDomain();
$sameSite = $cookie->getSameSite();

// Get all cookies
foreach ($cookieJar->all() as $cookie) { }

// Get all values for domain
foreach ($cookieJar->allValues('http://example.com') as $value) { }

// Get all raw values for domain
foreach ($cookieJar->allRawValues('http://example.com') as $rawValue) { }
```

### Setting Cookies

```php
use Symfony\Component\BrowserKit\Cookie;
use Symfony\Component\BrowserKit\CookieJar;

$cookie = new Cookie('flavor', 'chocolate', strtotime('+1 day'));
$cookieJar = new CookieJar();
$cookieJar->set($cookie);

// Pass to client constructor
$client = new Client([], null, $cookieJar);

// Or send in request
$client->request('GET', '/', [], [], [
    'HTTP_COOKIE' => $cookie,
    // OR as string
    // 'HTTP_COOKIE' => 'flavor=chocolate; path=/'
]);
```

## History Navigation

```php
$client->request('GET', '/');
$client->clickLink('Next');

// Navigate history
$crawler = $client->back();
$crawler = $client->forward();

// Check position
if (!$client->getHistory()->isFirstPage()) {
    $crawler = $client->back();
}

if (!$client->getHistory()->isLastPage()) {
    $crawler = $client->forward();
}

// Clear history and cookies
$client->restart();
```

## External HTTP Requests

Make requests to external websites:

```php
use Symfony\Component\BrowserKit\HttpBrowser;
use Symfony\Component\HttpClient\HttpClient;

$browser = new HttpBrowser(HttpClient::create());

// Make request
$browser->request('GET', 'https://github.com');
$browser->clickLink('Sign in');
$browser->submitForm('Sign in', ['login' => 'user', 'password' => 'pass']);

// Navigate and extract
$pullRequests = $browser->clickLink('Pull requests')->filter('.link-text')->text();
```

### Handling Responses

```php
$browser->request('GET', 'https://github.com');
$response = $browser->getResponse();

// JSON responses
$data = $browser->getResponse()->toArray(); // Returns decoded array
```

## Custom Headers

Override `getHeaders()` for special requirements:

```php
protected function getHeaders(Request $request): array
{
    $headers = parent::getHeaders($request);
    if (isset($request->getServer()['api_key'])) {
        $headers['X-API-Key'] = $request->getServer()['api_key'];
    }
    return $headers;
}
```

## Key Classes & Methods

**AbstractBrowser**
- `request(method, uri, parameters, files, server)` - Make HTTP request
- `jsonRequest(method, uri, data)` - JSON request
- `xmlHttpRequest(method, uri, data)` - AJAX request
- `clickLink(text, serverParameters)` - Click link by text
- `click(link)` - Click Link object
- `submitForm(button, values, method, serverParameters)` - Submit form
- `submit(form)` - Submit Form object
- `back()` - Go to previous page
- `forward()` - Go to next page
- `restart()` - Clear history/cookies
- `getCookieJar()` - Access cookie storage
- `getHistory()` - Access browsing history
- `getResponse()` - Get current response
- `getCrawler()` - Get current Crawler
- `wrapContent(wrapper)` - Wrap HTML fragments

**Cookie**
- `__construct(name, value, expires, path, domain, secure, httpOnly, raw, sameSite)`
- `getName()`, `getValue()`, `getRawValue()`
- `getExpiresTime()`, `getPath()`, `getDomain()`, `getSameSite()`
- `isSecure()`, `isHttpOnly()`, `isExpired()`

**CookieJar**
- `set(cookie)` - Add/update cookie
- `get(name)` - Retrieve cookie
- `all()` - Get all cookies
- `allValues(uri)` - Get all values for URI
- `allRawValues(uri)` - Get raw cookie strings

**HttpBrowser** - Implementation for HTTP requests via HttpClient

## Best Practices

- Use `HttpBrowser` for external HTTP requests, custom client for internal testing
- Always check response status before proceeding with assertions
- Use Crawler methods for robust element selection (selectLink, selectButton, filter)
- Pass absolute file paths for file uploads
- Leverage History API to validate navigation flows
- Use xmlHttpRequest() for AJAX endpoints with proper server parameters
- Extract cookies before restart() if you need to preserve authentication state
- Consider using the DomCrawler component in tandem for complex HTML parsing

## Related Components

- [DomCrawler](dom_crawler.html) - HTML traversal and element manipulation
- [HttpClient](../http_client.html) - HTTP client for external requests
- [CssSelector](css_selector.html) - CSS selector support in Crawler

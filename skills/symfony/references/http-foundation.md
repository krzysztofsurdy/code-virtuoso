# Symfony HttpFoundation Component

Provides an object-oriented interface for HTTP requests and responses, replacing PHP procedural approaches (`$_GET`, `echo`, `header()`, `setcookie()`) with clean, manageable classes.

## Installation

```bash
composer require symfony/http-foundation
```

## Request Class - Handle HTTP Requests

Create request instances and access incoming data safely.

### Creating Requests

```php
use Symfony\Component\HttpFoundation\Request;

// Create from PHP globals
$request = Request::createFromGlobals();

// Simulate a request (for testing)
$request = Request::create(
    '/hello-world',
    'GET',
    ['name' => 'Fabien'],
    ['session_id' => 'abc123']
);
```

### Accessing Request Data

All data properties expose ParameterBag instances with uniform access methods:

```php
// Query string parameters ($_GET)
$request->query->get('name');
$request->query->get('count', 0);  // With default
$request->query->all();

// POST data ($_POST)
$request->request->get('email');
$request->request->all();

// Cookies ($_COOKIE)
$request->cookies->get('session_id');

// File uploads
$uploadedFile = $request->files->get('uploaded_file');

// Server variables ($_SERVER)
$method = $request->server->get('REQUEST_METHOD');

// HTTP headers
$userAgent = $request->headers->get('User-Agent');

// Custom attributes (set by application)
$userId = $request->attributes->get('user_id');
$request->attributes->set('user', $user);

// Raw request body
$content = $request->getContent();

// JSON payload (POST or PUT)
$data = $request->toArray();        // Parse JSON to array
$payload = $request->getPayload();  // InputBag instance
$payload->all();
```

### Type-Safe Data Access

Use FilterBag methods to convert and validate data:

```php
$request->query->getInt('id');             // Convert to integer
$request->query->getBoolean('active');     // Convert to boolean
$request->query->getString('name');        // Get as string
$request->query->getDigits('phone');       // Only digits
$request->query->getAlpha('letters');      // Only alphabetic
$request->query->getAlnum('mixed');        // Alphanumeric only
$request->query->getEnum('status', MyEnum::class);  // Enum conversion
$request->query->filter('email', FILTER_VALIDATE_EMAIL);  // Custom filter
```

### ParameterBag Methods

```php
// Check/modify
$request->query->has('foo');
$request->query->set('key', 'value');
$request->query->add(['key' => 'val']);
$request->query->remove('key');
$request->query->replace(['new' => 'data']);
$request->query->keys();
```

### Request Information

```php
$request->getMethod();          // GET, POST, PUT, etc.
$request->getPathInfo();        // /post/hello-world
$request->getContentType();     // text/html, application/json
$request->getClientIp();        // Client's IP address
$request->isSecure();           // HTTPS?
$request->isXmlHttpRequest();   // AJAX request?
$request->isMethod('POST');     // Check specific method
```

### Headers and Content Negotiation

```php
// Get individual header
$userAgent = $request->headers->get('User-Agent');

// Get accepted content types (sorted by quality)
$types = $request->getAcceptableContentTypes();

// Get accepted languages
$languages = $request->getLanguages();

// Get accepted character sets
$charsets = $request->getCharsets();

// Get accepted encodings
$encodings = $request->getEncodings();

// Advanced Accept header parsing
use Symfony\Component\HttpFoundation\AcceptHeader;

$acceptHeader = AcceptHeader::fromString(
    $request->headers->get('Accept')
);

if ($acceptHeader->has('text/html')) {
    $item = $acceptHeader->get('text/html');
    $charset = $item->getAttribute('charset', 'utf-8');
    $quality = $item->getQuality();  // 0.0 to 1.0
}
```

### Session Access

```php
// Check if previous session exists
if ($request->hasPreviousSession()) {
    $session = $request->getSession();
    $session->set('key', 'value');
    $session->get('key');
}
```

### Request Matching

Match requests against specific criteria:

```php
use Symfony\Component\HttpFoundation\RequestMatcher\PathRequestMatcher;
use Symfony\Component\HttpFoundation\RequestMatcher\MethodRequestMatcher;
use Symfony\Component\HttpFoundation\ChainRequestMatcher;

// Single matcher
$matcher = new PathRequestMatcher('^/admin');
if ($matcher->matches($request)) { }

// Multiple matchers (all must match)
$matcher = new ChainRequestMatcher([
    new PathRequestMatcher('^/admin'),
    new MethodRequestMatcher('POST'),
]);

if ($matcher->matches($request)) { }
```

Available matchers: AttributesRequestMatcher, ExpressionRequestMatcher, HeaderRequestMatcher, HostRequestMatcher, IpsRequestMatcher, IsJsonRequestMatcher, MethodRequestMatcher, PathRequestMatcher, PortRequestMatcher, QueryParameterRequestMatcher, SchemeRequestMatcher.

### IP Address Utilities

```php
use Symfony\Component\HttpFoundation\IpUtils;

// Anonymize IP addresses (GDPR compliance)
$anonymized = IpUtils::anonymize('123.234.235.236');
// => '123.234.235.0'

$anonymized = IpUtils::anonymize('2a01:198:603:10::1');
// => '2a01:198:603:10::'

// Check CIDR subnet membership
$isInSubnet = IpUtils::checkIp('192.168.1.56', '192.168.1.0/16');  // true
$isInSubnet = IpUtils::checkIp('2001:db8:abcd:1234::1', '2001:db8:abcd::/48');

// Check if private IP
$isPrivate = IpUtils::isPrivateIp('192.168.1.1');   // true
$isPrivate = IpUtils::isPrivateIp('8.8.8.8');       // false
```

### Other Request Methods

```php
$request->duplicate();          // Create request copy
$request->getUri();            // Full URI
$request->getBaseUrl();        // Base URL without path
$request->getBasePath();       // Base path
$request->getQueryString();    // Query string
$request->overrideGlobals();   // Override PHP globals with Request data
```

## Response Class - Send HTTP Responses

Create and send HTTP responses to clients.

### Basic Response Creation

```php
use Symfony\Component\HttpFoundation\Response;

$response = new Response(
    'Hello World',                    // Content
    Response::HTTP_OK,               // Status code (default 200)
    ['content-type' => 'text/plain'] // Headers
);

// Or modify after creation
$response->setContent('Updated content');
$response->setStatusCode(Response::HTTP_CREATED);
$response->headers->set('X-Custom-Header', 'value');
$response->setCharset('UTF-8');
```

### Sending Responses

```php
// Prepare response (fix HTTP specification issues)
$response->prepare($request);

// Send to client
$response->send();

// Send without flushing (debugging)
$response->send(false);
```

### JsonResponse - JSON APIs

```php
use Symfony\Component\HttpFoundation\JsonResponse;

// Create with data
$response = new JsonResponse(['user_id' => 42, 'name' => 'John']);

// Build progressively
$response = new JsonResponse();
$response->setData(['status' => 'success']);

// From pre-encoded JSON string
$response = JsonResponse::fromJsonString('{"status":"ok"}');

// JSONP callback (for cross-domain requests)
$response->setCallback('handleResponse');
// Sends: handleResponse({"status":"ok"});

// Security note: Always return object, not array at root level
```

### RedirectResponse - HTTP Redirects

```php
use Symfony\Component\HttpFoundation\RedirectResponse;

$response = new RedirectResponse('/path/to/redirect');
$response->setStatusCode(Response::HTTP_MOVED_PERMANENTLY);  // 301
```

### StreamedResponse - Stream Large Content

Stream content with callback to handle large responses:

```php
use Symfony\Component\HttpFoundation\StreamedResponse;

// With chunks array
$response = new StreamedResponse();
$response->setChunks(['Hello', ' ', 'World']);

// With callback function
$response = new StreamedResponse();
$response->setCallback(function (): void {
    echo 'Line 1';
    flush();
    sleep(1);
    echo 'Line 2';
    flush();
});

// Disable Nginx buffering
$response->headers->set('X-Accel-Buffering', 'no');

$response->send();
```

### StreamedJsonResponse - Stream JSON Arrays

Generate large JSON arrays with minimal memory using generators:

```php
use Symfony\Component\HttpFoundation\StreamedJsonResponse;

function loadArticles(): \Generator {
    for ($i = 1; $i <= 1000; $i++) {
        yield ['id' => $i, 'title' => "Article $i"];
    }
}

$response = new StreamedJsonResponse([
    '_embedded' => [
        'articles' => loadArticles(),
    ],
]);

// With Doctrine ORM for database queries
public function loadArticles(): \Generator
{
    $qb = $entityManager->createQueryBuilder()
        ->from(Article::class, 'a')
        ->select('a.id', 'a.title');

    $count = 0;
    foreach ($qb->getQuery()->toIterable() as $article) {
        yield $article;
        if (0 === ++$count % 100) {
            $entityManager->flush();  // Free memory periodically
        }
    }
}
```

### EventStreamResponse - Server-Sent Events

Real-time push updates to browsers without polling:

```php
use Symfony\Component\HttpFoundation\EventStreamResponse;
use Symfony\Component\HttpFoundation\ServerEvent;

$response = new EventStreamResponse(function (): iterable {
    yield new ServerEvent('Connected');

    while (true) {
        $data = getLatestUpdate();  // Fetch update
        yield new ServerEvent(
            data: json_encode($data),
            type: 'message',
            id: uniqid(),
            retry: 5000  // Reconnect after 5 seconds if connection lost
        );
        sleep(1);
    }
});

// ServerEvent constructor:
// - data: string or iterable for multi-line content
// - type: event type for client-side listeners
// - id: event ID (browser sends Last-Event-ID on reconnect)
// - retry: milliseconds before browser retries
// - comment: keep-alive comment

$response->send();
```

### BinaryFileResponse - Serve Files

Serve files with automatic Range request support, X-Sendfile, and headers:

```php
use Symfony\Component\HttpFoundation\BinaryFileResponse;

// Serve static file
$response = new BinaryFileResponse('/path/to/file.pdf');

// With custom headers
$response->headers->set('Content-Type', 'application/pdf');
$response->setContentDisposition(
    ResponseHeaderBag::DISPOSITION_ATTACHMENT,
    'document.pdf'
);

// Delete file after sending (temp files)
$response->deleteFileAfterSend();

// Enable X-Sendfile support (nginx, Apache, FrankenPHP)
BinaryFileResponse::trustXSendfileTypeHeader();

// Temporary file handling
$file = new \SplTempFileObject();
$file->fwrite('Content');
$file->rewind();
$response = new BinaryFileResponse($file);  // Auto-deleted after send
```

### Cookies

```php
use Symfony\Component\HttpFoundation\Cookie;
use Symfony\Component\HttpFoundation\ResponseHeaderBag;

// Set cookie with fluent interface
$response->headers->setCookie(
    Cookie::create('user_id')
        ->withValue('12345')
        ->withExpires(strtotime('tomorrow'))
        ->withDomain('.example.com')
        ->withPath('/')
        ->withSecure(true)        // HTTPS only
        ->withHttpOnly(true)      // No JavaScript access
        ->withSameSite(Cookie::SAMESITE_LAX)
);

// Partitioned cookies (CHIPS - cross-site cookie isolation)
$response->headers->setCookie(
    Cookie::create('tracking', 'value', partitioned: true)
);

// Delete/clear cookie
$response->headers->clearCookie('old_cookie');

// Parse from raw header
$cookie = Cookie::fromString('Set-Cookie: name=value; Path=/');
```

### HTTP Cache Management

```php
// Cache control directives
$response->setPublic();           // Public cache (proxies, CDNs)
$response->setPrivate();          // Private cache (browsers only)
$response->setMaxAge(3600);       // Browser cache: 1 hour
$response->setSharedMaxAge(7200); // Shared cache: 2 hours
$response->expire();              // Expire immediately

// Expiration
$response->setExpires(new \DateTime('tomorrow'));
$response->setLastModified(new \DateTime());
$response->setEtag('version-123');
$response->setVary('Accept-Encoding');

// Advanced cache control
$response->setStaleIfError(86400);         // Serve stale for errors
$response->setStaleWhileRevalidate(60);    // Revalidate in background
$response->setImmutable();                 // Never revalidate

// Batch configuration
$response->setCache([
    'public'           => true,
    'max_age'          => 3600,
    's_maxage'         => 7200,
    'stale_if_error'   => 86400,
    'stale_while_revalidate' => 60,
    'must_revalidate'  => false,
    'no_cache'         => false,
    'immutable'        => true,
    'last_modified'    => new \DateTime(),
    'etag'             => 'v1',
]);

// Conditional requests (304 Not Modified)
if ($response->isNotModified($request)) {
    $response->send();  // Auto-sets 304 status
}
```

## Utility Classes

### HeaderUtils - HTTP Header Processing

```php
use Symfony\Component\HttpFoundation\HeaderUtils;

// Parse header by separator (value groups)
$parsed = HeaderUtils::split('da, en-gb;q=0.8', ',;');
// => [['da'], ['en-gb','q=0.8']]

// Combine to associative array
$combined = HeaderUtils::combine([['foo', 'abc'], ['bar']]);
// => ['foo' => 'abc', 'bar' => true]

// Join to HTTP header string
$header = HeaderUtils::toString(['foo' => 'abc', 'bar' => true], ',');
// => 'foo=abc, bar'

// Quote/unquote values
HeaderUtils::quote('foo "bar"');         // '"foo \"bar\""'
HeaderUtils::unquote('"foo \"bar\""');   // 'foo "bar"'

// Parse query string (preserves dots in keys)
HeaderUtils::parseQuery('user[first.name]=John');
// => ['user' => ['first.name' => 'John']]

// Create Content-Disposition for file serving
$disposition = HeaderUtils::makeDisposition(
    HeaderUtils::DISPOSITION_ATTACHMENT,
    'report.pdf'  // Handles non-ASCII filenames
);
```

### UrlHelper - URL Generation

```php
use Symfony\Component\HttpFoundation\UrlHelper;

// Inject or autowire UrlHelper
$urlHelper = new UrlHelper($request);

// Generate absolute URL
$absolute = $urlHelper->getAbsoluteUrl('/blog/article');
// => https://example.com/blog/article

// Generate relative path
$relative = $urlHelper->getRelativePath('/blog/article');
// => ../blog/article (from current request path)

// Available in Twig templates
// {{ absolute_url('/path') }}
// {{ relative_path('/path') }}
```

### AcceptHeader - Content Negotiation

```php
use Symfony\Component\HttpFoundation\AcceptHeader;

$acceptHeader = AcceptHeader::fromString(
    $request->headers->get('Accept')
);

// Check if content type accepted
if ($acceptHeader->has('application/json')) {
    $item = $acceptHeader->get('application/json');
    $quality = $item->getQuality();  // 0.0 to 1.0
}

// Get all items sorted by quality (highest first)
foreach ($acceptHeader->all() as $item) {
    echo $item->getValue();  // text/html, application/json, etc.
    echo $item->getQuality();
}

// Quality fallback handling
$accept = AcceptHeader::fromString('text/plain;q=0.5, text/*, */*;q=0.3');
$accept->get('text/xml')->getQuality();        // 0.8 (matches text/*)
$accept->get('application/xml')->getQuality(); // 0.3 (matches */*)
```

## Safe Content Preference (RFC 8674)

Respect user preferences for safe content:

```php
// Check if user prefers safe content
if ($request->preferSafeContent()) {
    $response = new Response($safeAlternativeContent);
    $response->setContentSafe();  // Signal preference respected
    return $response;
}
```

## Common Use Cases

### Download File
```php
$response = new BinaryFileResponse('/path/to/document.pdf');
$response->setContentDisposition(
    ResponseHeaderBag::DISPOSITION_ATTACHMENT,
    'download.pdf'
);
return $response;
```

### API JSON Response
```php
return new JsonResponse(['status' => 'success', 'id' => 42]);
```

### Stream Large Dataset
```php
$response = new StreamedJsonResponse([
    'data' => loadMillionRecords()
]);
return $response;
```

### Real-time Updates
```php
$response = new EventStreamResponse(function () {
    while (true) {
        yield new ServerEvent(json_encode(getUpdate()), 'message');
        sleep(1);
    }
});
return $response;
```

### Redirect After POST
```php
return new RedirectResponse('/success-page');
```

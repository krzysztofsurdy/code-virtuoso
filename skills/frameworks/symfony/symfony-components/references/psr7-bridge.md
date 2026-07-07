# Symfony PSR-7 Bridge

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core interfaces](#core-interfaces)
- [Core classes](#core-classes)
- [Converting HttpFoundation to PSR-7](#converting-httpfoundation-to-psr-7)
- [Converting PSR-7 to HttpFoundation](#converting-psr-7-to-httpfoundation)
- [Common use cases](#common-use-cases)
- [Supported PSR standards](#supported-psr-standards)
- [Important notes](#important-notes)
- [Related components](#related-components)
- [Integration points](#integration-points)
- [Version compatibility](#version-compatibility)

## Overview

The PSR-7 Bridge converts between Symfony's HttpFoundation objects and PSR-7 HTTP messages, so Symfony applications can use PSR-7 compatible libraries and middleware. Conversion works in both directions and supports any PSR-7/PSR-17 implementation.

## Installation

```bash
composer require symfony/psr-http-message-bridge
composer require nyholm/psr7
```

The `nyholm/psr7` package is recommended as a PSR-7 and PSR-17 implementation. Alternatively, use any PSR-7 and PSR-17 compliant library.

## Core interfaces

### HttpMessageFactoryInterface

Converts Symfony HttpFoundation objects to PSR-7 objects.

**Methods:**
- `createRequest(Request $request): ServerRequestInterface` - Convert Symfony Request to PSR-7 ServerRequestInterface
- `createResponse(Response $response): ResponseInterface` - Convert Symfony Response to PSR-7 ResponseInterface

**Location:** `Symfony\Bridge\PsrHttpMessage\HttpMessageFactoryInterface`

### HttpFoundationFactoryInterface

Converts PSR-7 objects back to Symfony HttpFoundation objects.

**Methods:**
- `createRequest(ServerRequestInterface $request): Request` - Convert PSR-7 ServerRequestInterface to Symfony Request
- `createResponse(ResponseInterface $response): Response` - Convert PSR-7 ResponseInterface to Symfony Response

**Location:** `Symfony\Bridge\PsrHttpMessage\HttpFoundationFactoryInterface`

## Core classes

### PsrHttpFactory

The main factory class for converting HttpFoundation objects to PSR-7 objects.

**Constructor:**
```php
public function __construct(
    RequestFactoryInterface $requestFactory,
    StreamFactoryInterface $streamFactory,
    UploadedFileFactoryInterface $uploadedFileFactory,
    ResponseFactoryInterface $responseFactory
)
```

**Methods:**
- `createRequest(Request $request): ServerRequestInterface`
- `createResponse(Response $response): ResponseInterface`

**Location:** `Symfony\Bridge\PsrHttpMessage\Factory\PsrHttpFactory`

**Example:**
```php
use Nyholm\Psr7\Factory\Psr17Factory;
use Symfony\Bridge\PsrHttpMessage\Factory\PsrHttpFactory;
use Symfony\Component\HttpFoundation\Request;

$psr17Factory = new Psr17Factory();
$psrHttpFactory = new PsrHttpFactory(
    $psr17Factory,
    $psr17Factory,
    $psr17Factory,
    $psr17Factory
);

$symfonyRequest = new Request(
    [],
    [],
    [],
    [],
    [],
    ['HTTP_HOST' => 'example.com'],
    'Content body'
);

$psrRequest = $psrHttpFactory->createRequest($symfonyRequest);
```

### HttpFoundationFactory

The main factory class for converting PSR-7 objects to HttpFoundation objects.

**Constructor:**
```php
public function __construct()
```

**Methods:**
- `createRequest(ServerRequestInterface $request): Request`
- `createResponse(ResponseInterface $response): Response`

**Location:** `Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory`

**Example:**
```php
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;

$httpFoundationFactory = new HttpFoundationFactory();

$symfonyRequest = $httpFoundationFactory->createRequest($psrRequest);
$symfonyResponse = $httpFoundationFactory->createResponse($psrResponse);
```

## Converting HttpFoundation to PSR-7

Convert Symfony Request and Response objects to PSR-7 compliant objects.

```php
use Nyholm\Psr7\Factory\Psr17Factory;
use Symfony\Bridge\PsrHttpMessage\Factory\PsrHttpFactory;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

// Initialize factory
$psr17Factory = new Psr17Factory();
$psrHttpFactory = new PsrHttpFactory(
    $psr17Factory,
    $psr17Factory,
    $psr17Factory,
    $psr17Factory
);

// Convert Request
$symfonyRequest = new Request(
    ['page' => '1'],
    ['name' => 'John'],
    [],
    [],
    [],
    ['HTTP_HOST' => 'example.com', 'REQUEST_METHOD' => 'POST'],
    '{"email":"john@example.com"}'
);
$psrRequest = $psrHttpFactory->createRequest($symfonyRequest);

// Convert Response
$symfonyResponse = new Response(
    'Hello World',
    Response::HTTP_OK,
    ['Content-Type' => 'text/html']
);
$psrResponse = $psrHttpFactory->createResponse($symfonyResponse);
```

## Converting PSR-7 to HttpFoundation

Convert PSR-7 ServerRequestInterface and ResponseInterface objects to Symfony objects.

```php
use Symfony\Bridge\PsrHttpMessage\Factory\HttpFoundationFactory;

$httpFoundationFactory = new HttpFoundationFactory();

// Convert ServerRequestInterface to Request
$symfonyRequest = $httpFoundationFactory->createRequest($psrRequest);

// Convert ResponseInterface to Response
$symfonyResponse = $httpFoundationFactory->createResponse($psrResponse);

// Access converted objects
echo $symfonyRequest->getPathInfo();
echo $symfonyResponse->getContent();
```

## Common use cases

### Using PSR-7 middleware in Symfony

```php
$psrHttpFactory = new PsrHttpFactory($factory1, $factory2, $factory3, $factory4);
$httpFoundationFactory = new HttpFoundationFactory();

// Convert Symfony request to PSR-7
$psrRequest = $psrHttpFactory->createRequest($symfonyRequest);

// Process with PSR-7 middleware
$psrRequest = $middleware->process($psrRequest, $handler);

// Convert back to Symfony response
$symfonyResponse = $httpFoundationFactory->createResponse($psrResponse);
```

### Third-party PSR-7 library integration

```php
use Some\ThirdParty\PsrProcessor;

$processor = new PsrProcessor();

// Convert Symfony request
$psrRequest = $psrHttpFactory->createRequest($request);

// Process with third-party PSR-7 library
$psrResponse = $processor->process($psrRequest);

// Convert to Symfony response
return $httpFoundationFactory->createResponse($psrResponse);
```

### Bridging HttpFoundation request/response properties

The bridge preserves:
- **Request:** Query parameters, POST data, cookies, files, headers, server variables, request body
- **Response:** Status code, headers, body content, content type

## Supported PSR standards

- **PSR-7** - HTTP message interfaces specification
  - `Psr\Http\Message\RequestInterface`
  - `Psr\Http\Message\ServerRequestInterface`
  - `Psr\Http\Message\ResponseInterface`
  - `Psr\Http\Message\StreamInterface`
  - `Psr\Http\Message\UploadedFileInterface`

- **PSR-17** - HTTP factories specification
  - `Psr\Http\Message\RequestFactoryInterface`
  - `Psr\Http\Message\ResponseFactoryInterface`
  - `Psr\Http\Message\StreamFactoryInterface`
  - `Psr\Http\Message\UploadedFileFactoryInterface`

## Important notes

1. **HTTP_HOST Required** - Set the `HTTP_HOST` server parameter when creating Symfony Request objects to avoid errors
2. **Factory Compatibility** - Use any PSR-7 and PSR-17 compliant implementation (nyholm/psr7, guzzlehttp/psr7, slim/http, etc.)
3. **Bidirectional** - The bridge supports conversion in both directions
4. **Immutability** - PSR-7 objects are immutable; conversions create new instances
5. **Content Handling** - Stream bodies are converted between Symfony and PSR-7

## Related components

- **HttpFoundation** - Symfony's native request/response abstraction
- **HttpKernel** - Core HTTP kernel that uses HttpFoundation
- **Contracts** - Framework contracts including PSR-7 compatibility interfaces

## Integration points

Use the PSR-7 Bridge when:
- Integrating PSR-7 middleware into Symfony applications
- Using third-party libraries that only support PSR-7
- Building framework-agnostic applications
- Requiring standards-based HTTP message handling
- Implementing middleware stacks with PSR-7 compliance

## Version compatibility

- Works with Symfony 4.0+
- Supports PHP 7.1 or higher
- Compatible with all PSR-7 and PSR-17 implementations

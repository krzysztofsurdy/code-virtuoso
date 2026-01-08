---
name: Proxy Pattern
description: A structural design pattern that lets you provide a substitute or placeholder for another object. A proxy controls access to the original object, allowing you to perform something before or after the request gets through to the original object.
---

## Overview

The Proxy Pattern is a structural design pattern that creates an intermediary object (proxy) to control access to another object (subject). The proxy acts as a surrogate or placeholder, intercepting all calls to the real subject and performing additional functionality such as lazy initialization, access control, logging, or caching.

## Intent

The Proxy Pattern aims to:
- Provide a surrogate or placeholder for another object to control access to it
- Defer the initialization of expensive objects until they're actually needed
- Implement lazy initialization, access control, logging, caching, or other cross-cutting concerns
- Separate concerns from the original subject implementation

## Problem/Solution

**Problem:** You need to delay initialization of expensive objects, control access to sensitive resources, log method calls, cache results, or perform other operations transparently. Adding this logic directly to the subject class violates the Single Responsibility Principle and becomes difficult to maintain.

**Solution:** Introduce a proxy object that implements the same interface as the real subject. The proxy receives requests from clients, performs additional operations (lazy loading, access checks, logging, caching), and then delegates to the real subject. Clients work with the proxy transparently.

## Structure

```
┌─────────────────────┐
│     Client          │
└──────────┬──────────┘
           │
     ┌─────▼─────────────┐         ┌──────────────────┐
     │  Subject           │◄────────┤ Proxy            │
     │ Interface          │ depends │                  │
     └──────────────────┘          │ - realSubject     │
     ▲                             │ - cachedData      │
     │                             │ - accessControl   │
     │                             └────┬─────────────┘
     │                                  │
     │                                  │delegates to
     │                                  │
     └──────────────────────────────────┘
           RealSubject
```

## When to Use

- **Lazy Initialization:** Defer expensive object creation until needed
- **Access Control:** Restrict access to objects based on permissions or conditions
- **Logging & Auditing:** Log all method calls and property accesses to the real object
- **Caching:** Cache method results to avoid redundant expensive operations
- **Remote Objects:** Represent objects on remote servers (RPC, HTTP calls)
- **Copy-on-Write:** Create a lightweight proxy and only copy the real object when modified
- **Smart References:** Add reference counting or cleanup logic

## Implementation (PHP 8.3+)

### Subject Interface

```php
<?php

declare(strict_types=1);

interface DocumentInterface
{
    public function getContent(): string;
    public function save(string $content): void;
    public function delete(): void;
}
```

### Real Subject

```php
<?php

declare(strict_types=1);

readonly class Document implements DocumentInterface
{
    public function __construct(private string $filename)
    {
    }

    public function getContent(): string
    {
        echo "Loading document: {$this->filename}\n";
        return file_get_contents($this->filename);
    }

    public function save(string $content): void
    {
        echo "Saving document: {$this->filename}\n";
        file_put_contents($this->filename, $content);
    }

    public function delete(): void
    {
        echo "Deleting document: {$this->filename}\n";
        unlink($this->filename);
    }
}
```

### Proxy Implementation

```php
<?php

declare(strict_types=1);

readonly class DocumentProxy implements DocumentInterface
{
    private ?DocumentInterface $realDocument = null;
    private ?string $cachedContent = null;
    private bool $isInitialized = false;

    public function __construct(
        private string $filename,
        private string $userRole = 'guest'
    ) {
    }

    private function getRealDocument(): DocumentInterface
    {
        if ($this->realDocument === null) {
            echo "Initializing real document...\n";
            $this->realDocument = new Document($this->filename);
            $this->isInitialized = true;
        }
        return $this->realDocument;
    }

    private function checkAccess(string $action): void
    {
        if ($this->userRole === 'guest' && $action !== 'read') {
            throw new \RuntimeException(
                "Access denied: {$this->userRole} cannot {$action}"
            );
        }
    }

    public function getContent(): string
    {
        $this->checkAccess('read');

        if ($this->cachedContent === null) {
            echo "Cache miss - fetching from document\n";
            $this->cachedContent = $this->getRealDocument()->getContent();
        } else {
            echo "Cache hit\n";
        }

        return $this->cachedContent;
    }

    public function save(string $content): void
    {
        $this->checkAccess('write');
        echo "Proxy logging save operation\n";
        $this->getRealDocument()->save($content);
        $this->cachedContent = $content;
    }

    public function delete(): void
    {
        $this->checkAccess('delete');
        echo "Proxy logging delete operation\n";
        $this->getRealDocument()->delete();
        $this->cachedContent = null;
    }
}
```

### Usage Example

```php
<?php

declare(strict_types=1);

// Create a proxy with lazy initialization
$document = new DocumentProxy('file.txt', 'user');

// First call: initializes real document and caches
echo "First read:\n";
$content = $document->getContent();

// Second call: uses cache
echo "\nSecond read:\n";
$content = $document->getContent();

// Write operation
echo "\nWrite operation:\n";
$document->save("New content");

// Guest access attempt (will throw exception)
try {
    $guest = new DocumentProxy('file.txt', 'guest');
    $guest->save("Unauthorized");
} catch (\RuntimeException $e) {
    echo "Error: " . $e->getMessage() . "\n";
}
```

## Real-World Analogies

- **Hotel Key Card (Access Control Proxy):** A key card controls access to hotel rooms without requiring a manager to open every door
- **Proxy Voting (Access Control):** Someone votes on your behalf if you can't be present
- **Bank Check (Protection Proxy):** A check is a proxy for money that protects the account holder
- **Remote Control (Remote Service Proxy):** Controls a TV without direct access to its internals
- **Library Catalog (Virtual Proxy):** Shows book information without loading the actual book

## Pros and Cons

### Advantages

- **Single Responsibility:** Separates access control logic from the real subject
- **Lazy Initialization:** Create expensive objects only when needed
- **Transparent to Clients:** Proxy implements the same interface as the subject
- **Additional Features:** Add logging, caching, access control without modifying the subject
- **Open/Closed Principle:** Can extend functionality without changing existing code

### Disadvantages

- **Code Complexity:** Introduces additional objects and complexity
- **Performance Overhead:** Extra layer of indirection for every method call
- **Potential Delays:** Lazy initialization can cause unexpected delays on first access
- **Testing Difficulty:** Proxies can make unit testing more complex

## Relations with Other Patterns

- **Adapter:** Similar structure but different intent. Adapter changes an object's interface, while Proxy maintains the same interface
- **Decorator:** Both use composition and delegation. Decorator adds features dynamically; Proxy controls access
- **Factory:** Can be used together. Factory creates proxies, proxies create real subjects
- **Strategy:** Can work together. Proxy controls access; Strategy encapsulates algorithms
- **Virtual Proxy vs Lazy Initialization:** Virtual Proxy is a specific use case of Proxy for lazy initialization
- **Protection Proxy vs Access Control:** Protection Proxy controls access; useful with Authentication/Authorization patterns
- **Remote Proxy:** Specialized proxy for distributed systems, coordinates with RPC frameworks

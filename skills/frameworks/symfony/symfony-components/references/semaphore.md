# Symfony Semaphore Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core classes and interfaces](#core-classes-and-interfaces)
- [Available stores](#available-stores)
- [Common use cases and examples](#common-use-cases-and-examples)
- [Important considerations](#important-considerations)
- [Store comparison](#store-comparison)
- [References](#references)

## Overview

The Semaphore Component provides a mechanism to manage semaphores: synchronization primitives that allow **multiple processes to access a shared resource concurrently up to a specified limit**. Unlike a lock, which restricts access to a single process, a semaphore allows concurrent access up to a limit.

**Key Difference:**
- **Semaphore**: Multiple processes can access a resource (up to limit)
- **Lock**: Only one process can access a resource

## Installation

Install the Semaphore component via Composer:

```bash
composer require symfony/semaphore
```

For standalone use outside Symfony applications, include Composer autoloading:

```php
require_once 'vendor/autoload.php';
```

## Core classes and interfaces

### SemaphoreFactory

The primary factory for creating semaphore instances. Accepts a storage backend and creates semaphore objects.

**Key Method:**
- `createSemaphore(string $resource, int $limit, ?bool $blocking = true, ?float $timeout = 300.0, ?bool $autoRelease = true): SemaphoreInterface`
  - `$resource` (string): Arbitrary identifier for the resource being semaphored
  - `$limit` (int): Maximum number of concurrent processes allowed to acquire the semaphore
  - `$blocking` (bool): Whether `acquire()` should block until available (default: true)
  - `$timeout` (float): Maximum time to wait for acquisition in seconds (default: 300)
  - `$autoRelease` (bool): Auto-release on instance destruction (default: true)

### SemaphoreInterface

Main interface for semaphore instances.

**Key Methods:**
- `acquire(bool $blocking = true, ?float $timeout = null): bool`
  - Acquires the semaphore, returns `true` on success, `false` on failure
  - Can be called repeatedly; safe even if already acquired
  - `$blocking`: Override the factory setting for this call
  - `$timeout`: Override the factory timeout for this call

- `release(): void`
  - Explicitly releases the semaphore
  - Called automatically on instance destruction if auto-release is enabled

- `__destruct(): void`
  - Automatically releases the semaphore if auto-release is enabled

## Available stores

### RedisStore

Use Redis as the backend for distributed semaphore management.

**Configuration:**

```php
use Symfony\Component\Semaphore\SemaphoreFactory;
use Symfony\Component\Semaphore\Store\RedisStore;

$redis = new Redis();
$redis->connect('127.0.0.1', 6379);

$store = new RedisStore($redis);
$factory = new SemaphoreFactory($store);
```

With Redis cluster:

```php
$redis = new RedisCluster(null, ['127.0.0.1:7000', '127.0.0.1:7001']);
$store = new RedisStore($redis);
$factory = new SemaphoreFactory($store);
```

### DynamoDbStore

Use AWS DynamoDB for serverless semaphore management.

**Configuration:**

```php
use Symfony\Component\Semaphore\SemaphoreFactory;
use Symfony\Component\Semaphore\Store\DynamoDbStore;
use AsyncAws\DynamoDb\DynamoDbClient;

$client = new DynamoDbClient();
$store = new DynamoDbStore($client, 'semaphores-table');
$factory = new SemaphoreFactory($store);
```

## Common use cases and examples

### Basic semaphore usage

Limit concurrent access to a resource to a maximum of N processes:

```php
use Symfony\Component\Semaphore\SemaphoreFactory;
use Symfony\Component\Semaphore\Store\RedisStore;

$redis = new Redis();
$redis->connect('127.0.0.1');

$store = new RedisStore($redis);
$factory = new SemaphoreFactory($store);

// Limit to 2 concurrent processes
$semaphore = $factory->createSemaphore('pdf-invoice-generation', 2);

if ($semaphore->acquire()) {
    try {
        // Safely generate invoice with at most 2 concurrent processes
        generateInvoice();
    } finally {
        $semaphore->release();
    }
}
```

### Rate limiting with semaphores

Control the rate of resource-intensive operations:

```php
$semaphore = $factory->createSemaphore('api-requests', 5);

if ($semaphore->acquire()) {
    try {
        // Execute request with max 5 concurrent API calls
        callExternalApi();
    } finally {
        $semaphore->release();
    }
}
```

### Non-blocking acquisition

Try to acquire without waiting:

```php
// Non-blocking acquisition
if ($semaphore->acquire(blocking: false)) {
    try {
        // Perform operation
    } finally {
        $semaphore->release();
    }
} else {
    // Semaphore unavailable, handle gracefully
    logWarning('Semaphore unavailable, skipping operation');
}
```

### With timeout

Limit the wait time for acquisition:

```php
$semaphore = $factory->createSemaphore('resource', 3);

// Wait at most 5 seconds
if ($semaphore->acquire(timeout: 5.0)) {
    try {
        // Process
    } finally {
        $semaphore->release();
    }
}
```

### Disabling auto-release (persistent locking)

For cross-request or persistent locking:

```php
$semaphore = $factory->createSemaphore(
    'resource',
    limit: 2,
    autoRelease: false
);

if ($semaphore->acquire()) {
    // Lock persists across requests until explicitly released
    // Must be released manually
    $semaphore->release();
}
```

### Shared semaphore instances

Share the same semaphore instance across multiple services:

```php
// In a service container or configuration
class ApiService {
    private $semaphore;

    public function __construct(SemaphoreFactory $factory) {
        // Create once and reuse
        $this->semaphore = $factory->createSemaphore('api-calls', 10);
    }

    public function execute() {
        if ($this->semaphore->acquire()) {
            try {
                // API operation
            } finally {
                $this->semaphore->release();
            }
        }
    }
}
```

## Important considerations

### Instance distinction

Semaphore instances are distinct objects even when created for the same resource and limit. For shared coordination:
- Store the semaphore instance in a service or container
- Pass the same instance to all code that needs it
- Avoid creating multiple semaphore instances for the same resource

### Automatic release

By default, semaphores are automatically released when the instance is destroyed:

```php
function processWithSemaphore($factory) {
    $semaphore = $factory->createSemaphore('task', 2);
    $semaphore->acquire();

    // Process work

    // Auto-release happens here when $semaphore goes out of scope
}
```

### Manual release

Release explicitly in try-finally blocks so the semaphore is freed when an exception is thrown:

```php
$semaphore = $factory->createSemaphore('resource', 2);

if ($semaphore->acquire()) {
    try {
        // Do work
    } finally {
        $semaphore->release();
    }
}
```

### Blocking behavior

The `$blocking` parameter controls behavior when the semaphore limit is reached:

```php
// Blocking (default): Wait for a slot
$semaphore->acquire(blocking: true);

// Non-blocking: Return immediately
$semaphore->acquire(blocking: false);
```

## Store comparison

| Store | Type | Distribution | Best For |
|-------|------|--------------|----------|
| RedisStore | Remote | Multi-server | Distributed systems, microservices |
| DynamoDbStore | Remote | Multi-server | Serverless, AWS environments |

## References

- **Main Classes**: `SemaphoreFactory`, `SemaphoreInterface`
- **Stores**: `RedisStore`, `DynamoDbStore`
- **Related**: Compare with the Lock Component for exclusive resource access
- **GitHub**: https://github.com/symfony/semaphore

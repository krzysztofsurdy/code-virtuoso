# Symfony Contracts

## Contents

- [Overview](#overview)
- [When to use](#when-to-use)
- [Key concepts](#key-concepts)
- [Common patterns](#common-patterns)
- [Available contract packages](#available-contract-packages)
- [Configuration](#configuration)
- [Testing](#testing)
- [Common pitfalls](#common-pitfalls)
- [Additional resources](#additional-resources)

## Overview

The Contracts component is a set of abstractions extracted from Symfony components. Its interfaces keep components loosely coupled and make them interchangeable across Symfony components and third-party PHP packages.

Contracts are split by domain into independent packages, so you depend only on the abstractions you need, whether or not you use full Symfony.

## When to use

- Building applications that need loose coupling between components
- Creating reusable libraries that work with any compatible implementation
- Integrating Symfony components with third-party packages
- Using autowiring and service injection
- Setting up auto-configuration for service tagging
- Handling caching, events, translations, or HTTP operations
- Deprecating features with standard warnings

## Key concepts

### Loose coupling via interfaces

Accept contracts through type hints instead of concrete implementations:

```php
// Bad: Tightly coupled to specific implementation
public function process(FileCache $cache): void {
    // Only works with FileCache
}

// Good: Loosely coupled to contract
use Symfony\Contracts\Cache\CacheInterface;

public function process(CacheInterface $cache): void {
    // Works with any CacheInterface implementation
}
```

### Contract organization

Contracts are split by domain into separate packages and sub-namespaces:

- **Cache Contracts** - Caching operations and management
- **Event Dispatcher Contracts** - Event system abstractions
- **Service Contracts** - Service container and lifecycle management
- **Translation Contracts** - Translation and localization
- **HTTP Client Contracts** - HTTP client operations
- **Deprecation Contracts** - Standard deprecation triggers

### Provider convention

Packages implementing contracts declare them in `composer.json`:

```json
{
    "provide": {
        "symfony/cache-implementation": "3.0",
        "symfony/event-dispatcher-implementation": "3.0"
    }
}
```

## Common patterns

### Pattern 1: Autowiring cache implementations

```php
use Symfony\Contracts\Cache\CacheInterface;

class MyService {
    public function __construct(
        private CacheInterface $cache
    ) {}

    public function getData(string $key): mixed {
        return $this->cache->get($key, function() {
            return $this->expensiveOperation();
        });
    }
}
```

### Pattern 2: Event dispatcher integration

```php
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

class OrderProcessor {
    public function __construct(
        private EventDispatcherInterface $dispatcher
    ) {}

    public function process(Order $order): void {
        // Process order
        $this->dispatcher->dispatch(new OrderProcessedEvent($order));
    }
}
```

### Pattern 3: Service container lifecycle

```php
use Symfony\Contracts\Service\ServiceSubscriberInterface;
use Symfony\Contracts\Service\ServiceSubscriberTrait;

class MyHandler implements ServiceSubscriberInterface {
    use ServiceSubscriberTrait;

    public function handle(Request $request): void {
        $logger = $this->container->get('logger');
        // Use lazy-loaded services
    }

    public static function getSubscribedServices(): array {
        return [
            'logger' => 'Psr\Log\LoggerInterface',
        ];
    }
}
```

### Pattern 4: Translation services

```php
use Symfony\Contracts\Translation\TranslatorInterface;

class EmailTemplate {
    public function __construct(
        private TranslatorInterface $translator
    ) {}

    public function getSubject(string $locale): string {
        return $this->translator->trans(
            'email.subject',
            [],
            'messages',
            $locale
        );
    }
}
```

### Pattern 5: HTTP client operations

```php
use Symfony\Contracts\HttpClient\HttpClientInterface;

class ApiClient {
    public function __construct(
        private HttpClientInterface $httpClient
    ) {}

    public function fetch(string $url): array {
        $response = $this->httpClient->request('GET', $url);
        return $response->toArray();
    }
}
```

### Pattern 6: Deprecation notices

```php
class LegacyService {
    public function oldMethod(): void {
        trigger_deprecation(
            'my-vendor/my-package',
            '2.1',
            'oldMethod() is deprecated, use newMethod() instead'
        );
    }
}
```

## Available contract packages

### symfony/cache-contracts
Abstractions for cache implementations. Provides:
- `CacheInterface` - Core cache operations (get, delete, clear)
- `ItemInterface` - Individual cache items with expiration
- `TagAwareCacheInterface` - Tagged cache operations

Installation:
```bash
composer require symfony/cache-contracts
```

### symfony/event-dispatcher-contracts
Abstractions for event systems. Provides:
- `EventDispatcherInterface` - Dispatch and listen to events
- `Event` - Base event class
- Support for both class-based and attribute-based listeners

Installation:
```bash
composer require symfony/event-dispatcher-contracts
```

### symfony/service-contracts
Abstractions for service container operations. Provides:
- `ServiceProviderInterface` - Service provider access
- `ServiceSubscriberInterface` - Lazy service dependency declaration
- `ResetInterface` - Service reset and cleanup
- `ServiceSubscriberTrait` - Helper trait for service subscribers

Installation:
```bash
composer require symfony/service-contracts
```

### symfony/translation-contracts
Abstractions for translation and localization. Provides:
- `TranslatorInterface` - Message translation operations
- Support for pluralization
- Locale handling

Installation:
```bash
composer require symfony/translation-contracts
```

### symfony/http-client-contracts
Abstractions for HTTP operations. Provides:
- `HttpClientInterface` - HTTP request handling
- `ResponseInterface` - Response abstractions
- Support for async operations

Installation:
```bash
composer require symfony/http-client-contracts
```

### symfony/deprecation-contracts
Standard deprecation handling. Provides:
- `trigger_deprecation()` - A single way to emit deprecation warnings
- Consistent formatting across projects
- Integration with test tools and error reporting

Installation:
```bash
composer require symfony/deprecation-contracts
```

## Configuration

Contracts are interfaces and have no configuration of their own. Configure their implementations instead:

```yaml
# config/packages/cache.yaml
framework:
    cache:
        default: cache.app
        pools:
            cache.app: ~
            cache.system: ~

# config/packages/messenger.yaml
framework:
    messenger:
        default_bus: command.bus
        buses:
            command.bus: ~
            event.bus: ~
```

Configure service autowiring in `services.yaml`:

```yaml
# config/services.yaml
services:
    _defaults:
        autowire: true
        autoconfigure: true

    App\Service\MyService:
        arguments:
            $cache: '@cache.app'
            $dispatcher: '@event_dispatcher'
```

## Testing

### Test cache contract implementations

```php
use PHPUnit\Framework\TestCase;
use Symfony\Contracts\Cache\CacheInterface;

class CacheServiceTest extends TestCase {
    private CacheInterface $cache;

    protected function setUp(): void {
        // Use any PSR-6 compatible cache for testing
        $this->cache = new ArrayAdapter();
    }

    public function testDataCaching(): void {
        $result = $this->cache->get('key', function() {
            return 'value';
        });

        $this->assertEquals('value', $result);
    }
}
```

### Mock event dispatcher

```php
use Symfony\Component\EventDispatcher\EventDispatcher;
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

class EventProcessorTest extends TestCase {
    public function testEventDispatching(): void {
        $dispatcher = new EventDispatcher();
        $eventFired = false;

        $dispatcher->addListener('order.processed', function () use (&$eventFired): void {
            $eventFired = true;
        });

        $service = new OrderProcessor($dispatcher);
        $service->process(new Order());

        $this->assertTrue($eventFired);
    }
}
```

## Common pitfalls

- **Mixing contracts with implementations**: Use contracts in type hints and inject implementations. Never type-hint a concrete class when a contract exists.
- **Forgetting the provider declaration**: A library should declare in `composer.json` which contracts it provides.
- **Not using lazy services**: When implementing `ServiceSubscriberInterface`, request only the services you use so they load lazily.
- **Ignoring deprecation warnings**: Call `trigger_deprecation()` for all deprecated code so users can migrate.
- **Relying on implementation details**: Contracts define behavior only. Do not depend on how a particular implementation works.
- **Missing autowiring setup**: Enable `autowire` and `autoconfigure` in `services.yaml` so contracts are injected automatically.

## Additional resources

- Official [Symfony Contracts Documentation](https://symfony.com/doc/current/components/contracts.html)
- [PHP-FIG PSRs](https://www.php-fig.org/), the underlying standards
- Symfony's [Service Container Autowiring Guide](https://symfony.com/doc/current/service_container/autowiring.html)
- [Service Tagging Documentation](https://symfony.com/doc/current/service_container/tags.html)

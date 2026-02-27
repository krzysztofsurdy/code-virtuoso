# Symfony Contracts

## Overview

The Contracts component provides a comprehensive set of abstractions extracted from Symfony components. These are battle-tested, semantic interfaces that enable loose coupling, interoperability, and reusability across Symfony components and third-party PHP packages.

Contracts are organized by domain into independent packages, allowing you to depend only on the abstractions you need, regardless of whether you use full Symfony or just specific packages.

## When to use

- Building applications that need loose coupling between components
- Creating reusable libraries that work with any compatible implementation
- Integrating Symfony components with third-party packages
- Using autowiring and service injection patterns
- Setting up auto-configuration for service tagging
- Handling caching, events, translations, or HTTP operations
- Deprecating features with standardized warnings

## Key concepts

### Loose Coupling via Interfaces

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

### Contract Organization

Contracts are split by domain into separate packages and sub-namespaces. Each package provides focused abstractions:

- **Cache Contracts** - Caching operations and management
- **Event Dispatcher Contracts** - Event system abstractions
- **Service Contracts** - Service container and lifecycle management
- **Translation Contracts** - Translation and localization
- **HTTP Client Contracts** - HTTP client operations
- **Deprecation Contracts** - Standardized deprecation triggers

### Provider Convention

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

### Pattern 1: Autowiring Cache Implementations

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

### Pattern 2: Event Dispatcher Integration

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

### Pattern 3: Service Container Lifecycle

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

### Pattern 4: Translation Services

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

### Pattern 5: HTTP Client Operations

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

### Pattern 6: Deprecation Notices

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

## Available Contract Packages

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
- Support for both traditional and new attribute-based listeners

Installation:
```bash
composer require symfony/event-dispatcher-contracts
```

### symfony/service-contracts
Abstractions for service container operations. Provides:
- `ServiceProviderInterface` - Service provider access
- `ServiceSubscriberInterface` - Lazy service dependency declaration
- `ResetInterface` - Service reset/cleanup
- `ServiceSubscriberTrait` - Helper trait for service subscribers

Installation:
```bash
composer require symfony/service-contracts
```

### symfony/translation-contracts
Abstractions for translation/localization. Provides:
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
Standardized deprecation handling. Provides:
- `trigger_deprecation()` - Unified deprecation warnings
- Consistent formatting across projects
- Integration with test tools and error reporting

Installation:
```bash
composer require symfony/deprecation-contracts
```

## Configuration

Contracts are interfaces without configuration. However, configure their implementations:

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

Configure service autowiring in services.yaml:

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

### Test Cache Contract Implementations

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

### Mock Event Dispatcher

```php
use Symfony\Component\EventDispatcher\EventDispatcher;
use Symfony\Contracts\EventDispatcher\EventDispatcherInterface;

class EventProcessorTest extends TestCase {
    public function testEventDispatching(): void {
        $dispatcher = new EventDispatcher();
        $eventFired = false;

        $dispatcher->addListener('order.processed', function() {
            $eventFired = true;
        });

        $service = new OrderProcessor($dispatcher);
        $service->process(new Order());

        $this->assertTrue($eventFired);
    }
}
```

## Common pitfalls

- **Mixing Contracts with Implementations**: Use contracts in type hints, but inject implementations. Never type-hint concrete classes when contracts exist.
- **Forgetting Provider Declaration**: If creating a library, declare what contracts your package provides in `composer.json`.
- **Not Using Lazy Services**: When implementing `ServiceSubscriberInterface`, only request services you actually use to enable lazy loading.
- **Ignoring Deprecation Warnings**: Use `trigger_deprecation()` consistently for all deprecated code to help users migrate.
- **Assuming Implementation Details**: Contracts define behavior, not internal implementation. Don't rely on specific implementation details.
- **Missing Autowiring Setup**: Enable autowiring and autoconfigure in your `services.yaml` to automatically inject contracts.

## Additional resources

- For detailed API reference and implementation guides, see the official [Symfony Contracts Documentation](https://symfony.com/doc/current/components/contracts.html)
- Study [PHP-FIG PSRs](https://www.php-fig.org/) for underlying standards
- Review Symfony's [Service Container Autowiring Guide](https://symfony.com/doc/current/service_container/autowiring.html)
- Explore [Service Tagging Documentation](https://symfony.com/doc/current/service_container/tags.html)

---
name: symfony
description: Comprehensive skill for all Symfony framework components. Covers HTTP handling, dependency injection, forms, validation, caching, messaging, console commands, event dispatching, workflows, serialization, testing, filesystem operations, configuration, and utility components. Use when working with any Symfony component.
---

# Symfony Components

Complete reference for all 38 Symfony components — patterns, APIs, configuration, and best practices for PHP 8.3+ and Symfony 7.x.

## Component Index

### HTTP & Runtime
- **HttpFoundation** — Object-oriented HTTP requests/responses replacing PHP globals → [reference](references/http-foundation.md)
- **HttpKernel** — Request handling, kernel events, controller resolution, middleware → [reference](references/http-kernel.md)
- **PSR-7 Bridge** — Bidirectional HttpFoundation ↔ PSR-7 conversion → [reference](references/psr7-bridge.md)
- **Runtime** — Decoupled bootstrapping for multiple runtime environments → [reference](references/runtime.md)

### Messaging
- **Messenger** — Sync/async message buses, transports (AMQP, Redis, Doctrine), middleware, envelopes → [reference](references/messenger.md)

### Console
- **Console** — CLI commands, input/output handling, helpers, formatters, progress bars → [reference](references/console.md)

### Dependency Injection
- **DependencyInjection** — Service container, autowiring, compiler passes, tagged services → [reference](references/dependency-injection.md)
- **Contracts** — Decoupled abstractions for interoperability (Cache, EventDispatcher, HttpClient, etc.) → [reference](references/contracts.md)

### Forms & Validation
- **Form** — Form creation, field types, events, data transformers, collections, theming → [reference](references/form.md)
- **Validator** — JSR-303 constraints, custom validators, groups, severity levels → [reference](references/validator.md)
- **OptionsResolver** — Option configuration with defaults, validation, normalization, nesting → [reference](references/options-resolver.md)

### Cache, Lock & Semaphore
- **Cache** — PSR-6/PSR-16 adapters, tag-based invalidation, stampede prevention → [reference](references/cache.md)
- **Lock** — Exclusive resource locking across processes/servers (Redis, PostgreSQL, file) → [reference](references/lock.md)
- **Semaphore** — Concurrent access with configurable limits (Redis, DynamoDB) → [reference](references/semaphore.md)

### Events & Workflow
- **EventDispatcher** — Observer/Mediator patterns, listeners, subscribers, priorities → [reference](references/event-dispatcher.md)
- **Workflow** — State machines, workflow transitions, guards, metadata, events → [reference](references/workflow.md)

### Configuration & Expressions
- **Config** — Configuration loading, validation, caching, tree building, bundle config → [reference](references/config.md)
- **ExpressionLanguage** — Safe expression sandbox for business rules, validation, security → [reference](references/expression-language.md)
- **Yaml** — YAML parsing, dumping, linting with full data type support → [reference](references/yaml.md)

### Filesystem, Finder & Process
- **Filesystem** — Platform-independent file/directory operations, atomic writes, path utils → [reference](references/filesystem.md)
- **Finder** — File search with fluent criteria (name, size, date, depth, content) → [reference](references/finder.md)
- **Process** — Secure system command execution, async processes, output streaming → [reference](references/process.md)

### Serialization & Types
- **PropertyAccess** — Read/write objects and arrays via string paths (`foo.bar[baz]`) → [reference](references/property-access.md)
- **PropertyInfo** — Property metadata extraction (types, access, descriptions) → [reference](references/property-info.md)
- **TypeInfo** — PHP type extraction, resolution, and validation → [reference](references/type-info.md)
- **VarDumper** — Enhanced variable debugging with HTML/CLI formatters → [reference](references/var-dumper.md)
- **VarExporter** — Export PHP data to OPcache-optimized code, lazy ghost/proxy objects → [reference](references/var-exporter.md)

### Testing
- **BrowserKit** — Simulated browser for programmatic HTTP, cookies, history → [reference](references/browser-kit.md)
- **DomCrawler** — HTML/XML traversal, CSS selectors, form automation → [reference](references/dom-crawler.md)
- **CssSelector** — CSS-to-XPath conversion for DOM querying → [reference](references/css-selector.md)
- **PHPUnit Bridge** — Deprecation reporting, time/DNS mocking, parallel tests → [reference](references/phpunit-bridge.md)

### Data & Text Utilities
- **Uid** — UUID (v1–v8) and ULID generation, conversion, Doctrine integration → [reference](references/uid.md)
- **Clock** — Testable time abstraction with MockClock and DatePoint → [reference](references/clock.md)
- **Intl** — Internationalization data (languages, countries, currencies, timezones) → [reference](references/intl.md)
- **JsonPath** — RFC 9535 JSONPath queries on JSON structures → [reference](references/json-path.md)
- **Mime** — MIME message creation for emails and content types → [reference](references/mime.md)
- **Ldap** — LDAP/Active Directory connections, queries, and management → [reference](references/ldap.md)
- **Asset** — URL generation and versioning for web assets → [reference](references/asset.md)

## Quick Patterns

### Dependency Injection (Autowiring)

```yaml
# services.yaml — most services are autowired automatically
services:
    _defaults:
        autowire: true
        autoconfigure: true
    App\:
        resource: '../src/'
        exclude: '../src/{DI,Entity,Kernel.php}'
```

### Define a Route + Controller

```php
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

class ArticleController
{
    #[Route('/articles/{id}', methods: ['GET'])]
    public function show(int $id): Response
    {
        return new Response("Article $id");
    }
}
```

### Dispatch a Message (Async)

```php
use Symfony\Component\Messenger\MessageBusInterface;

class OrderService
{
    public function __construct(private MessageBusInterface $bus) {}

    public function place(Order $order): void
    {
        $this->bus->dispatch(new OrderPlaced($order->getId()));
    }
}
```

### Create and Validate a Form

```php
$form = $this->createForm(ArticleType::class, $article);
$form->handleRequest($request);

if ($form->isSubmitted() && $form->isValid()) {
    $em->persist($form->getData());
    $em->flush();
    return $this->redirectToRoute('article_list');
}
```

### Cache with Tags

```php
use Symfony\Contracts\Cache\ItemInterface;

$value = $cache->get('products_list', function (ItemInterface $item) {
    $item->expiresAfter(3600);
    $item->tag(['products']);
    return $this->repository->findAll();
});

$cache->invalidateTags(['products']);
```

### Console Command

```php
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

#[AsCommand(name: 'app:process', description: 'Process items')]
class ProcessCommand extends Command
{
    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $output->writeln('Processing...');
        return Command::SUCCESS;
    }
}
```

### Event Subscriber

```php
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class OrderSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [OrderPlacedEvent::class => 'onOrderPlaced'];
    }

    public function onOrderPlaced(OrderPlacedEvent $event): void
    {
        // Handle event
    }
}
```

### Workflow Transition

```php
if ($workflow->can($article, 'publish')) {
    $workflow->apply($article, 'publish');
}
```

### Lock a Resource

```php
$lock = $factory->createLock('pdf-generation', ttl: 30);
if ($lock->acquire()) {
    try {
        generatePdf();
    } finally {
        $lock->release();
    }
}
```

## Best Practices

- Target **PHP 8.3+** and **Symfony 7.x** with strict typing
- Use **attributes** over YAML/XML for routes, commands, message handlers, event listeners
- Prefer **autowiring** — only register services manually when configuration is needed
- Use **Cache Contracts** (`$cache->get()`) over raw PSR-6 for stampede prevention
- Apply **validation groups** to support multiple form contexts
- Use **state machines** by default; use workflows only when parallel states are needed
- Create **custom constraints** for business logic that can't be expressed with built-in ones
- Mock **time and DNS** in tests using PHPUnit Bridge for deterministic results

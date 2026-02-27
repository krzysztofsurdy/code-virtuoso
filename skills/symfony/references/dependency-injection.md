# Symfony DependencyInjection Component

Manage dependencies efficiently with Symfony's powerful dependency injection container. Configure services, automate dependency resolution, and optimize container performance.

## Core Concepts

### Types of Injection

**Constructor Injection** (Recommended)
```php
class NewsletterManager
{
    public function __construct(private MailerInterface $mailer) {}
}
```

**Setter Injection** (Optional dependencies)
```php
class NewsletterManager
{
    #[Required]
    public function setMailer(MailerInterface $mailer): void
    {
        $this->mailer = $mailer;
    }
}
```

**Immutable-Setter Injection**
```php
public function withMailer(MailerInterface $mailer): self
{
    $new = clone $this;
    $new->mailer = $mailer;
    return $new;
}
```

**Property Injection** (Third-party code)
```yaml
services:
    app.newsletter_manager:
        class: App\Mail\NewsletterManager
        properties:
            mailer: '@mailer'
```

### Service Configuration

**YAML Configuration**
```yaml
services:
    App\Mail\NewsletterManager:
        arguments: ['@mailer']
        calls:
            - setLogger: ['@logger']
        tags: ['app.newsletter']
        lazy: true
        public: false
        shared: true
```

**PHP Configuration**
```php
namespace Symfony\Component\DependencyInjection\Loader\Configurator;

return static function(ContainerConfigurator $container) {
    $container->services()
        ->set(NewsletterManager::class)
        ->arguments([service('mailer')])
        ->call('setLogger', [service('logger')])
        ->tag('app.newsletter')
        ->lazy(true)
        ->public(false);
};
```

## Autowiring

Enable automatic dependency resolution by type-hints.

**Enable Autowiring**
```yaml
services:
    _defaults:
        autowire: true
        autoconfigure: true
```

**Interface-Based Autowiring**
```yaml
services:
    App\Util\Rot13Transformer: ~
    App\Util\TransformerInterface: '@App\Util\Rot13Transformer'
```

**Named Autowiring Aliases**
```yaml
services:
    App\Util\TransformerInterface: '@App\Util\Rot13Transformer'
    App\Util\TransformerInterface $shoutyTransformer: '@App\Util\UppercaseTransformer'
```

**#[Target] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\Target;

class MastodonClient
{
    public function __construct(
        #[Target('shoutyTransformer')]
        private TransformerInterface $transformer,
    ) {}
}
```

**#[Autowire] Attribute for Scalars**
```php
use Symfony\Component\DependencyInjection\Attribute\Autowire;

class MessageGenerator
{
    public function __construct(
        #[Autowire(service: 'monolog.logger.request')] private LoggerInterface $logger,
        #[Autowire('%kernel.project_dir%/data')] string $dataDir,
        #[Autowire(param: 'kernel.debug')] bool $debugMode,
        #[Autowire(env: 'SOME_ENV_VAR')] string $sender,
    ) {}
}
```

## Factory Services

Delegate object creation to factory classes.

**Static Factory**
```yaml
services:
    App\Email\NewsletterManager:
        factory: ['App\Email\NewsletterManagerStaticFactory', 'createNewsletterManager']
```

**Instance Factory**
```yaml
services:
    App\Email\NewsletterManagerFactory: ~
    App\Email\NewsletterManager:
        factory: ['@App\Email\NewsletterManagerFactory', 'createNewsletterManager']
```

**Invokable Factory**
```yaml
services:
    App\Email\NewsletterManager:
        factory: '@App\Email\InvokableNewsletterManagerFactory'
```

## Lazy Services

Defer instantiation of expensive services until first use.

**YAML Configuration**
```yaml
services:
    App\Twig\AppExtension:
        lazy: true
```

**#[Lazy] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\Lazy;

#[Lazy]
class AppExtension implements ExtensionInterface {}
```

**Interface Proxifying**
```yaml
services:
    App\Twig\AppExtension:
        lazy: 'Twig\Extension\ExtensionInterface'
```

## Service Subscribers & Locators

Lazily load multiple services without injecting the entire container.

**Service Subscribers**
```php
use Symfony\Contracts\Service\ServiceSubscriberInterface;
use Psr\Container\ContainerInterface;

class CommandBus implements ServiceSubscriberInterface
{
    public function __construct(private ContainerInterface $locator) {}

    public static function getSubscribedServices(): array
    {
        return [
            'App\FooCommand' => FooHandler::class,
            'App\BarCommand' => BarHandler::class,
        ];
    }

    public function handle(Command $command): mixed
    {
        $handler = $this->locator->get($command::class);
        return $handler->handle($command);
    }
}
```

**Service Locators**
```yaml
services:
    App\CommandBus:
        arguments:
            - !service_locator
                App\FooCommand: '@app.command_handler.foo'
                App\BarCommand: '@app.command_handler.bar'
```

**#[AutowireLocator] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AutowireLocator;

class CommandBus
{
    public function __construct(
        #[AutowireLocator([FooHandler::class, BarHandler::class])]
        private ContainerInterface $handlers,
    ) {}
}
```

**#[AutowireIterator] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AutowireIterator;

class HandlerCollection
{
    public function __construct(
        #[AutowireIterator('app.handler')]
        private iterable $handlers,
    ) {}
}
```

## Service Tags

Mark services for special handling by framework or bundles.

**Defining Tagged Services**
```yaml
services:
    App\Twig\AppExtension:
        tags: ['twig.extension']

    App\Mail\SmtpTransport:
        tags:
            - { name: 'app.mail_transport', alias: 'smtp', priority: 10 }
```

**#[AsTaggedItem] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;

#[AsTaggedItem(index: 'handler_one', priority: 10)]
class Handler {}
```

**Processing Tagged Services**
```php
foreach ($container->findTaggedServiceIds('app.mail_transport') as $id => $tags) {
    foreach ($tags as $attributes) {
        $definition->addMethodCall('addTransport', [
            new Reference($id),
            $attributes['alias'],
        ]);
    }
}
```

## Compiler Passes

Manipulate service definitions during compilation.

**Implement CompilerPassInterface**
```php
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;

class CustomPass implements CompilerPassInterface
{
    public function process(ContainerBuilder $container): void
    {
        if (!$container->has('app.some_service')) {
            return;
        }

        $definition = $container->findDefinition('app.some_service');
        // Manipulate the definition
    }
}
```

**Register in Kernel**
```php
class Kernel extends BaseKernel
{
    protected function build(ContainerBuilder $container): void
    {
        $container->addCompilerPass(new CustomPass());
    }
}
```

**Pass Execution Order**
```php
use Symfony\Component\DependencyInjection\Compiler\PassConfig;

$container->addCompilerPass(
    new FirstPass(),
    PassConfig::TYPE_AFTER_REMOVING,
    10 // priority (higher = earlier)
);
```

Available phases: `TYPE_BEFORE_OPTIMIZATION`, `TYPE_OPTIMIZE`, `TYPE_BEFORE_REMOVING`, `TYPE_REMOVE`, `TYPE_AFTER_REMOVING`

## Service Aliases

Create shortcuts to services with different IDs.

**YAML Configuration**
```yaml
services:
    App\Mail\PhpMailer: ~
    app.mailer: '@App\Mail\PhpMailer'
```

**#[AsAlias] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsAlias;

#[AsAlias(id: 'app.mailer', public: true)]
class PhpMailer {}
```

**Mark Services as Public/Private**
```yaml
services:
    App\Service\Foo:
        public: true
```

## Service Decoration

Wrap services with decorators using the Decorator pattern.

**Basic Decoration**
```yaml
services:
    App\Mailer: ~
    App\DecoratingMailer:
        decorates: App\Mailer
        arguments: ['@.inner']
```

**#[AsDecorator] Attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsDecorator;
use Symfony\Component\DependencyInjection\Attribute\AutowireDecorated;

#[AsDecorator(decorates: Mailer::class)]
class DecoratingMailer
{
    public function __construct(#[AutowireDecorated] private Mailer $mailer) {}
}
```

**Decoration Priority**
```yaml
services:
    Bar:
        decorates: Foo
        decoration_priority: 5
        arguments: ['@.inner']
    Baz:
        decorates: Foo
        decoration_priority: 1
        arguments: ['@.inner']
```
Result: `new Baz(new Bar(new Foo()))`

## Parent Services

Share common configuration across multiple services.

**Define Parent Service**
```yaml
services:
    App\Repository\BaseDoctrineRepository:
        abstract: true
        arguments: ['@doctrine.orm.entity_manager']
        calls:
            - setLogger: ['@logger']

    App\Repository\DoctrineUserRepository:
        parent: App\Repository\BaseDoctrineRepository

    App\Repository\DoctrinePostRepository:
        parent: App\Repository\BaseDoctrineRepository
        arguments:
            index_0: '@doctrine.custom_entity_manager'
```

## Optional Dependencies

Handle missing services gracefully.

**Setting Missing to Null**
```php
NewsletterManager::class => [
    'arguments' => [service('logger')->nullOnInvalid()],
],
```

**Ignoring Missing Dependencies**
```yaml
services:
    App\Newsletter\NewsletterManager:
        calls:
            - setLogger: ['@?logger']
```

**PHP Configuration**
```php
'calls' => [
    'setLogger' => [service('logger')->ignoreOnInvalid()],
],
```

## Service Definitions

Manipulate service definitions programmatically in compiler passes.

```php
use Symfony\Component\DependencyInjection\Definition;
use Symfony\Component\DependencyInjection\Reference;

// Get a definition
$definition = $container->getDefinition('app.mailer');

// Set class
$definition->setClass(CustomMailer::class);

// Manage arguments
$definition->setArguments([new Reference('logger')]);
$definition->addArgument('value');
$definition->setArgument('$name', $value);

// Method calls
$definition->addMethodCall('setLogger', [new Reference('logger')]);

// Check existence
if ($container->hasDefinition('app.mailer')) {
    // Process
}
```

## Container Compilation & Caching

Compile and dump the container for production.

**Compilation**
```php
use Symfony\Component\DependencyInjection\ContainerBuilder;

$container = new ContainerBuilder();
// ... configure services
$container->compile();
```

**Dumping to PHP**
```php
use Symfony\Component\DependencyInjection\Dumper\PhpDumper;
use Symfony\Component\Config\ConfigCache;

$file = __DIR__ . '/cache/container.php';
$cache = new ConfigCache($file, $isDebug = false);

if (!$cache->isFresh()) {
    $container = new ContainerBuilder();
    // ... configure
    $container->compile();

    $dumper = new PhpDumper($container);
    $cache->write(
        $dumper->dump(['class' => 'MyCachedContainer']),
        $container->getResources()
    );
}

require $file;
$container = new MyCachedContainer();
```

## Best Practices

- Use constructor injection for required dependencies
- Enable autowiring with type-hints for cleaner configuration
- Use setter injection only for optional dependencies
- Mark services private by default for better optimization
- Use service tags to organize related services
- Implement lazy loading for heavy/rarely-used services
- Use service locators instead of injecting the full container
- Leverage compiler passes to handle cross-service configuration
- Cache compiled container in production for performance
- Use aliases to provide convenient shortcuts to services
- Document service dependencies with proper type-hints and attributes
- Avoid circular dependencies; refactor if needed

## Service Visibility

- **Private services** (default): Only accessible via dependency injection
- **Public services**: Accessible via `$container->get('service_id')`
- **Synthetic services**: Injected directly into the container at runtime
- **Abstract services**: Only used as parents for inheritance

## Key Classes & Interfaces

- `ContainerBuilder`: Build and configure services
- `Container`: Runtime access to services
- `Definition`: Describe how to construct a service
- `Reference`: Reference another service
- `CompilerPassInterface`: Manipulate definitions during compilation
- `ExtensionInterface`: Load bundle-specific configuration
- `ServiceSubscriberInterface`: Define dependencies for lazy loading
- `ServiceLocator`: PSR-11 container for predefined services

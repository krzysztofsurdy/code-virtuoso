# Symfony DependencyInjection Component

The DependencyInjection component provides Symfony's service container. Use it to configure services, resolve dependencies automatically, and compile the container for production.

## Contents

- [Core concepts](#core-concepts)
- [Autowiring](#autowiring)
- [Factory services](#factory-services)
- [Lazy services](#lazy-services)
- [Service subscribers and locators](#service-subscribers-and-locators)
- [Service tags](#service-tags)
- [Compiler passes](#compiler-passes)
- [Service aliases](#service-aliases)
- [Service decoration](#service-decoration)
- [Parent services](#parent-services)
- [Optional dependencies](#optional-dependencies)
- [Service definitions](#service-definitions)
- [Container compilation and caching](#container-compilation-and-caching)
- [Best practices](#best-practices)
- [Service visibility](#service-visibility)
- [Key classes and interfaces](#key-classes-and-interfaces)

## Core concepts

### Types of injection

**Constructor injection** (recommended)
```php
class NewsletterManager
{
    public function __construct(private MailerInterface $mailer) {}
}
```

**Setter injection** (optional dependencies)
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

**Immutable-setter injection**
```php
public function withMailer(MailerInterface $mailer): self
{
    $new = clone $this;
    $new->mailer = $mailer;
    return $new;
}
```

**Property injection** (third-party code)
```yaml
services:
    app.newsletter_manager:
        class: App\Mail\NewsletterManager
        properties:
            mailer: '@mailer'
```

### Service configuration

**YAML configuration**
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

**PHP configuration**
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

Autowiring resolves dependencies from type hints.

**Enable autowiring**
```yaml
services:
    _defaults:
        autowire: true
        autoconfigure: true
```

**Interface-based autowiring**
```yaml
services:
    App\Util\Rot13Transformer: ~
    App\Util\TransformerInterface: '@App\Util\Rot13Transformer'
```

**Named autowiring aliases**
```yaml
services:
    App\Util\TransformerInterface: '@App\Util\Rot13Transformer'
    App\Util\TransformerInterface $shoutyTransformer: '@App\Util\UppercaseTransformer'
```

**#[Target] attribute**
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

**#[Autowire] attribute for scalars**
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

## Factory services

Delegate object creation to factory classes.

**Static factory**
```yaml
services:
    App\Email\NewsletterManager:
        factory: ['App\Email\NewsletterManagerStaticFactory', 'createNewsletterManager']
```

**Instance factory**
```yaml
services:
    App\Email\NewsletterManagerFactory: ~
    App\Email\NewsletterManager:
        factory: ['@App\Email\NewsletterManagerFactory', 'createNewsletterManager']
```

**Invokable factory**
```yaml
services:
    App\Email\NewsletterManager:
        factory: '@App\Email\InvokableNewsletterManagerFactory'
```

## Lazy services

Defer instantiation of expensive services until first use.

**YAML configuration**
```yaml
services:
    App\Twig\AppExtension:
        lazy: true
```

**#[Lazy] attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\Lazy;

#[Lazy]
class AppExtension implements ExtensionInterface {}
```

**Interface proxying**
```yaml
services:
    App\Twig\AppExtension:
        lazy: 'Twig\Extension\ExtensionInterface'
```

## Service subscribers and locators

Load several services lazily without injecting the whole container.

**Service subscribers**
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

**Service locators**
```yaml
services:
    App\CommandBus:
        arguments:
            - !service_locator
                App\FooCommand: '@app.command_handler.foo'
                App\BarCommand: '@app.command_handler.bar'
```

**#[AutowireLocator] attribute**
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

**#[AutowireIterator] attribute**
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

## Service tags

Tag services so the framework or a bundle can handle them specially.

**Defining tagged services**
```yaml
services:
    App\Twig\AppExtension:
        tags: ['twig.extension']

    App\Mail\SmtpTransport:
        tags:
            - { name: 'app.mail_transport', alias: 'smtp', priority: 10 }
```

**#[AsTaggedItem] attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsTaggedItem;

#[AsTaggedItem(index: 'handler_one', priority: 10)]
class Handler {}
```

**Processing tagged services**
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

## Compiler passes

Compiler passes change service definitions during compilation.

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

**Register in the kernel**
```php
class Kernel extends BaseKernel
{
    protected function build(ContainerBuilder $container): void
    {
        $container->addCompilerPass(new CustomPass());
    }
}
```

**Pass execution order**
```php
use Symfony\Component\DependencyInjection\Compiler\PassConfig;

$container->addCompilerPass(
    new FirstPass(),
    PassConfig::TYPE_AFTER_REMOVING,
    10 // priority (higher = earlier)
);
```

Available phases: `TYPE_BEFORE_OPTIMIZATION`, `TYPE_OPTIMIZE`, `TYPE_BEFORE_REMOVING`, `TYPE_REMOVE`, `TYPE_AFTER_REMOVING`

## Service aliases

An alias gives a service a second ID.

**YAML configuration**
```yaml
services:
    App\Mail\PhpMailer: ~
    app.mailer: '@App\Mail\PhpMailer'
```

**#[AsAlias] attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsAlias;

#[AsAlias(id: 'app.mailer', public: true)]
class PhpMailer {}
```

**Mark services public or private**
```yaml
services:
    App\Service\Foo:
        public: true
```

## Service decoration

Wrap services with decorators using the Decorator pattern.

**Basic decoration**
```yaml
services:
    App\Mailer: ~
    App\DecoratingMailer:
        decorates: App\Mailer
        arguments: ['@.inner']
```

**#[AsDecorator] attribute**
```php
use Symfony\Component\DependencyInjection\Attribute\AsDecorator;
use Symfony\Component\DependencyInjection\Attribute\AutowireDecorated;

#[AsDecorator(decorates: Mailer::class)]
class DecoratingMailer
{
    public function __construct(#[AutowireDecorated] private Mailer $mailer) {}
}
```

**Decoration priority**
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

## Parent services

Share common configuration across services.

**Define a parent service**
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

## Optional dependencies

Handle services that may be missing.

**Set a missing service to null**
```php
NewsletterManager::class => [
    'arguments' => [service('logger')->nullOnInvalid()],
],
```

**Ignore missing dependencies**
```yaml
services:
    App\Newsletter\NewsletterManager:
        calls:
            - setLogger: ['@?logger']
```

**PHP configuration**
```php
'calls' => [
    'setLogger' => [service('logger')->ignoreOnInvalid()],
],
```

## Service definitions

Change service definitions programmatically in compiler passes.

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

## Container compilation and caching

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

## Best practices

- Use constructor injection for required dependencies
- Enable autowiring and rely on type hints to keep configuration short
- Use setter injection only for optional dependencies
- Keep services private by default, which lets the container optimize them
- Use service tags to group related services
- Make heavy or rarely used services lazy
- Inject a service locator instead of the full container
- Use compiler passes for configuration that spans several services
- Cache the compiled container in production
- Use aliases as shortcuts to services
- Express service dependencies through type hints and attributes
- Avoid circular dependencies; refactor if you hit one

## Service visibility

- **Private services** (default): Only accessible via dependency injection
- **Public services**: Accessible via `$container->get('service_id')`
- **Synthetic services**: Injected directly into the container at runtime
- **Abstract services**: Only used as parents for inheritance

## Key classes and interfaces

- `ContainerBuilder`: Build and configure services
- `Container`: Runtime access to services
- `Definition`: Describe how to construct a service
- `Reference`: Reference another service
- `CompilerPassInterface`: Manipulate definitions during compilation
- `ExtensionInterface`: Load bundle-specific configuration
- `ServiceSubscriberInterface`: Define dependencies for lazy loading
- `ServiceLocator`: PSR-11 container for predefined services

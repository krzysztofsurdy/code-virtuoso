# Symfony Config Component

## Contents

- [Overview](#overview)
- [Core classes](#core-classes)
- [Loading configuration resources](#loading-configuration-resources)
- [Configuration caching](#configuration-caching)
- [Creating bundle configuration](#creating-bundle-configuration)
- [Loading service configuration](#loading-service-configuration)
- [Sharing configuration across bundles](#sharing-configuration-across-bundles)
- [Best practices](#best-practices)
- [Common patterns](#common-patterns)

## Overview

The Config component manages application configuration. It defines configuration structures with validation rules, loads configuration from several sources, merges it, and caches the result.

### When to use this reference

- Define and validate application or bundle configuration
- Load configuration from YAML, XML, INI, attributes, or custom formats
- Merge several configuration sources
- Cache processed configuration
- Give bundles a user-friendly configuration interface
- Share configuration across bundles

## Core classes

### Configuration definition

#### TreeBuilder
Defines all configuration validation rules. Returned from a `Configuration` class implementing `ConfigurationInterface`:

```php
use Symfony\Component\Config\Definition\Builder\TreeBuilder;
use Symfony\Component\Config\Definition\ConfigurationInterface;

class DatabaseConfiguration implements ConfigurationInterface
{
    public function getConfigTreeBuilder(): TreeBuilder
    {
        $treeBuilder = new TreeBuilder('database');
        $rootNode = $treeBuilder->getRootNode();

        $rootNode
            ->children()
                ->scalarNode('driver')->defaultValue('mysql')->end()
                ->scalarNode('host')->defaultValue('localhost')->end()
                ->integerNode('port')->defaultValue(3306)->end()
            ->end()
        ;

        return $treeBuilder;
    }
}
```

#### Processor
Processes and merges configuration arrays according to the defined rules:

```php
use Symfony\Component\Config\Definition\Processor;

$processor = new Processor();
$configuration = new DatabaseConfiguration();
$processedConfig = $processor->processConfiguration($configuration, $configs);
```

### Node types

- **scalar** - Generic scalar values (strings, numbers, booleans, null)
- **boolean** - Boolean true/false values
- **string** - String values
- **integer** - Integer numbers with optional min/max constraints
- **float** - Floating-point numbers with optional min/max constraints
- **enum** - Restricted to predefined values or PHP enums
- **array** - Nested array structures with prototypes
- **variable** - No validation, accepts any value

### Node definition examples

```php
$rootNode
    ->children()
        // Basic nodes
        ->booleanNode('debug')->defaultTrue()->end()
        ->stringNode('env')->defaultValue('prod')->end()
        ->integerNode('max_connections')->min(1)->max(100)->end()

        // Enum node with predefined values
        ->enumNode('log_level')
            ->values(['debug', 'info', 'warning', 'error'])
            ->defaultValue('info')
        ->end()

        // Enum with PHP enum
        ->enumNode('delivery')
            ->enumFqcn(Delivery::class)
        ->end()

        // Required nodes
        ->scalarNode('api_key')
            ->isRequired()
            ->cannotBeEmpty()
        ->end()

        // Node with constraints
        ->floatNode('timeout')
            ->min(0.1)
            ->max(300)
            ->defaultValue(30)
        ->end()
    ->end()
;
```

### Array nodes with prototypes

Define nested array structures with repeating elements:

```php
->arrayNode('connections')
    ->arrayPrototype()
        ->children()
            ->scalarNode('driver')->end()
            ->scalarNode('host')->end()
            ->integerNode('port')->defaultValue(5432)->end()
        ->end()
    ->end()
    ->requiresAtLeastOneElement()
    ->addDefaultsIfNotSet()
->end()
```

### Array node methods

- `arrayPrototype()` - Repeat the same structure for array elements
- `useAttributeAsKey('name')` - Use a child node's value as the array key
- `requiresAtLeastOneElement()` - Array must contain at least one element
- `addDefaultsIfNotSet()` - Apply child default values automatically
- `normalizeKeys(false)` - Don't normalize dashes to underscores
- `ignoreExtraKeys()` - Allow extra configuration keys
- `acceptAndWrap()` - Auto-wrap scalar values into arrays

### Normalization and validation

#### Normalization

Normalize configuration before validation:

```php
->arrayNode('connection')
    ->beforeNormalization()
        ->ifString()
        ->then(function (string $v): array { return ['name' => $v]; })
    ->end()
->end()
```

#### Validation

Use `ExprBuilder` for custom validation logic:

```php
->scalarNode('driver')
    ->isRequired()
    ->validate()
        ->ifNotInArray(['mysql', 'sqlite', 'mssql'])
        ->thenInvalid('Invalid driver %s')
    ->end()
->end()
```

Validation conditions:
- `ifTrue()`, `ifFalse()`, `ifString()`, `ifNull()`, `ifEmpty()`, `ifArray()`
- `ifInArray()`, `ifNotInArray()`, `always()`

### Deprecating options

Mark an option as deprecated:

```php
->integerNode('old_option')
    ->setDeprecated('acme/package', '1.2', 'Use "new_option" instead')
->end()
```

### Documenting options

Add a description to an option:

```php
->integerNode('entries_per_page')
    ->info('This value is only used for the search results page.')
    ->defaultValue(25)
->end()
```

## Loading configuration resources

### FileLocator

Searches the given directories for configuration files:

```php
use Symfony\Component\Config\FileLocator;

$locator = new FileLocator([__DIR__.'/config']);
$files = $locator->locate('users.yaml', null, false);  // false = first match
$allFiles = $locator->locate('*.yaml', null, true);    // true = all matches
```

### Custom loader implementation

Create custom loaders by extending `FileLoader` or implementing `LoaderInterface`:

```php
use Symfony\Component\Config\Loader\FileLoader;
use Symfony\Component\Yaml\Yaml;

class YamlUserLoader extends FileLoader
{
    public function load($resource, $type = null): void
    {
        $configValues = Yaml::parse(file_get_contents($resource));

        // Process configuration
        foreach ($configValues as $user) {
            // Handle user configuration
        }

        // Import other resources if needed
        $this->import('extra_users.yaml');
    }

    public function supports($resource, $type = null): bool
    {
        return is_string($resource) && 'yaml' === pathinfo($resource, PATHINFO_EXTENSION);
    }
}
```

### Loader resolution

Use `LoaderResolver` and `DelegatingLoader` to pick the loader automatically:

```php
use Symfony\Component\Config\Loader\DelegatingLoader;
use Symfony\Component\Config\Loader\LoaderResolver;

$resolver = new LoaderResolver([
    new YamlUserLoader($locator),
    new XmlUserLoader($locator),
]);

$delegatingLoader = new DelegatingLoader($resolver);
$delegatingLoader->load(__DIR__.'/users.yaml');  // Automatically selects YamlUserLoader
```

## Configuration caching

### ConfigCache class

Cache processed configuration and track changes to its resources:

```php
use Symfony\Component\Config\ConfigCache;
use Symfony\Component\Config\Resource\FileResource;

$cachePath = __DIR__.'/cache/appConfig.php';
$cache = new ConfigCache($cachePath, true);  // true = debug mode

if (!$cache->isFresh()) {
    $resources = [];

    // Load configuration from resources
    foreach ($yamlFiles as $file) {
        $delegatingLoader->load($file);
        $resources[] = new FileResource($file);
    }

    // Generate code/config
    $code = generateConfigCode($delegatingLoader);

    // Write to cache with resource tracking
    $cache->write($code, $resources);
}

// Use cached configuration
require $cachePath;
```

### Constructor parameters

```php
new ConfigCache($cachePath, $debug = false, $metaPath = null);
```

- `$cachePath` - File path where cache is stored
- `$debug` - When true, creates `.meta` file for resource tracking
- `$metaPath` - Optional absolute path to the meta file

### How caching works

1. **Check freshness**: `isFresh()` compares resource timestamps against the `.meta` file
2. **Generate**: If the cache is stale, load all resources again
3. **Store**: Write the generated code and resource list with `write()`
4. **Track**: In debug mode, timestamps are serialized for later comparison

## Creating bundle configuration

### With AbstractBundle

Define configuration directly in the bundle class:

```php
use Symfony\Component\Config\Definition\Configurator\DefinitionConfigurator;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\Configurator\ContainerConfigurator;
use Symfony\Component\HttpKernel\Bundle\AbstractBundle;

class AcmeSocialBundle extends AbstractBundle
{
    public function configure(DefinitionConfigurator $definition): void
    {
        $definition->rootNode()
            ->children()
                ->arrayNode('twitter')
                    ->children()
                        ->integerNode('client_id')->end()
                        ->scalarNode('client_secret')->end()
                    ->end()
                ->end()
            ->end()
        ;
    }

    public function loadExtension(array $config, ContainerConfigurator $container, ContainerBuilder $builder): void
    {
        $container->services()
            ->get('acme_social.twitter_client')
            ->arg(0, $config['twitter']['client_id'])
            ->arg(1, $config['twitter']['client_secret'])
        ;
    }
}
```

### With Configuration and Extension classes

Create separate `Configuration` and `Extension` classes:

```php
// Configuration class
namespace Acme\SocialBundle\DependencyInjection;

class Configuration implements ConfigurationInterface
{
    public function getConfigTreeBuilder(): TreeBuilder
    {
        $treeBuilder = new TreeBuilder('acme_social');
        $treeBuilder->getRootNode()
            ->children()
                ->arrayNode('twitter')
                    ->children()
                        ->integerNode('client_id')->end()
                        ->scalarNode('client_secret')->end()
                    ->end()
                ->end()
            ->end()
        ;
        return $treeBuilder;
    }
}

// Extension class
namespace Acme\SocialBundle\DependencyInjection;

use Symfony\Component\DependencyInjection\Extension\Extension;

class AcmeSocialExtension extends Extension
{
    public function load(array $configs, ContainerBuilder $container): void
    {
        $loader = new PhpFileLoader(
            $container,
            new FileLocator(dirname(__DIR__).'/Resources/config')
        );
        $loader->load('services.php');

        $configuration = new Configuration();
        $config = $this->processConfiguration($configuration, $configs);

        $container->getDefinition('acme_social.twitter_client')
            ->replaceArgument(0, $config['twitter']['client_id'])
            ->replaceArgument(1, $config['twitter']['client_secret'])
        ;
    }
}
```

### User configuration

Users configure the bundle in YAML:

```yaml
# config/packages/acme_social.yaml
acme_social:
    twitter:
        client_id: 123
        client_secret: your_secret
```

### View the configuration reference

```bash
php bin/console config:dump-reference acme_social
```

## Loading service configuration

### With AbstractBundle.loadExtension()

```php
class AcmeHelloBundle extends AbstractBundle
{
    public function loadExtension(array $config, ContainerConfigurator $container, ContainerBuilder $builder): void
    {
        // Import configuration files
        $container->import('../config/services.php');

        // Set parameters based on configuration
        $container->parameters()
            ->set('acme_hello.phrase', $config['phrase'])
        ;

        // Conditionally modify services
        if ($config['scream']) {
            $container->services()
                ->get('acme_hello.printer')
                ->class(ScreamingPrinter::class)
            ;
        }
    }
}
```

### With an Extension class

```php
namespace Acme\HelloBundle\DependencyInjection;

use Symfony\Component\DependencyInjection\Extension\Extension;

class AcmeHelloExtension extends Extension
{
    public function load(array $configs, ContainerBuilder $container): void
    {
        $loader = new PhpFileLoader(
            $container,
            new FileLocator(__DIR__.'/../../config')
        );
        $loader->load('services.php');
    }
}
```

## Sharing configuration across bundles

### Using PrependExtensionInterface

Prepend configuration for other bundles before their `load()` method runs:

```php
use Symfony\Component\DependencyInjection\Extension\PrependExtensionInterface;

class AcmeHelloExtension extends Extension implements PrependExtensionInterface
{
    public function prepend(ContainerBuilder $container): void
    {
        $bundles = $container->getParameter('kernel.bundles');

        if (isset($bundles['AcmeGoodbyeBundle'])) {
            $config = ['use_acme_goodbye' => true];
            $container->prependExtensionConfig('acme_goodbye', $config);
        }
    }
}
```

### Using AbstractBundle.prependExtension()

```php
class FooBundle extends AbstractBundle
{
    public function prependExtension(ContainerConfigurator $container, ContainerBuilder $builder): void
    {
        $builder->prependExtensionConfig('framework', [
            'cache' => ['prefix_seed' => 'foo/bar'],
        ]);
    }
}
```

### Key behaviors

- **User config overrides**: User-defined configuration takes priority over prepended settings
- **First bundle wins**: The first registered bundle's prepended value takes priority
- **Compile-time only**: Prepend methods run only during container compilation

## Best practices

1. **Use AbstractBundle for new bundles** - The API is simpler than separate Extension and Configuration classes
2. **Define defaults** - Give every option a default value
3. **Validate configuration** - Use validation rules to catch errors early
4. **Document options** - Use `info()` to describe what each option does
5. **Cache in production** - Use `ConfigCache` with resource tracking
6. **Support several formats** - Write loaders for YAML, XML, and PHP
7. **Deprecate options before removing them** - Point users to the replacement
8. **Normalize configuration** - Use `beforeNormalization()` to handle variations in user input

## Common patterns

### Optional bundle features

```php
public function prepend(ContainerBuilder $container): void
{
    $bundles = $container->getParameter('kernel.bundles');

    if (isset($bundles['DoctrineBundle'])) {
        $container->prependExtensionConfig('acme_hello', [
            'database_enabled' => true
        ]);
    }
}
```

### Environment-specific configuration

```php
if ($container->getParameter('kernel.environment') === 'dev') {
    $container->prependExtensionConfig('acme_hello', [
        'debug' => true,
        'log_level' => 'debug'
    ]);
}
```

### Merging configuration from multiple files

```php
$processor = new Processor();
$config = new Configuration();

$configs = [
    $this->load('config/defaults.yaml'),
    $this->load('config/custom.yaml'),
];

$processedConfig = $processor->processConfiguration($config, $configs);
```

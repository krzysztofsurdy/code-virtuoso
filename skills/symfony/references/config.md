# Symfony Config Component

## Overview

The Config Component is a Symfony utility for managing application configuration. It provides tools to define configuration structures with validation rules, load configuration from multiple sources, merge configurations, and implement intelligent caching.

### When to Use This Skill

- Define and validate application or bundle configuration
- Load configuration from YAML, XML, INI, attributes, or custom formats
- Merge multiple configuration sources
- Cache processed configuration for performance
- Create user-friendly bundle configuration interfaces
- Share configuration across multiple bundles

## Core Classes

### Configuration Definition

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
Processes and merges multiple configuration arrays according to defined rules:

```php
use Symfony\Component\Config\Definition\Processor;

$processor = new Processor();
$configuration = new DatabaseConfiguration();
$processedConfig = $processor->processConfiguration($configuration, $configs);
```

### Node Types

Define configuration nodes using these types:

- **scalar** - Generic scalar values (strings, numbers, booleans, null)
- **boolean** - Boolean true/false values
- **string** - String values
- **integer** - Integer numbers with optional min/max constraints
- **float** - Floating-point numbers with optional min/max constraints
- **enum** - Restricted to predefined values or PHP enums
- **array** - Nested array structures with prototypes
- **variable** - No validation, accepts any value

### Node Definition Examples

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

### Array Nodes with Prototypes

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

### Array Node Methods

- `arrayPrototype()` - Repeat the same structure for array elements
- `useAttributeAsKey('name')` - Use a child node's value as the array key
- `requiresAtLeastOneElement()` - Array must contain at least one element
- `addDefaultsIfNotSet()` - Apply child default values automatically
- `normalizeKeys(false)` - Don't normalize dashes to underscores
- `ignoreExtraKeys()` - Allow extra configuration keys
- `acceptAndWrap()` - Auto-wrap scalar values into arrays

### Normalization and Validation

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

Use ExprBuilder for custom validation logic:

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

### Deprecating Options

Mark configuration options as deprecated:

```php
->integerNode('old_option')
    ->setDeprecated('acme/package', '1.2', 'Use "new_option" instead')
->end()
```

### Documenting Options

Add descriptions to configuration options:

```php
->integerNode('entries_per_page')
    ->info('This value is only used for the search results page.')
    ->defaultValue(25)
->end()
```

## Loading Configuration Resources

### FileLocator

Search for configuration files in specified directories:

```php
use Symfony\Component\Config\FileLocator;

$locator = new FileLocator([__DIR__.'/config']);
$files = $locator->locate('users.yaml', null, false);  // false = first match
$allFiles = $locator->locate('*.yaml', null, true);    // true = all matches
```

### Custom Loader Implementation

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

### Loader Resolution

Use `LoaderResolver` and `DelegatingLoader` to automatically select loaders:

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

## Configuration Caching

### ConfigCache Class

Cache processed configuration and track resource modifications:

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

### Constructor Parameters

```php
new ConfigCache($cachePath, $debug = false, $metaPath = null);
```

- `$cachePath` - File path where cache is stored
- `$debug` - When true, creates `.meta` file for resource tracking
- `$metaPath` - Optional absolute path to the meta file

### How Caching Works

1. **Check Freshness** - `isFresh()` examines resource timestamps in `.meta` file
2. **Generate** - If stale, regenerate cache by loading all resources
3. **Store** - Write generated code and resource list via `write()`
4. **Track** - In debug mode, timestamps serialized for future comparisons

## Creating Bundle Configuration

### Modern Approach: AbstractBundle

Define configuration directly in your bundle class:

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

### Traditional Approach: Configuration and Extension Classes

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

### User Configuration

Users configure bundles with friendly syntax:

```yaml
# config/packages/acme_social.yaml
acme_social:
    twitter:
        client_id: 123
        client_secret: your_secret
```

### View Configuration Reference

```bash
php bin/console config:dump-reference acme_social
```

## Loading Service Configuration

### Modern Approach: AbstractBundle.loadExtension()

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

### Traditional Approach: Extension Class

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

## Sharing Configuration Across Bundles

### Using PrependExtensionInterface

Prepend configuration for other bundles before their `load()` method is called:

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

### Key Behaviors

- **User config overrides** - User-defined configuration takes priority over prepended settings
- **First bundle wins** - First registered bundle's prepended value takes priority
- **Compile-time only** - Prepend methods called only during container compilation

## Best Practices

1. **Use AbstractBundle for new bundles** - Simpler API than separate Extension/Configuration classes
2. **Define sensible defaults** - Configure default values for all options
3. **Validate configuration** - Use validation rules to catch configuration errors early
4. **Document options** - Use `info()` to describe what each configuration option does
5. **Implement caching** - Use ConfigCache with proper resource tracking in production
6. **Support multiple formats** - Create loaders for YAML, XML, PHP to maximize flexibility
7. **Use deprecation warnings** - Mark deprecated options to guide users to newer alternatives
8. **Normalize configuration** - Use beforeNormalization() to handle user input variations

## Common Patterns

### Optional Bundle Features

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

### Environment-Specific Configuration

```php
if ($container->getParameter('kernel.environment') === 'dev') {
    $container->prependExtensionConfig('acme_hello', [
        'debug' => true,
        'log_level' => 'debug'
    ]);
}
```

### Merging Configuration from Multiple Files

```php
$processor = new Processor();
$config = new Configuration();

$configs = [
    $this->load('config/defaults.yaml'),
    $this->load('config/custom.yaml'),
];

$processedConfig = $processor->processConfiguration($config, $configs);
```

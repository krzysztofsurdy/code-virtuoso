# Symfony OptionsResolver Component

Provide a robust solution for managing configuration options in your applications. The OptionsResolver component enables creation of flexible option systems with validation, normalization, and dependency management between options.

## Installation

```bash
composer require symfony/options-resolver
```

## Core Classes & Interfaces

### OptionsResolver
Main class for resolving and validating options.

```php
use Symfony\Component\OptionsResolver\OptionsResolver;

$resolver = new OptionsResolver();
```

### Options
Provides access to other options during normalization and default value closures.

```php
use Symfony\Component\OptionsResolver\Options;

function (Options $options, string $value): string {
    // Access $options['key'] to reference other options
}
```

### OptionsResolverIntrospector
Inspect resolver configuration for debugging and introspection.

```php
use Symfony\Component\OptionsResolver\Debug\OptionsResolverIntrospector;

$introspector = new OptionsResolverIntrospector($resolver);
$default = $introspector->getDefault('host');
```

## Essential Methods

### Setting Defaults

Set default values for options:

```php
$resolver->setDefault('host', 'localhost');
$resolver->setDefaults([
    'host' => 'localhost',
    'port' => 25,
    'encryption' => null,
]);
```

Use closures for dynamic defaults dependent on other options:

```php
$resolver->setDefault('port', function (Options $options): int {
    return 'ssl' === $options['encryption'] ? 465 : 25;
});
```

Override default with access to previous value:

```php
$resolver->setDefault('host', function (Options $options, string $previous): string {
    return 'ssl' === $options['encryption'] ? 'secure.example.org' : $previous;
});
```

### Marking Required Options

Define options that must be provided:

```php
$resolver->setRequired('username');
$resolver->setRequired(['username', 'password']);

// Check if option is required
$resolver->isRequired('username');
$resolver->getRequiredOptions();
$resolver->isMissing('username');
$resolver->getMissingOptions();
```

### Type Validation

Validate option types using `setAllowedTypes()`:

```php
$resolver->setAllowedTypes('host', 'string');
$resolver->setAllowedTypes('port', ['null', 'int']);
$resolver->setAllowedTypes('port', 'int|null'); // String syntax

// Array validation
$resolver->setAllowedTypes('dates', 'DateTime[]');
$resolver->setAllowedTypes('ports', 'int[]');
$resolver->setAllowedTypes('endpoints', '(int|string)[]');
```

In subclasses, add types without erasing existing ones:

```php
$resolver->addAllowedTypes('port', 'string');
```

### Value Validation

Restrict options to specific values:

```php
$resolver->setAllowedValues('transport', ['sendmail', 'mail', 'smtp']);

// Using a closure for complex validation
$resolver->setAllowedValues('transport', function (string $value): bool {
    return strlen($value) > 0 && strlen($value) <= 255;
});

// Using Validator component
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validation;

$resolver->setAllowedValues('port', Validation::createIsValidCallable(
    new Assert\Length(['min' => 1, 'max' => 65535])
));
```

Add values in subclasses:

```php
$resolver->addAllowedValues('transport', 'custom-transport');
```

### Option Normalization

Transform option values after validation:

```php
use Symfony\Component\OptionsResolver\Options;

$resolver->setNormalizer('host', function (Options $options, string $value): string {
    if (!str_starts_with($value, 'http')) {
        $value = 'http://' . $value;
    }
    return $value;
});

// Access other options during normalization
$resolver->setNormalizer('host', function (Options $options, string $value): string {
    if (!str_starts_with($value, 'http')) {
        $prefix = 'ssl' === $options['encryption'] ? 'https://' : 'http://';
        $value = $prefix . $value;
    }
    return $value;
});
```

In subclasses, add normalization without replacing parent:

```php
$resolver->addNormalizer('host', function (Options $options, string $value): string {
    return strtolower($value);
});
```

### Options Without Defaults

Define options that only exist if provided:

```php
$resolver->setDefined('port');
$resolver->setDefined(['port', 'encryption']);

// Check if defined
$resolver->isDefined('port');
$resolver->getDefinedOptions();

// Usage in resolved options
if (array_key_exists('port', $resolved)) {
    // Option was provided
}
```

### Nested Options

Define sub-options for complex configurations:

```php
$resolver->setOptions('spool', function (OptionsResolver $spoolResolver): void {
    $spoolResolver->setDefaults([
        'type' => 'file',
        'path' => '/path/to/spool',
    ]);
    $spoolResolver->setAllowedValues('type', ['file', 'memory']);
    $spoolResolver->setAllowedTypes('path', 'string');
});
```

Access parent options during nested configuration:

```php
$resolver->setDefault('sandbox', false);
$resolver->setOptions('spool', function (OptionsResolver $spoolResolver, Options $parent): void {
    $spoolResolver->setDefault('type', $parent['sandbox'] ? 'memory' : 'file');
});
```

Access nested options from parent:

```php
$resolver->setOptions('profiling', function (Options $options): void {
    if ('file' === $options['spool']['type']) {
        // Configure based on nested option
    }
});
```

### Prototype Options

Define repeating option structures using prototypes:

```php
$resolver->setOptions('connections', function (OptionsResolver $connResolver): void {
    $connResolver
        ->setPrototype(true)
        ->setRequired(['host', 'database'])
        ->setDefaults(['user' => 'root', 'password' => null]);
});

// Usage
$resolver->resolve([
    'connections' => [
        'default' => [
            'host' => '127.0.0.1',
            'database' => 'symfony',
        ],
        'test' => [
            'host' => '127.0.0.1',
            'database' => 'symfony_test',
            'user' => 'test',
            'password' => 'test',
        ],
    ],
]);
```

### Deprecating Options

Mark options as deprecated:

```php
$resolver
    ->setDefined(['hostname', 'host'])
    ->setDeprecated('hostname', 'acme/package', '1.2');

// With custom deprecation message
$resolver->setDeprecated(
    'hostname',
    'acme/package',
    '1.2',
    'Use "host" instead of "hostname".'
);
```

Deprecate based on option values using closure:

```php
$resolver
    ->setDefault('encryption', null)
    ->setDefault('port', null)
    ->setAllowedTypes('port', ['null', 'int'])
    ->setDeprecated('port', 'acme/package', '1.2', function (Options $options, ?int $value): string {
        if (null === $value) {
            return 'Passing null to "port" is deprecated.';
        }
        if ('ssl' === $options['encryption'] && 456 !== $value) {
            return 'Non-standard port with "ssl" is deprecated.';
        }
        return '';
    });
```

### Ignoring Undefined Options

Allow undefined options instead of throwing exception:

```php
$resolver
    ->setDefined(['hostname'])
    ->setIgnoreUndefined(true);

// Undefined options are silently ignored
$resolved = $resolver->resolve([
    'hostname' => 'example.com',
    'unknown'  => 'value', // Not included in result
]);
```

### Chainable Configuration (define Method)

Use `define()` for fluent, readable configuration:

```php
$resolver->define('host')
    ->required()
    ->default('smtp.example.org')
    ->allowedTypes('string')
    ->info('SMTP server hostname or IP address');

$resolver->define('transport')
    ->default('sendmail')
    ->allowedValues('sendmail', 'mail', 'smtp')
    ->info('Transport mechanism for sending mail');

$resolver->define('port')
    ->default(25)
    ->allowedTypes('int')
    ->allowedValues(function (int $value): bool {
        return $value > 0 && $value < 65536;
    });
```

### Resolving Options

Resolve and validate user-provided options:

```php
$options = $resolver->resolve([
    'host' => 'mail.example.com',
    'port' => 587,
]);

// Returns array with defaults merged and validation applied
// Throws InvalidOptionsException if validation fails
// Throws MissingOptionsException if required options missing
```

## Common Use Cases

### Creating Flexible APIs

```php
class EmailSender
{
    protected array $options;

    public function __construct(array $options = [])
    {
        $resolver = new OptionsResolver();
        $this->configureOptions($resolver);
        $this->options = $resolver->resolve($options);
    }

    protected function configureOptions(OptionsResolver $resolver): void
    {
        $resolver
            ->setDefaults([
                'host' => 'localhost',
                'port' => 25,
                'username' => null,
                'password' => null,
                'encryption' => null,
            ])
            ->setRequired(['host'])
            ->setAllowedTypes('port', 'int')
            ->setAllowedValues('encryption', [null, 'ssl', 'tls']);
    }
}
```

### Subclass Configuration Extension

```php
class SecureEmailSender extends EmailSender
{
    protected function configureOptions(OptionsResolver $resolver): void
    {
        parent::configureOptions($resolver);

        $resolver
            ->setDefault('encryption', 'tls')
            ->setDefault('port', 587)
            ->setRequired(['username', 'password']);
    }
}
```

### Performance-Optimized Configuration

```php
class MailerFactory
{
    private static array $resolvers = [];

    public static function createMailer(array $options): Mailer
    {
        $class = Mailer::class;

        if (!isset(self::$resolvers[$class])) {
            self::$resolvers[$class] = new OptionsResolver();
            // Configure resolver once
            $mailer = new Mailer([]);
            $mailer->configureOptions(self::$resolvers[$class]);
        }

        return new Mailer(self::$resolvers[$class]->resolve($options));
    }
}
```

### Inspecting Configuration

```php
use Symfony\Component\OptionsResolver\Debug\OptionsResolverIntrospector;

$resolver = new OptionsResolver();
$resolver->setDefaults(['host' => 'localhost', 'port' => 25]);

$introspector = new OptionsResolverIntrospector($resolver);
$default = $introspector->getDefault('host'); // 'localhost'
```

## Best Practices

1. Extract configuration into dedicated methods for maintainability.
2. Use closures for dynamic defaults instead of pre-computing values.
3. Cache resolvers when creating many instances with same configuration.
4. Always type-hint closure parameters for proper recognition.
5. Use `define()` for cleaner, more readable configuration setup.
6. Allow subclass customization by extracting configuration to protected methods.
7. Document default values and allowed values for API clarity.
8. Use nested options for complex configurations with many related settings.
9. Mark deprecated options early to guide users to alternatives.
10. Combine type and value validation for maximum option safety.

## Exception Handling

- `InvalidOptionsException`: Thrown when invalid options provided.
- `MissingOptionsException`: Thrown when required options missing.
- `UndefinedOptionsException`: Thrown when undefined options provided (unless `setIgnoreUndefined()` used).

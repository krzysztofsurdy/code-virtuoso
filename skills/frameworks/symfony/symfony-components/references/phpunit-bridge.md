# Symfony PHPUnit Bridge

The PHPUnit Bridge adds utilities for testing Symfony applications and components: deprecation reporting, mocking of system functions, and test execution across multiple PHPUnit versions.

## Contents

- [Installation](#installation)
- [Quick start](#quick-start)
- [Core features](#core-features)
- [Mark tests as legacy](#mark-tests-as-legacy)
- [Time-sensitive tests](#time-sensitive-tests)
- [DNS-sensitive tests](#dns-sensitive-tests)
- [Class existence based tests](#class-existence-based-tests)
- [Configuration](#configuration)
- [Parallel test execution](#parallel-test-execution)
- [Code coverage listener](#code-coverage-listener)
- [Multi-PHPUnit version support](#multi-phpunit-version-support)
- [Common patterns](#common-patterns)
- [Best practices](#best-practices)

## Installation

```bash
composer require --dev symfony/phpunit-bridge
```

## Quick start

Run tests with the enhanced PHPUnit wrapper:

```bash
./vendor/bin/simple-phpunit
```

## Core features

### Consistent testing environment

Sets up a standard test environment:

- Default locale set to `C` for all tests
- Class existence checks auto-registered for Doctrine annotations

### Deprecation reporting

Track deprecated code usage across your test suite:

```
Remaining deprecation notices (2)

getEntityManager is deprecated since Symfony 2.1. Use getManager instead: 2x
  1x in DefaultControllerTest::testPublicUrls
  1x in BlogControllerTest::testIndex
```

Configure deprecation behavior with environment variables:

```bash
# Set maximum allowed deprecations
SYMFONY_DEPRECATIONS_HELPER='max[total]=320' ./vendor/bin/simple-phpunit

# Control by deprecation type
SYMFONY_DEPRECATIONS_HELPER='max[total]=42&max[self]=0&max[direct]=5' ./vendor/bin/simple-phpunit

# Disable verbose output
SYMFONY_DEPRECATIONS_HELPER='verbose=0' ./vendor/bin/simple-phpunit

# Log deprecations to file
SYMFONY_DEPRECATIONS_HELPER='logFile=/path/deprecations.log' ./vendor/bin/simple-phpunit

# Ignore specific deprecations
SYMFONY_DEPRECATIONS_HELPER='ignoreFile=./tests/baseline-ignore' ./vendor/bin/simple-phpunit

# Generate and use baseline
SYMFONY_DEPRECATIONS_HELPER='generateBaseline=true&baselineFile=./tests/allowed.json' ./vendor/bin/simple-phpunit
SYMFONY_DEPRECATIONS_HELPER='baselineFile=./tests/allowed.json' ./vendor/bin/simple-phpunit
```

**Deprecation Types:**
- `max[total]` - Total deprecations allowed
- `max[self]` - Deprecations from your code only
- `max[direct]` - Direct dependency deprecations
- `max[indirect]` - Indirect dependency deprecations

### Trigger deprecation notices

Emit deprecation notices in your code:

```php
use Symfony\Contracts\Service\Attribute\SubscribedService;

trigger_deprecation('vendor-name/package-name', '1.3', 'Your deprecation message');
trigger_deprecation('vendor-name/package-name', '1.3', 'Value "%s" is deprecated.', $value);
```

### Assert on deprecations

Test that deprecated code triggers expected notices:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Bridge\PhpUnit\ExpectDeprecationTrait;

class MyTest extends TestCase
{
    use ExpectDeprecationTrait;

    /**
     * @group legacy
     */
    public function testDeprecatedCode(): void
    {
        $this->expectDeprecation('Since vendor-name/package-name 5.1: This "%s" method is deprecated');

        // code that triggers deprecation
    }
}
```

## Mark tests as legacy

Indicate that tests validate legacy functionality using any of these methods:

### Annotation
```php
/**
 * @group legacy
 */
class MyTest extends TestCase { }
```

### Class name prefix
```php
class LegacyMyTest extends TestCase { }
```

### Method name prefix
```php
public function testLegacyFeature() { }
```

## Time-sensitive tests

Mock time functions to make tests deterministic and prevent flakiness:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Bridge\PhpUnit\Attribute\TimeSensitive;
use Symfony\Component\Stopwatch\Stopwatch;

#[TimeSensitive]
class MyTest extends TestCase
{
    public function testElapsedTime(): void
    {
        $stopwatch = new Stopwatch();
        $stopwatch->start('event_name');
        sleep(10);
        $duration = $stopwatch->stop('event_name')->getDuration();

        $this->assertEquals(10000, $duration); // Instant execution
    }
}
```

### Mocked functions

Time advances instantly without actual delays:

- `time()`, `microtime()`, `sleep()`, `usleep()`
- `gmdate()`, `date()`, `hrtime()`, `strtotime()`

### Manual registration

For older PHPUnit versions or specific namespaces:

```php
use Symfony\Bridge\PhpUnit\ClockMock;

ClockMock::register(__CLASS__);
ClockMock::withClockMock(true);
// test code
ClockMock::withClockMock(false);
```

### PHPUnit 10+ configuration

```xml
<extensions>
    <bootstrap class="Symfony\Bridge\PhpUnit\SymfonyExtension">
        <parameter name="clock-mock-namespaces" value="App\Util,App\Service"/>
    </bootstrap>
</extensions>
```

### Legacy PHPUnit configuration

```xml
<listeners>
    <listener class="\Symfony\Bridge\PhpUnit\SymfonyTestsListener"/>
</listeners>
```

## DNS-sensitive tests

Mock DNS lookups to avoid network calls and keep tests reliable:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Bridge\PhpUnit\Attribute\DnsSensitive;
use Symfony\Bridge\PhpUnit\DnsMock;

#[DnsSensitive]
class DomainValidatorTest extends TestCase
{
    public function testEmailValidationWithMockedDns(): void
    {
        DnsMock::withMockedHosts([
            'example.com' => [
                ['type' => 'A', 'ip' => '1.2.3.4'],
                ['type' => 'AAAA', 'ipv6' => '::12'],
            ],
            'invalid.test' => false,
        ]);

        $validator = new DomainValidator(['checkDnsRecord' => true]);
        $this->assertTrue($validator->validate('example.com'));
        $this->assertFalse($validator->validate('invalid.test'));
    }
}
```

### Mocked functions

- `checkdnsrr()`, `dns_check_record()`
- `getmxrr()`, `dns_get_mx()`
- `gethostbyaddr()`, `gethostbyname()`, `gethostbynamel()`
- `dns_get_record()`

### PHPUnit 10+ configuration

```xml
<extensions>
    <bootstrap class="Symfony\Bridge\PhpUnit\SymfonyExtension">
        <parameter name="dns-mock-namespaces" value="App\Validator"/>
    </bootstrap>
</extensions>
```

## Class existence based tests

Mock class/interface/trait/enum existence checks:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Bridge\PhpUnit\ClassExistsMock;

class MyClassTest extends TestCase
{
    public function testHelloWithoutDependency(): void
    {
        ClassExistsMock::register(MyClass::class);
        ClassExistsMock::withMockedClasses([DependencyClass::class => false]);

        $class = new MyClass();
        $result = $class->hello();

        $this->assertSame('The default behavior.', $result);
    }
}
```

### Mock enumerations

```php
ClassExistsMock::withMockedEnums([EnumClass::class => true]);
```

### Mocked functions

- `class_exists()`, `interface_exists()`, `trait_exists()`, `enum_exists()`

## Configuration

### Environment variables

| Variable | Purpose |
|----------|---------|
| `SYMFONY_DEPRECATIONS_HELPER` | Control deprecation behavior and reporting |
| `SYMFONY_PHPUNIT_LOCALE` | Set test locale (default: `C`) |
| `SYMFONY_PHPUNIT_VERSION` | Specify PHPUnit version |
| `SYMFONY_PHPUNIT_MAX_DEPTH` | Depth for parallel test scanning (default: 3) |
| `SYMFONY_PHPUNIT_REMOVE_RETURN_TYPEHINT` | Remove void return types for legacy PHP |
| `SYMFONY_PHPUNIT_SKIPPED_TESTS` | File for storing and replaying skipped tests |

### Namespace detection

The bridge automatically detects tested class namespaces:

- Test class: `App\Tests\Watch\DummyWatchTest`
- Tested class namespace: `App\Watch` (removes `Tests\` prefix)

Override in `phpunit.xml`:

```xml
<listeners>
    <listener class="Symfony\Bridge\PhpUnit\SymfonyTestsListener">
        <arguments>
            <array>
                <element key="time-sensitive"><string>Symfony\Component\HttpFoundation</string></element>
            </array>
        </arguments>
    </listener>
</listeners>
```

Or in bootstrap file:

```php
// config/bootstrap.php
use Symfony\Bridge\PhpUnit\ClockMock;

if ('test' === $_SERVER['APP_ENV']) {
    ClockMock::register('Acme\\MyClass\\');
}
```

## Parallel test execution

Execute tests in parallel by organizing them into separate test suites:

```
tests/
├── Functional/
│   └── phpunit.xml.dist
└── Unit/
    └── phpunit.xml.dist
```

```bash
./vendor/bin/simple-phpunit tests/
```

## Code coverage listener

Adds `@covers` annotations automatically to improve coverage accuracy:

```xml
<listeners>
    <listener class="Symfony\Bridge\PhpUnit\CoverageListener"/>
</listeners>
```

### Custom system under test solver

```xml
<listeners>
    <listener class="Symfony\Bridge\PhpUnit\CoverageListener">
        <arguments>
            <string>My\Namespace\SutSolver::solve</string>
        </arguments>
    </listener>
</listeners>
```

### Enable coverage warnings

```xml
<listeners>
    <listener class="Symfony\Bridge\PhpUnit\CoverageListener">
        <arguments>
            <null/>
            <boolean>true</boolean>
        </arguments>
    </listener>
</listeners>
```

## Multi-PHPUnit version support

Use a single test suite across multiple PHPUnit versions:

### Automatic polyfills

The bridge provides polyfills for:

- `expectException()`, `expectExceptionCode()`, `expectExceptionMessage()`
- `assertContainsEquals()`, `assertDoesNotContainEquals()`
- Namespaced test case aliases
- Other version-specific methods

### Remove void return types

For compatibility with older PHP versions:

```bash
SYMFONY_PHPUNIT_REMOVE_RETURN_TYPEHINT=1 ./vendor/bin/simple-phpunit
```

### Namespace compatibility

Use `PHPUnit\Framework\TestCase` in all versions; the bridge provides automatic aliases.

## Common patterns

### Skip tests based on optional dependencies

```php
class MyTest extends TestCase
{
    protected function setUp(): void
    {
        if (!class_exists('Optional\Dependency')) {
            $this->markTestSkipped('Optional dependency not available');
        }
    }
}
```

### Test with different locales

```php
class LocaleAwareTest extends TestCase
{
    /**
     * @dataProvider provideLocales
     */
    public function testFormatting(string $locale): void
    {
        putenv("LC_ALL=$locale");
        // assertions
    }

    public function provideLocales(): array
    {
        return [['C'], ['en_US.UTF-8'], ['fr_FR.UTF-8']];
    }
}
```

### Assert environment isolation

```php
class EnvironmentTest extends TestCase
{
    public function testLocaleIsC(): void
    {
        $this->assertSame('C', setlocale(LC_ALL, 0));
    }
}
```

## Best practices

1. Use `@group legacy` annotation to mark tests for deprecated features
2. Set reasonable deprecation limits with `SYMFONY_DEPRECATIONS_HELPER`
3. Use baseline files to manage known deprecations
4. Mock time and DNS for deterministic tests
5. Enable code coverage listener for accurate coverage metrics
6. Keep test namespaces mirrored to source code structure
7. Use attributes over docblock annotations (PHPUnit 10+)

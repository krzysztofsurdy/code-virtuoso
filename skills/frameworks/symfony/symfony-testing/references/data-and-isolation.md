# Data and isolation

## Contents

- [What each tool does](#what-each-tool-does)
- [Setup](#setup)
- [Foundry v2 habits](#foundry-v2-habits)
- [Stories and global state](#stories-and-global-state)
- [Factories in data providers](#factories-in-data-providers)
- [DAMA limits](#dama-limits)
- [Parallel runs and speed](#parallel-runs-and-speed)

## What each tool does

| Tool | Job | Does not do |
|---|---|---|
| Foundry factories | Build entities with random defaults and persist them | Roll back anything |
| `#[ResetDatabase]` (Foundry) | Drop and create the test database before the first test, then reset the schema before each test | Run per test when DAMA is active (it resets once per suite) |
| DAMA doctrine-test-bundle | Wrap each test in a transaction and roll it back | Create the schema or load data |
| Doctrine fixtures bundle | Load a fixed data set for dev or test | Isolate tests |

Use the pair: Foundry builds data and creates the schema, DAMA makes each test cheap and isolated. With DAMA active, Foundry detects it and skips the per-test schema reset.

## Setup

Install both as dev dependencies, then check what Flex did. In a non-interactive `composer require`, Flex registered the Foundry bundle and `FoundryExtension` but not DAMA, so verify both entries yourself.

```php
// config/bundles.php
DAMA\DoctrineTestBundle\DAMADoctrineTestBundle::class => ['test' => true],
```

```xml
<!-- phpunit.dist.xml -->
<extensions>
    <bootstrap class="DAMA\DoctrineTestBundle\PHPUnit\PHPUnitExtension"/>
    <bootstrap class="Zenstruck\Foundry\PHPUnit\FoundryExtension"/>
</extensions>
```

On DBAL below 4, add `use_savepoints: true` to every connection that DAMA wraps.

Point the test database away from dev in `.env.test` or `.env.test.local`. The `when@test` Doctrine config from the recipe adds a `_test` suffix to the database name and appends `TEST_TOKEN` for parallel runners.

Each test class that persists Foundry objects needs `#[ResetDatabase]`, or enable it for every `KernelTestCase` subclass:

```xml
<bootstrap class="Zenstruck\Foundry\PHPUnit\FoundryExtension">
    <parameter name="enabled-auto-reset" value="true"/>
</bootstrap>
```

Without a reset, the first factory call fails with "no such table" on a fresh test database. Without DAMA or a reset, rows from one test and from earlier runs show up in later tests.

## Foundry v2 habits

- A factory extends `PersistentObjectFactory`, names its entity in `class()` and returns defaults from `defaults()`. Put only required and unique fields in defaults and override the field the test is about: `PostFactory::createOne(['slug' => 'post-a'])`.
- Express variations as named methods on the factory (`published()`), not as long override arrays in each test.
- Foundry v1 names (`getDefaults()`, the `Factories` and `ResetDatabase` traits, `->object()`, `Proxy`) appear in older posts and in some official pages. Do not mix them in. The traits are the PHPUnit 9 route in v2.
- Proxies are deprecated since Foundry 2.7. Auto-refresh replaces them and needs PHP 8.4, which Symfony 8 already requires. On PHP below 8.4, keep the proxy factory until you upgrade.
- Arrange with factories, act through the client, assert with `PostFactory::assert()` or the repository.
- A factory in `tests/Factory` that takes injected services must be registered as a service. The Foundry docs show the config, because `make:factory --test` runs in the dev environment.

## Stories and global state

A story builds a database state that several tests need (`PostStory::load()`). `load()` runs once and objects it creates are cleared after each test unless the story is global state. Use a story when the arrange step is long or repeated. Use a plain factory call when one test needs one entity.

Global state loads a story before each reset (once per suite when DAMA is active). It makes every test depend on that data, so keep it for reference data such as roles and countries, and keep it small.

## Factories in data providers

Providers run before the kernel exists. With the Foundry extension and PHPUnit 11.4 or later, a provider can yield `PostFactory::createOne()` and receive a lazy object. Do not read properties or call methods on it inside the provider, because that would persist too early. Without the extension, a provider may only return factory instances, not created objects. Providers are `public static` either way.

## DAMA limits

- It wraps one PHP process. A Panther or Selenium browser talks to the app through a separate server process, so rollback does not cover those writes. This is inferred from the DAMA README (it states Behat with Selenium cannot work) and the Panther docs (the app runs on a built-in web server). Reset the data with Foundry for such tests.
- DDL statements that commit implicitly, such as `ALTER TABLE`, break the rollback. On MySQL the symptom is a "SAVEPOINT does not exist" error.
- A transaction your code opens and never closes goes unnoticed, because everything is rolled back at the end. The extension reports a warning for it. Use `failOnWarning="true"` to fail on it, which the Flex recipe already sets.
- `#[SkipDatabaseRollback]` on a class or method turns it off when a test needs real commits.
- To inspect the data of a failing test, call `StaticDriver::commit()` in the test before it stops. The README documents this for debugging.

## Parallel runs and speed

- With paratest, give each process its own database: the Doctrine `when@test` block with `dbname_suffix: '_test%env(default::TEST_TOKEN)%'` does it.
- `APP_DEBUG=0` in `.env.test` speeds tests up. Clear `var/cache/test` in `tests/bootstrap.php` so a stale cache is not reused.
- Lower the password hasher cost for the test environment, or pre-hash a known password in the user factory.

# PHPStan

## Contents

- [Levels](#levels)
- [Minimal config](#minimal-config)
- [Choosing and raising the level](#choosing-and-raising-the-level)
- [Baseline commands](#baseline-commands)
- [Ignoring errors](#ignoring-errors)
- [Bleeding edge](#bleeding-edge)
- [Extensions](#extensions)
- [Generics in PHPDoc](#generics-in-phpdoc)
- [Sources](#sources)

## Levels

Levels are cumulative: each one keeps the checks of the levels below it. Source: https://phpstan.org/user-guide/rule-levels

| Level | Adds |
|---|---|
| 0 | Unknown classes, functions and methods on `$this`, wrong argument counts, always-undefined variables |
| 1 | Possibly undefined variables, unknown magic methods and properties on classes with `__call` and `__get` |
| 2 | Unknown methods on all expressions, PHPDoc validation |
| 3 | Return types and property assignment types |
| 4 | Basic dead code: always-false `instanceof`, dead `else`, unreachable code |
| 5 | Argument types passed to methods and functions |
| 6 | Missing type hints |
| 7 | Partially wrong union types |
| 8 | Method calls and property access on nullable types |
| 9 | Strict handling of explicit `mixed` |
| 10 | Strict handling of implicit `mixed` too (new in 2.0) |

The default level is 0, and a config file must name a level unless `customRulesetUsed` is set.

## Minimal config

```neon
includes:
    - phpstan-baseline.neon

parameters:
    level: 10
    paths:
        - src
        - tests
    tmpDir: var/cache/phpstan
```

Run it with `vendor/bin/phpstan analyse`. Keep `tmpDir` outside version control and cache it in CI. `tmpDir` is resolved relative to the config file (https://phpstan.org/config-reference).

## Choosing and raising the level

1. Run at level 0 and note the error count, then run at the level you want.
2. If the target level reports a few dozen to a few hundred errors, fix what is cheap and baseline the rest.
3. If it reports thousands, choose a lower level. The docs say a baseline is not the right tool at 15,000 errors.
4. Raise the level one step at a time in separate pull requests so each diff stays reviewable.
5. Write a number in the config. `--level max` always means the highest level, so a PHPStan upgrade that adds a level changes your result.

Level 10 differs from 9 mostly through code with missing types: untyped dependencies, array shapes without PHPDoc, and framework return values. Fix those with extensions, generics and PHPDoc rather than with casts.

`treatPhpDocTypesAsCertain` defaults to `true`, so PHPStan trusts PHPDoc types like native ones. Set it to `false` only for a library that untrusted callers use (https://phpstan.org/config-reference).

## Baseline commands

| Goal | Command or setting |
|---|---|
| Create a baseline | `vendor/bin/phpstan analyse --generate-baseline` (writes `phpstan-baseline.neon`) |
| Different file name | `--generate-baseline baseline.neon`. A `.php` name writes PHP instead of NEON, which helps with very large baselines |
| Use it | `includes: - phpstan-baseline.neon` |
| Find obsolete entries | Keep `reportUnmatchedIgnoredErrors` on. PHPStan reports entries that match nothing |
| Shrink it | Fix errors, delete the entries PHPStan flags, or regenerate on a clean branch and check the diff is deletions only |

The baseline stores a message pattern, a count and a path per entry (PHPStan 2.3.1 also writes the error `identifier`). It has no line numbers and no comments, so an error you mean to keep belongs in an inline `@phpstan-ignore` with a reason. The PHPStan docs state that the life goal of a baseline is to not exist. Sources: https://phpstan.org/user-guide/baseline, https://phpstan.org/blog/phpstans-baseline-feature-lets-you-hold-new-code-to-a-higher-standard

Policy for a team: generate once, shrink, never grow. Enforce it in CI by comparing the baseline's line count with the main branch. That check is a convention you add, PHPStan does not provide it.

## Ignoring errors

| Need | Use |
|---|---|
| One error on one line | `// @phpstan-ignore argument.type (legacy API returns int)` |
| Several identifiers | Separate with commas inside one comment |
| A whole class of error in a path | `ignoreErrors` with `identifier` and `path` in the config |
| A line with unknown error | Run the default `table` output, it prints the identifier next to each error |

Every error carries an identifier. Ignoring by identifier means the comment cannot hide a different error that appears on the same line later. `@phpstan-ignore-line` and `@phpstan-ignore-next-line` still work but take no identifier, and `reportIgnoresWithoutComments: true` forbids them. Source: https://phpstan.org/user-guide/ignoring-errors

## Bleeding edge

```neon
includes:
    - phar://phpstan.phar/conf/bleedingEdge.neon
```

Bleeding edge turns on rules and behavior that are off by default in the current major and become default in the next one. They ship in minor releases, so a minor update can add errors. Use it on projects that handle that, and read the release notes. The file `conf/bleedingEdge.neon` in the PHPStan source lists what it enables. Some config options in the reference state they need bleeding edge until PHPStan 3.0. Sources: https://phpstan.org/blog/what-is-bleeding-edge, https://phpstan.org/config-reference

Before the 1.x to 2.x move the upgrade guide advised enabling bleeding edge on the last 1.12 release to see the 2.0 defaults early (https://phpstan.org/blog/upgrading-from-phpstan-1-to-2).

## Extensions

Install `phpstan/extension-installer` and then require the extensions you need. Without the installer, add each extension's `.neon` file to `includes` by hand. Source: https://phpstan.org/user-guide/extension-library

| Package | Adds | Config worth knowing |
|---|---|---|
| `phpstan/phpstan-symfony` | Container service types, console input types, form and request helpers | `parameters.symfony.containerXmlPath` (the dumped container XML), `parameters.symfony.consoleApplicationLoader` |
| `phpstan/phpstan-doctrine` | Repository and query result types, DQL checks | `parameters.doctrine.objectManagerLoader` enables DQL validation, with `rules.neon` included |
| `phpstan/phpstan-phpunit` | Mock and assertion types | None needed to start |
| `phpstan/phpstan-strict-rules` | Extra strict rules such as no loose comparison and no `empty()` | `parameters.strictRules.allRules: false` turns them all off so you can enable one by one |
| `phpstan/phpstan-deprecation-rules` | Reports use of deprecated code | None |

Sources: https://github.com/phpstan/phpstan-symfony, https://github.com/phpstan/phpstan-doctrine, https://github.com/phpstan/phpstan-strict-rules

Notes:

- phpstan-symfony 2.x dropped underscore option names. Use `containerXmlPath`, `constantHassers` and `consoleApplicationLoader` (https://phpstan.org/blog/upgrading-from-phpstan-1-to-2).
- The container XML must exist before analysis, since the extension reads it. In CI warm the cache of the environment you point at before running PHPStan.
- phpstan-strict-rules also changes defaults of some core parameters, even with `allRules: false`.

## Generics in PHPDoc

PHPStan reads generics from PHPDoc, since PHP has none. Source: https://phpstan.org/blog/generics-in-php-using-phpdocs

| Tag | Meaning |
|---|---|
| `@template T` | Declares a type variable. `@template T of \Exception` bounds it, `@template T = string` sets a default |
| `@template-covariant T` | Lets `Collection<Dog>` pass where `Collection<Animal>` is expected |
| `@extends Parent<Foo>`, `@implements Iface<Foo>`, `@use Trait<Foo>` | Fix the type arguments of the parent, interface or trait |
| `class-string<T>` | Take a class name and infer `T` from it |

```php
/**
 * @template T of object
 * @param class-string<T> $className
 * @return T|null
 */
public function find(string $className, int $id): ?object

/** @implements \IteratorAggregate<int, Invoice> */
final class InvoiceList implements \IteratorAggregate
```

Repeat `@template` on a child class to keep it generic. A missing generic on a collection or repository is the usual reason a value becomes `mixed` at level 10.

## Sources

| Fact | URL |
|---|---|
| Levels, level 10 new in 2.0 | https://phpstan.org/user-guide/rule-levels |
| 2.0 release, level 10 | https://phpstan.org/blog/phpstan-2-0-released-level-10-elephpants |
| Upgrade 1.x to 2.x, PHP 7.4+ to run | https://phpstan.org/blog/upgrading-from-phpstan-1-to-2 |
| Baseline | https://phpstan.org/user-guide/baseline |
| Config reference | https://phpstan.org/config-reference |
| Releases | https://github.com/phpstan/phpstan/releases |

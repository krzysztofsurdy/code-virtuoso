# Rector for quality

Rector upgrades code to a new PHP version and also improves code that already runs on the right version. Upgrades are covered by the `php-upgrade` skill (`withPhpSets`, `withPhpLevel`). This file covers the quality side only.

## Contents

- [Level methods](#level-methods)
- [Prepared sets](#prepared-sets)
- [Workflow](#workflow)
- [Ordering with the formatter and PHPStan](#ordering-with-the-formatter-and-phpstan)
- [Sources](#sources)

## Level methods

A level is the first N rules of a set, sorted from the safest to the most complex. Start each at 0 and raise by one per pull request. When the level reaches the end of the set, it equals the whole set. Source: https://getrector.com/documentation/levels

| Method | Improves |
|---|---|
| `withTypeCoverageLevel(int)` | Native type declarations (parameters, returns, properties) |
| `withTypeCoverageDocblockLevel(int)` | Docblock `@param`, `@return` and `@var` types where native types are not possible (since Rector 2.2) |
| `withDeadCodeLevel(int)` | Dead code removal |
| `withCodeQualityLevel(int)` | Simplifications, early returns and instanceof cleanups |
| `withCodingStyleLevel(int)` | Style rules that a formatter would also touch |

```php
<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withTypeCoverageLevel(0)
    ->withTypeCoverageDocblockLevel(0)
    ->withDeadCodeLevel(0)
    ->withCodeQualityLevel(0);
```

Raise type coverage first. It reduces the missing-type errors PHPStan reports from level 6, and the Rector page suggests tackling dead code, quality and style once type coverage is high.

## Prepared sets

`withPreparedSets()` enables whole sets with named booleans (source: `RectorConfigBuilder.php` in https://github.com/rectorphp/rector-src).

| Argument | Notes |
|---|---|
| `deadCode`, `codeQuality`, `codingStyle`, `typeDeclarations`, `typeDeclarationDocblocks`, `privatization`, `namedArgs` | Whole-set versions of the level methods |
| `phpunitCodeQuality`, `phpunitNarrowAsserts`, `phpunitMockToStub` | PHPUnit test improvements |
| `doctrineCodeQuality`, `symfonyCodeQuality`, `symfonyConfigs` | Framework sets |
| `naming` | Deprecated |
| `instanceOf`, `if`, `earlyReturn` | Deprecated. The rules moved into `codeQuality` and `codingStyle` |

Whole sets suit a new project or a small codebase. On a large codebase they produce one diff nobody can review, so use levels there.

## Workflow

1. Commit a clean state with tests passing.
2. Raise one level by one step.
3. Run `vendor/bin/rector process --dry-run` and read the diff.
4. Apply with `vendor/bin/rector process`, run the tests and PHPStan, and open a pull request.
5. Repeat. Keep Rector changes in their own commits, apart from manual fixes.

Skip rules that conflict with your intent with `withSkip([...])` and a comment on why, instead of turning a whole level off.

## Ordering with the formatter and PHPStan

- Rector rewrites code and the formatter normalizes its layout, so run Rector first and the formatter last. This ordering is a recommendation, not a documented rule.
- Do not enable `withCodingStyleLevel` and a formatter that owns the same rules, for example PHP-CS-Fixer with `@PER-CS3x0`. Let one tool own style.
- Rector 2.7.0 requires `phpstan/phpstan` ^2.3.0, so the two share an installation. Rector is built on PHPStan, so update them together.

## Sources

| Fact | URL |
|---|---|
| Levels | https://getrector.com/documentation/levels |
| Config builder methods | https://github.com/rectorphp/rector-src/blob/main/src/Configuration/RectorConfigBuilder.php |
| Release and requirements | https://github.com/rectorphp/rector/releases |

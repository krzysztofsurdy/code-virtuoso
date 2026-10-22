# Code style

## Contents

- [PER-CS and PSR-12](#per-cs-and-psr-12)
- [What PER-CS added by version](#what-per-cs-added-by-version)
- [PHP-CS-Fixer setup](#php-cs-fixer-setup)
- [PHP_CodeSniffer](#php_codesniffer)
- [Choosing and CI](#choosing-and-ci)
- [Sources](#sources)

## PER-CS and PSR-12

| Item | Fact |
|---|---|
| PSR-12 | Extended Coding Style Guide. The PHP-FIG index still lists it as Accepted. PER-CS says it was accepted in 2019 |
| PER Coding Style | A PER, which is a document with numbered releases that evolves, as opposed to a PSR that is frozen once accepted. Current release is 3.1 |
| Relation | PER-CS "extends, expands and replaces" PSR-12 and requires PSR-1. The PER makes PSR-12 errata binding |
| PSR-2 | Deprecated. PSR-12 replaced it |
| Version 1.0 | Direct equivalent of PSR-12 with very minor changes |

Say "PER-CS" in new project rules, and name the revision the tooling enforces, for example PER-CS 3.0 via `@PER-CS3x0`. Sources: https://www.php-fig.org/per/coding-style/, https://www.php-fig.org/psr/psr-12/, https://www.php-fig.org/psr/

## What PER-CS added by version

Source for all rows: the migration documents at https://www.php-fig.org/per/coding-style/meta/migration-2.0, migration-3.0 and migration-3.1.

| Version | Notable changes |
|---|---|
| 2.0 | Optional trailing commas (required when the last item is on its own line), `{}` for empty class and method bodies, modifier keyword rules |
| 3.0 | Formatting for union and intersection types (no spaces around `\|` and `&`, `null` last, prefer `?T`), naming advice for acronyms, lowercase `<?php`, drop parentheses around `new` when targeting 8.4 or later, set-visibility rule |
| 3.1 | `clone()` always with parentheses, expanded `switch` and `case` rules, pipe operator spacing and line breaks, empty closure rule (prefer arrow functions) |

The full text also covers enums, attributes, property hooks and readonly classes. Read the spec page for the exact rule.

## PHP-CS-Fixer setup

Current rule sets (https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/tree/master/doc/ruleSets):

| Rule set | Meaning |
|---|---|
| `@PER-CS3x0` | PER-CS 3.0 rules. Stable until you change it |
| `@PER-CS3x0:risky` | Risky rules for the same revision. Needs `setRiskyAllowed(true)` |
| `@PER-CS` | Alias for the latest revision. Moves when a new revision lands |
| `@PER-CS3.0`, `@PER` | Deprecated, removed in the next major version |
| `@Symfony` | Symfony coding standard, extends `@PER-CS` |
| `@PSR12` | Older style. The default when no config file exists |
| `@PHP8x5Migration` and siblings | Syntax migration rules. These belong to an upgrade, see `php-upgrade` |

No rule set for PER-CS 3.1 was listed when this skill was written. Check the directory before claiming 3.1 is enforced.

```php
<?php

declare(strict_types=1);

use PhpCsFixer\Config;
use PhpCsFixer\Finder;

$finder = (new Finder())->in([__DIR__ . '/src', __DIR__ . '/tests']);

return (new Config())
    ->setRiskyAllowed(true)
    ->setRules([
        '@PER-CS3x0' => true,
        '@PER-CS3x0:risky' => true,
    ])
    ->setFinder($finder);
```

Commands (https://cs.symfony.com/doc/usage.html):

| Goal | Command |
|---|---|
| Report without changing | `vendor/bin/php-cs-fixer check --diff` (`check` is shorthand for `fix --dry-run`) |
| Fix | `vendor/bin/php-cs-fixer fix` |
| Override risky setting | `--allow-risky=yes` or `no` |

Risky rules can change what the code does, and PHP-CS-Fixer never runs them unless you allow it. Review their diff separately from the formatting diff, and commit the first PER-CS run as its own formatting-only commit. PHP-CS-Fixer supports PHP 7.4 to 8.5 per its README. For a newer PHP version, the tool may not parse the syntax yet (`--allow-unsupported-php-version=yes` runs it at your own risk).

## PHP_CodeSniffer

| Fact | Detail |
|---|---|
| Maintainer | The `squizlabs/PHP_CodeSniffer` repository is abandoned. Use `PHPCSStandards/PHP_CodeSniffer` |
| Version | 4.0.0 shipped on 2025-09-16. Check the releases page for the current patch |
| Bundled standards | Generic, PEAR, PSR1, PSR12, PSR2, Squiz, Zend. No PER standard in core |
| PER-CS 3.0 ruleset | A pull request was opened and closed without merge, so do not assume `--standard=PER` works |
| Fixing | `phpcbf` fixes a subset of violations, `phpcs` reports |

Use PHPCS when the team already has custom sniffs or a shared ruleset, and keep it as the only formatter. For PER-CS enforcement on its own, PHP-CS-Fixer is the tool with rule sets. Sources: https://github.com/PHPCSStandards/PHP_CodeSniffer, https://github.com/squizlabs/PHP_CodeSniffer

## Choosing and CI

| Situation | Choice |
|---|---|
| New project | PHP-CS-Fixer, `@PER-CS3x0`, `check --diff` in CI, `fix` in a pre-commit hook or editor |
| Existing PSR-12 on PHPCS | Keep PHPCS and move later in a dedicated change |
| Symfony application following the Symfony standard | `@Symfony` rule set, which builds on PER-CS |
| Both tools present | Pick one formatter. Let the other only report, or remove it |

Run Rector first and the formatter last, so the formatter normalizes whatever Rector wrote.

## Sources

| Fact | URL |
|---|---|
| PER-CS 3.1 spec | https://www.php-fig.org/per/coding-style/ |
| PER list | https://www.php-fig.org/per/ |
| PHP-CS-Fixer rule sets | https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/tree/master/doc/ruleSets |
| PHP-CS-Fixer usage | https://cs.symfony.com/doc/usage.html |
| PHPCS | https://github.com/PHPCSStandards/PHP_CodeSniffer |

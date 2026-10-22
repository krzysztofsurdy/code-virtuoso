---
name: php-quality
description: PHP static analysis, code style and modern idioms for PHP 8.3 to 8.5. Use when setting up phpstan.neon or a baseline, choosing PHPStan or Psalm, PHP-CS-Fixer or PHP_CodeSniffer, PER-CS or PSR-12, configuring Rector quality sets, or reviewing PHP for readonly, enums, property hooks and the pipe operator.
user-invocable: false
---

# PHP quality

Three kinds of stale advice cause most bad PHP tooling setups: "PHPStan level 9 is the maximum", "follow PSR-12", and "use Rector for everything". Level 10 has existed since PHPStan 2.0. PER Coding Style now extends and replaces PSR-12. Rector has quality sets that are separate from the upgrade sets. This skill gives the current facts, a decision for each tool choice, and the idioms the model tends to miss or misuse. Version upgrades are out of scope: use `php-upgrade`.

## Decide first

| Question | Answer | Why |
|---|---|---|
| Which static analyzer for a new project? | PHPStan | Official extensions cover Symfony, Doctrine and PHPUnit, and Rector itself depends on PHPStan ([extensions](https://phpstan.org/user-guide/extension-library)) |
| Project already uses Psalm and it works? | Keep it | Switching costs more than it returns. Psalm is maintained, see [Psalm vs PHPStan](#psalm-vs-phpstan) |
| Need taint analysis for injection paths? | Psalm, with `--taint-analysis` | It is a Psalm feature ([error levels](https://github.com/vimeo/psalm/blob/master/docs/running_psalm/error_levels.md)). The PHPStan docs read for this skill list none |
| Which formatter for a new project? | PHP-CS-Fixer with `@PER-CS3x0` | Ships PER-CS rule sets and fixes files in place |
| Project already has a PHP_CodeSniffer standard? | Keep PHPCS as the single formatter | Two tools fighting over whitespace produce endless diffs |
| Which coding style target? | PER-CS, not PSR-12 | See [PER-CS and PSR-12](#per-cs-and-psr-12) |
| Which Rector sets for quality? | Level methods, raised one step per PR | See [Rector for quality](#rector-for-quality) |
| Legacy code with thousands of errors? | Lower level plus a baseline, or fix by directory | See [Baseline strategy](#baseline-strategy) |

## PHPStan

Levels are cumulative. Level 0 checks unknown symbols and argument counts, 5 checks argument types, 6 checks missing type hints, 8 checks nullable access, 9 is strict about explicit `mixed`, and 10 (new in 2.0) also flags implicit `mixed`, such as missing types from third-party code. The full list is on [rule-levels](https://phpstan.org/user-guide/rule-levels). Details, config samples, extensions and generics are in [phpstan.md](references/phpstan.md).

Rules the model gets wrong:

- Level 10 is the ceiling. Do not write "level 9 is the maximum" and do not stop at 9 by habit.
- Set a number in `phpstan.neon`, not `--level max`. `max` always means the highest level, so a PHPStan upgrade can add errors without any code change, and the docs advise against it unless you accept that.
- Pick the level from the code, not from a target. Start where the error count is small, raise it, and use the baseline for the remainder.
- Enable [bleeding edge](https://phpstan.org/blog/what-is-bleeding-edge) only on projects that can absorb new errors on a minor update. It previews rules that become default in the next major version.
- Install the framework extension. Without `phpstan-symfony` or `phpstan-doctrine`, container services, console input and repository results are `mixed`, and higher levels drown in noise.
- Prefer `// @phpstan-ignore identifier (reason)` over line ignores. It names the error, so the ignore cannot hide a different error on the same line.

### Baseline strategy

A baseline is a debt ledger, not a settings file. The rule is generate once, shrink, never grow.

1. Run PHPStan at the target level and generate the baseline once with `--generate-baseline`.
2. Commit the baseline file and include it from `phpstan.neon`.
3. Keep `reportUnmatchedIgnoredErrors` on (it is the default). When a fix makes an entry obsolete, PHPStan reports it and you delete the entry, so the file shrinks.
4. Never regenerate to make a red build green. Regenerating records new errors as accepted debt. New code gets fixed or gets a reasoned inline ignore.
5. In CI, fail when the baseline file gains lines compared with the main branch. This check is a team convention, not a PHPStan feature.
6. Regenerate only on a clean branch to rewrite counts after a mass fix, and read the diff: it must be deletions only.

The PHPStan docs say the life goal of a baseline is to not exist, and that it suits dozens to hundreds of errors, not 15,000. For a huge backlog, lower the level.

### Generics in PHPDoc

PHP has no generics, so PHPStan reads them from PHPDoc: `@template T`, bounds with `@template T of Foo`, `@extends Parent<Foo>`, `@implements Iface<Foo>`, `@use Trait<Foo>` and `class-string<T>`. Write them for collections, repositories and factories, since a missing generic is what turns return values into `mixed` at level 10. Syntax and an example are in [phpstan.md](references/phpstan.md#generics-in-phpdoc).

## Psalm vs PHPStan

| Aspect | PHPStan | Psalm |
|---|---|---|
| Strictness scale | Levels 0-10, higher is stricter | Error levels 1-8, lower is stricter, default 2 |
| Extension ecosystem | Official packages for Symfony, Doctrine, PHPUnit, strict rules, deprecation rules | Plugins exist, check the plugin you need before choosing |
| Security data flow | Not in the docs read for this skill | Taint analysis (`--taint-analysis`) |
| Release state | Stable 2.x | Stable 6.x, 7.0 in release candidates |
| Maintenance | Active, the repo is the official source | Active, the README names one active maintainer |

Both read PHPDoc generics, and Psalm reads some `@phpstan-` tags. Do not run both at full strictness on one codebase without a reason: they report overlapping errors and the team ends up maintaining two baselines. For current release numbers see the [PHPStan releases](https://github.com/phpstan/phpstan/releases) and [Psalm releases](https://github.com/vimeo/psalm/releases).

## Code style

### PER-CS and PSR-12

| Standard | What it is | Status |
|---|---|---|
| PSR-12 | Extended coding style guide, accepted 2019 | Still listed as Accepted. PER-CS says it "extends, expands and replaces" PSR-12 |
| PER Coding Style 3.1 | A PER (PHP Evolving Recommendation), a living document with numbered releases, not a PSR | Current. Requires PSR-1 |
| PSR-2 | Old coding style | Deprecated |

PER-CS covers syntax PSR-12 never addressed: enums, attributes, match, union and intersection types, property hooks, asymmetric visibility and the pipe operator. New projects target PER-CS. Existing PSR-12 projects can adopt it with a one-time formatting commit. See [php-fig-status.md](references/php-fig-status.md) for the other standards.

### PHP-CS-Fixer vs PHP_CodeSniffer

| Aspect | PHP-CS-Fixer | PHP_CodeSniffer |
|---|---|---|
| PER-CS rule sets | `@PER-CS3x0`, `@PER-CS3x0:risky`, `@PER-CS` (floating alias) | Core ships PSR12, not PER. Check PHPCSStandards before assuming otherwise |
| Main job | Rewrite files to match the rules | Report violations, fix some with `phpcbf` |
| Pick it when | New project, you want one tool that formats | You have custom sniffs or a shared standard already |

Use `@PER-CS3x0` in config when you want stable diffs, and `@PER-CS` only when you accept formatting changes after each fixer upgrade. `@PER-CS3.0` and `@PER` are deprecated aliases that go away in the next major. A sample config and the risky-rules note are in [code-style.md](references/code-style.md). Check `doc/ruleSets` in the PHP-CS-Fixer repo for a newer revision, since 3.1 had no rule set when this skill was written.

## Rector for quality

Rector has two jobs. Upgrading to a new PHP version is `php-upgrade`. Raising code quality is covered here, and it works best with level methods, because each level adds the next safest slice of a set:

```php
return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withTypeCoverageLevel(0)
    ->withDeadCodeLevel(0)
    ->withCodeQualityLevel(0);
```

Raise one level per pull request, dry-run first (`vendor/bin/rector process --dry-run`), and review the diff. Add `withCodingStyleLevel()` only if no formatter owns that concern. `withPreparedSets(...)` turns on whole sets at once and is a poor start on an existing codebase. Details, framework sets and ordering with the formatter are in [rector-quality.md](references/rector-quality.md).

## Modern idioms

Check the project's PHP constraint before suggesting any of these. The table lists what the model underuses or gets wrong. Full detail and traps are in [modern-idioms.md](references/modern-idioms.md).

| Feature | Since | Use it for | Trap |
|---|---|---|---|
| `readonly` class | 8.2 | Value objects and DTOs with every property readonly | A readonly class can only be extended by a readonly class. No untyped or static properties |
| Enum implementing an interface | 8.1 | Cases that share behavior through a contract | Interface goes after the backing type: `enum Suit: string implements HasLabel`. Traits in enums cannot hold properties |
| Typed class constants | 8.3 | `public const string NAME = '...'` in classes and interfaces | An implementing class must keep a compatible type |
| `#[\Override]` | 8.3 (properties 8.5) | Methods that must match a parent or interface member | Not allowed on `__construct()`. Without it, a renamed parent method silently breaks the override |
| Property hooks | 8.4 | Validation or computed values without getter and setter pairs | Not on static or `readonly` properties. A hook that never touches `$this->prop` makes it virtual |
| Asymmetric visibility | 8.4 | `public private(set)` for read-only-from-outside state | Typed properties only. Set visibility cannot be wider than read visibility. `private(set)` makes the property final |
| `new` without parentheses | 8.4 | `new Foo()->bar()` instead of `(new Foo())->bar()` | Needs 8.4. PER-CS 3.0 says to drop the wrapping parentheses only when the project targets 8.4 or later |
| `array_find`, `array_any`, `array_all` | 8.4 | Replace manual `foreach` search loops | Callback-based, so do not use them where a plain loop is clearer |
| Pipe operator `\|>` | 8.5 | Left-to-right chains of single-argument callables | Arrow functions need parentheses, by-reference parameters fail, extra required arguments fail |
| `clone($obj, [...])` | 8.5 | "With-er" methods on readonly classes | Use it instead of rebuilding objects by hand, but only on 8.5 |
| `#[\NoDiscard]`, `(void)` | 8.5 | Results that must not be ignored | Needs 8.5. On older versions the attribute is inert and `$_ = f()` is the portable discard |

Do not combine hooks and `readonly` on one property (use asymmetric visibility to restrict writes), and do not use 8.4 or 8.5 syntax in a project whose `composer.json` allows older PHP.

## Pitfalls

- Treating PHPStan level 9 as the end. Level 10 exists, so check whether the project can reach it.
- Using `--level max` in CI. It changes meaning on every PHPStan upgrade.
- Regenerating the baseline after every red build. The baseline then only grows.
- Using blanket `ignoreErrors` message patterns where an error identifier would do.
- Writing "follow PSR-12" in new instructions. Say PER-CS, and name the rule set.
- Using the floating `@PER-CS` alias in a repo that wants stable formatting.
- Running PHP-CS-Fixer and PHP_CodeSniffer as formatters on the same files.
- Enabling Rector `codingStyle` while a formatter also runs, so the two undo each other.
- Using `withPreparedSets()` with many sets on day one, which produces a diff nobody can review.
- Using `@var` or PHPDoc to silence an error instead of fixing the type. PHPStan 2.0 checks inline `@var` against the native type.
- Suggesting hooks, `private(set)`, `#[\Override]` on properties or the pipe operator without checking the project's minimum PHP version.
- Quoting PSR status from memory. Use [php-fig-status.md](references/php-fig-status.md) and the PHP-FIG site.

## Reference files

| Reference | Open when |
|---|---|
| [phpstan.md](references/phpstan.md) | Writing `phpstan.neon`, choosing a level, installing extensions, baseline commands, ignore syntax, generics |
| [code-style.md](references/code-style.md) | Setting up PHP-CS-Fixer or PHPCS, choosing a PER-CS rule set, CI commands |
| [rector-quality.md](references/rector-quality.md) | Configuring Rector quality levels, framework sets, ordering with the formatter |
| [modern-idioms.md](references/modern-idioms.md) | Reviewing or writing code that uses 8.2 to 8.5 features |
| [php-fig-status.md](references/php-fig-status.md) | Checking whether a PSR or PER is current, deprecated, draft or abandoned |
| [research-notes](references/research-notes.md) | Research: prior-art table, fact ledger with sources and dates, unconfirmed items |

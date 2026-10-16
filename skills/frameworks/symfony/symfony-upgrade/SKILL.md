---
name: symfony-upgrade
description: Symfony version upgrade guide using the deprecation-first approach. Use to upgrade to a new minor or major version, fix deprecations, update recipes, check bundle compatibility, or move between LTS versions.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Symfony Framework Upgrade

Symfony's upgrade model rests on one fact: a new major version is the last minor of the previous branch with the deprecated code removed. Fix all deprecations first and the major upgrade becomes a small step.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before any upgrade, read the UPGRADE-X.Y.md file for the target version and the CHANGELOG.md of the Symfony packages you use. Never rely on built-in knowledge alone |
| **Deprecation-first** | Fix every deprecation on the current version before upgrading to the next major. Symfony 8.0 is 7.4 minus deprecations |
| **Incremental minor upgrades** | Upgrade 6.2 -> 6.3 -> 6.4 and do not skip minors, because each one surfaces new deprecations |
| **Recipes keep config current** | Run `composer recipes:update` after every upgrade to sync configuration files |
| **Test deprecation count** | Use `SYMFONY_DEPRECATIONS_HELPER` to fail builds when direct deprecations appear |
| **Update bundles first** | Third-party bundles are the most common blocker - update them before bumping Symfony |

---

## First step: read the changelog

Before touching any code or running any command, read what changed in the target version:

1. **Use the `docs-lookup` skill** to fetch the Symfony upgrade docs and the `UPGRADE-X.Y.md` file for the target version (the file name has the target version: `UPGRADE-8.0.md` covers 7.4 -> 8.0, `UPGRADE-8.1.md` covers 8.0 -> 8.1)
2. **Without that skill**, read it from the Symfony repository: `https://github.com/symfony/symfony/blob/X.Y/UPGRADE-X.Y.md`
3. **Check the installed packages.** Each Symfony package ships its own `vendor/symfony/<package>/CHANGELOG.md` with the deprecations and BC breaks for that package. The `UPGRADE-*.md` files are not in those packages. They are only in `vendor/symfony/symfony/` when the project requires the full `symfony/symfony` package, so `vendor/symfony/*/UPGRADE-*.md` usually matches nothing
4. **Check the Symfony blog** for the release announcement with highlighted changes
5. **Or ask the user** to provide the release notes

Do not skip this. Each version has its own changes that this skill cannot capture in full. The UPGRADE file lists exactly what broke, what was deprecated, and what was removed.

---

## Symfony release model

| Release type | Cycle | Support | Example |
|---|---|---|---|
| **Patch** (X.Y.Z) | Monthly | Bug fixes only | 7.4.1 -> 7.4.2 |
| **Minor** (X.Y) | Every 6 months (May + November) | May add deprecations, no BC breaks | 7.3 -> 7.4 |
| **Major** (X.0) | Every 2 years (November, odd years) | Removes deprecated code, may have BC breaks | 7.x -> 8.0 |
| **LTS** (X.4) | Always the X.4 release | 3 years bug fixes, 4 years security fixes | 6.4 LTS, 7.4 LTS |

Each major branch has exactly 5 minor versions: X.0, X.1, X.2, X.3, X.4 (LTS).

### Minimum PHP version

| Symfony | Minimum PHP |
|---|---|
| 6.4 LTS | 8.1.0 |
| 7.4 LTS | 8.2.0 |
| 8.0 | 8.4.0 |
| 8.1 | 8.4.1 |

Symfony 8.0 and 8.1 both need PHP 8.4 or newer, so moving from 7.4 to 8.x is also a PHP upgrade. Do the PHP upgrade first (see the `php-upgrade` skill), on the Symfony version you already run, then bump Symfony. Check `https://symfony.com/releases.json` (`min_php_requirements`) or the `php` constraint in the package's `composer.json` for the exact value of the version you target.

---

## Minor version upgrade (for example 7.3 -> 7.4)

### Step 1: Read the changelog

Read `UPGRADE-7.4.md` (see "First step: read the changelog"). Note the new deprecations and any changes that affect your code.

### Step 2: Update composer.json

With Symfony Flex (recommended):

```json
{
    "extra": {
        "symfony": {
            "require": "7.4.*"
        }
    }
}
```

Without Flex, update each `symfony/*` constraint manually.

### Step 3: Run composer update

```bash
composer update "symfony/*"
```

If dependency conflicts arise:

```bash
composer update "symfony/*" --with-all-dependencies
```

### Step 4: Update recipes

```bash
composer recipes:update
```

### Step 5: Run tests

```bash
vendor/bin/phpunit
```

---

## Major version upgrade (for example 6.4 -> 7.0)

### Phase 1: Read the changelog

Read `UPGRADE-7.0.md` (see "First step: read the changelog"). It lists every backward-compatibility break and every removed deprecation. Read all of it before starting.

### Phase 2: Eliminate all deprecations

This is most of the work. Do it while still on the current major version.

A. Detect deprecations through tests:

```bash
composer require --dev symfony/phpunit-bridge
```

Set strict deprecation handling in `phpunit.xml.dist`:

```xml
<php>
    <env name="SYMFONY_DEPRECATIONS_HELPER" value="max[direct]=0"/>
</php>
```

Run tests and fix every direct deprecation:

```bash
vendor/bin/phpunit
```

B. Detect deprecations in the browser:

Open the app in the dev environment and check the deprecation panel of the Symfony Profiler in the web debug toolbar.

C. Automate fixes with Rector:

```bash
composer require --dev rector/rector rector/rector-symfony
```

```php
// rector.php
use Rector\Config\RectorConfig;
use Rector\Symfony\Set\SymfonySetList;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withSets([SymfonySetList::SYMFONY_70]);
```

```bash
vendor/bin/rector process --dry-run
vendor/bin/rector process
```

D. Handle indirect deprecations:

Indirect deprecations come from third-party bundles. Update those bundles to versions that support the target Symfony version:

```bash
composer outdated
composer update vendor/bundle-name
```

### Phase 3: Bump the Symfony version

With Flex:

```json
{
    "extra": {
        "symfony": {
            "require": "7.0.*"
        }
    }
}
```

```bash
composer update "symfony/*" --with-all-dependencies
rm -rf var/cache/*
```

Packages such as `symfony/polyfill-*`, `symfony/ux-*`, and some `symfony/*-bundle` follow their own versioning. Do not force them to the new major.

### Phase 4: Update recipes

```bash
composer recipes              # list all, see which have updates
composer recipes:update       # interactive update, one at a time
```

The command generates a diff between your installed recipe version and the latest one and applies it as a git patch. Resolve conflicts as you would any git conflict. Commit your work before running it.

### Phase 5: Test

```bash
vendor/bin/phpunit
vendor/bin/phpstan analyse
```

Deploy to staging before production.

See [Upgrade Workflow Reference](references/upgrade-workflow.md) for deprecation handling, SYMFONY_DEPRECATIONS_HELPER options, and bundle compatibility strategies.

---

## SYMFONY_DEPRECATIONS_HELPER options

| Configuration | Effect |
|---|---|
| `max[direct]=0` | Fail on any deprecation caused by your code |
| `max[indirect]=999` | Tolerate deprecations from vendor code during transition |
| `max[total]=0` | Fail on any deprecation from any source (strictest setting) |
| `disabled=1` | Disable deprecation tracking entirely (not recommended) |
| `generateBaseline=true&baselineFile=./tests/allowed.json` | Snapshot current deprecations to a baseline file |
| `baselineFile=./tests/allowed.json` | Ignore deprecations already in the baseline (ratchet approach) |

---

## Handling third-party bundles

Bundles are the most common upgrade blocker. Work in this order:

1. **Check compatibility**: read each bundle's `composer.json` for Symfony version constraints
2. **Update bundles first**: run `composer update` before bumping the Symfony version
3. **Check for forks**: if a bundle is abandoned, look for maintained forks on Packagist
4. **Wrap risky dependencies**: put an adapter in front of bundles that may not keep up

For bundle maintainers, use feature detection instead of version checks:

```php
// Bad: version-based check
if (Kernel::VERSION_ID <= 60400) { ... }

// Good: feature-based check
if (!method_exists(OptionsResolver::class, 'setDefined')) { ... }
```

Support multiple versions with flexible constraints:

```json
{
    "require": {
        "symfony/framework-bundle": "^6.4|^7.0"
    }
}
```

---

## Quick reference: major upgrade checklist

- [ ] Read `UPGRADE-X.0.md` completely
- [ ] Upgrade to the last minor of current major (for example 6.4)
- [ ] Update all third-party bundles to latest versions
- [ ] Configure `SYMFONY_DEPRECATIONS_HELPER` with `max[direct]=0`
- [ ] Run test suite and fix all direct deprecations
- [ ] Run Rector with Symfony deprecation rules
- [ ] Verify zero direct deprecations in test output
- [ ] Update `extra.symfony.require` to new major version
- [ ] Run `composer update "symfony/*" --with-all-dependencies`
- [ ] Clear cache: `rm -rf var/cache/*`
- [ ] Run `composer recipes:update` until all recipes are current
- [ ] Run full test suite
- [ ] Run static analysis
- [ ] Deploy to staging and verify
- [ ] Deploy to production and monitor logs

---

## Reference Files

| Reference | Contents |
|---|---|
| [Upgrade Workflow](references/upgrade-workflow.md) | Deprecation handling workflow, `recipes:update` in detail, CI pipeline integration, and version-specific migration notes |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Upgrading PHP version alongside Symfony | Use the `php-upgrade` skill |
| Updating Composer dependencies | Use the `composer-dependencies` playbook skill |
| Working with Symfony components | Use the `symfony-components` skill in `frameworks/symfony/` |
| Modernizing PHP code patterns | Install `php-modernization` from `dirnbauer/webconsulting-skills` |

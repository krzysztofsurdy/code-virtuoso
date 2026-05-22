---
name: symfony-upgrade
description: Symfony framework version upgrade guide using the deprecation-first approach. Use when the user asks to upgrade Symfony to a new minor or major version, fix deprecation warnings, update Symfony recipes, check bundle compatibility, migrate between LTS versions, or plan a Symfony version migration strategy. Covers PHPUnit Bridge deprecation tracking, recipe updates, bundle compatibility checks, version-specific breaking changes, and the changelog-first upgrade workflow.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Symfony Framework Upgrade

Symfony's upgrade model is built on one core insight: a new major version is identical to the last minor version of the previous branch, minus deprecated code. Fix all deprecations first, then the major upgrade is trivial.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before any upgrade, search the web for the actual UPGRADE-X.Y.md file or ask the user for the changelog - never rely on static knowledge alone |
| **Deprecation-first** | Fix every deprecation on the current version before upgrading to the next major - Symfony 8.0 is 7.4 minus deprecations |
| **Incremental minor upgrades** | Upgrade 6.2 -> 6.3 -> 6.4, never skip minors - each surfaces new deprecations |
| **Recipes keep config current** | Run `composer recipes:update` after every upgrade to sync configuration files |
| **Test deprecation count** | Use `SYMFONY_DEPRECATIONS_HELPER` to fail builds when direct deprecations appear |
| **Update bundles first** | Third-party bundles are the most common blocker - update them before bumping Symfony |

---

## Critical First Step: Read the Changelog

Before touching any code or running any command, you MUST obtain the actual changelog for the target version:

1. **Search the web** for `Symfony UPGRADE-X.Y.md` (e.g., `Symfony UPGRADE-7.0.md github`)
2. **Or ask the user** to provide the changelog / release notes
3. **Read the UPGRADE file** in the Symfony repository: `https://github.com/symfony/symfony/blob/X.Y/UPGRADE-X.Y.md`
4. **Check the Symfony blog** for the release announcement with highlighted changes

This is non-negotiable. Each version has unique changes that static skill knowledge cannot fully capture. The changelog tells you exactly what broke, what was deprecated, and what was removed.

---

## Symfony Release Model

| Release Type | Cycle | Support | Example |
|---|---|---|---|
| **Patch** (X.Y.Z) | Monthly | Bug fixes only | 7.4.1 -> 7.4.2 |
| **Minor** (X.Y) | Every 6 months (May + November) | May add deprecations, no BC breaks | 7.3 -> 7.4 |
| **Major** (X.0) | Every 2 years (November, odd years) | Removes deprecated code, may have BC breaks | 7.x -> 8.0 |
| **LTS** (X.4) | Always the X.4 release | 3 years bug fixes, 4 years security fixes | 6.4 LTS, 7.4 LTS |

Each major branch has exactly 5 minor versions: X.0, X.1, X.2, X.3, X.4 (LTS).

---

## Minor Version Upgrade (e.g., 7.3 -> 7.4)

### Step 1: Read the Changelog

Search the web for `UPGRADE-7.4.md` in the Symfony repository. Identify new deprecations and any changes that affect your code.

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

### Step 3: Run Composer Update

```bash
composer update "symfony/*"
```

If dependency conflicts arise:

```bash
composer update "symfony/*" --with-all-dependencies
```

### Step 4: Update Recipes

```bash
composer recipes:update
```

### Step 5: Run Tests

```bash
vendor/bin/phpunit
```

---

## Major Version Upgrade (e.g., 6.4 -> 7.0)

### Phase 1: Read the Changelog

Search the web for `UPGRADE-7.0.md` in the Symfony repository. This file lists every backward-compatibility break and every removed deprecation. Read it completely before starting.

### Phase 2: Eliminate All Deprecations

This is the bulk of the work. Do this while still on the current major version.

**A. Detect deprecations via tests:**

```bash
composer require --dev symfony/phpunit-bridge
```

Configure strict deprecation handling in `phpunit.xml.dist`:

```xml
<php>
    <env name="SYMFONY_DEPRECATIONS_HELPER" value="max[direct]=0"/>
</php>
```

Run tests and fix every direct deprecation:

```bash
vendor/bin/phpunit
```

**B. Detect deprecations in browser:**

Visit the app in dev environment, check the Symfony Profiler's deprecation panel in the web debug toolbar.

**C. Automate fixes with Rector:**

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

**D. Handle indirect deprecations:**

Indirect deprecations come from third-party bundles. Update them to versions that support the target Symfony version:

```bash
composer outdated
composer update vendor/bundle-name
```

### Phase 3: Bump Symfony Version

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

Note: packages like `symfony/polyfill-*`, `symfony/ux-*`, and some `symfony/*-bundle` follow their own versioning - do not force them to the new major.

### Phase 4: Update Recipes

```bash
composer recipes              # list all, see which have updates
composer recipes:update       # interactive update, one at a time
```

The command generates a diff between your installed recipe version and the latest, applies it as a git patch. Resolve conflicts like normal git conflicts. Commit your work before running this.

### Phase 5: Test Thoroughly

```bash
vendor/bin/phpunit
vendor/bin/phpstan analyse
```

Deploy to staging before production.

See [Upgrade Workflow Reference](references/upgrade-workflow.md) for detailed deprecation handling, SYMFONY_DEPRECATIONS_HELPER options, and bundle compatibility strategies.

---

## SYMFONY_DEPRECATIONS_HELPER Options

| Configuration | Effect |
|---|---|
| `max[direct]=0` | Fail on any deprecation caused by your code |
| `max[indirect]=999` | Tolerate deprecations from vendor code during transition |
| `max[total]=0` | Fail on any deprecation from any source (strictest) |
| `disabled=1` | Disable deprecation tracking entirely (not recommended) |
| `generateBaseline=true&baselineFile=./tests/allowed.json` | Snapshot current deprecations to a baseline file |
| `baselineFile=./tests/allowed.json` | Ignore deprecations already in the baseline (ratchet approach) |

---

## Handling Third-Party Bundles

Bundles are the most common upgrade blocker. Follow this order:

1. **Check compatibility** - look at each bundle's `composer.json` for Symfony version constraints
2. **Update bundles first** - `composer update` before bumping Symfony version
3. **Check for forks** - if a bundle is abandoned, look for maintained forks on Packagist
4. **Wrap risky dependencies** - use adapter pattern to isolate bundles that may not keep up

For bundle maintainers, use feature detection instead of version checks:

```php
// Bad - version-based check
if (Kernel::VERSION_ID <= 60400) { ... }

// Good - feature-based check
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

## Quick Reference: Major Upgrade Checklist

- [ ] Search the web for `UPGRADE-X.0.md` and read it completely
- [ ] Upgrade to the last minor of current major (e.g., 6.4)
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
| [Upgrade Workflow](references/upgrade-workflow.md) | Detailed deprecation handling workflow, recipes:update deep dive, CI pipeline integration, and version-specific migration notes |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Upgrading PHP version alongside Symfony | Use the `php-upgrade` playbook skill |
| Updating Composer dependencies | Use the `composer-dependencies` playbook skill |
| Working with Symfony components | Use the `symfony-components` skill in `frameworks/symfony/` |
| Modernizing PHP code patterns | Install `php-modernization` from `dirnbauer/webconsulting-skills` |

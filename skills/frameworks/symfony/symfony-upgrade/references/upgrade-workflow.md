# Symfony Upgrade Workflow

## Contents

- [Deprecation handling](#deprecation-handling)
- [recipes:update in detail](#recipesupdate-in-detail)
- [CI pipeline integration](#ci-pipeline-integration)
- [Version-specific migration notes](#version-specific-migration-notes)
- [Troubleshooting](#troubleshooting)

## Deprecation handling

### Deprecation categories

The Symfony PHPUnit Bridge sorts deprecations into three categories:

| Category | Source | Your responsibility |
|---|---|---|
| **Direct** | Your code triggers the deprecation | Fix before upgrading |
| **Indirect** | Vendor code triggers the deprecation | Update the package or report upstream |
| **Self** | The deprecated class/method is in your code | Refactor the API |

### The ratchet approach

A deprecation baseline stops regressions while you fix deprecations a batch at a time.

**Step 1: Generate the baseline (snapshot the current state):**

```xml
<!-- phpunit.xml.dist -->
<php>
    <env name="SYMFONY_DEPRECATIONS_HELPER"
         value="generateBaseline=true&amp;baselineFile=./tests/deprecation-baseline.json"/>
</php>
```

```bash
vendor/bin/phpunit
```

This creates `tests/deprecation-baseline.json` with all current deprecations.

**Step 2: Switch to baseline mode:**

```xml
<php>
    <env name="SYMFONY_DEPRECATIONS_HELPER"
         value="baselineFile=./tests/deprecation-baseline.json"/>
</php>
```

Tests now fail only on new deprecations. Existing ones are tolerated.

**Step 3: Fix deprecations incrementally:**

After each batch of fixes, regenerate the baseline to lock in the progress:

```bash
SYMFONY_DEPRECATIONS_HELPER="generateBaseline=true&baselineFile=./tests/deprecation-baseline.json" vendor/bin/phpunit
```

**Step 4: When the baseline is empty, switch to strict mode:**

```xml
<php>
    <env name="SYMFONY_DEPRECATIONS_HELPER" value="max[direct]=0"/>
</php>
```

### Common deprecation patterns and fixes

**Service configuration (YAML to PHP):**

```yaml
# Before (deprecated in some versions)
services:
    App\Service\MyService:
        arguments: ['@doctrine.orm.entity_manager']
```

```yaml
# After
services:
    App\Service\MyService:
        arguments: ['@doctrine.orm.default_entity_manager']
```

**Annotations to attributes:**

```php
// Before (deprecated)
use Symfony\Component\Routing\Annotation\Route;

/**
 * @Route("/api/users", methods={"GET"})
 */
public function list(): Response { }

// After
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api/users', methods: ['GET'])]
public function list(): Response { }
```

**Security configuration (authenticator system):**

The old `guard` and `security.interactive_login` patterns are deprecated. Use the authenticator system, available since Symfony 5.3.

---

## recipes:update in detail

### How it works

1. Compares the recipe version you installed against the latest version
2. Generates a git-format patch of the differences
3. Applies the patch to your project using git
4. If conflicts occur, you get standard git merge conflict markers

### Workflow

```bash
# Commit all unrelated changes first
git add -A && git commit -m "WIP before recipe update"

# List all recipes and see which have updates
composer recipes

# Update interactively (one recipe at a time)
composer recipes:update

# Or update a specific recipe
composer recipes:update symfony/framework-bundle
```

### After each recipe update

1. Review the changes with `git diff`
2. Resolve any merge conflicts
3. Test: `vendor/bin/phpunit`
4. Commit: `git add -A && git commit -m "Update symfony/framework-bundle recipe"`
5. Repeat for the next recipe

### Common recipe changes

| Recipe | Typical changes |
|---|---|
| `symfony/framework-bundle` | New framework.yaml defaults, new environment variables, updated Docker configs |
| `symfony/security-bundle` | Security configuration structure changes, new authenticator defaults |
| `symfony/doctrine-bundle` | New Doctrine configuration options, migration tool defaults |
| `symfony/twig-bundle` | Template path changes, new Twig configuration |
| `symfony/mailer` | DSN format changes, new transport options |

---

## CI pipeline integration

### Deprecation gate in CI

Add a CI step that fails when direct deprecations appear:

```yaml
# GitHub Actions example
symfony-deprecation-check:
  steps:
    - name: Install dependencies
      run: composer install --no-interaction

    - name: Check for deprecations
      env:
        SYMFONY_DEPRECATIONS_HELPER: "max[direct]=0"
      run: vendor/bin/phpunit
```

### Multi-version testing

While moving between Symfony versions, test against both:

```yaml
strategy:
  matrix:
    symfony-version: ['6.4.*', '7.0.*']
steps:
  - name: Set Symfony version
    run: composer config extra.symfony.require "${{ matrix.symfony-version }}"

  - name: Update dependencies
    run: composer update "symfony/*" --with-all-dependencies --no-interaction

  - name: Run tests
    run: vendor/bin/phpunit
```

---

## Version-specific migration notes

### Symfony 5.4 -> 6.0

Key areas:

- PHP 8.0 minimum requirement
- Return type declarations required on all controller methods
- Security component: the authenticator-based system is mandatory
- Removed `enable_authenticator_manager` setting (always enabled)
- `AbstractController::getDoctrine()` removed; inject `ManagerRegistry` instead

### Symfony 6.4 -> 7.0

Key areas:

- PHP 8.2 minimum requirement
- Attributes replace annotations entirely (routing, validation, serialization)
- `MapQueryParameter`, `MapRequestPayload` attributes for controller argument mapping
- Scheduler component is no longer experimental
- AssetMapper is available as an alternative to Webpack Encore
- Removed deprecated `TreeBuilder::root()` method
- Removed deprecated security configuration options

### Symfony 7.4 -> 8.0

Key areas:

- PHP 8.4 minimum requirement expected
- TypeInfo component is no longer experimental
- Remaining annotation support removed
- Check `UPGRADE-8.0.md` for the complete list

---

## Troubleshooting

### Dependency conflicts during update

```bash
# See what blocks an upgrade
composer why-not symfony/framework-bundle 7.0

# See what depends on a specific package
composer why vendor/some-bundle

# Force update with all dependencies
composer update "symfony/*" --with-all-dependencies
```

### Cache issues after upgrade

After a major upgrade, clear the cache by hand:

```bash
rm -rf var/cache/*
```

Do not rely on `bin/console cache:clear`. It can fail if the container cannot compile with the new version.

### Recipe conflicts

If `composer recipes:update` produces conflicts you cannot resolve:

```bash
# Reset the recipe update
git checkout -- .

# Apply manually by reading the recipe diff
composer recipes symfony/framework-bundle  # shows diff details
```

### Bundle not compatible

```bash
# Check if a newer version exists
composer outdated vendor/bundle-name

# Check what Symfony version it requires
composer show vendor/bundle-name | grep -i symfony

# Look for forks or alternatives on Packagist
# https://packagist.org/?query=bundle-name
```

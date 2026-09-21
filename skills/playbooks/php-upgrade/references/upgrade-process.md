# PHP Upgrade Process

## Contents

- [Tool configuration](#tool-configuration)
- [CI pipeline setup](#ci-pipeline-setup)
- [Docker strategy](#docker-strategy)
- [Composer platform configuration](#composer-platform-configuration)
- [Step-by-step command sequence](#step-by-step-command-sequence)

## Tool configuration

### Rector

Rector parses PHP into an AST (Abstract Syntax Tree) and transforms the code automatically. It supports upgrades from PHP 5.3 through 8.4+.

**Installation:**

```bash
composer require --dev rector/rector
```

**Configuration for PHP version upgrades:**

```php
// rector.php
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([
        __DIR__ . '/src',
        __DIR__ . '/tests',
    ])
    ->withPhpSets(php84: true);  // includes all rules from 5.3 through 8.4
```

**Target-specific configuration examples:**

```php
// For PHP 8.2 upgrade
return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php82: true);

// For PHP 8.3 upgrade
return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php83: true);
```

**Running Rector:**

```bash
# Preview changes without modifying files
vendor/bin/rector process --dry-run

# Apply changes
vendor/bin/rector process

# Process specific directory
vendor/bin/rector process src/Legacy/
```

**Symfony-specific Rector rules:**

```bash
composer require --dev rector/rector-symfony
```

```php
use Rector\Config\RectorConfig;
use Rector\Symfony\Set\SymfonySetList;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php84: true)
    ->withSets([
        SymfonySetList::SYMFONY_72,  // adjust to target Symfony version
    ]);
```

### PHPCompatibility

A PHP_CodeSniffer ruleset that detects cross-version compatibility issues. It gives the same results whichever PHP version runs the analysis.

**Installation:**

```bash
composer require --dev phpcompatibility/php-compatibility
```

**Running against a target version:**

```bash
# Check compatibility with PHP 8.4
vendor/bin/phpcs -ps --standard=PHPCompatibility --runtime-set testVersion 8.4- src/

# Check compatibility across a range (e.g., 8.2 through 8.4)
vendor/bin/phpcs -ps --standard=PHPCompatibility --runtime-set testVersion 8.2-8.4 src/

# Generate a report file
vendor/bin/phpcs --standard=PHPCompatibility --runtime-set testVersion 8.4- --report=json --report-file=compatibility-report.json src/
```

### php-parallel-lint

Checks PHP syntax in parallel, about 20x faster than serial checking.

**Installation:**

```bash
composer require --dev php-parallel-lint/php-parallel-lint
```

**Running:**

```bash
# Lint all PHP files
vendor/bin/parallel-lint src/ tests/

# Show git blame for each error
vendor/bin/parallel-lint --blame src/ tests/

# Lint with a specific PHP binary (useful for testing against a different version)
vendor/bin/parallel-lint -p /usr/bin/php8.4 src/ tests/

# Exclude directories
vendor/bin/parallel-lint --exclude vendor --exclude var src/ tests/ config/
```

### Symfony PHPUnit Bridge

Shows a deprecation summary at the end of test reports, grouped by source.

**Installation:**

```bash
composer require --dev symfony/phpunit-bridge
```

**Configuration in phpunit.xml.dist:**

```xml
<phpunit>
    <php>
        <!-- Fail on any direct deprecation -->
        <env name="SYMFONY_DEPRECATIONS_HELPER" value="max[direct]=0"/>

        <!-- Tolerate indirect deprecations during transition -->
        <env name="SYMFONY_DEPRECATIONS_HELPER" value="max[direct]=0&amp;max[indirect]=999"/>

        <!-- Generate a deprecation baseline (snapshot current state) -->
        <env name="SYMFONY_DEPRECATIONS_HELPER" value="generateBaseline=true&amp;baselineFile=./tests/allowed.json"/>

        <!-- Use the baseline to ignore known deprecations -->
        <env name="SYMFONY_DEPRECATIONS_HELPER" value="baselineFile=./tests/allowed.json"/>
    </php>
</phpunit>
```

---

## CI pipeline setup

### Recommended CI steps

```yaml
# Example GitHub Actions workflow
php-upgrade-check:
  strategy:
    matrix:
      php-version: ['8.3', '8.4']  # Test both current and target
  steps:
    - name: Lint check
      run: vendor/bin/parallel-lint --exclude vendor src/ tests/

    - name: Compatibility check
      run: vendor/bin/phpcs -ps --standard=PHPCompatibility --runtime-set testVersion ${{ matrix.php-version }}- src/

    - name: Static analysis
      run: vendor/bin/phpstan analyse

    - name: Unit tests
      run: vendor/bin/phpunit

    - name: Rector dry-run (verify no pending changes)
      run: vendor/bin/rector process --dry-run
```

### Matrix testing strategy

During the transition, run tests against both the current and target PHP versions:

1. Add both versions to your CI matrix
2. Once all checks pass on the new version, remove the old version
3. Update `config.platform.php` to reflect the new minimum

---

## Docker strategy

### Updating the PHP version in Docker

```dockerfile
# Update the base image tag
FROM php:8.4-fpm-alpine

# Ensure extensions are installed for the new version
RUN docker-php-ext-install pdo_mysql intl opcache
```

**Rebuild from scratch:**

```bash
docker compose build --no-cache
docker compose up -d
```

**Rollback:** Revert the Dockerfile version tag and rebuild.

### Multi-stage testing

```dockerfile
# Build stage with target PHP version
FROM php:8.4-fpm-alpine AS test
COPY . /app
WORKDIR /app
RUN composer install --no-interaction
RUN vendor/bin/phpunit
```

---

## Composer platform configuration

Always set `config.platform.php` to match your lowest deployment target. Composer then resolves dependencies for the correct PHP version regardless of what runs locally.

```json
{
    "config": {
        "platform": {
            "php": "8.4.0"
        }
    }
}
```

**Why this matters:**

- Without it, Composer may install packages that work on your local PHP 8.4 but fail on production PHP 8.3
- It removes the temptation to use `--ignore-platform-reqs`
- CI and production get the same dependency versions

---

## Step-by-step command sequence

For upgrading from PHP 8.3 to 8.4 (adjust versions as needed):

```bash
# 1. Audit
vendor/bin/phpcs -ps --standard=PHPCompatibility --runtime-set testVersion 8.4- src/
vendor/bin/parallel-lint src/ tests/
composer outdated --direct

# 2. Automate with Rector
# Edit rector.php to set php84: true
vendor/bin/rector process --dry-run
vendor/bin/rector process
git add -A && git commit -m "Apply Rector PHP 8.4 transformations"

# 3. Manual fixes for remaining issues
# Fix issues identified by PHPCompatibility that Rector didn't handle
git add -A && git commit -m "Manual PHP 8.4 compatibility fixes"

# 4. Update Composer
# Edit composer.json: "php": ">=8.4", config.platform.php: "8.4.0"
composer update
git add composer.json composer.lock && git commit -m "Update PHP constraint to 8.4"

# 5. Verify
vendor/bin/phpstan analyse
vendor/bin/phpunit
vendor/bin/phpcs -ps --standard=PHPCompatibility --runtime-set testVersion 8.4- src/

# 6. Deploy
# Update Docker/CI to use PHP 8.4
# Deploy to staging, verify, then production
```

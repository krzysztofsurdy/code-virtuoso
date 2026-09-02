# Composer Update Workflow

## Contents

- [Step-by-step safe update process](#step-by-step-safe-update-process)
- [Handling major version updates](#handling-major-version-updates)
- [Symfony-specific dependency updates](#symfony-specific-dependency-updates)
- [CI integration](#ci-integration)
- [Troubleshooting](#troubleshooting)

## Step-by-step safe update process

### 1. Audit the current state

```bash
# Check for security vulnerabilities first
composer audit

# See what needs updating (direct dependencies only)
composer outdated --direct

# Validate composer.json structure
composer validate --strict
```

### 2. Create a dedicated branch

```bash
git checkout -b chore/dependency-updates
```

### 3. Apply patch updates (lowest risk)

```bash
# Preview what would change
composer update --patch-only --dry-run

# Apply patch updates
composer update --patch-only

# Run tests
vendor/bin/phpunit
vendor/bin/phpstan analyse

# Commit
git add composer.json composer.lock
git commit -m "Update dependencies (patch versions)"
```

### 4. Apply minor updates

```bash
# Preview
composer update --minor-only --dry-run

# Apply
composer update --minor-only

# Test and commit
vendor/bin/phpunit
git add composer.json composer.lock
git commit -m "Update dependencies (minor versions)"
```

### 5. Handle major updates (one at a time)

```bash
# Check what prevents upgrading
composer why-not vendor/package 2.0

# Review changelog/UPGRADE file for the package
# Then update
composer update vendor/package --with-all-dependencies

# Test thoroughly
vendor/bin/phpunit
vendor/bin/phpstan analyse

# Commit separately
git add composer.json composer.lock
git commit -m "Update vendor/package to v2.0"
```

### 6. Post-update verification

```bash
# Security check again
composer audit

# Verify no unused packages crept in
# (requires composer-unused/composer-unused)
vendor/bin/composer-unused

# Optionally raise lower bounds (applications only)
composer bump
```

---

## Handling major version updates

Major updates need extra care because they may contain breaking changes.

### Investigation phase

```bash
# What version are we on?
composer show vendor/package | head -5

# What blocks the upgrade?
composer why-not vendor/package 3.0

# Who depends on this package?
composer why vendor/package

# What would change?
composer update vendor/package --with-all-dependencies --dry-run
```

### Execution phase

1. Read the package's CHANGELOG.md and UPGRADE guide
2. Search your codebase for deprecated API usage
3. Update the constraint in `composer.json` if needed
4. Run `composer update vendor/package --with-all-dependencies`
5. Fix compilation and runtime errors
6. Run tests and fix failures
7. Commit with a descriptive message that references the major version change

### When the update breaks things

```bash
# Revert and investigate
git checkout -- composer.json composer.lock
composer install

# Try a more targeted approach
# Update just the blocker first
composer why-not vendor/package 3.0
# Fix the blocker, then retry
```

---

## Symfony-specific dependency updates

### Updating Symfony packages

With Flex:

```json
{
    "extra": {
        "symfony": {
            "require": "7.4.*"
        }
    }
}
```

```bash
composer update "symfony/*" --with-all-dependencies
```

Dependabot may ignore the `extra.symfony.require` setting. Use Renovate or manual updates for Symfony version bumps.

### Updating recipes after package updates

```bash
composer recipes           # check for recipe updates
composer recipes:update    # apply recipe patches
```

---

## CI integration

### Automated security checks

Add to your CI pipeline:

```yaml
security-audit:
  steps:
    - run: composer install --no-interaction
    - run: composer audit
    - run: composer validate --strict
```

### Outdated dependency reporting

```yaml
dependency-check:
  steps:
    - run: composer outdated --direct --format=json > outdated.json
    # Parse and report/alert on critical updates
```

---

## Troubleshooting

### Lock file merge conflicts

Composer 2.9+ can recover from simple lock file conflicts on its own. For complex ones:

```bash
# Accept either side's composer.json (with your desired constraints)
# Then regenerate the lock file
composer update --lock
```

If that fails:

```bash
# Nuclear option: regenerate entirely
rm composer.lock
composer update
# Verify the result carefully
```

### Dependency conflicts

When multiple packages conflict:

```bash
# Find the root cause
composer why vendor/package-a
composer why vendor/package-b
composer why-not vendor/package-a 2.0

# Sometimes relaxing one constraint unblocks others
# Edit composer.json to widen the constraint, then:
composer update vendor/package-a vendor/package-b --with-all-dependencies
```

### Platform mismatches

If dependencies install locally but fail in CI or production, set the target platform:

```json
{
    "config": {
        "platform": {
            "php": "8.3.0",
            "ext-intl": "8.3.0"
        }
    }
}
```

Composer then resolves for the target platform regardless of the local PHP version.

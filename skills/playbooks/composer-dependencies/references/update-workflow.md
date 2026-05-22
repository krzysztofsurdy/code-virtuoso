# Composer Update Workflow

## Step-by-Step Safe Update Process

### 1. Audit Current State

```bash
# Check for security vulnerabilities first
composer audit

# See what needs updating (direct dependencies only)
composer outdated --direct

# Validate composer.json structure
composer validate --strict
```

### 2. Create a Dedicated Branch

```bash
git checkout -b chore/dependency-updates
```

### 3. Apply Patch Updates (Lowest Risk)

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

### 4. Apply Minor Updates

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

### 5. Handle Major Updates (One at a Time)

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

### 6. Post-Update Verification

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

## Handling Major Version Updates

Major updates require special care because they may contain breaking changes.

### Investigation Phase

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

### Execution Phase

1. Read the package's CHANGELOG.md and UPGRADE guide
2. Search your codebase for deprecated API usage
3. Update the constraint in `composer.json` if needed
4. Run `composer update vendor/package --with-all-dependencies`
5. Fix compilation/runtime errors
6. Run tests, fix failures
7. Commit with a descriptive message referencing the major version change

### When the Update Breaks Things

```bash
# Revert and investigate
git checkout - composer.json composer.lock
composer install

# Try a more targeted approach
# Update just the blocker first
composer why-not vendor/package 3.0
# Fix the blocker, then retry
```

---

## Symfony-Specific Dependency Updates

### Updating Symfony Packages

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

Note: Dependabot may ignore the `extra.symfony.require` setting. Use Renovate or manual updates for Symfony version bumps.

### Updating Recipes After Package Updates

```bash
composer recipes           # check for recipe updates
composer recipes:update    # apply recipe patches
```

---

## CI Integration

### Automated Security Checks

Add to your CI pipeline:

```yaml
security-audit:
  steps:
    - run: composer install --no-interaction
    - run: composer audit
    - run: composer validate --strict
```

### Outdated Dependency Reporting

```yaml
dependency-check:
  steps:
    - run: composer outdated --direct --format=json > outdated.json
    # Parse and report/alert on critical updates
```

---

## Troubleshooting

### Lock File Merge Conflicts

Composer 2.9+ can auto-recover from simple lock file conflicts. For complex ones:

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

### Dependency Hell

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

### Platform Mismatches

If dependencies install locally but fail in CI/production:

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

This ensures Composer resolves for the target platform regardless of local PHP version.

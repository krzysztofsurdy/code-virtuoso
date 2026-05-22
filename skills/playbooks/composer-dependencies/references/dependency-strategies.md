# Dependency Strategies

## Constraint Selection Guide

### For Applications

| Scenario | Recommended Constraint | Reason |
|---|---|---|
| Most dependencies | `^1.2.3` (caret) | Allows non-breaking updates per semver |
| Known regression in a patch | `1.2.3` (exact, temporarily) | Pin until regression is fixed upstream |
| Pre-1.0 packages | `^0.3` (caret) | Respects semver instability: `>=0.3.0 <0.4.0` |
| Symfony packages with Flex | `*` in require, version in `extra.symfony.require` | Flex manages the actual constraint |
| Development tools | `^` with `--dev` | Same strategy, separate section |

After updating, run `composer bump` to raise lower bounds to currently installed versions. This prevents accidental downgrades and improves dependency resolution speed.

### For Libraries

| Rule | Reason |
|---|---|
| Always use `^` (caret) | Maximizes interoperability - don't cause dependency hell for consumers |
| Support multiple major versions when practical | e.g., `^6.4\|^7.0` for Symfony packages |
| Never use `composer bump` on library constraints | Narrows the range for consumers |
| `composer bump --dev-only` is safe | Dev dependencies don't affect consumers |

---

## Automated Update Tools

### Dependabot (GitHub Native)

Configuration file: `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
      day: "monday"
    versioning-strategy: "lockfile-only"  # recommended for apps
    open-pull-requests-limit: 10
    reviewers:
      - "your-team"
    groups:
      symfony:
        patterns:
          - "symfony/*"
      doctrine:
        patterns:
          - "doctrine/*"
    ignore:
      # Ignore major updates for packages you want to control manually
      - dependency-name: "vendor/critical-package"
        update-types: ["version-update:semver-major"]
```

Key settings:
- `versioning-strategy: lockfile-only` - updates only the lock file, not constraints in `composer.json` (safest for applications)
- Group related packages into single PRs to reduce noise
- Set `ignore` rules for packages where major updates require manual planning

**Limitation:** Dependabot may not respect `extra.symfony.require` in Flex projects.

### Renovate Bot

More powerful alternative to Dependabot. Works on GitHub, GitLab, Bitbucket, Azure DevOps.

Configuration file: `renovate.json`

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "packageRules": [
    {
      "matchPackagePatterns": ["symfony/*"],
      "groupName": "Symfony packages",
      "schedule": ["before 9am on Monday"]
    },
    {
      "matchPackagePatterns": ["doctrine/*"],
      "groupName": "Doctrine packages"
    },
    {
      "matchUpdateTypes": ["major"],
      "dependencyDashboardApproval": true
    }
  ],
  "composer": {
    "rangeStrategy": "update-lockfile"
  }
}
```

Advantages over Dependabot:
- Better monorepo support
- Dependency Dashboard for visibility
- More granular scheduling and grouping
- Supports 90+ package managers
- `rangeStrategy: update-lockfile` is similar to Dependabot's `lockfile-only`

---

## Abandoned Package Handling

### Detection

Composer warns during install/update:

```
Package vendor/old-package is abandoned, you should avoid using it.
Use vendor/new-package instead.
```

### Replacement Process

1. **Check suggested replacement** in the Composer warning
2. **Search Packagist** for alternatives: https://packagist.org
3. **Compare candidates** by: maintenance activity, download count, PHP version support, test coverage
4. **Check API compatibility** - is the replacement a drop-in or does it require refactoring?
5. **Wrap behind an interface** if replacement APIs differ significantly (adapter pattern)

### Proactive Monitoring

```bash
# Find packages not actually used in code
composer require --dev composer-unused/composer-unused
vendor/bin/composer-unused

# Check maintenance status periodically
composer outdated --direct  # packages with no updates for 2+ years may be abandoned
```

### Signs a Package May Be Abandoned Soon

- No commits in 12+ months
- Open issues/PRs with no response
- No support for recent PHP versions
- Single maintainer with no activity
- No CI/CD pipeline

---

## Update Frequency Recommendations

| Update Type | Frequency | Approach |
|---|---|---|
| Security patches | Immediately | `composer audit` in CI, auto-merge Dependabot security PRs |
| Patch updates | Weekly | Batch all patch updates, auto-merge if tests pass |
| Minor updates | Biweekly | Review changelogs, group by ecosystem (Symfony, Doctrine) |
| Major updates | As needed | One at a time, dedicated branch, thorough testing |
| Full audit | Monthly | `composer outdated --direct`, review abandoned packages |

---

## composer-unused

Finds packages declared in `composer.json` that are not actually imported in your code.

```bash
composer require --dev composer-unused/composer-unused
vendor/bin/composer-unused
```

Common false positives:
- Symfony Flex recipes that register bundles automatically
- Packages loaded via configuration rather than direct imports
- Runtime-only packages (e.g., `ext-*` polyfills)

Configure exclusions in `composer-unused.php` if needed.

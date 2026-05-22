---
name: composer-dependencies
description: Composer dependency management playbook for safe, systematic package updates. Use when the user asks to update Composer dependencies, audit packages for security vulnerabilities, manage composer.lock, configure Dependabot or Renovate for automated updates, replace abandoned packages, or resolve version conflicts. Covers patch/minor/major update strategies, composer audit, semantic versioning constraints, lock file hygiene, and the changelog-first update workflow.
user-invocable: true
---

# Composer Dependencies Update

Dependency updates are maintenance, not features. Do them regularly in small batches rather than rarely in large ones. Every update follows the same cycle: audit, update, verify, commit.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before any major dependency update, search the web for the package's changelog/UPGRADE file or ask the user to provide it - never guess what changed |
| **Security first** | Run `composer audit` before and after every update - vulnerabilities take priority over everything |
| **Small batches** | Update one package or one logical group at a time - never update everything at once |
| **Lock file is truth** | Always commit `composer.lock` - production uses `composer install`, never `composer update` |
| **Verify before merging** | Every update must pass the full test suite and static analysis before merging |
| **Caret by default** | Use `^` constraints for most dependencies - it balances stability with receiving fixes |

---

## Critical First Step: Read the Changelog

Before updating any dependency to a new major version, you MUST obtain the actual changelog:

1. **Search the web** for `{package-name} CHANGELOG` or `{package-name} UPGRADE guide` (e.g., `doctrine/orm UPGRADE.md github`)
2. **Or ask the user** to provide the changelog / release notes
3. **Check the package's GitHub repository** for `CHANGELOG.md`, `UPGRADE.md`, or release notes

This is non-negotiable for major updates. Each package has unique breaking changes that static skill knowledge cannot capture. For patch and minor updates, changelogs are recommended but not blocking.

---

## Update Strategies by Risk Level

| Strategy | Scope | Risk | Frequency | Command |
|---|---|---|---|---|
| **Patch only** | Bug fixes (1.2.3 -> 1.2.4) | Lowest | Weekly | `composer update --patch-only` |
| **Minor** | New features, backward-compatible (1.2 -> 1.3) | Low | Biweekly | `composer update --minor-only` |
| **Major** | Breaking changes possible (1.x -> 2.0) | Highest | Planned, one at a time | `composer update vendor/package --with-all-dependencies` |
| **Security** | Vulnerability fixes | Urgent | Immediately | `composer audit` then targeted update |

---

## Essential Commands

| Command | Purpose |
|---|---|
| `composer outdated --direct` | Show outdated direct dependencies (skip transitive) |
| `composer outdated --major-only` | Show only packages with major updates available |
| `composer outdated --minor-only` | Show only packages with minor updates available |
| `composer audit` | Check locked versions against known security advisories |
| `composer why vendor/package` | Show which packages depend on a given dependency |
| `composer why-not vendor/package 2.0` | Show what prevents upgrading to a specific version |
| `composer update vendor/package --with-all-dependencies` | Update a package and all its dependents |
| `composer bump` | Raise lower bounds in `composer.json` to currently installed versions (apps only) |
| `composer validate --strict` | Validate `composer.json` structure and constraints |

---

## Security Auditing

### composer audit

Built into Composer since 2.4. Compares locked versions against GitHub Security Advisories and FriendsOfPHP databases.

```bash
# Check for known vulnerabilities
composer audit

# JSON output for CI parsing
composer audit --format=json
```

Returns non-zero exit code when vulnerabilities are found - use as a CI gate.

Since Composer 2.9 (November 2025), `composer update` and `composer require` automatically block installation of packages with known security advisories by default.

### roave/security-advisories

Preventive complement to `composer audit`. Declares `conflict` rules against all known vulnerable versions, preventing them from being installed.

```bash
composer require --dev roave/security-advisories:dev-latest
```

Must always be pinned to `dev-latest` (never a tagged version).

Quick check: `composer update --dry-run roave/security-advisories`

See [Update Workflow Reference](references/update-workflow.md) for the complete step-by-step update process.

---

## Version Constraints

| Operator | Example | Range | Use Case |
|---|---|---|---|
| `^` (caret) | `^1.2.3` | `>=1.2.3 <2.0.0` | **Default for most dependencies** |
| `~` (tilde) | `~1.2.3` | `>=1.2.3 <1.3.0` | Conservative - patch updates only |
| `~` (minor) | `~1.2` | `>=1.2.0 <2.0.0` | Same as `^1.2` in practice |
| Exact | `1.2.3` | Only `1.2.3` | Avoid except for known regressions |
| `*` (wildcard) | `1.2.*` | `>=1.2.0 <1.3.0` | Avoid in production |

**Pre-1.0 packages:** The caret respects semver for unstable packages: `^0.3` means `>=0.3.0 <0.4.0`, and `^0.0.3` means `>=0.0.3 <0.0.4`.

---

## Lock File Management

| Rule | Reason |
|---|---|
| Always commit `composer.lock` for applications | Ensures identical versions across all environments |
| Use `composer install` in CI and production | Reads from lock file, guarantees reproducible builds |
| Use `composer update` only intentionally | Resolves constraints anew, writes new lock file |
| Never edit `composer.lock` manually | Let Composer manage it |
| Use `--no-dev` in production | Exclude development dependencies |
| Use `--optimize-autoloader` in production | Generate optimized class map |

Production install command:

```bash
composer install --no-dev --optimize-autoloader --no-interaction
```

---

## Abandoned Packages

Composer warns about abandoned packages during install/update. Handle them proactively:

1. **Check the warning** - some suggest a replacement package directly
2. **Search Packagist** for maintained alternatives
3. **Use `composer why vendor/package`** to understand who depends on it
4. **Wrap risky dependencies** behind interfaces (adapter pattern) to make future replacement easier
5. **Use `composer-unused`** to find packages in `composer.json` that are not actually used in code

---

## Quick Reference: Update Checklist

- [ ] Run `composer audit` to check for security vulnerabilities
- [ ] Run `composer outdated --direct` to see what needs updating
- [ ] Create a dedicated branch for the update
- [ ] Update one package or logical group at a time
- [ ] Run full test suite after each update
- [ ] Run static analysis (PHPStan/Psalm)
- [ ] Run `composer audit` again post-update
- [ ] Commit both `composer.json` and `composer.lock`
- [ ] Optionally run `composer bump` to raise lower bounds (apps only)
- [ ] Deploy via `composer install --no-dev --optimize-autoloader`
- [ ] Monitor application behavior after deployment

---

## Reference Files

| Reference | Contents |
|---|---|
| [Update Workflow](references/update-workflow.md) | Step-by-step update process, CI integration with Dependabot/Renovate, major update handling, and troubleshooting |
| [Dependency Strategies](references/dependency-strategies.md) | Versioning strategies, constraint selection, automated update tools configuration, and abandoned package handling |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Upgrading PHP version (may require dependency updates) | Use the `php-upgrade` playbook skill |
| Upgrading Symfony framework | Use the `symfony-upgrade` skill in `frameworks/symfony/` |
| Detecting N+1 query issues after ORM updates | Use the `detect-n-plus-one` skill |

---
name: composer-dependencies
description: Composer dependency management playbook for safe package updates. Use when the user asks to update Composer dependencies, audit packages for security vulnerabilities, manage composer.lock, configure Dependabot or Renovate for automated updates, replace abandoned packages, block insecure or abandoned versions with config.policy, or resolve version conflicts. Covers patch/minor/major update strategies, composer audit, semantic versioning constraints, lock file hygiene, and the changelog-first update workflow.
user-invocable: true
---

# Composer Dependencies Update

Dependency updates are maintenance, not features. Do them regularly in small batches rather than rarely in large ones. Every update follows the same cycle: audit, update, verify, commit.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before any major dependency update, search the web for the package's changelog or UPGRADE file, or ask the user for it. Never guess what changed |
| **Security first** | Run `composer audit` before and after every update. Vulnerabilities take priority over everything |
| **Small batches** | Update one package or one logical group at a time. Never update everything at once |
| **Lock file is truth** | Always commit `composer.lock`. Production uses `composer install`, never `composer update` |
| **Verify before merging** | Every update must pass the full test suite and static analysis before merging |
| **Caret by default** | Use `^` constraints for most dependencies. They balance stability with receiving fixes |

---

## First step: read the changelog

Before updating any dependency to a new major version, you MUST obtain the actual changelog:

1. **Search the web** for `{package-name} CHANGELOG` or `{package-name} UPGRADE guide` (e.g., `doctrine/orm UPGRADE.md github`)
2. **Or ask the user** to provide the changelog or release notes
3. **Check the package's GitHub repository** for `CHANGELOG.md`, `UPGRADE.md`, or release notes

This is required for major updates. Each package has its own breaking changes, and this skill cannot know them. For patch and minor updates, changelogs are recommended but do not block the update.

---

## Update strategies by risk level

| Strategy | Scope | Risk | Frequency | Command |
|---|---|---|---|---|
| **Patch only** | Bug fixes (1.2.3 -> 1.2.4) | Lowest | Weekly | `composer update --patch-only` |
| **Minor** | New features, backward-compatible (1.2 -> 1.3) | Low | Biweekly | `composer update --minor-only` |
| **Major** | Breaking changes possible (1.x -> 2.0) | Highest | Planned, one at a time | `composer update vendor/package --with-all-dependencies` |
| **Security** | Vulnerability fixes | Urgent | Immediately | `composer audit` then targeted update |

---

## Essential commands

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

## Security auditing

### composer audit

Built into Composer since 2.4. It checks locked versions against the advisory data from Packagist.org (or other repositories listed in `composer.json`), and reports abandoned packages.

```bash
composer audit
composer audit --locked --format=json
composer audit --abandoned=report
composer audit --ignore-severity=low --ignore-severity=medium
```

| Option | Effect |
|---|---|
| `--locked` | Audit `composer.lock` regardless of what is in `vendor/` |
| `--no-dev` | Skip `require-dev` packages |
| `--format` | `table` (default), `plain`, `json`, or `summary` |
| `--abandoned=ignore\|report\|fail` | How abandoned packages affect the exit code. Overrides config and `COMPOSER_AUDIT_ABANDONED` (since 2.8) |
| `--ignore-severity=<level>` | Ignore `low`, `medium`, `high` or `critical` advisories. Repeat the option for several levels (since 2.8) |

Abandoned packages fail the audit by default since Composer 2.7. Since 2.10 the exit code is `0` (clean) or `1` (anything failed), so a CI gate only needs to check for non-zero.

### Blocking insecure and abandoned packages

Since Composer 2.9, `composer update`, `require` and `remove` refuse package versions with known security advisories. Since 2.10, versions flagged as malware are also blocked, including on `composer install`. Configure all of it under `config.policy`:

```json
{
    "config": {
        "policy": {
            "advisories": {
                "block": true,
                "audit": "fail",
                "ignore-id": {
                    "PKSA-xxxx-xxxx-xxxx": "Not reachable from our code, fix scheduled."
                },
                "ignore-severity": ["low"]
            },
            "abandoned": {
                "block": true,
                "audit": "report",
                "ignore": {
                    "acme/legacy-lib": "Replacement planned for next quarter."
                }
            }
        }
    }
}
```

| Key | Default | Meaning |
|---|---|---|
| `policy.advisories.block` | `true` | Block versions with active advisories during `update`, `require`, `remove` |
| `policy.advisories.audit` | `fail` | `ignore`, `report` or `fail` for `composer audit` |
| `policy.advisories.ignore-id` | none | Advisory IDs (CVE, GHSA, PKSA), optionally with a reason and `on-block` / `on-audit` scoping |
| `policy.advisories.ignore`, `ignore-severity` | none | Package names (wildcards allowed) or severity levels to ignore |
| `policy.abandoned.block` | `false` | Block abandoned packages during `update`, `require`, `remove` |
| `policy.abandoned.audit` | `fail` | `ignore`, `report` or `fail` for `composer audit` |
| `policy.abandoned.ignore` | none | Packages to keep despite being abandoned |
| `policy.malware.block`, `block-scope` | `true`, `all` | Block flagged versions on `update`, `install` or both |

`config.policy` arrived in Composer 2.10. The older `config.audit` keys (`block-insecure`, `block-abandoned`, `ignore`, `ignore-severity`, `ignore-abandoned`, `abandoned`) still work but are deprecated. Composer reads them only when the matching `policy.advisories` or `policy.abandoned` section is absent, and it then ignores all legacy keys for that policy. Migrate them together, not one by one. If a project must support Composer 2.9 or older, keep using `config.audit`.

Always give an ignore entry a reason. An ignore without one hides the risk from the next reviewer.

### roave/security-advisories

A preventive complement to `composer audit`. It declares `conflict` rules against all known vulnerable versions, so they cannot be installed.

```bash
composer require --dev roave/security-advisories:dev-latest
```

Always pin it to `dev-latest`, never to a tagged version.

Quick check: `composer update --dry-run roave/security-advisories`

See [Update Workflow Reference](references/update-workflow.md) for the full step-by-step update process.

---

## Version constraints

| Operator | Example | Range | Use case |
|---|---|---|---|
| `^` (caret) | `^1.2.3` | `>=1.2.3 <2.0.0` | **Default for most dependencies** |
| `~` (tilde) | `~1.2.3` | `>=1.2.3 <1.3.0` | Conservative, patch updates only |
| `~` (minor) | `~1.2` | `>=1.2.0 <2.0.0` | Same as `^1.2` in practice |
| Exact | `1.2.3` | Only `1.2.3` | Avoid except for known regressions |
| `*` (wildcard) | `1.2.*` | `>=1.2.0 <1.3.0` | Avoid in production |

**Pre-1.0 packages:** The caret follows semver for unstable packages. `^0.3` means `>=0.3.0 <0.4.0`, and `^0.0.3` means `>=0.0.3 <0.0.4`.

---

## Lock file management

| Rule | Reason |
|---|---|
| Always commit `composer.lock` for applications | Gives identical versions in all environments |
| Use `composer install` in CI and production | Reads from the lock file, so builds are reproducible |
| Use `composer update` only intentionally | Resolves constraints anew and writes a new lock file |
| Never edit `composer.lock` manually | Let Composer manage it |
| Use `--no-dev` in production | Excludes development dependencies |
| Use `--optimize-autoloader` in production | Generates an optimized class map |

Production install command:

```bash
composer install --no-dev --optimize-autoloader --no-interaction
```

---

## Abandoned packages

Composer warns about abandoned packages during install and update, and `composer audit` fails on them by default. Deal with them early:

1. **Check the warning.** Some suggest a replacement package directly
2. **Run `composer audit --abandoned=report`** to list them without failing the build while you plan the work
3. **Search Packagist** for maintained alternatives
4. **Run `composer why vendor/package`** to see who depends on it
5. **Wrap risky dependencies** behind interfaces (adapter pattern) so they are easier to replace later
6. **Run `composer-unused`** to find packages in `composer.json` that the code does not use
7. **Set `policy.abandoned.block` to `true`** once the backlog is clear, so new abandoned dependencies cannot slip in. Use `policy.abandoned.ignore` with a reason for the ones you cannot replace yet

---

## Quick reference: update checklist

- [ ] Run `composer audit` to check for security vulnerabilities
- [ ] Run `composer outdated --direct` to see what needs updating
- [ ] Create a dedicated branch for the update
- [ ] Update one package or logical group at a time
- [ ] Run the full test suite after each update
- [ ] Run static analysis (PHPStan/Psalm)
- [ ] Run `composer audit` again after the update
- [ ] Commit both `composer.json` and `composer.lock`
- [ ] Optionally run `composer bump` to raise lower bounds (apps only)
- [ ] Deploy via `composer install --no-dev --optimize-autoloader`
- [ ] Monitor application behavior after deployment

---

## Reference Files

| Reference | Contents |
|---|---|
| [Update Workflow](references/update-workflow.md) | Step-by-step update process, CI integration with Dependabot/Renovate, major update handling, and troubleshooting |
| [Dependency Strategies](references/dependency-strategies.md) | Versioning strategies, constraint selection, automated update tool configuration, and abandoned package handling |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Upgrading PHP version (may require dependency updates) | Use the `php-upgrade` skill |
| Upgrading Symfony framework | Use the `symfony-upgrade` skill in `frameworks/symfony/` |
| Detecting N+1 query issues after ORM updates | Use the `detect-n-plus-one` skill |

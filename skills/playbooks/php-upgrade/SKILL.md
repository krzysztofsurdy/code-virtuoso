---
name: php-upgrade
description: Step-by-step PHP version upgrade playbook for PHP 8.0 through 8.4+ with automated tooling. Use when the user asks to upgrade PHP to a new version, check PHP compatibility, fix deprecation warnings, run Rector for automated refactoring, audit code with PHPCompatibility, or plan a PHP migration strategy. Covers breaking changes per version, php.ini configuration updates, extension compatibility, Rector rule sets, testing strategies, and the changelog-first upgrade workflow.
user-invocable: true
---

# PHP Version Upgrade

Upgrade one minor version at a time and never skip versions. Each step surfaces deprecations that become errors in the next release. Every upgrade follows the same cycle: audit, automate, test, deploy.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before any upgrade, search the web for the official PHP migration guide (php.net/migration) or ask the user for the changelog. Never rely on static knowledge alone |
| **One version at a time** | Upgrade 8.1 -> 8.2 -> 8.3 -> 8.4 in sequence. Skipping versions makes it impossible to isolate breakage |
| **Fix deprecations before upgrading** | Deprecations in version N become errors in version N+1, so treat them as mandatory fixes |
| **Automate first, manual second** | Run Rector and PHPCompatibility before touching code by hand. They catch 80%+ of required changes |
| **Prove it with tests** | An upgrade is not complete until the test suite passes on the target version |
| **Pin your platform** | Set `config.platform.php` in `composer.json` to match your lowest deployment target |

---

## Upgrade process overview

### Phase 0: Read the changelog

Before touching any code, obtain the actual changelog for the target PHP version:

1. **Search the web** for `PHP X.Y migration guide` (e.g., `PHP 8.4 migration guide php.net`)
2. **Or ask the user** to provide the changelog or release notes
3. **Read the official migration page** at `https://www.php.net/manual/en/migrationXY.php`

This step is required. Each version has its own changes, and this skill cannot capture them all.

### Phase 1: Audit

Before changing any code, find out how big the upgrade is.

1. **Run PHPCompatibility** against the target version to identify incompatible code
2. **Run php-parallel-lint** with the target PHP binary to catch syntax errors
3. **Run `composer outdated`** to check that all dependencies support the target version
4. **Review the official migration guide** at php.net for the target version
5. **Check PHP extensions** for compatibility (`ext-intl`, `ext-mbstring`, etc.)

### Phase 2: Automate

Use Rector to apply the bulk of the code transformations.

```php
// rector.php
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php84: true);  // adjust to target version
```

Always dry-run first:

```bash
vendor/bin/rector process --dry-run
```

Review the changes, then apply them:

```bash
vendor/bin/rector process
```

Commit Rector changes separately from manual fixes to keep the git history clean.

### Phase 3: Update dependencies

1. Update `composer.json` with the new PHP version constraint: `"php": ">=8.4"`
2. Update `config.platform.php` to match the target version
3. Run `composer update` and resolve conflicts
4. Update PHP extensions as needed

### Phase 4: Test and deploy

1. Run the full test suite under the new PHP version
2. Run static analysis (PHPStan/Psalm)
3. Deploy to staging and verify
4. Monitor production logs for deprecation notices after deployment

See [Upgrade Process Reference](references/upgrade-process.md) for tool configuration, CI pipeline setup, and Docker considerations.

---

## Tools

| Tool | Purpose | When to use |
|---|---|---|
| **Rector** | Automated AST-based code transformation | First step after auditing. Handles most mechanical changes |
| **PHPCompatibility** | PHP_CodeSniffer ruleset for cross-version compatibility | Audit phase. Identifies all incompatible code before you start |
| **php-parallel-lint** | Parallel syntax checking (~20x faster than serial) | Audit phase. Catches syntax errors under the new version |
| **PHPStan/Psalm** | Static analysis | Verification phase. Catches type errors after transformation |
| **symfony/phpunit-bridge** | Deprecation summary in test output | Ongoing. Tracks the deprecation count during upgrades |

---

## Breaking changes by version

| Transition | Key breaking changes |
|---|---|
| **8.0 -> 8.1** | Fibers introduced, enums added, readonly properties, intersection types, `never` return type |
| **8.1 -> 8.2** | Dynamic properties deprecated (use `#[AllowDynamicProperties]` temporarily), `$GLOBALS` access restrictions, readonly classes, disjunctive normal form types |
| **8.2 -> 8.3** | Typed class constants, `json_validate()` added, `#[Override]` attribute, `Randomizer` additions, date/time exception changes |
| **8.3 -> 8.4** | Implicit nullable types deprecated (`function foo(string $bar = null)` must become `?string $bar = null`), property hooks, asymmetric visibility, `new Foo()->method()` allowed without wrapping parentheses, new `Dom` namespace classes (the old DOM classes remain), `E_STRICT` and `trigger_error()` with `E_USER_ERROR` deprecated, session ini and `session_set_save_handler()` deprecations |

See [Version Changes Reference](references/version-changes.md) for per-version details with code examples.

---

## Common pitfalls

| Pitfall | Why it hurts | Prevention |
|---|---|---|
| Skipping versions | You cannot isolate which changes broke what | Always upgrade one version at a time |
| Ignoring deprecation warnings | Deprecations become fatal errors in the next version | Fix all deprecations before upgrading |
| Not checking dependencies | Third-party packages may not support the target version | Run `composer outdated` and check support before starting |
| Using `--ignore-platform-reqs` | Bypasses safety checks and causes runtime errors | Never use it. Fix the actual constraints instead |
| Not pinning `config.platform.php` | Local PHP differs from production, causing install mismatches | Always set it to match production |
| Large unreviewed Rector runs | Rector can make incorrect transformations in edge cases | Always dry-run first, review changes, run on small batches |
| Forgetting PHP extensions | Extensions change behavior or get deprecated between versions | Audit all required extensions before upgrading |

---

## Quick reference: upgrade checklist

- [ ] Review php.net migration guide for target version
- [ ] Run PHPCompatibility scan against target version
- [ ] Run php-parallel-lint with target PHP binary
- [ ] Verify all Composer dependencies support target version
- [ ] Configure and run Rector with target version set (dry-run first)
- [ ] Review and commit Rector changes
- [ ] Apply manual fixes for remaining issues
- [ ] Update `composer.json` PHP constraint and `config.platform.php`
- [ ] Run `composer update`
- [ ] Run full test suite on target PHP version
- [ ] Run static analysis (PHPStan/Psalm)
- [ ] Deploy to staging and verify
- [ ] Deploy to production and monitor logs

---

## Reference Files

| Reference | Contents |
|---|---|
| [Upgrade Process](references/upgrade-process.md) | Tool configuration, CI pipeline setup, Docker strategy, and step-by-step commands |
| [Version Changes](references/version-changes.md) | Per-version breaking changes, new features, and deprecations with code examples (PHP 8.0 through 8.4) |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Upgrading Symfony alongside PHP | Use the `symfony-upgrade` skill in `frameworks/symfony/` |
| Updating Composer dependencies after PHP upgrade | Use the `composer-dependencies` playbook skill |
| Modernizing PHP code patterns (DTOs, enums, strict types) | Install `php-modernization` from `dirnbauer/webconsulting-skills` or `netresearch/php-modernization-skill` |
| Running static analysis after upgrade | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies |

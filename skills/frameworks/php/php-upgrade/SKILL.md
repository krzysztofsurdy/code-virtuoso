---
name: php-upgrade
description: Step-by-step PHP upgrade playbook for hops from 7.4 to 8.5, with known traps per version, Rector rule sets, and a CI matrix. Use to upgrade PHP, fix deprecations, check compatibility, or plan a PHP migration.
user-invocable: true
---

# PHP Version Upgrade

Upgrade one minor version at a time and never skip versions. Each step surfaces deprecations that become errors in the next release. Every upgrade follows the same cycle: audit, automate, test, deploy.

## Core Principles

| Principle | Meaning |
|---|---|
| **Changelog first** | Before each hop, fetch the official php.net migration guide for that hop. Never rely on a static list in this skill or in model memory |
| **One version at a time** | Upgrade 8.2 -> 8.3 -> 8.4 -> 8.5 in sequence. Skipping versions makes it impossible to isolate breakage |
| **Fix deprecations before upgrading** | Deprecations in version N become errors in version N+1, so treat them as mandatory fixes |
| **Automate first, manual second** | Run Rector and PHPCompatibility before touching code by hand. They catch 80%+ of required changes |
| **Prove it with tests** | An upgrade is not complete until the test suite passes on the target version |
| **Pin your platform** | Set `config.platform.php` in `composer.json` to match your lowest deployment target |

---

## Upgrade process overview

### Phase 0: Read the migration guide

Before touching any code, read the official guide for every hop between the current and target version. Each hop has its own page, named `migrationXY` after the target version:

| Hop | Page |
|---|---|
| 7.4 -> 8.0 | `https://www.php.net/manual/en/migration80.php` |
| 8.4 -> 8.5 | `https://www.php.net/manual/en/migration85.php` |

Each guide has sub-pages: `migrationXY.incompatible.php` (backward incompatible changes), `migrationXY.deprecated.php`, and `migrationXY.removed-extensions.php` where it exists. Read at least the first two.

How to fetch them:

1. **Use the `docs-lookup` skill.** For PHP it resolves to the Context7 library ID `/websites/php_net_manual_en`. Ask for "Migrating from PHP X.Y to X.Z, backward incompatible changes and deprecated features"
2. **Fallback:** fetch the php.net URLs above directly, or ask the user for the release notes
3. **Write down what applies.** Grep the codebase for each listed item and keep the hits as the work list for the Automate and manual-fix steps

The table under "Known traps by version" is a starting point for the grep, not a replacement for the guide.

### Phase 1: Audit

Before changing any code, find out how big the upgrade is.

1. **Run PHPCompatibility** against the target version to identify incompatible code. The last stable release (9.3.5, 2019) predates PHP 8.1 and misses most newer rules. Install `10.0.0-alpha2` or later, which has PHP 8.x sniffs, and read its upgrade notes first
2. **Run php-parallel-lint** with the target PHP binary to catch syntax errors
3. **Run `composer outdated`** to check that all dependencies support the target version
4. **Check your list** from Phase 0 against the code
5. **Check PHP extensions** for compatibility (`ext-intl`, `ext-mbstring`, etc.)

### Phase 2: Automate

Use Rector to apply the bulk of the code transformations.

```php
// rector.php
use Rector\Config\RectorConfig;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/src', __DIR__ . '/tests'])
    ->withPhpSets(php85: true);  // adjust to target version
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

1. Update `composer.json` with the new PHP version constraint: `"php": ">=8.5"`
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

## Known traps by version

Items that most often break real upgrades. Each one is taken from the php.net migration pages for that hop. Fetch the full guide (Phase 0) for everything else.

| Hop | Traps |
|---|---|
| 7.4 -> 8.0 | `0 == "abc"` is now false (number is cast to string). Arithmetic on arrays, resources, or objects throws `TypeError`. `@` no longer silences fatal errors. Undefined variable, key, and property reads are warnings. Undefined bare constants throw `Error`. `create_function()` and `each()` removed. `.` now binds looser than `+` and `-` |
| 8.0 -> 8.1 | Passing `null` to non-nullable built-in parameters is deprecated. Float to int conversions that lose precision are deprecated. `Serializable` without `__serialize()` and `__unserialize()` is deprecated. Inherited methods share `static` variables with the parent. Appending to `false` is deprecated. Writing to the whole `$GLOBALS` array is an error |
| 8.1 -> 8.2 | Dynamic properties are deprecated (declare them, or add `#[\AllowDynamicProperties]`). `"${var}"` interpolation is deprecated. `utf8_encode()` and `utf8_decode()` are deprecated. Callables like `"self::method"` are deprecated. `strtolower()`, `ucfirst()`, and similar are no longer locale-sensitive |
| 8.2 -> 8.3 | `++` and `--` on empty or non-alphanumeric strings are deprecated. `get_class()` without arguments is deprecated. Date extension errors are now `DateError` and `DateException` types instead of warnings. Traits with static properties redeclare the parent's property. A negative index on an empty array makes the next key `n+1` |
| 8.3 -> 8.4 | Implicitly nullable parameters (`T $x = null`) are deprecated, use `?T`. `E_STRICT` and `trigger_error()` with `E_USER_ERROR` are deprecated. `exit()` is type-checked. IMAP, OCI8, PDO_OCI, and PSpell moved to PECL. `GMP` is final. A class named `_` is deprecated. `0 ** -1` is deprecated |
| 8.4 -> 8.5 | Opcache is always built in, and `zend_extension=opcache.so` now warns, so remove it from `php.ini` and Docker configs. The backtick operator, `(boolean)`, `(integer)`, `(double)`, and `(binary)` casts, `null` array offsets, and `case x;` are deprecated. `__sleep()` and `__wakeup()` are soft-deprecated. `disable_classes` INI removed. Traits bind before the parent class. Casting a float that does not fit an int now warns |

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

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Looking up the migration guide for a hop | Use the `docs-lookup` skill |
| Upgrading Symfony alongside PHP | Use the `symfony-upgrade` skill in `frameworks/symfony/` |
| Updating Composer dependencies after PHP upgrade | Use the `composer-dependencies` skill |
| Modernizing PHP code patterns (DTOs, enums, strict types) | Install `php-modernization` from `dirnbauer/webconsulting-skills` or `netresearch/php-modernization-skill` |
| Running static analysis after upgrade | `testing` |

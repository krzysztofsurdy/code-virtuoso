# Research notes: php-quality (static analysis, code style, modern PHP idioms)

Date: 2026-10-22
Depth: standard
Research skill used: no (inline, WebFetch, WebSearch-free, gh api, curl, Context7 not needed)
Prior-art search: done
Confirmation gates: approved by the maintainer in the build brief.

## Scope

Covers: PHPStan levels 0-10, bleeding edge, baseline strategy, extensions, PHPDoc generics, ignore identifiers; Psalm vs PHPStan; PHP-CS-Fixer vs PHP_CodeSniffer with PER-CS 3.x and the PSR-12 relation; Rector quality sets (not upgrades, which stay in php-upgrade); modern idioms for PHP 8.3 to 8.5 (readonly classes, enums, typed class constants, #[\Override], property hooks, asymmetric visibility, pipe operator, clone with, #[\NoDiscard]); PHP-FIG status table.
Not covered: upgrade procedure (php-upgrade), Composer (composer-dependencies), Symfony specifics, PHPUnit.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://phpstan.org/user-guide/rule-levels | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/user-guide/baseline | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/user-guide/ignoring-errors | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/user-guide/extension-library | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/blog/what-is-bleeding-edge | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/blog/phpstan-2-0-released-level-10-elephpants | official | PHPStan | 2024-11-11 | 2026-10-22 |
| https://phpstan.org/blog/upgrading-from-phpstan-1-to-2 | official | PHPStan | 2024-11 | 2026-10-22 |
| https://phpstan.org/blog/generics-in-php-using-phpdocs | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/blog/phpstans-baseline-feature-lets-you-hold-new-code-to-a-higher-standard | official | PHPStan | unknown | 2026-10-22 |
| https://phpstan.org/config-reference (source: github.com/phpstan/phpstan website/src/config-reference.md) | official | PHPStan | live | 2026-10-22 |
| https://github.com/phpstan/phpstan (releases, composer.json) | official | PHPStan | 2.3.1 on 2026-10-08 | 2026-10-22 |
| https://github.com/phpstan/phpstan-symfony, phpstan-doctrine, phpstan-strict-rules (READMEs, releases) | official | PHPStan | 2026-10 | 2026-10-22 |
| https://github.com/vimeo/psalm (releases, README, docs/running_psalm/error_levels.md, installation.md) | official | Psalm | 7.0.0-rc6 on 2026-10-20 | 2026-10-22 |
| https://www.php-fig.org/psr/ | standard | PHP-FIG | live | 2026-10-22 |
| https://www.php-fig.org/psr/psr-12/ | standard | PHP-FIG | 2019 | 2026-10-22 |
| https://www.php-fig.org/per/ and https://www.php-fig.org/per/coding-style/ | standard | PHP-FIG | 3.1 | 2026-10-22 |
| https://www.php-fig.org/per/coding-style/meta/migration-2.0, migration-3.0, migration-3.1 | standard | PHP-FIG | live | 2026-10-22 |
| https://github.com/PHP-CS-Fixer/PHP-CS-Fixer (README, doc/ruleSets/*, src/Config.php, releases) | official | PHP-CS-Fixer | v3.95.27 on 2026-09-22 | 2026-10-22 |
| https://cs.symfony.com/doc/usage.html | official | PHP-CS-Fixer | live | 2026-10-22 |
| https://github.com/PHPCSStandards/PHP_CodeSniffer (releases, src/Standards, PR 1265) and https://github.com/squizlabs/PHP_CodeSniffer README | official | PHPCSStandards | 4.0.4 on 2026-08-06 | 2026-10-22 |
| https://getrector.com/documentation/levels and github.com/rectorphp/rector-src RectorConfigBuilder.php | official | Rector | 2.7.0 on 2026-10-06 | 2026-10-22 |
| https://www.php.net/releases/8.3/en.php, 8.4, 8.5 | official | PHP | 2023-11, 2024-11, 2025-11 | 2026-10-22 |
| https://www.php.net/manual/en/language.oop5.properties.php, .property-hooks.php, .visibility.php, .basic.php, .constants.php | official | PHP | live | 2026-10-22 |
| https://www.php.net/manual/en/language.enumerations.methods.php, .traits.php | official | PHP | live | 2026-10-22 |
| https://www.php.net/manual/en/class.override.php, class.nodiscard.php, language.operators.functional.php | official | PHP | live | 2026-10-22 |
| https://www.php.net/supported-versions.php | official | PHP | live | 2026-10-22 |
| ~/.agents/skills/php-pro, ~/.agents/skills/psr-overview-knowledge | local | third party | 2026-02/04 | 2026-10-22 |

## Prior art

Queries: `npx skills find "phpstan"`, `npx skills find "php"`, `gh search code "analyse-with-phpstan" --filename SKILL.md`, `gh api repos/.../contents` reads of each SKILL.md. Local: skills/frameworks/php/, ~/.agents/skills.

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| phpstan/phpstan@analyse-with-phpstan | https://github.com/phpstan/phpstan/blob/2.3.x/.claude/skills/analyse-with-phpstan/SKILL.md | official | 242 installs, repo pushed 2026-10-22 | Runs code through the PHPStan playground API and tabulates errors per PHP version | Correct (defaults to level 10), official, concrete steps | Not a guide: no level strategy, baseline, style, Rector or idioms. Sends code to a remote API | MIT (repo) |
| jeffallan/claude-skills@php-pro (and local ~/.agents/skills/php-pro) | https://skills.sh/jeffallan/claude-skills/php-pro | community | 15.4K installs, 1.1.0 | Whole-language PHP 8.3+ plus Laravel/Symfony code patterns | Popular, readonly DTO and enum examples, verification step | Says "Run PHPStan level 9" and treats 9 as the target (level 10 exists since 2.0, 2024-11-11). "MUST follow PSR-12" (superseded by PER-CS). Textbook patterns the model knows. Broad, no decision rules. Triggers on every PHP task | MIT |
| local psr-overview-knowledge | ~/.agents/skills/psr-overview-knowledge/SKILL.md | community | local, 2026-02 | PSR catalogue | Lists accepted PSRs | Lists PSR-12 as the coding-style standard (`phpcs --standard=PSR12`) with no mention of PER-CS; no PSR-2 deprecation; PSR-20 listed, PSR-5/19/21/22 drafts not flagged | none stated |
| asyrafhussin/agent-skills@php-best-practices | https://github.com/asyrafhussin/agent-skills/blob/main/skills/php-best-practices/SKILL.md | community | 3.6K installs, 92 stars, pushed 2026-08-27 | 51 rules on PHP 8.0-8.5 features, PSR, SOLID | Version-gated feature table that matches php.net (8.3 typed constants and #[\Override], 8.4 hooks, 8.5 pipe) | Lists "psr-12-coding-style" as the rule; no static analysis or tooling decisions; mostly textbook | MIT |
| dev-toolings/superpowers-symfony@symfony:quality-checks | https://skills.sh/dev-toolings/superpowers-symfony/symfonyquality-checks | community | 622 installs | Symfony change workflow | Checkpointed process | Body shown is generic workflow, no tool facts | not checked |
| dirnbauer/webconsulting-skills@php-modernization | https://github.com/dirnbauer/webconsulting-skills/tree/main/skills/php-modernization | community | 98 installs, 33 stars | Script-driven modernization (introspect, modernize_loop) with references | Tooling scripts and dry-run discipline | Depends on uv and its own scripts, TYPO3 leaning; license NOASSERTION | NOASSERTION |

Decision: write a new skill. No official or clearly better skill covers the need. The only official one is a playground runner.

Strengths adopted (as ideas, nothing copied): php-best-practices' version-gating of features; analyse-with-phpstan's level 10 default and error-identifier habit; php-modernization's dry-run-first discipline. Weaknesses avoided: level 9 as the ceiling, PSR-12 as current, whole-language scope, textbook examples, undated status claims. Gap filled: tool decision table plus verified status facts (PSR-12 vs PER-CS, Psalm 7, PHPCS vs PHP-CS-Fixer PER support), baseline policy, Rector quality levels.

## Claim checks requested in the brief

- "PHPStan level 9 is the max" (php-pro): FALSE. Level 10 exists (rule-levels page, 2.0 blog).
- "PSR-12 is current" (php-pro, psr-overview-knowledge, php-best-practices): PARTLY STALE. php-fig.org/psr/ still lists PSR-12 as Accepted (not Deprecated), but PER Coding Style 3.1 states it "extends, expands and replaces PSR-12" and PHP-FIG's own PSR-12 page links to it. PSR-2 is Deprecated. New projects should target PER-CS.

## Fact ledger

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | PHPStan has levels 0-10, cumulative; level 10 is new in 2.0 and treats implicit mixed strictly; level 9 covers explicit mixed | https://phpstan.org/user-guide/rule-levels | 2026-10-22 | 2.x | confirmed | read page + 2.0 blog |
| 2 | PHPStan 2.0 released 2024-11-11 | https://phpstan.org/blog/phpstan-2-0-released-level-10-elephpants | 2026-10-22 | 2.0 | likely | one page (blog) |
| 3 | PHPStan needs PHP 7.4+ to run; latest 2.3.1 (2026-10-08) | https://phpstan.org/blog/upgrading-from-phpstan-1-to-2, https://github.com/phpstan/phpstan | 2026-10-22 | 2.3.1 | confirmed | blog + composer.json (`^7.4|^8.0`) |
| 4 | `--level max` always uses the highest level; page advises against it unless ready for upgrades | https://phpstan.org/user-guide/rule-levels | 2026-10-22 | 2.x | likely | one page |
| 5 | Baseline: `--generate-baseline` writes phpstan-baseline.neon; stores message, count, path; "life goal ... is to not exist"; regenerating to absorb new errors is discouraged; suits dozens to hundreds of errors, not 15,000; `.php` extension option; inline `@phpstan-ignore` preferred for kept ignores | https://phpstan.org/user-guide/baseline, https://phpstan.org/blog/phpstans-baseline-feature-lets-you-hold-new-code-to-a-higher-standard | 2026-10-22 | 2.x | confirmed | two pages (second page does not repeat the "life goal" quote, repeats the size guidance) |
| 6 | reportUnmatchedIgnoredErrors reports baseline/ignore entries that no longer match | https://phpstan.org/user-guide/ignoring-errors | 2026-10-22 | 2.x | confirmed | two pages |
| 7 | `@phpstan-ignore identifier (reason)` syntax; `@phpstan-ignore-line` and `-next-line` still supported but forbidden when reportIgnoresWithoutComments is true | https://phpstan.org/user-guide/ignoring-errors | 2026-10-22 | 2.x | likely | one page |
| 8 | Bleeding edge: `includes: - phar://phpstan.phar/conf/bleedingEdge.neon`; ships new rules disabled by default; features reach everyone in the next major; config reference marks some options "Requires Bleeding Edge until PHPStan 3.0" | https://phpstan.org/blog/what-is-bleeding-edge, config-reference.md in github.com/phpstan/phpstan | 2026-10-22 | 2.x | confirmed | two pages |
| 9 | Official extensions: phpstan-strict-rules, phpstan-deprecation-rules, phpstan-symfony, phpstan-doctrine, phpstan-phpunit; install via phpstan/extension-installer or manual includes | https://phpstan.org/user-guide/extension-library | 2026-10-22 | n/a | confirmed | page + READMEs |
| 10 | phpstan-symfony: `parameters.symfony.containerXmlPath`, `consoleApplicationLoader`; underscore option names removed in 2.0 | https://github.com/phpstan/phpstan-symfony, upgrading-from-phpstan-1-to-2 | 2026-10-22 | 2.1.0 | confirmed | README + blog |
| 11 | phpstan-doctrine: `parameters.doctrine.objectManagerLoader` enables DQL validation and result type inference; rules.neon needed for DQL/QueryBuilder validation | https://github.com/phpstan/phpstan-doctrine | 2026-10-22 | 2.0.28 | confirmed | README |
| 12 | PHPDoc generics tags: @template (with `of` bound, `=` default), @template-covariant, @extends, @implements, @use, class-string<T> | https://phpstan.org/blog/generics-in-php-using-phpdocs | 2026-10-22 | 2.x | confirmed | read page |
| 13 | `treatPhpDocTypesAsCertain` default true; false relaxes checks for libraries | https://phpstan.org/config-reference | 2026-10-22 | 2.x | confirmed | config-reference.md |
| 14 | Psalm: levels 1 (strictest) to 8, default 2; taint analysis via --taint-analysis; stable line 6.20.1 (2026-10-20), 7.0.0-rc6 prerelease (2026-10-20); README names one active maintainer | https://github.com/vimeo/psalm | 2026-10-22 | 6.20.1 / 7.0.0-rc6 | confirmed | docs + releases API + README |
| 15 | Psalm is not archived, pushed 2026-10-22 | https://github.com/vimeo/psalm | 2026-10-22 | n/a | confirmed | gh api |
| 16 | PSR-12 listed Accepted; PSR-2 and PSR-0 Deprecated; PSR-5, 19, 21, 22 Draft; PSR-8, 9, 10 Abandoned; PSR-20 Clock Accepted | https://www.php-fig.org/psr/ | 2026-10-22 | n/a | confirmed | HTML read twice (WebFetch + curl) |
| 17 | PER Coding Style 3.1 "extends, expands and replaces PSR-12", requires PSR-1; PSR-12 accepted 2019; PER-CS is a PER (evolving recommendation), not a PSR | https://www.php-fig.org/per/coding-style/, https://www.php-fig.org/per/ | 2026-10-22 | 3.1 | confirmed | two pages |
| 18 | PER-CS 3.0 adds compound type formatting, naming advice, lowercase `<?php`, `new` without parentheses on 8.4+, set-visibility rule; 3.1 adds clone() parentheses, switch/case/match rules, pipe operator formatting, empty closure rule; 2.0 added trailing commas, empty body `{}` | https://www.php-fig.org/per/coding-style/meta/migration-3.0, migration-3.1, migration-2.0 | 2026-10-22 | 3.1 | confirmed | read three pages |
| 19 | PHP-CS-Fixer rule sets: `@PER-CS` is an alias for the latest, currently `@PER-CS3x0`; `@PER-CS3.0` and `@PER` deprecated, removed in 4.0; `@PER-CS3x0Risky` exists; no 3.1 rule set listed; `@Symfony` extends `@PER-CS` | https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/tree/master/doc/ruleSets | 2026-10-22 | v3.95.27 | confirmed | read rst files and directory listing |
| 20 | PHP-CS-Fixer supports PHP 7.4 to 8.5; `Config::setRiskyAllowed`, `setParallelConfig`; `check` is shorthand for `fix --dry-run`; `--diff`; no config file defaults to @PSR12 | https://github.com/PHP-CS-Fixer/PHP-CS-Fixer README, https://cs.symfony.com/doc/usage.html, src/Config.php | 2026-10-22 | v3.95.27 | confirmed | README + usage page + source |
| 21 | PHP_CodeSniffer: squizlabs repo abandoned, successor PHPCSStandards; 4.0.0 released 2025-09-16, 4.0.4 on 2026-08-06; bundled standards are Generic, PEAR, PSR1, PSR12, PSR2, Squiz, Zend (no PER); PER 3.0 ruleset PR 1265 closed not merged | https://github.com/PHPCSStandards/PHP_CodeSniffer | 2026-10-22 | 4.0.4 | confirmed | README banner, releases API, directory listing, PR API |
| 22 | Rector prepared sets via withPreparedSets(deadCode, codeQuality, codingStyle, typeDeclarations, typeDeclarationDocblocks, privatization, naming (deprecated), instanceOf/if/earlyReturn (deprecated), phpunitCodeQuality, doctrineCodeQuality, symfonyCodeQuality ...) | https://github.com/rectorphp/rector-src RectorConfigBuilder.php | 2026-10-22 | 2.7.0 | confirmed | source read |
| 23 | Rector levels: withTypeCoverageLevel, withTypeCoverageDocblockLevel (since 2.2), withDeadCodeLevel, withCodeQualityLevel, withCodingStyleLevel, withPhpLevel; start at 0 and raise by 1 per PR | https://getrector.com/documentation/levels, RectorConfigBuilder.php | 2026-10-22 | 2.7.0 | confirmed | page + source |
| 24 | Rector 2.7.0 requires phpstan/phpstan ^2.3.0, PHP ^7.4|^8.0 | https://github.com/rectorphp/rector composer.json | 2026-10-22 | 2.7.0 | confirmed | composer.json |
| 25 | Readonly properties 8.1 (typed, no default, init once from declaring scope; implicit protected(set) from 8.4; reinit in __clone since 8.3); readonly classes 8.2 (all props readonly, no static or untyped props, no AllowDynamicProperties, child must be readonly) | https://www.php.net/manual/en/language.oop5.properties.php, https://www.php.net/manual/en/language.oop5.basic.php | 2026-10-22 | 8.1-8.4 | confirmed | two manual pages |
| 26 | Enums (8.1) may implement interfaces (interface goes after backing type), have methods, use traits without properties, constants | https://www.php.net/manual/en/language.enumerations.methods.php, ...traits.php | 2026-10-22 | 8.1+ | confirmed | two pages; "since 8.1" from enum intro (php.net manual, not re-fetched, widely known) |
| 27 | Typed class constants 8.3; dynamic class constant fetch 8.3; visibility checked against interface constants in 8.3 | https://www.php.net/manual/en/language.oop5.constants.php, https://www.php.net/releases/8.3/en.php | 2026-10-22 | 8.3 | confirmed | two pages |
| 28 | #[\Override] 8.3 on methods (compile error if no parent member), 8.5 on properties, not on __construct | https://www.php.net/manual/en/class.override.php | 2026-10-22 | 8.3/8.5 | confirmed | manual + release pages (8.5 page lists it) |
| 29 | Property hooks 8.4: get/set, non-static only, not with readonly, backed vs virtual, set parameter type contravariant, parent::$prop::get(), final hooks | https://www.php.net/manual/en/language.oop5.property-hooks.php | 2026-10-22 | 8.4 | confirmed | manual + release page |
| 30 | Asymmetric visibility 8.4: typed properties only, set visibility same or narrower, private(set) implies final, reference follows set visibility; static properties allowed in 8.5 | https://www.php.net/manual/en/language.oop5.visibility.php | 2026-10-22 | 8.4/8.5 | confirmed | manual + release page |
| 31 | PHP 8.5 released 2025-11-20: pipe operator, clone with, #[\NoDiscard] with (void) cast, array_first/array_last, closures in constant expressions, URI extension | https://www.php.net/releases/8.5/en.php | 2026-10-22 | 8.5 | confirmed | release page + manual pages |
| 32 | Pipe operator: single-parameter callable on RHS, no by-ref params, arrow functions must be parenthesized | https://www.php.net/manual/en/language.operators.functional.php | 2026-10-22 | 8.5 | confirmed | manual + RFC-consistent release example |
| 33 | PHP 8.4 adds #[\Deprecated], new without parentheses, array_find/array_find_key/array_any/array_all | https://www.php.net/releases/8.4/en.php | 2026-10-22 | 8.4 | confirmed | release page |
| 34 | Supported versions: 8.3 active until 2025-12-31 (security to 2027-12-31), 8.4 active to 2026-12-31, 8.5 active to 2027-12-31 | https://www.php.net/supported-versions.php | 2026-10-22 | n/a | confirmed | page |

## Not confirmed

- "Enums were introduced in 8.1" came from the manual's enum pages not stating the version in fetched text; widely documented and consistent with the PER and release pages. Kept, marked likely.
- Rector ordering advice (run Rector before the code style fixer) is a judgment, not a source claim. Written as a recommendation without citation.
- PHPStan `--level max` page advice was read once. Kept as a pointer.
- Psalm minimum PHP: composer.json (master) and docs disagree (>=8.2 vs ~8.1.31). Not stated in the skill.
- PHPCS 4.0 PHP minimum not read. Not stated.
- Rector `rectorPreset`, `carbon` sets not described. Left out.
- PHPStan Pro and Psalm plugins left out.
- phpstan.org/blog/what-is-bleeding-edge page does not name the next major; the config reference says "until PHPStan 3.0". Skill says "next major".

## Left out

PHPStan custom rules, result cache tuning, Psalm taint details, PSR catalogue beyond status, Laravel extensions (larastan), enum examples and DTO patterns (model knows), design pattern discussions.

## Verification by running (Phase 4)

Run on PHP 8.5.10 in a local sandbox (s3-php-quality/t*.php, proj/): every PHP snippet in modern-idioms.md executed as written (readonly class with clone-with, enum with interface and tryFrom, typed constants, #[\Override], hooks, private(set), pipe, #[\NoDiscard] with (void), array_first/array_last). Negative checks confirmed: hooked readonly property is a fatal error; `protected public(set)` is a compile error; non-readonly class extending a readonly class is a fatal error; unparenthesized arrow function after `|>` is a fatal error.
Installed phpstan 2.3.1, php-cs-fixer 3.95.27, rector (2.7.x) in a scratch project: `level: 10` config with baseline include ran; `--generate-baseline` wrote entries with message, identifier, count, path; second run reported no errors; `@PER-CS3x0` plus `@PER-CS3x0:risky` config with `setRiskyAllowed(true)` ran under `check --diff`; Rector level config ran under `process --dry-run`. The generics snippet (`class-string<T>`, `@implements IteratorAggregate<int, Repo>`) analysed clean at level 10.

Additional ledger rows:

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 35 | Psalm 6.20.1 release notes: reads `@phpstan-require-extends` and `@phpstan-require-implements` ("reads some phpstan tags") | https://github.com/vimeo/psalm/releases/tag/6.20.1 | 2026-10-22 | 6.20.1 | likely | release notes |
| 36 | Psalm taint analysis flag `--taint-analysis` | https://github.com/vimeo/psalm/blob/master/docs/running_psalm/error_levels.md | 2026-10-22 | 6.x/7.x | confirmed | docs text; 7.0 RC notes show taint work |
| 37 | Generated baseline entries include `identifier` in 2.3.1 | local run | 2026-10-22 | 2.3.1 | confirmed | ran command |
| 38 | PHP-CS-Fixer: `@PER-CS3x0:risky` is the config name of the risky set | https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/blob/master/doc/ruleSets/PER-CS3x0Risky.rst | 2026-10-22 | v3.95.27 | confirmed | rst file + ran config |

Gate note: the PHPStan docs for 2.3 print "do not add baseline entries or ignores" guidance in the default output when run (observed). Not used as a ledger fact.

Convention note: the repo checklist says no dates in skill text. The brief asks for the retrieval date with each fact. Dates are in this ledger; the only dated line in the skill is the status line of references/php-fig-status.md, which is a status snapshot.

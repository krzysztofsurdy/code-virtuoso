# Research notes: symfony-testing

Date: 2026-10-22
Confirmation gates: approved by the maintainer in the build brief.
Research skill used: no (inline, with gh api, WebFetch and a throwaway Symfony 8.1 project)
Prior-art search: done

## Scope

A background framework skill (user-invocable: false) for testing in Symfony 7.4 and 8.x with PHPUnit 11, 12 and 13. It covers the version matrix, a decision table for the test type, a Symfony-specific "which test first" loop, and pitfalls. Topics: attributes-only PHPUnit, static data providers, KernelTestCase vs WebTestCase vs ApiTestCase, getContainer() and private services, loginUser, test env and .env.test, Foundry v2, DAMA rollback, Panther, Messenger in-memory and test transports, MockHttpClient, MockClock, mailer assertions.

Out of scope: the generic red-green-refactor procedure (skill `tdd`), test strategy and test doubles theory (skill `testing`), Doctrine mapping (another agent owns doctrine-orm), API Platform resource design.

Questions answered: which PHPUnit and Symfony versions are maintained and what each changes in tests; what the docs and the bundle READMEs say; which claims fail when run.

## Sources

All retrieved 2026-10-22. Symfony docs were read as RST from github.com/symfony/symfony-docs at branches 7.4 and 8.1 (the rendered pages on symfony.com are built from them). Bundle docs were read from the bundle repositories.

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://symfony.com/releases | official | Symfony | live | 2026-10-22 |
| https://symfony.com/doc/current/testing.html | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/http_client.html#testing | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/components/clock.html | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/messenger.html#in-memory-transport | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/mailer.html | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/console.html#testing-commands | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://symfony.com/doc/current/testing/end_to_end.html | official | Symfony | live (8.1 branch) | 2026-10-22 |
| https://github.com/symfony/symfony/blob/8.1/src/Symfony/Bundle/FrameworkBundle/Test/KernelTestCase.php and WebTestCase.php | official source | Symfony | 8.1 branch | 2026-10-22 |
| https://github.com/symfony/symfony/blob/8.1/src/Symfony/Component/Clock/Test/ClockSensitiveTrait.php | official source | Symfony | 8.1 branch | 2026-10-22 |
| https://github.com/symfony/recipes/tree/main/phpunit/phpunit/11.1 | official | Symfony | main | 2026-10-22 |
| https://phpunit.de/supported-versions.html | official | Sebastian Bergmann | live | 2026-10-22 |
| https://github.com/sebastianbergmann/phpunit (ChangeLog-10.0, 11.0, 12.0, 12.5, 13.0 .md) | official | Sebastian Bergmann | tags 10.0.0 to 13.0.0, 12.5 branch | 2026-10-22 |
| https://docs.phpunit.de/en/13.4/writing-tests-for-phpunit.html (source: sebastianbergmann/phpunit-documentation-english, branch 13.4) | official | Sebastian Bergmann | 13.4 | 2026-10-22 |
| https://github.com/dmaicher/doctrine-test-bundle (README, composer.json) | bundle repo | D. Maicher | v8.7.0 | 2026-10-22 |
| https://github.com/zenstruck/foundry (docs/index.rst, composer.json) | bundle repo | Zenstruck | v2.14.1 | 2026-10-22 |
| https://github.com/zenstruck/messenger-test (README, composer.json) | bundle repo | Zenstruck | v1.15.0 | 2026-10-22 |
| https://github.com/symfony/panther (README, composer.json) | bundle repo | Symfony | v2.4.0 | 2026-10-22 |
| https://github.com/api-platform/docs/blob/main/symfony/testing.md | official | API Platform | main | 2026-10-22 |
| A throwaway Symfony 8.1.9 project with PHPUnit 13.4.3, Foundry 2.14.1, DAMA 8.7.0, messenger-test 1.15.0 on PHP 8.5.10 | local run | n/a | 2026-10-22 | 2026-10-22 |

## Prior art

Queries run: `npx skills find "symfony testing phpunit"`, `gh search code "symfony WebTestCase" --filename SKILL.md --limit 15`, and a read of the repo tree of dev-toolings/superpowers-symfony via `gh api repos/dev-toolings/superpowers-symfony/git/trees/HEAD?recursive=1`. Read via `gh api .../contents/...` (no install, no script run).

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| dev-toolings/superpowers-symfony@tdd-with-phpunit | https://github.com/dev-toolings/superpowers-symfony/blob/main/content/skills/tdd-with-phpunit/SKILL.md | community | 226 stars (repo), pushed 2026-10-05 | PHPUnit 10/11 red-green with KernelTestCase and WebTestCase | Clear guardrails (attributes, getContainer), output contract, note on 8.1-only helpers | Targets PHPUnit 10/11 only. Its reference example mocks EntityManagerInterface in a unit test, against its own guardrail, and uses createMock as a stub (notice on PHPUnit 12.5+). No version matrix, no decision on which test to write first | MIT |
| dev-toolings/superpowers-symfony@functional-tests | https://github.com/dev-toolings/superpowers-symfony/blob/main/content/skills/functional-tests/SKILL.md | community | same repo | WebTestCase, loginUser, DAMA, smoke tests | Good guardrails: real DB, .env.local not loaded, loginUser over form replay, 422 assertion | Says nothing on kernel reboot between requests, private service removal, DAMA limits, Messenger, HttpClient, Clock | MIT |
| dev-toolings/superpowers-symfony@doctrine-fixtures-foundry, e2e-panther-playwright, test-doubles-mocking, api-platform-tests | https://github.com/dev-toolings/superpowers-symfony/tree/main/content/skills | community | same repo | Foundry v2, Panther 2.4, doubles, ApiTestCase | Foundry v2 aware (no ->object(), #[ResetDatabase] needs 2.9), PATCH merge-patch note, explicit waits for Panther | Split into 6 skills, each loaded separately, with overlapping setup text. No MockHttpClient or MockClock coverage anywhere. Messenger test transports are one line in a different skill | MIT |
| ~/.agents/skills/symfony-tdd-with-phpunit (installed) | local | unknown | local | Generic TDD posture for Symfony | Short | Generic: no Symfony API, no versions, no pitfalls. A thin early variant of the dev-toolings skill | none stated |
| fatonh/symfony-skills@testing-pyramid | https://github.com/fatonh/symfony-skills/blob/main/skills/testing-pyramid/SKILL.md | community | 35 stars, pushed 2026-07-25 | Unit/integration/functional split with Foundry | Clear pyramid and a rule against mocking what you do not own | Tutorial-style code the model already knows; no versions; no boundaries (HTTP, clock, mail, queue) | MIT |
| This repo: skills/frameworks/symfony/symfony-components, skills/knowledge/testing, skills/playbooks/tdd | local | this repo | local | Components defaults, generic testing, generic TDD | symfony-components notes MockClock in one line | No Symfony test-type guidance | n/a |

Decision: write a new skill. dev-toolings covers parts of the topic well, but it is spread over six skills, targets PHPUnit 10/11, has no version matrix, no decision table, no MockHttpClient or MockClock coverage, and no run-verified pitfalls. It is not "correct and better" as a whole, so the stop rule does not apply. Users who want a Symfony TDD command set (plans, commands, agents) could still install dev-toolings next to this skill.

Strengths adopted (as ideas, no text copied): the guardrail style (use the test container, real DB for data tests), the point that `.env.local` is not loaded in tests, the Foundry v2 migration warnings, and the explicit-wait rule for Panther (dev-toolings). The pyramid framing (fatonh) is covered by the existing `testing` skill, so it is linked, not repeated. Weaknesses avoided: version drift, tutorial code, one concern split over several skills, unverified claims.

Gap this skill fills: one place for version facts, test-type choice, the Symfony-specific red-green order, and pitfalls confirmed by running a Symfony 8.1 project.

## Fact ledger

Confidence: confirmed = primary source plus a run or a second source.

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | PHPUnit 10 needs PHP 8.1, 11 needs 8.2, 12 needs 8.3, 13 needs 8.4 | https://phpunit.de/supported-versions.html | 2026-10-22 | 10-13 | confirmed | read page, installed 13.4.3 on 8.5 |
| 2 | Current PHPUnit tags are 13.4.x; no 14 yet | https://github.com/sebastianbergmann/phpunit/tags | 2026-10-22 | 13.4.3 | confirmed | gh api tags, composer resolved 13.4.3 |
| 3 | Symfony 7.4 (LTS, PHP 8.2), 8.1 (PHP 8.4) are the maintained lines besides 6.4; 8.0 is unmaintained | https://symfony.com/releases | 2026-10-22 | 7.4, 8.0, 8.1 | single-source | read page. Kept out of the skill text except PHP minimums and a pointer |
| 4 | Doc-comment metadata deprecated in PHPUnit 11.0, removed in 12.0 | https://github.com/sebastianbergmann/phpunit/blob/12.0.0/ChangeLog-12.0.md and ChangeLog-11.0.md | 2026-10-22 | 11, 12 | confirmed | read both changelogs, ran a `@test` method on 13.4.3: not listed by --list-tests |
| 5 | Non-static, non-public, parameterized data providers removed in 11.0 | ChangeLog-11.0.md (#5100) | 2026-10-22 | 11 | confirmed | changelog plus run: "Data Provider method ... is not static" error on 13.4.3 |
| 6 | PHPUnit docs: data provider is public static, attribute #[DataProvider]; #[Test] marks a test | https://docs.phpunit.de/en/13.4/writing-tests-for-phpunit.html | 2026-10-22 | 13.4 | confirmed | read page |
| 7 | expects() on test stubs removed in 12.0; mock without expectation emits a notice from 12.5.0; #[AllowMockObjectsWithoutExpectations] opts out | ChangeLog-12.0.md, ChangeLog-12.5.md | 2026-10-22 | 12.0, 12.5 | confirmed | changelog plus run: notice text on 13.4.3 |
| 8 | Recipe `failOnNotice="true"` does not fail the run on a PHPUnit notice; `failOnPhpunitNotice="true"` does | https://github.com/symfony/recipes/blob/main/phpunit/phpunit/11.1/phpunit.dist.xml, phpunit.xsd | 2026-10-22 | 13.4.3 | confirmed | ran: exit 0 then exit 1 after adding the attribute |
| 9 | PHPUnit 13 adds sealed test doubles, hard-deprecates any(), drops PHP 8.3 | ChangeLog-13.0.md | 2026-10-22 | 13.0 | confirmed | read changelog |
| 10 | `symfony/test-pack` installs phpunit; config file is phpunit.dist.xml; run `php bin/phpunit` | https://symfony.com/doc/current/testing.html | 2026-10-22 | 8.1 docs | confirmed | docs plus recipe: bin/phpunit requires vendor/phpunit/phpunit/phpunit |
| 11 | Test env reads .env, .env.test, .env.test.local; .env.local is not read | https://symfony.com/doc/current/testing.html | 2026-10-22 | 7.4, 8.1 | confirmed | docs, same text in both branches |
| 12 | Recipe forces APP_ENV=test and sets KERNEL_CLASS in .env.test | recipes phpunit/phpunit/11.1 | 2026-10-22 | recipe 11.1 | confirmed | read recipe, saw it in the scratch project |
| 13 | getContainer() exposes public and non-removed private services; unused private services are removed | testing.html, KernelTestCase.php | 2026-10-22 | 8.1 | confirmed | docs, source, run: ServiceNotFoundException "removed or inlined" |
| 14 | Services redeclared under when@test do not get the file's `_defaults` | n/a (observed) | 2026-10-22 | 8.1.9 | confirmed (observed) | run: ArgumentCountError until `autowire: true` was added |
| 15 | createClient() throws LogicException if the kernel is already booted (also after getContainer() or a Foundry factory call) | WebTestCase.php, Foundry docs ("ensureKernelShutdown") | 2026-10-22 | 8.1 | confirmed | source plus run |
| 16 | The client reboots the kernel between requests; disableReboot() resets instead; both clear the security token and detach entities | testing.html | 2026-10-22 | 8.1 | confirmed | read docs |
| 17 | loginUser($user, $firewall = 'main'); not usable with stateless firewalls | testing.html | 2026-10-22 | 8.1 | confirmed | docs; run: 401 until the user existed in the in-memory provider, then 200 |
| 18 | Mocking non-shared services needs a Closure factory, new in 8.1 | testing.html (8.1 branch, versionadded) | 2026-10-22 | 8.1 | single-source | docs only, not run |
| 19 | runCommand() and the console assertions are new in 8.1; 7.4 docs use CommandTester | console.rst 8.1 and 7.4 | 2026-10-22 | 8.1 | confirmed | docs diff plus run of runCommand + assertCommandIsSuccessful |
| 20 | assertSessionHasFlashMessage new in 8.1 | testing.html | 2026-10-22 | 8.1 | single-source | docs diff 7.4 vs 8.1 |
| 21 | Mailer assertions work in KernelTestCase or with MailerAssertionsTrait; assertQueuedEmailCount when Messenger queues mail | https://symfony.com/doc/current/mailer.html | 2026-10-22 | 8.1 | confirmed | docs plus run of assertEmailCount/assertEmailSubjectContains |
| 22 | HttpClient assertions (assertHttpClientRequest etc.) need $client->enableProfiler() | testing.html | 2026-10-22 | 8.1 | single-source | docs only, not run |
| 23 | MockHttpClient/MockResponse; framework.http_client.mock_response_factory (callback class, or true/false and per scoped client from 8.1) | http_client.html#testing | 2026-10-22 | 8.1 | confirmed | docs plus run with a callback service; JsonMockResponse used. true/false and scoped values docs only |
| 24 | The mock_response_factory class must be a service; a class under tests/ fails with "non-existent service" until registered | n/a (observed) | 2026-10-22 | 8.1.9 | confirmed (observed) | run |
| 25 | ClockSensitiveTrait::mockTime() sets the global Clock to a MockClock and restores it after each test | ClockSensitiveTrait.php | 2026-10-22 | 8.1 | confirmed | source plus run: injected ClockInterface saw the mocked time |
| 26 | MockClock does not advance by itself; sleep() and modify() move it | components/clock.html | 2026-10-22 | 8.1 | confirmed | docs |
| 27 | in-memory:// transport: getSent(), serialize option, reset after each KernelTestCase/WebTestCase test, client resets before a new request; does not run handlers | messenger.html#in-memory-transport | 2026-10-22 | 8.1 | confirmed | docs plus run (sent count, no mail until handled) |
| 28 | zenstruck/messenger-test: test:// transport, InteractsWithMessenger, queue(), process(), acknowledged() | https://github.com/zenstruck/messenger-test | 2026-10-22 | 1.15.0 | confirmed | README plus run: process(1) ran the handler and sent the mail |
| 29 | Foundry v2: PersistentObjectFactory, defaults(), #[ResetDatabase] and FoundryExtension need 2.9 and PHPUnit 10+; enabled-auto-reset param; proxies deprecated since 2.7; auto-refresh needs PHP 8.4 | Foundry docs/index.rst | 2026-10-22 | 2.14.1 | confirmed | docs; run: extension registered by Flex, "no such table" without #[ResetDatabase], pass with it |
| 30 | Foundry in data providers needs PHPUnit 11.4+ (Foundry 2.2+) and lazy objects must not be touched | Foundry docs/index.rst | 2026-10-22 | 2.14.1 | single-source | docs only |
| 31 | Stories: ::load() runs once, objects cleared after each test unless global state | Foundry docs/index.rst | 2026-10-22 | 2.14.1 | single-source | docs only |
| 32 | DAMA: PHPUnit extension `DAMA\DoctrineTestBundle\PHPUnit\PHPUnitExtension` via <bootstrap>; supports PHPUnit 11, 12, 13; transaction per test; DDL implicit commits break it; use_savepoints needed on DBAL < 4; does not work across processes; warns on unclosed transactions | https://github.com/dmaicher/doctrine-test-bundle | 2026-10-22 | 8.7.0 | confirmed | README plus run: rollback worked with it, rows leaked across tests and runs without it |
| 33 | Flex did not register DAMA (bundle or extension) in a non-interactive composer require | n/a (observed) | 2026-10-22 | 8.7.0 | confirmed (observed, non-interactive) | bundles.php and phpunit.dist.xml inspected after composer require --no-interaction |
| 34 | With DAMA Foundry resets the schema only once per suite | Foundry docs "Performance" | 2026-10-22 | 2.14.1 | single-source | docs only |
| 35 | Foundry doc and API Platform doc drift: API Platform docs still show Foundry v1 names (getDefaults, Test\Factories trait, ResetDatabase trait) and `<extension>` | https://github.com/api-platform/docs/blob/main/symfony/testing.md | 2026-10-22 | docs main | confirmed | read page versus Foundry 2.14 docs |
| 36 | Panther 2.4.0; PantherTestCase extends WebTestCase in a Symfony app; createPantherClient(); ServerExtension via <bootstrap>; serves the app with the built-in PHP server; waitFor* methods | https://symfony.com/doc/current/testing/end_to_end.html, https://github.com/symfony/panther | 2026-10-22 | 2.4.0 | confirmed (docs) | docs; not run (no browser driver) |
| 37 | Panther runs the app in a separate web server process, so DAMA's in-process rollback does not cover it | DAMA README (Behat note: cannot work with Selenium) plus end_to_end.html | 2026-10-22 | n/a | likely | inference from two sources, marked as such in the skill |
| 38 | API Platform 5.0: ApiTestCase moved to package api-platform/test as ApiPlatform\Test\ApiTestCase (extends KernelTestCase); ApiPlatform\Symfony\Bundle\Test\ApiTestCase is deprecated and removed in 6.0; api-platform/test needs Symfony ^7.4/^8.0 and PHPUnit ^11.5/^12.2/^13; denormalization errors on constrained properties return 422 instead of 400 | https://github.com/api-platform/core/blob/main/CHANGELOG.md, src/Test/ApiTestCase.php, src/Symfony/Bundle/Test/ApiTestCase.php, src/Test/composer.json | 2026-10-22 | api-platform/core 5.0.x | confirmed | read changelog, both class files and composer.json (the docs page still shows the old namespace). Not run |
| 39 | `getContainer()` boots the kernel when it is not booted; requires framework.test: true | KernelTestCase.php | 2026-10-22 | 8.1 | confirmed | source, run |
| 41 | Unrouted messages are handled immediately; a `sync://` transport handles messages immediately too | https://symfony.com/doc/current/messenger.html | 2026-10-22 | 8.1 | confirmed | read docs section "Handling Messages Synchronously" |
| 42 | API Platform docs page shows the old ApiTestCase namespace and Foundry v1 names (finding that the docs lag the code) | https://github.com/api-platform/docs/blob/main/symfony/testing.md | 2026-10-22 | docs main | confirmed | compared with row 38 and Foundry docs |
| 40 | Package floors: Foundry PHP>=8.1; Panther PHP>=8.1, Symfony ^6.4/^7.3/^8.0; DAMA PHP>=8.2; messenger-test PHP>=8.1 | each composer.json | 2026-10-22 | as listed | confirmed | read composer.json files |

## Not confirmed

- Rows 3, 18, 20, 22, 30, 31, 34: single source, docs only. Kept in the skill as docs-backed facts without a "run" claim. Row 3 (maintenance status) is not stated in the skill text; the skill links the releases page.
- Row 36, 37 and 38: Panther and ApiTestCase were not run (no driver). Row 37 is an inference and the skill says so.
- True/false and per-scoped-client values of mock_response_factory (8.1) were not run.
- Whether Symfony registers the `clock` service so that every autowired ClockInterface follows the global clock: not read in source. The run showed the injected service followed mockTime(), so the skill states only that observation.

## Left out

- Generic AAA structure, pyramid shape, test double vocabulary: the model knows them and skills `testing` and `tdd` cover them.
- Smoke-test data providers, PHPUnit XML options, code coverage setup: standard PHPUnit.
- Behat, Pest, Playwright setup: out of scope; Playwright appears as a pointer only.
- Maintenance end dates for Symfony and PHPUnit: volatile, linked instead.

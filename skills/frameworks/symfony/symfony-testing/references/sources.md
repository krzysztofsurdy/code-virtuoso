# Sources

Each fact in this skill traces to one of these pages. Symfony docs were read as RST from the `symfony/symfony-docs` repository (branches 7.4 and 8.1), which builds the pages on symfony.com. Retrieved 2026-10-22.

## Contents

- [Symfony](#symfony)
- [PHPUnit](#phpunit)
- [Bundles](#bundles)
- [Checked by running](#checked-by-running)
- [Not confirmed](#not-confirmed)

## Symfony

| Page or file | Backs |
|---|---|
| https://symfony.com/releases | Maintained versions and PHP minimums |
| https://symfony.com/doc/current/testing.html | Test types, env files, test container, mocking services, `loginUser()`, client reboot, assertions, 8.1 notes |
| https://symfony.com/doc/current/http_client.html#testing | `MockHttpClient`, `MockResponse`, `mock_response_factory` |
| https://symfony.com/doc/current/components/clock.html | `MockClock`, `sleep()`, `modify()` |
| https://symfony.com/doc/current/messenger.html | `in-memory://` transport, `sync://`, unrouted messages |
| https://symfony.com/doc/current/mailer.html | Mailer assertions, `null://null` DSN |
| https://symfony.com/doc/current/console.html#testing-commands | `runCommand()` (8.1), `CommandTester` (7.4) |
| https://symfony.com/doc/current/testing/end_to_end.html | Panther setup and usage |
| https://github.com/symfony/symfony/blob/8.1/src/Symfony/Bundle/FrameworkBundle/Test/KernelTestCase.php | `getContainer()` boots the kernel, `framework.test` requirement |
| https://github.com/symfony/symfony/blob/8.1/src/Symfony/Bundle/FrameworkBundle/Test/WebTestCase.php | `createClient()` throws when the kernel is booted |
| https://github.com/symfony/symfony/blob/8.1/src/Symfony/Component/Clock/Test/ClockSensitiveTrait.php | `mockTime()` and restore after each test |
| https://github.com/symfony/recipes/tree/main/phpunit/phpunit/11.1 | `phpunit.dist.xml` defaults, `.env.test`, `bin/phpunit` |

## PHPUnit

| Page or file | Backs |
|---|---|
| https://phpunit.de/supported-versions.html | PHP minimum per major |
| https://github.com/sebastianbergmann/phpunit/blob/10.0.0/ChangeLog-10.0.md | Attributes introduced, non-static providers deprecated |
| https://github.com/sebastianbergmann/phpunit/blob/11.0.0/ChangeLog-11.0.md | Doc-comment metadata deprecated, non-static providers removed |
| https://github.com/sebastianbergmann/phpunit/blob/12.0.0/ChangeLog-12.0.md | Doc-comment metadata removed, `expects()` on stubs removed |
| https://github.com/sebastianbergmann/phpunit/blob/12.5/ChangeLog-12.5.md | Notice for a mock without expectations |
| https://github.com/sebastianbergmann/phpunit/blob/13.0.0/ChangeLog-13.0.md | Sealed doubles, `any()` deprecation, PHP 8.3 dropped |
| https://docs.phpunit.de/en/13.4/writing-tests-for-phpunit.html | `#[Test]`, `#[DataProvider]`, public static providers |

## Bundles

| Page or file | Backs |
|---|---|
| https://github.com/dmaicher/doctrine-test-bundle | DAMA behavior, extension, limits, supported PHPUnit versions |
| https://github.com/zenstruck/foundry (docs/index.rst, also at https://symfony.com/bundles/ZenstruckFoundryBundle/current/index.html) | Factories, `#[ResetDatabase]`, stories, data providers, proxies and auto-refresh |
| https://github.com/zenstruck/messenger-test | `test://` transport and helpers |
| https://github.com/symfony/panther | Panther version and requirements |
| https://github.com/api-platform/docs/blob/main/symfony/testing.md | `ApiTestCase` usage, assertions, E2E recommendation |
| https://github.com/api-platform/core/blob/main/CHANGELOG.md and src/Test/ApiTestCase.php | `ApiTestCase` moved to `api-platform/test`, old namespace deprecated, 422 change |

## Checked by running

A throwaway project on PHP 8.5, Symfony 8.1.9, PHPUnit 13.4.3, Foundry 2.14.1, DAMA 8.7.0 and messenger-test 1.15.0 confirmed: the unused private service error, the `when@test` `_defaults` gap, `createClient()` after `getContainer()` or a factory call, `ClockSensitiveTrait` reaching an injected `ClockInterface`, `mock_response_factory` with a callback service, in-memory Messenger assertions, `test://` processing, mailer assertions, `loginUser()` with a known and an unknown user, `runCommand()`, the ignored `@test` annotation, the non-static provider error, the mock-without-expectation notice and `failOnPhpunitNotice`, Foundry without a reset, and DAMA rollback versus leaking rows.

## Not confirmed

Not run: Panther, `ApiTestCase`, the Closure form for non-shared services, `assertHttpClientRequest()`, the `true`, `false` and scoped values of `mock_response_factory`, stories, and Foundry data providers.

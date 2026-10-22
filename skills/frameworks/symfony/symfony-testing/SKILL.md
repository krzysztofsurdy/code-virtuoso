---
name: symfony-testing
description: "Symfony tests with PHPUnit 11 to 13: pick KernelTestCase, WebTestCase, ApiTestCase or Panther and avoid version pitfalls. Use when adding a functional test, testing a controller, a service missing from getContainer, mocking the HTTP client or clock, Messenger or mailer assertions, or Foundry and DAMA setup."
user-invocable: false
---

# Symfony testing

PHPUnit knowledge alone does not predict how Symfony tests fail. The container removes private services, the kernel reboots between requests, database state leaks between tests, and the assertion API changes with the Symfony minor and the PHPUnit major. This skill gives the version facts, the choice of test type, a Symfony-specific order for red-green, and a pitfall list that was checked by running a Symfony 8.1 project.

The generic procedure is in the `tdd` playbook and the strategy, doubles and flakiness rules are in the `testing` skill. This skill does not repeat them.

## Check the installed versions first

Memory of "PHPUnit" or "Symfony" is often a major behind. Read the lock file before writing a test:

```bash
jq -r '(.packages + ."packages-dev")[] | select(.name|test("^(phpunit/phpunit|symfony/framework-bundle|zenstruck/(foundry|messenger-test)|dama/doctrine-test-bundle|symfony/panther|api-platform/(core|symfony))$")) | .name+" "+.version' composer.lock
```

## Version matrix

PHPUnit (what changes in the tests you write):

| Version | Min PHP | Changes that bite |
|---|---|---|
| 10 | 8.1 | Attributes introduced. Non-static data providers deprecated |
| 11 | 8.2 | Doc-comment metadata deprecated. Non-static, non-public and parameterized data providers removed |
| 12 | 8.3 | Doc-comment metadata removed: `@test` and `@dataProvider` stop working silently. `expects()` on stubs removed. From 12.5, a mock without expectations raises a notice |
| 13 | 8.4 | Sealed test doubles added. `any()` matcher hard-deprecated. PHP 8.3 dropped |

Symfony (what changes in the test API):

| Version | Min PHP | Test API facts |
|---|---|---|
| 7.4 LTS | 8.2 | `static::getContainer()`, `loginUser()`, mailer and HttpClient assertions, `CommandTester` for commands |
| 8.0 and 8.1 | 8.4 | 8.1 adds `runCommand()` with console assertions, `assertSessionHasFlashMessage()`, Closure factories for non-shared services, `mock_response_factory` per scoped client and `true` or `false` values |

Bundles:

| Package | Version facts |
|---|---|
| zenstruck/foundry 2.x | Factories extend `PersistentObjectFactory` with `defaults()`. `#[ResetDatabase]` and `FoundryExtension` need 2.9 and PHPUnit 10+. Proxies deprecated since 2.7, auto-refresh needs PHP 8.4. Factories in data providers need PHPUnit 11.4+ |
| dama/doctrine-test-bundle 8.x | Built-in extension for PHPUnit 11, 12 and 13. On DBAL below 4 set `use_savepoints: true` |
| symfony/panther 2.x | `PantherTestCase` extends `WebTestCase` in a Symfony app. Register `ServerExtension` |
| zenstruck/messenger-test 1.x | `test://` transport and `InteractsWithMessenger` for queue assertions and processing |
| api-platform 5.x | `ApiPlatform\Test\ApiTestCase` from the `api-platform/test` package. The old `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` is deprecated and removed in 6.0, and the docs page still shows it |

Check the release pages for the maintained lines: https://symfony.com/releases and https://phpunit.de/supported-versions.html.

## Pick the test type

| You are checking | Write | Base class | Notes |
|---|---|---|---|
| A pure rule, value object, or handler logic with fakes | Unit | PHPUnit `TestCase` | No kernel. Call the handler's `__invoke()` directly |
| Wiring, tagged services, config, event subscriber registration | Integration | `KernelTestCase` | Read services with `static::getContainer()` |
| A repository query or Doctrine mapping | Integration | `KernelTestCase` | Real database. Do not mock the EntityManager. See [data-and-isolation](references/data-and-isolation.md) |
| A route, controller, form, redirect, flash, access rule, Twig output | Application | `WebTestCase` | `static::createClient()`, `loginUser()` |
| A JSON or Hydra endpoint built with API Platform | Application | `ApiTestCase` | See [browser-and-api](references/browser-and-api.md) |
| A console command | Integration | `KernelTestCase` | `runCommand()` on 8.1+, `CommandTester` before |
| That a request or action dispatches a message | Application | `WebTestCase` plus an in-memory transport | Assert on the transport. See [boundaries](references/boundaries.md) |
| That a queued message gets handled | Integration | `KernelTestCase` plus `test://` transport | One end-to-end test is enough. Test handler logic as a unit |
| An outbound HTTP call | Any of the above | `MockHttpClient` or `mock_response_factory` | Never hit the network |
| Time-dependent logic | Any of the above | `ClockSensitiveTrait::mockTime()` or `MockClock` | Inject `ClockInterface` |
| An email being sent | `WebTestCase` or `KernelTestCase` | Mailer assertions | `assertQueuedEmailCount()` when Messenger queues mail |
| Behavior that needs JavaScript, a real browser, WebSockets or Mercure | End-to-end | `PantherTestCase` | Slow. Cover critical paths only |

Start from the cheapest type that can fail for the behavior. Move up a type only when the lower one cannot see the behavior (JavaScript needs Panther, HTTP behavior needs `WebTestCase`).

## Red-green order in a Symfony app

1. Name the behavior and the layer where a user or caller can observe it.
2. A bug report about a page, status code, redirect, form error or access rule: write the `WebTestCase` first. It reproduces the report. When the cause turns out to be a rule inside a service, add a unit test for that rule and keep the web test as the regression guard.
3. A new rule with no framework in it: write the unit test first, with no kernel.
4. A query or mapping: write a `KernelTestCase` repository test with factory data against the real test database.
5. A wiring or config problem: write a `KernelTestCase` that fetches the service. Red is a `ServiceNotFoundException` or a `LogicException`, which is the right reason here.
6. Async work: write the dispatch assertion first (in-memory transport), then the handler unit test, then at most one processing test.
7. Check the red reason before writing code. "No such table", "kernel already booted", "service removed" and 401 from a missing `loginUser()` are setup failures, not red. Fix the setup until the test fails on the assertion about the behavior.
8. Run the narrow test (`vendor/bin/phpunit --filter name`), then the suite. A green suite does not prove the test can fail, so keep the red run in the report.

## Pitfalls

PHPUnit

- **Annotations are ignored on PHPUnit 12 and 13.** A method with `@test` and no `test` prefix never runs and nothing fails. Use `#[Test]`, `#[DataProvider]`, `#[CoversClass]`.
- **Data providers must be `public static`.** A non-static provider is an error on PHPUnit 11 and later.
- **`createMock()` used as a stub raises a PHPUnit notice from 12.5.** Use `createStub()` when you configure no expectation. The Flex recipe's `failOnNotice` does not fail on it. Add `failOnPhpunitNotice="true"` to make the suite fail.
- **Extensions go in `<extensions><bootstrap class="..."/></extensions>` of `phpunit.dist.xml`.** The `<extension>` form is for PHPUnit below 10.

Container and kernel

- **`getContainer()` cannot return a private service that nothing uses.** The container removes it and the call throws `ServiceNotFoundException` ("removed or inlined"). Fetch a service that uses it, or make it public under `when@test`. A service redeclared under `when@test` loses the file's `_defaults`, so add `autowire: true` or it is built with no arguments.
- **`createClient()` throws `LogicException` if the kernel is booted.** `getContainer()`, `bootKernel()` and any Foundry factory call boot it. Create the client first, or call `static::ensureKernelShutdown()` before `createClient()`.
- **The client reboots the kernel between requests in one test.** The security token clears and entities detach. Re-fetch entities, or call `$client->disableReboot()`, and read mocks and queues before the next request.
- **`loginUser()` needs a user the firewall's provider can load.** An object the provider does not know gives a 401 on the next request. It does not work with stateless firewalls. Pass the firewall name when it is not `main`.
- **`.env.local` is not read in the test environment.** Put test values in `.env.test` or `.env.test.local`.

Data

- **A Foundry factory without a reset fails with "no such table".** Flex registers `FoundryExtension`, but each class still needs `#[ResetDatabase]` unless the extension runs with `enabled-auto-reset`.
- **Foundry v1 code is still common in docs and answers.** v2 uses `defaults()`, `PersistentObjectFactory` and `#[ResetDatabase]`. The API Platform testing page still shows v1 names.
- **DAMA is not always registered by Flex.** Check that the bundle is enabled for `test` and the PHPUnit extension is in `phpunit.dist.xml`. Without it, rows leak between tests and between runs.
- **DAMA rolls back one process.** DDL statements commit implicitly and break it. It cannot cover an app served to a browser in another process, so Panther tests reset data another way.
- **Factory objects in data providers are lazy.** Do not read their properties inside the provider.

Boundaries

- **The `mock_response_factory` class must be a registered service.** A class under `tests/` fails with "non-existent service" until you register it under `when@test`.
- **In-memory Messenger transports never run handlers.** Assert what was sent, or use the `test://` transport and `process()` to run them. The client resets in-memory transports before a new request, so assert before the next request.
- **Mocked time only reaches code that asks the clock.** `new \DateTimeImmutable()` in the code under test is not mocked. Inject `ClockInterface` and call `now()`.
- **Mail assertions count sent mail.** When Messenger routes mail to a queue, use `assertQueuedEmailCount()` and process the queue before `assertEmailCount()`.

Browser and API

- **Panther needs explicit waits.** Use `waitFor()` and `assertSelectorWillExist()` for anything asynchronous, never sleeps.
- **Send API Platform `PATCH` requests with `Content-Type: application/merge-patch+json`,** as the API Platform examples do, and read the items per page from config instead of hardcoding a page size.

## Reference files

| Reference | Open when |
|---|---|
| [kernel-and-container](references/kernel-and-container.md) | Test env files, the test container, mocking services, the client, `loginUser()`, assertion choices |
| [data-and-isolation](references/data-and-isolation.md) | Setting up DAMA and Foundry, resets, stories, data providers, parallel runs |
| [boundaries](references/boundaries.md) | Mocking HttpClient, mocking time, Messenger transports, mailer assertions, console commands |
| [browser-and-api](references/browser-and-api.md) | Deciding on Panther, setting it up, and `ApiTestCase` |
| [sources](references/sources.md) | The pages and repositories behind each fact |
| [research-notes](references/research-notes.md) | Research: prior-art table, fact ledger with sources and dates, unconfirmed items |

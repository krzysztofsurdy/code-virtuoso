# Browser tests and API tests

Nothing in this file was run in a browser or against API Platform. It is read from the Symfony docs, the Panther and API Platform sources, and the bundle composer files.

## Contents

- [When Panther is worth it](#when-panther-is-worth-it)
- [Panther setup](#panther-setup)
- [Panther habits](#panther-habits)
- [ApiTestCase](#apitestcase)

## When Panther is worth it

Panther drives a real Chrome or Firefox through WebDriver and serves your app on a built-in PHP web server. It is slow and needs a driver, so use it only for what a `WebTestCase` cannot see.

| Behavior | Test type |
|---|---|
| Server-rendered page, form, redirect, access rule | `WebTestCase` |
| JSON API | `ApiTestCase` or `WebTestCase` |
| JavaScript changes the DOM, a Stimulus or Turbo flow, a drag and drop | Panther |
| WebSockets or Mercure updates | Panther |
| A screenshot of a failing step in CI | Panther |
| Cross-browser, tracing or video beyond WebDriver | Playwright, set up outside PHPUnit. API Platform recommends it for JavaScript-heavy apps and Panther for Twig apps |

Keep a handful of end-to-end tests on the critical paths: sign-up, login, checkout. Everything else belongs in cheaper tests.

## Panther setup

- `composer require --dev symfony/panther` and, for drivers, `dbrekelmans/bdi` then `vendor/bin/bdi detect drivers`.
- Register `Symfony\Component\Panther\ServerExtension` in `phpunit.dist.xml` with `<bootstrap>` on PHPUnit 10 and later. Without it the web server starts and stops per test class. With it, the server stops after the last test.
- Extend `PantherTestCase`. In a Symfony app it extends `WebTestCase`, so the crawler assertions work and you can still read the kernel's services in the test process.
- `static::createPantherClient()` starts a real browser. `static::createClient()` in the same class stays a fast in-process client with no JavaScript.
- Set `PANTHER_ERROR_SCREENSHOT_DIR` to get a screenshot when a test fails after the client exists. `PANTHER_NO_HEADLESS=1` shows the browser while debugging, and CI containers usually need `PANTHER_NO_SANDBOX=1`.
- Pass environment variables to the app's web server with the `env` option of `createPantherClient()`. If your bootstrap loads `.env` files, Dotenv can override them in the server process, and the docs show how to prevent it.

## Panther habits

- The browser and the app run in a different process from the test, so DAMA rollback does not undo what the app writes (inferred, see [data-and-isolation](data-and-isolation.md)). Reset data with Foundry before each test and create data before the page loads.
- Wait explicitly for anything asynchronous: `waitFor()`, `waitForVisibility()`, `assertSelectorWillExist()`, `assertSelectorWillContain()`. A sleep is a flaky test waiting to happen.
- Select by a stable hook such as `data-testid`, not by styling classes.
- WebDriver returns only displayed text. `text()` on `title` is empty, so use `html()` for head tags.
- Screenshots written by `takeScreenshot()` are artifacts. Do not commit them.

## ApiTestCase

Class: `ApiPlatform\Test\ApiTestCase`, shipped in the `api-platform/test` package since API Platform 5.0. The old `ApiPlatform\Symfony\Bundle\Test\ApiTestCase` extends it, is deprecated, and goes away in 6.0. The API Platform docs page still shows the old name, so use the new one in new tests and migrate old ones. The class extends `KernelTestCase`, and its client follows the Symfony HttpClient interfaces, so responses have `toArray()` and `getStatusCode()`.

```php
final class BooksTest extends ApiTestCase
{
    public function testCreateInvalidBook(): void
    {
        static::createClient()->request('POST', '/books', ['json' => ['isbn' => 'invalid']]);

        $this->assertResponseStatusCodeSame(422);
        $this->assertJsonContains(['@type' => 'ConstraintViolationList']);
    }
}
```

- Install `symfony/test-pack` and `symfony/http-client`, plus `api-platform/test` as a dev dependency if the project does not have it. It needs Symfony 7.4 or later and PHPUnit 11.5, 12.2 or 13. The docs also mention `justinrainbow/json-schema` for the JSON Schema assertions.
- Useful helpers: `assertJsonContains()` (the response must be a superset), `assertMatchesResourceItemJsonSchema()`, `assertMatchesResourceCollectionJsonSchema()` and `findIriBy()`. Authenticate through the HttpClient request options, such as `auth_bearer`.
- Send `PATCH` with `Content-Type: application/merge-patch+json`, as the API Platform examples do.
- Read the collection keys for your version. The 5.x docs example uses `member` and `view`, not the `hydra:`-prefixed names of older versions.
- Cover the anonymous, owner and other-user cases for each protected operation, plus 404, 422, 401 and 403. The 5.0 changelog says a denormalization error on a property with a validator constraint now returns 422, where older versions returned 400.
- Seed data with Foundry factories and isolate tests as described in [data-and-isolation](data-and-isolation.md). Use the v2 names. The API Platform docs page still shows Foundry v1 trait names.

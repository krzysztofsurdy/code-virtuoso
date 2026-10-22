# Boundaries: HTTP, time, mail, queues, commands

## Contents

- [Outbound HTTP](#outbound-http)
- [Time](#time)
- [Mail](#mail)
- [Messenger](#messenger)
- [Console commands](#console-commands)

Replace what you do not own at its edge, and keep the rest real. A fake at the edge keeps the test fast and deterministic without hiding wiring bugs.

## Outbound HTTP

Type-hint `HttpClientInterface` in the code under test. Tests then swap the real client for `MockHttpClient`.

Unit test: pass a mock client to the constructor.

```php
$client = new MockHttpClient([new JsonMockResponse(['text' => 'hi'])]);
$quote = new Quote($client);
```

`MockHttpClient` takes a list of responses (served in order), a callback, or an invokable class. `MockResponse` accepts `http_code` and chunked bodies, and an empty string in a generator body simulates a timeout. `JsonMockResponse` encodes an array and sets the JSON content type.

Application test: let the framework replace every client. The callback must be a registered service.

```yaml
# config/packages/framework.yaml
when@test:
    framework:
        http_client:
            mock_response_factory: App\Tests\MockClientCallback
```

```yaml
# config/services.yaml
when@test:
    services:
        App\Tests\MockClientCallback: ~
```

The callback receives `$method`, `$url` and `$options` and returns a response. Branch on the URL when one test touches several upstream APIs. From Symfony 8.1, `mock_response_factory` also accepts `true` (empty 200 responses), `false`, and a per-scoped-client value. Those values were read in the docs and not run.

To assert what was requested, call `$client->enableProfiler()` before the request and use `assertHttpClientRequest()`, `assertNotHttpClientRequest()` and `assertHttpClientRequestCount()`. Read in the docs, not run.

## Time

Inject `Symfony\Component\Clock\ClockInterface` and call `now()`. Code that builds `new \DateTimeImmutable()` or calls `time()` cannot be controlled.

In a test class, use the trait:

```php
use Symfony\Component\Clock\Test\ClockSensitiveTrait;

final class ExpiryTest extends KernelTestCase
{
    use ClockSensitiveTrait;

    public function testExpired(): void
    {
        self::mockTime('2030-01-01 00:00:00');
        // services fetched from the container now see this time
    }
}
```

`mockTime()` sets the global clock to a `MockClock`, takes a string, a `DateTimeImmutable` or a boolean, and restores the original clock after each test. In a run on Symfony 8.1 a service that received `ClockInterface` by autowiring saw the mocked time. For a unit test with no kernel, build `new MockClock('2030-01-01 00:00:00')` and pass it in.

`MockClock` does not move on its own. `sleep(600)` jumps the time without waiting, and `modify('+1 day')` moves it too, so a test can step across an expiry boundary without delay.

## Mail

Mailer assertions come with `KernelTestCase` and `WebTestCase`, or with `MailerAssertionsTrait`.

```php
self::assertEmailCount(1);
self::assertEmailSubjectContains(self::getMailerMessage(), 'Welcome');
```

- If Messenger routes mail to a queue, the mail is queued and not sent. Use `assertQueuedEmailCount()`, or process the queue first and then assert on sent mail.
- Keep a real `MAILER_DSN` out of tests. The skeleton `null://null` DSN disables delivery while assertions still see the messages.
- Assert subject, recipients and a key phrase of the body. Asserting the full HTML makes tests brittle.

## Messenger

Two transports for tests.

| Transport | Runs handlers | Assertions | Use when |
|---|---|---|---|
| `in-memory://` (Symfony) | No | `getSent()` on the transport service | You only need to know what was dispatched and to which transport |
| `test://` (zenstruck/messenger-test) | On `process()` | `queue()`, `dispatched()`, `acknowledged()`, `rejected()` | You also want to run the handler, retries or failures |

In-memory, replacing the transport for tests:

```yaml
when@test:
    framework:
        messenger:
            transports:
                async: 'in-memory://'
```

```php
/** @var InMemoryTransport $transport */
$transport = static::getContainer()->get('messenger.transport.async');
self::assertCount(1, $transport->getSent());
self::assertInstanceOf(Welcome::class, $transport->getSent()[0]->getMessage());
```

In-memory transports reset after each `KernelTestCase` or `WebTestCase` test, and the client resets them before a new request. Assert before the next request or call `disableReboot()`.

With `zenstruck/messenger-test`, set `async: 'test://'` under `when@test` and use the trait:

```php
use InteractsWithMessenger;

$this->transport('async')->queue()->assertCount(1);
$this->transport('async')->process(1);
$this->transport('async')->acknowledged()->assertCount(1);
```

In a run, `process(1)` handled the message and a mail assertion then saw the sent mail. The bundle also has `throwExceptions()` to surface handler errors, a DSN option to enable retries, and an unblock mode. Read its README for those.

Test the handler's logic as a unit by calling `__invoke()` with fakes. Use the transports for the routing and one end-to-end path. A `sync://` transport also runs handlers inline when you want the whole chain without a queue.

## Console commands

On Symfony 8.1 and later:

```php
$result = static::runCommand('app:hello', ['name' => 'Wouter']);
$this->assertCommandIsSuccessful($result);
self::assertStringContainsString('hello', $result->getOutput());
```

`runCommand()` is on `KernelTestCase`. Assertions: `assertCommandIsSuccessful()`, `assertCommandFailed()`, `assertCommandIsInvalid()` and `assertCommandResultEquals()`. Before 8.1, use `CommandTester` from the Console component. Commands that write to the database need the same isolation as any kernel test.

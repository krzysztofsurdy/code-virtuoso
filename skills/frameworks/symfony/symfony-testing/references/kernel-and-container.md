# Kernel, container and client

## Contents

- [Test environment and files](#test-environment-and-files)
- [The test container](#the-test-container)
- [Replacing a service in a test](#replacing-a-service-in-a-test)
- [The client and the kernel lifecycle](#the-client-and-the-kernel-lifecycle)
- [Logging in](#logging-in)
- [Choosing assertions](#choosing-assertions)

## Test environment and files

The Flex recipe for PHPUnit gives you `phpunit.dist.xml`, `tests/bootstrap.php`, `bin/phpunit` and a `.env.test`. `phpunit.dist.xml` forces `APP_ENV=test`, and `.env.test` sets `KERNEL_CLASS`.

| File | Loaded in test | Use for |
|---|---|---|
| `.env` | Yes | Defaults for every environment |
| `.env.test` | Yes, commit it | Values every developer and CI share, such as the test `DATABASE_URL` |
| `.env.test.local` | Yes, gitignored | Values for one machine |
| `.env.local` | No | Never read in tests, on purpose |

Keep test-only configuration in `config/packages/test/` or under `when@test:`. A `KernelTestCase` fails with "framework.test" errors when `framework.test` is not `true`. The recipe sets it under `when@test`.

`getContainer()` boots the kernel when it is not booted yet. `bootKernel()` always shuts down and boots a fresh one. The kernel is shut down after every test.

## The test container

`static::getContainer()` returns a container that can read public services and private services that still exist after compilation. Symfony removes a private service that no other service uses, and then `get()` throws a `ServiceNotFoundException` that says the service "has been removed or inlined".

Three fixes, in order of preference:

1. Test through a service that uses it. This also tests the wiring.
2. Make it public for the test environment only.
3. Stop fetching it from the container and construct it by hand in a unit test.

```yaml
# config/services.yaml
when@test:
    services:
        App\Service\Expiry:
            autowire: true
            public: true
```

The `autowire: true` line is needed. A definition under `when@test` does not receive the `_defaults` of the base `services:` block, so without it the service is built with no arguments and the test dies with an `ArgumentCountError`.

## Replacing a service in a test

`$container->set(Id::class, $double)` replaces a service, and a private alias works through the test container. Call it before the first `get()` of any service that depends on it, because services are built once per kernel.

```php
$container = static::getContainer();
$container->set(NewsRepositoryInterface::class, $stub);
$generator = $container->get(NewsletterGenerator::class);
```

A non-shared service is built on every `get()`, so a fixed instance does not fit. From Symfony 8.1 you pass a Closure that returns a new double each time. This was read in the docs and not run.

Prefer a fake class in `when@test` config over `set()` when many tests need the same replacement. Use `createStub()` for a value-only double and `createMock()` only when you assert a call (PHPUnit 12.5 and later notices on a mock with no expectation).

## The client and the kernel lifecycle

`static::createClient()` boots the kernel and returns the client. If the kernel is already booted it throws `LogicException` ("Booting the kernel before calling createClient() is not supported"). These all boot it:

- `static::getContainer()` and `static::bootKernel()`
- A Foundry factory call such as `PostFactory::createOne()`

Create the client first, or call `static::ensureKernelShutdown()` before `createClient()`. Foundry's own docs show the second form for the arrange step.

After the first request, each further request in the same test reboots the kernel. That gives fresh services, and it clears the security token and detaches Doctrine entities. Options:

- Re-fetch entities from the repository after a request.
- `$client->disableReboot()` resets services that carry the `kernel.reset` tag instead of rebooting. It still clears the token and detaches entities. Remove the `kernel.reset` tag from the services you need to keep, in a compiler pass for the test environment.
- Read in-memory queues, sent mail and profiler data before the next request.

`$client->enableProfiler()` is required before HttpClient assertions, and `$client->catchExceptions(false)` lets an exception reach the test while you debug a 500.

## Logging in

`$client->loginUser($user)` skips the login form. The second argument is the firewall name and defaults to `main`.

- The user must be loadable by the firewall's user provider. Observed on Symfony 8.1: a user the provider did not know led to a 401 on the next request, and the same request returned 200 once the provider knew the user.
- It does not work with stateless firewalls. Send the credential or token the firewall expects instead.
- Test the login form itself once with `submitForm()`. Use `loginUser()` everywhere else.

## Choosing assertions

Use the built-in assertions over `assertSame($client->getResponse()->getStatusCode(), ...)`, because the failure message includes the response.

| Check | Assertion |
|---|---|
| Any 2xx | `assertResponseIsSuccessful()` |
| Exact status | `assertResponseStatusCodeSame(201)` |
| Redirect | `assertResponseRedirects('/login')` |
| Invalid form re-rendered | `assertResponseIsUnprocessable()` (422) |
| Rendered text | `assertSelectorTextContains()`, `assertSelectorExists()`, `assertSelectorCount()` |
| Route that matched | `assertRouteSame()` |
| Flash message | `assertSessionHasFlashMessage()` (8.1 and later) |
| Mail | `assertEmailCount()`, `assertQueuedEmailCount()`, `assertEmailSubjectContains()` |
| Outbound HTTP | `assertHttpClientRequest()` after `enableProfiler()` |
| Command | `assertCommandIsSuccessful($result)` on 8.1 and later |

Mailer assertions come with `KernelTestCase`, or with `MailerAssertionsTrait` in other classes.

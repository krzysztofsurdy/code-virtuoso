# Symfony HttpKernel Component

## Overview

The HttpKernel component converts HTTP requests into HTTP responses through an event-driven architecture. It handles the complete request-response lifecycle including controller resolution, argument injection, exception handling, and response modification. Use this component when building custom HTTP kernels, managing request-response flows, creating event listeners, or implementing middleware patterns.

## When to use

- Building custom HTTP kernels or request handlers
- Creating event listeners for request/response lifecycle hooks
- Implementing middleware or filters
- Resolving controllers from routing information
- Injecting dependencies into controller arguments
- Handling and customizing error responses
- Creating error handlers and exception listeners
- Managing long-running processes with state cleanup
- Implementing sub-requests (partial page rendering)
- Creating custom controller or argument resolvers

## Key concepts

### Request-Response Lifecycle

The HttpKernel processes requests through a series of dispatch events:

1. **kernel.request** - Early request processing, add info or return response early
2. **Controller Resolution** - Determine which callable handles the request
3. **kernel.controller** - Modify controller or initialize systems
4. **Argument Resolution** - Determine controller method parameters
5. **Controller Execution** - Execute the resolved controller
6. **kernel.view** - Convert non-Response controller returns to Response
7. **kernel.response** - Modify response before sending
8. **kernel.finish_request** - Reset application state after response
9. **kernel.terminate** - Execute heavy tasks after response sent
10. **kernel.exception** - Handle exceptions and create error responses

### Kernel Events

All kernel events extend `KernelEvent` and provide common methods:

- `isMainRequest()` - Check if main or sub request
- `getRequest()` - Get current Request object
- `getKernel()` - Get kernel instance
- `getRequestType()` - Return MAIN_REQUEST or SUB_REQUEST constant

**Event Classes and Purposes:**

| Event | Class | Purpose |
|-------|-------|---------|
| `kernel.request` | `RequestEvent` | Initialize request, add data, return early response |
| `kernel.controller` | `ControllerEvent` | Initialize dependencies, change controller |
| `kernel.controller_arguments` | `ControllerArgumentsEvent` | Modify arguments passed to controller |
| `kernel.view` | `ViewEvent` | Transform non-Response controller result |
| `kernel.response` | `ResponseEvent` | Modify response headers, cookies, content |
| `kernel.finish_request` | `FinishRequestEvent` | Reset global application state |
| `kernel.terminate` | `TerminateEvent` | Execute slow tasks after response sent |
| `kernel.exception` | `ExceptionEvent` | Handle exceptions, create error responses |

### Core Interfaces and Classes

**HttpKernelInterface** - Main contract for converting Request to Response:

```php
interface HttpKernelInterface
{
    const MAIN_REQUEST = 1;
    const SUB_REQUEST = 2;

    public function handle(
        Request $request,
        int $type = self::MAIN_REQUEST,
        bool $catch = true
    ): Response;
}
```

**ControllerResolverInterface** - Determines which callable handles request:

```php
interface ControllerResolverInterface
{
    public function getController(Request $request): callable|false;
}
```

**ArgumentResolverInterface** - Determines controller method arguments:

```php
interface ArgumentResolverInterface
{
    public function getArguments(Request $request, callable $controller): array;
}
```

**ResetInterface** - Clean up state for long-running processes:

```php
interface ResetInterface
{
    public function reset(): void;
}
```

## Common patterns

### Create a basic HttpKernel

```php
use Symfony\Component\EventDispatcher\EventDispatcher;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\HttpKernel\HttpKernel;
use Symfony\Component\HttpKernel\Controller\ControllerResolver;
use Symfony\Component\HttpKernel\Controller\ArgumentResolver;

$dispatcher = new EventDispatcher();
$controllerResolver = new ControllerResolver();
$argumentResolver = new ArgumentResolver();
$requestStack = new RequestStack();

$kernel = new HttpKernel(
    $dispatcher,
    $controllerResolver,
    $requestStack,
    $argumentResolver
);

$response = $kernel->handle($request);
```

### Register a kernel event listener

```php
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpFoundation\Response;

$dispatcher->addListener(
    KernelEvents::REQUEST,
    function (RequestEvent $event): void {
        $event->getRequest()->attributes->set('custom', 'data');
        if ($event->isMainRequest() && $someCondition) {
            $event->setResponse(new Response('Early response'));
        }
    }
);
```

### Handle exceptions and create error responses

```php
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpException;

$dispatcher->addListener(
    KernelEvents::EXCEPTION,
    function (ExceptionEvent $event): void {
        $exception = $event->getThrowable();
        if ($exception instanceof HttpException) {
            $response = new Response(
                'Error: ' . $exception->getMessage(),
                $exception->getStatusCode(),
                $exception->getHeaders()
            );
            $event->setResponse($response);
        }
    }
);
```

### Modify response headers and cookies

```php
use Symfony\Component\HttpKernel\Event\ResponseEvent;

$dispatcher->addListener(
    KernelEvents::RESPONSE,
    function (ResponseEvent $event): void {
        $response = $event->getResponse();
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        if ($event->isMainRequest()) {
            $response->setMaxAge(3600);
            $response->setPublic();
        }
    }
);
```

### Transform controller result to Response

```php
use Symfony\Component\HttpKernel\Event\ViewEvent;
use Symfony\Component\HttpFoundation\JsonResponse;

$dispatcher->addListener(
    KernelEvents::VIEW,
    function (ViewEvent $event): void {
        $data = $event->getControllerResult();
        if (is_array($data)) {
            $event->setResponse(new JsonResponse($data));
        }
    }
);
```

### Register an event subscriber

```php
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\KernelEvents;

class MyKernelSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::REQUEST => ['onKernelRequest', 10],
            KernelEvents::RESPONSE => ['onKernelResponse', -10],
        ];
    }

    public function onKernelRequest(RequestEvent $event): void
    {
        // Handle request
    }

    public function onKernelResponse(ResponseEvent $event): void
    {
        // Handle response
    }
}

$dispatcher->addSubscriber(new MyKernelSubscriber());
```

### Create custom controller resolver

```php
use Symfony\Component\HttpKernel\Controller\ControllerResolver;
use Symfony\Component\HttpFoundation\Request;

class CustomControllerResolver extends ControllerResolver
{
    public function getController(Request $request): callable|false
    {
        $controller = parent::getController($request);
        if ($controller && $this->shouldWrap($controller)) {
            return $this->wrapController($controller);
        }
        return $controller;
    }
}
```

### Execute heavy tasks after response

```php
use Symfony\Component\HttpKernel\Event\TerminateEvent;

$dispatcher->addListener(
    KernelEvents::TERMINATE,
    function (TerminateEvent $event): void {
        mail('user@example.com', 'Subject', 'Body');
        $logger->log('heavy-task', 'Task completed');
    }
);
```

### Handle sub-requests (fragments)

```php
use Symfony\Component\HttpKernel\HttpKernelInterface;

$subRequest = Request::create('/fragment');
$response = $kernel->handle($subRequest, HttpKernelInterface::SUB_REQUEST);

$dispatcher->addListener(
    KernelEvents::REQUEST,
    function (RequestEvent $event): void {
        if (!$event->isMainRequest()) {
            $event->getRequest()->attributes->set('_fragment', true);
        }
    }
);
```

### Implement state cleanup for long-running processes

```php
use Symfony\Contracts\Service\ResetInterface;

class MyDatabaseConnection implements ResetInterface
{
    public function reset(): void
    {
        $this->connection->close();
        $this->connection = null;
    }
}
```

## Kernel Constants

```php
use Symfony\Component\HttpKernel\HttpKernelInterface;
use Symfony\Component\HttpKernel\KernelEvents;

HttpKernelInterface::MAIN_REQUEST  // Primary HTTP request (value: 1)
HttpKernelInterface::SUB_REQUEST   // Internal fragment/sub request (value: 2)

KernelEvents::REQUEST              // 'kernel.request'
KernelEvents::CONTROLLER           // 'kernel.controller'
KernelEvents::CONTROLLER_ARGUMENTS  // 'kernel.controller_arguments'
KernelEvents::VIEW                 // 'kernel.view'
KernelEvents::RESPONSE             // 'kernel.response'
KernelEvents::FINISH_REQUEST       // 'kernel.finish_request'
KernelEvents::TERMINATE            // 'kernel.terminate'
KernelEvents::EXCEPTION            // 'kernel.exception'
```

## Complete working example

```php
use Symfony\Component\EventDispatcher\EventDispatcher;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\RequestStack;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Controller\ArgumentResolver;
use Symfony\Component\HttpKernel\Controller\ControllerResolver;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\EventListener\RouterListener;
use Symfony\Component\HttpKernel\HttpKernel;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\Routing\Matcher\UrlMatcher;
use Symfony\Component\Routing\RequestContext;
use Symfony\Component\Routing\Route;
use Symfony\Component\Routing\RouteCollection;

$routes = new RouteCollection();
$routes->add('hello', new Route('/hello/{name}', [
    '_controller' => function (Request $request): Response {
        return new Response(
            sprintf("Hello %s", $request->attributes->get('name'))
        );
    }
]));

$dispatcher = new EventDispatcher();
$matcher = new UrlMatcher($routes, new RequestContext());
$dispatcher->addSubscriber(new RouterListener($matcher, new RequestStack()));

$dispatcher->addListener(KernelEvents::REQUEST, function (RequestEvent $event): void {
    $event->getRequest()->attributes->set('processed_at', date('Y-m-d H:i:s'));
});

$dispatcher->addListener(KernelEvents::RESPONSE, function (ResponseEvent $event): void {
    $event->getResponse()->headers->set('X-App-Version', '1.0');
});

$controllerResolver = new ControllerResolver();
$argumentResolver = new ArgumentResolver();
$requestStack = new RequestStack();

$kernel = new HttpKernel($dispatcher, $controllerResolver, $requestStack, $argumentResolver);
$request = Request::create('/hello/World');
$response = $kernel->handle($request);

$response->send();
$kernel->terminate($request, $response);
```

## Testing

Test kernel event listeners by creating mock requests and dispatching events:

```php
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\HttpKernelInterface;

class KernelListenerTest extends TestCase
{
    public function testRequestListener(): void
    {
        $request = Request::create('/test');
        $kernel = $this->createMock(HttpKernelInterface::class);
        $event = new RequestEvent($kernel, $request, HttpKernelInterface::MAIN_REQUEST);

        $listener = new MyListener();
        $listener->onKernelRequest($event);

        $this->assertEquals('expected', $event->getRequest()->attributes->get('key'));
    }
}
```

## Common pitfalls

- **Setting response in kernel.controller**: Use kernel.request instead to return early responses
- **Heavy tasks in kernel.response**: Move slow operations to kernel.terminate which runs after response
- **Not checking isMainRequest()**: Sub-requests should often be handled differently
- **Missing ResetInterface**: Long-running processes need ResetInterface for state cleanup
- **Exception swallowing**: Let exceptions propagate unless intentionally handling them
- **Not implementing error responses**: kernel.exception listeners should always set a Response
- **Modifying immutable objects**: Use headers->set() or setCookie() for Response headers
- **Listener priority**: Higher priorities execute first; use negative priorities for cleanup
- **Infinite loops with sub-requests**: Prevent recursion with request attributes or type checks

## Additional resources

- [Symfony HttpFoundation Component](https://symfony.com/doc/current/components/http_foundation.html) - Request and Response classes
- [Symfony EventDispatcher Component](https://symfony.com/doc/current/components/event_dispatcher.html) - Event system details
- [Symfony Routing Component](https://symfony.com/doc/current/components/routing.html) - URL matching and route resolution
- [Built-in Symfony Events Reference](https://symfony.com/doc/current/reference/events.html) - Complete event listing

# Django Async Support

## Overview

Django provides native support for asynchronous views, middleware, and ORM operations. Async views run efficiently under ASGI servers, enabling hundreds of concurrent connections without threads. Django also provides adapter functions (`sync_to_async` and `async_to_sync`) for bridging synchronous and asynchronous code, along with safety mechanisms to prevent mixing them incorrectly.

## Core Concepts

### Async Views

Function-based async views use `async def`:

```python
async def my_async_view(request):
    results = await some_async_operation()
    return HttpResponse(results)
```

Class-based views declare individual HTTP method handlers as async:

```python
from django.views import View

class MyView(View):
    async def get(self, request):
        data = await fetch_data()
        return JsonResponse(data)

    async def post(self, request):
        await process_request(request)
        return HttpResponse(status=201)
```

### WSGI vs ASGI Behavior

| Server | Async View Behavior |
|--------|-------------------|
| ASGI | Full async stack, hundreds of concurrent connections |
| WSGI | Creates one-off event loop per request, performance penalty |

For full async benefits, use an ASGI server (e.g., Daphne, Uvicorn, Hypercorn).

## Key Classes and Methods

### sync_to_async()

Wraps synchronous code to be called from async contexts:

```python
from asgiref.sync import sync_to_async

# As a wrapper
results = await sync_to_async(sync_function, thread_sensitive=True)(pk=123)

# As a decorator
@sync_to_async
def sync_function():
    return User.objects.all()
```

Parameters:
- `thread_sensitive=True` (default): runs in the same thread as other thread-sensitive functions. Required for Django ORM and most Django internals.
- `thread_sensitive=False`: runs in a new thread.

```python
# WRONG -- passes database connection across threads
await sync_to_async(connection.cursor)()

# CORRECT -- encapsulate database access in a single function
@sync_to_async
def get_user(user_id):
    return User.objects.get(id=user_id)

user = await get_user(42)
```

### async_to_sync()

Wraps asynchronous code to be called from synchronous contexts:

```python
from asgiref.sync import async_to_sync

async def get_data():
    return await some_async_call()

sync_get_data = async_to_sync(get_data)
result = sync_get_data()

# As a decorator
@async_to_sync
async def get_other_data():
    return await another_async_call()

result = get_other_data()  # Called synchronously
```

## Async ORM Operations

Django provides `a`-prefixed async versions of QuerySet methods:

```python
# Async iteration over querysets
async for author in Author.objects.filter(name__startswith="A"):
    book = await author.books.afirst()

# Async model save
async def make_book(*args, **kwargs):
    book = Book(...)
    await book.asave(using="secondary")

# Async create and relationship operations
async def make_book_with_tags(tags, *args, **kwargs):
    book = await Book.objects.acreate(...)
    await book.tags.aset(tags)
```

### Limitations

- Transactions do not yet work in async mode -- wrap transaction code with `sync_to_async()`
- Disable `CONN_MAX_AGE` setting when using async; use database backend connection pooling instead

## Async Safety

Django raises `SynchronousOnlyOperation` when async-unsafe operations are called from an async context:

```python
# This raises SynchronousOnlyOperation in async context
try:
    connection.cursor()
except SynchronousOnlyOperation:
    cursor = await sync_to_async(connection.cursor)()
```

### Override for Development

```python
import os
os.environ["DJANGO_ALLOW_ASYNC_UNSAFE"] = "true"
```

For IPython/Jupyter notebooks:

```
%autoawait off
```

Never enable this in production with concurrent access -- it risks data corruption.

## Supported Decorators

All these decorators work with both sync and async views:

```python
from django.views.decorators.cache import never_cache
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET

@never_cache
async def my_view(request):
    ...

@csrf_exempt
async def my_api_view(request):
    ...

@require_GET
async def my_read_view(request):
    ...
```

Full list of async-compatible decorators:
- Cache: `cache_control()`, `never_cache()`
- CSRF: `csrf_exempt()`, `csrf_protect()`, `ensure_csrf_cookie()`, `requires_csrf_token()`
- Conditional: `condition()`, `etag()`, `last_modified()`
- HTTP methods: `require_http_methods()`, `require_GET()`, `require_POST()`, `require_safe()`
- Vary: `vary_on_cookie()`, `vary_on_headers()`
- Other: `gzip_page()`, `sensitive_variables()`, `sensitive_post_parameters()`
- CSP: `csp_override()`, `csp_report_only_override()`

## Async Middleware

Middleware can support both sync and async contexts. Django's built-in middleware partially supports this. Check for adaptation messages in the `django.request` logger:

```
Asynchronous handler adapted for middleware ...
```

Synchronous middleware between an ASGI server and an async view causes context switches that degrade async performance.

## Common Patterns

### Handling Client Disconnects

```python
import asyncio

async def long_running_view(request):
    try:
        result = await expensive_async_operation()
        return JsonResponse(result)
    except asyncio.CancelledError:
        # Client disconnected -- clean up resources
        await cleanup()
        raise
```

### Mixing Sync and Async Code

```python
from asgiref.sync import sync_to_async

async def my_view(request):
    # Call sync ORM code from async view
    users = await sync_to_async(list)(User.objects.filter(is_active=True))

    # Call sync function
    result = await sync_to_async(some_sync_library_call)(data)

    return JsonResponse({"users": len(users), "result": result})
```

### Parallel Async Operations

```python
import asyncio

async def dashboard_view(request):
    # Run multiple async operations concurrently
    users, orders, stats = await asyncio.gather(
        get_users(),
        get_orders(),
        get_stats(),
    )
    return JsonResponse({
        "users": users,
        "orders": orders,
        "stats": stats,
    })
```

## Configuration

### ASGI Setup

```python
# asgi.py
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_asgi_application()
```

### Database Connection Settings

```python
# Disable persistent connections for async
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydb",
        "CONN_MAX_AGE": 0,  # Required for async
    }
}
```

## Performance Considerations

| Scenario | Performance |
|----------|------------|
| ASGI + all async middleware + async views | Best for async workloads |
| ASGI + sync middleware + async views | Context-switch overhead (~1ms per switch) |
| WSGI + async views | One-off event loop per request, worst async performance |
| ASGI + all sync views | May still benefit from async request handling |

- Each sync-to-async or async-to-sync transition costs approximately 1ms
- Synchronous middleware in the ASGI stack forces context switches on every request
- For I/O-bound workloads, async provides significant throughput gains
- For CPU-bound workloads, async provides minimal benefit

## Best Practices

- Use ASGI servers for production async deployments (Daphne, Uvicorn, Hypercorn)
- Keep the entire middleware stack async to avoid context-switch penalties
- Use `thread_sensitive=True` (the default) when calling Django ORM from async code
- Never pass database connections across thread boundaries
- Disable `CONN_MAX_AGE` when using async views; use database-level connection pooling
- Wrap transaction blocks with `sync_to_async()` until native async transaction support lands
- Handle `asyncio.CancelledError` for long-running async views to clean up on client disconnect
- Avoid `DJANGO_ALLOW_ASYNC_UNSAFE` in production
- Use `asyncio.gather()` for concurrent I/O operations within a single view
- Profile context-switch overhead when mixing sync and async code in the same request path

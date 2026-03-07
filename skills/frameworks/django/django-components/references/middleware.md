# Django Middleware

## Overview

Middleware is a framework of hooks into Django's request/response processing. It provides a low-level plugin system for globally altering Django's input or output. Each middleware component processes requests on the way in and responses on the way out, forming an "onion" layered architecture.

## Middleware Architecture

```
Request  ->  Middleware 1  ->  Middleware 2  ->  ... ->  View
Response <-  Middleware 1  <-  Middleware 2  <-  ... <-  View
```

Middleware is activated via the `MIDDLEWARE` setting, which is an ordered list of strings:

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
```

## Writing Custom Middleware

### Function-Based Middleware

```python
def simple_middleware(get_response):
    # One-time configuration and initialization (called once at server start).

    def middleware(request):
        # Code executed for each request BEFORE the view.

        response = get_response(request)

        # Code executed for each request AFTER the view.

        return response

    return middleware
```

### Class-Based Middleware

```python
class SimpleMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
        # One-time configuration and initialization.

    def __call__(self, request):
        # Code executed for each request BEFORE the view.

        response = self.get_response(request)

        # Code executed for each request AFTER the view.

        return response
```

## Lifecycle Methods

### __init__(get_response)

Called once when the web server starts. Must accept only `get_response`. Used for one-time setup. Raise `MiddlewareNotUsed` to disable:

```python
from django.core.exceptions import MiddlewareNotUsed

class ConditionalMiddleware:
    def __init__(self, get_response):
        if not some_condition:
            raise MiddlewareNotUsed("Middleware not applicable")
        self.get_response = get_response
```

### __call__(request)

Called once per request. Executes code before and after `get_response(request)`.

### process_view(request, view_func, view_args, view_kwargs)

Called just before Django calls the view. Return `None` to continue processing, or an `HttpResponse` to short-circuit:

```python
class MyMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        return response

    def process_view(self, request, view_func, view_args, view_kwargs):
        # Return None to continue, or HttpResponse to short-circuit
        return None
```

### process_exception(request, exception)

Called when a view raises an exception. Return `None` for default handling, or an `HttpResponse` to handle the exception:

```python
    def process_exception(self, request, exception):
        if isinstance(exception, SpecificError):
            return HttpResponse("Handled error", status=500)
        return None
```

### process_template_response(request, response)

Called after the view finishes, only if the response has a `render()` method (e.g., `TemplateResponse`). Runs in reverse middleware order:

```python
    def process_template_response(self, request, response):
        response.context_data["extra_key"] = "extra_value"
        return response
```

## Async Middleware

### Function-Based Async Middleware

```python
from asgiref.sync import iscoroutinefunction
from django.utils.decorators import sync_and_async_middleware

@sync_and_async_middleware
def simple_middleware(get_response):
    if iscoroutinefunction(get_response):
        async def middleware(request):
            response = await get_response(request)
            return response
    else:
        def middleware(request):
            response = get_response(request)
            return response
    return middleware
```

### Class-Based Async Middleware

```python
from asgiref.sync import iscoroutinefunction, markcoroutinefunction

class AsyncMiddleware:
    async_capable = True
    sync_capable = False

    def __init__(self, get_response):
        self.get_response = get_response
        if iscoroutinefunction(self.get_response):
            markcoroutinefunction(self)

    async def __call__(self, request):
        response = await self.get_response(request)
        return response
```

### Capability Flags

| Flag | Default | Meaning |
|------|---------|---------|
| `sync_capable` | `True` | Can handle synchronous requests |
| `async_capable` | `False` | Can handle asynchronous requests |

## Streaming Responses

Check for streaming before accessing content:

```python
if response.streaming:
    response.streaming_content = wrap_streaming_content(response.streaming_content)
else:
    response.content = alter_content(response.content)

def wrap_streaming_content(content):
    for chunk in content:
        yield alter_content(chunk)
```

## Built-in Middleware

### SecurityMiddleware

`django.middleware.security.SecurityMiddleware`

Provides HTTPS enforcement, HSTS, referrer policy, and content type sniffing protection:

```python
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
```

### SessionMiddleware

`django.contrib.sessions.middleware.SessionMiddleware`

Enables session support. Provides `request.session` dictionary.

### CommonMiddleware

`django.middleware.common.CommonMiddleware`

URL rewriting and convenience features:

```python
APPEND_SLASH = True   # Adds trailing slash to URLs
PREPEND_WWW = True    # Adds www. prefix
DISALLOWED_USER_AGENTS = [re.compile(r"bad-bot")]
```

Exclude specific views from `APPEND_SLASH`:

```python
from django.views.decorators.common import no_append_slash

@no_append_slash
def my_api_view(request):
    pass
```

### CsrfViewMiddleware

`django.middleware.csrf.CsrfViewMiddleware`

Protects against Cross-Site Request Forgery by validating CSRF tokens on POST requests.

### AuthenticationMiddleware

`django.contrib.auth.middleware.AuthenticationMiddleware`

Attaches the `user` attribute to `HttpRequest` representing the currently logged-in user.

#### LoginRequiredMiddleware

Redirects all unauthenticated requests to the login page:

```python
MIDDLEWARE = [
    ...
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.auth.middleware.LoginRequiredMiddleware",
    ...
]

LOGIN_URL = "/accounts/login/"
```

Exempt specific views:

```python
from django.contrib.auth.decorators import login_not_required

@login_not_required
def public_view(request):
    pass
```

### MessageMiddleware

`django.contrib.messages.middleware.MessageMiddleware`

Enables cookie- and session-based one-time messaging (debug, info, success, warning, error levels).

### XFrameOptionsMiddleware

`django.middleware.clickjacking.XFrameOptionsMiddleware`

Sets `X-Frame-Options` header to prevent clickjacking by blocking iframe embedding.

### GZipMiddleware

`django.middleware.gzip.GZipMiddleware`

Compresses responses for browsers supporting GZip. Only compresses content >= 200 bytes. Implements Heal The Breach (HTB) mitigation:

```python
class CustomGZipMiddleware(GZipMiddleware):
    max_random_bytes = 50
```

### LocaleMiddleware

`django.middleware.locale.LocaleMiddleware`

Enables language selection based on request data (Accept-Language header, URL prefix, session/cookie):

```python
LANGUAGE_CODE = "en-us"
USE_I18N = True
LANGUAGES = [
    ("en", "English"),
    ("es", "Spanish"),
    ("fr", "French"),
]
```

### Cache Middleware

- `UpdateCacheMiddleware` -- stores responses in cache (place near top)
- `FetchFromCacheMiddleware` -- retrieves cached responses (place near bottom)

### ConditionalGetMiddleware

Handles conditional GET operations using ETag and Last-Modified headers.

### ContentSecurityPolicyMiddleware (Django 6.0+)

Implements Content Security Policy headers:

```python
SECURE_CSP = {
    "default-src": ["'self'"],
    "script-src": ["'self'", "cdn.example.com"],
}
```

## Middleware Ordering

Order is critical. Recommended ordering:

```python
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",         # 1. Security first
    "django.middleware.cache.UpdateCacheMiddleware",          # 2. Cache (store)
    "django.middleware.gzip.GZipMiddleware",                  # 3. Before body modifiers
    "django.contrib.sessions.middleware.SessionMiddleware",   # 4. Before auth/CSRF
    "django.middleware.http.ConditionalGetMiddleware",        # 5. Conditional GET
    "django.middleware.locale.LocaleMiddleware",              # 6. After session
    "django.middleware.common.CommonMiddleware",              # 7. URL rewriting
    "django.middleware.csrf.CsrfViewMiddleware",              # 8. Before views
    "django.contrib.auth.middleware.AuthenticationMiddleware",# 9. After session
    "django.contrib.auth.middleware.LoginRequiredMiddleware", # 10. After auth
    "django.contrib.messages.middleware.MessageMiddleware",   # 11. After session
    "django.middleware.cache.FetchFromCacheMiddleware",       # 12. After Vary modifiers
    "django.middleware.csp.ContentSecurityPolicyMiddleware",  # 13. CSP headers
]
```

### Key Ordering Rules

- **SecurityMiddleware**: Near the top to avoid unnecessary processing on insecure requests
- **GZipMiddleware**: Before any middleware that modifies the response body
- **SessionMiddleware**: Before authentication, CSRF, and messages middleware
- **CsrfViewMiddleware**: Before any view middleware that assumes CSRF validation
- **AuthenticationMiddleware**: After SessionMiddleware (depends on sessions)
- **FetchFromCacheMiddleware**: Near the bottom, after all Vary header modifiers
- **Fallback middleware**: At the very bottom (FlatpageFallbackMiddleware, RedirectFallbackMiddleware)

## Exception Handling

Django converts exceptions to appropriate HTTP responses automatically:
- Specific exceptions map to 4xx status codes
- Unknown exceptions map to 500
- Set `DEBUG_PROPAGATE_EXCEPTIONS = True` to skip conversion

## Best Practices

- Keep middleware lightweight -- it runs on every request
- Use `process_view` only when you need access to the view function before execution
- Check `response.streaming` before accessing `response.content`
- Use `MiddlewareNotUsed` to conditionally disable middleware
- Place middleware that short-circuits early near the top of the stack
- For async projects, implement both sync and async paths using `@sync_and_async_middleware`
- Test middleware in isolation with `RequestFactory`

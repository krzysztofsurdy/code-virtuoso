# Django Views

## Overview

A view is a Python function (or class) that takes a web request and returns a web response. Views contain the logic necessary to return a response -- HTML content, a redirect, a 404 error, JSON data, an image, or anything else. Views are conventionally placed in a `views.py` file within each Django app.

## Function-Based Views

### Basic View Structure

Every view function takes an `HttpRequest` object as its first parameter and must return an `HttpResponse`:

```python
from django.http import HttpResponse
import datetime

def current_datetime(request):
    now = datetime.datetime.now()
    html = "<html><body>It is now %s.</body></html>" % now
    return HttpResponse(html)
```

### Async Views

Views can be asynchronous using `async def`. Django detects and runs them in an async context automatically:

```python
import datetime
from django.http import HttpResponse

async def current_datetime(request):
    now = datetime.datetime.now()
    html = "<html><body>It is now %s.</body></html>" % now
    return HttpResponse(html)
```

An ASGI server is required for full async performance benefits.

## Shortcut Functions

### render()

```python
render(request, template_name, context=None, content_type=None, status=None, using=None)
```

Combines a template with a context dictionary and returns an `HttpResponse` with rendered text:

```python
from django.shortcuts import render

def my_view(request):
    return render(
        request,
        "myapp/index.html",
        {"foo": "bar"},
        content_type="application/xhtml+xml",
    )
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `request` | The request object (required) | -- |
| `template_name` | Template name or sequence of names (required) | -- |
| `context` | Dictionary of template context values | `None` |
| `content_type` | MIME type for the response | `text/html` |
| `status` | HTTP status code | `200` |
| `using` | Template engine name | `None` |

### redirect()

```python
redirect(to, *args, permanent=False, preserve_request=False, **kwargs)
```

Returns an `HttpResponseRedirect` to the appropriate URL. The `to` argument accepts a model (calls `get_absolute_url()`), a view name (uses `reverse()`), or a URL string:

```python
from django.shortcuts import redirect

# Redirect to a model's absolute URL
def my_view(request):
    obj = MyModel.objects.get(...)
    return redirect(obj)

# Redirect to a named view
def my_view(request):
    return redirect("some-view-name", foo="bar")

# Redirect to a hardcoded URL
def my_view(request):
    return redirect("/some/url/")

# Permanent redirect preserving request method
def my_view(request):
    return redirect(obj, permanent=True, preserve_request=True)
```

| permanent | preserve_request | HTTP Status |
|-----------|------------------|-------------|
| `False` | `False` | 302 |
| `True` | `False` | 301 |
| `False` | `True` | 307 |
| `True` | `True` | 308 |

### get_object_or_404()

Calls `get()` on a model manager and raises `Http404` instead of `DoesNotExist`:

```python
from django.shortcuts import get_object_or_404

def my_view(request):
    obj = get_object_or_404(MyModel, pk=1)
```

Works with models, managers, and querysets:

```python
# With a QuerySet
queryset = Book.objects.filter(title__startswith="M")
get_object_or_404(queryset, pk=1)

# With a custom manager
get_object_or_404(Book.dahl_objects, title="Matilda")

# With a related manager
author = Author.objects.get(name="Roald Dahl")
get_object_or_404(author.book_set, title="Matilda")
```

Async version: `aget_object_or_404()`.

### get_list_or_404()

Returns the result of `filter()` cast to a list, raising `Http404` if the list is empty:

```python
from django.shortcuts import get_list_or_404

def my_view(request):
    my_objects = get_list_or_404(MyModel, published=True)
```

Async version: `aget_list_or_404()`.

## View Decorators

### HTTP Method Decorators

Located in `django.views.decorators.http`:

```python
from django.views.decorators.http import require_http_methods, require_GET, require_POST, require_safe

@require_http_methods(["GET", "POST"])
def my_view(request):
    pass

@require_GET
def get_only_view(request):
    pass

@require_POST
def post_only_view(request):
    pass

@require_safe  # GET and HEAD only
def safe_view(request):
    pass
```

Returns `HttpResponseNotAllowed` (405) if the request method is not in the allowed list. Prefer `require_safe` over `require_GET` as it also handles HEAD requests.

### Conditional View Decorators

Control caching behavior:

```python
from django.views.decorators.http import condition, etag, last_modified

@condition(etag_func=None, last_modified_func=None)
def my_view(request):
    pass

@etag(etag_func)
def my_view(request):
    pass

@last_modified(last_modified_func)
def my_view(request):
    pass
```

### GZip Compression

```python
from django.views.decorators.gzip import gzip_page

@gzip_page
def my_view(request):
    pass
```

### Vary Headers

```python
from django.views.decorators.vary import vary_on_cookie, vary_on_headers

@vary_on_cookie
def my_view(request):
    pass

@vary_on_headers("User-Agent")
def my_view(request):
    pass
```

## Returning Errors

### HTTP Error Responses

Use `HttpResponse` subclasses for specific status codes:

```python
from django.http import HttpResponse, HttpResponseNotFound

def my_view(request):
    if foo:
        return HttpResponseNotFound("<h1>Page not found</h1>")
    else:
        return HttpResponse("<h1>Page was found</h1>")
```

Or pass a custom status code:

```python
def my_view(request):
    return HttpResponse(status=201)
```

### Http404 Exception

Raise `Http404` for Django to catch and return the standard 404 page:

```python
from django.http import Http404
from django.shortcuts import render
from polls.models import Poll

def detail(request, poll_id):
    try:
        p = Poll.objects.get(pk=poll_id)
    except Poll.DoesNotExist:
        raise Http404("Poll does not exist")
    return render(request, "polls/detail.html", {"poll": p})
```

Create a `404.html` template at the root of your template directory for custom 404 pages (used when `DEBUG = False`).

## Built-in Error Views

### Customizing Error Handlers

Override in your root URLconf:

```python
handler400 = "mysite.views.my_custom_bad_request_view"
handler403 = "mysite.views.my_custom_permission_denied_view"
handler404 = "mysite.views.my_custom_page_not_found_view"
handler500 = "mysite.views.my_custom_error_view"
```

### Default Error View Functions

| View | Function | Template | Context Variables |
|------|----------|----------|-------------------|
| 404 | `defaults.page_not_found(request, exception, template_name='404.html')` | `404.html` | `request_path`, `exception` |
| 500 | `defaults.server_error(request, template_name='500.html')` | `500.html` | None (empty Context) |
| 403 | `defaults.permission_denied(request, exception, template_name='403.html')` | `403.html` | `exception` |
| 400 | `defaults.bad_request(request, exception, template_name='400.html')` | `400.html` | None |

### Raising 403 Forbidden

```python
from django.core.exceptions import PermissionDenied

def edit(request, pk):
    if not request.user.is_staff:
        raise PermissionDenied
```

## Serving Static Files in Development

```python
from django.conf import settings
from django.urls import re_path
from django.views.static import serve

if settings.DEBUG:
    urlpatterns += [
        re_path(
            r"^media/(?P<path>.*)$",
            serve,
            {"document_root": settings.MEDIA_ROOT},
        ),
    ]
```

## Best Practices

- Keep view functions focused -- delegate complex logic to services or model methods
- Use shortcut functions (`render`, `redirect`, `get_object_or_404`) to reduce boilerplate
- Use `require_safe` instead of `require_GET` to properly handle HEAD requests
- Return appropriate HTTP status codes for different outcomes
- Use async views when performing I/O-bound operations under ASGI
- Create custom error templates (`404.html`, `500.html`) at the template root
- Use `PermissionDenied` and `Http404` exceptions rather than manually constructing error responses

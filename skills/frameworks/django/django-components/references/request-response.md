# Django Request and Response Objects

## Overview

Django uses `HttpRequest` and `HttpResponse` objects to pass state through the system. When a request comes in, Django creates an `HttpRequest` object containing metadata about the request and passes it as the first argument to the view. Each view is responsible for returning an `HttpResponse` object.

## HttpRequest

### Request Data Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `GET` | `QueryDict` | Dictionary-like object of GET parameters |
| `POST` | `QueryDict` | Dictionary-like object of POST form data |
| `FILES` | `MultiValueDict` | Uploaded files (only with `enctype="multipart/form-data"`) |
| `COOKIES` | `dict` | All cookies as strings |
| `body` | `bytes` | Raw request body as bytestring |

### Request Information Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `method` | `str` | HTTP method (`"GET"`, `"POST"`, etc.) |
| `path` | `str` | Full path excluding scheme, domain, query string |
| `path_info` | `str` | Path after script prefix |
| `scheme` | `str` | `"http"` or `"https"` |
| `content_type` | `str` | MIME type from Content-Type header |
| `content_params` | `dict` | Parameters from Content-Type header |
| `encoding` | `str` | Encoding for form data (or `None`) |

### Headers and Metadata

**`META`** -- dictionary of all HTTP headers and server variables:

```python
request.META["CONTENT_LENGTH"]
request.META["CONTENT_TYPE"]
request.META["HTTP_ACCEPT"]
request.META["HTTP_HOST"]
request.META["HTTP_REFERER"]
request.META["HTTP_USER_AGENT"]
request.META["QUERY_STRING"]
request.META["REMOTE_ADDR"]
request.META["SERVER_NAME"]
request.META["SERVER_PORT"]
```

HTTP headers in META are uppercased, hyphens replaced with underscores, prefixed with `HTTP_`.

**`headers`** -- case-insensitive dict-like access to HTTP headers:

```python
request.headers["User-Agent"]
request.headers["user-agent"]  # case-insensitive
request.headers.get("User-Agent")

# In templates, use underscores for hyphens:
# {{ request.headers.user_agent }}
```

### Middleware-Set Attributes

| Attribute | Set By | Description |
|-----------|--------|-------------|
| `user` | `AuthenticationMiddleware` | Current user (`AUTH_USER_MODEL` instance) |
| `session` | `SessionMiddleware` | Dictionary-like session object |
| `site` | `CurrentSiteMiddleware` | Current site instance |

### HttpRequest Methods

#### URL and Host Information

```python
request.get_host()
# "127.0.0.1:8000"

request.get_port()
# "8000"

request.get_full_path()
# "/music/bands/the_beatles/?print=true"

request.get_full_path_info()
# Like get_full_path() but uses path_info

request.build_absolute_uri(location=None)
# "https://example.com/music/bands/the_beatles/?print=true"
request.build_absolute_uri("/bands/")
# "https://example.com/bands/"
```

#### Content Negotiation

```python
request.accepts("text/html")
# True if Accept header matches

request.get_preferred_type(["text/html", "application/json"])
# Returns preferred MIME type or None (Django 5.2+)
```

#### Security

```python
request.is_secure()
# True if HTTPS

request.get_signed_cookie("name", default=RAISE_ERROR, salt="", max_age=None)
# Returns signed cookie value or raises BadSignature/SignatureExpired
```

#### File-Like Interface

```python
request.read(size=None)
request.readline()
request.readlines()

# Iterable -- useful for streaming parsers
for element in ET.iterparse(request):
    process(element)
```

## QueryDict

Immutable dictionary-like object in `HttpRequest.GET` and `HttpRequest.POST` that handles multiple values per key.

### Creating QueryDict

```python
from django.http import QueryDict

QueryDict("a=1&a=2&c=3")
# <QueryDict: {'a': ['1', '2'], 'c': ['3']}>

QueryDict(mutable=True)
# Mutable QueryDict

QueryDict.fromkeys(["a", "a", "b"], value="val")
# <QueryDict: {'a': ['val', 'val'], 'b': ['val']}>
```

### Key Methods

```python
q = QueryDict("a=1&a=2&a=3")

q["a"]                    # "3" (last value)
q.get("a")                # "3"
q.get("missing", "default")  # "default"
q.getlist("a")            # ["1", "2", "3"]

# Iteration
q.items()                 # Returns last value per key
q.lists()                 # Returns all values per key
q.values()                # Returns last values

# URL encoding
q.urlencode()             # "a=1&a=2&a=3"
q.urlencode(safe="/")     # URL-encodes with safe characters

# Mutable operations (mutable QueryDict only)
q = q.copy()              # Returns mutable copy
q["b"] = "value"
q.setlist("a", ["1", "2"])
q.appendlist("a", "3")
q.update({"c": "4"})
q.pop("a")
q.dict()                  # {"a": "3"} -- last values only
```

## HttpResponse

### Creating Responses

```python
from django.http import HttpResponse

response = HttpResponse("Here's the text of the web page.")
response = HttpResponse(content_type="text/plain")
response = HttpResponse(b"Bytestrings are also accepted.")
response = HttpResponse(headers={"Age": 120})

# Incremental content
response = HttpResponse()
response.write("<p>First paragraph.</p>")
response.write("<p>Second paragraph.</p>")
```

### Setting Headers

```python
response.headers["Age"] = 120
del response.headers["Age"]

# File attachment
response = HttpResponse(
    my_data,
    headers={
        "Content-Type": "application/vnd.ms-excel",
        "Content-Disposition": 'attachment; filename="foo.xls"',
    },
)
```

### Key Attributes

| Attribute | Description |
|-----------|-------------|
| `content` | Bytestring of response content |
| `text` | String content decoded using charset (Django 5.2+) |
| `charset` | Charset for encoding |
| `status_code` | HTTP status code (default: 200) |
| `reason_phrase` | HTTP reason phrase |
| `headers` | Case-insensitive header dict |
| `cookies` | `SimpleCookie` object |
| `streaming` | Always `False` for HttpResponse |
| `closed` | `True` if response has been closed |

### Cookie Methods

```python
response.set_cookie(
    key,
    value="",
    max_age=None,       # timedelta or seconds
    expires=None,       # string or datetime
    path="/",
    domain=None,
    secure=False,       # HTTPS only
    httponly=False,      # prevent JS access
    samesite=None,      # "Strict", "Lax", or "None"
)

response.set_signed_cookie(key, value, salt="", max_age=None, ...)
response.delete_cookie(key, path="/", domain=None, samesite=None)
```

## HttpResponse Subclasses

| Class | Status | Notes |
|-------|--------|-------|
| `HttpResponseRedirect` | 302 | Requires URL argument |
| `HttpResponsePermanentRedirect` | 301 | Requires URL argument |
| `HttpResponseNotModified` | 304 | No content body |
| `HttpResponseBadRequest` | 400 | |
| `HttpResponseNotFound` | 404 | |
| `HttpResponseForbidden` | 403 | |
| `HttpResponseNotAllowed` | 405 | Requires allowed methods list |
| `HttpResponseGone` | 410 | |
| `HttpResponseServerError` | 500 | |

Redirect classes support `preserve_request=True` for 307/308 status codes:

```python
HttpResponseRedirect("/path/", preserve_request=True)   # 307
HttpResponsePermanentRedirect("/path/", preserve_request=True)  # 308
```

### Custom Response Classes

```python
from http import HTTPStatus
from django.http import HttpResponse

class HttpResponseNoContent(HttpResponse):
    status_code = HTTPStatus.NO_CONTENT
```

## JsonResponse

```python
from django.http import JsonResponse

response = JsonResponse({"foo": "bar"})
# Content-Type: application/json
# b'{"foo": "bar"}'

# Non-dict objects require safe=False
response = JsonResponse([1, 2, 3], safe=False)

# Custom encoder
response = JsonResponse(data, encoder=MyJSONEncoder)

# Pretty printing
response = JsonResponse(data, json_dumps_params={"indent": 2})
```

## StreamingHttpResponse

For large responses that should not be loaded entirely into memory:

```python
from django.http import StreamingHttpResponse

def file_iterator():
    for i in range(1000):
        yield f"chunk {i}\n"

response = StreamingHttpResponse(file_iterator())
response.headers["Content-Type"] = "text/plain"
```

### Key Differences from HttpResponse

- Takes an iterator yielding bytestrings
- No `content` or `text` attributes -- use `streaming_content`
- No `tell()` or `write()` methods
- `streaming` is always `True`
- Supports async iterators under ASGI

### Handling Client Disconnects (ASGI)

```python
import asyncio

async def streaming_response():
    try:
        async for chunk in my_streaming_iterator():
            yield chunk
    except asyncio.CancelledError:
        raise
```

## FileResponse

Optimized for binary file streaming:

```python
from django.http import FileResponse

# Stream a file
response = FileResponse(open("myfile.png", "rb"))

# As download attachment
response = FileResponse(
    open("myfile.pdf", "rb"),
    as_attachment=True,
    filename="document.pdf",
)

# From BytesIO
import io
response = FileResponse(io.BytesIO(content))
```

Features:
- Subclass of `StreamingHttpResponse`
- Uses `wsgi.file_wrapper` when available
- Auto-sets `Content-Length`, `Content-Type`, and `Content-Disposition`
- File automatically closed after streaming

## TemplateResponse

Retains template and context for modification after view construction. Rendering is deferred until needed:

```python
from django.template.response import TemplateResponse

def blog_index(request):
    return TemplateResponse(
        request, "entry_list.html", {"entries": Entry.objects.all()}
    )
```

### SimpleTemplateResponse

Base class without request awareness:

```python
from django.template.response import SimpleTemplateResponse

response = SimpleTemplateResponse("template.html", {"key": "value"})
```

### Key Attributes and Methods

| Attribute/Method | Description |
|------------------|-------------|
| `template_name` | Template to render |
| `context_data` | Context dictionary |
| `rendered_content` | Current rendered content |
| `is_rendered` | Whether content has been rendered |
| `render()` | Renders the template (effective only on first call) |
| `add_post_render_callback(callback)` | Register post-render callback |

### Post-Render Callbacks

```python
def my_render_callback(response):
    do_post_processing()

def my_view(request):
    response = TemplateResponse(request, "mytemplate.html", {})
    response.add_post_render_callback(my_render_callback)
    return response
```

### Rendering Behavior

A `TemplateResponse` renders in three circumstances:
1. Explicit `render()` call
2. Assignment to `response.content`
3. After template response middleware, before response middleware

Only the first render sets the content. To re-render with a new template:

```python
t = TemplateResponse(request, "original.html", {})
t.render()
t.template_name = "new.html"
t.content = t.rendered_content  # Force re-render
```

## Best Practices

- Use `request.headers` instead of `request.META` for HTTP headers
- Use `JsonResponse` instead of manually serializing JSON with `HttpResponse`
- Use `FileResponse` for binary file downloads instead of `HttpResponse`
- Use `StreamingHttpResponse` for large datasets to avoid memory issues
- Use `TemplateResponse` when middleware needs to modify template context
- Check `request.method` explicitly rather than relying on URL routing for method dispatch
- Use `QueryDict.getlist()` when expecting multiple values for the same key
- Use `get_preferred_type()` over `accepts()` for content negotiation (Django 5.2+)

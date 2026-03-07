# Django URL Configuration

## Overview

Django's URL dispatcher maps URL patterns to view functions using a URLconf (URL configuration) module. A URLconf is a Python module containing a `urlpatterns` list that maps URL patterns to views. Django processes URL patterns in order, calling the first matching view with the captured parameters.

## How Django Processes Requests

1. Django determines the root URLconf from `ROOT_URLCONF` setting (or `HttpRequest.urlconf`)
2. Loads the module and finds the `urlpatterns` variable
3. Iterates through patterns in order until finding a match against `path_info`
4. Calls the matched view with an `HttpRequest` instance plus captured arguments
5. If no match is found, invokes the error-handling view

## Core Functions

### path()

```python
path(route, view, kwargs=None, name=None)
```

The primary function for defining URL patterns:

```python
from django.urls import path
from . import views

urlpatterns = [
    path("articles/2003/", views.special_case_2003),
    path("articles/<int:year>/", views.year_archive),
    path("articles/<int:year>/<int:month>/", views.month_archive),
    path("articles/<int:year>/<int:month>/<slug:slug>/", views.article_detail),
]
```

| Parameter | Description |
|-----------|-------------|
| `route` | URL pattern string with optional angle-bracket captures |
| `view` | View function, `as_view()` result, or `include()` |
| `kwargs` | Extra arguments dict passed to the view |
| `name` | Name for reverse URL resolution |

### re_path()

For complex URL patterns using regular expressions:

```python
from django.urls import re_path
from . import views

urlpatterns = [
    re_path(r"^articles/(?P<year>[0-9]{4})/$", views.year_archive),
    re_path(r"^articles/(?P<year>[0-9]{4})/(?P<month>[0-9]{2})/$", views.month_archive),
    re_path(
        r"^articles/(?P<year>[0-9]{4})/(?P<month>[0-9]{2})/(?P<slug>[\w-]+)/$",
        views.article_detail,
    ),
]
```

Use named groups `(?P<name>pattern)` -- unnamed groups pass as positional arguments. Use non-capturing groups `(?:...)` to avoid unwanted captures:

```python
# Good -- only captures page_number
re_path(r"^comments/(?:page-(?P<page_number>[0-9]+)/)?$", comments)
```

### include()

Includes another URLconf module:

```python
from django.urls import include, path

urlpatterns = [
    path("community/", include("aggregator.urls")),
    path("contact/", include("contact.urls")),
]
```

Include with a pattern list:

```python
extra_patterns = [
    path("reports/", credit_views.report),
    path("reports/<int:id>/", credit_views.report),
    path("charge/", credit_views.charge),
]

urlpatterns = [
    path("credit/", include(extra_patterns)),
]
```

Inline include to reduce redundancy:

```python
urlpatterns = [
    path(
        "<page_slug>-<page_id>/",
        include([
            path("history/", views.history),
            path("edit/", views.edit),
            path("discuss/", views.discuss),
            path("permissions/", views.permissions),
        ]),
    ),
]
```

### register_converter()

Registers a custom path converter:

```python
from django.urls import path, register_converter

class FourDigitYearConverter:
    regex = "[0-9]{4}"

    def to_python(self, value):
        return int(value)

    def to_url(self, value):
        return "%04d" % value

register_converter(FourDigitYearConverter, "yyyy")

urlpatterns = [
    path("articles/<yyyy:year>/", views.year_archive),
]
```

## Path Converters

Built-in converters for use with `path()`:

| Converter | Matches | Example |
|-----------|---------|---------|
| `str` | Any non-empty string excluding `/` (default) | `<str:username>` or `<username>` |
| `int` | Zero or any positive integer | `<int:year>` |
| `slug` | ASCII letters, numbers, hyphens, underscores | `<slug:post_slug>` |
| `uuid` | Formatted UUID (lowercase with dashes) | `<uuid:pk>` |
| `path` | Any non-empty string including `/` | `<path:file_path>` |

## Default View Arguments

Specify defaults for URL parameters to handle multiple patterns with one view:

```python
urlpatterns = [
    path("blog/", views.page),
    path("blog/page<int:num>/", views.page),
]

def page(request, num=1):
    ...
```

## Passing Extra Options to Views

```python
urlpatterns = [
    path("blog/<int:year>/", views.year_archive, {"foo": "bar"}),
]

# View receives: request, year=2005, foo='bar'
```

Extra options passed to `include()` apply to every view in the included URLconf:

```python
urlpatterns = [
    path("blog/", include("inner"), {"blog_id": 3}),
]
```

## Captured Parameters with include()

Captured parameters from the parent URLconf are passed to all views in the included URLconf:

```python
# main urls.py
urlpatterns = [
    path("<username>/blog/", include("foo.urls.blog")),
]

# foo/urls/blog.py -- all views receive 'username'
urlpatterns = [
    path("", views.blog.index),
    path("archive/", views.blog.archive),
]
```

## Reverse URL Resolution

### Naming URL Patterns

```python
urlpatterns = [
    path("articles/<int:year>/", views.year_archive, name="news-year-archive"),
]
```

### Using reverse() in Python Code

```python
from django.http import HttpResponseRedirect
from django.urls import reverse

def redirect_to_year(request):
    year = 2006
    return HttpResponseRedirect(reverse("news-year-archive", args=(year,)))
```

### Using {% url %} in Templates

```html
<a href="{% url 'news-year-archive' 2012 %}">2012 Archive</a>

<ul>
{% for yearvar in year_list %}
    <li><a href="{% url 'news-year-archive' yearvar %}">{{ yearvar }} Archive</a></li>
{% endfor %}
</ul>
```

## URL Namespaces

Namespaces allow unique reverse resolution when multiple apps use the same URL names.

### Application vs Instance Namespaces

- **Application namespace**: Identifies the app (e.g., `polls`)
- **Instance namespace**: Identifies a specific deployment (e.g., `author-polls`)

### Setting Up Namespaces

Using `app_name` in the included URLconf:

```python
# polls/urls.py
from django.urls import path
from . import views

app_name = "polls"
urlpatterns = [
    path("", views.IndexView.as_view(), name="index"),
    path("<int:pk>/", views.DetailView.as_view(), name="detail"),
]
```

Multiple instances of the same app:

```python
# urls.py
from django.urls import include, path

urlpatterns = [
    path("author-polls/", include("polls.urls", namespace="author-polls")),
    path("publisher-polls/", include("polls.urls", namespace="publisher-polls")),
]
```

### Reversing Namespaced URLs

```python
# Explicit namespace
reverse("author-polls:index")
reverse("publisher-polls:index")

# Application namespace (resolves to current or default instance)
reverse("polls:index", current_app=self.request.resolver_match.namespace)
```

In templates:

```html
{% url 'polls:index' %}
```

### Using Tuples with include()

Alternative to `app_name`:

```python
polls_patterns = (
    [
        path("", views.IndexView.as_view(), name="index"),
        path("<int:pk>/", views.DetailView.as_view(), name="detail"),
    ],
    "polls",
)

urlpatterns = [
    path("polls/", include(polls_patterns)),
]
```

## Error Handlers

Set custom error handlers in the root URLconf:

```python
handler400 = "myapp.views.bad_request"
handler403 = "myapp.views.permission_denied"
handler404 = "myapp.views.page_not_found"
handler500 = "myapp.views.server_error"
```

## Important Notes

- URL patterns do not match GET/POST parameters or domain names
- Request method does not affect routing -- all methods route to the same view
- No leading slash needed in patterns (every URL already has one)
- Regular expressions are compiled on first access and cached
- Extra option kwargs override captured URL parameters with the same name

## Best Practices

- Use `path()` by default; use `re_path()` only when path converters are insufficient
- Name all URL patterns for reverse resolution
- Use namespaces when building reusable apps
- Group related URLs with `include()` to keep URLconfs organized
- Use `reverse_lazy()` instead of `reverse()` when URLs are needed at import time
- Use named groups in `re_path()` patterns for clarity
- Keep URL patterns simple and RESTful

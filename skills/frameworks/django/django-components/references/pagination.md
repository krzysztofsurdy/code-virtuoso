# Django Pagination

## Overview

Django provides the `Paginator` and `Page` classes for splitting large datasets across multiple pages with navigation links. The pagination system works with QuerySets, lists, tuples, or any object implementing `count()` or `__len__()`. Django 6.0 introduces `AsyncPaginator` and `AsyncPage` for asynchronous views.

## Core Concepts

### Paginator Class

```python
from django.core.paginator import Paginator

objects = ["john", "paul", "george", "ringo"]
p = Paginator(objects, 2)  # 2 items per page

p.count       # 4 (total objects)
p.num_pages   # 2 (total pages)
p.page_range  # range(1, 3) -> [1, 2]
```

### Constructor Parameters

```python
Paginator(object_list, per_page, orphans=0, allow_empty_first_page=True, error_messages=None)
```

| Parameter | Description |
|---|---|
| `object_list` | List, tuple, QuerySet, or sliceable object with `count()`/`__len__()` |
| `per_page` | Maximum items per page (excluding orphans) |
| `orphans` | If last page has <= this many items, merge with previous page (default: 0) |
| `allow_empty_first_page` | If False, raises EmptyPage when object_list is empty (default: True) |
| `error_messages` | Dict to override error messages (`invalid_page`, `min_page`, `no_results`) |

Orphans example: 23 items with `per_page=10` and `orphans=3` creates 2 pages (10 + 13 items).

### Paginator Methods

| Method | Description |
|---|---|
| `get_page(number)` | Returns Page, handles invalid/out-of-range numbers gracefully |
| `page(number)` | Returns Page, raises exceptions on invalid input |
| `get_elided_page_range(number, on_each_side=3, on_ends=2)` | Returns page range with ellipsis |

`get_page()` vs `page()`:
- `get_page()`: non-numeric input returns first page, out-of-range returns last page
- `page()`: raises `PageNotAnInteger` or `EmptyPage` on invalid input

### Elided Page Range

For large page counts, generates a range with ellipsis:

```python
paginator = Paginator(range(500), 10)  # 50 pages
list(paginator.get_elided_page_range(10))
# [1, 2, '...', 7, 8, 9, 10, 11, 12, 13, '...', 49, 50]
```

### Paginator Attributes

| Attribute | Description |
|---|---|
| `ELLIPSIS` | Translatable string used for elided pages (default: `'...'`) |
| `count` | Total number of objects across all pages |
| `num_pages` | Total number of pages |
| `page_range` | 1-based range iterator of page numbers |

## Page Class

```python
page = paginator.page(1)
```

### Page Methods

| Method | Description |
|---|---|
| `has_next()` | True if next page exists |
| `has_previous()` | True if previous page exists |
| `has_other_pages()` | True if next or previous page exists |
| `next_page_number()` | Next page number (raises InvalidPage if none) |
| `previous_page_number()` | Previous page number (raises InvalidPage if none) |
| `start_index()` | 1-based index of first item on page |
| `end_index()` | 1-based index of last item on page |

### Page Attributes

| Attribute | Description |
|---|---|
| `object_list` | List of objects on this page |
| `number` | 1-based page number |
| `paginator` | Associated Paginator object |

### Example

```python
page1 = p.page(1)
page1.object_list        # ['john', 'paul']
page1.has_next()         # True
page1.next_page_number() # 2

page2 = p.page(2)
page2.object_list          # ['george', 'ringo']
page2.has_previous()       # True
page2.previous_page_number() # 1
page2.start_index()        # 3
page2.end_index()          # 4
```

## Using Pagination in Views

### Function-Based View

```python
from django.core.paginator import Paginator
from django.shortcuts import render
from myapp.models import Contact

def listing(request):
    contact_list = Contact.objects.all()
    paginator = Paginator(contact_list, 25)

    page_number = request.GET.get("page")
    page_obj = paginator.get_page(page_number)
    return render(request, "list.html", {"page_obj": page_obj})
```

### Class-Based View (ListView)

```python
from django.views.generic import ListView
from myapp.models import Contact

class ContactListView(ListView):
    paginate_by = 25
    model = Contact
```

This automatically adds `paginator` and `page_obj` to the template context.

### Template with Pagination Navigation

```django
{% for contact in page_obj %}
    {{ contact.full_name|upper }}<br>
{% endfor %}

<div class="pagination">
    <span class="step-links">
        {% if page_obj.has_previous %}
            <a href="?page=1">&laquo; first</a>
            <a href="?page={{ page_obj.previous_page_number }}">previous</a>
        {% endif %}

        <span class="current">
            Page {{ page_obj.number }} of {{ page_obj.paginator.num_pages }}.
        </span>

        {% if page_obj.has_next %}
            <a href="?page={{ page_obj.next_page_number }}">next</a>
            <a href="?page={{ page_obj.paginator.num_pages }}">last &raquo;</a>
        {% endif %}
    </span>
</div>
```

## AsyncPaginator (Django 6.0)

```python
from django.core.paginator import AsyncPaginator

async def listing(request):
    contact_list = Contact.objects.all()
    paginator = AsyncPaginator(contact_list, 25)

    page_number = request.GET.get("page")
    page_obj = await paginator.aget_page(page_number)
    num_pages = await paginator.anum_pages()
    total = await paginator.acount()
    page_range = await paginator.apage_range()

    return render(request, "list.html", {"page_obj": page_obj})
```

### AsyncPage

```python
async_page = await paginator.aget_page(1)
has_next = await async_page.ahas_next()
has_prev = await async_page.ahas_previous()
objects = await async_page.aget_object_list()
```

## Exceptions

All pagination exceptions inherit from `InvalidPage`:

| Exception | Raised When |
|---|---|
| `InvalidPage` | Base exception for invalid page numbers |
| `PageNotAnInteger` | `page()` receives a non-integer value |
| `EmptyPage` | `page()` given a valid number but page is empty |

```python
from django.core.paginator import InvalidPage

try:
    page = paginator.page(page_num)
except InvalidPage:
    # Handles both PageNotAnInteger and EmptyPage
    page = paginator.page(1)
```

Custom error messages:

```python
paginator = Paginator(
    queryset, 10,
    error_messages={"no_results": "Page does not exist"},
)
```

## Common Patterns

### Pagination with Filtered QuerySets

```python
def search(request):
    query = request.GET.get("q", "")
    results = Article.objects.filter(title__icontains=query)
    paginator = Paginator(results, 20)
    page_obj = paginator.get_page(request.GET.get("page"))
    return render(request, "search.html", {
        "page_obj": page_obj,
        "query": query,
    })
```

Preserve query parameters in pagination links:

```django
<a href="?q={{ query }}&page={{ page_obj.next_page_number }}">next</a>
```

### Elided Page Range in Templates

```django
{% for page_num in page_obj.paginator.get_elided_page_range(page_obj.number) %}
    {% if page_num == page_obj.paginator.ELLIPSIS %}
        <span>{{ page_num }}</span>
    {% elif page_num == page_obj.number %}
        <strong>{{ page_num }}</strong>
    {% else %}
        <a href="?page={{ page_num }}">{{ page_num }}</a>
    {% endif %}
{% endfor %}
```

## Best Practices

- Use `get_page()` instead of `page()` for user-facing views to handle invalid input gracefully
- Always order QuerySets before paginating to ensure consistent results across pages
- Use `orphans` parameter to avoid nearly-empty last pages
- Prefer `ListView` with `paginate_by` for simple list views
- Use `get_elided_page_range()` for large datasets to avoid rendering hundreds of page links
- Pass the `page_obj` to templates rather than individual pagination attributes
- Use `AsyncPaginator` in async views for non-blocking database access

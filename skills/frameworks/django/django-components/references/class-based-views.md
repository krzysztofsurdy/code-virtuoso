# Django Class-Based Views

## Overview

Class-based views (CBVs) allow you to structure views as Python classes, enabling code reuse through inheritance and mixins. All CBVs inherit from the `View` base class, which handles URL linking, HTTP method dispatching, and other common features. Django provides a rich set of generic views for common patterns like displaying object lists, detail pages, and form handling.

## Base Views

### View

The foundational class for all CBVs. Dispatches requests to the appropriate method handler (`get()`, `post()`, etc.):

```python
from django.http import HttpResponse
from django.views import View

class MyView(View):
    def get(self, request, *args, **kwargs):
        return HttpResponse("Hello, World!")

    def post(self, request, *args, **kwargs):
        return HttpResponse("Posted!")
```

URL configuration always uses `as_view()`:

```python
from django.urls import path
from myapp.views import MyView

urlpatterns = [
    path("mine/", MyView.as_view()),
]
```

### TemplateView

Renders a template with context data:

```python
from django.views.generic import TemplateView

class AboutView(TemplateView):
    template_name = "about.html"

# Or directly in URLconf
urlpatterns = [
    path("about/", TemplateView.as_view(template_name="about.html")),
]
```

### RedirectView

Provides an HTTP redirect to another URL:

```python
from django.views.generic.base import RedirectView

urlpatterns = [
    path("old-page/", RedirectView.as_view(url="/new-page/", permanent=True)),
]
```

## Generic Display Views

### ListView

Displays a list of objects with automatic template resolution and pagination:

```python
from django.views.generic import ListView
from books.models import Publisher

class PublisherListView(ListView):
    model = Publisher
```

Template automatically resolves to `books/publisher_list.html`. Default context variable is `object_list` (plus a lowercased model name version like `publisher_list`).

Customize the context variable name:

```python
class PublisherListView(ListView):
    model = Publisher
    context_object_name = "publishers"
```

#### Filtering and Ordering

```python
class BookListView(ListView):
    queryset = Book.objects.order_by("-publication_date")
    context_object_name = "book_list"

class AcmeBookListView(ListView):
    context_object_name = "book_list"
    queryset = Book.objects.filter(publisher__name="ACME Publishing")
    template_name = "books/acme_list.html"
```

#### Dynamic Filtering from URL Parameters

```python
# urls.py
path("books/<publisher>/", PublisherBookListView.as_view()),

# views.py
class PublisherBookListView(ListView):
    template_name = "books/books_by_publisher.html"

    def get_queryset(self):
        self.publisher = get_object_or_404(Publisher, name=self.kwargs["publisher"])
        return Book.objects.filter(publisher=self.publisher)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["publisher"] = self.publisher
        return context
```

### DetailView

Displays a single object. Looks up by `pk` or `slug` from the URL:

```python
from django.views.generic import DetailView
from books.models import Book

class BookDetailView(DetailView):
    model = Book

# urls.py
path("books/<int:pk>/", BookDetailView.as_view(), name="book-detail"),
```

Template resolves to `books/book_detail.html`. Context variable is `object` (plus lowercased model name).

#### Adding Extra Context

```python
class PublisherDetailView(DetailView):
    model = Publisher

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["book_list"] = Book.objects.all()
        return context
```

#### Performing Extra Work

```python
class AuthorDetailView(DetailView):
    queryset = Author.objects.all()

    def get_object(self):
        obj = super().get_object()
        obj.last_accessed = timezone.now()
        obj.save()
        return obj
```

## Generic Editing Views

### FormView

Displays and processes a form:

```python
from django.views.generic.edit import FormView
from myapp.forms import ContactForm

class ContactFormView(FormView):
    template_name = "contact.html"
    form_class = ContactForm
    success_url = "/thanks/"

    def form_valid(self, form):
        form.send_email()
        return super().form_valid(form)
```

### CreateView

Creates a new object using a model form:

```python
from django.views.generic.edit import CreateView
from myapp.models import Author

class AuthorCreateView(CreateView):
    model = Author
    fields = ["name"]
```

Template resolves to `myapp/author_form.html`. Redirects to `get_absolute_url()` on success.

### UpdateView

Updates an existing object:

```python
from django.views.generic.edit import UpdateView
from myapp.models import Author

class AuthorUpdateView(UpdateView):
    model = Author
    fields = ["name"]
```

Uses the same template as `CreateView` (`myapp/author_form.html`).

### DeleteView

Deletes an object after confirmation:

```python
from django.urls import reverse_lazy
from django.views.generic.edit import DeleteView
from myapp.models import Author

class AuthorDeleteView(DeleteView):
    model = Author
    success_url = reverse_lazy("author-list")
```

Template resolves to `myapp/author_confirm_delete.html`. Use `reverse_lazy()` instead of `reverse()` because URLs are not loaded at import time.

### Tracking the Creating User

```python
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic.edit import CreateView
from myapp.models import Author

class AuthorCreateView(LoginRequiredMixin, CreateView):
    model = Author
    fields = ["name"]

    def form_valid(self, form):
        form.instance.created_by = self.request.user
        return super().form_valid(form)
```

### AJAX / Content Negotiation

```python
from django.http import JsonResponse
from django.views.generic.edit import CreateView

class JsonableResponseMixin:
    def form_invalid(self, form):
        response = super().form_invalid(form)
        if self.request.accepts("text/html"):
            return response
        else:
            return JsonResponse(form.errors, status=400)

    def form_valid(self, form):
        response = super().form_valid(form)
        if self.request.accepts("text/html"):
            return response
        else:
            return JsonResponse({"pk": self.object.pk})

class AuthorCreateView(JsonableResponseMixin, CreateView):
    model = Author
    fields = ["name"]
```

## URL Configuration for Editing Views

```python
from django.urls import path
from myapp.views import AuthorCreateView, AuthorUpdateView, AuthorDeleteView

urlpatterns = [
    path("author/add/", AuthorCreateView.as_view(), name="author-add"),
    path("author/<int:pk>/", AuthorUpdateView.as_view(), name="author-update"),
    path("author/<int:pk>/delete/", AuthorDeleteView.as_view(), name="author-delete"),
]
```

## Mixins

### Core Mixins

| Mixin | Purpose |
|-------|---------|
| `ContextMixin` | Provides `get_context_data()` and `extra_context` |
| `TemplateResponseMixin` | Provides `render_to_response()` and `get_template_names()` |

### Single Object Mixins

| Mixin | Purpose |
|-------|---------|
| `SingleObjectMixin` | Provides `get_object()` to fetch by `pk` or `slug` |
| `SingleObjectTemplateResponseMixin` | Auto-generates template name from model |

### Multiple Object Mixins

| Mixin | Purpose |
|-------|---------|
| `MultipleObjectMixin` | Provides `get_queryset()` and `paginate_queryset()` |
| `MultipleObjectTemplateResponseMixin` | Auto-generates list template name |

### Editing Mixins

| Mixin | Purpose |
|-------|---------|
| `FormMixin` | Handles form instantiation and validation |
| `ModelFormMixin` | Works with model-bound forms |
| `ProcessFormView` | Processes GET (display) and POST (validate) |
| `DeletionMixin` | Handles object deletion |

### Using SingleObjectMixin with View

```python
from django.http import HttpResponseForbidden, HttpResponseRedirect
from django.urls import reverse
from django.views import View
from django.views.generic.detail import SingleObjectMixin

class RecordInterestView(SingleObjectMixin, View):
    model = Author

    def post(self, request, *args, **kwargs):
        if not request.user.is_authenticated:
            return HttpResponseForbidden()
        self.object = self.get_object()
        return HttpResponseRedirect(
            reverse("author-detail", kwargs={"pk": self.object.pk})
        )
```

### Paginating Related Objects with SingleObjectMixin + ListView

```python
class PublisherDetailView(SingleObjectMixin, ListView):
    paginate_by = 2
    template_name = "books/publisher_detail.html"

    def get(self, request, *args, **kwargs):
        self.object = self.get_object(queryset=Publisher.objects.all())
        return super().get(request, *args, **kwargs)

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["publisher"] = self.object
        return context

    def get_queryset(self):
        return self.object.book_set.all()
```

### Custom JSON Response Mixin

```python
from django.http import JsonResponse

class JSONResponseMixin:
    def render_to_json_response(self, context, **response_kwargs):
        return JsonResponse(self.get_data(context), **response_kwargs)

    def get_data(self, context):
        return context
```

## Async Class-Based Views

All method handlers within a single view class must be either all sync or all async:

```python
import asyncio
from django.http import HttpResponse
from django.views import View

class AsyncView(View):
    async def get(self, request, *args, **kwargs):
        await asyncio.sleep(1)
        return HttpResponse("Hello async world!")
```

Mixing sync and async handlers raises `ImproperlyConfigured`.

## Method Flowchart

### Request Processing Order

1. `dispatch()` -- routes to `get()`, `post()`, etc.
2. `http_method_not_allowed()` -- called if method not supported

### Display Views (GET)

1. `dispatch()` -> `get()`
2. `get_queryset()` / `get_object()`
3. `get_context_data()`
4. `render_to_response()`

### Editing Views (POST)

1. `dispatch()` -> `post()`
2. `get_form()`
3. `form_valid()` or `form_invalid()`
4. On valid: save and redirect
5. On invalid: re-render with errors

## Complete CBV Reference

| Category | Views |
|----------|-------|
| Base | `View`, `TemplateView`, `RedirectView` |
| Display | `DetailView`, `ListView` |
| Editing | `FormView`, `CreateView`, `UpdateView`, `DeleteView` |
| Date-based | `ArchiveIndexView`, `YearArchiveView`, `MonthArchiveView`, `WeekArchiveView`, `DayArchiveView`, `TodayArchiveView`, `DateDetailView` |

## Best Practices

- Use `as_view()` for all URL configuration -- never instantiate views directly
- Prefer subclassing over passing many arguments to `as_view()`
- Only use mixins from the same group (detail, list, editing, date) in a single view
- Use `LoginRequiredMixin` as the leftmost parent for protected views
- Override `get_queryset()` for dynamic filtering rather than setting `queryset` as a class attribute
- Use `reverse_lazy()` for `success_url` in editing views
- Each request gets an independent view instance -- `self` attributes are thread-safe

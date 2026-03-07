---
name: django-components
description: Comprehensive skill for all Django framework components. Covers models, views, templates, forms, admin, authentication, caching, testing, middleware, signals, deployment, async, and utility components. Use when working with any Django component.
user-invocable: false
---

# Django Components

Complete reference for all 33 Django components -- patterns, APIs, configuration, and best practices for Python 3.10+ and Django 6.0.

## Component Index

### Models & Database
- **Models** -- Model definition, field types, Meta options, inheritance, managers -> [reference](references/models.md)
- **QuerySets** -- QuerySet API, field lookups, Q objects, F expressions, aggregation -> [reference](references/querysets.md)
- **Migrations** -- Migration workflow, operations, data migrations, squashing -> [reference](references/migrations.md)
- **Database Functions** -- Database functions, conditional expressions, full-text search -> [reference](references/database-functions.md)

### Views & HTTP
- **Views** -- Function-based views, shortcuts (render, redirect, get_object_or_404) -> [reference](references/views.md)
- **Class-Based Views** -- ListView, DetailView, CreateView, UpdateView, DeleteView, mixins -> [reference](references/class-based-views.md)
- **URL Routing** -- URL configuration, path(), re_path(), namespaces, reverse() -> [reference](references/urls.md)
- **Middleware** -- Middleware architecture, built-in middleware, custom middleware -> [reference](references/middleware.md)
- **Request & Response** -- HttpRequest, HttpResponse, JsonResponse, StreamingHttpResponse -> [reference](references/request-response.md)

### Templates
- **Templates** -- Template language, tags, filters, inheritance, custom template tags -> [reference](references/templates.md)

### Forms
- **Forms** -- Form class, fields, widgets, ModelForm, formsets, validation -> [reference](references/forms.md)

### Admin
- **Admin** -- ModelAdmin, list_display, fieldsets, inlines, actions, customization -> [reference](references/admin.md)

### Authentication & Security
- **Authentication** -- User model, login/logout, permissions, groups, custom user models -> [reference](references/auth.md)
- **Security** -- CSRF, XSS, clickjacking, SSL, CSP, cryptographic signing -> [reference](references/security.md)
- **Sessions** -- Session framework, backends, configuration -> [reference](references/sessions.md)

### Caching
- **Cache** -- Cache backends (Redis, Memcached, DB, filesystem), per-view/template caching -> [reference](references/cache.md)

### Signals
- **Signals** -- Signal dispatcher, built-in signals (pre_save, post_save, etc.) -> [reference](references/signals.md)

### Communication
- **Email** -- send_mail, EmailMessage, HTML emails, backends -> [reference](references/email.md)
- **Messages** -- Messages framework, levels, storage backends -> [reference](references/messages.md)

### Testing
- **Testing** -- TestCase, Client, assertions, RequestFactory, fixtures -> [reference](references/testing.md)

### Files & Static Assets
- **Files** -- File objects, storage API, file uploads, custom storage -> [reference](references/files.md)
- **Static Files** -- Static file configuration, collectstatic, ManifestStaticFilesStorage -> [reference](references/static-files.md)

### Internationalization
- **I18n** -- Translation, localization, timezones, message files -> [reference](references/i18n.md)

### Serialization & Data
- **Serialization** -- Serializers, JSON/XML formats, natural keys, fixtures -> [reference](references/serialization.md)
- **Content Types** -- ContentType model, generic relations -> [reference](references/content-types.md)
- **Validators** -- Built-in validators, custom validators -> [reference](references/validators.md)
- **Pagination** -- Paginator, Page objects, template integration -> [reference](references/pagination.md)

### Async & Tasks
- **Async** -- Async views, async ORM, sync_to_async, ASGI -> [reference](references/async.md)
- **Tasks** -- Tasks framework, task backends, scheduling -> [reference](references/tasks.md)

### Configuration & CLI
- **Settings** -- Settings reference by category, splitting settings -> [reference](references/settings.md)
- **Management Commands** -- Built-in commands, custom commands, call_command -> [reference](references/management-commands.md)
- **Logging** -- Logging configuration, handlers, Django loggers -> [reference](references/logging.md)

### Deployment
- **Deployment** -- WSGI, ASGI, Gunicorn, Uvicorn, static files, checklist -> [reference](references/deployment.md)

## Quick Patterns

### Define a Model

```python
from django.db import models

class Article(models.Model):
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    content = models.TextField()
    published = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    author = models.ForeignKey('auth.User', on_delete=models.CASCADE)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title
```

### Define a URL + View

```python
# urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('articles/<int:pk>/', views.article_detail, name='article_detail'),
]

# views.py
from django.shortcuts import render, get_object_or_404

def article_detail(request, pk):
    article = get_object_or_404(Article, pk=pk)
    return render(request, 'articles/detail.html', {'article': article})
```

### Class-Based View

```python
from django.views.generic import ListView, DetailView

class ArticleListView(ListView):
    model = Article
    queryset = Article.objects.filter(published=True)
    paginate_by = 20

class ArticleDetailView(DetailView):
    model = Article
    slug_field = 'slug'
```

### QuerySet Filtering

```python
from django.db.models import Q, F, Count

# Complex filtering
articles = Article.objects.filter(
    Q(title__icontains='django') | Q(content__icontains='django'),
    published=True,
).exclude(
    author__is_active=False
).annotate(
    comment_count=Count('comments')
).order_by('-created_at')
```

### Form with Validation

```python
from django import forms

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = ['title', 'slug', 'content', 'published']

    def clean_title(self):
        title = self.cleaned_data['title']
        if len(title) < 5:
            raise forms.ValidationError('Title must be at least 5 characters.')
        return title
```

### Cache a View

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # 15 minutes
def article_list(request):
    articles = Article.objects.filter(published=True)
    return render(request, 'articles/list.html', {'articles': articles})
```

### Signal Receiver

```python
from django.db.models.signals import post_save
from django.dispatch import receiver

@receiver(post_save, sender=Article)
def notify_on_publish(sender, instance, created, **kwargs):
    if instance.published and created:
        send_notification(instance)
```

### Management Command

```python
from django.core.management.base import BaseCommand

class Command(BaseCommand):
    help = 'Process pending articles'

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=100)

    def handle(self, *args, **options):
        count = process_articles(limit=options['limit'])
        self.stdout.write(self.style.SUCCESS(f'Processed {count} articles'))
```

### Test Case

```python
from django.test import TestCase

class ArticleTests(TestCase):
    def setUp(self):
        self.article = Article.objects.create(
            title='Test Article',
            slug='test-article',
            content='Content here',
            published=True,
        )

    def test_article_detail_view(self):
        response = self.client.get(f'/articles/{self.article.pk}/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'Test Article')
```

## Best Practices

- Target **Python 3.10+** and **Django 6.0** with type hints where helpful
- Use **class-based views** for CRUD; function-based views for custom logic
- Prefer **select_related/prefetch_related** to avoid N+1 queries
- Use **F expressions** for database-level operations instead of Python
- Apply **migrations** atomically -- one logical change per migration
- Use **Django's cache framework** with Redis or Memcached in production
- Write **TestCase** tests with assertions specific to Django (assertContains, assertRedirects)
- Use **custom user models** from the start (AUTH_USER_MODEL)
- Enable **CSRF protection** everywhere -- never use @csrf_exempt without good reason
- Use **environment variables** for secrets -- never commit SECRET_KEY or database credentials
- Deploy with **Gunicorn/Uvicorn** behind a reverse proxy (nginx)
- Run **manage.py check --deploy** before every production deployment

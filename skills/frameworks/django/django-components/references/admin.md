# Django Admin

## Overview

Django's admin interface automatically generates a model-centric management UI by reading model metadata. It is designed for trusted internal users and provides CRUD operations, filtering, searching, bulk actions, and inline editing out of the box. The admin is highly customizable through `ModelAdmin` classes, decorators, and site configuration.

## Core Concepts

### Setup Requirements

```python
# settings.py
INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.messages",
    "django.contrib.sessions",
]

# urls.py
from django.contrib import admin

urlpatterns = [
    path("admin/", admin.site.urls),
]
```

Create a superuser: `python manage.py createsuperuser`.

### Basic Registration

```python
from django.contrib import admin
from myapp.models import Author

# Simple registration
admin.site.register(Author)

# With ModelAdmin
class AuthorAdmin(admin.ModelAdmin):
    list_display = ["name", "email"]

admin.site.register(Author, AuthorAdmin)

# Using decorator (preferred)
@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    list_display = ["name", "email"]
```

## ModelAdmin Options

### List Display and Navigation

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    # Columns shown on the change list
    list_display = ["title", "author", "status", "pub_date", "word_count"]

    # Which columns link to change page (default: first column)
    list_display_links = ["title"]

    # Enable inline editing on the list page
    list_editable = ["status"]

    # Sidebar filters
    list_filter = ["status", "pub_date", "author"]

    # Search box
    search_fields = ["title", "content", "author__name"]
    search_help_text = "Search by title, content, or author name"

    # Date-based navigation bar
    date_hierarchy = "pub_date"

    # Default sort order
    ordering = ["-pub_date"]

    # Items per page (default: 100)
    list_per_page = 50

    # Threshold for "Show all" link (default: 200)
    list_max_show_all = 500

    # Optimize queries for related objects
    list_select_related = ["author", "category"]

    # Display full count vs approximate (default: True)
    show_full_result_count = False
```

Search field prefixes: `^` (istartswith), `=` (iexact), `@` (search/PostgreSQL), no prefix (icontains).

### Form Layout

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    # Simple field list (tuple groups fields on same line)
    fields = [("title", "slug"), "content", "author", "pub_date"]

    # Or grouped fieldsets with sections
    fieldsets = [
        (None, {
            "fields": ["title", "slug", "content"],
        }),
        ("Publishing", {
            "fields": ["author", "pub_date", "status"],
        }),
        ("Advanced", {
            "classes": ["collapse"],  # Collapsible section
            "description": "Optional advanced settings.",
            "fields": ["template_name", "enable_comments"],
        }),
    ]

    # Fields to exclude from the form
    exclude = ["created_at"]

    # Read-only fields
    readonly_fields = ["created_at", "updated_at", "word_count"]

    # Custom ModelForm
    form = ArticleAdminForm
```

### Relation Field Widgets

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    # JavaScript filter interface for M2M fields
    filter_horizontal = ["tags"]
    # Or vertical layout
    filter_vertical = ["categories"]

    # Raw ID input with lookup popup
    raw_id_fields = ["author"]

    # Select2 autocomplete (requires search_fields on related admin)
    autocomplete_fields = ["category"]

    # Radio buttons instead of select
    radio_fields = {"status": admin.HORIZONTAL}

    # Auto-populate slug from title
    prepopulated_fields = {"slug": ["title"]}
```

### Other Options

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    # Enable "Save as new" button
    save_as = True

    # Save buttons at top and bottom
    save_on_top = True

    # Control "View on site" link
    view_on_site = True  # or False, or a callable

    # Keep filters after edit (default: True)
    preserve_filters = True

    # Action bar position
    actions_on_top = True
    actions_on_bottom = False

    # Empty field display (default: "-")
    empty_value_display = "(none)"

    # Override field widgets by type
    formfield_overrides = {
        models.TextField: {"widget": RichTextEditorWidget},
    }

    # Facet counts in filters
    show_facets = admin.ShowFacets.ALWAYS
```

## Admin Decorators

### @admin.register

```python
@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    pass

# Multiple models
@admin.register(Author, Editor)
class PersonAdmin(admin.ModelAdmin):
    pass

# Custom admin site
@admin.register(Author, site=custom_admin_site)
class AuthorAdmin(admin.ModelAdmin):
    pass
```

### @admin.display

Controls how callable columns appear in `list_display` and `readonly_fields`:

```python
@admin.register(Person)
class PersonAdmin(admin.ModelAdmin):
    list_display = ["name", "colored_status", "is_adult"]

    @admin.display(description="Status", ordering="status")
    def colored_status(self, obj):
        colors = {"active": "green", "inactive": "red"}
        return format_html(
            '<span style="color: {};">{}</span>',
            colors.get(obj.status, "black"),
            obj.status,
        )

    @admin.display(boolean=True, description="Adult?")
    def is_adult(self, obj):
        return obj.age >= 18

    @admin.display(empty_value="N/A")
    def optional_field(self, obj):
        return obj.optional
```

| Parameter | Purpose |
|-----------|---------|
| `description` | Column header text |
| `ordering` | Field to sort by (supports `__` lookups, `-` for descending) |
| `boolean` | Display as yes/no icons |
| `empty_value` | Text for empty values |

### @admin.action

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    actions = ["make_published", "export_as_json"]

    @admin.action(description="Mark selected as published")
    def make_published(self, request, queryset):
        updated = queryset.update(status="published")
        self.message_user(request, f"{updated} articles published.")

    @admin.action(
        description="Export as JSON",
        permissions=["change"],
    )
    def export_as_json(self, request, queryset):
        from django.http import HttpResponse
        from django.core import serializers
        response = HttpResponse(content_type="application/json")
        serializers.serialize("json", queryset, stream=response)
        return response
```

## Admin Actions

### Writing Actions

```python
# As a standalone function
@admin.action(description="Mark as published")
def make_published(modeladmin, request, queryset):
    queryset.update(status="p")

class ArticleAdmin(admin.ModelAdmin):
    actions = [make_published]

# As a ModelAdmin method
class ArticleAdmin(admin.ModelAdmin):
    actions = ["make_published"]

    @admin.action(description="Mark as published")
    def make_published(self, request, queryset):
        queryset.update(status="p")
```

### User Feedback

```python
from django.contrib import messages
from django.utils.translation import ngettext

@admin.action(description="Publish selected")
def make_published(self, request, queryset):
    updated = queryset.update(status="p")
    self.message_user(
        request,
        ngettext(
            "%d article published.",
            "%d articles published.",
            updated,
        ) % updated,
        messages.SUCCESS,
    )
```

### Action Permissions

```python
@admin.action(permissions=["change"])
def make_published(self, request, queryset):
    queryset.update(status="p")

# Custom permission
@admin.action(permissions=["publish"])
def make_published(self, request, queryset):
    queryset.update(status="p")

def has_publish_permission(self, request):
    return request.user.has_perm("myapp.publish_article")
```

### Intermediate Pages

Return an `HttpResponse` to show a confirmation page:

```python
@admin.action(description="Export selected")
def export_selected(self, request, queryset):
    selected = queryset.values_list("pk", flat=True)
    return HttpResponseRedirect(
        f"/export/?ids={','.join(str(pk) for pk in selected)}"
    )
```

### Site-Wide Actions

```python
# Add globally
admin.site.add_action(export_selected, "export_selected")

# Disable globally
admin.site.disable_action("delete_selected")

# Re-enable for specific admin
class MyAdmin(admin.ModelAdmin):
    actions = ["delete_selected", "my_action"]
```

### Conditionally Disabling Actions

```python
class ArticleAdmin(admin.ModelAdmin):
    def get_actions(self, request):
        actions = super().get_actions(request)
        if not request.user.is_superuser:
            del actions["delete_selected"]
        return actions
```

## InlineModelAdmin

### TabularInline

Renders related objects in a compact table:

```python
class BookInline(admin.TabularInline):
    model = Book
    extra = 1           # Empty forms to display (default: 3)
    max_num = 10        # Maximum forms
    min_num = 0         # Minimum forms
    fields = ["title", "isbn", "published_date"]
    readonly_fields = ["created_at"]
    autocomplete_fields = ["publisher"]
    raw_id_fields = ["editor"]
    show_change_link = True  # Link to full change form
```

### StackedInline

Renders related objects in a stacked vertical layout:

```python
class ReviewInline(admin.StackedInline):
    model = Review
    extra = 0
    fields = ["reviewer", "rating", "comment"]
    classes = ["collapse"]  # Make collapsible
```

### Using Inlines

```python
@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    inlines = [BookInline, ReviewInline]
```

### Common Inline Options

| Option | Default | Description |
|--------|---------|-------------|
| `model` | required | Related model |
| `extra` | `3` | Number of empty forms |
| `max_num` | `None` | Maximum total forms |
| `min_num` | `None` | Minimum total forms |
| `fields` | all | Fields to display |
| `exclude` | none | Fields to exclude |
| `readonly_fields` | `[]` | Non-editable fields |
| `form` | `ModelForm` | Custom form class |
| `formset` | `BaseInlineFormSet` | Custom formset class |
| `show_change_link` | `False` | Link to full edit page |

## Key ModelAdmin Methods

### Data Access and Filtering

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if not request.user.is_superuser:
            return qs.filter(author=request.user)
        return qs

    def get_search_results(self, request, queryset, search_term):
        queryset, may_have_duplicates = super().get_search_results(
            request, queryset, search_term,
        )
        try:
            queryset |= self.model.objects.filter(pk=int(search_term))
        except ValueError:
            pass
        return queryset, may_have_duplicates
```

### Save and Delete Hooks

```python
    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)

    def delete_model(self, request, obj):
        # Pre-delete operations
        super().delete_model(request, obj)

    def save_formset(self, request, form, formset, change):
        instances = formset.save(commit=False)
        for obj in formset.deleted_objects:
            obj.delete()
        for instance in instances:
            instance.user = request.user
            instance.save()
        formset.save_m2m()
```

### Dynamic Configuration

```python
    def get_readonly_fields(self, request, obj=None):
        if obj and not request.user.is_superuser:
            return ["author", "created_at"]
        return []

    def get_fieldsets(self, request, obj=None):
        if obj is None:  # Adding new object
            return [(None, {"fields": ["title", "content"]})]
        return [
            (None, {"fields": ["title", "content"]}),
            ("Metadata", {"fields": ["created_at", "updated_at"]}),
        ]

    def get_list_display(self, request):
        if request.user.is_superuser:
            return ["title", "author", "status", "created_at"]
        return ["title", "status"]

    def get_form(self, request, obj=None, **kwargs):
        if request.user.is_superuser:
            kwargs["form"] = SuperuserArticleForm
        return super().get_form(request, obj, **kwargs)
```

### Permission Methods

```python
    def has_add_permission(self, request):
        return request.user.is_superuser

    def has_change_permission(self, request, obj=None):
        if obj and obj.author == request.user:
            return True
        return request.user.is_superuser

    def has_delete_permission(self, request, obj=None):
        return request.user.is_superuser

    def has_view_permission(self, request, obj=None):
        return True

    def has_module_permission(self, request):
        return True
```

### Custom Admin URLs

```python
    def get_urls(self):
        from django.urls import path
        urls = super().get_urls()
        custom_urls = [
            path(
                "report/",
                self.admin_site.admin_view(self.report_view),
                name="article-report",
            ),
        ]
        return custom_urls + urls

    def report_view(self, request):
        # Custom view logic
        pass
```

## AdminSite Customization

```python
from django.contrib.admin import AdminSite

class MyAdminSite(AdminSite):
    site_header = "My Project Admin"
    site_title = "My Project"
    index_title = "Dashboard"
    empty_value_display = "(N/A)"

my_admin = MyAdminSite(name="myadmin")
my_admin.register(Author, AuthorAdmin)

# urls.py
urlpatterns = [
    path("myadmin/", my_admin.urls),
]
```

Or customize the default site:

```python
admin.site.site_header = "My Project Admin"
admin.site.site_title = "My Project"
admin.site.index_title = "Dashboard"
```

## Custom Templates

Override admin templates per-model or globally:

```python
@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    change_form_template = "admin/article/change_form.html"
    change_list_template = "admin/article/change_list.html"
    delete_confirmation_template = "admin/article/delete_confirmation.html"
    object_history_template = "admin/article/object_history.html"
```

## Common Patterns

### Complete ModelAdmin Example

```python
from django.contrib import admin
from django.utils.html import format_html
from .models import Author, Book, Review

class BookInline(admin.TabularInline):
    model = Book
    extra = 1
    fields = ["title", "isbn", "published_date"]

@admin.register(Author)
class AuthorAdmin(admin.ModelAdmin):
    inlines = [BookInline]

    list_display = ["name", "email_link", "book_count", "is_active"]
    list_filter = ["is_active", "created_at"]
    list_per_page = 50
    search_fields = ["^name", "email"]
    search_help_text = "Search by name or email"

    fieldsets = [
        (None, {"fields": ["name", "email", "website"]}),
        ("Personal Info", {
            "classes": ["collapse"],
            "fields": ["birth_date", "biography"],
        }),
    ]

    readonly_fields = ["created_at"]
    prepopulated_fields = {"slug": ["name"]}
    date_hierarchy = "created_at"
    ordering = ["-created_at"]
    actions = ["deactivate_authors"]

    @admin.display(description="Email", ordering="email")
    def email_link(self, obj):
        return format_html('<a href="mailto:{}">{}</a>', obj.email, obj.email)

    @admin.display(description="Books")
    def book_count(self, obj):
        return obj.books.count()

    @admin.display(boolean=True)
    def is_active(self, obj):
        return obj.is_active

    @admin.action(description="Deactivate selected authors")
    def deactivate_authors(self, request, queryset):
        queryset.update(is_active=False)

    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related("books")

    def save_model(self, request, obj, form, change):
        if not change:
            obj.created_by = request.user
        super().save_model(request, obj, form, change)
```

## Best Practices

- Use `@admin.register` decorator over `admin.site.register()` for cleaner code
- Always set `list_display` to show relevant columns
- Use `search_fields` with lookup prefixes (`^`, `=`) for performance
- Use `list_select_related` to avoid N+1 queries in list views
- Override `get_queryset()` to filter by user permissions
- Use `readonly_fields` for computed or non-editable data
- Use `fieldsets` with `collapse` class for advanced/optional sections
- Use `autocomplete_fields` instead of default select for large relation sets
- Set `show_full_result_count = False` for tables with millions of rows
- Use `@admin.display(ordering=...)` to make computed columns sortable

# Django Forms

## Overview

Django's form system handles HTML form rendering, data validation, and cleaning. It provides `Form` for standalone forms, `ModelForm` for model-backed forms, and formsets for working with multiple form instances. Forms manage three tasks: preparing data for rendering, creating HTML inputs, and receiving/processing submitted data.

## Core Concepts

### Form Class

```python
from django import forms

class ContactForm(forms.Form):
    subject = forms.CharField(max_length=100)
    message = forms.CharField(widget=forms.Textarea)
    sender = forms.EmailField()
    cc_myself = forms.BooleanField(required=False)
```

### Bound and Unbound Forms

```python
# Unbound - no data, renders empty
form = ContactForm()
form.is_bound  # False

# Bound - has data, can validate
form = ContactForm({"subject": "hello", "message": "Hi"})
form.is_bound  # True

# Empty dict is still bound
form = ContactForm({})
form.is_bound  # True
```

### Processing Forms in Views

```python
from django.shortcuts import render, redirect

def contact(request):
    if request.method == "POST":
        form = ContactForm(request.POST)
        if form.is_valid():
            subject = form.cleaned_data["subject"]
            message = form.cleaned_data["message"]
            # Process data...
            return redirect("/thanks/")
    else:
        form = ContactForm()
    return render(request, "contact.html", {"form": form})
```

### Validation and Cleaned Data

```python
form = ContactForm(data)
if form.is_valid():
    # cleaned_data contains validated, type-converted values
    form.cleaned_data["subject"]      # str
    form.cleaned_data["cc_myself"]    # bool

# Accessing errors
form.errors                    # {"field": ["error msg"]}
form.errors.as_json()          # JSON-serialized errors
form.non_field_errors()        # Errors not tied to a field
form.has_error("subject")      # Check specific field
form.add_error("subject", "Custom error")
form.add_error(None, "Non-field error")
```

## Form Fields

### Core Field Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `required` | `True` | Field must have a value |
| `label` | Field name | Human-readable label |
| `initial` | `None` | Default value for unbound forms |
| `widget` | Field default | HTML rendering widget |
| `help_text` | `""` | Descriptive text |
| `error_messages` | `{}` | Override default error messages |
| `validators` | `[]` | List of validation functions |
| `disabled` | `False` | Render as disabled |

### Built-in Field Types

| Field | Normalizes To | Default Widget |
|-------|--------------|----------------|
| `BooleanField` | `bool` | `CheckboxInput` |
| `CharField` | `str` | `TextInput` |
| `EmailField` | `str` | `EmailInput` |
| `URLField` | `str` | `URLInput` |
| `SlugField` | `str` | `TextInput` |
| `RegexField` | `str` | `TextInput` |
| `UUIDField` | `UUID` | `TextInput` |
| `IntegerField` | `int` | `NumberInput` |
| `FloatField` | `float` | `NumberInput` |
| `DecimalField` | `Decimal` | `NumberInput` |
| `DateField` | `date` | `DateInput` |
| `TimeField` | `time` | `TimeInput` |
| `DateTimeField` | `datetime` | `DateTimeInput` |
| `DurationField` | `timedelta` | `TextInput` |
| `ChoiceField` | `str` | `Select` |
| `TypedChoiceField` | coerced type | `Select` |
| `MultipleChoiceField` | `list[str]` | `SelectMultiple` |
| `FileField` | `UploadedFile` | `ClearableFileInput` |
| `ImageField` | `UploadedFile` | `ClearableFileInput` |
| `FilePathField` | `str` | `Select` |
| `GenericIPAddressField` | `str` | `TextInput` |
| `JSONField` | Python object | `Textarea` |
| `ModelChoiceField` | model instance | `Select` |
| `ModelMultipleChoiceField` | `QuerySet` | `SelectMultiple` |
| `SplitDateTimeField` | `datetime` | `SplitDateTimeWidget` |

### Field Examples

```python
class RegistrationForm(forms.Form):
    username = forms.CharField(max_length=30, min_length=3)
    email = forms.EmailField()
    password = forms.CharField(widget=forms.PasswordInput)
    age = forms.IntegerField(min_value=13, max_value=120)
    birth_date = forms.DateField(input_formats=["%Y-%m-%d", "%m/%d/%Y"])
    role = forms.ChoiceField(choices=[("user", "User"), ("admin", "Admin")])
    avatar = forms.ImageField(required=False)
    bio = forms.CharField(widget=forms.Textarea, required=False)
    tags = forms.MultipleChoiceField(
        choices=[("python", "Python"), ("django", "Django")],
        widget=forms.CheckboxSelectMultiple,
    )
    category = forms.ModelChoiceField(
        queryset=Category.objects.all(),
        empty_label="Select a category",
    )
```

## Widgets

### Built-in Widgets

| Widget | HTML Output |
|--------|-------------|
| `TextInput` | `<input type="text">` |
| `NumberInput` | `<input type="number">` |
| `EmailInput` | `<input type="email">` |
| `URLInput` | `<input type="url">` |
| `PasswordInput` | `<input type="password">` |
| `HiddenInput` | `<input type="hidden">` |
| `Textarea` | `<textarea>` |
| `DateInput` | `<input type="text">` |
| `TimeInput` | `<input type="text">` |
| `CheckboxInput` | `<input type="checkbox">` |
| `Select` | `<select>` |
| `SelectMultiple` | `<select multiple>` |
| `RadioSelect` | Radio buttons |
| `CheckboxSelectMultiple` | Multiple checkboxes |
| `FileInput` | `<input type="file">` |
| `ClearableFileInput` | File input with clear option |
| `SplitDateTimeWidget` | Separate date and time inputs |
| `SelectDateWidget` | Three selects (day, month, year) |

### Customizing Widgets

```python
class MyForm(forms.Form):
    # Override widget type
    comment = forms.CharField(widget=forms.Textarea)

    # Set HTML attributes
    name = forms.CharField(
        widget=forms.TextInput(attrs={"class": "form-control", "placeholder": "Name"})
    )

    # Widget with choices
    color = forms.ChoiceField(
        choices=[("r", "Red"), ("g", "Green")],
        widget=forms.RadioSelect,
    )

    # Date widget with custom options
    birth = forms.DateField(
        widget=forms.SelectDateWidget(
            years=range(1950, 2025),
            empty_label=("Year", "Month", "Day"),
        )
    )
```

### Custom MultiWidget

```python
from datetime import date

class DateSelectorWidget(forms.MultiWidget):
    def __init__(self, attrs=None):
        widgets = [
            forms.Select(choices={(d, d) for d in range(1, 32)}),
            forms.Select(choices={(m, m) for m in range(1, 13)}),
            forms.Select(choices={(y, y) for y in range(2020, 2030)}),
        ]
        super().__init__(widgets, attrs)

    def decompress(self, value):
        if isinstance(value, date):
            return [value.day, value.month, value.year]
        return [None, None, None]
```

## Form Validation

### Validation Order

1. `Field.to_python()` -- coerce to correct type
2. `Field.validate()` -- field-specific validation
3. `Field.run_validators()` -- run all validators
4. `clean_<fieldname>()` -- per-field custom cleaning on the form
5. `Form.clean()` -- cross-field validation

### Per-Field Validation

```python
class RegistrationForm(forms.Form):
    email = forms.EmailField()
    password = forms.CharField()
    password_confirm = forms.CharField()

    def clean_email(self):
        email = self.cleaned_data["email"]
        if User.objects.filter(email=email).exists():
            raise forms.ValidationError("Email already registered.")
        return email
```

### Cross-Field Validation

```python
    def clean(self):
        cleaned_data = super().clean()
        password = cleaned_data.get("password")
        confirm = cleaned_data.get("password_confirm")
        if password and confirm and password != confirm:
            raise forms.ValidationError("Passwords do not match.")
```

### Using add_error for Field-Specific Errors in clean()

```python
    def clean(self):
        cleaned_data = super().clean()
        if cleaned_data.get("start") and cleaned_data.get("end"):
            if cleaned_data["start"] > cleaned_data["end"]:
                self.add_error("end", "End date must be after start date.")
```

### Raising ValidationError

```python
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

raise ValidationError(
    _("Invalid value: %(value)s"),
    code="invalid",
    params={"value": "42"},
)

# Multiple errors
raise ValidationError([
    ValidationError(_("Error 1"), code="error1"),
    ValidationError(_("Error 2"), code="error2"),
])
```

### Custom Field with Validation

```python
class MultiEmailField(forms.Field):
    def to_python(self, value):
        if not value:
            return []
        return value.split(",")

    def validate(self, value):
        super().validate(value)
        from django.core.validators import validate_email
        for email in value:
            validate_email(email.strip())
```

## ModelForm

### Basic Usage

```python
from django.forms import ModelForm

class ArticleForm(ModelForm):
    class Meta:
        model = Article
        fields = ["title", "content", "category"]
        # Or exclude specific fields
        # exclude = ["created_at"]
        # Or include all
        # fields = "__all__"
        widgets = {
            "content": forms.Textarea(attrs={"rows": 10}),
        }
        labels = {
            "title": "Article Title",
        }
        help_texts = {
            "title": "Enter a descriptive title.",
        }
        error_messages = {
            "title": {"max_length": "Title is too long."},
        }
```

### Saving ModelForms

```python
# Create new object
form = ArticleForm(request.POST)
if form.is_valid():
    article = form.save()

# Edit existing object
article = Article.objects.get(pk=1)
form = ArticleForm(request.POST, instance=article)
if form.is_valid():
    form.save()

# Deferred save (modify before saving)
article = form.save(commit=False)
article.author = request.user
article.save()
form.save_m2m()  # Required when using commit=False with M2M fields
```

### Overriding Fields

```python
class ArticleForm(ModelForm):
    slug = forms.CharField(validators=[validate_slug])

    class Meta:
        model = Article
        fields = ["title", "slug", "content"]
        field_classes = {"slug": MySlugFormField}
```

### ModelForm Factory

```python
from django.forms import modelform_factory

ArticleForm = modelform_factory(Article, fields=["title", "content"])
ArticleForm = modelform_factory(
    Article,
    fields=["title", "content"],
    widgets={"content": forms.Textarea},
)
```

### Form Inheritance

```python
class BaseArticleForm(ModelForm):
    class Meta:
        model = Article
        fields = ["title", "content"]

class ExtendedArticleForm(BaseArticleForm):
    class Meta(BaseArticleForm.Meta):
        fields = BaseArticleForm.Meta.fields + ["category"]

# Remove inherited field
class SimplifiedForm(BaseArticleForm):
    content = None
```

## Formsets

### Basic Formset

```python
from django.forms import formset_factory

ArticleFormSet = formset_factory(ArticleForm, extra=2, max_num=5)

# In a view
if request.method == "POST":
    formset = ArticleFormSet(request.POST)
    if formset.is_valid():
        for form in formset:
            if form.cleaned_data:
                # Process each form
                pass
else:
    formset = ArticleFormSet()
```

### Formset with Initial Data

```python
formset = ArticleFormSet(initial=[
    {"title": "First Article", "pub_date": date.today()},
    {"title": "Second Article", "pub_date": date.today()},
])
```

### Formset Validation

```python
from django.forms import BaseFormSet

class BaseArticleFormSet(BaseFormSet):
    def clean(self):
        if any(self.errors):
            return
        titles = set()
        for form in self.forms:
            if self.can_delete and self._should_delete_form(form):
                continue
            title = form.cleaned_data.get("title")
            if title in titles:
                raise ValidationError("Articles must have distinct titles.")
            titles.add(title)

ArticleFormSet = formset_factory(
    ArticleForm,
    formset=BaseArticleFormSet,
    min_num=1,
    validate_min=True,
    max_num=10,
    validate_max=True,
)
```

### Ordering and Deletion

```python
ArticleFormSet = formset_factory(
    ArticleForm,
    can_order=True,     # Adds ORDER field
    can_delete=True,    # Adds DELETE checkbox
)

formset = ArticleFormSet(request.POST)
if formset.is_valid():
    for form in formset.ordered_forms:
        # Process in order
        pass
    for form in formset.deleted_forms:
        # Handle deletions
        pass
```

### Multiple Formsets in One View

```python
def manage(request):
    if request.method == "POST":
        article_formset = ArticleFormSet(request.POST, prefix="articles")
        book_formset = BookFormSet(request.POST, prefix="books")
        if article_formset.is_valid() and book_formset.is_valid():
            # Process both
            pass
    else:
        article_formset = ArticleFormSet(prefix="articles")
        book_formset = BookFormSet(prefix="books")
```

### Passing Custom Parameters

```python
class MyForm(forms.Form):
    def __init__(self, *args, user, **kwargs):
        self.user = user
        super().__init__(*args, **kwargs)

MyFormSet = formset_factory(MyForm)
formset = MyFormSet(form_kwargs={"user": request.user})
```

## Form Rendering

### Template Rendering Methods

```python
form.as_div()    # Wraps fields in <div> (recommended, default)
form.as_p()      # Wraps fields in <p>
form.as_ul()     # Wraps fields in <li>
form.as_table()  # Wraps fields in <tr>
```

### Template Examples

```django
{# Automatic rendering #}
<form method="post">
    {% csrf_token %}
    {{ form.as_div }}
    <button type="submit">Submit</button>
</form>

{# Manual field rendering #}
<form method="post">
    {% csrf_token %}
    {{ form.non_field_errors }}
    {% for field in form %}
        <div class="field {% if field.errors %}error{% endif %}">
            {{ field.label_tag }}
            {{ field }}
            {{ field.errors }}
            {% if field.help_text %}
                <p class="help">{{ field.help_text|safe }}</p>
            {% endif %}
        </div>
    {% endfor %}
    <button type="submit">Submit</button>
</form>

{# Formset rendering #}
<form method="post">
    {% csrf_token %}
    {{ formset.management_form }}
    {% for form in formset %}
        {{ form.as_div }}
    {% endfor %}
    <button type="submit">Submit</button>
</form>

{# File uploads #}
{% if form.is_multipart %}
    <form enctype="multipart/form-data" method="post">
{% else %}
    <form method="post">
{% endif %}
```

### BoundField Attributes

| Attribute | Description |
|-----------|-------------|
| `field.errors` | Validation errors |
| `field.label_tag` | Label in `<label>` tag |
| `field.label` | Label text |
| `field.value` | Current value |
| `field.help_text` | Help text |
| `field.html_name` | HTML name attribute |
| `field.id_for_label` | HTML ID |
| `field.is_hidden` | Whether field is hidden |
| `field.widget_type` | Widget class name (e.g., "checkbox") |
| `field.css_classes()` | CSS classes for the field |

### Form Configuration

```python
class MyForm(forms.Form):
    error_css_class = "error"
    required_css_class = "required"

# Per-instance configuration
form = MyForm(
    auto_id="field_%s",       # HTML ID format
    label_suffix=" ->",       # Label suffix (default: ":")
    prefix="contact",         # Field name prefix
    initial={"name": "John"}, # Initial values
)
```

## Common Patterns

### Form with File Upload

```python
class UploadForm(forms.Form):
    file = forms.FileField()

def upload(request):
    if request.method == "POST":
        form = UploadForm(request.POST, request.FILES)
        if form.is_valid():
            handle_uploaded_file(request.FILES["file"])
            return redirect("/success/")
    else:
        form = UploadForm()
    return render(request, "upload.html", {"form": form})
```

### Dynamic Form Fields

```python
class DynamicForm(forms.Form):
    def __init__(self, *args, extra_fields=None, **kwargs):
        super().__init__(*args, **kwargs)
        if extra_fields:
            for name, field in extra_fields.items():
                self.fields[name] = field
```

### Change Detection

```python
form = MyForm(request.POST, initial=original_data)
if form.has_changed():
    changed = form.changed_data  # List of changed field names
```

## Best Practices

- Always use `fields` (not `exclude`) in ModelForm for security
- Use `commit=False` when you need to modify the object before saving
- Call `save_m2m()` after `commit=False` saves when M2M fields are involved
- Use `prefix` when rendering multiple formsets or forms on one page
- Validate at the form level (`clean()`) for cross-field rules
- Use `raise ValidationError(message, code=code)` with error codes for programmatic handling
- Always pass `request.FILES` alongside `request.POST` for file upload forms
- Use `form_kwargs` to pass request-specific data (like `user`) to formset forms

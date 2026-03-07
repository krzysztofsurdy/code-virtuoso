# Django Validators

## Overview

Django validators are callables that take a value and raise `ValidationError` if the value does not meet certain criteria. Validators are used on model fields, form fields, and can be written as functions or classes. They run during form validation and when explicitly calling `model.full_clean()`, but do not run automatically on `model.save()`.

## Core Concepts

### Writing a Custom Validator

```python
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _

def validate_even(value):
    if value % 2 != 0:
        raise ValidationError(
            _("%(value)s is not an even number"),
            params={"value": value},
        )
```

### Using Validators on Model Fields

```python
from django.db import models

class MyModel(models.Model):
    even_field = models.IntegerField(validators=[validate_even])
```

### Using Validators on Form Fields

```python
from django import forms

class MyForm(forms.Form):
    even_field = forms.IntegerField(validators=[validate_even])
```

### Class-Based Validators

For complex validation logic, use a class with `__call__()`:

```python
from django.core.exceptions import ValidationError

class MultipleOfValidator:
    def __init__(self, base):
        self.base = base

    def __call__(self, value):
        if value % self.base != 0:
            raise ValidationError(
                "%(value)s is not a multiple of %(base)s",
                params={"value": value, "base": self.base},
            )

    def __eq__(self, other):
        return isinstance(other, MultipleOfValidator) and self.base == other.base

    def deconstruct(self):
        return (
            "%s.%s" % (self.__class__.__module__, self.__class__.__qualname__),
            (self.base,),
            {},
        )
```

Class-based validators used on model fields must implement `deconstruct()` and `__eq__()` for migration serialization.

### When Validators Run

| Context | Runs Automatically? |
|---|---|
| Form validation (`form.is_valid()`) | Yes |
| ModelForm validation | Yes |
| `model.full_clean()` | Yes |
| `model.save()` | No |
| `model.clean_fields()` | Yes |

## Built-in Validators

### RegexValidator

```python
from django.core.validators import RegexValidator

class RegexValidator(regex=None, message=None, code=None, inverse_match=None, flags=0)
```

Validates that a value matches (or does not match) a regular expression using `re.search()`.

| Parameter | Default | Description |
|---|---|---|
| `regex` | `""` | Regex string or compiled pattern |
| `message` | `"Enter a valid value."` | Error message |
| `code` | `"invalid"` | Error code |
| `inverse_match` | `False` | If True, raises error when match IS found |
| `flags` | `0` | Regex flags (e.g., `re.IGNORECASE`) |

```python
alphanumeric = RegexValidator(
    r"^[0-9a-zA-Z]*$",
    "Only alphanumeric characters are allowed.",
)

class MyModel(models.Model):
    code = models.CharField(max_length=10, validators=[alphanumeric])
```

### EmailValidator

```python
from django.core.validators import EmailValidator

class EmailValidator(message=None, code=None, allowlist=None)
```

Validates email addresses. Values longer than 320 characters are always invalid.

| Parameter | Default | Description |
|---|---|---|
| `message` | `"Enter a valid email address."` | Error message |
| `code` | `"invalid"` | Error code |
| `allowlist` | `["localhost"]` | Whitelisted email domains |

### DomainNameValidator

```python
class DomainNameValidator(accept_idna=True, message=None, code=None)
```

Validates domain names. Values longer than 255 characters are invalid. IP addresses are not accepted. Set `accept_idna=False` to reject internationalized domain names.

### URLValidator

```python
from django.core.validators import URLValidator

class URLValidator(schemes=None, regex=None, message=None, code=None)
```

| Parameter | Default | Description |
|---|---|---|
| `schemes` | `["http", "https", "ftp", "ftps"]` | Allowed URL schemes |
| `max_length` | `2048` | Maximum URL length |

Note: `file:///` URLs are not valid; URLs must contain a host.

```python
validate_url = URLValidator(schemes=["https"])

class MyModel(models.Model):
    website = models.URLField(validators=[validate_url])
```

### Numeric Validators

```python
from django.core.validators import MaxValueValidator, MinValueValidator

class MaxValueValidator(limit_value, message=None)  # code: 'max_value'
class MinValueValidator(limit_value, message=None)  # code: 'min_value'
```

`limit_value` can be a callable for dynamic limits:

```python
from django.utils import timezone

class Event(models.Model):
    date = models.DateField(validators=[MinValueValidator(timezone.now)])
```

### Length Validators

```python
from django.core.validators import MaxLengthValidator, MinLengthValidator

class MaxLengthValidator(limit_value, message=None)  # code: 'max_length'
class MinLengthValidator(limit_value, message=None)  # code: 'min_length'
```

`limit_value` can be a callable.

### DecimalValidator

```python
from django.core.validators import DecimalValidator

class DecimalValidator(max_digits, decimal_places)
```

Error codes: `max_digits`, `max_decimal_places`, `max_whole_digits`.

### FileExtensionValidator

```python
from django.core.validators import FileExtensionValidator

class FileExtensionValidator(allowed_extensions, message, code)
```

Validates file extensions (case-insensitive). Error code: `invalid_extension`.

```python
class Document(models.Model):
    file = models.FileField(
        validators=[FileExtensionValidator(allowed_extensions=["pdf", "doc", "docx"])]
    )
```

Do not rely solely on extension validation to determine file type; files can be renamed.

### StepValueValidator

```python
from django.core.validators import StepValueValidator

class StepValueValidator(limit_value, message=None, offset=None)
```

Validates that a value is an integral multiple of `limit_value`, with optional `offset`. Error code: `step_size`.

```python
# Accepts 0, 3, 6, 9, ...
StepValueValidator(3)

# Accepts 1.4, 4.4, 7.4, 10.4, ...
StepValueValidator(3, offset=1.4)
```

### ProhibitNullCharactersValidator

```python
from django.core.validators import ProhibitNullCharactersValidator

class ProhibitNullCharactersValidator(message=None, code=None)
```

Raises `ValidationError` if value contains null characters (`\x00`). Error code: `null_characters_not_allowed`.

## Pre-configured Validator Instances

| Instance | Description |
|---|---|
| `validate_email` | EmailValidator with defaults |
| `validate_domain_name` | DomainNameValidator with defaults |
| `validate_slug` | Letters, numbers, underscores, hyphens only |
| `validate_unicode_slug` | Unicode letters, numbers, underscores, hyphens |
| `validate_ipv4_address` | IPv4 address validation |
| `validate_ipv6_address` | IPv6 address validation |
| `validate_ipv46_address` | IPv4 or IPv6 address validation |
| `validate_comma_separated_integer_list` | Comma-separated integers |
| `validate_image_file_extension` | Image file extension validation (uses Pillow) |

### int_list_validator

```python
from django.core.validators import int_list_validator

def int_list_validator(sep=",", message=None, code="invalid", allow_negative=False)
```

Returns a `RegexValidator` for integers separated by `sep`.

## Common Patterns

### Combining Multiple Validators

```python
class Product(models.Model):
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[
            MinValueValidator(0.01),
            MaxValueValidator(99999.99),
        ],
    )
    sku = models.CharField(
        max_length=20,
        validators=[
            RegexValidator(r"^[A-Z]{2}-\d{4,}$", "SKU must be XX-0000 format"),
            MinLengthValidator(7),
        ],
    )
```

### Validator with Database Lookup

```python
def validate_unique_email_domain(value):
    domain = value.split("@")[1]
    blocked = BlockedDomain.objects.filter(domain=domain).exists()
    if blocked:
        raise ValidationError("This email domain is not allowed.")
```

### Reusable Validator for File Size

```python
from django.core.exceptions import ValidationError

def validate_file_size(value):
    limit = 5 * 1024 * 1024  # 5 MB
    if value.size > limit:
        raise ValidationError("File too large. Size should not exceed 5 MB.")

class Upload(models.Model):
    file = models.FileField(validators=[validate_file_size])
```

## Best Practices

- Prefer built-in validators over custom implementations when possible
- Always provide meaningful error messages with translation support using `gettext_lazy`
- Use `params` in `ValidationError` for interpolation rather than string formatting
- Implement `deconstruct()` and `__eq__()` on class-based validators used in model fields
- Combine `FileExtensionValidator` with content-type checking for file uploads
- Use callable `limit_value` for dynamic validation boundaries (e.g., current date)
- Remember that validators do not run on `model.save()` -- call `full_clean()` explicitly or use ModelForm
- Keep validators focused on a single concern; combine multiple validators on a field rather than building one complex validator
- Use pre-configured instances (`validate_email`, `validate_slug`) for common validation patterns

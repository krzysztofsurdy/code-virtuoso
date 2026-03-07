# Django Models

## Overview

Django models are Python classes that define the structure of database tables. Each model maps to a single database table, with class attributes representing fields (columns). Django automatically generates a database-access API from model definitions, handles migrations, and provides an ORM for querying data without writing raw SQL.

## Core Concepts

### Model Definition

Every model subclasses `django.db.models.Model`. Each attribute is a field that maps to a database column.

```python
from django.db import models

class Person(models.Model):
    first_name = models.CharField(max_length=30)
    last_name = models.CharField(max_length=30)
    birth_date = models.DateField()

    def __str__(self):
        return f"{self.first_name} {self.last_name}"
```

An `id` field (BigAutoField) is added automatically unless you define a field with `primary_key=True`.

### Field Options (Common to All Fields)

| Option | Description |
|---|---|
| `null` | If `True`, stores empty values as `NULL` in database. Default: `False` |
| `blank` | If `True`, field allowed to be blank in forms. Default: `False` |
| `choices` | Iterable of choices restricting valid values |
| `default` | Default value or callable |
| `db_default` | Database-computed default value |
| `db_index` | If `True`, creates database index |
| `db_column` | Custom database column name |
| `db_comment` | Comment on the database column |
| `primary_key` | If `True`, field is the primary key |
| `unique` | If `True`, value must be unique across the table |
| `validators` | List of validators to run on the field |
| `verbose_name` | Human-readable name |
| `help_text` | Extra help text for forms |
| `editable` | If `False`, excluded from admin and ModelForm |

## Field Types

### String Fields

```python
name = models.CharField(max_length=100)         # VARCHAR, max_length required
bio = models.TextField()                         # TEXT, unlimited length
slug = models.SlugField(max_length=50)           # URL-safe slug, implies db_index
email = models.EmailField(max_length=254)        # CharField with email validation
url = models.URLField(max_length=200)            # CharField with URL validation
```

### Numeric Fields

```python
count = models.IntegerField()                    # -2B to 2B
big_count = models.BigIntegerField()             # 64-bit integer
small_count = models.SmallIntegerField()         # -32768 to 32767
positive = models.PositiveIntegerField()         # 0 to 2B
rating = models.FloatField()                     # Python float (avoid for money)
price = models.DecimalField(max_digits=10, decimal_places=2)  # Fixed precision
```

### Date/Time Fields

```python
pub_date = models.DateField()                    # datetime.date
created_at = models.DateTimeField(auto_now_add=True)  # Set on creation
updated_at = models.DateTimeField(auto_now=True)      # Set on every save
duration = models.DurationField()                     # timedelta
```

### Boolean, Binary, and Special Fields

```python
is_active = models.BooleanField(default=True)
data = models.BinaryField()                      # Raw binary data
ip = models.GenericIPAddressField()              # IPv4 or IPv6
uuid = models.UUIDField(default=uuid.uuid4)     # UUID
metadata = models.JSONField(default=dict)        # JSON data
```

### File Fields

```python
document = models.FileField(upload_to='documents/%Y/%m/')
photo = models.ImageField(upload_to='photos/', height_field='height', width_field='width')
```

Upload path can use `strftime()` formatting or a callable:

```python
def user_directory_path(instance, filename):
    return f"user_{instance.user.id}/{filename}"

upload = models.FileField(upload_to=user_directory_path)
```

### Auto-Increment Fields

```python
id = models.AutoField(primary_key=True)          # 32-bit auto-increment
id = models.BigAutoField(primary_key=True)        # 64-bit (default in Django)
id = models.SmallAutoField(primary_key=True)      # 16-bit
```

### Generated Fields

```python
full_name = models.GeneratedField(
    expression=Concat("first_name", Value(" "), "last_name"),
    output_field=models.CharField(max_length=200),
    db_persist=True,
)
```

## Choices with Enumerations

```python
class Student(models.Model):
    class YearInSchool(models.TextChoices):
        FRESHMAN = "FR", "Freshman"
        SOPHOMORE = "SO", "Sophomore"
        JUNIOR = "JR", "Junior"
        SENIOR = "SR", "Senior"

    year = models.CharField(max_length=2, choices=YearInSchool, default=YearInSchool.FRESHMAN)

student = Student.objects.first()
student.get_year_display()  # "Freshman"
```

Use `TextChoices` for strings, `IntegerChoices` for integers.

## Relationships

### ForeignKey (Many-to-One)

```python
class Car(models.Model):
    manufacturer = models.ForeignKey(Manufacturer, on_delete=models.CASCADE)
```

`on_delete` options:

| Option | Behavior |
|---|---|
| `CASCADE` | Delete related objects |
| `PROTECT` | Raise `ProtectedError` |
| `RESTRICT` | Raise `RestrictedError` (more nuanced than PROTECT) |
| `SET_NULL` | Set to NULL (requires `null=True`) |
| `SET_DEFAULT` | Set to default value |
| `SET(callable)` | Set to specific value or callable result |
| `DO_NOTHING` | No action (may cause IntegrityError) |

### ManyToManyField

```python
class Pizza(models.Model):
    toppings = models.ManyToManyField(Topping)
```

With extra fields on the relationship (through model):

```python
class Membership(models.Model):
    person = models.ForeignKey(Person, on_delete=models.CASCADE)
    group = models.ForeignKey(Group, on_delete=models.CASCADE)
    date_joined = models.DateField()

class Group(models.Model):
    members = models.ManyToManyField(Person, through="Membership")
```

### OneToOneField

```python
class Restaurant(models.Model):
    place = models.OneToOneField(Place, on_delete=models.CASCADE)
```

## Meta Options

```python
class Article(models.Model):
    class Meta:
        db_table = "custom_table_name"
        ordering = ["-pub_date", "author"]
        verbose_name = "article"
        verbose_name_plural = "articles"
        unique_together = [["author", "title"]]  # deprecated, use constraints
        constraints = [
            models.CheckConstraint(condition=models.Q(age__gte=18), name="age_gte_18"),
            models.UniqueConstraint(fields=["email"], name="unique_email"),
        ]
        indexes = [
            models.Index(fields=["last_name", "first_name"]),
        ]
        permissions = [("can_publish", "Can publish articles")]
        get_latest_by = "pub_date"
        abstract = False
        proxy = False
        managed = True
        default_related_name = "articles"
```

## Model Inheritance

### Abstract Base Classes

No database table created. Fields are copied to child models.

```python
class CommonInfo(models.Model):
    name = models.CharField(max_length=100)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True
        ordering = ["name"]

class Student(CommonInfo):
    grade = models.IntegerField()
    # Creates ONE table with name, created_at, grade
```

### Multi-Table Inheritance

Each model gets its own table, linked by an automatic OneToOneField.

```python
class Place(models.Model):
    name = models.CharField(max_length=50)

class Restaurant(Place):
    serves_pizza = models.BooleanField(default=False)
    # Creates TWO tables: place and restaurant

p = Place.objects.get(id=1)
p.restaurant  # Access child if it exists
```

### Proxy Models

Same database table, different Python behavior.

```python
class OrderedPerson(Person):
    class Meta:
        proxy = True
        ordering = ["last_name"]

    def custom_method(self):
        pass
```

## Model Methods

```python
class Person(models.Model):
    first_name = models.CharField(max_length=50)
    last_name = models.CharField(max_length=50)

    def __str__(self):
        return f"{self.first_name} {self.last_name}"

    def get_absolute_url(self):
        return f"/people/{self.pk}/"

    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"

    def save(self, **kwargs):
        self.first_name = self.first_name.strip()
        super().save(**kwargs)  # Always call super and pass kwargs
```

## Managers

```python
class PublishedManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(status="published")

class Article(models.Model):
    objects = models.Manager()          # Default manager
    published = PublishedManager()      # Custom manager

Article.objects.all()       # All articles
Article.published.all()     # Only published articles
```

For use in migrations:

```python
class MyManager(models.Manager):
    use_in_migrations = True
```

## Common Patterns

### UUID Primary Key

```python
import uuid

class MyModel(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
```

### Timestamps Mixin

```python
class TimestampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True
```

### Soft Delete

```python
class SoftDeleteManager(models.Manager):
    def get_queryset(self):
        return super().get_queryset().filter(deleted_at__isnull=True)

class SoftDeleteModel(models.Model):
    deleted_at = models.DateTimeField(null=True, blank=True)
    objects = SoftDeleteManager()
    all_objects = models.Manager()

    class Meta:
        abstract = True
```

## Best Practices

- Use `CharField` with `max_length` for bounded strings, `TextField` for unbounded
- Prefer `DecimalField` over `FloatField` for financial data
- Use `TextChoices`/`IntegerChoices` enums instead of raw choice tuples
- Set `related_name` on ForeignKey/M2M to control reverse accessor naming
- Use `%(app_label)s_%(class)s_related` pattern in abstract base classes for related_name
- Always call `super().save(**kwargs)` when overriding save()
- Use `constraints` instead of deprecated `unique_together`
- Keep models in a package (`models/`) when the file grows large

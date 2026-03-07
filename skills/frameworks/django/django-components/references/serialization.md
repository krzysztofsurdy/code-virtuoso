# Django Serialization

## Overview

Django's serialization framework translates Django model instances into various formats (JSON, XML, YAML, JSONL) for data export, fixtures, and inter-system communication. It provides both serialization (model to format) and deserialization (format to model) capabilities, with support for natural keys, relationship handling, and custom serializer implementations.

## Core Concepts

### Basic Serialization

```python
from django.core import serializers

# Serialize a QuerySet to JSON
data = serializers.serialize("json", SomeModel.objects.all())

# Serialize specific fields only
data = serializers.serialize("json", SomeModel.objects.all(), fields=["name", "size"])
```

### Using Serializer Objects Directly

```python
JSONSerializer = serializers.get_serializer("json")
json_serializer = JSONSerializer()
json_serializer.serialize(queryset)
data = json_serializer.getvalue()

# Stream to file
with open("file.json", "w") as out:
    json_serializer.serialize(SomeModel.objects.all(), stream=out)
```

### Basic Deserialization

```python
for obj in serializers.deserialize("json", data):
    obj.save()  # Saves to database
```

Deserialized objects are `DeserializedObject` wrappers, not regular model instances. Access the actual model via `obj.object`.

```python
for deserialized_object in serializers.deserialize("json", data):
    if object_should_be_saved(deserialized_object):
        deserialized_object.save()

# Ignore fields that no longer exist on the model
serializers.deserialize("json", data, ignorenonexistent=True)
```

## Serialization Formats

### JSON

```python
data = serializers.serialize("json", SomeModel.objects.all())
```

Output structure:

```json
[
    {
        "pk": "4b678b301dfd8a4e0dad910de3ae245b",
        "model": "sessions.session",
        "fields": {
            "expire_date": "2013-01-16T08:16:59.844Z"
        }
    }
]
```

### JSONL (JSON Lines)

```python
data = serializers.serialize("jsonl", SomeModel.objects.all())
```

One JSON object per line, useful for streaming and large datasets:

```
{"pk": "4b678b30...", "model": "sessions.session", "fields": {...}}
{"pk": "88bea72c...", "model": "sessions.session", "fields": {...}}
```

### XML

```python
data = serializers.serialize("xml", SomeModel.objects.all())
```

```xml
<?xml version="1.0" encoding="utf-8"?>
<django-objects version="1.0">
    <object pk="123" model="sessions.session">
        <field type="DateTimeField" name="expire_date">
            2013-01-16T08:16:59.844560+00:00
        </field>
    </object>
</django-objects>
```

Foreign keys and many-to-many relationships in XML:

```xml
<object pk="27" model="auth.permission">
    <field to="contenttypes.contenttype" name="content_type" rel="ManyToOneRel">9</field>
</object>

<object pk="1" model="auth.user">
    <field to="auth.permission" name="user_permissions" rel="ManyToManyRel">
        <object pk="46"></object>
        <object pk="47"></object>
    </field>
</object>
```

### YAML

Requires `PyYAML` package:

```python
data = serializers.serialize("yaml", SomeModel.objects.all())
```

```yaml
- model: sessions.session
  pk: 4b678b301dfd8a4e0dad910de3ae245b
  fields:
    expire_date: 2013-01-16 08:16:59.844560+00:00
```

## Key Classes and Methods

### DjangoJSONEncoder

Custom encoder for Django-specific types:

```python
from django.core.serializers.json import DjangoJSONEncoder

class LazyEncoder(DjangoJSONEncoder):
    def default(self, obj):
        if isinstance(obj, YourCustomType):
            return str(obj)
        return super().default(obj)

serializers.serialize("json", queryset, cls=LazyEncoder)
```

Supported types: `datetime`, `date`, `time`, `timedelta`, `Decimal`, `UUID`, `Promise` (lazy strings).

### Exception Handling

- `SerializerDoesNotExist` - unknown format passed to `get_serializer()`
- `DeserializationError` - deserialization failure
- `ValueError` - XML contains disallowed control characters

## Natural Keys

Natural keys provide human-readable, stable references to objects without relying on auto-generated primary keys.

### Deserialization with Natural Keys

Define `get_by_natural_key()` on a custom manager:

```python
class PersonManager(models.Manager):
    def get_by_natural_key(self, first_name, last_name):
        return self.get(first_name=first_name, last_name=last_name)

class Person(models.Model):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    birthdate = models.DateField()

    objects = PersonManager()

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["first_name", "last_name"],
                name="unique_first_last_name",
            ),
        ]
```

### Serialization with Natural Keys

Add `natural_key()` method to the model:

```python
class Person(models.Model):
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)

    objects = PersonManager()

    def natural_key(self):
        return (self.first_name, self.last_name)
```

Serialize using natural keys:

```python
serializers.serialize(
    "json",
    [book1, book2],
    indent=2,
    use_natural_foreign_keys=True,
    use_natural_primary_keys=True,
)
```

With `use_natural_primary_keys=True`, the `pk` field is omitted from output:

```json
{
    "model": "store.person",
    "fields": {
        "first_name": "Douglas",
        "last_name": "Adams",
        "birth_date": "1952-03-11"
    }
}
```

### Dependencies Between Natural Keys

Control serialization order when natural keys reference other models:

```python
class Book(models.Model):
    name = models.CharField(max_length=100)
    author = models.ForeignKey(Person, on_delete=models.CASCADE)

    def natural_key(self):
        return (self.name,) + self.author.natural_key()

    natural_key.dependencies = ["example_app.person"]
```

### Forward References

Handle objects referencing other objects not yet deserialized:

```python
objs_with_deferred_fields = []

for obj in serializers.deserialize("json", data, handle_forward_references=True):
    obj.save()
    if obj.deferred_fields is not None:
        objs_with_deferred_fields.append(obj)

for obj in objs_with_deferred_fields:
    obj.save_deferred_fields()
```

Requires `null=True` on the ForeignKey field.

## Handling Inherited Models

### Abstract Base Classes

No special handling required -- serialization includes all inherited fields automatically.

### Multi-table Inheritance

Must serialize both parent and child explicitly:

```python
class Place(models.Model):
    name = models.CharField(max_length=50)

class Restaurant(Place):
    serves_hot_dogs = models.BooleanField(default=False)

# Incorrect -- loses Place fields
data = serializers.serialize("json", Restaurant.objects.all())

# Correct -- include both
all_objects = [*Restaurant.objects.all(), *Place.objects.all()]
data = serializers.serialize("json", all_objects)
```

## Custom Serializers

Register custom serializers in settings:

```python
SERIALIZATION_MODULES = {
    "csv": "path.to.custom_csv_serializer",
}
```

Custom serializers extend `serializers.python.Serializer` and implement `get_dump_object()`, `end_object()`, and a `Deserializer` class.

## Management Commands

### dumpdata

Export model data to a file:

```bash
# Basic export
python manage.py dumpdata myapp > fixture.json

# With natural keys
python manage.py dumpdata --natural-foreign --natural-primary -o fixture.json

# Specific models
python manage.py dumpdata myapp.MyModel --indent 2

# Exclude specific apps
python manage.py dumpdata --exclude auth.permission
```

### loaddata

Import serialized data:

```bash
python manage.py loaddata fixture.json
```

Django searches for fixtures in:
1. The `fixtures` directory of every installed application
2. Directories listed in `FIXTURE_DIRS` setting
3. The literal path provided

## Common Patterns

### Fixture Workflow

```bash
# Export current data as fixture
python manage.py dumpdata myapp --indent 2 --natural-foreign -o myapp/fixtures/initial_data.json

# Load fixture into database
python manage.py loaddata initial_data

# Load specific format
python manage.py loaddata initial_data.yaml
```

### Selective Field Serialization

```python
# Only serialize specific fields (pk always included)
data = serializers.serialize("json", MyModel.objects.all(), fields=["name", "email"])
```

### Primary Key Handling

When `pk` in serialized data is `None` or missing, a new instance is created on deserialization, enabling non-destructive imports.

## Best Practices

- Use natural keys for fixtures shared across environments (avoids pk conflicts)
- Add `UniqueConstraint` on fields used in `natural_key()` to guarantee uniqueness
- Declare `natural_key.dependencies` when natural keys reference other models
- Use JSONL format for large datasets to enable streaming
- Always test fixture loading in a clean database before relying on them
- Use `--indent 2` with `dumpdata` for human-readable output
- Handle multi-table inheritance explicitly by serializing all model levels
- Use `ignorenonexistent=True` when loading fixtures from older schema versions

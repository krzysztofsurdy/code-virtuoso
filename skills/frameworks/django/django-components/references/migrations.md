# Django Migrations

## Overview

Migrations are Django's version control system for database schemas. They propagate model changes (adding fields, deleting models, etc.) to the database in a consistent, repeatable way. Migrations are Python files that describe operations to apply or reverse schema changes.

## Core Concepts

### Migration Workflow

```bash
# 1. Make changes to models.py

# 2. Generate migration files
python manage.py makemigrations

# 3. Review the generated migration
# Inspect migrations/000X_auto.py

# 4. Apply migrations to database
python manage.py migrate

# 5. Commit both model changes and migration files
```

### Key Commands

| Command | Description |
|---|---|
| `makemigrations` | Create migration files from model changes |
| `migrate` | Apply or unapply migrations |
| `showmigrations` | List all migrations and their status |
| `sqlmigrate app 0001` | Display SQL for a specific migration |
| `squashmigrations app 0004` | Combine migrations into fewer files |
| `makemigrations --empty app` | Create an empty migration for data migrations |
| `makemigrations --name changed_model app` | Create with custom name |

### Migration File Structure

```python
from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [("myapp", "0001_initial")]

    operations = [
        migrations.AddField("Author", "rating", models.IntegerField(default=0)),
        migrations.DeleteModel("Tribble"),
    ]
```

Key attributes:
- `dependencies`: migrations that must run before this one
- `operations`: list of schema/data operations
- `initial`: marks as initial migration (optional)
- `atomic`: set to `False` to disable transaction wrapping (optional)

## Schema Operations

### Model Operations

```python
# Create a model
migrations.CreateModel(
    name="Article",
    fields=[
        ("id", models.AutoField(primary_key=True)),
        ("title", models.CharField(max_length=200)),
    ],
    options={"verbose_name": "Article"},
)

# Delete a model
migrations.DeleteModel(name="OldModel")

# Rename a model
migrations.RenameModel(old_name="OldName", new_name="NewName")

# Change table name
migrations.AlterModelTable(name="MyModel", table="custom_table_name")

# Change model options (permissions, verbose_name, etc.)
migrations.AlterModelOptions(
    name="MyModel",
    options={"verbose_name": "Updated Name"},
)
```

### Field Operations

```python
# Add a field
migrations.AddField(
    model_name="Article",
    name="description",
    field=models.TextField(null=True),
)

# Remove a field
migrations.RemoveField(model_name="Article", name="old_field")

# Alter a field (change type, null, unique, etc.)
migrations.AlterField(
    model_name="Article",
    name="email",
    field=models.EmailField(unique=True),
)

# Rename a field
migrations.RenameField(
    model_name="Article",
    old_name="email_address",
    new_name="email",
)
```

### Index and Constraint Operations

```python
# Add index
migrations.AddIndex(
    model_name="Article",
    index=models.Index(fields=["title"], name="idx_title"),
)

# Remove index
migrations.RemoveIndex(model_name="Article", name="idx_title")

# Add constraint
migrations.AddConstraint(
    model_name="Article",
    constraint=models.CheckConstraint(
        check=models.Q(rating__gte=1),
        name="rating_gte_1",
    ),
)

# Remove constraint
migrations.RemoveConstraint(model_name="Article", name="rating_gte_1")
```

## Data Migrations

Create an empty migration and add `RunPython` operations.

```bash
python manage.py makemigrations --empty yourapp
```

```python
from django.db import migrations

def populate_slugs(apps, schema_editor):
    Article = apps.get_model("yourapp", "Article")
    for article in Article.objects.all():
        article.slug = article.title.lower().replace(" ", "-")
        article.save(update_fields=["slug"])

def reverse_slugs(apps, schema_editor):
    Article = apps.get_model("yourapp", "Article")
    Article.objects.update(slug="")

class Migration(migrations.Migration):
    dependencies = [("yourapp", "0002_add_slug")]

    operations = [
        migrations.RunPython(populate_slugs, reverse_slugs),
    ]
```

### Historical Models

Always use `apps.get_model()` instead of direct imports in data migrations:

```python
# WRONG: direct import may not match migration state
from myapp.models import Article

# CORRECT: historical model matching the migration state
def my_migration(apps, schema_editor):
    Article = apps.get_model("myapp", "Article")
```

Historical models do not have custom methods, `save()` overrides, or custom constructors.

### RunSQL

Execute raw SQL statements:

```python
migrations.RunSQL(
    sql="INSERT INTO myapp_country (name, code) VALUES ('USA', 'us');",
    reverse_sql="DELETE FROM myapp_country WHERE code = 'us';",
)

# With parameters
migrations.RunSQL(
    sql=[("INSERT INTO musician (name) VALUES (%s);", ["Reinhardt"])],
    reverse_sql=[("DELETE FROM musician WHERE name=%s;", ["Reinhardt"])],
)

# Irreversible (one-way)
migrations.RunSQL("DROP VIEW my_view;", reverse_sql=migrations.RunSQL.noop)
```

### SeparateDatabaseAndState

Separate database operations from Django state changes:

```python
migrations.SeparateDatabaseAndState(
    database_operations=[
        migrations.RunSQL("ALTER TABLE app_model ADD COLUMN col VARCHAR(255);"),
    ],
    state_operations=[
        migrations.AddField("Model", "col", models.CharField(max_length=255)),
    ],
)
```

## Common Patterns

### Adding a Unique Non-Nullable Field

Multi-step approach for tables with existing rows:

```python
# Step 1: Add field as nullable
migrations.AddField(
    model_name="mymodel",
    name="uuid",
    field=models.UUIDField(default=uuid.uuid4, null=True),
)
```

```python
# Step 2: Populate values (data migration)
import uuid

def gen_uuid(apps, schema_editor):
    MyModel = apps.get_model("myapp", "MyModel")
    for row in MyModel.objects.all():
        row.uuid = uuid.uuid4()
        row.save(update_fields=["uuid"])

class Migration(migrations.Migration):
    operations = [
        migrations.RunPython(gen_uuid, reverse_code=migrations.RunPython.noop),
    ]
```

```python
# Step 3: Make non-nullable and unique
migrations.AlterField(
    model_name="mymodel",
    name="uuid",
    field=models.UUIDField(default=uuid.uuid4, unique=True),
)
```

### Non-Atomic Migrations for Large Tables

```python
from django.db import migrations, transaction

def gen_uuid(apps, schema_editor):
    MyModel = apps.get_model("myapp", "MyModel")
    while MyModel.objects.filter(uuid__isnull=True).exists():
        with transaction.atomic():
            for row in MyModel.objects.filter(uuid__isnull=True)[:1000]:
                row.uuid = uuid.uuid4()
                row.save(update_fields=["uuid"])

class Migration(migrations.Migration):
    atomic = False

    operations = [
        migrations.RunPython(gen_uuid),
    ]
```

### Multiple Database Support

```python
def forwards(apps, schema_editor):
    if schema_editor.connection.alias != "default":
        return
    MyModel = apps.get_model("myapp", "MyModel")
    # ... migration logic

class Migration(migrations.Migration):
    operations = [
        migrations.RunPython(forwards, hints={"target_db": "default"}),
    ]
```

## Reversing Migrations

```bash
# Reverse to a specific migration
python manage.py migrate myapp 0002

# Reverse all migrations for an app
python manage.py migrate myapp zero
```

## Squashing Migrations

Combine multiple migrations into one to reduce migration count:

```bash
python manage.py squashmigrations myapp 0004
```

Post-squash workflow:
1. Keep old migrations, commit squashed migration
2. Deploy and verify all environments run `migrate`
3. Remove old migrations, update dependencies referencing them
4. Remove `replaces` attribute from squashed migration
5. Commit and deploy again

## Dependencies

```python
class Migration(migrations.Migration):
    dependencies = [
        ("myapp", "0001_initial"),          # Same app
        ("other_app", "0003_add_field"),    # Cross-app
    ]

    # Force this migration to run before another
    run_before = [
        ("third_party_app", "0001_initial"),
    ]
```

Django auto-creates cross-app dependencies for ForeignKey references.

For swappable models (like custom User):

```python
from django.conf import settings
from django.db.migrations import swappable_dependency

dependencies = [
    swappable_dependency(settings.AUTH_USER_MODEL),
]
```

## Database Backend Support

| Feature | PostgreSQL | MySQL | SQLite |
|---|---|---|---|
| DDL transactions | Yes | No | Yes |
| Schema alteration | Full | Full | Limited (emulated) |
| Production ready | Yes | Yes | No |

- PostgreSQL: most capable, supports DDL transactions
- MySQL: no transaction support for schema changes; manual fix-up on failures
- SQLite: limited alteration (Django emulates via create-copy-drop-rename)

## Migration Transactions

```python
# Disable transaction wrapping (needed for some PostgreSQL operations)
class Migration(migrations.Migration):
    atomic = False

# RunPython with explicit atomic control
migrations.RunPython(forward_code, reverse_code, atomic=True)
```

## Serialization

Migrations can serialize: primitives, collections, dates, Decimal, UUID, Path, Enum, Django fields, and classes with `deconstruct()`.

```python
from django.utils.deconstruct import deconstructible

@deconstructible
class MyValidator:
    def __init__(self, max_length=100):
        self.max_length = max_length

    def __eq__(self, other):
        return self.max_length == other.max_length
```

## Best Practices

- Commit migrations with model changes as a single commit
- Never edit auto-generated migrations unless necessary
- Use `--name` flag for meaningful migration names
- Use `apps.get_model()` instead of direct imports in data migrations
- Use `schema_editor.connection.alias` for multi-database support
- Test migrations locally before production
- Run `makemigrations` with the lowest Django version you support
- Squash migrations periodically to reduce migration count
- Always provide `reverse_code` for reversible data migrations
- Use `RunPython.noop` for one-way operations instead of omitting reverse

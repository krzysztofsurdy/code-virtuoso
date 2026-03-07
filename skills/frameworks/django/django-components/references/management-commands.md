# Django Management Commands

## Overview

Django management commands are invoked via `manage.py` or `django-admin`. Django ships with dozens of built-in commands for database management, project scaffolding, testing, and more. Custom commands can be created within any installed app.

## Built-in Commands

### Database Commands

#### migrate

Synchronizes database state with models and migrations:

```bash
./manage.py migrate                          # Apply all pending migrations
./manage.py migrate myapp                    # Migrate specific app
./manage.py migrate myapp 0001_initial       # Migrate to specific version
./manage.py migrate myapp zero               # Revert all app migrations
./manage.py migrate --plan                   # Show what would be applied
./manage.py migrate --fake                   # Mark as applied without running SQL
./manage.py migrate --fake-initial           # Skip initial if tables exist
./manage.py migrate --check                  # Exit non-zero if unapplied migrations
./manage.py migrate --database other         # Target specific database
./manage.py migrate --prune                  # Remove nonexistent migrations from DB
```

#### makemigrations

Creates new migrations based on model changes:

```bash
./manage.py makemigrations                   # Auto-detect all changes
./manage.py makemigrations myapp             # For specific app
./manage.py makemigrations --dry-run -v 3    # Preview without writing
./manage.py makemigrations --merge           # Fix migration conflicts
./manage.py makemigrations --name add_field  # Custom migration name
./manage.py makemigrations --empty myapp     # Empty migration for manual editing
./manage.py makemigrations --check           # Exit non-zero if changes detected
./manage.py makemigrations --update          # Merge into latest migration
```

#### showmigrations

Displays migration status:

```bash
./manage.py showmigrations                   # List all with [X] applied status
./manage.py showmigrations --plan            # Show execution plan
./manage.py showmigrations myapp             # For specific app
```

#### sqlmigrate

Prints SQL for a migration:

```bash
./manage.py sqlmigrate myapp 0001           # Forward SQL
./manage.py sqlmigrate myapp 0001 --backwards  # Reverse SQL
```

#### squashmigrations

Squashes multiple migrations into one:

```bash
./manage.py squashmigrations myapp 0004     # Squash 0001-0004
./manage.py squashmigrations myapp 0002 0004  # Squash 0002-0004
./manage.py squashmigrations myapp 0004 --squashed-name merged
```

#### dbshell

Opens the database command-line client:

```bash
./manage.py dbshell                          # Default database
./manage.py dbshell --database other         # Specific database
./manage.py dbshell -- -c 'SELECT 1'         # Pass args to client (PostgreSQL)
```

#### inspectdb

Generates model code from existing database tables:

```bash
./manage.py inspectdb > models.py            # All tables
./manage.py inspectdb table1 table2          # Specific tables
./manage.py inspectdb --include-views        # Include database views
```

#### flush

Removes all data from the database:

```bash
./manage.py flush                            # With confirmation prompt
./manage.py flush --noinput                  # Without confirmation
```

#### dumpdata

Exports data as fixtures:

```bash
./manage.py dumpdata > backup.json                    # All data
./manage.py dumpdata myapp --indent=2                 # Specific app, formatted
./manage.py dumpdata myapp.MyModel --pks=1,2,3        # Specific records
./manage.py dumpdata --exclude=auth --exclude=contenttypes
./manage.py dumpdata --natural-foreign --natural-primary
./manage.py dumpdata -o backup.json.gz                # Compressed output
```

#### loaddata

Loads fixture data:

```bash
./manage.py loaddata mydata.json             # Load fixture
./manage.py loaddata fixture1 fixture2       # Multiple fixtures
./manage.py loaddata --app=myapp             # Search in specific app
```

### Server Commands

#### runserver

Starts the development server:

```bash
./manage.py runserver                        # localhost:8000
./manage.py runserver 8080                   # Custom port
./manage.py runserver 0.0.0.0:8000           # All interfaces
./manage.py runserver --noreload             # Disable auto-reload
./manage.py runserver --nothreading          # Disable threading
./manage.py runserver -6                     # IPv6
```

#### testserver

Runs development server with fixture data:

```bash
./manage.py testserver fixture1.json fixture2.json
```

### Project Scaffolding

#### startproject

```bash
django-admin startproject myproject
django-admin startproject myproject /path/to/directory
django-admin startproject --template=/path/to/template myproject
```

#### startapp

```bash
./manage.py startapp myapp
./manage.py startapp myapp /path/to/directory
```

### Testing and Checks

#### test

```bash
./manage.py test                             # All tests
./manage.py test myapp                       # App tests
./manage.py test myapp.tests.MyTestCase      # Specific class
./manage.py test --failfast                  # Stop on first failure
./manage.py test --parallel auto             # Parallel execution
./manage.py test --keepdb                    # Preserve test database
./manage.py test --shuffle                   # Random order
./manage.py test --tag=fast                  # Tagged tests only
./manage.py test --exclude-tag=slow          # Exclude tagged tests
./manage.py test -k test_name               # Pattern matching
./manage.py test --pdb                       # Debug on failure
./manage.py test --timing                    # Show timings
./manage.py test --durations 10              # 10 slowest tests
```

#### check

Inspects the project for common problems:

```bash
./manage.py check                            # All checks
./manage.py check auth admin                 # Specific apps
./manage.py check --deploy                   # Deployment checks
./manage.py check --tag models               # Specific check category
./manage.py check --list-tags                # List available tags
./manage.py check --fail-level WARNING       # Fail threshold
```

### User Management

#### createsuperuser

```bash
./manage.py createsuperuser
./manage.py createsuperuser --username=admin --email=admin@example.com
DJANGO_SUPERUSER_PASSWORD=pass ./manage.py createsuperuser --noinput --username=admin --email=admin@example.com
```

#### changepassword

```bash
./manage.py changepassword username
```

### Static Files

#### collectstatic

Collects static files into `STATIC_ROOT`:

```bash
./manage.py collectstatic
./manage.py collectstatic --noinput          # No confirmation
./manage.py collectstatic --clear            # Clear before collecting
```

### Internationalization

#### makemessages

```bash
./manage.py makemessages -l de              # German translations
./manage.py makemessages --all              # All languages
./manage.py makemessages -e html,txt,py     # Specific extensions
```

#### compilemessages

```bash
./manage.py compilemessages                  # All locales
./manage.py compilemessages -l pt_BR         # Specific locale
```

### Shell

```bash
./manage.py shell                            # Default Python shell
./manage.py shell -i ipython                 # IPython
./manage.py shell -c "import django; print(django.__version__)"
```

Auto-imports (Django 5.2+): models from `INSTALLED_APPS`, `connection`, `settings`, `timezone`.

### Utility

```bash
./manage.py version                          # Django version
./manage.py diffsettings                     # Show non-default settings
./manage.py help                             # List commands
./manage.py help migrate                     # Command help
```

## Default Options (All Commands)

| Option | Description |
|--------|-------------|
| `--settings SETTINGS` | Settings module path |
| `--pythonpath PATH` | Add to sys.path |
| `--traceback` | Full stack trace on error |
| `-v {0,1,2,3}` | Verbosity level |
| `--no-color` | Disable colored output |
| `--force-color` | Force colored output |
| `--skip-checks` | Skip system checks |

## Writing Custom Management Commands

### Directory Structure

```
myapp/
    management/
        __init__.py
        commands/
            __init__.py
            closepoll.py
    models.py
```

### Basic Command

```python
from django.core.management.base import BaseCommand, CommandError
from polls.models import Question

class Command(BaseCommand):
    help = "Closes the specified poll for voting"

    def add_arguments(self, parser):
        # Positional arguments
        parser.add_argument("poll_ids", nargs="+", type=int)

        # Optional arguments
        parser.add_argument(
            "--delete",
            action="store_true",
            help="Delete poll instead of closing it",
        )

    def handle(self, *args, **options):
        for poll_id in options["poll_ids"]:
            try:
                poll = Question.objects.get(pk=poll_id)
            except Question.DoesNotExist:
                raise CommandError(f'Poll "{poll_id}" does not exist')

            if options["delete"]:
                poll.delete()
                self.stdout.write(self.style.WARNING(f'Deleted poll "{poll_id}"'))
            else:
                poll.opened = False
                poll.save()
                self.stdout.write(self.style.SUCCESS(f'Closed poll "{poll_id}"'))
```

### BaseCommand Attributes

| Attribute | Description |
|-----------|-------------|
| `help` | Command description shown in help output |
| `missing_args_message` | Custom error for missing arguments |
| `output_transaction` | Wrap output with `BEGIN;`/`COMMIT;` |
| `requires_migrations_checks` | Warn if migrations don't match database |
| `requires_system_checks` | List of check tags or `'__all__'` |
| `style` | Colored output styling instance |

### Command Output

```python
def handle(self, *args, **options):
    # Always use self.stdout/self.stderr, never print()
    self.stdout.write("Normal output")
    self.stderr.write("Error output")

    # Styled output
    self.stdout.write(self.style.SUCCESS("Success"))
    self.stdout.write(self.style.WARNING("Warning"))
    self.stdout.write(self.style.ERROR("Error"))
    self.stdout.write(self.style.NOTICE("Notice"))

    # Custom line ending
    self.stdout.write("No newline", ending="")
```

### BaseCommand Subclasses

#### AppCommand

Operates on installed applications:

```python
from django.core.management.base import AppCommand

class Command(AppCommand):
    def handle_app_config(self, app_config, **options):
        # Called once per app label from command line
        self.stdout.write(f"Processing {app_config.label}")
```

#### LabelCommand

Operates on arbitrary labels:

```python
from django.core.management.base import LabelCommand

class Command(LabelCommand):
    label = "domain name"

    def handle_label(self, label, **options):
        self.stdout.write(f"Processing {label}")
```

### Suppressing Translations

```python
from django.core.management.base import BaseCommand, no_translations

class Command(BaseCommand):
    @no_translations
    def handle(self, *args, **options):
        # No active locale -- prevents translated content in DB
        pass
```

## Calling Commands Programmatically

```python
from django.core.management import call_command

# Basic usage
call_command("flush", verbosity=0, interactive=False)
call_command("loaddata", "test_data", verbosity=0)

# With multiple options
call_command("dumpdata", exclude=["contenttypes", "auth"])

# Capture output
from io import StringIO
out = StringIO()
call_command("dumpdata", stdout=out)
output = out.getvalue()

# Redirect to file
with open("/path/to/output", "w") as f:
    call_command("dumpdata", stdout=f)
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `DJANGO_SETTINGS_MODULE` | Settings module path |
| `DJANGO_SUPERUSER_PASSWORD` | Superuser password for `--noinput` |
| `DJANGO_SUPERUSER_<FIELD>` | Required fields for `createsuperuser --noinput` |
| `DJANGO_COLORS` | Color palette (`dark`, `light`, `nocolor`) |
| `DJANGO_WATCHMAN_TIMEOUT` | Watchman timeout (default: 5s) |

## Best Practices

- Always use `self.stdout`/`self.stderr` instead of `print()` for testability
- Use `CommandError` for user-facing errors (formatted nicely by Django)
- Use `add_arguments` with `argparse` for argument parsing
- Set `help` attribute for command documentation
- Use `call_command` for programmatic invocation, not `execute()`
- Use `--noinput` flag for CI/CD pipelines
- Use `--check` flags (`migrate --check`, `makemigrations --check`) in CI

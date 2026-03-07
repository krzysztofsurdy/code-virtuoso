# Django Static Files

## Overview

Django's `django.contrib.staticfiles` app collects static files (CSS, JavaScript, images) from each application and other specified locations into a single directory for production serving. It provides finders to locate files during development, storage backends for production optimization, and management commands for deployment.

## Core Concepts

### Static File Organization

Store static files in a subdirectory matching the app name to avoid naming conflicts:

```
my_app/
    static/
        my_app/          # Namespace directory
            css/
                styles.css
            js/
                app.js
            images/
                logo.png
```

### Using Static Files in Templates

```django
{% load static %}
<link rel="stylesheet" href="{% static 'my_app/css/styles.css' %}">
<script src="{% static 'my_app/js/app.js' %}"></script>
<img src="{% static 'my_app/images/logo.png' %}" alt="Logo">
```

## Configuration

### Essential Settings

```python
# settings.py

INSTALLED_APPS = [
    "django.contrib.staticfiles",
    # ...
]

# URL prefix for static files
STATIC_URL = "static/"

# Absolute path where collectstatic will gather files
STATIC_ROOT = "/var/www/example.com/static/"

# Additional directories to search for static files
STATICFILES_DIRS = [
    BASE_DIR / "static",
    "/var/www/static/",
]
```

### STATICFILES_FINDERS

Controls which finder backends locate static files:

```python
STATICFILES_FINDERS = [
    "django.contrib.staticfiles.finders.FileSystemFinder",       # Searches STATICFILES_DIRS
    "django.contrib.staticfiles.finders.AppDirectoriesFinder",   # Searches app/static/ dirs
]
```

### Settings Summary

| Setting | Purpose | Default |
|---|---|---|
| `STATIC_URL` | URL prefix for serving static files | `"static/"` |
| `STATIC_ROOT` | Filesystem path for collected static files | `None` |
| `STATICFILES_DIRS` | Additional directories to search | `[]` |
| `STATICFILES_FINDERS` | Finder backends to use | FileSystemFinder, AppDirectoriesFinder |
| `STORAGES["staticfiles"]` | Storage backend for collected files | `StaticFilesStorage` |

## Management Commands

### collectstatic

Collects all static files into `STATIC_ROOT`:

```bash
python manage.py collectstatic
```

| Option | Description |
|---|---|
| `--noinput` | No user prompts |
| `--ignore PATTERN` / `-i` | Ignore files matching pattern |
| `--dry-run` / `-n` | Preview without modifying filesystem |
| `--clear` / `-c` | Clear existing files before collecting |
| `--link` / `-l` | Create symbolic links instead of copying |
| `--no-post-process` | Skip post-processing (e.g., hashing) |

Customizing ignored patterns:

```python
from django.contrib.staticfiles.apps import StaticFilesConfig

class MyStaticFilesConfig(StaticFilesConfig):
    ignore_patterns = ["CVS", ".*", "*~", "*.map"]
```

### findstatic

Searches for static files using enabled finders:

```bash
python manage.py findstatic css/base.css
# Found 'css/base.css' here:
#   /home/project/core/static/css/base.css

python manage.py findstatic css/base.css --first  # Only first match
```

## Storage Classes

### StaticFilesStorage

Default storage. Subclass of `FileSystemStorage` using `STATIC_ROOT` and `STATIC_URL`.

### ManifestStaticFilesStorage

Appends an MD5 hash of file contents to filenames for cache-busting:

```
css/styles.css -> css/styles.55e7cbb9ba48.css
```

Configuration:

```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

Features:
- Enables far-future Expires headers for aggressive caching
- Automatically replaces referenced paths in CSS/JS files
- Creates a `staticfiles.json` manifest file

CSS transformation example:

```css
/* Original */
@import url("../admin/css/base.css");

/* After collectstatic processing */
@import url("../admin/css/base.27e20196a850.css");
```

| Attribute | Description |
|---|---|
| `manifest_hash` | Single hash for all manifest changes |
| `max_post_process_passes` | Max replacement passes (default: 5) |
| `manifest_strict` | Raise ValueError if file not in manifest (default: True) |

Custom manifest storage location:

```python
from django.conf import settings
from django.contrib.staticfiles.storage import (
    ManifestStaticFilesStorage,
    StaticFilesStorage,
)

class MyManifestStaticFilesStorage(ManifestStaticFilesStorage):
    def __init__(self, *args, **kwargs):
        manifest_storage = StaticFilesStorage(location=settings.BASE_DIR)
        super().__init__(*args, manifest_storage=manifest_storage, **kwargs)
```

### ManifestFilesMixin

Mixin class for building custom storage backends with MD5 hash appending behavior.

## Serving Static Files

### During Development

When `DEBUG=True` and `django.contrib.staticfiles` is installed, `runserver` automatically serves static files.

Manual URL configuration:

```python
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    # ... your URLconf ...
] + static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
```

### Serving User-Uploaded Files in Development

```python
urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

### Production Deployment

1. Set `STATIC_ROOT` to the target directory
2. Run `python manage.py collectstatic`
3. Configure your web server (Nginx, Apache) to serve the `STATIC_ROOT` directory

## Template Tags

### static

```django
{% load static %}
<img src="{% static 'images/my_img.png' %}" alt="My image">
```

### get_static_prefix

```django
{% load static %}
{% get_static_prefix as STATIC_PREFIX %}
<img src="{{ STATIC_PREFIX }}images/my_img.png" alt="My image">
```

### get_media_prefix

```django
{% load static %}
{% get_media_prefix as MEDIA_PREFIX %}
<a href="{{ MEDIA_PREFIX }}uploads/report.pdf">Download</a>
```

## Finders API

```python
from django.contrib.staticfiles import finders

result = finders.find("css/base.css")
searched_locations = finders.searched_locations
```

## Testing

Use `StaticLiveServerTestCase` to serve static files during tests without running `collectstatic`:

```python
from django.contrib.staticfiles.testing import StaticLiveServerTestCase

class MyLiveTest(StaticLiveServerTestCase):
    def test_page_loads(self):
        # Static assets served transparently
        pass
```

## Best Practices

- Always namespace static files under app-named subdirectories to prevent collisions
- Use `ManifestStaticFilesStorage` in production for cache-busting with hashed filenames
- Never serve static files through Django in production; use a dedicated web server or CDN
- Run `collectstatic` as part of your deployment pipeline
- Keep `STATICFILES_DIRS` for project-level static assets not tied to any specific app
- Use `--dry-run` with `collectstatic` to preview changes before deploying
- The `runserver` static file serving is inefficient and insecure; use only in development

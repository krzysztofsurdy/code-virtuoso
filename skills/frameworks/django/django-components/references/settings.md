# Django Settings

## Overview

Django settings are Python module-level variables that configure every aspect of a Django application. Settings are accessed via `django.conf.settings` and determined by the `DJANGO_SETTINGS_MODULE` environment variable.

## Core Concepts

### Accessing Settings

```python
from django.conf import settings

if settings.DEBUG:
    print("Debug mode is on")

# Never import individual settings directly
# WRONG: from django.conf.settings import DEBUG
```

### Settings Module

```bash
# Set via environment variable
export DJANGO_SETTINGS_MODULE=mysite.settings

# Or via command line
./manage.py runserver --settings=mysite.settings
```

### Standalone Configuration

```python
from django.conf import settings

settings.configure(DEBUG=True, DATABASES={...})

import django
django.setup()
```

### Checking Configuration State

```python
if not settings.configured:
    settings.configure(DEBUG=True)
```

### View Non-Default Settings

```bash
./manage.py diffsettings
```

## Core Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `DEBUG` | `False` | Enables debug mode. Never `True` in production |
| `SECRET_KEY` | `''` | Cryptographic signing key. Must be unique and secret |
| `ALLOWED_HOSTS` | `[]` | Host/domain names the site can serve |
| `ROOT_URLCONF` | - | Python path to root URLconf (e.g., `"mysite.urls"`) |
| `INSTALLED_APPS` | `[]` | List of enabled application paths |
| `MIDDLEWARE` | `None` | List of middleware classes |
| `WSGI_APPLICATION` | - | Path to WSGI application callable |
| `DEFAULT_AUTO_FIELD` | `'django.db.models.BigAutoField'` | Default primary key type |
| `APPEND_SLASH` | `True` | Append slash to URLs (requires `CommonMiddleware`) |

## Database Settings

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "mydatabase",
        "USER": "mydatabaseuser",
        "PASSWORD": "mypassword",
        "HOST": "127.0.0.1",
        "PORT": "5432",
        "CONN_MAX_AGE": 0,       # Connection lifetime in seconds (0 = close each request)
        "ATOMIC_REQUESTS": False, # Wrap each view in a transaction
        "AUTOCOMMIT": True,
        "TIME_ZONE": None,
        "OPTIONS": {},
        "TEST": {
            "NAME": None,        # Test database name override
            "CHARSET": None,
            "COLLATION": None,
            "MIRROR": None,      # Mirror another database in tests
            "DEPENDENCIES": [],
        },
    }
}
```

**Available Backends:**

| Backend | Engine |
|---------|--------|
| PostgreSQL | `django.db.backends.postgresql` |
| MySQL | `django.db.backends.mysql` |
| SQLite | `django.db.backends.sqlite3` |
| Oracle | `django.db.backends.oracle` |

## Template Settings

```python
TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.debug",
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]
```

## Static Files Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `STATIC_URL` | - | URL prefix for static files (e.g., `"/static/"`) |
| `STATIC_ROOT` | - | Absolute path for `collectstatic` output |
| `STATICFILES_DIRS` | `[]` | Additional directories for static files |
| `STATICFILES_FINDERS` | Built-in | How Django finds static files |
| `STATICFILES_STORAGE` | `StaticFilesStorage` | Storage backend for static files |

```python
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STATICFILES_DIRS = [BASE_DIR / "static"]
```

## Media Files Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `MEDIA_URL` | `''` | URL for user-uploaded files (e.g., `"/media/"`) |
| `MEDIA_ROOT` | `''` | Absolute filesystem path for uploads |

```python
MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"
```

## Authentication Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `AUTH_USER_MODEL` | `'auth.User'` | Custom user model |
| `LOGIN_URL` | `'/accounts/login/'` | Redirect URL for unauthenticated users |
| `LOGIN_REDIRECT_URL` | `'/accounts/profile/'` | Default redirect after login |
| `LOGOUT_REDIRECT_URL` | `None` | Redirect after logout |

### Password Validators

```python
AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
        "OPTIONS": {"min_length": 8},
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]
```

## Internationalization Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `LANGUAGE_CODE` | `'en-us'` | Default language |
| `TIME_ZONE` | `'UTC'` | Time zone (e.g., `'America/Chicago'`) |
| `USE_I18N` | `True` | Enable internationalization |
| `USE_L10N` | `True` | Enable localized formatting |
| `USE_TZ` | `True` | Use timezone-aware datetimes |
| `LANGUAGES` | All available | Available language choices |
| `LOCALE_PATHS` | `[]` | Directories for translation files |
| `FIRST_DAY_OF_WEEK` | `0` | 0=Sunday, 1=Monday |

```python
from django.utils.translation import gettext_lazy as _

LANGUAGES = [
    ("en", _("English")),
    ("de", _("German")),
    ("fr", _("French")),
]

LOCALE_PATHS = [BASE_DIR / "locale"]
```

## Email Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `EMAIL_BACKEND` | `'django.core.mail.backends.smtp.EmailBackend'` | Email sending backend |
| `EMAIL_HOST` | `'localhost'` | SMTP server host |
| `EMAIL_PORT` | `25` | SMTP server port |
| `EMAIL_HOST_USER` | `''` | SMTP username |
| `EMAIL_HOST_PASSWORD` | `''` | SMTP password |
| `EMAIL_USE_TLS` | `False` | Use TLS (port 587) |
| `EMAIL_USE_SSL` | `False` | Use implicit SSL (port 465) |
| `EMAIL_TIMEOUT` | `None` | Timeout for SMTP operations |
| `DEFAULT_FROM_EMAIL` | `'webmaster@localhost'` | Default "From" address |
| `SERVER_EMAIL` | `'root@localhost'` | "From" address for error emails |
| `EMAIL_SUBJECT_PREFIX` | `'[Django] '` | Subject prefix for admin emails |

**Available backends:**

```python
# Development
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"  # Print to console
EMAIL_BACKEND = "django.core.mail.backends.filebased.EmailBackend"  # Write to file
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"  # In-memory (testing)
EMAIL_BACKEND = "django.core.mail.backends.dummy.EmailBackend"  # Discard

# Production
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
```

## Cache Settings

```python
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379",
        "TIMEOUT": 300,
        "OPTIONS": {
            "MAX_ENTRIES": 300,
        },
    }
}
```

**Available backends:**

| Backend | Class |
|---------|-------|
| Local memory | `django.core.cache.backends.locmem.LocMemCache` |
| Database | `django.core.cache.backends.db.DatabaseCache` |
| File-based | `django.core.cache.backends.filebased.FileBasedCache` |
| Memcached | `django.core.cache.backends.memcached.PyMemcacheCache` |
| Redis | `django.core.cache.backends.redis.RedisCache` |
| Dummy | `django.core.cache.backends.dummy.DummyCache` |

## Security Settings

### CSRF Protection

| Setting | Default | Description |
|---------|---------|-------------|
| `CSRF_COOKIE_AGE` | `31449600` | CSRF cookie lifetime (~1 year) |
| `CSRF_COOKIE_HTTPONLY` | `False` | HTTPOnly flag on CSRF cookie |
| `CSRF_COOKIE_NAME` | `'csrftoken'` | CSRF cookie name |
| `CSRF_COOKIE_SECURE` | `False` | HTTPS-only CSRF cookie |
| `CSRF_COOKIE_SAMESITE` | `'Lax'` | SameSite attribute |
| `CSRF_TRUSTED_ORIGINS` | `[]` | Trusted origins for CSRF |
| `CSRF_USE_SESSIONS` | `False` | Store CSRF token in session |

### HTTPS/SSL Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `SECURE_SSL_REDIRECT` | `False` | Redirect HTTP to HTTPS |
| `SECURE_PROXY_SSL_HEADER` | `None` | Proxy SSL header tuple |
| `SECURE_HSTS_SECONDS` | `0` | HSTS max-age in seconds |
| `SECURE_HSTS_INCLUDE_SUBDOMAINS` | `False` | HSTS includeSubDomains |
| `SECURE_HSTS_PRELOAD` | `False` | HSTS preload flag |
| `SECURE_CONTENT_TYPE_NOSNIFF` | `True` | X-Content-Type-Options: nosniff |
| `SECURE_REFERRER_POLICY` | `'same-origin'` | Referrer-Policy header |
| `SECURE_CROSS_ORIGIN_OPENER_POLICY` | `'same-origin'` | COOP header |

### Content Security Policy (Django 6.0+)

```python
from django.utils.csp import CSP

SECURE_CSP = {
    "default-src": [CSP.SELF],
    "img-src": ["data:", CSP.SELF, "https://images.example.com"],
    "frame-src": [CSP.NONE],
}
```

## Session Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `SESSION_COOKIE_AGE` | `1209600` (2 weeks) | Session cookie lifetime |
| `SESSION_COOKIE_HTTPONLY` | `True` | HTTPOnly flag |
| `SESSION_COOKIE_NAME` | `'sessionid'` | Cookie name |
| `SESSION_COOKIE_SECURE` | `False` | HTTPS-only cookie |
| `SESSION_COOKIE_SAMESITE` | `'Lax'` | SameSite attribute |
| `SESSION_ENGINE` | `'...backends.db'` | Session backend |
| `SESSION_EXPIRE_AT_BROWSER_CLOSE` | `False` | Expire on browser close |
| `SESSION_SAVE_EVERY_REQUEST` | `False` | Save on every request |

## File Upload Settings

| Setting | Default | Description |
|---------|---------|-------------|
| `FILE_UPLOAD_MAX_MEMORY_SIZE` | `2621440` (2.5 MB) | Max upload before disk streaming |
| `DATA_UPLOAD_MAX_MEMORY_SIZE` | `2621440` (2.5 MB) | Max request body size |
| `DATA_UPLOAD_MAX_NUMBER_FIELDS` | `1000` | Max form fields |
| `DATA_UPLOAD_MAX_NUMBER_FILES` | `100` | Max file uploads |
| `FILE_UPLOAD_PERMISSIONS` | `0o644` | File permissions |

## Storage Settings (Django 4.2+)

```python
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.StaticFilesStorage",
    },
}
```

## Logging Settings

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {message}",
            "style": "{",
        },
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
        "file": {
            "level": "ERROR",
            "class": "logging.FileHandler",
            "filename": "/var/log/django/error.log",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
}
```

## Admin and Error Reporting

```python
ADMINS = [("Admin Name", "admin@example.com")]  # Notified on 500 errors
MANAGERS = [("Manager Name", "manager@example.com")]  # Notified on 404 errors
INTERNAL_IPS = ["127.0.0.1"]  # IPs that see debug info
IGNORABLE_404_URLS = []  # 404 patterns to ignore
```

## Splitting Settings

### Environment-Based Settings

```python
# settings/base.py
DEBUG = False
INSTALLED_APPS = [...]

# settings/development.py
from .base import *
DEBUG = True
DATABASES = {"default": {"ENGINE": "django.db.backends.sqlite3", "NAME": "db.sqlite3"}}

# settings/production.py
from .base import *
import os
SECRET_KEY = os.environ["SECRET_KEY"]
DATABASES = {"default": {"ENGINE": "django.db.backends.postgresql", ...}}
```

```bash
DJANGO_SETTINGS_MODULE=mysite.settings.production ./manage.py runserver
```

### Environment Variable Pattern

```python
import os

SECRET_KEY = os.environ["SECRET_KEY"]
DEBUG = os.environ.get("DEBUG", "False") == "True"
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "").split(",")

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ.get("DB_NAME", "mydb"),
        "USER": os.environ.get("DB_USER", "myuser"),
        "PASSWORD": os.environ.get("DB_PASSWORD", ""),
        "HOST": os.environ.get("DB_HOST", "localhost"),
        "PORT": os.environ.get("DB_PORT", "5432"),
    }
}
```

## Best Practices

- Never deploy with `DEBUG = True`
- Keep `SECRET_KEY` out of source control
- Use environment variables or secure files for sensitive settings
- Set `ALLOWED_HOSTS` explicitly when `DEBUG = False`
- Use `CONN_MAX_AGE` for persistent database connections in production
- Use cached template loader (automatic when `DEBUG = False`)
- Separate development and production settings
- Restrict file permissions on settings files
- Settings names must be ALL_UPPERCASE
- Never modify settings at runtime (`settings.DEBUG = True` is wrong)

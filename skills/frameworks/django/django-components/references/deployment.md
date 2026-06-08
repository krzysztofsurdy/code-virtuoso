# Django Deployment

## Contents

- [Overview](#overview)
- [WSGI deployment](#wsgi-deployment)
- [ASGI deployment](#asgi-deployment)
- [Deployment checklist](#deployment-checklist)
- [Static files in production](#static-files-in-production)
- [Media files](#media-files)
- [Error reporting](#error-reporting)
- [Nginx reject unknown hosts](#nginx-reject-unknown-hosts)
- [Production settings template](#production-settings-template)
- [Best practices](#best-practices)

## Overview

Django deploys under two standards: WSGI (synchronous) and ASGI (asynchronous). A production deployment needs an application server, a reverse proxy, static file serving, and hardened security settings. Never use the development server (`runserver`) in production.

## WSGI deployment

### wsgi.py configuration

Generated automatically by `startproject`:

```python
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_wsgi_application()
```

The `WSGI_APPLICATION` setting points to this callable (default: `myproject.wsgi.application`).

### Gunicorn

```bash
pip install gunicorn
gunicorn myproject.wsgi:application

# Common production options
gunicorn myproject.wsgi:application \
    --bind 0.0.0.0:8000 \
    --workers 4 \
    --timeout 120 \
    --access-logfile - \
    --error-logfile -
```

### uWSGI

```bash
pip install uwsgi
uwsgi --http :8000 --module myproject.wsgi

# With INI config
uwsgi --ini uwsgi.ini
```

```ini
# uwsgi.ini
[uwsgi]
module = myproject.wsgi:application
master = true
processes = 4
socket = /tmp/myproject.sock
chmod-socket = 660
vacuum = true
```

### Apache with mod_wsgi

```apache
WSGIScriptAlias / /path/to/myproject/wsgi.py
WSGIPythonHome /path/to/venv
WSGIPythonPath /path/to/myproject

<Directory /path/to/myproject>
    <Files wsgi.py>
        Require all granted
    </Files>
</Directory>
```

For multiple Django sites, use daemon mode:

```apache
WSGIDaemonProcess myproject python-home=/path/to/venv python-path=/path/to/myproject
WSGIProcessGroup myproject
```

### Adding WSGI middleware

```python
# wsgi.py
import os
from django.core.wsgi import get_wsgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_wsgi_application()

# Wrap with WSGI middleware
from some_wsgi_library import SomeMiddleware
application = SomeMiddleware(application)
```

## ASGI deployment

### asgi.py configuration

```python
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_asgi_application()
```

### Uvicorn

```bash
pip install uvicorn
uvicorn myproject.asgi:application

# Production options
uvicorn myproject.asgi:application \
    --host 0.0.0.0 \
    --port 8000 \
    --workers 4 \
    --log-level info
```

### Daphne

```bash
pip install daphne
daphne myproject.asgi:application

# With options
daphne -b 0.0.0.0 -p 8000 myproject.asgi:application
```

### Hypercorn

```bash
pip install hypercorn
hypercorn myproject.asgi:application

# With options
hypercorn myproject.asgi:application --bind 0.0.0.0:8000 --workers 4
```

### Adding ASGI middleware

```python
# asgi.py
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_asgi_application()

from some_asgi_library import AmazingMiddleware
application = AmazingMiddleware(application)
```

## Deployment checklist

Run Django's built-in deployment validator:

```bash
./manage.py check --deploy
./manage.py check --deploy --settings=myproject.settings.production
```

### Critical settings

#### SECRET_KEY

```python
import os

# From environment variable
SECRET_KEY = os.environ["SECRET_KEY"]

# Or from file
with open("/etc/secret_key.txt") as f:
    SECRET_KEY = f.read().strip()

# Key rotation
SECRET_KEY_FALLBACKS = [
    os.environ.get("OLD_SECRET_KEY", ""),
]
```

#### DEBUG

```python
DEBUG = False  # Must be False in production
```

#### ALLOWED_HOSTS

```python
ALLOWED_HOSTS = ["example.com", "www.example.com"]
```

### HTTPS settings

```python
# Redirect HTTP to HTTPS
SECURE_SSL_REDIRECT = True

# Secure cookies
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True

# HSTS (start small, increase gradually)
SECURE_HSTS_SECONDS = 3600        # 1 hour initially
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Proxy SSL header (if behind a reverse proxy)
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
```

### Security headers

```python
SECURE_CONTENT_TYPE_NOSNIFF = True    # X-Content-Type-Options: nosniff
SECURE_REFERRER_POLICY = "same-origin"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
```

### Database security

```python
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_NAME"],
        "USER": os.environ["DB_USER"],
        "PASSWORD": os.environ["DB_PASSWORD"],
        "HOST": os.environ["DB_HOST"],
        "PORT": os.environ.get("DB_PORT", "5432"),
        "CONN_MAX_AGE": 600,  # Persistent connections
    }
}
```

### Performance settings

```python
# Persistent database connections
DATABASES["default"]["CONN_MAX_AGE"] = 600

# Cached template loader (automatic when DEBUG=False)
# No configuration needed

# Cached sessions for better performance
SESSION_ENGINE = "django.contrib.sessions.backends.cached_db"
```

## Static files in production

### collectstatic

```bash
./manage.py collectstatic
./manage.py collectstatic --noinput  # For CI/CD
```

### Nginx configuration

```nginx
server {
    listen 80;
    server_name example.com;

    location /static/ {
        alias /var/www/example.com/static/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /var/www/example.com/media/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### WhiteNoise (serve static from app server)

```bash
pip install whitenoise
```

```python
# settings.py
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "whitenoise.middleware.WhiteNoiseMiddleware",  # Add after SecurityMiddleware
    # ...
]

STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}
```

### ManifestStaticFilesStorage

Appends content hash to filenames for cache busting:

```python
STORAGES = {
    "staticfiles": {
        "BACKEND": "django.contrib.staticfiles.storage.ManifestStaticFilesStorage",
    },
}
```

### CDN / cloud storage

```python
# Custom storage backend for S3, GCS, etc.
STORAGES = {
    "staticfiles": {
        "BACKEND": "myproject.storage.S3StaticStorage",
    },
}
```

Third-party packages: `django-storages` for S3, GCS, Azure Blob, etc.

## Media files

```python
MEDIA_URL = "/media/"
MEDIA_ROOT = "/var/www/example.com/media/"
```

- Configure the web server to never execute uploaded files.
- Back up uploads.
- Consider cloud storage if you need to scale.

## Error reporting

### Admin email notifications

```python
ADMINS = [("Admin", "admin@example.com")]
MANAGERS = [("Manager", "manager@example.com")]

EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
SERVER_EMAIL = "server@example.com"
```

### Logging

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "file": {
            "level": "ERROR",
            "class": "logging.FileHandler",
            "filename": "/var/log/django/error.log",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["file"],
            "level": "ERROR",
        },
    },
}
```

In production, consider a dedicated error tracking service such as Sentry.

### Custom error templates

Create in the root template directory:

- `404.html` - Page not found
- `500.html` - Server error
- `403.html` - Permission denied
- `400.html` - Bad request

## Nginx reject unknown hosts

```nginx
# Default server to reject unrecognized hosts
server {
    listen 80 default_server;
    return 444;
}
```

## Production settings template

```python
import os

# Security
DEBUG = False
SECRET_KEY = os.environ["SECRET_KEY"]
ALLOWED_HOSTS = os.environ.get("ALLOWED_HOSTS", "").split(",")

# HTTPS
SECURE_SSL_REDIRECT = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# Database
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.environ["DB_NAME"],
        "USER": os.environ["DB_USER"],
        "PASSWORD": os.environ["DB_PASSWORD"],
        "HOST": os.environ["DB_HOST"],
        "PORT": os.environ.get("DB_PORT", "5432"),
        "CONN_MAX_AGE": 600,
    }
}

# Static files
STATIC_URL = "/static/"
STATIC_ROOT = "/var/www/mysite/static/"
MEDIA_URL = "/media/"
MEDIA_ROOT = "/var/www/mysite/media/"

# Email
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.environ.get("EMAIL_HOST", "localhost")
DEFAULT_FROM_EMAIL = "noreply@example.com"
SERVER_EMAIL = "server@example.com"
ADMINS = [("Admin", "admin@example.com")]

# Cache
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": os.environ.get("REDIS_URL", "redis://127.0.0.1:6379"),
    }
}

# Sessions
SESSION_ENGINE = "django.contrib.sessions.backends.cached_db"
```

## Best practices

- Run `manage.py check --deploy` before every deployment.
- Never use `runserver` in production.
- Keep `SECRET_KEY` out of source control.
- Use environment variables for all sensitive configuration.
- Set `CONN_MAX_AGE` for persistent database connections.
- Use WhiteNoise or a dedicated server for static files.
- Enable HTTPS with HSTS headers.
- Configure logging and error reporting.
- Create custom error templates (404, 500, 403, 400).
- Configure the reverse proxy to reject unknown hosts.
- Back up the database and media files regularly.
- Use `collectstatic --noinput` in CI/CD pipelines.

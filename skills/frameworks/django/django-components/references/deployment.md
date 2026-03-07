# Django Deployment

## Overview

Django supports two deployment standards: WSGI (synchronous) and ASGI (asynchronous). Production deployment requires a proper application server, a reverse proxy, static file serving, and security hardening. The development server (`runserver`) is not suitable for production.

## WSGI Deployment

### wsgi.py Configuration

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

### Adding WSGI Middleware

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

## ASGI Deployment

### asgi.py Configuration

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

### Adding ASGI Middleware

```python
# asgi.py
import os
from django.core.asgi import get_asgi_application

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "myproject.settings")
application = get_asgi_application()

from some_asgi_library import AmazingMiddleware
application = AmazingMiddleware(application)
```

## Deployment Checklist

Run Django's built-in deployment validator:

```bash
./manage.py check --deploy
./manage.py check --deploy --settings=myproject.settings.production
```

### Critical Settings

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
DEBUG = False  # Always False in production
```

#### ALLOWED_HOSTS

```python
ALLOWED_HOSTS = ["example.com", "www.example.com"]
```

### HTTPS Settings

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

### Security Headers

```python
SECURE_CONTENT_TYPE_NOSNIFF = True    # X-Content-Type-Options: nosniff
SECURE_REFERRER_POLICY = "same-origin"
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
```

### Database Security

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

### Performance Settings

```python
# Persistent database connections
DATABASES["default"]["CONN_MAX_AGE"] = 600

# Cached template loader (automatic when DEBUG=False)
# No configuration needed

# Cached sessions for better performance
SESSION_ENGINE = "django.contrib.sessions.backends.cached_db"
```

## Static Files in Production

### collectstatic

```bash
./manage.py collectstatic
./manage.py collectstatic --noinput  # For CI/CD
```

### Nginx Configuration

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

### WhiteNoise (Serve Static from App Server)

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

### CDN / Cloud Storage

```python
# Custom storage backend for S3, GCS, etc.
STORAGES = {
    "staticfiles": {
        "BACKEND": "myproject.storage.S3StaticStorage",
    },
}
```

Third-party packages: `django-storages` for S3, GCS, Azure Blob, etc.

## Media Files

```python
MEDIA_URL = "/media/"
MEDIA_ROOT = "/var/www/example.com/media/"
```

- Configure web server to never execute uploaded files
- Implement backup strategy for uploads
- Consider cloud storage for scalability

## Error Reporting

### Admin Email Notifications

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

Consider dedicated error tracking services (Sentry) for production.

### Custom Error Templates

Create in the root template directory:

- `404.html` -- Page not found
- `500.html` -- Server error
- `403.html` -- Permission denied
- `400.html` -- Bad request

## Nginx Reject Unknown Hosts

```nginx
# Default server to reject unrecognized hosts
server {
    listen 80 default_server;
    return 444;
}
```

## Production Settings Template

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

## Best Practices

- Always run `manage.py check --deploy` before deploying
- Never use `runserver` in production
- Keep `SECRET_KEY` out of source control
- Use environment variables for all sensitive configuration
- Set `CONN_MAX_AGE` for persistent database connections
- Use WhiteNoise or a dedicated server for static files
- Configure HTTPS with HSTS headers
- Set up proper logging and error reporting
- Create custom error templates (404, 500, 403, 400)
- Configure your reverse proxy to reject unknown hosts
- Back up your database and media files regularly
- Use `collectstatic --noinput` in CI/CD pipelines

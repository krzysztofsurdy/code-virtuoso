# Django Logging

## Overview

Django uses and extends Python's built-in `logging` module. It provides a structured approach to system logging through four components: loggers, handlers, filters, and formatters. Logging is configured via the `LOGGING` setting using Python's `dictConfig` format and is initialized during Django's `setup()` function.

## Core Concepts

### The Four Components

#### Loggers

Entry points into the logging system. Named buckets that process messages based on severity level.

Log levels (ascending severity):
- `DEBUG` -- low-level system information for debugging
- `INFO` -- general system information
- `WARNING` -- minor problems that do not prevent operation
- `ERROR` -- major problems requiring attention
- `CRITICAL` -- critical problems that may crash the system

```python
import logging

logger = logging.getLogger("myapp")

logger.debug("Debug info: %s", variable)
logger.info("Processing started")
logger.warning("Disk space low")
logger.error("Failed to connect to database")
logger.critical("System is shutting down")
```

#### Handlers

Determine what happens with each log message. A logger can have multiple handlers with different levels.

Common handler classes:
- `logging.StreamHandler` -- output to console (sys.stderr)
- `logging.FileHandler` -- write to files
- `logging.handlers.RotatingFileHandler` -- rotating file output
- `django.utils.log.AdminEmailHandler` -- email ERROR/CRITICAL to admins

#### Filters

Provide additional control over which records are processed. Can also modify log records before emission.

Django built-in filters:
- `django.utils.log.RequireDebugTrue` -- passes records only when `DEBUG=True`
- `django.utils.log.RequireDebugFalse` -- passes records only when `DEBUG=False`
- `django.utils.log.CallbackFilter` -- custom filter using a callback function

#### Formatters

Render log records as text using Python format strings:

```python
"formatters": {
    "verbose": {
        "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
        "style": "{",
    },
    "simple": {
        "format": "{levelname} {message}",
        "style": "{",
    },
}
```

## Configuration

### LOGGING Setting

Django uses Python's `dictConfig` format. The `LOGGING` dict is merged with Django's default configuration.

#### Minimal Console Logging

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "WARNING",
    },
}
```

#### File Logging

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "file": {
            "level": "DEBUG",
            "class": "logging.FileHandler",
            "filename": "/path/to/django/debug.log",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["file"],
            "level": "DEBUG",
            "propagate": True,
        },
    },
}
```

#### Environment-Driven Log Level

```python
import os

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
        },
    },
    "root": {
        "handlers": ["console"],
        "level": "WARNING",
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "level": os.getenv("DJANGO_LOG_LEVEL", "INFO"),
            "propagate": False,
        },
    },
}
```

#### Production Configuration

```python
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {
            "format": "{levelname} {asctime} {module} {process:d} {thread:d} {message}",
            "style": "{",
        },
        "simple": {
            "format": "{levelname} {message}",
            "style": "{",
        },
    },
    "filters": {
        "special": {
            "()": "project.logging.SpecialFilter",
            "foo": "bar",
        },
        "require_debug_true": {
            "()": "django.utils.log.RequireDebugTrue",
        },
        "require_debug_false": {
            "()": "django.utils.log.RequireDebugFalse",
        },
    },
    "handlers": {
        "console": {
            "level": "INFO",
            "filters": ["require_debug_true"],
            "class": "logging.StreamHandler",
            "formatter": "simple",
        },
        "mail_admins": {
            "level": "ERROR",
            "filters": ["require_debug_false"],
            "class": "django.utils.log.AdminEmailHandler",
        },
        "file": {
            "level": "WARNING",
            "class": "logging.FileHandler",
            "filename": "/var/log/django/app.log",
            "formatter": "verbose",
        },
    },
    "loggers": {
        "django": {
            "handlers": ["console"],
            "propagate": True,
        },
        "django.request": {
            "handlers": ["mail_admins"],
            "level": "ERROR",
            "propagate": False,
        },
        "myproject.custom": {
            "handlers": ["console", "file", "mail_admins"],
            "level": "INFO",
            "filters": ["special"],
        },
    },
}
```

### Key Configuration Options

#### disable_existing_loggers

- Default: `True` (when key is missing)
- Set to `False` to preserve Django's default loggers and redefine only what you need

#### propagate

- `True` -- log records propagate up the logger hierarchy (e.g., `django.request` -> `django` -> root)
- `False` -- messages handled only by the current logger's handlers

### Custom Logging Configuration

```python
# Use a custom configuration callable
LOGGING_CONFIG = "myproject.logging.configure_logging"

# Disable automatic configuration entirely
LOGGING_CONFIG = None

import logging.config
logging.config.dictConfig({...})
```

## Django's Built-in Loggers

| Logger | Purpose |
|--------|---------|
| `django` | Catch-all logger for the Django framework |
| `django.request` | HTTP request processing; 5xx = ERROR, 4xx = WARNING |
| `django.server` | Messages from the development server (`runserver`) |
| `django.template` | Template rendering issues |
| `django.db.backends` | Database queries; logs every SQL statement at DEBUG level |
| `django.db.backends.schema` | Schema-altering SQL from migrations |
| `django.security.*` | Security-related issues (e.g., `SuspiciousOperation`) |

### django.request

Logs HTTP errors with extra context:

```python
# Automatic behavior:
# 5xx responses -> ERROR level with request as extra
# 4xx responses -> WARNING level with request as extra
```

### django.db.backends

Logs every SQL query at DEBUG level. Can generate significant output -- use with caution in production.

### django.security

Sub-loggers for specific security events:
- `django.security.csrf` -- CSRF failures
- `django.security.DisallowedHost` -- requests with disallowed Host header

## Django's Built-in Handlers

### AdminEmailHandler

Sends ERROR and CRITICAL log messages to site admins via email.

```python
"handlers": {
    "mail_admins": {
        "level": "ERROR",
        "class": "django.utils.log.AdminEmailHandler",
        "include_html": True,  # include HTML traceback in email
    },
}
```

Options:
- `include_html` -- include full HTML error page in email (security risk in production)
- `email_backend` -- override the email backend used for sending

## Django's Built-in Filters

### RequireDebugFalse

```python
"filters": {
    "require_debug_false": {
        "()": "django.utils.log.RequireDebugFalse",
    },
}
```

### RequireDebugTrue

```python
"filters": {
    "require_debug_true": {
        "()": "django.utils.log.RequireDebugTrue",
    },
}
```

### CallbackFilter

```python
"filters": {
    "custom": {
        "()": "django.utils.log.CallbackFilter",
        "callback": lambda record: record.levelno >= logging.WARNING,
    },
}
```

## Common Patterns

### Application Logger

```python
# myapp/views.py
import logging

logger = logging.getLogger(__name__)  # e.g., "myapp.views"

def my_view(request):
    logger.info("Processing request for user %s", request.user)
    try:
        result = expensive_operation()
    except Exception:
        logger.exception("Failed to process request")
        raise
    logger.debug("Result: %s", result)
    return render(request, "template.html", {"result": result})
```

### Structured Logging with Extra Data

```python
logger.info(
    "Order placed",
    extra={
        "order_id": order.id,
        "user_id": request.user.id,
        "total": str(order.total),
    },
)
```

### Development vs Production

```python
# Development: verbose console output
if DEBUG:
    LOGGING["root"]["level"] = "DEBUG"
    LOGGING["loggers"]["django.db.backends"] = {
        "handlers": ["console"],
        "level": "DEBUG",
        "propagate": False,
    }

# Production: file + email for errors
else:
    LOGGING["loggers"]["django.request"] = {
        "handlers": ["file", "mail_admins"],
        "level": "ERROR",
        "propagate": False,
    }
```

### Suppress Noisy Loggers

```python
LOGGING = {
    ...
    "loggers": {
        "django.db.backends": {
            "handlers": ["console"],
            "level": "WARNING",  # suppress DEBUG SQL queries
            "propagate": False,
        },
    },
}
```

## Best Practices

- Set `"disable_existing_loggers": False` to avoid silencing Django's default loggers
- Use `__name__` as the logger name for automatic hierarchy based on module path
- Use `logger.exception()` inside except blocks to automatically include traceback
- Use `RequireDebugFalse` filter on `AdminEmailHandler` to avoid email floods in development
- Do not enable `django.db.backends` at DEBUG level in production -- it logs every SQL query
- Use `%s` string formatting in log calls (not f-strings) for lazy evaluation
- Use `extra` dict for structured data rather than embedding it in the message string
- Keep sensitive data out of log messages (passwords, tokens, PII)
- Consider third-party logging services with proper access control instead of `AdminEmailHandler` with `include_html=True`
- Set log levels via environment variables for easy deployment configuration

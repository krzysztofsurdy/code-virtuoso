# Django Cache Framework

## Overview

Django's cache framework provides a flexible caching system that supports multiple backends and various levels of granularity -- from caching an entire site to caching individual values. It eliminates redundant computation by storing expensive calculations and serving them on subsequent requests.

## Core Concepts

### Cache Backends

Django supports several cache backends out of the box. Configure them via the `CACHES` setting in `settings.py`.

### Memcached

Production-ready, memory-based cache daemon. Supports `pymemcache` and `pylibmc` bindings.

```python
# PyMemcache (recommended)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyMemcacheCache",
        "LOCATION": "127.0.0.1:11211",
    }
}

# Unix socket
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyMemcacheCache",
        "LOCATION": "unix:/tmp/memcached.sock",
    }
}

# Distributed across multiple servers
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyMemcacheCache",
        "LOCATION": [
            "172.19.26.240:11211",
            "172.19.26.242:11211",
        ],
    }
}

# PyMemcache with connection pooling
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyMemcacheCache",
        "LOCATION": "127.0.0.1:11211",
        "OPTIONS": {
            "no_delay": True,
            "ignore_exc": True,
            "max_pool_size": 4,
            "use_pooling": True,
        },
    }
}

# PyLibMC with binary protocol
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.memcached.PyLibMCCache",
        "LOCATION": "127.0.0.1:11211",
        "OPTIONS": {
            "binary": True,
            "username": "user",
            "password": "pass",
            "behaviors": {"ketama": True},
        },
    }
}
```

### Redis

Built-in Redis backend (Django 4.0+). Supports replication mode.

```python
# Basic
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379",
    }
}

# With authentication
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": "redis://username:password@127.0.0.1:6379",
    }
}

# Replication mode (write to leader, read from replicas)
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": [
            "redis://127.0.0.1:6379",  # leader
            "redis://127.0.0.1:6378",  # read-replica
        ],
    }
}

# Custom database and connection pool
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.redis.RedisCache",
        "LOCATION": "redis://127.0.0.1:6379",
        "OPTIONS": {
            "db": "10",
            "pool_class": "redis.BlockingConnectionPool",
        },
    }
}
```

### Database Caching

```python
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.db.DatabaseCache",
        "LOCATION": "my_cache_table",
    }
}
```

Create the cache table:

```bash
python manage.py createcachetable
```

### Filesystem Caching

```python
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.filebased.FileBasedCache",
        "LOCATION": "/var/tmp/django_cache",
    }
}
```

### Local-Memory Caching

Per-process, thread-safe, uses LRU culling. Not suitable for production.

```python
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "unique-snowflake",
    }
}
```

### Dummy Cache (Development)

Implements the cache interface without caching anything.

```python
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.dummy.DummyCache",
    }
}
```

## Configuration

### Common Cache Arguments

```python
CACHES = {
    "default": {
        "BACKEND": "...",
        "LOCATION": "...",
        "TIMEOUT": 60,           # Default timeout in seconds (default: 300)
        "KEY_PREFIX": "site1",   # Prepended to all cache keys
        "VERSION": 1,            # Version number for cache keys
        "KEY_FUNCTION": "path.to.key_function",
        "OPTIONS": {
            "MAX_ENTRIES": 1000, # Max entries before culling (default: 300)
            "CULL_FREQUENCY": 3, # Fraction culled: 1/N (default: 3)
        },
    }
}
```

### Cache Key Transformation

Default key function produces keys in the format `prefix:version:key`:

```python
def make_key(key, key_prefix, version):
    return "%s:%s:%s" % (key_prefix, version, key)
```

Custom key function:

```python
CACHES = {
    "default": {
        "BACKEND": "...",
        "KEY_FUNCTION": "myapp.cache_utils.custom_make_key",
    }
}
```

## Per-Site Cache

Cache the entire site using middleware:

```python
MIDDLEWARE = [
    "django.middleware.cache.UpdateCacheMiddleware",     # must be first
    "django.middleware.common.CommonMiddleware",
    "django.middleware.cache.FetchFromCacheMiddleware",  # must be last
]

CACHE_MIDDLEWARE_ALIAS = "default"
CACHE_MIDDLEWARE_SECONDS = 600
CACHE_MIDDLEWARE_KEY_PREFIX = "site1"
```

Caches GET and HEAD responses with status 200. Sets `Expires` and `Cache-Control` headers.

## Per-View Cache

### Using the Decorator

```python
from django.views.decorators.cache import cache_page

@cache_page(60 * 15)  # 15 minutes
def my_view(request):
    ...

# With specific cache backend
@cache_page(60 * 15, cache="special_cache")
def my_view(request):
    ...

# With custom key prefix
@cache_page(60 * 15, key_prefix="site1")
def my_view(request):
    ...
```

### In URLconf

```python
from django.views.decorators.cache import cache_page

urlpatterns = [
    path("foo/<int:code>/", cache_page(60 * 15)(my_view)),
]
```

## Template Fragment Caching

```django
{% load cache %}

{# Basic fragment cache (500 seconds) #}
{% cache 500 sidebar %}
    .. sidebar content ..
{% endcache %}

{# Vary by user #}
{% cache 500 sidebar request.user.username %}
    .. user-specific sidebar ..
{% endcache %}

{# Use alternate cache backend #}
{% cache 300 local-thing ... using="localcache" %}
    .. content ..
{% endcache %}
```

### Invalidating Cached Fragments

```python
from django.core.cache import cache
from django.core.cache.utils import make_template_fragment_key

key = make_template_fragment_key("sidebar", [username])
cache.delete(key)
```

## Low-Level Cache API

### Accessing the Cache

```python
from django.core.cache import cache          # default cache
from django.core.cache import caches

specific_cache = caches["myalias"]
```

### Basic Operations

```python
# Set / Get
cache.set("my_key", "hello", 30)         # 30-second timeout
cache.get("my_key")                       # returns "hello"
cache.get("missing", "default_value")     # returns "default_value"

# Add (only if key does not exist)
cache.add("my_key", "new value")          # returns False if key exists

# Get or set
cache.get_or_set("key", "value", 100)     # returns existing or sets new
cache.get_or_set("key", datetime.now)     # callable as default

# Bulk operations
cache.set_many({"a": 1, "b": 2, "c": 3})
cache.get_many(["a", "b", "c"])           # returns {'a': 1, 'b': 2, 'c': 3}

# Delete
cache.delete("a")                         # returns True if existed
cache.delete_many(["a", "b", "c"])
cache.clear()                             # remove everything

# Touch (update expiration without changing value)
cache.touch("a", 10)

# Increment / Decrement
cache.set("num", 1)
cache.incr("num")                         # returns 2
cache.incr("num", 10)                     # returns 12
cache.decr("num")                         # returns 11
cache.decr("num", 5)                      # returns 6

# Close connection
cache.close()
```

### Cache Versioning

```python
cache.set("my_key", "value", version=2)
cache.get("my_key")                       # None (default version=1)
cache.get("my_key", version=2)            # "value"
cache.incr_version("my_key")              # bumps version 2 -> 3
```

### Async Support

All cache methods have async variants prefixed with `a`:

```python
await cache.aset("num", 1)
await cache.aget("num")
await cache.ahas_key("num")
await cache.adelete("key")
await cache.adelete_many(["a", "b"])
```

## Downstream Caches (HTTP Caching)

### Vary Headers

```python
from django.views.decorators.vary import vary_on_headers, vary_on_cookie

@vary_on_headers("User-Agent")
def my_view(request):
    ...

@vary_on_cookie
def my_view(request):
    ...
```

### Cache-Control Headers

```python
from django.views.decorators.cache import cache_control, never_cache

@cache_control(private=True)
def my_view(request):
    ...

@cache_control(max_age=3600)
def my_view(request):
    ...

@never_cache
def my_view(request):
    ...
```

Manual patching:

```python
from django.utils.cache import patch_cache_control, patch_vary_headers

def my_view(request):
    response = render(request, "template.html", context)
    patch_cache_control(response, private=True)
    patch_vary_headers(response, ["Cookie"])
    return response
```

## Common Patterns

### Database Cache Router

```python
class CacheRouter:
    def db_for_read(self, model, **hints):
        if model._meta.app_label == "django_cache":
            return "cache_replica"
        return None

    def db_for_write(self, model, **hints):
        if model._meta.app_label == "django_cache":
            return "cache_primary"
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        if app_label == "django_cache":
            return db == "cache_primary"
        return None
```

### Public/Private Cache Based on User

```python
from django.views.decorators.cache import patch_cache_control
from django.views.decorators.vary import vary_on_cookie

@vary_on_cookie
def list_entries(request):
    if request.user.is_anonymous:
        response = render_public()
        patch_cache_control(response, public=True)
    else:
        response = render_private(request.user)
        patch_cache_control(response, private=True)
    return response
```

## Best Practices

- Use Redis or Memcached in production; local-memory cache is per-process only
- Set `KEY_PREFIX` when sharing a cache instance across environments
- Use cache versioning to invalidate stale data without flushing the entire cache
- Place `UpdateCacheMiddleware` first and `FetchFromCacheMiddleware` last in middleware
- Use `@never_cache` for views that must always return fresh data
- Use `get_or_set()` to avoid race conditions in cache population
- Memcached keys must be under 250 characters and cannot contain whitespace
- Cache only picklable Python objects (the default serializer uses pickle)

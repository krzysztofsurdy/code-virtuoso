# Django Sessions

## Overview

Django's session framework provides full support for anonymous sessions, storing arbitrary data on a per-site-visitor basis. Sessions are implemented via middleware and support multiple storage backends including database, cache, file-based, and cookie-based storage. Session data is stored server-side by default, with only a session ID cookie sent to the browser.

## Core Concepts

### Enabling Sessions

```python
# settings.py (enabled by default in new projects)
INSTALLED_APPS = [
    'django.contrib.sessions',
]

MIDDLEWARE = [
    'django.contrib.sessions.middleware.SessionMiddleware',
]
```

Run `python manage.py migrate` to create the session database table.

### Disabling Sessions

Remove `SessionMiddleware` from `MIDDLEWARE` and `django.contrib.sessions` from `INSTALLED_APPS`.

## Session Backends

### Database-Backed (Default)

```python
SESSION_ENGINE = "django.contrib.sessions.backends.db"
```

- Stores sessions in the `django_session` database table
- Requires `django.contrib.sessions` in `INSTALLED_APPS`
- Most reliable, works with any database

### Cache-Backed

```python
# Cache-only (fastest, but data can be lost on eviction)
SESSION_ENGINE = "django.contrib.sessions.backends.cache"

# Write-through cache (recommended for production)
SESSION_ENGINE = "django.contrib.sessions.backends.cached_db"
```

- `cache`: Reads/writes only to cache. Data lost if cache fills up or restarts.
- `cached_db`: Writes to both database and cache. Reads from cache first, falls back to database.
- Never use local-memory cache backend (not multi-process safe).

```python
# Use a specific cache
SESSION_CACHE_ALIAS = "sessions"
```

### File-Based

```python
SESSION_ENGINE = "django.contrib.sessions.backends.file"
SESSION_FILE_PATH = "/var/lib/django/sessions"  # Defaults to tempfile.gettempdir()
```

Ensure the web server has read/write permissions on the directory.

### Cookie-Based

```python
SESSION_ENGINE = "django.contrib.sessions.backends.signed_cookies"
```

- Session data stored in signed cookies using `SECRET_KEY`
- Data is signed but NOT encrypted (readable by clients)
- Subject to 4096-byte cookie size limit
- Not invalidated server-side on logout
- Vulnerable to replay attacks

## Key Classes and Methods

### Using Sessions in Views

```python
def my_view(request):
    # Read
    value = request.session['key']
    value = request.session.get('key', 'default')

    # Write
    request.session['key'] = 'value'

    # Delete
    del request.session['key']

    # Check existence
    if 'key' in request.session:
        ...

    # Update multiple values
    request.session.update({'key1': 'val1', 'key2': 'val2'})

    # Pop with default
    value = request.session.pop('key', 'default')

    # Clear all data and delete cookie
    request.session.flush()

    # Check if empty
    request.session.is_empty()
```

### Expiration Control

```python
# Expire in 5 minutes
request.session.set_expiry(300)

# Expire at specific datetime
request.session.set_expiry(datetime_obj)

# Expire when browser closes
request.session.set_expiry(0)

# Use global SESSION_COOKIE_AGE setting
request.session.set_expiry(None)

# Query expiration
request.session.get_expiry_age()               # Seconds until expiration
request.session.get_expiry_date()              # Expiration datetime
request.session.get_expire_at_browser_close()  # Boolean
```

### Session Key Management

```python
# Get current session key
key = request.session.session_key

# Regenerate session key (retains data)
request.session.cycle_key()
```

### Async Methods

All session methods have async variants prefixed with `a`:

```python
value = await request.session.aget('key', 'default')
await request.session.aupdate({'key': 'value'})
await request.session.apop('key', 'default')
await request.session.aflush()
```

## Common Patterns

### Login/Logout with Sessions

```python
def login(request):
    member = Member.objects.get(username=request.POST["username"])
    if member.check_password(request.POST["password"]):
        request.session["member_id"] = member.id
        return HttpResponse("Logged in.")
    return HttpResponse("Invalid credentials.")

def logout(request):
    try:
        del request.session["member_id"]
    except KeyError:
        pass
    return HttpResponse("Logged out.")
```

### Preventing Duplicate Actions

```python
def post_comment(request, new_comment):
    if request.session.get("has_commented", False):
        return HttpResponse("You've already commented.")
    c = Comment(comment=new_comment)
    c.save()
    request.session["has_commented"] = True
    return HttpResponse("Thanks for your comment!")
```

### Test Cookie Support

```python
def login(request):
    if request.method == "POST":
        if request.session.test_cookie_worked():
            request.session.delete_test_cookie()
            return HttpResponse("Logged in.")
        else:
            return HttpResponse("Please enable cookies.")
    request.session.set_test_cookie()
    return render(request, "login.html")
```

### Sessions Outside Views

```python
from importlib import import_module
from django.conf import settings

SessionStore = import_module(settings.SESSION_ENGINE).SessionStore

# Create new session
s = SessionStore()
s["last_login"] = 1376587691
s.create()
key = s.session_key

# Load existing session
s = SessionStore(session_key=key)
print(s["last_login"])
```

### Database Session Model Access

```python
from django.contrib.sessions.models import Session

s = Session.objects.get(pk="session_key_here")
print(s.expire_date)
decoded = s.get_decoded()  # {'user_id': 42}
```

## Session Save Behavior

By default, Django saves sessions only when modified:

```python
# Session IS modified (auto-saved)
request.session["foo"] = "bar"
del request.session["foo"]
request.session["foo"] = {}

# Session is NOT modified (common gotcha)
request.session["foo"]["bar"] = "baz"   # Modifies nested dict, not session

# Fix: explicitly mark as modified
request.session.modified = True
```

Force save on every request:

```python
SESSION_SAVE_EVERY_REQUEST = True
```

Session is not saved if the response status code is 500.

## Session Serialization

```python
# Default: JSON serializer
SESSION_SERIALIZER = "django.contrib.sessions.serializers.JSONSerializer"
```

JSON limitations:
- Non-string keys converted to strings (`0` becomes `"0"`)
- Cannot serialize `datetime`, `Decimal`, or non-UTF8 bytes
- Tuples become lists after deserialization

Custom serializer:

```python
class CustomSerializer:
    def dumps(self, obj):
        return json.dumps(obj)

    def loads(self, data):
        return json.loads(data)

SESSION_SERIALIZER = "path.to.CustomSerializer"
```

Never use `pickle` for session serialization with the cookie backend.

## Configuration

### All Session Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `SESSION_ENGINE` | `"...backends.db"` | Session storage backend |
| `SESSION_CACHE_ALIAS` | `"default"` | Cache alias for cached sessions |
| `SESSION_COOKIE_AGE` | `1209600` (2 weeks) | Cookie lifetime in seconds |
| `SESSION_COOKIE_DOMAIN` | `None` | Cookie domain |
| `SESSION_COOKIE_HTTPONLY` | `True` | Block JavaScript access |
| `SESSION_COOKIE_NAME` | `"sessionid"` | Cookie name |
| `SESSION_COOKIE_PATH` | `"/"` | Cookie path |
| `SESSION_COOKIE_SAMESITE` | `"Lax"` | SameSite attribute |
| `SESSION_COOKIE_SECURE` | `False` | HTTPS-only cookie |
| `SESSION_EXPIRE_AT_BROWSER_CLOSE` | `False` | Expire on browser close |
| `SESSION_FILE_PATH` | `tempfile.gettempdir()` | File backend storage path |
| `SESSION_SAVE_EVERY_REQUEST` | `False` | Save on every request |
| `SESSION_SERIALIZER` | `"JSONSerializer"` | Data serializer class |

### Browser-Length vs Persistent Sessions

```python
# Persistent sessions (default) - survives browser close
SESSION_EXPIRE_AT_BROWSER_CLOSE = False

# Browser-length sessions - cleared on browser close
SESSION_EXPIRE_AT_BROWSER_CLOSE = True

# Per-session override
request.session.set_expiry(0)  # Expire at browser close
```

## Session Security

### Session Fixation Protection

- `django.contrib.auth.login()` calls `cycle_key()` automatically
- Do not set `SESSION_COOKIE_DOMAIN` too broadly
- Ensure untrusted subdomains cannot set cookies on parent domain

### Secure Cookie Settings

```python
# Production settings
SESSION_COOKIE_SECURE = True       # HTTPS only
SESSION_COOKIE_HTTPONLY = True      # No JavaScript access
SESSION_COOKIE_SAMESITE = "Lax"    # CSRF protection
```

### Cookie Backend Risks

- Data readable by the client (signed, not encrypted)
- Subject to replay attacks
- Sessions not invalidated on server-side logout
- 4096-byte size limit per cookie

## Clearing Expired Sessions

Database and file backends accumulate stale sessions. Clean them with:

```bash
python manage.py clearsessions
```

Run as a daily cron job. Cache backend handles expiration automatically; cookie backend stores data client-side.

## Extending Sessions

### Custom Database Session

```python
from django.contrib.sessions.backends.db import SessionStore as DBStore
from django.contrib.sessions.base_session import AbstractBaseSession
from django.db import models

class CustomSession(AbstractBaseSession):
    account_id = models.IntegerField(null=True, db_index=True)

    @classmethod
    def get_session_store_class(cls):
        return SessionStore

class SessionStore(DBStore):
    @classmethod
    def get_model_class(cls):
        return CustomSession

    def create_model_instance(self, data):
        obj = super().create_model_instance(data)
        try:
            account_id = int(data.get("_auth_user_id"))
        except (ValueError, TypeError):
            account_id = None
        obj.account_id = account_id
        return obj
```

## Best Practices

- Use `cached_db` backend for production (performance + reliability)
- Set `SESSION_COOKIE_SECURE = True` and `SESSION_COOKIE_HTTPONLY = True` in production
- Run `clearsessions` as a daily cron job for database/file backends
- Mark `request.session.modified = True` when modifying nested session data
- Use `request.session.flush()` for complete session destruction (not just `del`)
- Avoid storing large objects in sessions (keep data minimal)
- Use `cycle_key()` after authentication to prevent session fixation
- Prefer `SESSION_EXPIRE_AT_BROWSER_CLOSE = True` for sensitive applications
- Never use the cookie backend for sensitive data (data is readable)
- Use JSON serializer (default) for security; never use pickle

# Django Security

## Overview

Django provides built-in protection against most common web security vulnerabilities including CSRF, XSS, SQL injection, and clickjacking. The framework follows a secure-by-default philosophy where protections are enabled automatically, requiring explicit opt-out rather than opt-in. Django 6.0 also introduces Content Security Policy (CSP) support.

## CSRF Protection

### How It Works

Django's `CsrfViewMiddleware` protects against Cross-Site Request Forgery attacks:

1. Sets a CSRF cookie with a random secret (rotates on login)
2. Requires a `csrfmiddlewaretoken` hidden field in POST forms
3. Masks the token differently per response (BREACH attack protection)
4. Validates the `Origin` header against current host and `CSRF_TRUSTED_ORIGINS`
5. For HTTPS, validates the `Referer` header if `Origin` is absent

### Template Usage

```html
<form method="post">
    {% csrf_token %}
    {{ form.as_p }}
    <button type="submit">Submit</button>
</form>
```

### AJAX Requests

Include the CSRF token in the `X-CSRFToken` header:

```javascript
function getCookie(name) {
    let cookieValue = null;
    if (document.cookie && document.cookie !== '') {
        const cookies = document.cookie.split(';');
        for (let i = 0; i < cookies.length; i++) {
            const cookie = cookies[i].trim();
            if (cookie.substring(0, name.length + 1) === (name + '=')) {
                cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                break;
            }
        }
    }
    return cookieValue;
}

fetch('/api/endpoint/', {
    method: 'POST',
    headers: {
        'X-CSRFToken': getCookie('csrftoken'),
        'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
});
```

### CSRF Decorators

```python
from django.views.decorators.csrf import (
    csrf_exempt,
    csrf_protect,
    requires_csrf_token,
    ensure_csrf_cookie,
)

@csrf_exempt           # Disable CSRF protection (use sparingly)
def webhook_view(request):
    ...

@csrf_protect          # Force CSRF protection on a specific view
def protected_view(request):
    ...

@requires_csrf_token   # Ensure csrf_token tag works without middleware
def template_view(request):
    ...

@ensure_csrf_cookie    # Force CSRF cookie to be sent
def api_view(request):
    ...
```

### CSRF Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `CSRF_COOKIE_AGE` | `31449600` | Cookie lifetime in seconds |
| `CSRF_COOKIE_DOMAIN` | `None` | Cookie domain |
| `CSRF_COOKIE_HTTPONLY` | `False` | Prevent JavaScript access |
| `CSRF_COOKIE_NAME` | `"csrftoken"` | Cookie name |
| `CSRF_COOKIE_PATH` | `"/"` | Cookie path |
| `CSRF_COOKIE_SAMESITE` | `"Lax"` | SameSite attribute |
| `CSRF_COOKIE_SECURE` | `False` | HTTPS-only cookie |
| `CSRF_FAILURE_VIEW` | `"django.views.csrf.csrf_failure"` | View for 403 errors |
| `CSRF_HEADER_NAME` | `"HTTP_X_CSRFTOKEN"` | Header name for AJAX |
| `CSRF_TRUSTED_ORIGINS` | `[]` | Trusted cross-origin hosts |
| `CSRF_USE_SESSIONS` | `False` | Store token in session |

## XSS Prevention

Django templates auto-escape dangerous HTML characters by default:

```python
# These characters are escaped:
# < is converted to &lt;
# > is converted to &gt;
# ' is converted to &#x27;
# " is converted to &quot;
# & is converted to &amp;
```

### Potential Vulnerabilities

```html
<!-- VULNERABLE: Unquoted attribute -->
<style class={{ var }}>...</style>

<!-- SAFE: Quoted attribute -->
<style class="{{ var }}">...</style>
```

### Caution Points

- Avoid `mark_safe()` on user-controlled data
- Be careful with the `safe` template filter
- Disable `autoescape` only when absolutely necessary
- Validate HTML stored in the database before rendering
- Do not use `is_safe` on custom template tags unnecessarily

## SQL Injection Prevention

Django's ORM uses parameterized queries by default:

```python
# SAFE: ORM handles parameterization
User.objects.filter(username=user_input)
User.objects.get(pk=user_id)

# CAUTION: Raw queries require manual escaping
from django.db import connection

cursor = connection.cursor()
cursor.execute("SELECT * FROM users WHERE id = %s", [user_id])

# DANGEROUS: Never interpolate user input directly
# cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")  # DO NOT
```

### Methods Requiring Care

```python
# These accept raw SQL -- always use parameterized queries
queryset.extra(select={"field": "raw_sql"})
queryset.annotate(field=RawSQL("raw_sql", [params]))
queryset.raw("SELECT * FROM table WHERE id = %s", [param])
```

## Clickjacking Protection

### X-Frame-Options Middleware

```python
# settings.py
MIDDLEWARE = [
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

# Default: DENY (blocks all framing)
X_FRAME_OPTIONS = "DENY"

# Or allow same-origin framing
X_FRAME_OPTIONS = "SAMEORIGIN"
```

### Per-View Control

```python
from django.views.decorators.clickjacking import (
    xframe_options_deny,
    xframe_options_sameorigin,
    xframe_options_exempt,
)

@xframe_options_deny
def never_in_frame(request):
    ...

@xframe_options_sameorigin
def same_origin_frame(request):
    ...

@xframe_options_exempt
def embeddable_view(request):
    ...
```

## SSL/HTTPS Enforcement

### Security Middleware Settings

```python
# settings.py
MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",  # Place near top
    ...
]

# Redirect all HTTP to HTTPS
SECURE_SSL_REDIRECT = True

# HTTP Strict Transport Security
SECURE_HSTS_SECONDS = 31536000          # 1 year
SECURE_HSTS_INCLUDE_SUBDOMAINS = True   # Apply to all subdomains
SECURE_HSTS_PRELOAD = True              # Allow HSTS preload list inclusion

# Secure cookies
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True

# Behind a reverse proxy
SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
```

### All SecurityMiddleware Settings

| Setting | Default | Purpose |
|---------|---------|---------|
| `SECURE_HSTS_SECONDS` | `0` | HSTS header duration |
| `SECURE_HSTS_INCLUDE_SUBDOMAINS` | `False` | HSTS for subdomains |
| `SECURE_HSTS_PRELOAD` | `False` | HSTS preload list |
| `SECURE_SSL_REDIRECT` | `False` | HTTP to HTTPS redirect |
| `SECURE_SSL_HOST` | `None` | Redirect target host |
| `SECURE_REDIRECT_EXEMPT` | `[]` | URL patterns exempt from redirect |
| `SECURE_CONTENT_TYPE_NOSNIFF` | `True` | X-Content-Type-Options: nosniff |
| `SECURE_CROSS_ORIGIN_OPENER_POLICY` | `"same-origin"` | COOP header |
| `SECURE_REFERRER_POLICY` | `"same-origin"` | Referrer-Policy header |

## Host Header Validation

```python
# settings.py
ALLOWED_HOSTS = ['example.com', 'www.example.com']

# Wildcard subdomain
ALLOWED_HOSTS = ['.example.com']

# Always use request.get_host() instead of request.META['HTTP_HOST']
```

## Content Security Policy (Django 6.0+)

CSP mitigates XSS and content injection by controlling which resources browsers can load:

- Blocks inline scripts
- Restricts external script/resource loading
- Prevents unwanted framing
- Reports violations for monitoring

## Cryptographic Signing

### Basic Signing

```python
from django.core.signing import Signer

signer = Signer()
signed = signer.sign("My string")
# 'My string:v9G-nxfz3iQGTXrePqYPlGvH79WTcIgj1QIQSUODTW0'

original = signer.unsign(signed)
# 'My string'
```

### Timed Signatures

```python
from django.core.signing import TimestampSigner
from datetime import timedelta

signer = TimestampSigner()
signed = signer.sign("hello")

# Verify with expiration
signer.unsign(signed, max_age=3600)              # 1 hour
signer.unsign(signed, max_age=timedelta(hours=1))
# Raises SignatureExpired if too old
```

### Signing Complex Data

```python
from django.core import signing

# Sign a dictionary
token = signing.dumps({"user_id": 42, "action": "confirm_email"})

# Verify and retrieve
data = signing.loads(token, max_age=86400)  # Valid for 24 hours
```

### Salts for Context Separation

```python
signer = Signer(salt="email-confirmation")
signed = signer.sign("user@example.com")

# Different salt produces different signature
signer2 = Signer(salt="password-reset")
signer2.unsign(signed)  # Raises BadSignature
```

### Error Handling

```python
from django.core.signing import BadSignature, SignatureExpired

try:
    data = signing.loads(token, max_age=3600)
except SignatureExpired:
    # Token expired
    pass
except BadSignature:
    # Token tampered with
    pass
```

## Referrer Policy

```python
# Controls how much referrer information browsers send
SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"

# Options:
# "no-referrer"
# "no-referrer-when-downgrade"
# "origin"
# "origin-when-cross-origin"
# "same-origin"
# "strict-origin"
# "strict-origin-when-cross-origin"
# "unsafe-url"
```

## Configuration

### Production Security Checklist

```python
# settings.py - Production
DEBUG = False
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
ALLOWED_HOSTS = ["example.com", "www.example.com"]

# HTTPS
SECURE_SSL_REDIRECT = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# Cookies
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SESSION_COOKIE_HTTPONLY = True

# Headers
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_CROSS_ORIGIN_OPENER_POLICY = "same-origin"
SECURE_REFERRER_POLICY = "strict-origin-when-cross-origin"
X_FRAME_OPTIONS = "DENY"
```

### Django Security Check Command

```bash
python manage.py check --deploy
```

This command audits your settings and warns about common security misconfigurations.

## Common Patterns

### Serving User-Uploaded Content Safely

```python
# Use a completely separate domain (not a subdomain)
MEDIA_URL = "https://usercontent-example.com/"

# Whitelist allowed file extensions
# Validate uploads with ImageField (uses Pillow)
# Consider serving from CDN or cloud storage
```

### Protecting Secret Key

```python
# Never commit SECRET_KEY to version control
SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]

# Rotate keys with fallbacks
SECRET_KEY_FALLBACKS = ["old-secret-key"]
```

## Best Practices

- Never disable CSRF protection globally; use `@csrf_exempt` sparingly on specific views
- Always use `{% csrf_token %}` in POST forms
- Quote all template variable attributes to prevent XSS
- Use the ORM instead of raw SQL; parameterize when raw SQL is necessary
- Enable HTTPS and HSTS in production (start HSTS with small values, increase gradually)
- Set `ALLOWED_HOSTS` explicitly; never use `["*"]` in production
- Use `check --deploy` before every production deployment
- Serve user-uploaded files from a separate domain
- Keep `SECRET_KEY` out of version control
- Use `Signer` with salts to prevent token reuse across contexts
- Review OWASP Top 10 regularly

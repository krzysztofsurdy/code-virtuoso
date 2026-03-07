# Django Authentication

## Overview

Django's authentication system handles both authentication (verifying user identity) and authorization (determining what users can do). It provides user accounts, groups, permissions, cookie-based sessions, and a pluggable backend system. The system ships in `django.contrib.auth` and `django.contrib.contenttypes`.

## Core Concepts

### Installation

```python
# settings.py
INSTALLED_APPS = [
    'django.contrib.auth',
    'django.contrib.contenttypes',
]

MIDDLEWARE = [
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
]
```

Run `python manage.py migrate` to create auth database tables.

### The User Model

The default `User` model provides these fields:

| Field | Type | Description |
|-------|------|-------------|
| `username` | CharField(150) | Required. Alphanumeric, `_`, `@`, `+`, `.`, `-` |
| `password` | CharField | Hashed password with metadata |
| `email` | EmailField | Optional |
| `first_name` | CharField(150) | Optional |
| `last_name` | CharField(150) | Optional |
| `is_staff` | BooleanField | Admin site access |
| `is_active` | BooleanField | Soft-delete pattern |
| `is_superuser` | BooleanField | All permissions granted implicitly |
| `last_login` | DateTimeField | Last login timestamp |
| `date_joined` | DateTimeField | Account creation timestamp |
| `groups` | ManyToMany | Related groups |
| `user_permissions` | ManyToMany | Direct permissions |

## Key Classes and Methods

### Creating Users

```python
from django.contrib.auth.models import User

# Regular user
user = User.objects.create_user("john", "john@example.com", "password123")
user.last_name = "Doe"
user.save()

# Superuser
admin = User.objects.create_superuser("admin", "admin@example.com", "adminpass")

# Command line
# python manage.py createsuperuser --username=admin --email=admin@example.com
```

### Password Management

```python
user.set_password("new_password")
user.save()

user.check_password("raw_password")       # Returns bool
user.set_unusable_password()               # Mark as unusable
user.has_usable_password()                 # Returns bool
```

### Authenticating Users

```python
from django.contrib.auth import authenticate, login, logout

# Verify credentials
user = authenticate(request, username="john", password="secret")
if user is not None:
    login(request, user)     # Attach user to session
else:
    # Invalid credentials
    pass

# Log out
logout(request)
```

### User Methods

```python
user.get_username()
user.get_full_name()           # first_name + last_name
user.get_short_name()          # first_name
user.email_user(subject, message, from_email=None)
user.is_authenticated          # Always True for User instances
user.is_anonymous              # Always False for User instances
```

### AnonymousUser

Represents unauthenticated users on `request.user`:

```python
from django.contrib.auth.models import AnonymousUser

anon = AnonymousUser()
anon.id                  # None
anon.is_authenticated    # False
anon.is_anonymous        # True
anon.is_staff            # False
anon.is_superuser        # False
```

## Permissions and Authorization

### Default Permissions

Django creates four permissions per model automatically:
- `app_label.add_modelname`
- `app_label.change_modelname`
- `app_label.delete_modelname`
- `app_label.view_modelname`

### Checking Permissions

```python
user.has_perm('myapp.add_article')                      # Single
user.has_perm('myapp.change_article', obj=article)      # Object-level
user.has_perms(['myapp.view_article', 'myapp.add_article'])  # Multiple
user.has_module_perms('myapp')                           # Any perm in app

user.get_user_permissions()     # Direct permissions
user.get_group_permissions()    # From groups
user.get_all_permissions()      # Combined
```

### Custom Permissions

```python
class Task(models.Model):
    title = models.CharField(max_length=100)

    class Meta:
        permissions = [
            ("close_task", "Can close a task"),
            ("reopen_task", "Can reopen a task"),
        ]
```

### Programmatic Permission Creation

```python
from django.contrib.auth.models import Permission
from django.contrib.contenttypes.models import ContentType

content_type = ContentType.objects.get_for_model(BlogPost)
permission = Permission.objects.create(
    codename="can_publish",
    name="Can Publish Posts",
    content_type=content_type,
)
```

### Groups

```python
from django.contrib.auth.models import Group

editors = Group.objects.create(name="Editors")
editors.permissions.add(edit_perm, view_perm)

user.groups.add(editors)
user.groups.remove(editors)
user.groups.set([editors])
user.groups.clear()
```

### Permission Caching

```python
# Permissions are cached on the user object
user.has_perm("myapp.change_post")  # Cached

# After adding permissions, re-fetch user to clear cache
user = User.objects.get(pk=user.pk)
user.has_perm("myapp.change_post")  # Fresh lookup
```

## Login/Logout Views

### URL Configuration

```python
from django.urls import path, include

urlpatterns = [
    path("accounts/", include("django.contrib.auth.urls")),
]

# Provides:
# accounts/login/                    [name='login']
# accounts/logout/                   [name='logout']
# accounts/password_change/          [name='password_change']
# accounts/password_change/done/     [name='password_change_done']
# accounts/password_reset/           [name='password_reset']
# accounts/password_reset/done/      [name='password_reset_done']
# accounts/reset/<uidb64>/<token>/   [name='password_reset_confirm']
# accounts/reset/done/               [name='password_reset_complete']
```

### LoginView

```python
from django.contrib.auth.views import LoginView

path("login/", LoginView.as_view(template_name="myapp/login.html"))

# Key attributes: template_name, next_page, redirect_field_name,
# authentication_form, redirect_authenticated_user
```

### LogoutView

```python
from django.contrib.auth.views import LogoutView

path("logout/", LogoutView.as_view())
# Attributes: next_page, template_name, redirect_field_name
```

### Session Invalidation on Password Change

```python
from django.contrib.auth import update_session_auth_hash

def password_change(request):
    if request.method == "POST":
        form = PasswordChangeForm(user=request.user, data=request.POST)
        if form.is_valid():
            form.save()
            update_session_auth_hash(request, form.user)
```

## Decorators and Mixins

### login_required

```python
from django.contrib.auth.decorators import login_required

@login_required
def my_view(request):
    ...

@login_required(login_url="/accounts/login/")
def my_view(request):
    ...
```

### LoginRequiredMixin

```python
from django.contrib.auth.mixins import LoginRequiredMixin

class MyView(LoginRequiredMixin, View):
    login_url = "/login/"
    redirect_field_name = "redirect_to"
```

### permission_required

```python
from django.contrib.auth.decorators import permission_required

@permission_required("polls.add_choice")
def my_view(request):
    ...

@permission_required(["polls.view_choice", "polls.change_choice"])
def my_view(request):
    ...

@permission_required("polls.add_choice", raise_exception=True)
def my_view(request):
    ...
```

### PermissionRequiredMixin

```python
from django.contrib.auth.mixins import PermissionRequiredMixin

class MyView(PermissionRequiredMixin, View):
    permission_required = "polls.add_choice"
    # Or multiple:
    permission_required = ["polls.view_choice", "polls.change_choice"]
```

### user_passes_test

```python
from django.contrib.auth.decorators import user_passes_test

def email_check(user):
    return user.email.endswith("@example.com")

@user_passes_test(email_check)
def my_view(request):
    ...
```

### UserPassesTestMixin

```python
from django.contrib.auth.mixins import UserPassesTestMixin

class MyView(UserPassesTestMixin, View):
    def test_func(self):
        return self.request.user.email.endswith("@example.com")
```

### login_not_required

```python
from django.contrib.auth.decorators import login_not_required

@login_not_required
def public_view(request):
    # Works without auth when LoginRequiredMiddleware is active
    ...
```

## Password Management

### Password Hashers

```python
PASSWORD_HASHERS = [
    "django.contrib.auth.hashers.PBKDF2PasswordHasher",      # Default
    "django.contrib.auth.hashers.PBKDF2SHA1PasswordHasher",
    "django.contrib.auth.hashers.Argon2PasswordHasher",       # pip install django[argon2]
    "django.contrib.auth.hashers.BCryptSHA256PasswordHasher", # pip install django[bcrypt]
    "django.contrib.auth.hashers.ScryptPasswordHasher",
]
```

### Custom Hasher (Increase Work Factor)

```python
from django.contrib.auth.hashers import PBKDF2PasswordHasher

class MyPBKDF2PasswordHasher(PBKDF2PasswordHasher):
    iterations = PBKDF2PasswordHasher.iterations * 100
```

### Password Validation

```python
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
     "OPTIONS": {"min_length": 9}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]
```

### Manual Password Functions

```python
from django.contrib.auth.hashers import make_password, check_password, is_password_usable

hashed = make_password("my_password")
check_password("my_password", hashed)    # True
is_password_usable(hashed)               # True
```

### Custom Validator

```python
from django.core.exceptions import ValidationError

class MinimumLengthValidator:
    def __init__(self, min_length=8):
        self.min_length = min_length

    def validate(self, password, user=None):
        if len(password) < self.min_length:
            raise ValidationError(
                "Password must contain at least %(min_length)d characters.",
                code="password_too_short",
                params={"min_length": self.min_length},
            )

    def get_help_text(self):
        return f"Your password must contain at least {self.min_length} characters."
```

## Custom User Models

### AbstractUser (Recommended)

```python
# models.py
from django.contrib.auth.models import AbstractUser

class CustomUser(AbstractUser):
    pass

# settings.py
AUTH_USER_MODEL = "myapp.CustomUser"
```

### AbstractBaseUser (Full Control)

```python
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin

class MyUserManager(BaseUserManager):
    def create_user(self, email, password=None):
        if not email:
            raise ValueError("Email is required")
        user = self.model(email=self.normalize_email(email))
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None):
        user = self.create_user(email, password)
        user.is_admin = True
        user.save(using=self._db)
        return user

class MyUser(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)
    is_active = models.BooleanField(default=True)
    is_admin = models.BooleanField(default=False)

    objects = MyUserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = []

    @property
    def is_staff(self):
        return self.is_admin
```

### Referencing the User Model

```python
from django.conf import settings
from django.contrib.auth import get_user_model

# In models (ForeignKey)
class Article(models.Model):
    author = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

# At runtime
User = get_user_model()
```

## Authentication Backends

### Custom Backend

```python
from django.contrib.auth.backends import BaseBackend

class MyBackend(BaseBackend):
    def authenticate(self, request, username=None, password=None):
        try:
            user = User.objects.get(username=username)
            if user.check_password(password):
                return user
        except User.DoesNotExist:
            return None

    def get_user(self, user_id):
        try:
            return User.objects.get(pk=user_id)
        except User.DoesNotExist:
            return None
```

```python
# settings.py
AUTHENTICATION_BACKENDS = [
    "myapp.backends.MyBackend",
    "django.contrib.auth.backends.ModelBackend",
]
```

## Auth Signals

```python
from django.contrib.auth.signals import user_logged_in, user_logged_out, user_login_failed

@receiver(user_logged_in)
def on_login(sender, request, user, **kwargs):
    print(f"{user.username} logged in")

@receiver(user_login_failed)
def on_login_failed(sender, credentials, request, **kwargs):
    print(f"Login failed for {credentials.get('username')}")
```

## Common Patterns

### Authentication in Templates

```html
{% if user.is_authenticated %}
    <p>Welcome, {{ user.username }}.</p>
{% else %}
    <p><a href="{% url 'login' %}">Log in</a></p>
{% endif %}

{% if perms.myapp.add_article %}
    <a href="{% url 'article_create' %}">New Article</a>
{% endif %}
```

### Profile Model (Extending User)

```python
class Profile(models.Model):
    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to="avatars/", blank=True)
```

## Built-in Forms

| Form | Purpose |
|------|---------|
| `AuthenticationForm` | Login form with username/password |
| `UserCreationForm` | User registration with password validation |
| `BaseUserCreationForm` | Base for custom user creation forms |
| `PasswordChangeForm` | Change password (requires old password) |
| `SetPasswordForm` | Set password without old password |
| `PasswordResetForm` | Request password reset email |
| `AdminPasswordChangeForm` | Admin password change |

## Best Practices

- Always use `AUTH_USER_MODEL` setting and `get_user_model()` in reusable apps
- Set `AUTH_USER_MODEL` before running the first migration
- Use `AbstractUser` for simple customizations, `AbstractBaseUser` for full control
- Never store raw passwords; use `set_password()` and `check_password()`
- Use Argon2 or bcrypt for stronger password hashing in production
- Call `update_session_auth_hash()` after programmatic password changes
- Combine `@login_required` with `@permission_required(raise_exception=True)` to avoid redirect loops
- Use `PermissionsMixin` with `AbstractBaseUser` for Django's permission framework
- Re-fetch user objects after permission changes to clear the cache

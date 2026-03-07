# Django Messages Framework

## Overview

The Django messages framework provides cookie- and session-based messaging for temporarily storing messages in one request and retrieving them in subsequent requests. Each message is tagged with a priority level (debug, info, success, warning, error) and can carry additional custom tags for styling and categorization.

## Core Concepts

### Enabling Messages

The default Django project configuration includes everything needed:

```python
# settings.py
INSTALLED_APPS = [
    "django.contrib.messages",
    # ...
]

MIDDLEWARE = [
    "django.contrib.sessions.middleware.SessionMiddleware",  # Must come before MessageMiddleware
    "django.contrib.messages.middleware.MessageMiddleware",
    # ...
]

TEMPLATES = [{
    "OPTIONS": {
        "context_processors": [
            "django.contrib.messages.context_processors.messages",
            # ...
        ],
    },
}]
```

### Message Levels

| Constant | Value | Purpose | Default Tag |
|---|---|---|---|
| `DEBUG` | 10 | Development-related messages | `debug` |
| `INFO` | 20 | Informational messages | `info` |
| `SUCCESS` | 25 | Action completed successfully | `success` |
| `WARNING` | 30 | Potential problem warnings | `warning` |
| `ERROR` | 40 | Action failed or error occurred | `error` |

## Adding Messages

### Shortcut Methods

```python
from django.contrib import messages

def my_view(request):
    messages.debug(request, "%s SQL statements were executed." % count)
    messages.info(request, "Three credits remain in your account.")
    messages.success(request, "Profile details updated.")
    messages.warning(request, "Your account expires in three days.")
    messages.error(request, "Document deleted.")
```

### Generic add_message

```python
messages.add_message(request, messages.INFO, "Hello world.")
```

### Extra Tags

```python
messages.add_message(request, messages.INFO, "Over 9000!", extra_tags="dragonball")
messages.error(request, "Email box full", extra_tags="email")
```

### Failing Silently

Use `fail_silently=True` when the messages framework might not be available:

```python
messages.info(request, "Hello world.", fail_silently=True)
```

### Custom Message Levels

```python
CRITICAL = 50

def my_view(request):
    messages.add_message(request, CRITICAL, "A serious error occurred.")
```

Configure tags for custom levels:

```python
from django.contrib.messages import constants as messages

MESSAGE_TAGS = {
    messages.INFO: "",
    50: "critical",
}
```

## Displaying Messages in Templates

### Basic Display

```django
{% if messages %}
<ul class="messages">
    {% for message in messages %}
    <li{% if message.tags %} class="{{ message.tags }}"{% endif %}>
        {{ message }}
    </li>
    {% endfor %}
</ul>
{% endif %}
```

### With Level Checking

```django
{% if messages %}
<ul class="messages">
    {% for message in messages %}
    <li{% if message.tags %} class="{{ message.tags }}"{% endif %}>
        {% if message.level == DEFAULT_MESSAGE_LEVELS.ERROR %}Important: {% endif %}
        {{ message }}
    </li>
    {% endfor %}
</ul>
{% endif %}
```

### Message Object Attributes

| Attribute | Description |
|---|---|
| `message` | The actual text of the message |
| `level` | Integer describing message type (10, 20, 25, 30, 40) |
| `tags` | Combined string of extra_tags and level_tag, space-separated |
| `extra_tags` | Custom tags passed via extra_tags parameter |
| `level_tag` | String representation of level (e.g., "error", "success") |

## Displaying Messages Outside Templates

```python
from django.contrib.messages import get_messages

storage = get_messages(request)
for message in storage:
    do_something_with(message)
```

For JSON responses:

```python
def api_view(request):
    # Process request...
    storage = get_messages(request)
    response_messages = [
        {"level": msg.level_tag, "text": str(msg)}
        for msg in storage
    ]
    return JsonResponse({"messages": response_messages})
```

## Storage Backends

### Available Backends

| Backend | Description |
|---|---|
| `FallbackStorage` | Default. Uses CookieStorage first, falls back to SessionStorage |
| `CookieStorage` | Stores in signed cookie. Drops old messages if cookie > 2048 bytes |
| `SessionStorage` | Stores in request session. Requires `django.contrib.sessions` |

### Configuring Storage

```python
MESSAGE_STORAGE = "django.contrib.messages.storage.cookie.CookieStorage"
```

## Managing Message Levels Per Request

```python
from django.contrib import messages

# Set minimum level to DEBUG (show all messages)
messages.set_level(request, messages.DEBUG)

# Set minimum level to WARNING (ignore DEBUG, INFO, SUCCESS)
messages.set_level(request, messages.WARNING)
messages.success(request, "Profile updated.")  # Ignored
messages.warning(request, "Account expiring.")  # Recorded

# Reset to default level
messages.set_level(request, None)

# Get current level
current_level = messages.get_level(request)
```

## Class-Based Views Integration

### SuccessMessageMixin

```python
from django.contrib.messages.views import SuccessMessageMixin
from django.views.generic.edit import CreateView
from myapp.models import Author

class AuthorCreateView(SuccessMessageMixin, CreateView):
    model = Author
    success_url = "/success/"
    success_message = "%(name)s was created successfully"
```

### Custom Success Message with Computed Fields

```python
class ComplicatedCreateView(SuccessMessageMixin, CreateView):
    model = ComplicatedModel
    success_url = "/success/"
    success_message = "%(calculated_field)s was created successfully"

    def get_success_message(self, cleaned_data):
        return self.success_message % dict(
            cleaned_data,
            calculated_field=self.object.calculated_field,
        )
```

## Message Expiration

Messages are cleared when the storage instance is iterated during response processing.

Prevent auto-clearing:

```python
storage = messages.get_messages(request)
for message in storage:
    do_something_with(message)
storage.used = False  # Messages will persist to next request
```

## Testing Messages

```python
from django.contrib.messages.test import MessagesTestMixin
from django.test import TestCase

class MyTest(MessagesTestMixin, TestCase):
    def test_message_on_create(self):
        response = self.client.post("/create/", data={"name": "Test"})
        self.assertMessages(response, [
            messages.Message(messages.SUCCESS, "Test was created successfully"),
        ])
```

## Configuration

| Setting | Description | Default |
|---|---|---|
| `MESSAGE_LEVEL` | Minimum recorded message level | `INFO` (20) |
| `MESSAGE_STORAGE` | Storage backend class path | `FallbackStorage` |
| `MESSAGE_TAGS` | Dict mapping levels to tag strings | Default level names |

## Best Practices

- Always iterate over messages in templates even when expecting only one, to ensure the storage is cleared
- Use `FallbackStorage` (the default) for the best balance of performance and reliability
- Use `extra_tags` to add CSS classes for styling (e.g., Bootstrap alert classes)
- Set `MESSAGE_LEVEL` to `DEBUG` only during development
- Use `SuccessMessageMixin` with class-based views instead of manually adding success messages
- Place `SessionMiddleware` before `MessageMiddleware` in the `MIDDLEWARE` list
- Use `MessagesTestMixin` in tests to assert messages are generated correctly
- Be aware that messages are undefined when the same client makes parallel requests
- Use `fail_silently=True` in reusable apps where the messages framework may not be installed

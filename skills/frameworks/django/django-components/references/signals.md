# Django Signals

## Overview

Django's signal dispatcher enables decoupled applications to notify each other when actions occur. Signals allow senders to notify a set of receivers that some action has taken place, without requiring direct coupling between the two. Django provides a set of built-in signals for model lifecycle events, HTTP requests, migrations, and testing.

## Core Concepts

### Signal Dispatcher

The signal system consists of three parts: the signal itself, senders that emit the signal, and receivers that listen for it. Receivers are callback functions connected to a signal.

### Receiver Functions

A receiver is any Python function or method that accepts `sender` and `**kwargs`:

```python
def my_callback(sender, **kwargs):
    print("Signal received!")
```

Async receivers are also supported:

```python
async def my_callback(sender, **kwargs):
    await asyncio.sleep(1)
    print("Async signal received!")
```

## Connecting Receivers

### Using the @receiver Decorator

```python
from django.dispatch import receiver
from django.db.models.signals import pre_save
from myapp.models import MyModel

@receiver(pre_save, sender=MyModel)
def my_handler(sender, **kwargs):
    ...
```

Connect to multiple signals:

```python
@receiver([pre_save, post_save], sender=MyModel)
def my_handler(sender, **kwargs):
    ...
```

### Using Signal.connect()

```python
Signal.connect(receiver, sender=None, weak=True, dispatch_uid=None)
```

```python
from django.core.signals import request_finished

request_finished.connect(my_callback)
```

Parameters:
- `receiver` -- callback function
- `sender` -- receive signals only from this sender (optional)
- `weak` -- store as weak reference (default: `True`); set to `False` for local functions
- `dispatch_uid` -- unique identifier to prevent duplicate registration

### Where to Connect Signals

Define handlers in a `signals` submodule and connect them in `AppConfig.ready()`:

```python
# myapp/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from myapp.models import MyModel

@receiver(post_save, sender=MyModel)
def my_handler(sender, **kwargs):
    ...

# myapp/apps.py
from django.apps import AppConfig

class MyAppConfig(AppConfig):
    def ready(self):
        from . import signals  # noqa: F401
```

### Connecting to Specific Senders

```python
@receiver(pre_save, sender=MyModel)
def my_handler(sender, **kwargs):
    # Only called when MyModel instances are saved
    ...
```

### Preventing Duplicate Signals

```python
request_finished.connect(my_callback, dispatch_uid="my_unique_identifier")
```

## Defining Custom Signals

```python
import django.dispatch

pizza_done = django.dispatch.Signal()
```

## Sending Signals

### Signal.send()

Does not catch exceptions raised by receivers. If a receiver raises an error, remaining receivers may not be notified.

```python
class PizzaStore:
    def send_pizza(self, toppings, size):
        pizza_done.send(sender=self.__class__, toppings=toppings, size=size)
```

Returns a list of `(receiver, response)` tuples.

### Signal.send_robust()

Catches all `Exception` subclasses. Guarantees all receivers are notified.

```python
responses = pizza_done.send_robust(sender=self.__class__, toppings=toppings, size=size)
for receiver, response in responses:
    if isinstance(response, Exception):
        # Handle error; traceback available via response.__traceback__
        pass
```

### Async Variants

```python
await pizza_done.asend(sender=self.__class__, toppings=toppings, size=size)
await pizza_done.asend_robust(sender=self.__class__, toppings=toppings, size=size)
```

Sync receivers called via `asend()` are automatically wrapped with `sync_to_async()`. Async receivers called via `send()` are wrapped with `async_to_sync()`.

## Disconnecting Signals

```python
Signal.disconnect(receiver=None, sender=None, dispatch_uid=None)
```

Returns `True` if a receiver was disconnected, `False` otherwise.

## Built-in Signals

### Model Signals

#### pre_init / post_init

Sent at the beginning and end of a model's `__init__()` method.

```python
from django.db.models.signals import pre_init, post_init
```

`pre_init` arguments: `sender`, `args`, `kwargs`
`post_init` arguments: `sender`, `instance`

#### pre_save

Sent at the beginning of a model's `save()` method.

```python
from django.db.models.signals import pre_save

@receiver(pre_save, sender=MyModel)
def before_save(sender, instance, raw, using, update_fields, **kwargs):
    ...
```

Arguments: `sender`, `instance`, `raw`, `using`, `update_fields`

#### post_save

Sent at the end of a model's `save()` method.

```python
from django.db.models.signals import post_save

@receiver(post_save, sender=MyModel)
def after_save(sender, instance, created, raw, using, update_fields, **kwargs):
    if created:
        # New record was created
        ...
```

Arguments: `sender`, `instance`, `created` (bool), `raw`, `using`, `update_fields`

#### pre_delete / post_delete

Sent at the beginning and end of a model's `delete()` method.

```python
from django.db.models.signals import pre_delete, post_delete

@receiver(pre_delete, sender=MyModel)
def before_delete(sender, instance, using, origin, **kwargs):
    ...
```

Arguments: `sender`, `instance`, `using`, `origin` (the Model or QuerySet that initiated deletion)

#### m2m_changed

Sent when a `ManyToManyField` is modified.

```python
from django.db.models.signals import m2m_changed

@receiver(m2m_changed, sender=Pizza.toppings.through)
def toppings_changed(sender, instance, action, reverse, model, pk_set, using, **kwargs):
    if action == "post_add":
        ...
```

Arguments:
- `sender` -- intermediate model class (the `.through` table)
- `instance` -- the instance whose M2M relation changed
- `action` -- one of: `"pre_add"`, `"post_add"`, `"pre_remove"`, `"post_remove"`, `"pre_clear"`, `"post_clear"`
- `reverse` -- which side of the relation was updated
- `model` -- class of objects added/removed/cleared
- `pk_set` -- set of primary keys (or `None` for clear actions)
- `using` -- database alias

#### class_prepared

Sent when a model class is fully defined and registered. Cannot be connected in `AppConfig.ready()` -- use `AppConfig.__init__()` instead.

### Management Signals

#### pre_migrate / post_migrate

Sent before and after the `migrate` command runs.

```python
from django.db.models.signals import post_migrate

class MyAppConfig(AppConfig):
    def ready(self):
        post_migrate.connect(my_callback, sender=self)
```

Arguments: `sender` (AppConfig), `app_config`, `verbosity`, `interactive`, `stdout`, `using`, `plan`, `apps`

### Request/Response Signals

#### request_started

Sent when Django begins processing an HTTP request.

Arguments: `sender` (handler class, e.g. `WsgiHandler`), `environ`

#### request_finished

Sent when Django finishes delivering a response.

Arguments: `sender` (handler class)

#### got_request_exception

Sent when Django encounters an exception during request processing.

Arguments: `sender` (`None`), `request` (HttpRequest)

### Test Signals

#### setting_changed

Sent when a setting changes via `override_settings()` or `TestCase.settings()`. Fired twice: once when applied, once when restored.

```python
from django.core.signals import setting_changed

@receiver(setting_changed)
def on_setting_changed(sender, setting, value, enter, **kwargs):
    if setting == "MY_SETTING" and enter:
        # Setting was just applied
        ...
```

Arguments: `sender`, `setting` (name), `value`, `enter` (bool: True=applied, False=restored)

#### template_rendered

Sent when the test system renders a template (not during normal operation).

Arguments: `sender` (Template), `template`, `context`

### Database Signals

#### connection_created

Sent when a database connection is first established.

Arguments: `sender` (database wrapper class), `connection`

### Task Signals (Django 6.0)

#### task_enqueued / task_started / task_finished

Sent during task lifecycle when using Django's task framework.

Arguments: `sender` (backend class), `task_result` (TaskResult instance)

## Common Patterns

### Create Profile on User Registration

```python
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from myapp.models import Profile

@receiver(post_save, sender=User)
def create_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)
```

### Audit Logging

```python
@receiver(post_save)
def log_save(sender, instance, created, **kwargs):
    action = "created" if created else "updated"
    AuditLog.objects.create(
        model=sender.__name__,
        object_id=instance.pk,
        action=action,
    )
```

## Best Practices

- Always include `**kwargs` in receiver signatures for forward compatibility
- Use `dispatch_uid` when receiver registration code may run multiple times (e.g., in tests)
- Prefer direct function calls over signals when sender and receiver are in the same app
- Define signal handlers in a dedicated `signals.py` module
- Connect signals in `AppConfig.ready()` to ensure they are registered once
- Use `send_robust()` when all receivers must be notified regardless of errors
- Avoid database queries in `pre_init`/`post_init` receivers due to performance impact during queryset iteration
- Override model methods must call `super()` for signals to fire
- Use lazy model references (`'app_label.Model'`) to avoid circular imports

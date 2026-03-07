# Django Tasks Framework

## Overview

The Django Tasks framework (new in Django 6.0) provides a built-in way to define and enqueue background work that runs outside the request-response cycle. Tasks are units of work with metadata, stored in a queue and executed by external worker processes. For older Django versions, the `django-tasks` backport package is available on PyPI.

## Core Concepts

### Architecture

| Component | Role |
|-----------|------|
| Task | Decorated function with metadata, ready to be enqueued |
| Task Backend | Queue store that holds enqueued tasks |
| Worker | External process that claims, executes, and records results |
| TaskResult | Tracking object with unique ID, status, and return value |

### Task Lifecycle

1. Task function is decorated with `@task`
2. Task is enqueued via `.enqueue()` -- returns a `TaskResult`
3. Worker claims the task from the backend
4. Worker executes the function
5. Result (success or error) is saved back to the backend

## Key Classes and Methods

### Defining Tasks

Use the `@task` decorator on module-level functions. By convention, define tasks in `tasks.py`:

```python
from django.core.mail import send_mail
from django.tasks import task

@task
def email_users(emails, subject, message):
    return send_mail(
        subject=subject,
        message=message,
        from_email=None,
        recipient_list=emails,
    )
```

### Task Customization

```python
@task(priority=2, queue_name="emails")
def email_users(emails, subject, message):
    return send_mail(
        subject=subject,
        message=message,
        from_email=None,
        recipient_list=emails,
    )
```

### Task Context

Access execution metadata with `takes_context=True`:

```python
import logging
from django.tasks import task

logger = logging.getLogger(__name__)

@task(takes_context=True)
def email_users(context, emails, subject, message):
    logger.debug(
        f"Attempt {context.attempt} to send user email. "
        f"Task result id: {context.task_result.id}."
    )
    return send_mail(
        subject=subject,
        message=message,
        from_email=None,
        recipient_list=emails,
    )
```

Context properties:
- `context.attempt` -- current attempt number
- `context.task_result` -- associated `TaskResult` instance

### Modifying Task Parameters

Create modified task instances without changing the original:

```python
email_users.priority          # 0
email_users.using(priority=10).priority  # 10
```

## Enqueueing Tasks

### Basic Enqueueing

```python
result = email_users.enqueue(
    emails=["user@example.com"],
    subject="You have a message",
    message="Hello there!",
)
```

### Async Enqueueing

```python
result = await email_users.aenqueue(
    emails=["user@example.com"],
    subject="You have a message",
    message="Hello there!",
)
```

### Serialization Requirements

All task arguments and return values must be JSON-serializable:

```python
# FAILS -- datetime not JSON serializable
process_data.enqueue(datetime.now())

# FAILS -- tuples become lists after JSON round-trip
@task()
def double_dictionary(key):
    return {key: key * 2}

result = double_dictionary.enqueue((1, 2, 3))
# TypeError: unhashable type: 'list'
```

Convert complex objects before passing them to tasks.

### Enqueueing with Transactions

Use `transaction.on_commit()` to prevent workers from executing before data is committed:

```python
from functools import partial
from django.db import transaction

@task
def my_task(thing_num):
    Thing.objects.get(num=thing_num)

with transaction.atomic():
    Thing.objects.create(num=1)
    transaction.on_commit(partial(my_task.enqueue, thing_num=1))
```

## Task Results

### Retrieving Results

```python
# By task function
result = email_users.get_result(result_id)

# By backend
from django.tasks import default_task_backend
result = default_task_backend.get_result(result_id)

# Async variant
result = await email_users.aget_result(result_id)
```

### Refreshing Stale Results

```python
result.status    # RUNNING
result.refresh()  # or await result.arefresh()
result.status    # SUCCESSFUL
```

### Accessing Return Values

```python
result.status        # SUCCESSFUL
result.return_value  # 42

# Raises ValueError if task has not finished
result.status        # RUNNING
result.return_value  # ValueError: Task has not finished yet
```

### Error Handling

```python
result.errors[0].exception_class  # <class 'ValueError'>
result.errors[0].traceback        # String traceback for debugging
```

`TaskError` attributes:
- `exception_class` -- the exception type (no values included)
- `traceback` -- string representation of the full traceback

## Configuration

### Task Backends

Configure backends using the `TASKS` setting:

```python
TASKS = {
    "default": {
        "BACKEND": "backend.path",
    }
}
```

### Built-in Backends

#### ImmediateBackend (Default)

Executes tasks immediately (synchronously). Useful for development:

```python
TASKS = {
    "default": {
        "BACKEND": "django.tasks.backends.immediate.ImmediateBackend",
    }
}
```

Does not support `get_result()` (raises `NotImplementedError`).

#### DummyBackend

Stores results without executing tasks. For testing:

```python
TASKS = {
    "default": {
        "BACKEND": "django.tasks.backends.dummy.DummyBackend",
    }
}
```

```python
from django.tasks import default_task_backend

my_task.enqueue()
len(default_task_backend.results)  # 1
default_task_backend.clear()       # Clear stored results
```

#### Third-party Backends

For production, use backends with durable queue implementations. Check the Django community ecosystem page and Django Packages for available options.

### Retrieving Backends

```python
from django.tasks import task_backends, default_task_backend

task_backends["default"]    # The default backend
task_backends["reserve"]    # Another configured backend
default_task_backend        # Quick access to default
```

### Custom Backend Requirements

Custom backends must:
- Inherit from `BaseTaskBackend`
- Implement `BaseTaskBackend.enqueue()`
- Async variants are prefixed with `a` (e.g., `aenqueue()`, `aget_result()`)

## Common Patterns

### Email Processing

```python
@task(queue_name="emails", priority=5)
def send_welcome_email(user_id):
    user = User.objects.get(id=user_id)
    send_mail(
        subject="Welcome!",
        message=f"Hello {user.first_name}",
        from_email=None,
        recipient_list=[user.email],
    )
```

### Data Processing Pipeline

```python
@task
def process_upload(upload_id):
    upload = Upload.objects.get(id=upload_id)
    data = parse_file(upload.file.path)
    upload.processed_data = data
    upload.status = "completed"
    upload.save()
```

### Safe Enqueueing After Object Creation

```python
from functools import partial
from django.db import transaction

def create_order(request):
    with transaction.atomic():
        order = Order.objects.create(user=request.user, total=100)
        transaction.on_commit(
            partial(send_order_confirmation.enqueue, order_id=order.id)
        )
    return JsonResponse({"order_id": order.id})
```

## Comparison with Celery

| Feature | Django Tasks | Celery |
|---------|-------------|--------|
| Decorator | `@task` | `@shared_task` / `@app.task` |
| Installation | Built-in (Django 6.0+) | Separate package |
| Broker | Backend-dependent | Redis, RabbitMQ, etc. |
| Worker | External (backend-provided) | `celery worker` |
| Serialization | JSON only | JSON, pickle, msgpack, etc. |
| Scheduling | Backend-dependent | Celery Beat |
| Result backend | Built into task backend | Separate result backend config |
| API complexity | Minimal | Feature-rich |
| Retry | Via `context.attempt` | Built-in retry with backoff |
| Chaining/Groups | Not built-in | Canvas (chain, group, chord) |

## Best Practices

- Define tasks in `tasks.py` by convention for discoverability
- Keep task arguments JSON-serializable (pass IDs, not model instances)
- Use `transaction.on_commit()` when enqueueing tasks that depend on uncommitted data
- Use the `DummyBackend` in tests to verify tasks are enqueued without executing them
- Use `ImmediateBackend` during development before infrastructure is available
- Check `context.attempt` for retry-aware logic when using backends that support retries
- Use `priority` and `queue_name` to separate workloads (e.g., emails vs data processing)
- Handle `ValueError` when accessing `return_value` on unfinished tasks
- Use third-party backends with durable queues for production deployments

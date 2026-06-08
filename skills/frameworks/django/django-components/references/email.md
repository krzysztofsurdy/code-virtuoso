# Django Email

## Contents

- [Overview](#overview)
- [Core concepts](#core-concepts)
- [Key classes and methods](#key-classes-and-methods)
- [Email backends](#email-backends)
- [Common patterns](#common-patterns)
- [Configuration](#configuration)
- [Best practices](#best-practices)

## Overview

Django's email framework is built on Python's `smtplib`. It has simple functions for common cases, an `EmailMessage` class for anything more involved, and pluggable backends for different delivery mechanisms. It rejects header injection attempts.

## Core concepts

### Quick sending functions

#### send_mail()

Sends a single email:

```python
from django.core.mail import send_mail

send_mail(
    subject="Subject here",
    message="Plain text body.",
    from_email="from@example.com",
    recipient_list=["to@example.com"],
    fail_silently=False,
)
```

Parameters:
- `subject` - email subject line
- `message` - plain text body
- `from_email` - sender address (uses `DEFAULT_FROM_EMAIL` if `None`)
- `recipient_list` - list of recipient addresses
- `fail_silently` - suppress `smtplib.SMTPException` on failure
- `auth_user` / `auth_password` - override `EMAIL_HOST_USER` / `EMAIL_HOST_PASSWORD`
- `connection` - email backend instance to use
- `html_message` - HTML body (creates multipart/alternative email)

Returns: number of successfully delivered messages (0 or 1).

#### send_mass_mail()

Send multiple emails efficiently using a single SMTP connection:

```python
from django.core.mail import send_mass_mail

message1 = ("Subject 1", "Body 1", "from@example.com", ["to1@example.com"])
message2 = ("Subject 2", "Body 2", "from@example.com", ["to2@example.com"])

send_mass_mail((message1, message2), fail_silently=False)
```

Key difference from `send_mail()`: opens one connection for all messages instead of one per call.

#### mail_admins()

Send email to site admins (defined in `ADMINS` setting):

```python
from django.core.mail import mail_admins

mail_admins("Subject", "Message content", html_message="<p>HTML content</p>")
```

Prefixes subject with `EMAIL_SUBJECT_PREFIX` (default: `"[Django] "`). Uses `SERVER_EMAIL` as sender.

#### mail_managers()

Same as `mail_admins()` but sends to `MANAGERS` setting.

## Key classes and methods

### EmailMessage

Email class with support for attachments, CC, BCC, and custom headers:

```python
from django.core.mail import EmailMessage

email = EmailMessage(
    subject="Hello",
    body="Body text",
    from_email="from@example.com",
    to=["to@example.com"],
    cc=["cc@example.com"],
    bcc=["bcc@example.com"],
    reply_to=["reply@example.com"],
    headers={"Message-ID": "custom-id"},
)
email.send()
```

Parameters:
- `subject` - subject line
- `body` - plain text body
- `from_email` - sender (supports `"Name <email>"` format)
- `to` - list of recipients
- `cc` - list of CC recipients
- `bcc` - list of BCC recipients
- `reply_to` - list of Reply-To addresses
- `attachments` - list of attachments
- `headers` - dict of extra email headers
- `connection` - email backend instance

Methods:
- `send(fail_silently=False)` - send the email; returns 1 on success, 0 on failure
- `message()` - build and return the Python `email.message.EmailMessage` object
- `recipients()` - list of all recipients (to + cc + bcc)
- `attach(filename, content, mimetype)` - add an attachment
- `attach_file(path, mimetype=None)` - attach a file from the filesystem

### EmailMultiAlternatives

For sending multipart emails with both plain text and HTML:

```python
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string

text_content = render_to_string("emails/welcome.txt", context)
html_content = render_to_string("emails/welcome.html", context)

msg = EmailMultiAlternatives(
    subject="Welcome",
    body=text_content,
    from_email="from@example.com",
    to=["to@example.com"],
    headers={"List-Unsubscribe": "<mailto:unsub@example.com>"},
)
msg.attach_alternative(html_content, "text/html")
msg.send()
```

Methods:
- `attach_alternative(content, mimetype)` - add an alternative content representation
- `body_contains(text)` - check if text exists in body and all text/* alternatives

### Attachments

```python
# Attach content directly
email.attach("report.pdf", pdf_bytes, "application/pdf")

# Attach from filesystem
email.attach_file("/path/to/document.pdf")

# Inline image with Content-ID
import email.utils
from email.message import MIMEPart

cid = email.utils.make_msgid()
inline_image = MIMEPart()
inline_image.set_content(
    image_bytes,
    maintype="image",
    subtype="png",
    disposition="inline",
    cid=cid,
)
msg.attach(inline_image)
msg.attach_alternative(f'<img src="cid:{cid[1:-1]}">', "text/html")
```

### Changing default content type

```python
msg = EmailMessage(subject, html_content, from_email, [to])
msg.content_subtype = "html"  # body is now text/html instead of text/plain
msg.send()
```

## Email backends

### SMTP backend (default)

```python
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
```

### Console backend

Writes emails to stdout. Useful in development.

```python
EMAIL_BACKEND = "django.core.mail.backends.console.EmailBackend"
```

### File backend

Writes each email to a separate file.

```python
EMAIL_BACKEND = "django.core.mail.backends.filebased.EmailBackend"
EMAIL_FILE_PATH = "/tmp/app-messages"
```

### In-memory backend

Stores messages in `django.core.mail.outbox`. Used by the test runner.

```python
EMAIL_BACKEND = "django.core.mail.backends.locmem.EmailBackend"
```

Access sent emails in tests:

```python
from django.core import mail

self.assertEqual(len(mail.outbox), 1)
self.assertEqual(mail.outbox[0].subject, "Expected Subject")
```

### Dummy backend

Silently discards all emails.

```python
EMAIL_BACKEND = "django.core.mail.backends.dummy.EmailBackend"
```

### Custom backend

```python
from django.core.mail.backends.base import BaseEmailBackend

class CustomEmailBackend(BaseEmailBackend):
    def open(self):
        pass

    def close(self):
        pass

    def send_messages(self, email_messages):
        num_sent = 0
        for message in email_messages:
            # Custom delivery logic
            num_sent += 1
        return num_sent
```

## Common patterns

### Sending multiple emails efficiently

```python
from django.core import mail

# Using context manager (single connection)
with mail.get_connection() as connection:
    mail.EmailMessage("Subject 1", "Body", "from@example.com",
                      ["to1@example.com"], connection=connection).send()
    mail.EmailMessage("Subject 2", "Body", "from@example.com",
                      ["to2@example.com"], connection=connection).send()

# Using send_messages()
connection = mail.get_connection()
messages = [
    mail.EmailMessage("Subject 1", "Body", "from@example.com", ["to1@example.com"]),
    mail.EmailMessage("Subject 2", "Body", "from@example.com", ["to2@example.com"]),
]
connection.send_messages(messages)
```

### Using a different backend per connection

```python
from django.core.mail import get_connection

connection = get_connection(
    backend="django.core.mail.backends.smtp.EmailBackend",
    fail_silently=False,
)
```

### Safe user-submitted email

```python
from django.core.mail import send_mail
from django.http import HttpResponse, HttpResponseRedirect

def contact(request):
    subject = request.POST.get("subject", "")
    message = request.POST.get("message", "")
    from_email = request.POST.get("from_email", "")

    if subject and message and from_email:
        try:
            send_mail(subject, message, from_email, ["admin@example.com"])
        except ValueError:
            return HttpResponse("Invalid header found.")
        return HttpResponseRedirect("/contact/thanks/")
    return HttpResponse("All fields are required.")
```

## Configuration

| Setting | Purpose | Default |
|---------|---------|---------|
| `EMAIL_BACKEND` | Backend class path | `django.core.mail.backends.smtp.EmailBackend` |
| `EMAIL_HOST` | SMTP server hostname | `localhost` |
| `EMAIL_PORT` | SMTP server port | `25` |
| `EMAIL_HOST_USER` | SMTP username | `""` |
| `EMAIL_HOST_PASSWORD` | SMTP password | `""` |
| `EMAIL_USE_TLS` | Use TLS (port 587) | `False` |
| `EMAIL_USE_SSL` | Use SSL (port 465) | `False` |
| `EMAIL_TIMEOUT` | Socket timeout (seconds) | `None` |
| `EMAIL_SSL_KEYFILE` | SSL key file path | `None` |
| `EMAIL_SSL_CERTFILE` | SSL certificate file path | `None` |
| `DEFAULT_FROM_EMAIL` | Default sender address | `webmaster@localhost` |
| `SERVER_EMAIL` | Sender for error emails | `root@localhost` |
| `DEFAULT_CHARSET` | Email character encoding | `utf-8` |
| `EMAIL_FILE_PATH` | File backend directory | `None` |
| `EMAIL_SUBJECT_PREFIX` | Prefix for admin emails | `[Django]` |

### Development configuration

```python
# Using aiosmtpd for local testing
# pip install aiosmtpd
# python -m aiosmtpd -n -l localhost:8025

EMAIL_HOST = "localhost"
EMAIL_PORT = 8025
```

## Best practices

- Use `send_mass_mail()` or connection reuse when sending multiple emails.
- Set `DEFAULT_FROM_EMAIL` in settings instead of hardcoding sender addresses.
- Use `EmailMultiAlternatives` for HTML emails and always include a plain text fallback.
- Use the in-memory backend (`locmem`) in tests and read `django.core.mail.outbox`.
- Never set both `EMAIL_USE_TLS` and `EMAIL_USE_SSL` to `True`. They are mutually exclusive.
- Use templates (`render_to_string`) for email content instead of inline strings.
- Django prevents header injection by rejecting newlines in the subject, sender, and recipients.
- Use `fail_silently=True` only when email delivery is non-critical.
- For production workloads, consider sending email through a task queue (Celery, Django tasks).

# Symfony Mime Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Creating email messages](#creating-email-messages)
- [Email class methods](#email-class-methods)
- [Twig integration](#twig-integration)
- [Creating raw email messages](#creating-raw-email-messages)
- [Message parts](#message-parts)
- [Serializing messages](#serializing-messages)
- [MIME types utilities](#mime-types-utilities)
- [MIME structure reference](#mime-structure-reference)
- [Integration with other components](#integration-with-other-components)

## Overview

The Mime component provides APIs for creating and manipulating MIME (Multipurpose Internet Mail Extensions) messages used in email systems. It extends email format to support non-ASCII characters in headers, multi-part message bodies, and non-text attachments. Two APIs are available: a high-level `Email` class for common email features and a low-level `Message` class for complete control.

## Installation

Install the Mime component:

```bash
composer require symfony/mime
```

## Creating email messages

Use the chainable `Email` class to create emails with common features:

```php
use Symfony\Component\Mime\Email;

$email = (new Email())
    ->from('sender@example.com')
    ->to('recipient@example.com')
    ->cc('cc@example.com')
    ->bcc('bcc@example.com')
    ->replyTo('reply@example.com')
    ->priority(Email::PRIORITY_HIGH)
    ->subject('Email Subject')
    ->text('Plain text content')
    ->html('<h1>HTML content</h1>')
;
```

**Priority Constants:**
- `Email::PRIORITY_HIGHEST` (numeric: 1)
- `Email::PRIORITY_HIGH` (numeric: 2)
- `Email::PRIORITY_NORMAL` (numeric: 3)
- `Email::PRIORITY_LOW` (numeric: 4)
- `Email::PRIORITY_LOWEST` (numeric: 5)

## Email class methods

### Recipients and headers

- `from(string|Address|AddressInterface)` - Set sender address
- `to(string|Address|AddressInterface|array)` - Add recipient
- `cc(string|Address|AddressInterface|array)` - Add carbon copy recipient
- `bcc(string|Address|AddressInterface|array)` - Add blind carbon copy recipient
- `replyTo(string|Address|AddressInterface|array)` - Set reply-to address
- `getHeaders()` - Get headers object for custom headers

### Content

- `text(string $body)` - Set plain text body
- `html(string $body)` - Set HTML body
- `textTemplate(string $template)` - Set plain text template (requires Twig bridge)
- `htmlTemplate(string $template)` - Set HTML template (requires Twig bridge)

### Message properties

- `subject(string $subject)` - Set email subject
- `priority(int $priority)` - Set priority level
- `date(\DateTimeImmutable $date)` - Set sending date
- `sender(string|Address|AddressInterface)` - Set explicit sender (different from From header)

### Attachments and embedded content

- `attach(string|SplFileInfo|DataPart)` - Attach file
- `attachFromPath(string $path, string $name = null, string $contentType = null)` - Attach file from path
- `embed(string|SplFileInfo|DataPart)` - Embed file inline (returns Content-ID for referencing)

## Twig integration

### Setup for standalone usage

Render templates outside of Symfony framework using `BodyRenderer`:

```php
use Symfony\Bridge\Twig\Mime\BodyRenderer;
use Twig\Environment;
use Twig\Loader\FilesystemLoader;

$loader = new FilesystemLoader(__DIR__.'/templates');
$twig = new Environment($loader);
$renderer = new BodyRenderer($twig);

$email = (new Email())
    ->from('hello@example.com')
    ->to('recipient@example.com')
    ->subject('Test Email')
    ->html('<h1>{{ name }}</h1>', ['name' => 'John'])
;

// Renders templates and updates email object
$renderer->render($email);
```

### CSS inlining

Install the CSS inliner extension:

```bash
composer require twig/cssinliner-extra
```

Enable it:

```php
use Twig\Extra\CssInliner\CssInlinerExtension;

$twig->addExtension(new CssInlinerExtension());
```

Use in templates with `{% apply inline_css %}...{% endapply %}` block.

## Creating raw email messages

For advanced control over MIME structure, use the low-level `Message` class with proper multipart hierarchy.

### Basic structure

```php
use Symfony\Component\Mime\Header\Headers;
use Symfony\Component\Mime\Message;
use Symfony\Component\Mime\Part\Multipart\AlternativePart;
use Symfony\Component\Mime\Part\TextPart;

$headers = (new Headers())
    ->addMailboxListHeader('From', ['sender@example.com'])
    ->addMailboxListHeader('To', ['recipient@example.com'])
    ->addTextHeader('Subject', 'Test Email')
;

$textPart = new TextPart('Plain text version');
$htmlPart = new TextPart('<h1>HTML version</h1>', null, 'html');
$body = new AlternativePart($textPart, $htmlPart);

$message = new Message($headers, $body);
```

### With attachments and embedded images

```php
use Symfony\Component\Mime\Part\DataPart;
use Symfony\Component\Mime\Part\Multipart\MixedPart;
use Symfony\Component\Mime\Part\Multipart\RelatedPart;

// Embed image
$logo = new DataPart(
    fopen('/path/to/logo.png', 'r'),
    null,
    'image/png'
);
$logoId = $logo->getContentId();

// Attach file
$pdf = new DataPart(
    fopen('/path/to/document.pdf', 'r'),
    null,
    'application/pdf'
);

// Build hierarchy
$textPart = new TextPart('See attached document');
$htmlPart = new TextPart(
    sprintf('<img src="cid:%s"/> See attached document', $logoId),
    null,
    'html'
);
$alternative = new AlternativePart($textPart, $htmlPart);
$related = new RelatedPart($alternative, $logo);
$mixed = new MixedPart($related, $pdf);

$message = new Message($headers, $mixed);
```

### Headers class methods

- `addMailboxListHeader(string $name, array $addresses)` - Set mailbox list header
- `addTextHeader(string $name, string $value)` - Set text header
- `addDateHeader(string $name, \DateTimeImmutable $date)` - Set date header
- `addIdHeader(string $name, string $id)` - Set ID header
- `addPathHeader(string $name, string|array $path)` - Set path header

## Message parts

### TextPart

Create text or HTML content parts:

```php
new TextPart('Plain text content');
new TextPart('<h1>HTML</h1>', null, 'html');
new TextPart('UTF-8 content with charset', 'utf-8');
```

### DataPart

Create binary content parts (files, images):

```php
// From file handle
new DataPart(fopen('/path/to/file.pdf', 'r'), 'filename.pdf', 'application/pdf');

// From string
new DataPart('file contents', 'filename.txt', 'text/plain');

// From resource
$resource = fopen('php://memory', 'r+');
fwrite($resource, 'content');
rewind($resource);
new DataPart($resource, 'memory.txt', 'text/plain');
```

Methods:
- `getContentId()` - Get content ID for embedding (cid: reference)
- `getFilename()` - Get filename
- `getMediaType()` - Get MIME type

### Multipart classes

- `AlternativePart` - Offer multiple representations (text vs HTML)
- `RelatedPart` - Container with embedded resources
- `MixedPart` - Mix unrelated parts (content + attachments)
- `DigestPart` - Digest format for multiple messages
- `FormDataPart` - Multipart form data

## Serializing messages

Serialize email messages as simple data objects for storage or async processing:

```php
$email = (new Email())
    ->from('sender@example.com')
    ->to('recipient@example.com')
    ->subject('Test')
    ->text('Content')
;

// Serialize
$serialized = serialize($email);

// Later, recreate as RawMessage
use Symfony\Component\Mime\RawMessage;

$message = new RawMessage(unserialize($serialized));
```

This is useful for storing messages in databases or queuing with the Messenger component.

## MIME types utilities

### Convert between MIME types and extensions

```php
use Symfony\Component\Mime\MimeTypes;

$mimeTypes = new MimeTypes();

// Get extensions for MIME type (first is preferred)
$exts = $mimeTypes->getExtensions('application/javascript');
// Returns: ['js', 'jsm', 'mjs']

$exts = $mimeTypes->getExtensions('image/jpeg');
// Returns: ['jpeg', 'jpg', 'jpe']

// Get MIME types for extension
$types = $mimeTypes->getMimeTypes('js');
// Returns: ['application/javascript', 'application/x-javascript', 'text/javascript']
```

### Guess MIME type

Detect MIME type by file contents:

```php
$mimeTypes = new MimeTypes();
$type = $mimeTypes->guessMimeType('/path/to/image.gif');
// Returns: 'image/gif'
```

**Tip:** Install PHP `fileinfo` extension for better performance and accuracy.

### Custom MIME type guesser

Implement custom guessing logic:

```php
use Symfony\Component\Mime\MimeTypeGuesserInterface;

class CustomMimeTypeGuesser implements MimeTypeGuesserInterface
{
    public function isGuesserSupported(): bool
    {
        // Check if this guesser can operate in current environment
        return true;
    }

    public function guessMimeType(string $path): ?string
    {
        // Inspect file contents and return MIME type or null
        return 'application/custom';
    }
}
```

Register as service with `mime.mime_type_guesser` tag (auto-configured with autoconfiguration enabled).

## MIME structure reference

Standard MIME message hierarchy for email with embedded images and attachments:

```
multipart/mixed
├── multipart/related
│   ├── multipart/alternative
│   │   ├── text/plain
│   │   └── text/html
│   └── image/png (embedded)
└── application/pdf (attachment)
```

Use this structure when manually building complex messages with the low-level API.

## Integration with other components

- **Mailer Component** - Use `MailerInterface` to send `Email` or `RawMessage` objects
- **Messenger Component** - Serialize and queue messages for async sending
- **Twig Bridge** - Use `BodyRenderer` or `TemplatedEmail` for template rendering

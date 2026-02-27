# Symfony Messenger Component

Implement robust message-based communication patterns for synchronous execution, asynchronous queuing, and event-driven workflows.

## Installation

```bash
composer require symfony/messenger
```

## Core Concepts

- **Bus**: Dispatches messages through an ordered middleware stack
- **Sender**: Serializes and sends messages to message brokers/APIs
- **Receiver**: Retrieves, deserializes, and forwards messages to handlers
- **Handler**: Executes business logic in `__invoke()` for a specific message type
- **Envelope**: Wraps messages with metadata through stamps
- **Stamp**: Metadata attached to messages (DelayStamp, SentStamp, ReceivedStamp, etc.)
- **Middleware**: Cross-cutting concerns (logging, validation, transactions) in message flow

## Creating Messages & Handlers

Define a simple serializable message class:

```php
namespace App\Message;

class SmsNotification {
    public function __construct(private string $content) {}
    public function getContent(): string { return $this->content; }
}
```

Create a handler with `#[AsMessageHandler]` attribute:

```php
namespace App\MessageHandler;

use App\Message\SmsNotification;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

#[AsMessageHandler]
class SmsNotificationHandler {
    public function __invoke(SmsNotification $message): void {
        // Send SMS using $message->getContent()
    }
}
```

Dispatch messages via the MessageBusInterface:

```php
use Symfony\Component\Messenger\MessageBusInterface;

class NotificationService {
    public function __construct(private MessageBusInterface $bus) {}

    public function notify(string $content): void {
        $this->bus->dispatch(new SmsNotification($content));
    }
}
```

## Asynchronous Message Routing

Route messages to transports using attributes, YAML, or PHP configuration.

**Route via attribute:**

```php
#[AsMessage('async')]
class SmsNotification {}

// Route to multiple transports:
#[AsMessage(['async', 'audit'])]
class SmsNotification {}
```

**Route via YAML configuration:**

```yaml
framework:
  messenger:
    transports:
      sync: 'sync://'
      async: '%env(MESSENGER_TRANSPORT_DSN)%'
    routing:
      'App\Message\SmsNotification': async
      'App\Message\EmailNotification': ['async', 'audit']
```

## Transport Configuration

### Doctrine Transport

```bash
composer require symfony/doctrine-messenger
```

```yaml
framework:
  messenger:
    transports:
      async:
        dsn: 'doctrine://default'
        options:
          table_name: messenger_messages
          queue_name: default
          redeliver_timeout: 3600
          auto_setup: true
```

### Redis Transport

```bash
composer require symfony/redis-messenger
```

```yaml
framework:
  messenger:
    transports:
      async:
        dsn: 'redis://localhost:6379/messages'
        options:
          stream: messages
          group: symfony
          consumer: consumer-1
          auto_setup: true
          delete_after_ack: true
```

### AMQP Transport

```bash
composer require symfony/amqp-messenger
```

```yaml
framework:
  messenger:
    transports:
      async:
        dsn: 'amqp://guest:guest@localhost:5672/%2f/messages'
        options:
          auto_setup: true
          vhost: /
```

### Beanstalkd Transport

```bash
composer require symfony/beanstalkd-messenger
```

```yaml
framework:
  messenger:
    transports:
      async:
        dsn: 'beanstalkd://localhost:11300?tube_name=foo'
        options:
          bury_on_reject: true
          timeout: 4
          ttr: 120
```

Set priority on messages:

```php
use Symfony\Component\Messenger\Bridge\Beanstalkd\Transport\BeanstalkdPriorityStamp;

$bus->dispatch(new SomeMessage(), [
    new BeanstalkdPriorityStamp(0),  // 0 = highest priority
]);
```

## Consuming Messages

Run the worker to process asynchronous messages:

```bash
# Consume from single transport
php bin/console messenger:consume async

# Consume from all transports
php bin/console messenger:consume --all

# Exclude specific transports
php bin/console messenger:consume --all --exclude-receivers=async_priority_low

# Limit messages/memory/time
php bin/console messenger:consume async --limit=100 --memory-limit=256M --time-limit=3600

# Keep process alive and restart on failure
php bin/console messenger:consume async --keepalive --failure-limit=5

# Consume specific queue
php bin/console messenger:consume my_transport --queues=fasttrack
```

### Production Configuration

**Supervisor configuration:**

```ini
[program:messenger-consume]
command=php /path/app/bin/console messenger:consume async --time-limit=3600
autostart=true
autorestart=true
numprocs=2
user=www-data
```

**Systemd configuration:**

```ini
[Unit]
Description=Symfony Messenger Worker %i
After=network.target

[Service]
Type=simple
ExecStart=php /path/app/bin/console messenger:consume async --time-limit=3600
Restart=always
RestartSec=30
User=www-data

[Install]
WantedBy=multi-user.target
```

## Message Retry & Failure Handling

Configure automatic retries with exponential backoff:

```yaml
framework:
  messenger:
    failure_transport: failed
    transports:
      async:
        dsn: '%env(MESSENGER_TRANSPORT_DSN)%'
        retry_strategy:
          max_retries: 3
          delay: 1000        # milliseconds
          multiplier: 2      # exponential backoff
          max_delay: 10000   # cap on delay
          jitter: 0.1        # randomness factor (0-1)
      failed: 'doctrine://default?queue_name=failed'
```

Skip retries for unrecoverable errors:

```php
use Symfony\Component\Messenger\Exception\UnrecoverableMessageHandlingException;

throw new UnrecoverableMessageHandlingException('Invalid data', 0, $e);
```

Force retries regardless of max_retries:

```php
use Symfony\Component\Messenger\Exception\RecoverableMessageHandlingException;

throw new RecoverableMessageHandlingException('Temporary failure', 0, $e);
```

Manage failed messages:

```bash
# Show failed messages
php bin/console messenger:failed:show

# Show failed messages with stats
php bin/console messenger:failed:show --stats

# Filter by message class
php bin/console messenger:failed:show --class-filter='App\Message\MyMessage' --max=10

# Retry failed messages
php bin/console messenger:failed:retry -vv

# Remove failed message
php bin/console messenger:failed:remove 20
```

## Envelope Stamps

Attach metadata to messages via stamps:

```php
use Symfony\Component\Messenger\Envelope;
use Symfony\Component\Messenger\Stamp\DelayStamp;
use Symfony\Component\Messenger\Stamp\TransportNamesStamp;

// Delay processing by 5 seconds
$bus->dispatch(
    new Envelope(new Message()),
    [new DelayStamp(5000)]
);

// Route to multiple transports
$bus->dispatch(
    new Message(),
    [new TransportNamesStamp(['async', 'audit'])]
);
```

**Built-in Stamps:**

- `DelayStamp(delay)` - Delay asynchronous processing (milliseconds)
- `DispatchAfterCurrentBusStamp` - Handle after current bus execution completes
- `HandledStamp` - Marks message as handled; contains handler return value
- `ReceivedStamp(transport, from)` - Marks message received from transport
- `SentStamp(sender, alias)` - Marks message sent by sender FQCN
- `SerializerStamp(context)` - Configure serialization groups
- `ValidationStamp(groups)` - Configure validation groups
- `ErrorDetailsStamp(exception)` - Contains FlattenException on handler failure
- `ScheduledStamp` - Marks messages from scheduler

## Custom Middleware

Implement `MiddlewareInterface` to add cross-cutting concerns:

```php
use Symfony\Component\Messenger\Envelope;
use Symfony\Component\Messenger\Middleware\MiddlewareInterface;
use Symfony\Component\Messenger\Middleware\StackInterface;
use Symfony\Component\Messenger\Stamp\ReceivedStamp;

class LoggingMiddleware implements MiddlewareInterface {
    public function handle(Envelope $envelope, StackInterface $stack): Envelope {
        $message = $envelope->getMessage();

        if ($envelope->last(ReceivedStamp::class)) {
            // Message received from transport
            \log('Processing: ' . $message::class);
        }

        return $stack->next()->handle($envelope, $stack);
    }
}
```

Register middleware:

```yaml
framework:
  messenger:
    buses:
      messenger:
        middleware:
          - App\Messenger\LoggingMiddleware
```

## Custom Senders & Receivers

Implement `SenderInterface` for custom message sending:

```php
use Symfony\Component\Messenger\Envelope;
use Symfony\Component\Messenger\Transport\Sender\SenderInterface;

class EmailSender implements SenderInterface {
    public function send(Envelope $envelope): Envelope {
        $message = $envelope->getMessage();
        // Send logic
        return $envelope->with(new SentStamp(self::class));
    }
}
```

Implement `ReceiverInterface` for custom message retrieval:

```php
use Symfony\Component\Messenger\Envelope;
use Symfony\Component\Messenger\Transport\Receiver\ReceiverInterface;

class CsvReceiver implements ReceiverInterface {
    public function get(): iterable {
        // Parse CSV and yield Envelopes
    }

    public function ack(Envelope $envelope): void {
        // Mark as processed
    }

    public function reject(Envelope $envelope): void {
        // Reject message
    }
}
```

## Custom Transports

Create a custom transport factory implementing `TransportFactoryInterface`:

```php
use Symfony\Component\Messenger\Transport\TransportFactoryInterface;
use Symfony\Component\Messenger\Transport\TransportInterface;
use Symfony\Component\Messenger\Transport\Serialization\SerializerInterface;

class YourTransportFactory implements TransportFactoryInterface {
    public function createTransport(
        string $dsn,
        array $options,
        SerializerInterface $serializer
    ): TransportInterface {
        return new YourTransport($serializer, $options);
    }

    public function supports(string $dsn, array $options): bool {
        return str_starts_with($dsn, 'your-transport://');
    }
}
```

Implement `TransportInterface` combining `SenderInterface` and `ReceiverInterface`:

```php
use Symfony\Component\Messenger\Transport\TransportInterface;
use Symfony\Component\Messenger\Stamp\TransportMessageIdStamp;

class YourTransport implements TransportInterface {
    public function send(Envelope $envelope): Envelope {
        $encoded = $this->serializer->encode($envelope);
        $id = $this->store($encoded);
        return $envelope->with(new TransportMessageIdStamp($id));
    }

    public function get(): iterable {
        foreach ($this->retrieve() as $id => $data) {
            yield $this->serializer->decode(['body' => $data])
                ->with(new TransportMessageIdStamp($id));
        }
    }

    public function ack(Envelope $envelope): void {
        $stamp = $envelope->last(TransportMessageIdStamp::class);
        $this->markProcessed($stamp->getId());
    }

    public function reject(Envelope $envelope): void {
        $stamp = $envelope->last(TransportMessageIdStamp::class);
        $this->delete($stamp->getId());
    }
}
```

Register in services configuration:

```yaml
services:
    Your\Transport\YourTransportFactory:
        tags: [messenger.transport_factory]
```

Use in messenger configuration:

```yaml
framework:
  messenger:
    transports:
      yours: 'your-transport://...'
```

## Priority Message Handling

Route messages to different queues/transports with priorities:

```yaml
framework:
  messenger:
    transports:
      async_priority_high:
        dsn: 'redis://localhost/messages'
        options:
          queue_name: high
      async_priority_low:
        dsn: 'redis://localhost/messages'
        options:
          queue_name: low
    routing:
      'App\Message\UrgentNotification': async_priority_high
      'App\Message\WeeklyReport': async_priority_low
```

Consume with priorities:

```bash
php bin/console messenger:consume async_priority_high async_priority_low
```

## Message Batching

Process multiple messages in a single operation:

```php
use Symfony\Component\Messenger\Attribute\AsMessageHandler;
use Symfony\Component\Messenger\Stamp\BatchHandlerStamp;

#[AsMessageHandler]
class BatchPdfGeneratorHandler {
    public function __invoke(
        PdfGenerationMessage $message,
        BatchHandlerStamp $batch = null
    ): void {
        if (null === $batch) {
            return;  // Called synchronously
        }

        $messages = $batch->getMessages();
        // Process all messages as batch
    }
}
```

## Getting Handler Results

Retrieve return values from synchronous message handling:

```php
use Symfony\Component\Messenger\Stamp\HandledStamp;

$envelope = $this->bus->dispatch(new MyMessage());

$handledStamp = $envelope->last(HandledStamp::class);
$result = $handledStamp->getResult();
```

## Message Statistics

View transport statistics:

```bash
# Show all transport stats
php bin/console messenger:stats

# Show specific transport stats
php bin/console messenger:stats my_transport

# Output as JSON
php bin/console messenger:stats --format=json
```

## Multiple Buses (Command & Event Buses)

Configure separate buses for commands and events:

```yaml
framework:
  messenger:
    buses:
      command_bus:
        middleware:
          - validation
      event_bus:
        middleware:
          - validation
    routing:
      'App\Command\*': command_bus
      'App\Event\*': event_bus
```

Bind handlers to specific buses:

```php
#[AsMessageHandler(bus: 'command_bus')]
class MyCommandHandler {}

#[AsMessageHandler(bus: 'event_bus')]
class MyEventHandler {}
```

Debug registered buses and handlers:

```bash
php bin/console debug:messenger
```

## Doctrine Integration

Transactional message handling - process new messages only after handler completes:

```yaml
framework:
  messenger:
    buses:
      messenger:
        middleware:
          - before_send_middleware
          - doctrine_transaction
          - send_message
```

Inject Doctrine entity manager:

```php
use Doctrine\ORM\EntityManagerInterface;

#[AsMessageHandler]
class UpdateUserHandler {
    public function __construct(private EntityManagerInterface $em) {}

    public function __invoke(UpdateUserMessage $message): void {
        $user = $this->em->find(User::class, $message->userId);
        // Update and persist
    }
}
```

## State Management

Prevent memory leaks in worker processes - implement `ResetInterface`:

```php
use Symfony\Component\Messenger\ResettableInterface;

class DatabaseConnection implements ResettableInterface {
    public function reset(): void {
        // Close and reconnect
        $this->connection->close();
        $this->connection->connect();
    }
}
```

Automatic reset after each message:

```bash
php bin/console messenger:consume async  # Default: reset after each message
php bin/console messenger:consume async --no-reset  # Skip reset
```

## Encoding Custom Message Formats

Implement custom serializer for alternate formats (JSON, XML, etc.):

```php
use Symfony\Component\Messenger\Transport\Serialization\SerializerInterface;

class JsonSerializerStamp implements SerializerInterface {
    public function encode(Envelope $envelope): array {
        // Encode to JSON format
        return [
            'body' => \json_encode($data),
            'headers' => ['type' => 'json'],
        ];
    }

    public function decode(array $encodedEnvelope): Envelope {
        // Decode from JSON format
        $data = \json_decode($encodedEnvelope['body'], true);
        return new Envelope(new Message($data));
    }
}
```

## Common Configuration

Full messenger configuration example:

```yaml
framework:
  messenger:
    failure_transport: failed
    transports:
      async: '%env(MESSENGER_TRANSPORT_DSN)%'
      audit: '%env(AUDIT_TRANSPORT_DSN)%'
      failed: 'doctrine://default?queue_name=failed'
    routing:
      'App\Message\*': async
      'App\Message\AuditLog': [async, audit]
    buses:
      messenger:
        default_middleware: true
        middleware:
          - validation
```

## Environment Variables

```env
MESSENGER_TRANSPORT_DSN=redis://localhost:6379/messages
MESSENGER_TRANSPORT_DSN=amqp://guest:guest@localhost:5672/%2f/messages
MESSENGER_TRANSPORT_DSN=doctrine://default
MESSENGER_TRANSPORT_DSN=beanstalkd://localhost:11300
```

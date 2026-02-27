# Symfony EventDispatcher Component

## Overview

The EventDispatcher component implements the **Observer** and **Mediator** design patterns, enabling application components to communicate through events without tight coupling. Create a plugin-based architecture where listeners react to dispatched events throughout your application lifecycle.

## Core Concepts

### Events
- Identified by unique names (e.g., `kernel.response`, `acme.order.placed`)
- Represented by `Event` objects or custom subclasses extending `Symfony\Contracts\EventDispatcher\Event`
- Can carry domain-specific data via custom event classes

### Listeners
- Callable functions or class methods responding to specific events
- Executed in priority order (higher priority executes first)
- Receive the event object, event name, and dispatcher instance

### Subscribers
- Classes implementing `EventSubscriberInterface`
- Register multiple listeners at once
- Define event subscriptions and priorities in `getSubscribedEvents()` method

## Key Classes and Methods

### EventDispatcher
```php
use Symfony\Component\EventDispatcher\EventDispatcher;

$dispatcher = new EventDispatcher();

// Register a listener
addListener(string $eventName, callable $listener, int $priority = 0): void

// Register a subscriber
addSubscriber(EventSubscriberInterface $subscriber): void

// Remove a listener
removeListener(string $eventName, callable $listener): void

// Remove a subscriber
removeSubscriber(EventSubscriberInterface $subscriber): void

// Dispatch an event
dispatch(Event $event, ?string $eventName = null): Event

// Get listeners for an event
getListeners(?string $eventName = null): array

// Check if event has listeners
hasListeners(?string $eventName = null): bool
```

### Event Base Class
```php
use Symfony\Contracts\EventDispatcher\Event;

abstract class Event
{
    // Stop propagation to remaining listeners
    public function stopPropagation(): void

    // Check if propagation was stopped
    public function isPropagationStopped(): bool
}
```

### EventSubscriberInterface
```php
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

interface EventSubscriberInterface
{
    // Return array mapping event names to methods/priorities
    public static function getSubscribedEvents(): array;
}
```

## Essential Usage Examples

### 1. Create Custom Event Class
```php
namespace Acme\Store\Event;

use Symfony\Contracts\EventDispatcher\Event;

final class OrderPlacedEvent extends Event
{
    public function __construct(
        private Order $order,
        private User $customer,
    ) {}

    public function getOrder(): Order
    {
        return $this->order;
    }

    public function getCustomer(): User
    {
        return $this->customer;
    }
}
```

### 2. Dispatch an Event
```php
use Acme\Store\Event\OrderPlacedEvent;

$order = $this->orderRepository->find(123);
$event = new OrderPlacedEvent($order, $customer);

$dispatcher->dispatch($event);
// or explicitly specify event name
$dispatcher->dispatch($event, 'store.order.placed');
```

### 3. Register Listener with Priority
```php
// Higher numbers execute earlier
$dispatcher->addListener('store.order.placed', function (OrderPlacedEvent $event): void {
    // Send confirmation email
    $mailer->send($event->getCustomer()->getEmail());
}, 100); // High priority

$dispatcher->addListener('store.order.placed', function (OrderPlacedEvent $event): void {
    // Log order to analytics
    $analytics->track('order_placed', $event->getOrder()->getId());
}, 50); // Lower priority
```

### 4. Create Event Subscriber
```php
namespace Acme\Store\Subscriber;

use Acme\Store\Event\OrderPlacedEvent;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\HttpKernel\Event\ResponseEvent;

class StoreSubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            OrderPlacedEvent::class => [
                ['onOrderPlaced', 10],
                ['notifyInventory', -10],
            ],
            KernelEvents::RESPONSE => 'onKernelResponse',
        ];
    }

    public function onOrderPlaced(OrderPlacedEvent $event): void
    {
        // Handle order placement
        $order = $event->getOrder();
        // Process order...
    }

    public function notifyInventory(OrderPlacedEvent $event): void
    {
        // Notify inventory system
    }

    public function onKernelResponse(ResponseEvent $event): void
    {
        // Handle HTTP response event
    }
}

$dispatcher->addSubscriber(new StoreSubscriber());
```

### 5. Stop Event Propagation
```php
$dispatcher->addListener('store.order.placed', function (OrderPlacedEvent $event): void {
    if (!$event->getOrder()->isValid()) {
        $event->stopPropagation(); // Prevent further listeners
    }
}, 100);

$dispatcher->addListener('store.order.placed', function (OrderPlacedEvent $event): void {
    // This won't execute if propagation was stopped
    $this->notifyWarehouse($event->getOrder());
});
```

### 6. Listener with Full Signature
```php
$dispatcher->addListener('store.order.placed', function (
    OrderPlacedEvent $event,
    string $eventName,
    EventDispatcherInterface $dispatcher
): void {
    // Full signature with event name and dispatcher access
    echo "Event: {$eventName}";
    // Access listeners for this event
    $listeners = $dispatcher->getListeners($eventName);
});
```

## Generic Event Object

Use `GenericEvent` for simple cases without custom event classes:

```php
use Symfony\Component\EventDispatcher\GenericEvent;

// Create event with subject and arguments
$event = new GenericEvent($subject, ['type' => 'action', 'counter' => 0]);
$dispatcher->dispatch($event, 'my.event');

// Access in listener using ArrayAccess or methods
$dispatcher->addListener('my.event', function (GenericEvent $event): void {
    if ($event['type'] === 'action') {
        $event['counter']++; // Modify arguments
    }

    $subject = $event->getSubject();
    $allArgs = $event->getArguments();

    if ($event->hasArgument('status')) {
        $status = $event->getArgument('status');
    }
});
```

## Immutable Event Dispatcher

Use `ImmutableEventDispatcher` to prevent modification of listener configuration:

```php
use Symfony\Component\EventDispatcher\ImmutableEventDispatcher;

// Create and configure normal dispatcher
$dispatcher = new EventDispatcher();
$dispatcher->addListener('my.event', $listener);

// Lock it in an immutable wrapper
$immutable = new ImmutableEventDispatcher($dispatcher);

// Now it can only dispatch events
$immutable->dispatch($event);

// This throws BadMethodCallException
$immutable->addListener('another.event', $listener); // Fails
```

**Use cases:** Dependency injection boundaries, API encapsulation, thread-safe references.

## Traceable Event Dispatcher

Debug event listener execution and identify unused listeners:

```php
use Symfony\Component\EventDispatcher\Debug\TraceableEventDispatcher;
use Symfony\Component\Stopwatch\Stopwatch;

$traceableDispatcher = new TraceableEventDispatcher(
    $dispatcher,
    new Stopwatch()
);

// Use normally - it tracks calls automatically
$traceableDispatcher->dispatch($event);

// Analyze which listeners were called
$called = $traceableDispatcher->getCalledListeners();
$notCalled = $traceableDispatcher->getNotCalledListeners();

foreach ($called as $listener) {
    echo "Executed: {$listener['class']}::{$listener['method']}";
}

foreach ($notCalled as $listener) {
    echo "Unused: {$listener['class']}::{$listener['method']}";
}
```

## Service Container Integration

Register listeners and subscribers with dependency injection:

```php
// Using YAML configuration
services:
  app.order_listener:
    class: Acme\Store\Listener\OrderListener
    tags:
      - name: kernel.event_listener
        event: store.order.placed
        method: onOrderPlaced
        priority: 10

  app.store_subscriber:
    class: Acme\Store\Subscriber\StoreSubscriber
    tags:
      - name: kernel.event_subscriber
```

Register compiler pass for automatic listener registration:

```php
use Symfony\Component\EventDispatcher\DependencyInjection\RegisterListenersPass;

$container->addCompilerPass(new RegisterListenersPass());
```

## Best Practices

1. **Create custom event classes** for domain-specific events rather than using GenericEvent
2. **Use class names as event identifiers**: `dispatch($event)` without explicit name when using class-based events
3. **Set appropriate priorities** (0 is default): use 100+ for essential operations, negative for cleanup
4. **Stop propagation sparingly** when semantically meaningful (validation failures, etc.)
5. **Implement EventSubscriberInterface** when registering multiple related listeners
6. **Use ImmutableEventDispatcher** at API boundaries to prevent accidental modifications
7. **Use TraceableEventDispatcher** during development to identify unused listeners

## Installation

```bash
composer require symfony/event-dispatcher
```

Requires the contracts package (often installed automatically):
```bash
composer require symfony/contracts
```

## Common Patterns

### Event Subscribers for Domain Models
```php
final class UserSubscriber implements EventSubscriberInterface
{
    public function __construct(private EmailService $emailService) {}

    public static function getSubscribedEvents(): array
    {
        return [
            UserRegisteredEvent::class => 'onUserRegistered',
            UserDeletedEvent::class => 'onUserDeleted',
        ];
    }

    public function onUserRegistered(UserRegisteredEvent $event): void
    {
        $this->emailService->sendWelcomeEmail($event->getUser());
    }

    public function onUserDeleted(UserDeletedEvent $event): void
    {
        $this->emailService->sendGoodbyeEmail($event->getUser());
    }
}
```

### Event Dispatcher Facade
```php
class MyApplication
{
    public function __construct(
        private EventDispatcher $dispatcher
    ) {}

    public function doSomething(): void
    {
        // Before action
        $this->dispatcher->dispatch(new ActionStartedEvent($this));

        try {
            // Perform work...
            $this->dispatcher->dispatch(new ActionCompletedEvent($this));
        } catch (Exception $e) {
            $this->dispatcher->dispatch(new ActionFailedEvent($this, $e));
            throw $e;
        }
    }
}
```
```

## How to Create the File

Since I don't have write permissions in this environment, you'll need to create the file manually. Follow these steps:

1. Navigate to the directory: `/Users/krzysztofsurdy/ProjectsPrivate/symfony-virtuoso/skills/symfony-event-dispatcher/`
2. Create a new file named `SKILL.md`
3. Copy and paste the complete markdown content shown above

Alternatively, you can run this command in your terminal:

```bash
cat > /Users/krzysztofsurdy/ProjectsPrivate/symfony-virtuoso/skills/symfony-event-dispatcher/SKILL.md << 'EOF'
[paste the content above here]
EOF

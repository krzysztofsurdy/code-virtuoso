## Overview

Shotgun Surgery is a code smell that occurs when making a single logical change requires modifying code scattered across multiple, unrelated classes. Instead of having cohesive, focused classes, the codebase is fragmented such that related functionality is split across numerous locations. This typically results from overzealously applying the Divergent Change refactoring, creating a mirror problem where one responsibility is distributed too widely.

## Why It's a Problem

Shotgun Surgery creates several maintainability issues:

- **High Change Friction**: Simple feature additions or bug fixes require touching many files, increasing the chance of introducing bugs
- **Difficult Maintenance**: The connection between logically related code becomes obscured, making the codebase harder to understand
- **Increased Risk**: More changes mean more opportunities for mistakes and inconsistencies
- **Poor Scalability**: As the codebase grows, the problem compounds exponentially

## Signs and Symptoms

- A single feature addition requires changes to 5+ classes
- Changes to a business rule are scattered across unrelated files
- You frequently make similar changes in parallel across multiple classes
- The rationale for class boundaries becomes unclear
- Tests must be updated in numerous places for a single logical change

## Before/After

### Before: Shotgun Surgery

```php
<?php
declare(strict_types=1);

namespace App\Orders;

readonly class OrderProcessor {
    public function processOrder(Order $order): void {
        // Modify inventory
        $inventoryUpdater = new InventoryUpdater();
        $inventoryUpdater->update($order->getItems());

        // Send notification
        $notificationSender = new NotificationSender();
        $notificationSender->send($order->getCustomerId());

        // Update accounting
        $accountingUpdater = new AccountingUpdater();
        $accountingUpdater->record($order->getTotal());
    }
}

class InventoryUpdater {
    public function update(array $items): void { /* ... */ }
}

class NotificationSender {
    public function send(int $customerId): void { /* ... */ }
}

class AccountingUpdater {
    public function record(float $amount): void { /* ... */ }
}
```

When you need to modify how orders are processed (e.g., add logging, change validation), you must modify `OrderProcessor`, `InventoryUpdater`, `NotificationSender`, AND `AccountingUpdater`.

### After: Consolidated Responsibility

```php
<?php
declare(strict_types=1);

namespace App\Orders;

enum OrderProcessingStep {
    case Inventory;
    case Notification;
    case Accounting;
}

readonly class OrderHandler {
    public function __construct(
        private OrderService $service,
    ) {}

    public function process(Order $order): void {
        $this->service->processInventory($order);
        $this->service->notifyCustomer($order);
        $this->service->recordAccounting($order);
    }
}

readonly class OrderService {
    public function __construct(
        private InventoryRepository $inventory,
        private NotificationGateway $notifications,
        private AccountingRepository $accounting,
    ) {}

    public function processInventory(Order $order): void {
        // Related inventory logic consolidated
    }

    public function notifyCustomer(Order $order): void {
        // Related notification logic consolidated
    }

    public function recordAccounting(Order $order): void {
        // Related accounting logic consolidated
    }
}
```

## Recommended Refactorings

**Move Method & Move Field**: Identify which class logically owns each piece of functionality. Move related methods and fields to consolidate responsibility. If a class becomes the natural home for multiple related changes, relocate the code there.

**Create New Class**: When no existing class cleanly owns the responsibility, create a dedicated, focused class. Use a facade or service class to coordinate related operations.

**Inline Class**: After consolidating functionality, remove classes that have become empty shells. Their purposes are now served by more cohesive units.

## Exceptions

Shotgun Surgery is acceptable in these scenarios:

- **Cross-cutting Concerns**: Logging, security, and monitoring intentionally affect multiple classes; use Aspects or Middleware patterns
- **Intentional Distributed Changes**: Some architectural patterns (Event Sourcing, CQRS) deliberately distribute related logic
- **Third-party Integration**: Adapting to external APIs may naturally require multiple touch points

## Related Smells

- **Divergent Change**: The opposite problem; when one class has too many reasons to change
- **Feature Envy**: Classes that rely too heavily on other classes' data suggest consolidation opportunities
- **Duplicate Code**: Often appears alongside Shotgun Surgery when similar changes are made across classes
- **Long Parameter List**: May indicate that a new class could better encapsulate related data

## Refactoring.guru Guidance

### Signs and Symptoms

Making any modifications requires that you make many small changes to many different classes.

### Reasons for the Problem

A single responsibility has been split up among a large number of classes. This can happen after overzealous application of Divergent Change refactoring.

### Treatment

- **Move Method** and **Move Field**: Consolidate dispersed behaviors by moving them into a single class that logically owns the responsibility.
- **Inline Class**: If moving code leaves original classes nearly empty, merge those classes into the target class to eliminate structural clutter.

### Payoff

- Better code organization
- Less code duplication
- Easier maintenance

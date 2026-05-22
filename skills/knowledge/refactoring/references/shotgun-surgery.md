## Overview

Shotgun Surgery is the smell you encounter when a single logical change forces you to edit code in many different classes. A responsibility that should be concentrated in one place is instead scattered across the codebase, so even a small modification requires a coordinated update to multiple files. This often results from over-aggressive decomposition - splitting classes too finely until a single concern spans many locations.

## Why It's a Problem

Shotgun Surgery creates compounding maintainability issues:

- **High Change Friction**: Even straightforward feature additions or bug fixes require touching many files, increasing the chance of missing one
- **Obscured Relationships**: The logical connection between related pieces of code is hidden by their physical distribution across the codebase
- **Error Amplification**: The more files you touch for a single change, the more opportunities for mistakes and inconsistencies
- **Scaling Pain**: As the codebase grows, the number of locations to update for a single concern tends to grow with it

## Signs and Symptoms

- A single feature or bug fix requires edits in five or more classes
- Business rule changes are spread across unrelated files
- You regularly make the same kind of edit in parallel across multiple classes
- Class boundaries feel arbitrary and do not align with conceptual responsibilities
- Test updates for one logical change span many test files

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

- **Divergent Change**: The inverse problem - one class accumulating too many reasons to change, while Shotgun Surgery spreads one reason across too many classes
- **Feature Envy**: Classes that constantly reach into other classes for data are a hint that consolidation would help
- **Duplicate Code**: Frequently accompanies Shotgun Surgery, since the same kind of change made in multiple places often produces near-identical code
- **Long Parameter List**: May signal that a new class could encapsulate related data currently passed around separately

After consolidating scattered code with Move Method and Move Field, check whether the original classes have become nearly empty. If so, use Inline Class to merge the remnants and eliminate structural clutter.

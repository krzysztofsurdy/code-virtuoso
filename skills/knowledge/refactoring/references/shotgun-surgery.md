## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before/After](#beforeafter)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Shotgun Surgery is the smell where one logical change forces edits in many different classes. A responsibility that belongs in one place is scattered across the codebase, so even a small modification needs a coordinated update to several files. It often comes from over-aggressive decomposition: classes split so finely that a single concern spans many locations.

## Why it's a problem

- **High change friction**: even simple feature additions or bug fixes touch many files, which raises the chance of missing one.
- **Obscured relationships**: the connection between related pieces of code is hidden by their physical distribution.
- **Error amplification**: each extra file touched is another chance for mistakes and inconsistencies.
- **Scaling pain**: as the codebase grows, the number of places to update for one concern tends to grow with it.

## Signs and symptoms

- A single feature or bug fix requires edits in five or more classes.
- Business rule changes are spread across unrelated files.
- You regularly make the same kind of edit in parallel across multiple classes.
- Class boundaries feel arbitrary and do not match conceptual responsibilities.
- Test updates for one logical change span many test files.

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

To change how orders are processed (e.g., add logging, change validation) you must modify `OrderProcessor`, `InventoryUpdater`, `NotificationSender`, and `AccountingUpdater`.

### After: consolidated responsibility

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

## Recommended refactorings

**Move Method and Move Field**: identify which class logically owns each piece of functionality, then move the related methods and fields there. If a class becomes the natural home for several related changes, relocate the code to it.

**Create a new class**: when no existing class cleanly owns the responsibility, create a focused one. Use a facade or service class to coordinate related operations.

**Inline Class**: after consolidating, remove classes that have become empty shells. More cohesive units now serve their purpose.

## Exceptions

Shotgun Surgery is acceptable in these cases:

- **Cross-cutting concerns**: logging, security, and monitoring intentionally affect multiple classes; use Aspects or Middleware patterns.
- **Intentional distributed changes**: some architectural patterns (Event Sourcing, CQRS) deliberately distribute related logic.
- **Third-party integration**: adapting to external APIs may require multiple touch points.

## Related smells

- **Divergent Change**: the inverse problem. One class accumulates too many reasons to change, while Shotgun Surgery spreads one reason across too many classes.
- **Feature Envy**: classes that keep reaching into other classes for data hint that consolidation would help.
- **Duplicate Code**: often accompanies Shotgun Surgery, since the same kind of change made in several places tends to produce near-identical code.
- **Long Parameter List**: may signal that a new class could encapsulate related data currently passed around separately.

After consolidating scattered code with Move Method and Move Field, check whether the original classes are nearly empty. If so, use Inline Class to merge the remnants.

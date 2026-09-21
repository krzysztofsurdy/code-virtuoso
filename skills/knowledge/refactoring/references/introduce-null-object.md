## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after: PHP 8.3+ code](#before-and-after-php-83-code)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Introduce Null Object replaces scattered null checks with a dedicated object that has safe default behavior. Instead of guarding every method call with `if ($object !== null)`, you create a class that implements the same interface but does nothing, or returns sensible defaults. Callers treat it like a real object, and the conditionals disappear.

## Motivation

When methods return `null` to signal a missing value, every consumer must check for null. This leads to:

- Null-checking conditionals scattered across the codebase
- Business logic buried under defensive checks
- Null pointer errors when a check is accidentally left out
- Verbose code that hides the actual flow of the program

A Null Object uses polymorphism to handle the "missing value" case. The code works the same whether a real object or a stand-in is present.

## Mechanics

1. **Create a null implementation** that shares the same interface or extends the same base class
2. **Add an `isNull()` method** (optional) returning `true` for the null object and `false` for real instances
3. **Return the null object** wherever the code previously returned `null`
4. **Remove null checks** in client code and rely on the null object's default behavior
5. **Implement sensible defaults** in the null class: no-ops for actions, empty strings or zeroes for queries

## Before and after: PHP 8.3+ code

### Before (with null checks)

```php
class User
{
    private ?Notification $notification;

    public function __construct(?Notification $notification = null)
    {
        $this->notification = $notification;
    }

    public function notifyUser(string $message): void
    {
        if ($this->notification !== null) {
            $this->notification->send($message);
        }
    }

    public function getNotificationMethod(): string
    {
        return $this->notification !== null
            ? $this->notification->getMethod()
            : 'No notification configured';
    }
}

// Usage
$user1 = new User(new EmailNotification());
$user1->notifyUser('Welcome!');

$user2 = new User(null);
if ($user2->notification !== null) {
    $user2->notifyUser('Welcome!');
}
```

### After (with Null Object pattern)

```php
interface Notification
{
    public function send(string $message): void;
    public function getMethod(): string;
    public function isNull(): bool;
}

class EmailNotification implements Notification
{
    public function send(string $message): void
    {
        echo "Sending email: {$message}";
    }

    public function getMethod(): string
    {
        return 'Email';
    }

    public function isNull(): bool
    {
        return false;
    }
}

class NullNotification implements Notification
{
    public function send(string $message): void
    {
        // Do nothing - silently ignore
    }

    public function getMethod(): string
    {
        return 'No notification configured';
    }

    public function isNull(): bool
    {
        return true;
    }
}

class User
{
    private Notification $notification;

    public function __construct(?Notification $notification = null)
    {
        $this->notification = $notification ?? new NullNotification();
    }

    public function notifyUser(string $message): void
    {
        // No null-check needed!
        $this->notification->send($message);
    }

    public function getNotificationMethod(): string
    {
        return $this->notification->getMethod();
    }
}

// Usage
$user1 = new User(new EmailNotification());
$user1->notifyUser('Welcome!');

$user2 = new User(); // Uses NullNotification by default
$user2->notifyUser('Welcome!'); // Silently ignored
echo $user2->getNotificationMethod(); // 'No notification configured'
```

## Benefits

- **No conditional clutter**: Null checks disappear from client code
- **Polymorphic handling**: Absence is modeled as an object, not a special case
- **Readable business logic**: The flow reads without defensive branching
- **Fewer missed checks**: Null pointer errors cannot come from the covered type
- **Clear responsibilities**: Real objects handle business logic; null objects handle absence
- **Uniform treatment**: Callers do not need to know whether they hold a real or null instance

## When not to use

- **Simple presence/absence**: When a boolean flag states the case clearly enough
- **Dynamic transitions**: If objects frequently switch between null and real states, consider Strategy or Optional instead
- **Strict type guarantees**: When callers must distinguish between real and absent objects for correctness
- **Negligible repetition**: If null checks appear in only one or two places, a full null class is probably too much
- **Performance sensitivity**: Object allocation overhead is usually trivial, but measure if unsure

## Related refactorings

- **Replace Conditional with Polymorphism**: Applies the same idea to other conditional branches
- **Strategy Pattern**: Similar structure, but for selecting among meaningful behavioral alternatives
- **Special Case Pattern**: A generalization of Null Object for any exceptional case, not just absence
- **Specification Pattern**: Another way to encode complex conditions as objects

## Examples in other languages

### Java

**Before:**
```java
if (customer == null) {
  plan = BillingPlan.basic();
}
else {
  plan = customer.getPlan();
}
```

**After:**
```java
class NullCustomer extends Customer {
  boolean isNull() {
    return true;
  }
  Plan getPlan() {
    return new NullPlan();
  }
  // Some other NULL functionality.
}

customer = (order.customer != null) ?
  order.customer : new NullCustomer();

plan = customer.getPlan();
```

### C#

**Before:**
```csharp
if (customer == null)
{
  plan = BillingPlan.Basic();
}
else
{
  plan = customer.GetPlan();
}
```

**After:**
```csharp
public sealed class NullCustomer: Customer
{
  public override bool IsNull
  {
    get { return true; }
  }

  public override Plan GetPlan()
  {
    return new NullPlan();
  }
  // Some other NULL functionality.
}

customer = order.customer ?? new NullCustomer();

plan = customer.GetPlan();
```

### Python

**Before:**
```python
if customer is None:
    plan = BillingPlan.basic()
else:
    plan = customer.getPlan()
```

**After:**
```python
class NullCustomer(Customer):

    def isNull(self):
        return True

    def getPlan(self):
        return self.NullPlan()

    # Some other NULL functionality.

customer = order.customer or NullCustomer()

plan = customer.getPlan()
```

### TypeScript

**Before:**
```typescript
if (customer == null) {
  plan = BillingPlan.basic();
}
else {
  plan = customer.getPlan();
}
```

**After:**
```typescript
class NullCustomer extends Customer {
  isNull(): boolean {
    return true;
  }
  getPlan(): Plan {
    return new NullPlan();
  }
  // Some other NULL functionality.
}

let customer = (order.customer != null) ?
  order.customer : new NullCustomer();

plan = customer.getPlan();
```

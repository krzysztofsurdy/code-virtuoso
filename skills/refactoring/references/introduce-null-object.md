## Overview

The Introduce Null Object refactoring technique eliminates excessive null-checking code by replacing null values with objects that provide default behavior. Instead of checking whether an object is null throughout your codebase, you create a subclass that represents the absence of a real object while maintaining the expected interface.

## Motivation

When methods return `null` to represent the absence of a value, it leads to scattered null-checks throughout your code. This results in:

- Repetitive conditional statements checking for `null`
- Reduced code readability and maintainability
- Higher chance of null pointer exceptions if checks are missed
- Defensive programming patterns that clutter business logic

By introducing a Null Object, you leverage polymorphism to handle absent values naturally, making the code cleaner and more maintainable.

## Mechanics

1. **Create a null subclass** from the original class that will act as a placeholder
2. **Implement an `isNull()` method** returning `true` for the null object and `false` for real instances
3. **Replace null returns** with instances of the null object instead of actual `null` values
4. **Substitute null checks** with calls to `isNull()` or remove them entirely
5. **Override methods** in the null class to provide sensible defaults or no-op implementations

## Before and After: PHP 8.3+ Code

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

### After (with Null Object Pattern)

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

    public function __construct(Notification $notification = null)
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

- **Eliminates conditional checks**: No more scattered `if ($object !== null)` checks throughout your code
- **Leverages polymorphism**: Uses object-oriented principles to handle absence naturally
- **Improves readability**: Business logic is cleaner and easier to understand
- **Reduces bugs**: Fewer places where null checks can be forgotten, reducing null pointer exceptions
- **Single Responsibility**: Each class has clear responsibility—real objects handle business logic, null objects handle absence

## When NOT to Use

- **Simple flags**: When you only need to check presence/absence, a simple boolean flag may be clearer
- **Frequent state changes**: If the null state frequently changes to a real object state, consider other patterns like Strategy or Optional
- **Type safety required**: When you need strict type guarantees, traditional null-checks with null coalescing operators are more explicit
- **Performance critical**: Extra object instantiation may have negligible impact, but consider in performance-sensitive code paths
- **Single use cases**: If null-checking happens in only one or two places, the overhead of creating a new class may not be justified

## Related Refactorings

- **Replace Conditional with Polymorphism**: Extending the principle to replace other conditional branches with object hierarchies
- **Strategy Pattern**: Similar structure but for selecting different algorithms rather than handling absence
- **Specification Pattern**: Another way to handle optional behaviors and complex conditions
- **Special Case Pattern**: A broader category encompassing the Null Object approach

## Examples in Other Languages

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

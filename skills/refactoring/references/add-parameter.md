# Add Parameter Refactoring

## Overview

Add Parameter is a refactoring technique that addresses the core problem: "A method doesn't have enough data to perform certain actions." When a method needs additional information to function properly, instead of making it dependent on class state, you introduce a new parameter to pass that data explicitly.

This refactoring promotes cleaner, more flexible code by ensuring methods receive all required data through their parameters rather than relying on mutable object state.

## Motivation

You use Add Parameter when:

- A method needs additional data to perform its task but currently lacks it
- Data is occasional or frequently changing (not worth storing as a class field)
- You want to make methods more reusable and testable
- You're reducing coupling by avoiding dependency on class state
- You need to pass context-specific information down the call chain

## Mechanics

1. **Create a new method** with the additional parameter
2. **Delegate the old method** - have it call the new method, passing a default value
3. **Update all callers** - modify code that needs the new functionality to pass the parameter
4. **Remove or deprecate** the original method (or keep it for backward compatibility)

Key considerations:
- Update method signatures carefully to avoid breaking existing code
- Use default parameters when possible to maintain backward compatibility
- Consider if the parameter adds value or signals a deeper design issue

## Before/After - PHP 8.3+ Code

**BEFORE:**

```php
class NotificationService {
    private string $channel = 'email';

    public function send(User $user, string $message): void {
        // Channel is hardcoded to instance variable
        $this->sendViaChannel($user, $message, $this->channel);
    }

    private function sendViaChannel(
        User $user,
        string $message,
        string $channel
    ): void {
        match($channel) {
            'email' => $this->sendEmail($user->email, $message),
            'sms' => $this->sendSms($user->phone, $message),
            'push' => $this->sendPush($user->id, $message),
        };
    }
}
```

**AFTER:**

```php
class NotificationService {
    public function send(
        User $user,
        string $message,
        string $channel = 'email'
    ): void {
        // Channel is now explicit parameter with default
        match($channel) {
            'email' => $this->sendEmail($user->email, $message),
            'sms' => $this->sendSms($user->phone, $message),
            'push' => $this->sendPush($user->id, $message),
        };
    }
}

// Usage becomes more flexible:
$service = new NotificationService();
$service->send($user, 'Hello');              // Uses default 'email'
$service->send($user, 'Alert', 'sms');      // Uses 'sms' channel
$service->send($user, 'Urgent', 'push');    // Uses 'push' channel
```

## Benefits

- **Flexibility**: Methods become more adaptable to different contexts
- **Testability**: Easier to test with various input combinations
- **Reduced Coupling**: Methods don't depend on mutable instance state
- **Reusability**: Same logic can be invoked with different parameters
- **Clarity**: Data dependencies are explicit and documented in the signature
- **Named Parameters**: PHP 8.0+ named arguments make call sites self-documenting

## When NOT to Use

- **Parameter Bloat**: Avoid creating methods with excessive parameters (typically >3-4 parameters suggests a design issue)
- **Frequent Additions**: If you constantly need to add parameters, consider using objects/DTOs instead
- **Related Data**: If the new parameter is closely related to existing parameters, combine them into an object
- **Public Interfaces**: Be cautious with public APIs—parameter changes break client code
- **Missing Design**: Adding parameters might signal that your class is missing responsibilities or data

Consider alternatives:
- Move data to the class as a property
- Use a DTO or value object to group related parameters
- Extract a new class for related functionality
- Use dependency injection for dependencies

## Related Refactorings

- **Remove Parameter**: The inverse operation when parameters become unused
- **Introduce Parameter Object**: Groups multiple parameters into a single object
- **Extract Method**: Often done alongside to improve method responsibility
- **Replace Method with Method Object**: For complex methods with many parameters
- **Move Method**: Transfer logic to a class with direct access to needed data

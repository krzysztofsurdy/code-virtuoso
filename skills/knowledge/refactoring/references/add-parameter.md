# Add Parameter Refactoring

## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after (PHP 8.3+)](#before-and-after-php-83)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)

## Overview

Add Parameter applies when a method needs more data to do its job. Instead of having the method dig into class internals or rely on global state, pass the missing information as an explicit parameter. The method's inputs become visible, which makes it easier to understand and verify.

## Motivation

Apply this technique when:

- A method needs data that its current signature does not provide
- The required information changes from call to call, making it a poor fit for a class property
- You want tests to control method inputs directly without manipulating object state
- You need to break an implicit dependency on internal fields
- Different callers have context-specific values that should flow into the method

## Mechanics

1. **Create the new method** with the additional parameter in its signature
2. **Delegate from the old method** by calling the new version with a reasonable default value
3. **Update callers progressively** so each one passes the parameter explicitly
4. **Remove the original method** once every caller has been migrated, or keep it as a shorthand overload

Points to keep in mind:
- Change the signature step by step so existing call sites keep working
- A default parameter value eases the transition and keeps old callers compatible
- If the parameter feels unnatural, it may point to a deeper design issue

## Before and after (PHP 8.3+)

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

- **Flexibility**: The method handles more scenarios without internal changes
- **Testability**: Tests can pass different values directly, in isolation
- **Reduced coupling**: The method no longer pulls values from mutable internal state
- **Reusability**: The same logic serves multiple callers with different data
- **Transparent interface**: The signature lists every piece of data the method depends on
- **Named arguments**: PHP 8.0+ named parameters make call sites self-documenting

## When NOT to use

- **Parameter overload**: A method with more than 3-4 parameters needs structural redesign
- **Repeated growth**: If parameters keep getting appended, bundle them into a Parameter Object or DTO
- **Related values**: When the new parameter belongs with existing ones, wrap them in a value object
- **Stable public contracts**: Changing a published interface breaks downstream consumers
- **Hidden abstraction gap**: The need to pass data may reveal a missing class or responsibility

Alternatives to consider:
- Make the data a class property if it belongs to the object
- Combine related parameters into a DTO or value object
- Extract a separate class for the associated functionality
- Inject service-level dependencies through the constructor

## Related refactorings

- **Remove Parameter**: The inverse operation, used when a parameter becomes unnecessary
- **Introduce Parameter Object**: Groups several related parameters into one object
- **Extract Method**: Often applied alongside to keep methods focused
- **Replace Method with Method Object**: Handles complex methods that accumulate many parameters
- **Move Method**: Moves logic to a class that already holds the needed data

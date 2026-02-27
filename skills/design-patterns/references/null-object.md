## Overview

The Null Object pattern is a behavioral design pattern that eliminates the need for explicit null checks by introducing an object that does nothing. Instead of returning `null` or checking for `null` values throughout your code, you return a special "null object" that implements the expected interface but performs no action or returns default values.

## Intent

- Eliminate null pointer exceptions (or null check conditionals)
- Provide a default behavior for missing or absent objects
- Simplify client code by removing null validation logic
- Encapsulate the concept of "nothing" as a proper object

## Problem/Solution

### Problem
In many applications, you need to handle cases where an object reference might be absent:

```php
$user = $userRepository->find($id);
if ($user !== null) {
    $user->sendWelcomeEmail();
    $user->updateLastLogin();
} else {
    // Handle null case
}
```

This leads to scattered null checks throughout the codebase, making code harder to maintain and more prone to null reference errors.

### Solution
Create a special object that implements the same interface as the real object but performs no-op operations:

```php
$user = $userRepository->find($id) ?? new NullUser();
$user->sendWelcomeEmail();  // Safe to call, does nothing if null
$user->updateLastLogin();    // Safe to call, does nothing if null
```

## Structure

The Null Object pattern consists of:

1. **Abstract Component** - Interface defining the contract
2. **Concrete Component** - Real object with actual behavior
3. **Null Object** - Implements the same interface with no-op methods

```php
// Abstract Component
interface User {
    public function sendWelcomeEmail(): void;
    public function updateLastLogin(): void;
    public function getEmail(): string;
}

// Concrete Component
readonly class RealUser implements User {
    public function __construct(private string $email) {}

    public function sendWelcomeEmail(): void {
        // Send actual email
        mail($this->email, 'Welcome!', 'Welcome to our platform');
    }

    public function updateLastLogin(): void {
        // Update database
    }

    public function getEmail(): string {
        return $this->email;
    }
}

// Null Object
readonly class NullUser implements User {
    public function sendWelcomeEmail(): void {
        // Do nothing
    }

    public function updateLastLogin(): void {
        // Do nothing
    }

    public function getEmail(): string {
        return '';  // Return sensible default
    }
}
```

## When to Use

- When you want to eliminate null checks throughout your application
- When you need a default behavior for absent objects
- When multiple null checks create complex conditional logic
- In composite structures where some elements may be "empty"
- When working with external libraries that might return null
- In IoC containers and dependency injection scenarios
- When implementing optional configuration or feature toggles

## Implementation (PHP 8.3+ Strict Types)

```php
<?php
declare(strict_types=1);

namespace App\Users\Null;

use App\Users\User;

readonly class NullUser implements User {
    private const DEFAULT_ID = 0;
    private const DEFAULT_EMAIL = '';
    private const DEFAULT_NAME = 'Unknown User';

    public function getId(): int {
        return self::DEFAULT_ID;
    }

    public function getEmail(): string {
        return self::DEFAULT_EMAIL;
    }

    public function getName(): string {
        return self::DEFAULT_NAME;
    }

    public function sendWelcomeEmail(): void {
        // Intentionally does nothing
    }

    public function updateLastLogin(): void {
        // Intentionally does nothing
    }

    public function isActive(): bool {
        return false;
    }
}

// Usage in repository
class UserRepository {
    public function find(int $id): User {
        // ... database query logic ...
        return $user ?? new NullUser();  // Return null object instead of null
    }
}

// Client code - no null checks needed
$user = $userRepository->find(999);
$user->sendWelcomeEmail();      // Safe - does nothing if not found
$user->updateLastLogin();        // Safe - does nothing if not found

if ($user->isActive()) {
    // Only execute if user actually exists
}
```

## Real-World Analogies

- **Empty seat in a meeting**: A chair that exists but no person sits in it
- **Placeholder UI component**: A component that renders but displays nothing
- **Silent logger**: A logger that accepts messages but writes them nowhere
- **Dummy employee**: A temporary staff member who performs required duties with no-op behaviors
- **Empty parking space**: A space that can be referenced but has no car

## Pros and Cons

### Pros
- Eliminates null checks and defensive programming
- Simplifies client code and improves readability
- Encapsulates the concept of absence as a proper object
- Supports polymorphism naturally
- Easier to test - no special null handling
- Reduces likelihood of null pointer exceptions

### Cons
- May hide logic errors where null return was intentional
- Can create false sense of security if not applied consistently
- Debugging can be harder when operations silently do nothing
- Requires discipline - all code paths must return consistent types
- May increase class count if many null objects needed
- Could be overkill for simple operations

## Relations with Other Patterns

- **Strategy Pattern**: Null Object is similar to Strategy with a no-op strategy
- **Composite Pattern**: Often used together - composite structures have "empty" nodes
- **Template Method**: Null Object can implement default behaviors via template methods
- **Decorator Pattern**: Can decorate real objects with logging/validation while null objects skip
- **Singleton Pattern**: Null Objects are often singletons since they have no state
- **Optional Type (Modern Alternative)**: PHP's union types or custom Optional classes can serve similar purposes

## Example: Notification Service

```php
<?php
declare(strict_types=1);

interface Notifier {
    public function notify(string $message): void;
}

readonly class EmailNotifier implements Notifier {
    public function __construct(private string $email) {}

    public function notify(string $message): void {
        echo "Sending email to {$this->email}: {$message}\n";
    }
}

readonly class NullNotifier implements Notifier {
    public function notify(string $message): void {
        // Silent - no action taken
    }
}

class NotificationService {
    public function __construct(
        private Notifier $notifier = new NullNotifier()
    ) {}

    public function alertUser(string $message): void {
        $this->notifier->notify($message);
    }
}

// Clean usage without null checks
$service = new NotificationService();  // Uses NullNotifier by default
$service->alertUser('User registered');  // Silent

$service = new NotificationService(
    new EmailNotifier('admin@example.com')
);
$service->alertUser('Error occurred');  // Sends email
```

This pattern is particularly valuable in large applications where null checks can become scattered and difficult to maintain.

## Examples in Other Languages

### Java

Example 1: Null output stream that silently discards debug output.

```java
import java.io.*;

class NullOutputStream extends OutputStream {
    public void write(int b) {
        // Do nothing
    }
}

class NullPrintStream extends PrintStream {
    public NullPrintStream() {
        super(new NullOutputStream());
    }
}

class Application {
    private PrintStream debugOut;

    public Application(PrintStream debugOut) {
        this.debugOut = debugOut;
    }

    public void doSomething() {
        int sum = 0;
        for (int i = 0; i < 10; i++) {
            sum += i;
            debugOut.println("i = " + i);
        }
        System.out.println("sum = " + sum);
    }
}

public class NullObjectDemo {
    public static void main(String[] args) {
        Application app = new Application(new NullPrintStream());
        app.doSomething();
    }
}
```

Example 2: Null object with visitor pattern for list processing.

```java
interface ListVisitor {
    Object whenNonNullList(NonNullList host, Object param);
    Object whenNullList(NullList host, Object param);
}

abstract class List {
    public abstract List getTail();
    public abstract Object accept(ListVisitor visitor, Object param);
}

class NonNullList extends List {
    private Object head;
    private List tail;

    public NonNullList(Object head, List tail) {
        this.head = head;
        this.tail = tail;
    }

    public Object getHead() {
        return head;
    }

    public List getTail() {
        return tail;
    }

    public Object accept(ListVisitor visitor, Object param) {
        return visitor.whenNonNullList(this, param);
    }
}

class NullList extends List {
    private static final NullList instance = new NullList();

    private NullList() {}

    public static NullList singleton() {
        return instance;
    }

    public List getTail() {
        return this;
    }

    public Object accept(ListVisitor visitor, Object param) {
        return visitor.whenNullList(this, param);
    }
}
```

### Python

```python
import abc


class AbstractObject(metaclass=abc.ABCMeta):
    """
    Declare the interface for Client's collaborator.
    Implement default behavior for the interface common to all classes,
    as appropriate.
    """

    @abc.abstractmethod
    def request(self):
        pass


class RealObject(AbstractObject):
    """
    Define a concrete subclass of AbstractObject whose instances provide
    useful behavior that Client expects.
    """

    def request(self):
        pass


class NullObject(AbstractObject):
    """
    Provide an interface identical to AbstractObject's so that a null
    object can be substituted for a real object.
    Implement its interface to do nothing. What exactly it means to do
    nothing depends on what sort of behavior Client is expecting.
    """

    def request(self):
        pass
```

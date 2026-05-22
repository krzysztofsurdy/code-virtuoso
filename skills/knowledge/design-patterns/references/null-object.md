## Overview

The Null Object pattern is a behavioral design pattern that replaces absent or missing references with a concrete object that implements the expected interface but performs no meaningful work. Instead of scattering `null` checks throughout the codebase, callers receive a benign stand-in that responds to every method call with safe, do-nothing defaults.

## Intent

- Remove the need for defensive null checks and conditional guards
- Represent the absence of a real collaborator as a legitimate, polymorphic object
- Streamline client code by guaranteeing that every reference points to a usable object
- Encapsulate the concept of "nothing to do" behind the same interface as the real thing

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

- When defensive null checks are spreading across the codebase and cluttering the logic
- When you want a safe fallback that satisfies the interface contract without side effects
- When composite or collection structures need "empty" nodes that participate in traversal without special handling
- When external libraries or APIs may return null and you want a clean boundary
- When dependency injection containers should always provide a working collaborator, even when the real one is absent
- When feature toggles need a way to silently disable behavior at the object level

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

- **Autopilot Disengaged**: When an aircraft's autopilot is off, the flight control system still expects inputs from the autopilot module. A "null autopilot" provides neutral, zero-correction inputs so the system continues operating normally without special-case logic.
- **Default Ringtone**: A phone without a custom ringtone assigned does not crash when a call arrives. It falls back to a default silent or system tone - a null object for the ringtone slot.
- **Placeholder Thumbnail**: A media gallery displays a generic grey box for images that have not loaded yet. The placeholder conforms to the same layout contract as a real thumbnail without requiring any special rendering path.

## Pros and Cons

### Pros
- Eliminates scattered conditional checks and the errors they cause when forgotten
- Client code reads more naturally because every reference is guaranteed to be valid
- The null object participates in polymorphism like any other implementation
- Testing becomes simpler because there is no need to mock or verify null-handling branches
- Reduces the surface area for NullPointerException-style runtime failures

### Cons
- Silent no-ops can mask genuine bugs where a null return signals an error condition
- If the pattern is applied inconsistently, developers may still write null checks out of habit
- Tracking down why an operation had no effect is harder when the code does not throw or log
- Each interface requires its own null object class, which adds to the class count
- Overly simple scenarios gain little benefit from the extra abstraction

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

# Null Object Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+ strict types)](#implementation-php-83-strict-types)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Example: notification service](#example-notification-service)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Null Object is a behavioral design pattern that replaces absent references with a concrete object that implements the expected interface but does no meaningful work. Instead of scattering `null` checks through the codebase, callers receive a harmless stand-in that answers every method call with a safe default.

## Intent

- Remove the need for defensive null checks and conditional guards
- Represent the absence of a real collaborator as a legitimate, polymorphic object
- Simplify client code by guaranteeing that every reference points to a usable object
- Hide the "nothing to do" case behind the same interface as the real thing

## Problem and solution

### Problem

An object reference might be absent, so callers have to guard against it:

```php
$user = $userRepository->find($id);
if ($user !== null) {
    $user->sendWelcomeEmail();
    $user->updateLastLogin();
} else {
    // Handle null case
}
```

The result is null checks scattered across the codebase, which are hard to maintain and easy to forget.

### Solution

Create a special object that implements the same interface as the real object but performs no-op operations:

```php
$user = $userRepository->find($id) ?? new NullUser();
$user->sendWelcomeEmail();  // Safe to call, does nothing if null
$user->updateLastLogin();    // Safe to call, does nothing if null
```

## Structure

Null Object has three parts:

1. **Abstract Component** - the interface that defines the contract
2. **Concrete Component** - the real object with actual behavior
3. **Null Object** - implements the same interface with no-op methods

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

## When to use

- Defensive null checks are spreading across the codebase and cluttering the logic
- You want a safe fallback that satisfies the interface contract without side effects
- Composite or collection structures need "empty" nodes that take part in traversal without special handling
- External libraries or APIs may return null and you want a clean boundary
- A dependency injection container should always provide a working collaborator, even when the real one is absent
- Feature toggles need a way to silently disable behavior at the object level

## Implementation (PHP 8.3+ strict types)

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

## Real-world analogies

- **Autopilot disengaged**: when an aircraft's autopilot is off, the flight control system still expects inputs from the autopilot module. A "null autopilot" supplies neutral, zero-correction inputs so the system keeps running without special-case logic.
- **Default ringtone**: a phone with no custom ringtone does not crash when a call arrives. It falls back to a default or silent tone, a null object for the ringtone slot.
- **Placeholder thumbnail**: a media gallery shows a generic grey box for images that have not loaded. The placeholder follows the same layout contract as a real thumbnail and needs no special rendering path.

## Pros and cons

### Pros

- Removes scattered conditional checks and the bugs that appear when one is forgotten
- Client code reads more naturally because every reference is valid
- The null object takes part in polymorphism like any other implementation
- Tests are simpler because there are no null-handling branches to mock or verify
- Fewer null-reference failures at runtime

### Cons

- Silent no-ops can mask real bugs where a null return signals an error condition
- If the pattern is applied inconsistently, developers may still write null checks out of habit
- It is harder to find out why an operation had no effect when the code neither throws nor logs
- Each interface needs its own null object class, which adds to the class count
- Simple scenarios gain little from the extra abstraction

## Relations with other patterns

- **Strategy**: Null Object is similar to Strategy with a no-op strategy
- **Composite**: often used together, since composite structures have "empty" nodes
- **Template Method**: a null object can implement default behavior through template methods
- **Decorator**: real objects can be decorated with logging or validation while null objects skip it
- **Singleton**: null objects are often singletons because they have no state
- **Optional type (alternative)**: PHP union types or custom Optional classes can serve a similar purpose

## Example: notification service

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

## Examples in other languages

### Java

Example 1: a null output stream that silently discards debug output.

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

Example 2: a null object with the Visitor pattern for list processing.

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

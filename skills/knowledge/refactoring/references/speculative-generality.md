## Overview

Speculative Generality is a code smell that arises when developers build abstractions for hypothetical future needs that never materialize. The result is unused abstract classes, unnecessary method parameters, unimplemented interfaces, and delegation layers that add structural weight without delivering any value. The code sits idle "just in case," making the system harder to work with for no practical benefit.

## Why It's a Problem

- **Unnecessary Complexity**: Unused abstractions clutter the codebase and make navigation harder
- **Wasted Maintenance Effort**: Developers must keep, test, and update code that contributes nothing to the application
- **Misleading Signals**: Unused structures suggest functionality or extensibility that does not actually exist
- **Refactoring Resistance**: Unnecessary layers make genuine changes harder by adding obstacles to navigate around
- **Minor Performance Cost**: Extra delegation layers can introduce small overhead, though this is usually secondary to the cognitive cost
- **Testing Waste**: Dead abstractions still demand test coverage to satisfy code quality metrics

## Signs and Symptoms

- Abstract classes or interfaces with no concrete implementations
- Method parameters that are never read inside the method body
- Classes whose sole purpose is forwarding calls to another class
- Helper methods that no caller ever invokes
- Unused generic type parameters or abstract methods never overridden
- Fields that are initialized but never subsequently accessed

## Before/After Examples

### Before: Over-engineered With Unused Parameters

```php
<?php
declare(strict_types=1);

interface Logger {
    public function log(string $message, array $context, LogLevel $level): void;
}

enum LogLevel: string {
    case DEBUG = 'debug';
    case INFO = 'info';
    case ERROR = 'error';
}

readonly class UserProcessor {
    public function __construct(private Logger $logger) {}

    public function processUser(
        int $id,
        string $name,
        string $email,
        string $oldEmail,
        string $tempStorageKey,
        string $futureMigrationId
    ): void {
        // Only $id, $name, and $email are actually used
        // $oldEmail, $tempStorageKey, $futureMigrationId are speculative
        $this->logger->log(
            "Processing user: $id",
            ['name' => $name, 'email' => $email],
            LogLevel::INFO
        );
    }
}

abstract class BaseDataHandler {
    abstract public function handle(): void;

    // This method is never overridden or used
    public function futureAnalyticsMethod(array $speculativeData): void {
        // Never called
    }
}
```

### After: Focused and Practical

```php
<?php
declare(strict_types=1);

interface Logger {
    public function log(string $message, array $context, LogLevel $level): void;
}

enum LogLevel: string {
    case DEBUG = 'debug';
    case INFO = 'info';
    case ERROR = 'error';
}

readonly class UserProcessor {
    public function __construct(private Logger $logger) {}

    public function processUser(
        int $id,
        string $name,
        string $email
    ): void {
        $this->logger->log(
            "Processing user: $id",
            ['name' => $name, 'email' => $email],
            LogLevel::INFO
        );
    }
}

readonly class DataHandler {
    public function handle(): void {
        // Concrete implementation
    }
}
```

## Recommended Refactorings

### Collapse Hierarchy
Remove unnecessary abstract classes when they have only one implementation or when abstract methods are never overridden.

```php
// Before: Unnecessary abstraction
abstract class ReportGenerator {
    abstract public function generate(): string;
}

readonly class PDFReportGenerator extends ReportGenerator {
    public function generate(): string {
        return "PDF Report";
    }
}

// After: Direct implementation
readonly class PDFReportGenerator {
    public function generate(): string {
        return "PDF Report";
    }
}
```

### Remove Parameter
Delete method parameters that are never used in the method body. Update all call sites accordingly.

```php
// Before
public function validateEmail(string $email, string $unusedLocale): bool {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

// After
public function validateEmail(string $email): bool {
    return filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}
```

### Inline Class
Remove unnecessary delegation classes that add a layer without real value.

```php
// Before: Unnecessary wrapper
readonly class OrderValidator {
    public function __construct(private PricingValidator $validator) {}

    public function validate(Order $order): bool {
        return $this->validator->validate($order->total);
    }
}

// After: Use the validator directly
$validator->validate($order->total);
```

### Inline Method
Replace method calls with direct code if the method adds no meaningful abstraction.

## Exceptions

**Framework Development**: Framework libraries intentionally provide unused extensions for framework users.

**Experimental Features**: Code explicitly marked as experimental or in-progress may justifiably include speculative elements.

**Test Utilities**: Internal test-only methods used by test suites should not be removed.

**Legacy Support**: Deprecated methods maintaining backward compatibility should be kept temporarily.

**Plugin Systems**: Framework extension points designed for third-party plugins may appear unused.

## Related Smells

- **Dead Code**: Unreachable or unused code blocks - closely related, but Dead Code refers to code that was once active
- **Lazy Class**: A class that contributes too little to justify its existence in the codebase
- **Middle Man**: A class that exists solely to forward calls to another, adding a layer without adding value
- **Feature Envy**: Methods that rely more heavily on another class's features than their own

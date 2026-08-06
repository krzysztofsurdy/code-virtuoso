## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before/After Examples](#beforeafter-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

Speculative Generality is the smell of abstractions built for hypothetical future needs that never arrive. The result is unused abstract classes, unnecessary method parameters, unimplemented interfaces, and delegation layers that add structure and no value. The code sits idle "just in case" and makes the system harder to work with.

## Why it's a problem

- **Unnecessary complexity**: unused abstractions clutter the codebase and make navigation harder.
- **Wasted maintenance effort**: developers must keep, test, and update code that contributes nothing to the application.
- **Misleading signals**: unused structures suggest functionality or extensibility that does not exist.
- **Refactoring resistance**: unnecessary layers get in the way of real changes.
- **Minor performance cost**: extra delegation layers add small overhead, though the cognitive cost is usually larger.
- **Testing waste**: dead abstractions still need test coverage to satisfy code quality metrics.

## Signs and symptoms

- Abstract classes or interfaces with no concrete implementations.
- Method parameters that are never read inside the method body.
- Classes whose only purpose is forwarding calls to another class.
- Helper methods that no caller invokes.
- Unused generic type parameters, or abstract methods that are never overridden.
- Fields that are initialized but never accessed.

## Before/After Examples

### Before: over-engineered with unused parameters

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

### After: focused and practical

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

## Recommended refactorings

### Collapse Hierarchy
Remove abstract classes that have only one implementation or whose abstract methods are never overridden.

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
Delete method parameters that are never used in the method body, and update all call sites.

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
Remove delegation classes that add a layer without real value.

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
Replace method calls with the method body if the method adds no meaningful abstraction.

## Exceptions

**Framework development**: framework libraries intentionally provide extension points that their own code does not use.

**Experimental features**: code marked as experimental or in progress may justifiably include speculative elements.

**Test utilities**: internal test-only methods used by test suites should not be removed.

**Legacy support**: deprecated methods that maintain backward compatibility should be kept temporarily.

**Plugin systems**: extension points designed for third-party plugins may appear unused.

## Related smells

- **Dead Code**: unreachable or unused code. Closely related, but Dead Code refers to code that was once active.
- **Lazy Class**: a class that contributes too little to justify its existence.
- **Middle Man**: a class that exists only to forward calls to another, adding a layer without value.
- **Feature Envy**: methods that rely more on another class's features than their own.

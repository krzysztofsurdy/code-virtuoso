## Overview

Speculative Generality is a code smell that occurs when developers write code in anticipation of features that may never be needed. This results in unused abstract classes, unnecessary method parameters, unimplemented interfaces, or delegation layers that add complexity without providing value. The code exists "just in case," but the anticipated future requirements never materialize.

## Why It's a Problem

- **Increased Complexity**: Unused code makes the codebase harder to understand and navigate
- **Maintenance Burden**: Developers must maintain, test, and potentially update code that serves no purpose
- **Misleading Intent**: Unused code sends confusing signals about the system's actual functionality
- **Harder Refactoring**: Future changes become more difficult when navigating unnecessary abstractions
- **Performance Impact**: Additional layers may introduce minor performance overhead
- **Testing Overhead**: More code requires more tests, even if unnecessary

## Signs and Symptoms

- Unused abstract classes or interfaces with no concrete implementations
- Methods with parameters that are never referenced in the method body
- Classes that exist purely to delegate to another class
- "Helper" methods that are never called
- Unused generic type parameters
- Abstract methods defined but never overridden
- Fields initialized but never used

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

- **Dead Code**: Unreachable or unused code blocks
- **Lazy Class**: A class that does too little to justify its existence
- **Middle Man**: A class that exists primarily to delegate to another
- **Feature Envy**: Methods that use more features of another class than their own

## Refactoring.guru Guidance

### Signs and Symptoms

There is an unused class, method, field, or parameter.

### Reasons for the Problem

Sometimes code is created "just in case" to support anticipated future features that never materialize. As a result, code becomes hard to understand and support.

### Treatment

- **Collapse Hierarchy**: Remove unnecessary abstract classes.
- **Inline Class**: Remove unnecessary delegation classes.
- **Inline Method**: Delete unused methods.
- **Remove Parameter**: Eliminate unused method parameters.

### Payoff

- Slimmer code.
- Easier maintenance.

### When to Ignore

- If you are working on a framework, it is eminently reasonable to create functionality not used in the framework itself, as long as it is needed by framework users.
- Keep elements if unit tests require them for accessing class information or performing testing-specific actions.

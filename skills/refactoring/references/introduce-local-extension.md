## Overview

Introduce Local Extension is a refactoring technique that safely extends third-party or legacy classes with additional functionality. Instead of modifying the original class (which may be outside your control), you create a local wrapper class that either inherits from or wraps the original class, adding necessary methods while maintaining compatibility and avoiding tight coupling.

## Motivation

### When to Apply

- **Third-party library limitations**: You need additional methods not provided by external classes
- **Legacy class enhancement**: Adding functionality to unmaintainable code without modifying it
- **API incompleteness**: Library classes don't provide all methods your domain needs
- **Avoiding monkey-patching**: PHP doesn't support open classes, so composition/inheritance solves this
- **Feature requirements diverge**: Original library doesn't support your specific use cases
- **Version compatibility**: Adding functionality without upgrading potentially breaking dependencies

### Why It Matters

Instead of modifying foreign classes or distributing patches, Introduce Local Extension provides a clean separation of concerns. It allows you to extend functionality for your specific domain while keeping third-party code untouched, reducing maintenance burden and avoiding conflicts with library updates.

## Mechanics: Step-by-Step

1. **Identify the limitation**: Determine which methods the foreign class lacks
2. **Create extension class**: Build a new class that either inherits from or wraps the original
3. **Implement inheritance or composition**: Choose based on your needs and constraints
4. **Add local methods**: Implement the additional functionality in your extension
5. **Update client code**: Replace references to the original class with your extension
6. **Test thoroughly**: Ensure new methods work correctly and don't break existing behavior
7. **Document the extension**: Clearly mark this as a local extension of foreign code

## Before: PHP 8.3+ Example

```php
<?php

declare(strict_types=1);

class DateProcessor
{
    private DateTime $date;

    public function __construct()
    {
        $this->date = new DateTime('2024-01-15');
    }

    public function displayFormattedDate(): string
    {
        // DateTime doesn't provide isWeekend() method
        // We need to add this functionality ourselves

        $dayOfWeek = (int) $this->date->format('w');
        $isWeekend = $dayOfWeek === 0 || $dayOfWeek === 6;

        return sprintf(
            'Date: %s (%s)',
            $this->date->format('Y-m-d'),
            $isWeekend ? 'Weekend' : 'Weekday'
        );
    }

    public function getQuarter(): int
    {
        $month = (int) $this->date->format('m');
        return (int) ceil($month / 3);
    }

    public function getDaysSinceEpoch(): int
    {
        $epoch = new DateTime('1970-01-01');
        $diff = $this->date->diff($epoch);
        return (int) $diff->days;
    }
}
```

## After: PHP 8.3+ Example

### Solution 1: Inheritance-based Extension

```php
<?php

declare(strict_types=1);

/**
 * Local extension of DateTime class with domain-specific functionality.
 * Inherits from DateTime to add business logic methods.
 */
class LocalDateTime extends DateTime
{
    /**
     * Check if the date falls on a weekend.
     */
    public function isWeekend(): bool
    {
        $dayOfWeek = (int) $this->format('w');
        return $dayOfWeek === 0 || $dayOfWeek === 6;
    }

    /**
     * Get the calendar quarter (1-4) for this date.
     */
    public function getQuarter(): int
    {
        $month = (int) $this->format('m');
        return (int) ceil($month / 3);
    }

    /**
     * Calculate days since Unix epoch.
     */
    public function getDaysSinceEpoch(): int
    {
        $epoch = new DateTime('1970-01-01');
        $diff = $this->diff($epoch);
        return (int) $diff->days;
    }

    /**
     * Check if date is in the future.
     */
    public function isFuture(): bool
    {
        return $this > new DateTime('now');
    }

    /**
     * Get human-readable relative date (e.g., "2 days ago").
     */
    public function getRelativeFormat(): string
    {
        $now = new DateTime('now');
        $interval = $now->diff($this);

        if ($interval->days === 0) {
            return 'Today';
        }

        if ($interval->days === 1 && $interval->invert === 1) {
            return 'Yesterday';
        }

        if ($interval->days === 1 && $interval->invert === 0) {
            return 'Tomorrow';
        }

        $direction = $interval->invert === 1 ? 'ago' : 'in';
        return sprintf('%d days %s', $interval->days, $direction);
    }
}

class DateProcessor
{
    private LocalDateTime $date;

    public function __construct()
    {
        $this->date = new LocalDateTime('2024-01-15');
    }

    public function displayFormattedDate(): string
    {
        return sprintf(
            'Date: %s (%s)',
            $this->date->format('Y-m-d'),
            $this->date->isWeekend() ? 'Weekend' : 'Weekday'
        );
    }

    public function getQuarter(): int
    {
        return $this->date->getQuarter();
    }

    public function getDaysSinceEpoch(): int
    {
        return $this->date->getDaysSinceEpoch();
    }
}
```

### Solution 2: Composition-based Extension (Safer Alternative)

```php
<?php

declare(strict_types=1);

/**
 * Local extension using composition.
 * Wraps DateTime to add domain-specific functionality.
 */
class LocalDateWrapper
{
    public function __construct(
        private readonly DateTime $dateTime
    ) {
    }

    public static function now(): self
    {
        return new self(new DateTime('now'));
    }

    public static function fromString(string $dateString): self
    {
        return new self(new DateTime($dateString));
    }

    public function isWeekend(): bool
    {
        $dayOfWeek = (int) $this->dateTime->format('w');
        return $dayOfWeek === 0 || $dayOfWeek === 6;
    }

    public function getQuarter(): int
    {
        $month = (int) $this->dateTime->format('m');
        return (int) ceil($month / 3);
    }

    public function getDaysSinceEpoch(): int
    {
        $epoch = new DateTime('1970-01-01');
        $diff = $this->dateTime->diff($epoch);
        return (int) $diff->days;
    }

    public function isFuture(): bool
    {
        return $this->dateTime > new DateTime('now');
    }

    public function getRelativeFormat(): string
    {
        $now = new DateTime('now');
        $interval = $now->diff($this->dateTime);

        if ($interval->days === 0) {
            return 'Today';
        }

        if ($interval->days === 1 && $interval->invert === 1) {
            return 'Yesterday';
        }

        if ($interval->days === 1 && $interval->invert === 0) {
            return 'Tomorrow';
        }

        $direction = $interval->invert === 1 ? 'ago' : 'in';
        return sprintf('%d days %s', $interval->days, $direction);
    }

    // Delegate to wrapped DateTime
    public function format(string $format): string
    {
        return $this->dateTime->format($format);
    }

    public function diff(DateTime $other, bool $absolute = false): DateInterval
    {
        return $this->dateTime->diff($other, $absolute);
    }
}

class DateProcessor
{
    private LocalDateWrapper $date;

    public function __construct()
    {
        $this->date = LocalDateWrapper::fromString('2024-01-15');
    }

    public function displayFormattedDate(): string
    {
        return sprintf(
            'Date: %s (%s)',
            $this->date->format('Y-m-d'),
            $this->date->isWeekend() ? 'Weekend' : 'Weekday'
        );
    }

    public function getQuarter(): int
    {
        return $this->date->getQuarter();
    }

    public function getDaysSinceEpoch(): int
    {
        return $this->date->getDaysSinceEpoch();
    }
}
```

## Benefits

- **Maintains original code integrity**: Third-party or legacy code remains unmodified
- **Avoids conflicts**: Local extensions don't conflict with library updates
- **Clean separation**: Domain-specific logic is isolated from foreign code
- **Flexibility**: Add features specific to your application without forking libraries
- **Testability**: Local extensions are easier to mock and test in isolation
- **Reusability**: The extension can be reused across your codebase
- **Documentation**: Makes custom functionality explicit and discoverable
- **No monkey-patching**: Provides a proper object-oriented solution

## When NOT to Use

- **Extending your own classes**: Use inheritance directly if you control the code
- **Simple utility functions**: Consider static helper classes instead
- **Frequent method additions**: If constantly adding methods, reconsider the design
- **Liskov Substitution violated**: Don't extend if behavior fundamentally differs
- **Composition requires too much delegation**: When most methods need wrapping, inheritance may be simpler
- **Library provides extension points**: Use official plugin/extension mechanisms if available
- **Performance is critical**: Composition adds minimal overhead, but inheritance is theoretically faster

## Related Refactorings

- **Extract Class**: Isolate new functionality into a dedicated class instead of extending
- **Replace Conditional with Polymorphism**: Use inheritance when behavior varies significantly
- **Adapter Pattern**: Similar intent but focuses on interface compatibility rather than feature addition
- **Decorator Pattern**: More flexible than inheritance for adding responsibilities
- **Introduce Foreign Method**: Adds a single method to a foreign class (simpler alternative)

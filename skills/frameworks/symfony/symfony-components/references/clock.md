# Symfony Clock Component

## Contents

- [Overview](#overview)
- [Installation](#installation)
- [Core classes](#core-classes)
- [Integration patterns](#integration-patterns)
- [Testing time-sensitive logic](#testing-time-sensitive-logic)
- [Doctrine integration](#doctrine-integration)
- [Exception handling](#exception-handling)
- [Best practices](#best-practices)
- [Common scenarios](#common-scenarios)

## Overview

The Clock component decouples your application from the system clock, so tests can fix the time. It provides several clock implementations and a `DatePoint` class for working with dates and times through the Clock abstraction.

## Installation

```bash
composer require symfony/clock
```

## Core classes

### Clock class

The static `Clock` class manages clock implementations globally.

```php
use Symfony\Component\Clock\Clock;
use Symfony\Component\Clock\MockClock;
use Symfony\Component\Clock\NativeClock;
use Symfony\Component\Clock\MonotonicClock;

// Set a specific clock implementation
Clock::set(new MockClock());
Clock::set(new NativeClock()); // Default
Clock::set(new MonotonicClock());

// Retrieve the current clock instance
$clock = Clock::get();

// Set timezone
$clock = $clock->withTimeZone('Europe/Paris');

// Get current DateTimeImmutable
$now = $clock->now();

// Sleep for specified seconds (MockClock & MonotonicClock only)
$clock->sleep(2.5);
```

### Clock implementations

**NativeClock** - Default implementation, reads the system clock. Equivalent to `new \DateTimeImmutable()`.

**MockClock** - Freezes time for testing. Time advances only through `sleep()` or `modify()`.

```php
$clock = new MockClock('2022-11-16 15:20:00');
$clock->sleep(600); // Advance 10 minutes
$clock->modify('2022-11-16 15:00:00'); // Jump to specific time
```

**MonotonicClock** - Uses `hrtime()` for high-resolution, monotonic timing. System clock changes do not affect it, which makes it the right choice for measuring durations.

### DatePoint class

Wrapper around `DateTimeImmutable` that gets the current time from the `Clock` class. All date and time operations delegate to `DateTimeImmutable`.

```php
use Symfony\Component\Clock\DatePoint;

// Create with default timezone
$datePoint = new DatePoint();

// Create with specific timezone
$datePoint = new DatePoint(timezone: new \DateTimezone('UTC'));

// Create relative to reference date
$datePoint = new DatePoint('+1 month', reference: $referenceDate);

// Create from timestamp
$datePoint = DatePoint::createFromTimestamp(1129645656);

// Handle microseconds
$datePoint->setMicrosecond(345);
$microseconds = $datePoint->getMicrosecond();

// All DateTimeImmutable methods available
$formatted = $datePoint->format('Y-m-d H:i:s');
$modified = $datePoint->modify('+1 day');
$withTimezone = $datePoint->setTimezone(new \DateTimezone('UTC'));
```

### now() Function

Helper function that returns the current time from `Clock` as a `DatePoint`.

```php
use function Symfony\Component\Clock\now;

// Get current time
$now = now();

// With date modifier
$later = now('+3 hours');
$yesterday = now('-1 day');
$specificDate = now('2022-11-16 15:00:00');
```

## Integration patterns

### ClockAwareTrait

Use it in services to read the clock via `$this->now()`.

```php
namespace App\TimeUtils;

use Symfony\Component\Clock\ClockAwareTrait;

class MonthSensitive
{
    use ClockAwareTrait;

    public function isWinterMonth(): bool
    {
        $now = $this->now();
        return match ($now->format('F')) {
            'December', 'January', 'February', 'March' => true,
            default => false,
        };
    }
}

// In Symfony service: setter injection automatic via ClockAwareTrait
```

### Dependency injection

```php
namespace App\TimeUtils;

use Symfony\Component\Clock\ClockInterface;

class ExpirationChecker
{
    public function __construct(private ClockInterface $clock) {}

    public function isExpired(\DateTimeImmutable $validUntil): bool
    {
        return $this->clock->now() > $validUntil;
    }
}
```

## Testing time-sensitive logic

### ClockSensitiveTrait

Testing trait that provides `mockTime()` for creating `MockClock` instances.

```php
namespace App\Tests;

use PHPUnit\Framework\TestCase;
use Symfony\Component\Clock\Test\ClockSensitiveTrait;

class MonthSensitiveTest extends TestCase
{
    use ClockSensitiveTrait;

    public function testIsWinterMonth(): void
    {
        // Create frozen clock at specific time
        $clock = static::mockTime(new \DateTimeImmutable('2022-03-02'));

        $service = new MonthSensitive();
        $service->setClock($clock);

        $this->assertTrue($service->isWinterMonth());
    }
}
```

### MockClock testing example

```php
use Symfony\Component\Clock\MockClock;
use PHPUnit\Framework\TestCase;

class ExpirationCheckerTest extends TestCase
{
    public function testIsExpired(): void
    {
        $clock = new MockClock('2022-11-16 15:20:00');
        $checker = new ExpirationChecker($clock);
        $validUntil = new \DateTimeImmutable('2022-11-16 15:25:00');

        // Token not expired yet
        $this->assertFalse($checker->isExpired($validUntil));

        // Sleep 10 minutes (advance time)
        $clock->sleep(600);
        $this->assertTrue($checker->isExpired($validUntil));

        // Jump to earlier time
        $clock->modify('2022-11-16 15:00:00');
        $this->assertFalse($checker->isExpired($validUntil));
    }
}
```

## Doctrine integration

### Custom Doctrine types

Map `DatePoint` to immutable date and time columns with custom types.

| Type | Base type | Class |
|------|-----------|-------|
| `date_point` | `datetime_immutable` | `DatePointType` |
| `day_point` | `date_immutable` | `DayPointType` |
| `time_point` | `time_immutable` | `TimePointType` |

### Entity configuration

```php
use Symfony\Component\Clock\DatePoint;
use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
class Product
{
    #[ORM\Column(type: 'date_point')]
    private DatePoint $createdAt;

    #[ORM\Column(type: 'date_point')]
    private DatePoint $updatedAt;

    #[ORM\Column(type: 'day_point')]
    public DatePoint $birthday;

    #[ORM\Column(type: 'time_point')]
    public DatePoint $openAt;
}
```

## Exception handling

Catch invalid timezones and date strings when working with user input.

```php
try {
    $clock = Clock::get()->withTimeZone($userInput);
} catch (\DateInvalidTimeZoneException $e) {
    // Handle invalid timezone
}
```

**Available exceptions** (PHP 8.3+ with polyfill support):
- `DateMalformedStringException` - Invalid date string format
- `DateInvalidTimeZoneException` - Invalid timezone identifier

## Best practices

1. **Use ClockAwareTrait or dependency injection** - Get the clock the same way in every service
2. **Test with MockClock** - Full control over time in tests
3. **Use DatePoint for immutability** - Every date operation returns a new instance
4. **Set MockClock globally** - Call `Clock::set()` at the start of a test to affect all services
5. **Use the now() function** - The shortest way to get the current `DatePoint`
6. **Keep system time out of logic** - Never call `new \DateTime()` or `time()` directly in time-sensitive code
7. **Use MonotonicClock for measurements** - High-resolution timing that system adjustments do not affect
8. **Store DatePoints with the custom Doctrine types** - They keep the type safe

## Common scenarios

### Checking expiration

```php
use Symfony\Component\Clock\Clock;

class TokenValidator
{
    public function isValid(Token $token): bool
    {
        $now = Clock::get()->now();
        return $token->expiresAt > $now;
    }
}
```

### Scheduling events

```php
use Symfony\Component\Clock\ClockAwareTrait;

class EventScheduler
{
    use ClockAwareTrait;

    public function isReadyToExecute(ScheduledEvent $event): bool
    {
        return $this->now() >= $event->scheduledAt;
    }
}
```

### Timezone-aware operations

```php
$clock = Clock::get()->withTimeZone('America/New_York');
$now = $clock->now();
echo $now->format('Y-m-d H:i:s e'); // 2024-01-15 14:30:00 America/New_York
```

### Measuring elapsed time

```php
$stopwatch = new MonotonicClock();
$start = $stopwatch->now();

// Do work...

$end = $stopwatch->now();
$elapsed = $end->getTimestamp() - $start->getTimestamp();
```

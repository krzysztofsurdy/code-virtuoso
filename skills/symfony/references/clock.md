# Symfony Clock Component

## Overview

The Clock component decouples your application from the system clock, enabling fixed time for testing time-sensitive logic. It provides multiple clock implementations and DatePoint classes for working with dates/times through the Clock abstraction.

## Installation

```bash
composer require symfony/clock
```

## Core Classes

### Clock Class

The static Clock class manages clock implementations globally.

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

### Clock Implementations

**NativeClock** - Default implementation interacting with system clock. Equivalent to `new \DateTimeImmutable()`.

**MockClock** - Freezes time for testing. Time only advances via `sleep()` or `modify()`. Full control over current time.

```php
$clock = new MockClock('2022-11-16 15:20:00');
$clock->sleep(600); // Advance 10 minutes
$clock->modify('2022-11-16 15:00:00'); // Jump to specific time
```

**MonotonicClock** - Uses `hrtime()` for high-resolution, monotonic timing. Unaffected by system clock changes. Ideal for precise measurements.

### DatePoint Class

Wrapper around `DateTimeImmutable` that fetches time from Clock class. All date/time operations delegate to DateTimeImmutable.

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

Helper function returns current time as DatePoint from Clock.

```php
use function Symfony\Component\Clock\now;

// Get current time
$now = now();

// With date modifier
$later = now('+3 hours');
$yesterday = now('-1 day');
$specificDate = now('2022-11-16 15:00:00');
```

## Integration Patterns

### ClockAwareTrait

Use in services to access clock via `$this->now()`.

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

### Dependency Injection

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

## Testing Time-Sensitive Logic

### ClockSensitiveTrait

Testing trait provides `mockTime()` for creating MockClock instances.

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

### MockClock Testing Example

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

## Doctrine Integration

### Custom Doctrine Types

Map DatePoint to immutable date/time columns using custom types.

| Type | Base Type | Class |
|------|-----------|-------|
| `date_point` | `datetime_immutable` | `DatePointType` |
| `day_point` | `date_immutable` | `DayPointType` |
| `time_point` | `time_immutable` | `TimePointType` |

### Entity Configuration

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

## Exception Handling

Handle invalid timezones and date strings when working with user input.

```php
try {
    $clock = Clock::get()->withTimeZone($userInput);
} catch (\DateInvalidTimeZoneException $e) {
    // Handle invalid timezone
}
```

**Available Exceptions** (PHP 8.3+ with polyfill support):
- `DateMalformedStringException` - Invalid date string format
- `DateInvalidTimeZoneException` - Invalid timezone identifier

## Best Practices

1. **Use ClockAwareTrait or Dependency Injection** - Access clock consistently throughout services
2. **Test with MockClock** - Control time completely in test environments
3. **Use DatePoint for Immutability** - All date operations return new instances
4. **Set MockClock Globally** - Call `Clock::set()` at test start to affect all services
5. **Leverage now() Function** - Simple, clean way to get current DatePoint
6. **Avoid System Time in Logic** - Never use `new \DateTime()` or `time()` directly in time-sensitive code
7. **Use MonotonicClock for Measurements** - High-resolution timing unaffected by system adjustments
8. **Store DatePoints in Database** - Use custom Doctrine types for type safety

## Common Scenarios

### Checking Expiration

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

### Scheduling Events

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

### Timezone-Aware Operations

```php
$clock = Clock::get()->withTimeZone('America/New_York');
$now = $clock->now();
echo $now->format('Y-m-d H:i:s e'); // 2024-01-15 14:30:00 America/New_York
```

### Measuring Elapsed Time

```php
$stopwatch = new MonotonicClock();
$start = $stopwatch->now();

// Do work...

$end = $stopwatch->now();
$elapsed = $end->getTimestamp() - $start->getTimestamp();
```

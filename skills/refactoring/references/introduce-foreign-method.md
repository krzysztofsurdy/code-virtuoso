## Overview

The Introduce Foreign Method refactoring is a technique for extending the functionality of a class that you cannot modify. Instead of modifying the class directly, you create a new method in a class you do own that performs the needed operation on an instance of the unmodifiable class.

This is particularly useful when working with third-party libraries, framework classes, or classes you're not responsible for maintaining. Rather than workaround code scattered throughout your application, a foreign method keeps the related logic in one place.

## Motivation

You often encounter situations where:

1. **Third-party classes cannot be modified** - You're using a library class that doesn't have the method you need
2. **Limited access to the original class** - The class belongs to another team or is part of a framework
3. **Unrelated to the class's primary responsibility** - Adding the method would bloat the original class with domain-specific logic
4. **Temporary workarounds** - You need a quick solution without waiting for upstream changes

A foreign method provides a cleaner alternative to scattered utility functions or complex workaround code throughout your codebase.

## Mechanics

### Step 1: Identify the Target Class
Determine which class you cannot modify that needs additional functionality.

### Step 2: Create a Method in Your Class
Create a method in a class you own that takes an instance of the target class as a parameter.

### Step 3: Implement the Logic
Place the logic that would naturally belong in the target class into your method.

### Step 4: Document the Purpose
Clearly document that this is a foreign method and explain why it exists as a workaround.

### Step 5: Consider Extracting to a Class
If foreign methods accumulate, consider extracting them into a dedicated wrapper or extension class.

## Before: Workaround Code

```php
<?php

namespace App\Service;

use DateTime;

class ReportService
{
    public function generateMonthlyReport(DateTime $date): string
    {
        // DateTime doesn't have this method, so we work around it
        $startOfMonth = clone $date;
        $startOfMonth->modify('first day of this month');
        $startOfMonth->setTime(0, 0, 0);

        $endOfMonth = clone $date;
        $endOfMonth->modify('last day of this month');
        $endOfMonth->setTime(23, 59, 59);

        return sprintf(
            "Report for %s to %s",
            $startOfMonth->format('Y-m-d'),
            $endOfMonth->format('Y-m-d')
        );
    }

    public function getNextPaymentDate(DateTime $date): DateTime
    {
        // Another workaround for DateTime
        $next = clone $date;
        $next->modify('first day of next month');
        return $next;
    }
}
```

## After: Using Foreign Methods

```php
<?php

namespace App\Service;

use DateTime;

class DateTimeExtension
{
    /**
     * Foreign method: Get the first day of the month at midnight.
     * Added because DateTime is a third-party class we cannot modify.
     *
     * @param DateTime $date The date to process
     * @return DateTime A new DateTime instance
     */
    public static function getStartOfMonth(DateTime $date): DateTime
    {
        $startOfMonth = clone $date;
        $startOfMonth->modify('first day of this month');
        $startOfMonth->setTime(0, 0, 0);
        return $startOfMonth;
    }

    /**
     * Foreign method: Get the last day of the month at end of day.
     * Added because DateTime is a third-party class we cannot modify.
     *
     * @param DateTime $date The date to process
     * @return DateTime A new DateTime instance
     */
    public static function getEndOfMonth(DateTime $date): DateTime
    {
        $endOfMonth = clone $date;
        $endOfMonth->modify('last day of this month');
        $endOfMonth->setTime(23, 59, 59);
        return $endOfMonth;
    }

    /**
     * Foreign method: Get the first day of the next month.
     * Added because DateTime is a third-party class we cannot modify.
     *
     * @param DateTime $date The date to process
     * @return DateTime A new DateTime instance
     */
    public static function getNextPaymentDate(DateTime $date): DateTime
    {
        $next = clone $date;
        $next->modify('first day of next month');
        return $next;
    }
}

class ReportService
{
    public function generateMonthlyReport(DateTime $date): string
    {
        $start = DateTimeExtension::getStartOfMonth($date);
        $end = DateTimeExtension::getEndOfMonth($date);

        return sprintf(
            "Report for %s to %s",
            $start->format('Y-m-d'),
            $end->format('Y-m-d')
        );
    }

    public function getNextPaymentDate(DateTime $date): DateTime
    {
        return DateTimeExtension::getNextPaymentDate($date);
    }
}
```

## Alternative: Using Trait-based Foreign Methods

For PHP 8.3+, you can use attributes to mark foreign methods:

```php
<?php

namespace App\Service;

use DateTime;

#[Attribute]
class ForeignMethod
{
    public function __construct(
        public string $reason = 'Third-party class cannot be modified'
    ) {}
}

class DateTimeExtension
{
    #[ForeignMethod(reason: 'DateTime is immutable and from PHP core')]
    public static function getStartOfMonth(DateTime $date): DateTime
    {
        $startOfMonth = clone $date;
        $startOfMonth->modify('first day of this month');
        $startOfMonth->setTime(0, 0, 0);
        return $startOfMonth;
    }
}
```

## Benefits

1. **Centralized Logic** - Related operations on third-party classes are grouped together
2. **Maintainability** - Changes to the logic are in one place instead of scattered throughout the code
3. **Reusability** - Foreign methods can be called from multiple locations
4. **Documentation** - The code clearly documents why workaround code exists
5. **Testing** - Foreign methods are easier to unit test than inline workaround code
6. **Clear Intent** - Readers understand this is a deliberate extension, not a mistake

## When NOT to Use

1. **You own the class** - If you can modify the class directly, do so instead
2. **The method belongs in the class** - If the functionality is truly core to the class's purpose, modify the class
3. **Too many foreign methods** - If you accumulate many foreign methods for one class, consider creating a proper wrapper class or inheritance
4. **Single use** - For one-off operations, inline code might be simpler
5. **Complex logic** - Very complex operations are better served by a full utility class or wrapper

## When to Upgrade to a Wrapper Class

If you find yourself creating many foreign methods for the same class, consider creating a wrapper:

```php
<?php

namespace App\Service;

use DateTime;

class ExtendedDateTime
{
    public function __construct(private DateTime $date) {}

    public function getStartOfMonth(): DateTime
    {
        $start = clone $this->date;
        $start->modify('first day of this month');
        $start->setTime(0, 0, 0);
        return $start;
    }

    public function getEndOfMonth(): DateTime
    {
        $end = clone $this->date;
        $end->modify('last day of this month');
        $end->setTime(23, 59, 59);
        return $end;
    }

    public function getNextPaymentDate(): DateTime
    {
        $next = clone $this->date;
        $next->modify('first day of next month');
        return $next;
    }

    public function getInnerDate(): DateTime
    {
        return $this->date;
    }
}
```

## Related Refactorings

- **Extract Method** - Isolate the foreign method logic if it's currently inline
- **Extract Class** - If foreign methods accumulate, extract them into a dedicated utility class
- **Introduce Parameter Object** - Group multiple related foreign method parameters
- **Adapter Pattern** - Use for more complex wrapping of third-party classes
- **Decorator Pattern** - When you need to extend behavior dynamically

## Common Pitfalls

1. **Too many foreign methods** - Accumulation indicates you need a wrapper class
2. **Modifying the original class** - If you have access, modify it instead; don't create foreign methods as a workaround
3. **Poor naming** - Name foreign methods clearly to indicate they extend external functionality
4. **Missing documentation** - Always document why the foreign method exists
5. **Static methods everywhere** - Consider instance methods or a wrapper class for readability

## Examples in Other Languages

### Java

**Before:**

```java
class Report {
  // ...
  void sendReport() {
    Date nextDay = new Date(previousEnd.getYear(),
      previousEnd.getMonth(), previousEnd.getDate() + 1);
    // ...
  }
}
```

**After:**

```java
class Report {
  // ...
  void sendReport() {
    Date newStart = nextDay(previousEnd);
    // ...
  }
  private static Date nextDay(Date arg) {
    return new Date(arg.getYear(), arg.getMonth(), arg.getDate() + 1);
  }
}
```

### C#

**Before:**

```csharp
class Report
{
  // ...
  void SendReport()
  {
    DateTime nextDay = previousEnd.AddDays(1);
    // ...
  }
}
```

**After:**

```csharp
class Report
{
  // ...
  void SendReport()
  {
    DateTime nextDay = NextDay(previousEnd);
    // ...
  }
  private static DateTime NextDay(DateTime date)
  {
    return date.AddDays(1);
  }
}
```

### Python

**Before:**

```python
class Report:
    # ...
    def sendReport(self):
        nextDay = Date(self.previousEnd.getYear(),
            self.previousEnd.getMonth(), self.previousEnd.getDate() + 1)
        # ...
```

**After:**

```python
class Report:
    # ...
    def sendReport(self):
        newStart = self._nextDay(self.previousEnd)
        # ...

    def _nextDay(self, arg):
        return Date(arg.getYear(), arg.getMonth(), arg.getDate() + 1)
```

### TypeScript

**Before:**

```typescript
class Report {
  // ...
  sendReport(): void {
    let nextDay: Date = new Date(previousEnd.getYear(),
      previousEnd.getMonth(), previousEnd.getDate() + 1);
    // ...
  }
}
```

**After:**

```typescript
class Report {
  // ...
  sendReport() {
    let newStart: Date = nextDay(previousEnd);
    // ...
  }
  private static nextDay(arg: Date): Date {
    return new Date(arg.getFullYear(), arg.getMonth(), arg.getDate() + 1);
  }
}
```


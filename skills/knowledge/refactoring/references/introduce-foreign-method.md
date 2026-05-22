## Overview

Introduce Foreign Method adds functionality to a class you cannot modify by placing a new method in a class you do control. The method accepts an instance of the unmodifiable class and performs the operation that class is missing. This keeps related logic in one place rather than scattering workaround code throughout the application.

## Motivation

Situations that call for a foreign method include:

1. **Third-party class limitations** - a library class lacks a method your domain needs
2. **Restricted ownership** - the class belongs to another team or a framework you should not patch
3. **Separation of concerns** - the desired behavior is specific to your domain and does not belong in the general-purpose class
4. **Temporary bridging** - you need a solution now without waiting for an upstream release

A foreign method is a cleaner alternative to duplicating workaround logic at every call site.

## Mechanics

### Step 1: Identify the Gap
Determine which method the foreign class is missing.

### Step 2: Write the Method in Your Own Class
Create a method that takes the foreign object as a parameter.

### Step 3: Implement the Logic
Place the logic that would naturally belong on the foreign class inside your method.

### Step 4: Document the Reason
Note that the method exists because the target class cannot be modified.

### Step 5: Consider Upgrading
If foreign methods accumulate for the same class, consider consolidating them into a wrapper or extension class.

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

1. **Consolidated logic** - related operations on external classes live in one place
2. **Easier maintenance** - changes to the workaround logic happen in a single location
3. **Reuse** - multiple callers can invoke the same foreign method
4. **Transparent intent** - the code clearly marks itself as an extension of a class that cannot be modified
5. **Testability** - foreign methods are straightforward to unit test in isolation
6. **Discoverable** - a dedicated extension class is easier to find than inline workaround code

## When NOT to Use

1. **You own the class** - modify it directly instead
2. **The method belongs upstream** - if the functionality is truly general-purpose, contribute it to the library
3. **Too many foreign methods accumulate** - at that point, create a full wrapper or subclass
4. **One-off usage** - a single inline workaround may be simpler than a dedicated method
5. **Complex interactions** - operations that deeply interact with the foreign class internals are better handled by a proper adapter or decorator

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

- **Extract Method** - isolates inline workaround code before promoting it to a foreign method
- **Extract Class** - groups accumulated foreign methods into a dedicated utility class
- **Introduce Parameter Object** - bundles related foreign method parameters
- **Adapter Pattern** - wraps a foreign class for interface compatibility
- **Decorator Pattern** - extends behavior dynamically without modifying the original class

## Common Pitfalls

1. **Accumulation** - too many foreign methods signals the need for a wrapper class
2. **Modifying the wrong thing** - if you can change the class, change it; do not create a workaround
3. **Vague naming** - name foreign methods clearly so readers understand they extend external functionality
4. **Missing rationale** - always document why the method exists as a foreign extension
5. **Overuse of statics** - consider instance methods or a wrapper class for better readability

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

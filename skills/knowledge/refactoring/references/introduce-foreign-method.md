## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before: workaround code](#before-workaround-code)
- [After: using foreign methods](#after-using-foreign-methods)
- [Alternative: marking foreign methods with attributes](#alternative-marking-foreign-methods-with-attributes)
- [Benefits](#benefits)
- [When not to use](#when-not-to-use)
- [When to upgrade to a wrapper class](#when-to-upgrade-to-a-wrapper-class)
- [Related refactorings](#related-refactorings)
- [Common pitfalls](#common-pitfalls)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Introduce Foreign Method adds functionality to a class you cannot modify by placing a new method in a class you control. The method takes an instance of the unmodifiable class and performs the operation that class is missing. Related logic stays in one place instead of being scattered through the application as workaround code.

## Motivation

Use a foreign method when:

1. **Third-party class limitations** - a library class lacks a method your domain needs
2. **Restricted ownership** - the class belongs to another team or to a framework you should not patch
3. **Separation of concerns** - the behavior is specific to your domain and does not belong in the general-purpose class
4. **Temporary bridging** - you need a solution now and cannot wait for an upstream release

A foreign method is better than repeating workaround logic at every call site.

## Mechanics

### Step 1: Identify the gap

Determine which method the foreign class is missing.

### Step 2: Write the method in your own class

Create a method that takes the foreign object as a parameter.

### Step 3: Implement the logic

Put the logic that would belong on the foreign class inside your method.

### Step 4: Document the reason

Note that the method exists because the target class cannot be modified.

### Step 5: Consider upgrading

If foreign methods pile up for the same class, move them into a wrapper or extension class.

## Before: workaround code

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

## After: using foreign methods

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

## Alternative: marking foreign methods with attributes

In PHP 8+, you can use attributes to mark foreign methods:

```php
<?php

namespace App\Service;

use Attribute;
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
    #[ForeignMethod(reason: 'DateTime is a PHP core class we cannot modify')]
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
3. **Reuse** - multiple callers can use the same foreign method
4. **Clear intent** - the code marks itself as an extension of a class that cannot be modified
5. **Testability** - foreign methods are easy to unit test in isolation
6. **Discoverability** - a dedicated extension class is easier to find than inline workaround code

## When not to use

1. **You own the class** - change it directly
2. **The method belongs upstream** - if the functionality is general-purpose, contribute it to the library
3. **Too many foreign methods** - at that point, create a full wrapper or subclass
4. **One-off usage** - a single inline workaround may be simpler than a dedicated method
5. **Complex interactions** - operations that depend heavily on the foreign class internals are better handled by an adapter or decorator

## When to upgrade to a wrapper class

If you create many foreign methods for the same class, consider a wrapper:

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

## Related refactorings

- **Extract Method** - isolates inline workaround code before you promote it to a foreign method
- **Extract Class** - groups accumulated foreign methods into a dedicated utility class
- **Introduce Parameter Object** - groups related foreign method parameters
- **Adapter Pattern** - wraps a foreign class for interface compatibility
- **Decorator Pattern** - adds behavior at runtime without modifying the original class

## Common pitfalls

1. **Accumulation** - too many foreign methods means you need a wrapper class
2. **Wrong target** - if you can change the class, change it; do not create a workaround
3. **Vague naming** - name foreign methods so readers see they extend external functionality
4. **Missing rationale** - document why the method exists as a foreign extension
5. **Overuse of statics** - consider instance methods or a wrapper class for readability

## Examples in other languages

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

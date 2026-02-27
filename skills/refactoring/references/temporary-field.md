# Temporary Field

## Overview

A Temporary Field is a class attribute that only receives a value under certain circumstances, remaining empty or null most of the time. This creates confusion about the object's intended purpose and state consistency, making the code harder to understand and maintain.

## Why It's a Problem

Temporary fields typically appear when developers avoid lengthy parameter lists by storing intermediate algorithm data as class fields. This approach trades parameter clarity for state confusion:

- **Obscured Intent**: The class's purpose becomes unclear when fields don't always contain meaningful data
- **Confusing State**: Developers expect fields to hold persistent data, not temporary algorithm values
- **Hidden Dependencies**: The relationship between the temporary field and specific code paths remains implicit
- **Maintenance Burden**: Future modifications risk breaking the undocumented contract of when fields should contain values

## Signs and Symptoms

- Fields populated only within specific methods or execution paths
- Instance variables that frequently remain null or empty
- Conditional checks throughout code verifying field initialization
- Comments explaining when a field will actually contain data
- Object state inconsistency based on which methods were invoked
- Difficulty understanding what an object represents at any given time

## Before/After Examples

**Before** — Temporary field for calculation intermediate values:

```php
<?php

declare(strict_types=1);

final class UserReportGenerator
{
    private ?string $tempStartDate = null;
    private ?string $tempEndDate = null;
    private array $tempResults = [];

    public function generateReport(string $userId): string
    {
        $this->tempStartDate = date('Y-m-01');
        $this->tempEndDate = date('Y-m-t');
        $this->tempResults = [];

        $user = User::find($userId);
        $data = $this->fetchData();

        return $this->formatReport($user, $data);
    }

    private function fetchData(): array
    {
        // Depends on tempStartDate and tempEndDate being set
        return Database::query(
            "SELECT * FROM transactions WHERE date BETWEEN ? AND ?",
            [$this->tempStartDate, $this->tempEndDate]
        );
    }

    private function formatReport(User $user, array $data): string
    {
        // Uses tempResults
        $this->tempResults = array_map(fn($row) => $row['amount'], $data);
        return "Report: " . json_encode($this->tempResults);
    }
}
```

**After** — Extract into method object with clear purpose:

```php
<?php

declare(strict_types=1);

final readonly class ReportDateRange
{
    public function __construct(
        public string $startDate,
        public string $endDate,
    ) {}

    public static function currentMonth(): self
    {
        return new self(
            startDate: date('Y-m-01'),
            endDate: date('Y-m-t'),
        );
    }
}

final readonly class MonthlyTransactionQuery
{
    public function __construct(
        private ReportDateRange $dateRange,
    ) {}

    public function execute(string $userId): array
    {
        return Database::query(
            "SELECT * FROM transactions WHERE user_id = ? AND date BETWEEN ? AND ?",
            [$userId, $this->dateRange->startDate, $this->dateRange->endDate]
        );
    }
}

final readonly class UserReportFormatter
{
    public function format(User $user, array $transactions): string
    {
        $amounts = array_map(fn($row) => $row['amount'], $transactions);
        return sprintf("Report for %s: %s", $user->name, json_encode($amounts));
    }
}

final class UserReportGenerator
{
    public function generateReport(string $userId): string
    {
        $user = User::find($userId);
        $dateRange = ReportDateRange::currentMonth();

        $query = new MonthlyTransactionQuery($dateRange);
        $transactions = $query->execute($userId);

        $formatter = new UserReportFormatter();
        return $formatter->format($user, $transactions);
    }
}
```

## Recommended Refactorings

**1. Extract Method Object**
Move the temporary field and related operations into a separate class. This creates a dedicated object with a clear purpose, eliminating the hidden state within the original class.

**2. Introduce Parameter Object**
Group temporary fields into a data transfer object or value object that explicitly represents what the method needs. Pass this as a parameter rather than storing it as instance state.

**3. Replace with Null Object Pattern**
If the field is primarily checked for null existence, create a Null Object that implements expected interfaces, eliminating conditional checks throughout the code.

**4. Extract to Private Helper Method**
For simple cases, convert the method using temporary fields into smaller, focused methods that accept parameters instead of relying on mutable state.

## Exceptions

Temporary fields are occasionally acceptable when:

- **Performance-Critical Caching**: Temporarily storing query results within a transaction scope for reuse during complex operations
- **Builder Pattern**: Accumulating state during object construction (acceptable because intent is explicit)
- **Transaction Processing**: Holding intermediate state during a discrete transaction that must be atomic
- **Short-Lived Objects**: Using temporary fields in objects designed to be instantiated, used once, then discarded

In these cases, clearly document the temporary nature and usage scope.

## Related Smells

- **Long Parameter List**: Often the root cause—temporary fields replace parameter passing
- **Message Chain**: Hidden temporary state can mask complex object collaborations
- **Data Clumps**: Temporary fields often group together and could become a dedicated class
- **Primitive Obsession**: Temporary state using primitives instead of meaningful objects

## Refactoring.guru Guidance

### Signs and Symptoms
Temporary fields get their values (and thus are needed by objects) only under certain circumstances. Outside of these circumstances, they are empty. This causes confusion because developers expect object data to be consistently populated.

### Reasons for the Problem
Temporary fields typically arise when algorithms require numerous inputs. Rather than creating extensive method parameters, programmers add fields to the class for this data. The fields serve the algorithm but remain unused otherwise, making code difficult to comprehend.

### Treatment
- **Extract Class**: Move temporary fields and their associated code into a separate class, effectively creating a method object
- **Introduce Null Object**: Integrate a null object to replace conditional code that checks whether temporary field values exist

### Payoff
- Better code clarity and organization

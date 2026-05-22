# Temporary Field

## Overview

A Temporary Field is an instance variable that only holds a meaningful value during specific execution paths, sitting empty or null the rest of the time. This makes the object's state unpredictable - readers expect every field on a class to be relevant to the object's identity, not to serve as scratch space for a single algorithm.

## Why It's a Problem

Temporary fields usually appear when a developer avoids a long parameter list by stashing intermediate computation data into class-level fields. The result is a trade-off that sacrifices clarity for convenience:

- **Unclear Purpose**: The class becomes harder to understand when some fields are only meaningful under certain conditions
- **Misleading State**: Developers naturally assume all fields represent persistent, meaningful data - temporary algorithm storage violates that expectation
- **Implicit Coupling**: The dependency between the temporary field and the specific code path that populates it remains undocumented and fragile
- **Fragile Maintenance**: Future changes risk breaking the unwritten rules about when fields are valid, especially when algorithms requiring numerous inputs evolve independently

## Signs and Symptoms

- Fields that are only populated inside specific methods or conditional branches
- Instance variables that are null or empty during most of the object's lifetime
- Null-checking scattered throughout the code to guard against uninitialized fields
- Comments explaining the conditions under which a field will actually contain data
- Object behavior that varies depending on which methods have been called previously
- Difficulty describing what the object represents at any arbitrary point in time

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

- **Long Parameter List**: Frequently the root cause - temporary fields are introduced specifically to avoid passing many parameters
- **Message Chain**: Hidden temporary state can obscure complex object collaborations happening behind the scenes
- **Data Clumps**: Temporary fields that appear together are strong candidates for extraction into a dedicated class
- **Primitive Obsession**: Temporary state stored as raw primitives rather than meaningful objects

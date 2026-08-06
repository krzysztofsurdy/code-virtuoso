# Temporary Field

## Contents

- [Overview](#overview)
- [Why it's a problem](#why-its-a-problem)
- [Signs and symptoms](#signs-and-symptoms)
- [Before/After Examples](#beforeafter-examples)
- [Recommended refactorings](#recommended-refactorings)
- [Exceptions](#exceptions)
- [Related smells](#related-smells)

## Overview

A Temporary Field is an instance variable that holds a meaningful value only on certain execution paths and sits empty or null the rest of the time. This makes the object's state unpredictable. Readers expect every field on a class to relate to the object's identity, not to act as scratch space for one algorithm.

## Why it's a problem

Temporary fields usually appear when a developer avoids a long parameter list by stashing intermediate data in class-level fields. This trades clarity for convenience:

- **Unclear purpose**: the class is harder to understand when some fields matter only under certain conditions.
- **Misleading state**: developers assume all fields hold persistent, meaningful data. Temporary algorithm storage breaks that expectation.
- **Implicit coupling**: the dependency between the temporary field and the code path that fills it is undocumented and fragile.
- **Fragile maintenance**: future changes can break the unwritten rules about when fields are valid, especially when algorithms with many inputs evolve on their own.

## Signs and symptoms

- Fields that are populated only inside specific methods or conditional branches.
- Instance variables that are null or empty for most of the object's lifetime.
- Null checks scattered through the code to guard against uninitialized fields.
- Comments explaining when a field will actually contain data.
- Object behavior that depends on which methods were called earlier.
- Difficulty describing what the object represents at an arbitrary point in time.

## Before/After Examples

**Before**: temporary fields hold intermediate calculation values.

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

**After**: the data moves into small objects with clear purposes.

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

## Recommended refactorings

**1. Extract Method Object**
Move the temporary field and the related operations into a separate class. The new object has a clear purpose, and the hidden state leaves the original class.

**2. Introduce Parameter Object**
Group temporary fields into a data transfer object or value object that states what the method needs. Pass it as a parameter instead of storing it as instance state.

**3. Replace with Null Object**
If the field is mostly checked for null, create a Null Object that implements the expected interface. The conditional checks then go away.

**4. Extract to private helper methods**
For simple cases, split the method that uses temporary fields into smaller methods that take parameters and do not rely on mutable state.

## Exceptions

Temporary fields are sometimes acceptable:

- **Performance-critical caching**: storing query results within a transaction scope for reuse during a complex operation.
- **Builder pattern**: accumulating state during object construction (acceptable because the intent is explicit).
- **Transaction processing**: holding intermediate state during a discrete transaction that must be atomic.
- **Short-lived objects**: objects designed to be created, used once, and discarded.

In these cases, document the temporary nature and the usage scope.

## Related smells

- **Long Parameter List**: often the root cause. Temporary fields are introduced to avoid passing many parameters.
- **Message Chain**: hidden temporary state can obscure complex object collaborations.
- **Data Clumps**: temporary fields that appear together are good candidates for extraction into their own class.
- **Primitive Obsession**: temporary state stored as raw primitives instead of meaningful objects.

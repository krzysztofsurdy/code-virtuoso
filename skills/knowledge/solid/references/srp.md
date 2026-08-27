# Single Responsibility Principle (SRP)

## Contents

- [Definition](#definition)
- [Why it matters](#why-it-matters)
- [Detecting violations](#detecting-violations)
- [Before/After: PHP 8.3+](#beforeafter-php-83)
- [Before/After: real-world scenario, invoice processing](#beforeafter-real-world-scenario-invoice-processing)
- [Examples in other languages](#examples-in-other-languages)
- [Common pitfalls](#common-pitfalls)
- [Related principles](#related-principles)

## Definition

Every class should be accountable for exactly one aspect of the system's functionality. That aspect should be fully contained in the class, and the class should have no other obligations.

In Robert C. Martin's framing, "responsibility" means "a reason for change." If you can name several independent reasons to modify a class, it has more than one responsibility.

## Why it matters

When one class handles several concerns, a change to one concern can break another. The code becomes brittle, with unrelated features tied together through shared internal state. SRP confines each class to a single dimension of change.

**Advantages of following SRP:**
- Changes stay contained: updating the notification system does not put the business rules at risk
- Naming is easier: difficulty choosing a class name often signals that the class does too much
- Testing is more targeted: each class has a small, verifiable contract
- Reuse is easier: narrowly focused classes fit into other contexts
- Parallel development is easier: separate responsibilities live in separate files, which reduces merge conflicts

## Detecting violations

Watch for these indicators:

- **Class name contains "And" or "Manager"**: `UserAndEmailManager` is a clear sign of bundled concerns
- **Methods that operate on disjoint subsets of fields**: when half the methods never touch half the properties, the class likely merges two concerns
- **Unrelated imports**: a class that pulls in both persistence drivers and email libraries probably does too much
- **Excessive line count**: not definitive, but classes over 200-300 lines often break SRP
- **Changes driven by different stakeholders**: when marketing and operations both trigger edits to the same file, responsibilities are mixed

## Before/After: PHP 8.3+

### Before: Report class handles data, formatting, and delivery

```php
<?php

declare(strict_types=1);

final class SalesReport
{
    public function gatherData(DateTimeImmutable $from, DateTimeImmutable $to): array
    {
        // Queries database for sales in date range
        return DB::query(
            'SELECT * FROM sales WHERE created_at BETWEEN ? AND ?',
            [$from->format('Y-m-d'), $to->format('Y-m-d')]
        );
    }

    public function formatAsHtml(array $data): string
    {
        $html = '<table>';
        foreach ($data as $row) {
            $html .= "<tr><td>{$row['product']}</td><td>{$row['amount']}</td></tr>";
        }
        return $html . '</table>';
    }

    public function formatAsCsv(array $data): string
    {
        $lines = ['product,amount'];
        foreach ($data as $row) {
            $lines[] = "{$row['product']},{$row['amount']}";
        }
        return implode("\n", $lines);
    }

    public function sendByEmail(string $to, string $content): void
    {
        mail($to, 'Sales Report', $content);
    }

    public function saveToDisk(string $path, string $content): void
    {
        file_put_contents($path, $content);
    }
}
```

This class has **three** reasons to change: data retrieval logic, output formatting, and delivery mechanism.

### After: each concern in its own class

```php
<?php

declare(strict_types=1);

final readonly class SalesDataRepository
{
    public function fetchByDateRange(DateTimeImmutable $from, DateTimeImmutable $to): array
    {
        return DB::query(
            'SELECT * FROM sales WHERE created_at BETWEEN ? AND ?',
            [$from->format('Y-m-d'), $to->format('Y-m-d')]
        );
    }
}

interface ReportFormatter
{
    public function format(array $data): string;
}

final readonly class HtmlReportFormatter implements ReportFormatter
{
    public function format(array $data): string
    {
        $html = '<table>';
        foreach ($data as $row) {
            $html .= "<tr><td>{$row['product']}</td><td>{$row['amount']}</td></tr>";
        }
        return $html . '</table>';
    }
}

final readonly class CsvReportFormatter implements ReportFormatter
{
    public function format(array $data): string
    {
        $lines = ['product,amount'];
        foreach ($data as $row) {
            $lines[] = "{$row['product']},{$row['amount']}";
        }
        return implode("\n", $lines);
    }
}

interface ReportDelivery
{
    public function deliver(string $content): void;
}

final readonly class EmailReportDelivery implements ReportDelivery
{
    public function __construct(private string $recipient) {}

    public function deliver(string $content): void
    {
        mail($this->recipient, 'Sales Report', $content);
    }
}

final readonly class FileReportDelivery implements ReportDelivery
{
    public function __construct(private string $path) {}

    public function deliver(string $content): void
    {
        file_put_contents($this->path, $content);
    }
}
```

Now each class changes for exactly one reason. Adding PDF formatting or Slack delivery requires no changes to existing classes.

## Before/After: real-world scenario, invoice processing

### Before: Invoice class validates, calculates, persists, and notifies

```php
<?php

declare(strict_types=1);

final class Invoice
{
    public function process(array $lineItems, string $customerEmail): void
    {
        // Validation
        if (empty($lineItems)) {
            throw new InvalidArgumentException('Invoice must have at least one line item');
        }

        // Calculation
        $subtotal = 0;
        foreach ($lineItems as $item) {
            $subtotal += $item['qty'] * $item['price'];
        }
        $tax = $subtotal * 0.21;
        $total = $subtotal + $tax;

        // Persistence
        DB::insert('invoices', [
            'subtotal' => $subtotal,
            'tax' => $tax,
            'total' => $total,
            'created_at' => date('Y-m-d H:i:s'),
        ]);

        // Notification
        mail($customerEmail, 'Your Invoice', "Total: $total");
    }
}
```

### After: separated responsibilities

```php
<?php

declare(strict_types=1);

final readonly class InvoiceCalculator
{
    private const float TAX_RATE = 0.21;

    public function calculate(array $lineItems): InvoiceTotals
    {
        if (empty($lineItems)) {
            throw new InvalidArgumentException('Invoice must have at least one line item');
        }

        $subtotal = array_sum(
            array_map(fn(array $item) => $item['qty'] * $item['price'], $lineItems)
        );

        return new InvoiceTotals(
            subtotal: $subtotal,
            tax: $subtotal * self::TAX_RATE,
        );
    }
}

final readonly class InvoiceTotals
{
    public readonly float $total;

    public function __construct(
        public float $subtotal,
        public float $tax,
    ) {
        $this->total = $this->subtotal + $this->tax;
    }
}

final readonly class InvoiceRepository
{
    public function save(InvoiceTotals $totals): void
    {
        DB::insert('invoices', [
            'subtotal' => $totals->subtotal,
            'tax' => $totals->tax,
            'total' => $totals->total,
            'created_at' => date('Y-m-d H:i:s'),
        ]);
    }
}

final readonly class InvoiceNotifier
{
    public function notifyCustomer(string $email, InvoiceTotals $totals): void
    {
        mail($email, 'Your Invoice', "Total: {$totals->total}");
    }
}
```

## Examples in Other Languages

### Java

**Before:**

```java
public class Employee {
    private String name;
    private double salary;

    public Employee(String name, double salary) {
        this.name = name;
        this.salary = salary;
    }

    // Business logic
    public double calculateBonus() {
        return salary * 0.1;
    }

    // Persistence concern
    public void saveToDatabase() {
        DatabaseConnection db = new DatabaseConnection();
        db.execute("INSERT INTO employees (name, salary) VALUES (?, ?)", name, salary);
    }

    // Presentation concern
    public String generatePaySlip() {
        return String.format("Pay slip for %s: Salary=%.2f, Bonus=%.2f",
            name, salary, calculateBonus());
    }
}
```

**After:**

```java
public record Employee(String name, double salary) {
    public double calculateBonus() {
        return salary * 0.1;
    }
}

public class EmployeeRepository {
    private final DatabaseConnection db;

    public EmployeeRepository(DatabaseConnection db) {
        this.db = db;
    }

    public void save(Employee employee) {
        db.execute("INSERT INTO employees (name, salary) VALUES (?, ?)",
            employee.name(), employee.salary());
    }
}

public class PaySlipGenerator {
    public String generate(Employee employee) {
        return String.format("Pay slip for %s: Salary=%.2f, Bonus=%.2f",
            employee.name(), employee.salary(), employee.calculateBonus());
    }
}
```

### Python

**Before:**

```python
class TaskManager:
    def __init__(self):
        self.tasks = []

    def add_task(self, title: str, priority: int) -> None:
        self.tasks.append({"title": title, "priority": priority, "done": False})

    def complete_task(self, title: str) -> None:
        for task in self.tasks:
            if task["title"] == title:
                task["done"] = True

    # Persistence: different reason to change
    def save_to_file(self, path: str) -> None:
        import json
        with open(path, "w") as f:
            json.dump(self.tasks, f)

    # Display: yet another reason to change
    def print_report(self) -> None:
        for task in self.tasks:
            status = "DONE" if task["done"] else "TODO"
            print(f"[{status}] {task['title']} (priority: {task['priority']})")
```

**After:**

```python
from dataclasses import dataclass, field


@dataclass
class TaskList:
    tasks: list[dict] = field(default_factory=list)

    def add(self, title: str, priority: int) -> None:
        self.tasks.append({"title": title, "priority": priority, "done": False})

    def complete(self, title: str) -> None:
        for task in self.tasks:
            if task["title"] == title:
                task["done"] = True


class TaskFileStorage:
    def save(self, tasks: TaskList, path: str) -> None:
        import json
        with open(path, "w") as f:
            json.dump(tasks.tasks, f)


class TaskReportPrinter:
    def print_report(self, tasks: TaskList) -> None:
        for task in tasks.tasks:
            status = "DONE" if task["done"] else "TODO"
            print(f"[{status}] {task['title']} (priority: {task['priority']})")
```

### TypeScript

**Before:**

```typescript
class BlogPost {
  constructor(
    private title: string,
    private content: string,
  ) {}

  // Content concern
  getWordCount(): number {
    return this.content.split(/\s+/).length;
  }

  // Serialization concern
  toJson(): string {
    return JSON.stringify({ title: this.title, content: this.content });
  }

  // Validation concern
  validate(): string[] {
    const errors: string[] = [];
    if (this.title.length === 0) errors.push("Title is required");
    if (this.content.length < 100) errors.push("Content too short");
    return errors;
  }
}
```

**After:**

```typescript
class BlogPost {
  constructor(
    readonly title: string,
    readonly content: string,
  ) {}

  getWordCount(): number {
    return this.content.split(/\s+/).length;
  }
}

class BlogPostSerializer {
  toJson(post: BlogPost): string {
    return JSON.stringify({ title: post.title, content: post.content });
  }
}

class BlogPostValidator {
  validate(post: BlogPost): string[] {
    const errors: string[] = [];
    if (post.title.length === 0) errors.push("Title is required");
    if (post.content.length < 100) errors.push("Content too short");
    return errors;
  }
}
```

### C++

**Before:**

```cpp
#include <string>
#include <fstream>
#include <iostream>

class Sensor {
    std::string name;
    double reading;

public:
    Sensor(std::string name) : name(std::move(name)), reading(0.0) {}

    void takeReading(double value) { reading = value; }
    double getReading() const { return reading; }

    // Logging concern
    void logToFile(const std::string& path) {
        std::ofstream file(path, std::ios::app);
        file << name << ": " << reading << "\n";
    }

    // Alert concern
    void checkThreshold(double max) {
        if (reading > max) {
            std::cout << "ALERT: " << name << " exceeded " << max << "\n";
        }
    }
};
```

**After:**

```cpp
#include <string>
#include <fstream>
#include <iostream>

class Sensor {
    std::string name;
    double reading;

public:
    Sensor(std::string name) : name(std::move(name)), reading(0.0) {}

    void takeReading(double value) { reading = value; }
    [[nodiscard]] double getReading() const { return reading; }
    [[nodiscard]] const std::string& getName() const { return name; }
};

class SensorLogger {
public:
    void log(const Sensor& sensor, const std::string& path) {
        std::ofstream file(path, std::ios::app);
        file << sensor.getName() << ": " << sensor.getReading() << "\n";
    }
};

class ThresholdAlert {
public:
    void check(const Sensor& sensor, double max) {
        if (sensor.getReading() > max) {
            std::cout << "ALERT: " << sensor.getName()
                      << " exceeded " << max << "\n";
        }
    }
};
```

## Common pitfalls

- **Over-splitting**: Do not create one class per method. SRP groups related methods that share a single *reason to change*.
- **Confusing "responsibility" with "action"**: A `UserRepository` that performs CRUD operations is valid, because every method changes for the same reason (the persistence strategy).
- **God service classes**: Names like `ApplicationService` or `UtilityHelper` are warning signs. They tend to accumulate unrelated logic over time.

## Related principles

- **Interface Segregation (ISP)**: applies the same single-focus idea at the interface level
- **Separation of Concerns**: a broader architectural guideline that SRP applies at the class level
- **Cohesion**: SRP drives high cohesion by keeping related behavior together

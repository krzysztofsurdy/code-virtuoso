# Single Responsibility Principle (SRP)

## Definition

A class should have one, and only one, reason to change. Every module or class should own a single part of the functionality provided by the software, and that responsibility should be entirely encapsulated by the class.

Robert C. Martin defines "responsibility" as "a reason for change." If you can think of more than one motive for changing a class, then that class has more than one responsibility.

## Why It Matters

When a class handles multiple concerns, changes to one concern risk breaking the other. This creates fragile code where unrelated features are coupled through shared state and methods. SRP reduces this coupling by ensuring each class focuses on a single axis of change.

**Benefits of applying SRP:**
- Changes are localized — modifying logging doesn't risk breaking business logic
- Classes become easier to name — if naming is hard, the class probably does too much
- Testing is simpler — each class has a clear, testable contract
- Reuse improves — focused classes are more likely to be useful elsewhere
- Teams can work in parallel — different responsibilities live in different files

## Detecting Violations

Look for these warning signs:

- **Class name includes "And" or "Manager"** — `UserAndEmailManager` screams multiple responsibilities
- **Methods that don't use the same fields** — if half the methods ignore half the properties, the class likely bundles two concerns
- **Unrelated imports** — a class importing both database drivers and email libraries probably does too much
- **Long class files** — not a guarantee, but classes exceeding 200-300 lines often violate SRP
- **Change frequency from different sources** — if marketing requests change the same file as infrastructure requests, SRP is violated

## Before/After — PHP 8.3+

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

### After: Each concern in its own class

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

Now each class changes for exactly one reason. Adding PDF formatting or Slack delivery requires zero changes to existing classes.

## Before/After — Real-World Scenario: Invoice Processing

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

### After: Separated responsibilities

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

    # Persistence — different reason to change
    def save_to_file(self, path: str) -> None:
        import json
        with open(path, "w") as f:
            json.dump(self.tasks, f)

    # Display — yet another reason to change
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

## Common Pitfalls

- **Over-splitting**: Don't create a class per method. SRP groups related methods under one *reason to change*, not one method per class.
- **Confusing "responsibility" with "action"**: A `UserRepository` doing CRUD is fine — all those methods change for the same reason (persistence strategy).
- **God service classes**: `ApplicationService` or `UtilityHelper` are red flags — they accumulate unrelated logic over time.

## Related Principles

- **Interface Segregation (ISP)** — applies SRP at the interface level
- **Separation of Concerns** — a broader architectural principle that SRP implements at the class level
- **Cohesion** — SRP maximizes cohesion by keeping related functionality together

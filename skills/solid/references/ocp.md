# Open/Closed Principle (OCP)

## Definition

Software entities (classes, modules, functions) should be open for extension but closed for modification. You should be able to add new behavior to a system without altering existing, tested code.

Bertrand Meyer originally formulated this principle, and Robert C. Martin later refined it for object-oriented design. The key insight: changing working code introduces risk. Instead, design systems so new requirements are met by writing *new* code that plugs into existing structures.

## Why It Matters

Every time you modify existing code to add a feature, you risk breaking something that already works. OCP pushes you toward designs where:

- **New features = new code** — existing classes remain untouched
- **Testing burden stays low** — you only test new additions, not re-test everything
- **Deployment risk decreases** — unchanged modules don't need re-deployment
- **Parallel development improves** — teams add features independently without merge conflicts

## Detecting Violations

Signs that OCP is being violated:

- **Growing switch/match statements** — adding a new type means adding another case
- **If-else chains based on type** — `if ($shape instanceof Circle)` scattered everywhere
- **Shotgun surgery** — adding one feature touches 5+ files
- **"Just add another case" mentality** — the pattern of extending by editing
- **Fear of changing existing code** — indicates the design doesn't support safe extension

## Before/After — PHP 8.3+

### Before: Adding a new shape requires modifying AreaCalculator

```php
<?php

declare(strict_types=1);

final readonly class Rectangle
{
    public function __construct(
        public float $width,
        public float $height,
    ) {}
}

final readonly class Circle
{
    public function __construct(public float $radius) {}
}

final class AreaCalculator
{
    public function totalArea(array $shapes): float
    {
        $total = 0.0;

        foreach ($shapes as $shape) {
            if ($shape instanceof Rectangle) {
                $total += $shape->width * $shape->height;
            } elseif ($shape instanceof Circle) {
                $total += M_PI * $shape->radius ** 2;
            }
            // Adding Triangle means editing THIS method
        }

        return $total;
    }
}
```

### After: New shapes extend without modifying existing code

```php
<?php

declare(strict_types=1);

interface Shape
{
    public function area(): float;
}

final readonly class Rectangle implements Shape
{
    public function __construct(
        public float $width,
        public float $height,
    ) {}

    public function area(): float
    {
        return $this->width * $this->height;
    }
}

final readonly class Circle implements Shape
{
    public function __construct(public float $radius) {}

    public function area(): float
    {
        return M_PI * $this->radius ** 2;
    }
}

// Adding a new shape requires ZERO changes to existing code
final readonly class Triangle implements Shape
{
    public function __construct(
        public float $base,
        public float $height,
    ) {}

    public function area(): float
    {
        return 0.5 * $this->base * $this->height;
    }
}

final class AreaCalculator
{
    /** @param Shape[] $shapes */
    public function totalArea(array $shapes): float
    {
        return array_sum(array_map(fn(Shape $s) => $s->area(), $shapes));
    }
}
```

### Real-World Example: Notification System

**Before — adding a channel means editing the notifier:**

```php
<?php

declare(strict_types=1);

final class Notifier
{
    public function send(string $message, string $channel): void
    {
        match ($channel) {
            'email' => $this->sendEmail($message),
            'sms' => $this->sendSms($message),
            'slack' => $this->sendSlack($message),
            // Every new channel = edit this class
        };
    }

    private function sendEmail(string $message): void { /* ... */ }
    private function sendSms(string $message): void { /* ... */ }
    private function sendSlack(string $message): void { /* ... */ }
}
```

**After — new channels are added by creating new classes:**

```php
<?php

declare(strict_types=1);

interface NotificationChannel
{
    public function send(string $message): void;
}

final readonly class EmailChannel implements NotificationChannel
{
    public function send(string $message): void
    {
        // Send via email API
    }
}

final readonly class SmsChannel implements NotificationChannel
{
    public function send(string $message): void
    {
        // Send via SMS gateway
    }
}

final readonly class SlackChannel implements NotificationChannel
{
    public function send(string $message): void
    {
        // Send via Slack webhook
    }
}

final readonly class Notifier
{
    /** @param NotificationChannel[] $channels */
    public function __construct(private array $channels) {}

    public function notify(string $message): void
    {
        foreach ($this->channels as $channel) {
            $channel->send($message);
        }
    }
}

// Adding PushNotificationChannel requires ZERO edits to existing code
```

## Techniques for Achieving OCP

1. **Strategy Pattern** — inject different algorithms via interfaces
2. **Template Method** — define skeleton in base class, let subclasses fill in steps
3. **Decorator Pattern** — wrap existing behavior with additional features
4. **Plugin Architecture** — load extensions dynamically
5. **Event/Observer Pattern** — let new listeners react to existing events

## Examples in Other Languages

### Java

**Before:**

```java
public class TaxCalculator {
    public double calculate(String country, double amount) {
        return switch (country) {
            case "US" -> amount * 0.07;
            case "UK" -> amount * 0.20;
            case "DE" -> amount * 0.19;
            // Must edit to add new countries
            default -> throw new IllegalArgumentException("Unknown country: " + country);
        };
    }
}
```

**After:**

```java
public interface TaxStrategy {
    double calculate(double amount);
}

public record UsTax() implements TaxStrategy {
    @Override
    public double calculate(double amount) { return amount * 0.07; }
}

public record UkTax() implements TaxStrategy {
    @Override
    public double calculate(double amount) { return amount * 0.20; }
}

public record GermanTax() implements TaxStrategy {
    @Override
    public double calculate(double amount) { return amount * 0.19; }
}

public class TaxCalculator {
    private final TaxStrategy strategy;

    public TaxCalculator(TaxStrategy strategy) {
        this.strategy = strategy;
    }

    public double calculate(double amount) {
        return strategy.calculate(amount);
    }
}
```

### Python

**Before:**

```python
class ReportExporter:
    def export(self, data: list[dict], format_type: str) -> str:
        if format_type == "json":
            import json
            return json.dumps(data)
        elif format_type == "csv":
            header = ",".join(data[0].keys())
            rows = [",".join(str(v) for v in row.values()) for row in data]
            return "\n".join([header] + rows)
        elif format_type == "xml":
            # Must edit class to add new format
            ...
        raise ValueError(f"Unknown format: {format_type}")
```

**After:**

```python
from abc import ABC, abstractmethod
import json


class ExportFormat(ABC):
    @abstractmethod
    def export(self, data: list[dict]) -> str: ...


class JsonExport(ExportFormat):
    def export(self, data: list[dict]) -> str:
        return json.dumps(data, indent=2)


class CsvExport(ExportFormat):
    def export(self, data: list[dict]) -> str:
        header = ",".join(data[0].keys())
        rows = [",".join(str(v) for v in row.values()) for row in data]
        return "\n".join([header] + rows)


class ReportExporter:
    def __init__(self, fmt: ExportFormat) -> None:
        self._fmt = fmt

    def export(self, data: list[dict]) -> str:
        return self._fmt.export(data)


# Adding XmlExport requires no changes to existing classes
```

### TypeScript

**Before:**

```typescript
class PriceCalculator {
  calculate(product: Product, promoType: string): number {
    switch (promoType) {
      case "none":
        return product.price;
      case "percentage":
        return product.price * 0.9;
      case "bogo":
        return product.price / 2;
      default:
        throw new Error(`Unknown promo: ${promoType}`);
    }
  }
}
```

**After:**

```typescript
interface PricingRule {
  apply(price: number): number;
}

class NoPricing implements PricingRule {
  apply(price: number): number {
    return price;
  }
}

class PercentageDiscount implements PricingRule {
  constructor(private discount: number) {}
  apply(price: number): number {
    return price * (1 - this.discount);
  }
}

class BuyOneGetOneFree implements PricingRule {
  apply(price: number): number {
    return price / 2;
  }
}

class PriceCalculator {
  constructor(private rule: PricingRule) {}

  calculate(product: Product): number {
    return this.rule.apply(product.price);
  }
}
```

### C++

**Before:**

```cpp
#include <string>
#include <stdexcept>

class Logger {
public:
    void log(const std::string& message, const std::string& dest) {
        if (dest == "console") {
            std::cout << "[LOG] " << message << "\n";
        } else if (dest == "file") {
            // write to file...
        } else if (dest == "network") {
            // send over network...
        } else {
            throw std::invalid_argument("Unknown destination");
        }
    }
};
```

**After:**

```cpp
#include <string>
#include <memory>
#include <iostream>
#include <fstream>

class LogDestination {
public:
    virtual ~LogDestination() = default;
    virtual void write(const std::string& message) = 0;
};

class ConsoleLog : public LogDestination {
public:
    void write(const std::string& message) override {
        std::cout << "[LOG] " << message << "\n";
    }
};

class FileLog : public LogDestination {
    std::ofstream file;
public:
    explicit FileLog(const std::string& path) : file(path, std::ios::app) {}
    void write(const std::string& message) override {
        file << "[LOG] " << message << "\n";
    }
};

class Logger {
    std::unique_ptr<LogDestination> dest;
public:
    explicit Logger(std::unique_ptr<LogDestination> dest)
        : dest(std::move(dest)) {}

    void log(const std::string& message) {
        dest->write(message);
    }
};
```

## Common Pitfalls

- **Speculative generality** — Don't abstract prematurely. Wait until you actually need a second implementation before creating an interface.
- **Over-engineering** — A simple helper function doesn't need a plugin architecture. Apply OCP where change is *likely*.
- **Leaky abstractions** — If every new implementation requires changes to the interface, the abstraction boundary is wrong.

## Related Principles

- **Strategy Pattern** — the most common way to implement OCP
- **Liskov Substitution (LSP)** — subtypes must be usable through the base interface for OCP to work
- **Dependency Inversion (DIP)** — abstractions that enable extension are the same abstractions DIP demands

# Open/Closed Principle (OCP)

## Contents

- [Definition](#definition)
- [Why it matters](#why-it-matters)
- [Detecting violations](#detecting-violations)
- [Before/After: PHP 8.3+](#beforeafter-php-83)
- [Techniques for achieving OCP](#techniques-for-achieving-ocp)
- [Examples in other languages](#examples-in-other-languages)
- [Common pitfalls](#common-pitfalls)
- [Related principles](#related-principles)

## Definition

Software entities (classes, modules, functions) should be open to extension and closed to modification. It should be possible to add new behavior without changing existing, already-tested code.

Bertrand Meyer first described this principle, and Robert C. Martin later adapted it for object-oriented design. Modifying working code carries risk. Design systems so that new requirements are met by writing *new* code that plugs into existing structures.

## Why it matters

Each time you edit existing code to add a feature, you risk breaking something that already works. OCP pushes you toward designs where:

- **New features mean new code**: existing classes stay untouched
- **Testing overhead stays manageable**: you validate only the new additions rather than re-verifying the whole system
- **Deployment risk drops**: modules that have not changed need no redeployment
- **Teams can work concurrently**: developers add features independently without stepping on each other

## Detecting violations

Indicators that OCP is not being followed:

- **Growing switch/match blocks**: a new type means appending another case
- **If-else chains based on type**: `if ($shape instanceof Circle)` scattered throughout the codebase
- **Shotgun surgery**: a single feature requires touching five or more files
- **The "just add another case" habit**: extending functionality by editing existing code
- **Reluctance to touch existing code**: this suggests the design does not support safe extension

## Before/After: PHP 8.3+

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

### After: new shapes extend without modifying existing code

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

### Real-world example: notification system

**Before: adding a channel means editing the notifier:**

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

**After: new channels are added by creating new classes:**

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

## Techniques for achieving OCP

1. **Strategy Pattern**: inject interchangeable algorithms through interfaces
2. **Template Method**: define the algorithm skeleton in a base class and let subclasses fill in the specifics
3. **Decorator Pattern**: layer additional behavior on top of existing objects
4. **Plugin architecture**: discover and load extensions at runtime
5. **Event/Observer Pattern**: let new listeners respond to existing events without touching the event source

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

## Common pitfalls

- **Speculative generality**: Do not abstract too early. Wait until a second implementation is needed before extracting an interface.
- **Over-engineering**: A plain helper function does not need a plugin architecture. Reserve OCP for areas where change is *probable*.
- **Leaky abstractions**: If every new implementation forces changes to the interface itself, the abstraction boundary is in the wrong place.

## Related principles

- **Strategy Pattern**: the most common technique for achieving OCP
- **Liskov Substitution (LSP)**: subtypes must behave correctly through the base interface for OCP to work
- **Dependency Inversion (DIP)**: the abstractions that allow extension are the same ones DIP calls for

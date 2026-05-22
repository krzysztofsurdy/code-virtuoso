## Overview

Extract Interface creates a formal contract from a set of methods that multiple clients rely on or that several classes implement in common. Unlike Extract Superclass, which shares both interface and implementation, Extract Interface isolates the contract alone, leaving each implementing class free to provide its own logic.

## Motivation

### Explicit Role Definition
Interfaces declare the roles a class plays in different contexts. Extracting an interface makes that role visible in the type system and defines a clear boundary between what callers can expect and how the class delivers it.

### Pluggable Implementations
When a system needs interchangeable variants - payment gateways, notification channels, storage backends - an interface ensures every variant conforms to the same contract without forcing them into an artificial inheritance tree.

### Dependency Inversion
Clients that depend on an interface rather than a concrete class become insulated from implementation changes. This makes the code easier to test with mocks and more flexible when requirements shift.

## Mechanics

1. **Define the interface** with a name that reflects the responsibility it represents
2. **Declare the methods** that shared clients depend on
3. **Have classes implement** the new interface
4. **Update client type hints** to reference the interface instead of concrete classes
5. **Optional**: Remove the concrete class from client signatures entirely if no class-specific features are needed

## Before/After

### Before

```php
<?php

declare(strict_types=1);

class PaymentProcessor
{
    public function processPayment(float $amount, string $currency): bool
    {
        // Process payment logic
        return true;
    }

    public function refund(string $transactionId, float $amount): bool
    {
        // Refund logic
        return true;
    }
}

class InvoiceService
{
    private PaymentProcessor $processor;

    public function __construct(PaymentProcessor $processor)
    {
        $this->processor = $processor;
    }

    public function createInvoice(float $amount): void
    {
        $this->processor->processPayment($amount, 'USD');
    }
}

class RefundService
{
    private PaymentProcessor $processor;

    public function __construct(PaymentProcessor $processor)
    {
        $this->processor = $processor;
    }

    public function refundTransaction(string $id, float $amount): void
    {
        $this->processor->refund($id, $amount);
    }
}
```

### After

```php
<?php

declare(strict_types=1);

interface PaymentGateway
{
    public function processPayment(float $amount, string $currency): bool;
    public function refund(string $transactionId, float $amount): bool;
}

readonly class PaymentProcessor implements PaymentGateway
{
    public function processPayment(float $amount, string $currency): bool
    {
        // Process payment logic
        return true;
    }

    public function refund(string $transactionId, float $amount): bool
    {
        // Refund logic
        return true;
    }
}

readonly class InvoiceService
{
    public function __construct(private PaymentGateway $gateway) {}

    public function createInvoice(float $amount): void
    {
        $this->gateway->processPayment($amount, 'USD');
    }
}

readonly class RefundService
{
    public function __construct(private PaymentGateway $gateway) {}

    public function refundTransaction(string $id, float $amount): void
    {
        $this->gateway->refund($id, $amount);
    }
}
```

## Benefits

- **Defined Contracts**: Interfaces make explicit what callers are allowed to depend on
- **Simplified Testing**: Mock the interface instead of the concrete class in unit tests
- **Loose Coupling**: Clients are insulated from implementation details
- **Swappable Implementations**: Different concrete classes can be substituted without touching client code
- **Clear Communication**: Interface names and method signatures document the expected behavior
- **Easy Extension**: New implementations can be added without modifying existing code

## When NOT to Use

- **Only one implementation exists**: An interface with a single implementor may be premature abstraction
- **Shared implementation needed**: If classes share code as well as a contract, Extract Superclass is a better fit
- **Interface is too broad**: A large interface with unrelated methods likely violates the Interface Segregation Principle - split it first
- **No evidence of variation**: Do not create interfaces speculatively; wait until a second implementation is needed
- **Artificial abstractions**: An interface should represent a genuine concept, not exist for the sake of having one

## Related Refactorings

- **Extract Superclass**: Shares both contract and implementation between classes
- **Extract Class**: Moves responsibilities to a new class without inheritance
- **Remove Middle Man**: Strips excessive abstraction layers that obscure rather than clarify
- **Interface Segregation**: Splits an overly broad interface into narrower, focused ones

## Examples in Other Languages

### Java

**Before:**

```java
class Employee {
    String getName() { /* ... */ }
    int getRate() { /* ... */ }
    boolean hasSpecialSkill() { /* ... */ }
}

// Client tightly coupled to concrete class
void calculatePay(Employee employee) {
    int rate = employee.getRate();
}
```

**After:**

```java
interface Billable {
    int getRate();
    boolean hasSpecialSkill();
}

class Employee implements Billable {
    String getName() { /* ... */ }
    public int getRate() { /* ... */ }
    public boolean hasSpecialSkill() { /* ... */ }
}

// Client depends on abstraction
void calculatePay(Billable billable) {
    int rate = billable.getRate();
}
```

### C#

**Before:**

```csharp
class Employee
{
    string GetName() { /* ... */ }
    int GetRate() { /* ... */ }
    bool HasSpecialSkill() { /* ... */ }
}
```

**After:**

```csharp
interface IBillable
{
    int GetRate();
    bool HasSpecialSkill();
}

class Employee : IBillable
{
    string GetName() { /* ... */ }
    public int GetRate() { /* ... */ }
    public bool HasSpecialSkill() { /* ... */ }
}
```

### Python

**Before:**

```python
class Employee:
    def get_name(self) -> str:
        # ...

    def get_rate(self) -> int:
        # ...

    def has_special_skill(self) -> bool:
        # ...
```

**After:**

```python
from abc import ABC, abstractmethod

class Billable(ABC):
    @abstractmethod
    def get_rate(self) -> int:
        pass

    @abstractmethod
    def has_special_skill(self) -> bool:
        pass

class Employee(Billable):
    def get_name(self) -> str:
        # ...

    def get_rate(self) -> int:
        # ...

    def has_special_skill(self) -> bool:
        # ...
```

### TypeScript

**Before:**

```typescript
class Employee {
    getName(): string { /* ... */ }
    getRate(): number { /* ... */ }
    hasSpecialSkill(): boolean { /* ... */ }
}
```

**After:**

```typescript
interface Billable {
    getRate(): number;
    hasSpecialSkill(): boolean;
}

class Employee implements Billable {
    getName(): string { /* ... */ }
    getRate(): number { /* ... */ }
    hasSpecialSkill(): boolean { /* ... */ }
}
```

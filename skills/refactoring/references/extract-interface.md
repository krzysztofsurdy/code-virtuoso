## Overview

Extract Interface is a refactoring technique that creates a new interface containing a set of common operations used by multiple clients or shared between different classes. This technique improves code organization by making shared responsibilities explicit and enabling polymorphic behavior without requiring inheritance hierarchies.

Unlike **Extract Superclass**, which consolidates both code and interface, Extract Interface isolates only the common interface contract, leaving duplicate implementation logic intact.

## Motivation

### Explicit Role Definition
Interfaces communicate the specialized roles classes play in different contexts. By extracting an interface, you make code intent clearer and define explicit contracts that other classes must fulfill.

### Multiple Implementations
When designing systems that require pluggable implementations, establishing a common interface ensures all variants conform to the same contract without artificial inheritance relationships.

### Dependency Inversion
Extracting interfaces decouples your code from concrete implementations, allowing clients to depend on abstractions rather than concrete classes. This improves testability and flexibility.

## Mechanics

1. **Create an empty interface** with a descriptive name reflecting the responsibility
2. **Declare common operations** within the interface that shared clients depend on
3. **Configure classes to implement** the new interface
4. **Update client code** to type-hint against the new interface instead of concrete classes
5. **Optional: Rename or remove** the original class if it no longer serves a purpose

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

- **Clearer Contracts**: Interfaces explicitly define what clients can depend on
- **Easier Testing**: Mock interfaces rather than concrete classes in unit tests
- **Loose Coupling**: Clients depend on abstractions, not concrete implementations
- **Polymorphism**: Swap implementations without modifying client code
- **Better Documentation**: Interface names and methods communicate intent
- **Scalability**: Add new implementations without touching existing code

## When NOT to Use

- **Single Implementation**: If only one class implements the interface, extract a more specific interface or leave code as-is
- **Shared Implementation Logic**: Use Extract Superclass instead if classes share implementation code
- **Too Many Methods**: An interface with many unrelated methods likely violates the Interface Segregation Principle
- **One-Time Usage**: Don't extract interfaces prematurely without evidence of multiple implementations
- **Artificial Abstractions**: Avoid creating interfaces just for the sake of it; ensure they represent genuine abstractions

## Related Refactorings

- **Extract Superclass**: Extract common code AND interface from classes with shared implementation
- **Extract Class**: Move related responsibilities to a new class without inheritance
- **Remove Middle Man**: Simplify excessive abstraction layers if they become confusing
- **Interface Segregation**: Split overly broad interfaces into smaller, more focused ones

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

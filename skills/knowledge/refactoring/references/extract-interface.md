## Contents

- [Overview](#overview)
- [Motivation](#motivation)
- [Mechanics](#mechanics)
- [Before and after](#before-and-after)
- [Benefits](#benefits)
- [When NOT to use](#when-not-to-use)
- [Related refactorings](#related-refactorings)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Extract Interface creates a formal contract from a set of methods that several clients rely on or that several classes implement in common. Extract Superclass shares both interface and implementation. Extract Interface isolates the contract alone, and each implementing class provides its own logic.

## Motivation

### Explicit roles
Interfaces declare the roles a class plays in different contexts. Extracting an interface makes the role visible in the type system and draws a clear line between what callers can expect and how the class delivers it.

### Pluggable implementations
When a system needs interchangeable variants (payment gateways, notification channels, storage backends), an interface makes every variant follow the same contract without forcing an artificial inheritance tree.

### Dependency inversion
Clients that depend on an interface instead of a concrete class are insulated from implementation changes. The code is easier to test with mocks and easier to adapt when requirements change.

## Mechanics

1. **Define the interface** with a name that reflects the responsibility it represents
2. **Declare the methods** that shared clients depend on
3. **Have classes implement** the new interface
4. **Update client type hints** to reference the interface instead of concrete classes
5. **Optional**: Remove the concrete class from client signatures if no class-specific features are needed

## Before and after

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

- **Defined contracts**: Interfaces make explicit what callers are allowed to depend on
- **Simpler testing**: Mock the interface instead of the concrete class in unit tests
- **Loose coupling**: Clients are insulated from implementation details
- **Swappable implementations**: Concrete classes can be substituted without touching client code
- **Clear communication**: Interface names and method signatures document the expected behavior
- **Easy extension**: New implementations can be added without modifying existing code

## When NOT to use

- **Only one implementation exists**: An interface with a single implementor may be a premature abstraction
- **Shared implementation needed**: If classes share code as well as a contract, Extract Superclass is a better fit
- **Interface is too broad**: A large interface with unrelated methods likely violates the Interface Segregation Principle. Split it first
- **No evidence of variation**: Do not create interfaces speculatively. Wait until a second implementation is needed
- **Artificial abstractions**: An interface should represent a real concept, not exist for its own sake

## Related refactorings

- **Extract Superclass**: Shares both contract and implementation between classes
- **Extract Class**: Moves responsibilities to a new class without inheritance
- **Remove Middle Man**: Removes abstraction layers that obscure more than they clarify
- **Interface Segregation**: Splits a broad interface into narrower, focused ones

## Examples in other languages

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

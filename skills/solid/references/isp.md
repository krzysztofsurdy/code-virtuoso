# Interface Segregation Principle (ISP)

## Definition

No client should be forced to depend on methods it does not use. Instead of one large interface, create smaller, focused interfaces so that implementing classes only need to know about the methods that are relevant to them.

Robert C. Martin formulated ISP after consulting for Xerox, where a single `Job` interface had grown to serve printers, staplers, and fax machines — forcing every implementation to stub out irrelevant methods.

## Why It Matters

Fat interfaces create unnecessary coupling. When a class depends on an interface with 20 methods but only uses 3, it is still coupled to the other 17. Any change to those unused methods forces recompilation and potential breakage. ISP creates focused contracts that:

- **Reduce coupling** — clients depend only on what they actually need
- **Improve clarity** — small interfaces communicate intent clearly
- **Simplify testing** — mocking a 3-method interface is easier than a 20-method one
- **Enable composition** — classes implement exactly the interfaces they need, nothing more
- **Prevent LSP violations** — smaller interfaces make it easier to honor the full contract

## Detecting Violations

Look for:

- **Interfaces with many methods** — 10+ methods is a strong signal
- **Implementing classes with empty or throwing methods** — `throw new \RuntimeException('Not implemented')`
- **"I only need half of this"** — when consumers ignore most of an interface
- **Adapters that wrap and delegate only partially** — adapting a fat interface to a thinner need
- **Interface names with "And"** — `ReadableAndWritableAndDeletable` should be three interfaces

## Before/After — PHP 8.3+

### Before: One fat interface for all workers

```php
<?php

declare(strict_types=1);

interface Worker
{
    public function work(): void;
    public function eat(): void;
    public function attendMeeting(): void;
    public function writeReport(): void;
}

final class Developer implements Worker
{
    public function work(): void
    {
        echo 'Writing code';
    }

    public function eat(): void
    {
        echo 'Eating lunch';
    }

    public function attendMeeting(): void
    {
        echo 'In standup';
    }

    public function writeReport(): void
    {
        // Developers don't write management reports
        throw new \RuntimeException('Not my job');
    }
}

final class Robot implements Worker
{
    public function work(): void
    {
        echo 'Assembling parts';
    }

    public function eat(): void
    {
        // Robots don't eat
        throw new \RuntimeException('Not applicable');
    }

    public function attendMeeting(): void
    {
        // Robots don't attend meetings
        throw new \RuntimeException('Not applicable');
    }

    public function writeReport(): void
    {
        // Robots don't write reports
        throw new \RuntimeException('Not applicable');
    }
}
```

### After: Focused interfaces for each capability

```php
<?php

declare(strict_types=1);

interface Workable
{
    public function work(): void;
}

interface Feedable
{
    public function eat(): void;
}

interface MeetingAttendee
{
    public function attendMeeting(): void;
}

interface ReportWriter
{
    public function writeReport(): void;
}

final class Developer implements Workable, Feedable, MeetingAttendee
{
    public function work(): void { echo 'Writing code'; }
    public function eat(): void { echo 'Eating lunch'; }
    public function attendMeeting(): void { echo 'In standup'; }
}

final class Manager implements Workable, Feedable, MeetingAttendee, ReportWriter
{
    public function work(): void { echo 'Managing projects'; }
    public function eat(): void { echo 'Business lunch'; }
    public function attendMeeting(): void { echo 'Leading meeting'; }
    public function writeReport(): void { echo 'Writing quarterly report'; }
}

final class Robot implements Workable
{
    public function work(): void { echo 'Assembling parts'; }
    // No forced stubs — Robot only implements what it can actually do
}
```

### Real-World Example: Document Handling

**Before — one bloated interface:**

```php
<?php

declare(strict_types=1);

interface Document
{
    public function read(): string;
    public function write(string $content): void;
    public function print(): void;
    public function fax(): void;
    public function scan(): string;
}

final class PdfDocument implements Document
{
    public function read(): string { return 'PDF content'; }
    public function write(string $content): void { /* ... */ }
    public function print(): void { /* ... */ }
    public function fax(): void { throw new \RuntimeException('PDF cannot fax'); }
    public function scan(): string { throw new \RuntimeException('PDF cannot scan'); }
}
```

**After — segregated by capability:**

```php
<?php

declare(strict_types=1);

interface Readable
{
    public function read(): string;
}

interface Writable
{
    public function write(string $content): void;
}

interface Printable
{
    public function print(): void;
}

interface Faxable
{
    public function fax(): void;
}

interface Scannable
{
    public function scan(): string;
}

final class PdfDocument implements Readable, Writable, Printable
{
    public function read(): string { return 'PDF content'; }
    public function write(string $content): void { /* ... */ }
    public function print(): void { /* ... */ }
}

final class FaxMachine implements Faxable, Scannable
{
    public function fax(): void { /* ... */ }
    public function scan(): string { return 'Scanned document'; }
}

// Consumer only depends on what it needs
final readonly class DocumentPrinter
{
    public function printDocument(Printable $doc): void
    {
        $doc->print();
    }
}
```

## Examples in Other Languages

### Java

**Before:**

```java
public interface MultiFunctionDevice {
    void print(String content);
    void scan();
    void fax(String destination);
    void copy();
    void staple();
}

public class BasicPrinter implements MultiFunctionDevice {
    @Override public void print(String content) { /* works */ }
    @Override public void scan() { throw new UnsupportedOperationException(); }
    @Override public void fax(String dest) { throw new UnsupportedOperationException(); }
    @Override public void copy() { throw new UnsupportedOperationException(); }
    @Override public void staple() { throw new UnsupportedOperationException(); }
}
```

**After:**

```java
public interface Printer {
    void print(String content);
}

public interface Scanner {
    String scan();
}

public interface FaxMachine {
    void fax(String destination);
}

public class BasicPrinter implements Printer {
    @Override
    public void print(String content) {
        System.out.println("Printing: " + content);
    }
}

public class OfficeDevice implements Printer, Scanner, FaxMachine {
    @Override public void print(String content) { /* ... */ }
    @Override public String scan() { return "scanned"; }
    @Override public void fax(String dest) { /* ... */ }
}
```

### Python

**Before:**

```python
from abc import ABC, abstractmethod


class DataStore(ABC):
    @abstractmethod
    def read(self, key: str) -> str: ...

    @abstractmethod
    def write(self, key: str, value: str) -> None: ...

    @abstractmethod
    def delete(self, key: str) -> None: ...

    @abstractmethod
    def list_keys(self) -> list[str]: ...

    @abstractmethod
    def watch(self, key: str, callback) -> None: ...


class SimpleCache(DataStore):
    """Only needs read/write but forced to implement everything."""
    def read(self, key): return self._cache.get(key, "")
    def write(self, key, value): self._cache[key] = value
    def delete(self, key): raise NotImplementedError
    def list_keys(self): raise NotImplementedError
    def watch(self, key, callback): raise NotImplementedError
```

**After:**

```python
from abc import ABC, abstractmethod
from typing import Callable


class Readable(ABC):
    @abstractmethod
    def read(self, key: str) -> str: ...


class Writable(ABC):
    @abstractmethod
    def write(self, key: str, value: str) -> None: ...


class Deletable(ABC):
    @abstractmethod
    def delete(self, key: str) -> None: ...


class Listable(ABC):
    @abstractmethod
    def list_keys(self) -> list[str]: ...


class Watchable(ABC):
    @abstractmethod
    def watch(self, key: str, callback: Callable) -> None: ...


class SimpleCache(Readable, Writable):
    def __init__(self):
        self._cache: dict[str, str] = {}

    def read(self, key: str) -> str:
        return self._cache.get(key, "")

    def write(self, key: str, value: str) -> None:
        self._cache[key] = value
```

### TypeScript

**Before:**

```typescript
interface CrudRepository<T> {
  findById(id: string): Promise<T | null>;
  findAll(): Promise<T[]>;
  save(entity: T): Promise<void>;
  update(id: string, entity: Partial<T>): Promise<void>;
  delete(id: string): Promise<void>;
  count(): Promise<number>;
  exists(id: string): Promise<boolean>;
  bulkInsert(entities: T[]): Promise<void>;
}

// Read-only view forced to implement write methods
class PublicCatalog implements CrudRepository<Product> {
  async findById(id: string) { /* ... */ }
  async findAll() { /* ... */ }
  async save() { throw new Error("Read-only"); }
  async update() { throw new Error("Read-only"); }
  async delete() { throw new Error("Read-only"); }
  async count() { /* ... */ }
  async exists(id: string) { /* ... */ }
  async bulkInsert() { throw new Error("Read-only"); }
}
```

**After:**

```typescript
interface ReadRepository<T> {
  findById(id: string): Promise<T | null>;
  findAll(): Promise<T[]>;
  count(): Promise<number>;
  exists(id: string): Promise<boolean>;
}

interface WriteRepository<T> {
  save(entity: T): Promise<void>;
  update(id: string, entity: Partial<T>): Promise<void>;
  delete(id: string): Promise<void>;
}

interface BulkWriteRepository<T> {
  bulkInsert(entities: T[]): Promise<void>;
}

class PublicCatalog implements ReadRepository<Product> {
  async findById(id: string) { /* ... */ }
  async findAll() { /* ... */ }
  async count() { /* ... */ }
  async exists(id: string) { /* ... */ }
  // No write methods — clean contract
}

class AdminCatalog implements ReadRepository<Product>, WriteRepository<Product> {
  // Implements both read and write
}
```

### C++

**Before:**

```cpp
class Animal {
public:
    virtual void walk() = 0;
    virtual void swim() = 0;
    virtual void fly() = 0;
    virtual ~Animal() = default;
};

class Dog : public Animal {
public:
    void walk() override { /* works */ }
    void swim() override { /* works */ }
    void fly() override { throw std::logic_error("Dogs can't fly"); }
};
```

**After:**

```cpp
class Walker {
public:
    virtual void walk() = 0;
    virtual ~Walker() = default;
};

class Swimmer {
public:
    virtual void swim() = 0;
    virtual ~Swimmer() = default;
};

class Flyer {
public:
    virtual void fly() = 0;
    virtual ~Flyer() = default;
};

class Dog : public Walker, public Swimmer {
public:
    void walk() override { /* runs on land */ }
    void swim() override { /* paddles in water */ }
};

class Eagle : public Walker, public Flyer {
public:
    void walk() override { /* hops on ground */ }
    void fly() override { /* soars high */ }
};

class Duck : public Walker, public Swimmer, public Flyer {
public:
    void walk() override { /* waddles */ }
    void swim() override { /* floats */ }
    void fly() override { /* flaps wings */ }
};
```

## How Small Should Interfaces Be?

There's no magic number, but consider:

- **1 method** — common for functional interfaces (Strategy, Command patterns)
- **2-5 methods** — typical for a focused capability
- **6+ methods** — worth examining if it can be split
- **Role-based grouping** — methods that are always used together belong in one interface

The test: if any implementation would need to stub or throw on a method, the interface is too broad.

## Common Pitfalls

- **Too many micro-interfaces** — splitting every method into its own interface creates complexity. Group methods that are always used together.
- **Interface explosion** — 50 single-method interfaces is worse than 5 well-designed ones. Find the natural boundaries.
- **Marker interfaces without behavior** — empty interfaces used just for type-checking add no value in most languages.

## Related Principles

- **Single Responsibility (SRP)** — ISP is SRP applied at the interface level
- **Liskov Substitution (LSP)** — segregated interfaces make LSP easier to satisfy
- **Dependency Inversion (DIP)** — smaller interfaces make better abstractions to depend on

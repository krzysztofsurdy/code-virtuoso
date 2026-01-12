---
name: iterator
description: Behavioral pattern that provides a way to access elements of a collection sequentially without exposing its underlying representation. Use when you need to traverse different data structures with a uniform interface while keeping the logic separate from the collection structure.
---

# Iterator Pattern

## Overview

The Iterator pattern is a behavioral design pattern that provides a way to access elements of a collection sequentially without exposing its underlying representation. It defines a common interface for traversing different data structures, allowing clients to iterate through collections without understanding their internal architecture.

## Intent

- Provide a way to access elements of a collection sequentially
- Encapsulate the traversal logic within an iterator object
- Enable different iteration strategies without modifying the collection
- Decouple collection implementation from client traversal code
- Support multiple simultaneous iterations over the same collection
- Hide the internal structure of the collection from clients

## Problem & Solution

### Problem

1. **Hidden Structure Coupling**: Clients directly coupled to collection internal structures (arrays, linked lists, trees)
2. **Multiple Traversal Strategies**: Different iteration patterns require repeated, complex logic in client code
3. **Collection Contamination**: Mixing traversal logic with collection management violates separation of concerns
4. **Inconsistent Access**: Different collections force clients to learn different access patterns
5. **Simultaneous Iterations**: Multiple iterations over the same collection interfere with state management

### Solution

Create an iterator object that handles the traversal logic independently:
1. Define an Iterator interface with common traversal methods
2. Implement concrete iterators for each collection type
3. Implement a collection method to create and return iterators
4. Clients use the iterator interface regardless of collection type
5. Collections remain focused on element management, not traversal

## Structure

```
Client Code
    ↓
Iterator Interface (hasNext(), next(), current(), key(), valid())
    ↑
    ├─ ConcreteIteratorA
    └─ ConcreteIteratorB
         ↑
    Aggregate Interface (createIterator())
         ↑
    ├─ ConcreteCollectionA
    └─ ConcreteCollectionB
```

## When to Use

- **Multiple Collection Types**: Need uniform access to different data structures
- **Complex Traversals**: Support various iteration strategies (forward, backward, filtered, sorted)
- **Separation of Concerns**: Keep collection and traversal logic separate
- **Simultaneous Iterations**: Multiple clients need to iterate independently over same collection
- **Internal Structure Privacy**: Hide collection implementation details
- **Lazy Loading**: Iterate large datasets without loading all into memory
- **Graph Traversals**: Implement DFS, BFS, or other graph iteration patterns
- **Custom Sequences**: Define custom iteration orders beyond default structure order

## Implementation

### PHP 8.3+ Example: File Collection Iterator

```php
<?php
declare(strict_types=1);

readonly interface Iterator {
    public function current(): mixed;
    public function key(): mixed;
    public function next(): void;
    public function rewind(): void;
    public function valid(): bool;
}

readonly interface Aggregate {
    public function createIterator(): Iterator;
}

readonly class FileIterator implements Iterator {
    private int $position = 0;

    public function __construct(
        private array $files
    ) {}

    public function current(): mixed {
        return $this->files[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        ++$this->position;
    }

    public function rewind(): void {
        $this->position = 0;
    }

    public function valid(): bool {
        return isset($this->files[$this->position]);
    }
}

readonly class FileCollection implements Aggregate {
    public function __construct(
        private array $files
    ) {}

    public function createIterator(): Iterator {
        return new FileIterator($this->files);
    }

    public function addFile(string $filename): void {
        $this->files[] = $filename;
    }
}

// Usage
$collection = new FileCollection(['file1.txt', 'file2.txt', 'file3.txt']);
$iterator = $collection->createIterator();

foreach ($iterator as $file) {
    echo "Processing: $file\n";
}
```

### Database Record Iterator

```php
<?php
declare(strict_types=1);

readonly class DatabaseRecordIterator implements Iterator {
    private int $position = 0;
    private array $records = [];

    public function __construct(
        private PDO $connection,
        private string $query
    ) {
        $this->loadRecords();
    }

    private function loadRecords(): void {
        $statement = $this->connection->prepare($this->query);
        $statement->execute();
        $this->records = $statement->fetchAll(PDO::FETCH_ASSOC);
    }

    public function current(): mixed {
        return $this->records[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        ++$this->position;
    }

    public function rewind(): void {
        $this->position = 0;
    }

    public function valid(): bool {
        return isset($this->records[$this->position]);
    }
}

readonly class UserRepository {
    public function __construct(
        private PDO $connection
    ) {}

    public function findAllIterator(): Iterator {
        return new DatabaseRecordIterator(
            $this->connection,
            'SELECT id, name, email FROM users ORDER BY id'
        );
    }
}

// Usage
$pdo = new PDO('mysql:host=localhost;dbname=app', 'user', 'password');
$userRepo = new UserRepository($pdo);

foreach ($userRepo->findAllIterator() as $user) {
    echo "User: {$user['name']} ({$user['email']})\n";
}
```

### Reverse Iterator Implementation

```php
<?php
declare(strict_types=1);

readonly class ReverseIterator implements Iterator {
    private int $position;

    public function __construct(
        private array $items
    ) {
        $this->position = count($items) - 1;
    }

    public function current(): mixed {
        return $this->items[$this->position] ?? null;
    }

    public function key(): mixed {
        return $this->position;
    }

    public function next(): void {
        --$this->position;
    }

    public function rewind(): void {
        $this->position = count($this->items) - 1;
    }

    public function valid(): bool {
        return $this->position >= 0 && isset($this->items[$this->position]);
    }
}

// Usage
$items = ['apple', 'banana', 'cherry'];
$reverseIterator = new ReverseIterator($items);

foreach ($reverseIterator as $key => $item) {
    echo "[$key] => $item\n";
}
// Output: [2] => cherry, [1] => banana, [0] => apple
```

## Real-World Analogies

**Library Card Catalog**: Catalog drawers provide an iterator-like interface. You open a drawer and flip through cards sequentially without needing to understand how cards are organized internally.

**Restaurant Menu Navigation**: Waiters iterate through menu items when describing specials, following a sequence regardless of how items are internally categorized.

**Traffic Light Sequence**: A traffic signal cycles through states (red, yellow, green) following a predetermined iteration pattern that drivers depend on.

**Book Chapter Navigation**: A book's table of contents provides an iterator-like structure to move through chapters sequentially without reorganizing the book itself.

## Pros and Cons

### Advantages
- **Separation of Concerns**: Traversal logic separated from collection structure
- **Single Responsibility**: Collections manage storage, iterators handle traversal
- **Uniform Interface**: Access different collections consistently
- **Multiple Iterations**: Support simultaneous independent iterations
- **Encapsulation**: Hide collection implementation details
- **Extensibility**: Add new iteration strategies without modifying collections
- **Lazy Evaluation**: Iterate large datasets efficiently

### Disadvantages
- **Added Complexity**: Creates additional classes and interfaces
- **Performance Overhead**: Extra abstraction layer may slow simple iterations
- **Memory Usage**: Iterators maintain additional state and position tracking
- **Language Support**: Native PHP iteration sometimes simpler than custom iterators
- **Debugging Difficulty**: Abstraction can make tracking iteration flow harder
- **Synchronization Issues**: Concurrent modifications during iteration cause errors

## Relations with Other Patterns

- **Composite**: Iterator commonly traverses hierarchical Composite structures
- **Factory Method**: Collections use factories to create appropriate iterators
- **Strategy**: Different iterators act as strategies for different traversal approaches
- **Command**: Can encapsulate iteration sequences as command objects
- **Memento**: Iterators can capture and restore iteration state
- **Template Method**: Defines skeleton of iteration algorithm
- **Visitor**: Works with iterators to process collection elements

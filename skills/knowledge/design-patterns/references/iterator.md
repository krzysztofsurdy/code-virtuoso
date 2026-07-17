# Iterator Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Iterator is a behavioral design pattern that gives callers a uniform way to step through a collection's elements one at a time without exposing how the collection stores them. Traversal logic lives in a dedicated object, so the collection's data structure is decoupled from the code that consumes its contents.

## Intent

- Provide sequential access to a collection's elements through a standard interface
- Encapsulate traversal state and logic in a separate iterator object
- Allow different traversal strategies without modifying the collection
- Separate data storage from data traversal
- Permit several independent iterations over the same collection at once
- Keep the collection's internal layout invisible to consumers

## Problem and solution

### Problem

1. **Structural coupling**: client code that indexes arrays, follows linked-list pointers, or walks tree nodes becomes tied to one data structure
2. **Duplicated traversal logic**: each consumer reimplements the same stepping logic
3. **Blurred responsibilities**: traversal methods mixed into the collection class dilute its main purpose
4. **Inconsistent APIs**: different collection types expose different access patterns, and clients must learn each one
5. **Interference between traversals**: two pieces of code iterating the same collection can corrupt each other's position

### Solution

Create an iterator object that handles traversal independently:
1. Define an Iterator interface with common traversal methods
2. Implement a concrete iterator for each collection type
3. Give the collection a method that creates and returns iterators
4. Have clients use the iterator interface regardless of collection type
5. Keep collections focused on managing elements, not traversing them

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

## When to use

- **Multiple collection types**: you need uniform access to different data structures
- **Complex traversals**: you support several iteration strategies (forward, backward, filtered, sorted)
- **Separation of concerns**: collection and traversal logic should stay apart
- **Simultaneous iterations**: several clients iterate the same collection independently
- **Hidden structure**: collection implementation details should stay private
- **Lazy loading**: you iterate large datasets without loading everything into memory
- **Graph traversals**: you implement DFS, BFS, or other graph iteration
- **Custom sequences**: you need iteration orders other than the structure's default

## Implementation

### PHP 8.3+ example: file collection iterator

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

### Database record iterator

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

### Reverse iterator

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

## Real-world analogies

**Jukebox playlist**: a jukebox lets you skip forward and backward through songs without exposing how the tracks are stored (vinyl, CDs, or digital files). The "next track" button is the iterator.

**Museum audio guide**: visitors follow a numbered tour through the exhibits. The guide advances from one stop to the next regardless of how the museum is physically laid out.

**TV channel surfing**: the channel-up button cycles through available stations. The viewer does not need to know whether channels are stored in a hash map, a sorted list, or fetched from a satellite feed.

## Pros and cons

### Advantages

- **Clean boundaries**: collection classes manage storage; iterators handle navigation
- **Focused classes**: each side owns one responsibility, which simplifies maintenance
- **Consistent access**: the same loop construct works for any underlying data structure
- **Independent cursors**: several iterations over one collection proceed without interfering
- **Hidden internals**: clients never see arrays, trees, or linked lists directly
- **Pluggable traversals**: new iteration strategies can be added without touching the collection
- **On-demand evaluation**: large or infinite sequences can be iterated lazily

### Disadvantages

- **Extra abstractions**: iterator and aggregate interfaces add classes to the project
- **Overhead for simple cases**: a plain array loop is faster and simpler than a custom iterator
- **State bookkeeping**: each iterator tracks its own position and validity
- **Language overlap**: PHP's built-in `foreach` and `Iterator` interface often make custom iterators redundant
- **Harder tracing**: the abstraction layers can obscure the actual traversal path when debugging
- **Mutation hazards**: modifying a collection while iterating it can produce unpredictable results

## Relations with other patterns

- **Composite**: iterators are the natural way to walk composite tree structures
- **Factory Method**: collections act as factories for their own iterators
- **Strategy**: different iterator implementations represent different traversal strategies
- **Command**: iteration steps can be wrapped as command objects for deferred execution
- **Memento**: an iterator's position can be captured and restored with a memento
- **Template Method**: a base iterator can define the traversal skeleton and let subclasses customize steps
- **Visitor**: works alongside iterators to process each element during traversal

## Examples in other languages

### Java

Before and after: encapsulating iteration to prevent external access to internal collection:

```java
class IntegerBox {
    private List<Integer> list = new ArrayList<>();

    public class Iterator {
        private IntegerBox box;
        private java.util.Iterator iterator;
        private int value;

        public Iterator(IntegerBox integerBox) {
            box = integerBox;
        }

        public void first() {
            iterator = box.list.iterator();
            next();
        }

        public void next() {
            try {
                value = (Integer)iterator.next();
            } catch (NoSuchElementException ex) {
                value = -1;
            }
        }

        public boolean isDone() {
            return value == -1;
        }

        public int currentValue() {
            return value;
        }
    }

    public void add(int in) {
        list.add(in);
    }

    public Iterator getIterator() {
        return new Iterator(this);
    }
}

public class IteratorDemo {
    public static void main(String[] args) {
        IntegerBox integerBox = new IntegerBox();
        for (int i = 9; i > 0; --i) {
            integerBox.add(i);
        }
        // Supports multiple simultaneous iterators
        IntegerBox.Iterator firstItr = integerBox.getIterator();
        IntegerBox.Iterator secondItr = integerBox.getIterator();
        for (firstItr.first(); !firstItr.isDone(); firstItr.next()) {
            System.out.print(firstItr.currentValue() + "  ");
        }
        System.out.println();
        for (firstItr.first(), secondItr.first(); !firstItr.isDone();
             firstItr.next(), secondItr.next()) {
            System.out.print(firstItr.currentValue() + " "
                + secondItr.currentValue() + "  ");
        }
    }
}
```

### Python

```python
import collections.abc


class ConcreteAggregate(collections.abc.Iterable):
    """
    Implement the Iterator creation interface to return an instance of
    the proper ConcreteIterator.
    """

    def __init__(self):
        self._data = None

    def __iter__(self):
        return ConcreteIterator(self)


class ConcreteIterator(collections.abc.Iterator):
    """
    Implement the Iterator interface.
    """

    def __init__(self, concrete_aggregate):
        self._concrete_aggregate = concrete_aggregate

    def __next__(self):
        if True:  # if no_elements_to_traverse:
            raise StopIteration
        return None  # return element


def main():
    concrete_aggregate = ConcreteAggregate()
    for _ in concrete_aggregate:
        pass


if __name__ == "__main__":
    main()
```

### C++

Stack iterator with friend class access and operator overloading for equality comparison:

```cpp
#include <iostream>
using namespace std;

class Stack
{
    int items[10];
    int sp;
  public:
    friend class StackIter;
    Stack()
    {
        sp = -1;
    }
    void push(int in)
    {
        items[++sp] = in;
    }
    int pop()
    {
        return items[sp--];
    }
    bool isEmpty()
    {
        return (sp == -1);
    }
    StackIter *createIterator() const;
};

class StackIter
{
    const Stack *stk;
    int index;
  public:
    StackIter(const Stack *s)
    {
        stk = s;
    }
    void first()
    {
        index = 0;
    }
    void next()
    {
        index++;
    }
    bool isDone()
    {
        return index == stk->sp + 1;
    }
    int currentItem()
    {
        return stk->items[index];
    }
};

StackIter *Stack::createIterator() const
{
  return new StackIter(this);
}

bool operator == (const Stack &l, const Stack &r)
{
  StackIter *itl = l.createIterator();
  StackIter *itr = r.createIterator();
  for (itl->first(), itr->first(); !itl->isDone(); itl->next(), itr->next())
    if (itl->currentItem() != itr->currentItem())
      break;
  bool ans = itl->isDone() && itr->isDone();
  delete itl;
  delete itr;
  return ans;
}

int main()
{
  Stack s1;
  for (int i = 1; i < 5; i++)
    s1.push(i);
  Stack s2(s1), s3(s1), s4(s1), s5(s1);
  s3.pop();
  s5.pop();
  s4.push(2);
  s5.push(9);
  cout << "1 == 2 is " << (s1 == s2) << endl;
  cout << "1 == 3 is " << (s1 == s3) << endl;
  cout << "1 == 4 is " << (s1 == s4) << endl;
  cout << "1 == 5 is " << (s1 == s5) << endl;
}
```

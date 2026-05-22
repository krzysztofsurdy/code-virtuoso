# Iterator Pattern

## Overview

The Iterator pattern is a behavioral design pattern that gives callers a uniform way to step through a collection's elements one at a time without revealing how the collection stores them internally. By packaging traversal logic into a dedicated object, it decouples the collection's data structure from the code that consumes its contents.

## Intent

- Offer sequential access to a collection's elements through a standard interface
- Encapsulate traversal state and logic inside a separate iterator object
- Allow different traversal strategies without modifying the collection itself
- Separate data storage responsibilities from data traversal responsibilities
- Permit multiple independent iterations over the same collection simultaneously
- Keep the collection's internal arrangement invisible to consumers

## Problem & Solution

### Problem

1. **Structural Coupling**: Client code that directly indexes arrays, follows linked-list pointers, or walks tree nodes becomes tied to a specific data structure
2. **Duplicated Traversal Logic**: Each consumer reimplements the same stepping logic, bloating the codebase
3. **Blurred Responsibilities**: Mixing traversal methods into the collection class dilutes its primary purpose
4. **Inconsistent APIs**: Different collection types expose different access patterns, forcing clients to learn each one
5. **Interference Between Traversals**: Two pieces of code iterating the same collection may corrupt each other's position

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

**Jukebox Playlist**: A jukebox lets you skip forward and backward through songs without exposing how the tracks are stored internally - vinyl records, CDs, or digital files. The "next track" button is the iterator.

**Museum Audio Guide**: Visitors follow a numbered tour through exhibits. The audio guide advances from one stop to the next regardless of how the museum is physically laid out, providing a consistent traversal experience.

**TV Channel Surfing**: Pressing the channel-up button on a remote cycles through available stations. The viewer does not need to know whether channels are stored in a hash map, a sorted list, or fetched from a satellite feed.

## Pros and Cons

### Advantages
- **Clean boundaries**: Collection classes manage storage; iterators handle navigation
- **Focused classes**: Each side owns one responsibility, simplifying maintenance
- **Consistent access**: The same loop construct works regardless of the underlying data structure
- **Independent cursors**: Multiple iterations over one collection proceed without interference
- **Hidden internals**: Clients never see arrays, trees, or linked lists directly
- **Pluggable traversals**: New iteration strategies can be introduced without touching the collection
- **On-demand evaluation**: Large or infinite sequences can be iterated lazily

### Disadvantages
- **Extra abstractions**: Iterator and aggregate interfaces add classes to the project
- **Overhead for simple cases**: A plain array loop is faster and simpler than a custom iterator
- **State bookkeeping**: Each iterator maintains its own position and validity tracking
- **Language overlap**: PHP's built-in `foreach` and `Iterator` interface often make custom iterators redundant
- **Harder tracing**: Abstraction layers can obscure the actual traversal path during debugging
- **Mutation hazards**: Modifying a collection while iterating it can produce unpredictable results

## Relations with Other Patterns

- **Composite**: Iterators are the natural tool for walking composite tree structures
- **Factory Method**: Collections act as factories for their own iterators
- **Strategy**: Different iterator implementations represent different traversal strategies
- **Command**: Iteration steps can be wrapped as command objects for deferred execution
- **Memento**: An iterator's position can be captured and restored via a memento
- **Template Method**: A base iterator can define the traversal skeleton, letting subclasses customize steps
- **Visitor**: Works alongside iterators to process each element during traversal

## Examples in Other Languages

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

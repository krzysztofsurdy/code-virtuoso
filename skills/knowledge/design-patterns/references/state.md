## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem & solution](#problem--solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Examples in other languages](#examples-in-other-languages)

## Overview

State is a behavioral design pattern that lets an object change its behavior when its internal state changes, so it appears to change its class. Instead of large conditionals, state-specific behavior lives in separate state classes, and transitions swap one state object for another.

## Intent

- Let an object change its behavior when its internal state changes
- Encapsulate state-specific behavior in separate classes
- Delegate behavior to state objects to simplify state management
- Remove conditional logic for state-dependent operations
- Make state transitions explicit

## Problem & solution

### Problem

Many objects behave differently depending on internal state. This usually leads to:

1. **Complex conditional logic**: large if-else or switch statements for each state
2. **Tight coupling**: state-related logic scattered through the class
3. **Hard maintenance**: adding a state means modifying existing code
4. **Error-prone transitions**: inconsistent state handling and invalid transitions
5. **Violated Single Responsibility**: the class handles both core logic and state management

### Solution

Move state-specific behavior into separate state classes that implement a common interface. The context object delegates to its current state object. When the state changes, the context switches to a different state object and the behavior changes with it, with no conditionals.

## Structure

```
Context
├── currentState: State
├── request()
└── setState(State)

State (interface)
├── handle(Context)

ConcreteStateA
├── handle(Context)

ConcreteStateB
├── handle(Context)
```

## When to use

- An object's behavior depends on its state and must change at runtime
- An object has large conditional statements that depend on multiple states
- Switch/case statements on state keep needing changes
- State transitions follow a predictable pattern
- Multiple operations depend on the same state conditions
- Object state determines which methods are valid to call

## Implementation

### PHP 8.3+ example: document workflow

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\State;

// State Interface
interface DocumentState {
    public function publish(Document $document): void;
    public function reject(Document $document): void;
    public function review(Document $document): void;
    public function getName(): string;
}

// Concrete States
readonly class DraftState implements DocumentState {
    public function publish(Document $document): void {
        throw new RuntimeException("Cannot publish from draft. Submit for review first.");
    }

    public function reject(Document $document): void {
        throw new RuntimeException("Cannot reject a draft.");
    }

    public function review(Document $document): void {
        echo "Document submitted for review\n";
        $document->setState(new ReviewState());
    }

    public function getName(): string {
        return 'Draft';
    }
}

readonly class ReviewState implements DocumentState {
    public function publish(Document $document): void {
        echo "Document approved and published\n";
        $document->setState(new PublishedState());
    }

    public function reject(Document $document): void {
        echo "Document rejected, returning to draft\n";
        $document->setState(new DraftState());
    }

    public function review(Document $document): void {
        throw new RuntimeException("Document is already under review.");
    }

    public function getName(): string {
        return 'Under Review';
    }
}

readonly class PublishedState implements DocumentState {
    public function publish(Document $document): void {
        throw new RuntimeException("Document is already published.");
    }

    public function reject(Document $document): void {
        throw new RuntimeException("Cannot reject a published document.");
    }

    public function review(Document $document): void {
        throw new RuntimeException("Cannot review a published document.");
    }

    public function getName(): string {
        return 'Published';
    }
}

// Context
class Document {
    private DocumentState $state;
    private string $title;
    private string $content;

    public function __construct(string $title, string $content) {
        $this->title = $title;
        $this->content = $content;
        $this->state = new DraftState();
    }

    public function publish(): void {
        $this->state->publish($this);
    }

    public function reject(): void {
        $this->state->reject($this);
    }

    public function submitForReview(): void {
        $this->state->review($this);
    }

    public function setState(DocumentState $state): void {
        $this->state = $state;
    }

    public function getStatus(): string {
        return "Document '{$this->title}' is {$this->state->getName()}";
    }
}

// Usage
$doc = new Document('Project Proposal', 'Content here...');
echo $doc->getStatus() . "\n"; // Draft

$doc->submitForReview(); // Draft → Review
echo $doc->getStatus() . "\n";

$doc->publish(); // Review → Published
echo $doc->getStatus() . "\n";
```

### Order processing example

```php
<?php
declare(strict_types=1);

interface OrderState {
    public function cancel(Order $order): void;
    public function ship(Order $order): void;
    public function receive(Order $order): void;
    public function getStatus(): string;
}

readonly class PendingState implements OrderState {
    public function cancel(Order $order): void {
        echo "Order cancelled\n";
        $order->setState(new CancelledState());
    }

    public function ship(Order $order): void {
        echo "Order shipped\n";
        $order->setState(new ShippedState());
    }

    public function receive(Order $order): void {
        throw new RuntimeException("Cannot receive pending order");
    }

    public function getStatus(): string {
        return 'Pending';
    }
}

readonly class ShippedState implements OrderState {
    public function cancel(Order $order): void {
        throw new RuntimeException("Cannot cancel shipped order");
    }

    public function ship(Order $order): void {
        throw new RuntimeException("Order already shipped");
    }

    public function receive(Order $order): void {
        echo "Order received\n";
        $order->setState(new DeliveredState());
    }

    public function getStatus(): string {
        return 'Shipped';
    }
}

readonly class DeliveredState implements OrderState {
    public function cancel(Order $order): void {
        throw new RuntimeException("Cannot cancel delivered order");
    }

    public function ship(Order $order): void {
        throw new RuntimeException("Order already delivered");
    }

    public function receive(Order $order): void {
        throw new RuntimeException("Order already received");
    }

    public function getStatus(): string {
        return 'Delivered';
    }
}

readonly class CancelledState implements OrderState {
    public function cancel(Order $order): void {
        throw new RuntimeException("Order already cancelled");
    }

    public function ship(Order $order): void {
        throw new RuntimeException("Cannot ship cancelled order");
    }

    public function receive(Order $order): void {
        throw new RuntimeException("Cannot receive cancelled order");
    }

    public function getStatus(): string {
        return 'Cancelled';
    }
}

class Order {
    private OrderState $state;
    private string $id;

    public function __construct(string $id) {
        $this->id = $id;
        $this->state = new PendingState();
    }

    public function cancel(): void {
        $this->state->cancel($this);
    }

    public function ship(): void {
        $this->state->ship($this);
    }

    public function receive(): void {
        $this->state->receive($this);
    }

    public function setState(OrderState $state): void {
        $this->state = $state;
    }

    public function getStatus(): string {
        return "Order {$this->id}: {$this->state->getStatus()}";
    }
}

// Usage
$order = new Order('ORD-001');
echo $order->getStatus() . "\n";
$order->ship();
echo $order->getStatus() . "\n";
$order->receive();
echo $order->getStatus() . "\n";
```

## Real-world analogies

**TCP connection**: A TCP socket has states such as LISTEN, ESTABLISHED, and CLOSE_WAIT. Each state handles the same operations differently. Sending data, for example, behaves differently depending on the current state.

**Media player**: A media player can be playing, paused, or stopped. The play button behaves differently in each: it resumes when paused and starts from the beginning when stopped.

**Vending machine**: A vending machine has states such as idle, accepting coins, and dispensing. A button press has a different effect in each.

**Traffic light**: A traffic light has red, yellow, and green states. Each state determines which transitions are valid and what happens next.

## Pros and cons

### Advantages
- **Single Responsibility**: each state class handles one state's logic
- **Open/Closed Principle**: new states can be added without modifying existing state classes
- **No conditionals**: polymorphism replaces large if-else chains
- **Explicit transitions**: state changes are easy to see and manage
- **Encapsulation**: state-specific logic stays inside state classes
- **Reusability**: states can be shared across context instances

### Disadvantages
- **More classes**: many state classes add to overall complexity
- **Overhead for simple cases**: overkill if the object has only one or two states
- **Indirection**: method delegation can make the code flow harder to follow
- **Memory usage**: each state instance takes memory
- **State initialization**: states with dependencies need more complex initialization

## Relations with other patterns

- **Strategy**: Both encapsulate behavior selection, but the client chooses a Strategy while State changes internally
- **Bridge**: Both vary the implementation independently of the abstraction
- **Singleton**: Individual state instances are often Singletons
- **Factory**: State creation can use Factory Method or Abstract Factory
- **Template Method**: State classes can use Template Method for similar state behaviors
- **Memento**: Useful for saving and restoring state
- **Builder**: Can be combined to build complex state machines

## Examples in other languages

### Java

Example 1: Ceiling fan pull chain - before and after applying the State pattern.

Before (using conditionals):

```java
class CeilingFanPullChain {
    private int currentState;

    public CeilingFanPullChain() {
        currentState = 0;
    }

    public void pull() {
        if (currentState == 0) {
            currentState = 1;
            System.out.println("low speed");
        } else if (currentState == 1) {
            currentState = 2;
            System.out.println("medium speed");
        } else if (currentState == 2) {
            currentState = 3;
            System.out.println("high speed");
        } else {
            currentState = 0;
            System.out.println("turning off");
        }
    }
}
```

After (using the State pattern):

```java
interface State {
    void pull(CeilingFanPullChain wrapper);
}

class CeilingFanPullChain {
    private State currentState;

    public CeilingFanPullChain() {
        currentState = new Off();
    }

    public void set_state(State s) {
        currentState = s;
    }

    public void pull() {
        currentState.pull(this);
    }
}

class Off implements State {
    public void pull(CeilingFanPullChain wrapper) {
        wrapper.set_state(new Low());
        System.out.println("low speed");
    }
}

class Low implements State {
    public void pull(CeilingFanPullChain wrapper) {
        wrapper.set_state(new Medium());
        System.out.println("medium speed");
    }
}

class Medium implements State {
    public void pull(CeilingFanPullChain wrapper) {
        wrapper.set_state(new High());
        System.out.println("high speed");
    }
}

class High implements State {
    public void pull(CeilingFanPullChain wrapper) {
        wrapper.set_state(new Off());
        System.out.println("turning off");
    }
}
```

### C++

```cpp
#include <iostream>
using namespace std;

class Machine {
    class State *current;
  public:
    Machine();
    void setCurrent(State *s) {
        current = s;
    }
    void on();
    void off();
};

class State {
  public:
    virtual void on(Machine *m) {
        cout << "   already ON\n";
    }
    virtual void off(Machine *m) {
        cout << "   already OFF\n";
    }
};

void Machine::on() {
    current->on(this);
}

void Machine::off() {
    current->off(this);
}

class ON : public State {
  public:
    ON() {
        cout << "   ON-ctor ";
    };
    ~ON() {
        cout << "   dtor-ON\n";
    };
    void off(Machine *m);
};

class OFF : public State {
  public:
    OFF() {
        cout << "   OFF-ctor ";
    };
    ~OFF() {
        cout << "   dtor-OFF\n";
    };
    void on(Machine *m) {
        cout << "   going from OFF to ON";
        m->setCurrent(new ON());
        delete this;
    }
};

void ON::off(Machine *m) {
    cout << "   going from ON to OFF";
    m->setCurrent(new OFF());
    delete this;
}

Machine::Machine() {
    current = new OFF();
    cout << '\n';
}

int main() {
    void(Machine::*ptrs[])() = {
        Machine::off, Machine::on
    };
    Machine fsm;
    int num;
    while (1) {
        cout << "Enter 0/1: ";
        cin >> num;
        (fsm.*ptrs[num])();
    }
}
```

### Python

```python
import abc

class Context:
    """
    Define the interface of interest to clients.
    Maintain an instance of a ConcreteState subclass that defines the
    current state.
    """

    def __init__(self, state):
        self._state = state

    def request(self):
        self._state.handle()

class State(metaclass=abc.ABCMeta):
    """
    Define an interface for encapsulating the behavior associated with a
    particular state of the Context.
    """

    @abc.abstractmethod
    def handle(self):
        pass

class ConcreteStateA(State):
    """
    Implement a behavior associated with a state of the Context.
    """

    def handle(self):
        pass

class ConcreteStateB(State):
    """
    Implement a behavior associated with a state of the Context.
    """

    def handle(self):
        pass

def main():
    concrete_state_a = ConcreteStateA()
    context = Context(concrete_state_a)
    context.request()

if __name__ == "__main__":
    main()
```

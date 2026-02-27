## Overview

The State pattern is a behavioral design pattern that lets an object alter its behavior when its internal state changes. The object will appear to change its class dynamically. Instead of using large conditional statements to handle different states, this pattern encapsulates state-specific behavior into separate state classes, allowing clean state transitions.

## Intent

- Allow an object to alter its behavior when its internal state changes
- Encapsulate state-specific behavior in separate classes
- Simplify state management by delegating behavior to state objects
- Eliminate conditional logic for state-dependent operations
- Make state transitions explicit and manageable

## Problem & Solution

### Problem

Many objects exhibit behavior that varies based on their internal state. Typically, this leads to:

1. **Complex Conditional Logic**: Large if-else or switch statements to handle different states
2. **Tight Coupling**: State-related logic scattered throughout the class
3. **Hard to Maintain**: Adding new states requires modifying existing code
4. **Error-Prone State Transitions**: Inconsistent state management and invalid transitions
5. **Violated Single Responsibility**: Class handles both core logic and state management

### Solution

Extract state-specific behavior into separate state classes that implement a common interface. The context object delegates behavior to the current state object. When the state changes, the context switches to a different state object, automatically changing behavior without complex conditionals.

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

## When to Use

- An object's behavior depends on its state and must change at runtime
- Large conditional statements in an object based on multiple states
- Code contains switch/case statements that need to change frequently
- State transitions follow a predictable pattern
- You want to avoid long conditional chains
- Multiple operations depend on the same state conditions
- Object state determines what methods are valid to call

## Implementation

### PHP 8.3+ Example: Document Workflow

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

### Order Processing Example

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

## Real-World Analogies

**TCP Connection**: A TCP socket has different states (LISTEN, ESTABLISHED, CLOSE_WAIT). Each state handles the same operations differently. Sending data behaves differently depending on current state.

**Media Player**: A media player can be playing, paused, or stopped. The play button behaves differently in each state - it resumes from paused state but starts from beginning in stopped state.

**Vending Machine**: A vending machine has different states (idle, accepting coins, dispensing). Button presses have different effects depending on current state.

**Traffic Light**: A traffic light has red, yellow, and green states. Each state determines which transitions are valid and what behavior follows.

## Pros and Cons

### Advantages
- **Single Responsibility**: Each state class handles one state's logic
- **Open/Closed Principle**: New states can be added without modifying existing state classes
- **Eliminates Conditionals**: Replaces large if-else chains with polymorphism
- **Explicit State Transitions**: State changes are clear and manageable
- **Encapsulation**: State-specific logic is hidden within state classes
- **Reusability**: States can be shared across multiple context instances

### Disadvantages
- **Increased Classes**: Creates many state classes, increasing overall complexity
- **Overhead for Simple States**: Overkill if object has only one or two states
- **Indirection**: May make code flow harder to follow with method delegation
- **Memory Usage**: Each state instance consumes memory
- **State Initialization**: Complex initialization logic for states with dependencies

## Relations with Other Patterns

- **Strategy**: Both encapsulate behavior selection, but Strategy is chosen by client; State is changed internally
- **Bridge**: Both vary implementation independently of abstraction
- **Singleton**: Individual state instances are often Singletons
- **Factory**: State creation can use Factory Method or Abstract Factory
- **Template Method**: State classes can use Template Method for similar state behaviors
- **Memento**: Useful to save/restore state transitions
- **Builder**: Can combine to build complex state machines

## Examples in Other Languages

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

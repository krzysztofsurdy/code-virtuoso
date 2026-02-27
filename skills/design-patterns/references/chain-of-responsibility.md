# Chain of Responsibility Pattern

## Overview

The Chain of Responsibility pattern is a behavioral design pattern that passes requests along a chain of handlers. Upon receiving a request, each handler decides either to process the request or to pass it along the chain to the next handler. This pattern decouples senders from receivers by allowing multiple objects to handle the request.

## Intent

- Pass requests along a chain of handlers
- Allow handlers to decide whether to process a request or pass it to the next handler
- Avoid coupling the sender of a request to its receiver
- Create dynamic chains of handlers at runtime
- Provide a flexible way to handle different types of requests

## Problem & Solution

### Problem

When you have multiple objects that can handle a request, you face several challenges:

1. **Tight Coupling**: Direct calls to specific handlers create dependencies
2. **Inflexible Logic**: Adding new handlers or changing order requires modifying client code
3. **Complex Conditionals**: Using if-else statements to determine which handler should process the request leads to unmaintainable code
4. **Runtime Flexibility**: You cannot determine which handler should process a request until runtime

### Solution

Create a chain of handler objects, where each handler contains a reference to the next handler in the chain. When receiving a request, a handler decides whether to process it or pass it to the next handler. This creates a linked list structure that is flexible and extensible.

## Structure

```
Request/Task
    ↓
Handler (interface/abstract)
├── ConcreteHandlerA → ConcreteHandlerB → ConcreteHandlerC → null
│   (process/forward)   (process/forward)   (process/forward)
└── Can be configured dynamically at runtime
```

## When to Use

- Multiple objects may handle a request and the handler isn't known in advance
- You want to issue a request without specifying the receiver explicitly
- You need to handle requests dynamically based on priority, permission levels, or conditions
- Creating approval workflows, logging systems, or event processing pipelines
- Building authentication/authorization chains
- Processing events through multiple filters or validators
- Implementing logging frameworks with multiple handlers

## Implementation

### PHP 8.3+ Example: Support Ticket Handler Chain

```php
<?php
declare(strict_types=1);

// Request object
readonly class SupportTicket {
    public function __construct(
        private string $id,
        private int $priority,
        private string $issue,
    ) {}

    public function getId(): string {
        return $this->id;
    }

    public function getPriority(): int {
        return $this->priority;
    }

    public function getIssue(): string {
        return $this->issue;
    }
}

// Abstract Handler
abstract class SupportHandler {
    protected ?SupportHandler $nextHandler = null;

    public function setNextHandler(SupportHandler $handler): self {
        $this->nextHandler = $handler;
        return $this;
    }

    abstract public function canHandle(SupportTicket $ticket): bool;

    public function handle(SupportTicket $ticket): void {
        if ($this->canHandle($ticket)) {
            $this->process($ticket);
        } elseif ($this->nextHandler !== null) {
            $this->nextHandler->handle($ticket);
        } else {
            echo "Ticket {$ticket->getId()}: No handler available\n";
        }
    }

    abstract protected function process(SupportTicket $ticket): void;
}

// Concrete Handlers
class BasicSupportHandler extends SupportHandler {
    public function canHandle(SupportTicket $ticket): bool {
        return $ticket->getPriority() <= 1;
    }

    protected function process(SupportTicket $ticket): void {
        echo "Ticket {$ticket->getId()}: Handled by Basic Support\n";
        echo "Issue: {$ticket->getIssue()}\n";
    }
}

class TechnicianHandler extends SupportHandler {
    public function canHandle(SupportTicket $ticket): bool {
        return $ticket->getPriority() === 2;
    }

    protected function process(SupportTicket $ticket): void {
        echo "Ticket {$ticket->getId()}: Handled by Technician\n";
        echo "Technical analysis: {$ticket->getIssue()}\n";
    }
}

class ManagerHandler extends SupportHandler {
    public function canHandle(SupportTicket $ticket): bool {
        return $ticket->getPriority() >= 3;
    }

    protected function process(SupportTicket $ticket): void {
        echo "Ticket {$ticket->getId()}: Handled by Manager\n";
        echo "Escalation: {$ticket->getIssue()}\n";
    }
}

// Setup and usage
$basic = new BasicSupportHandler();
$technician = new TechnicianHandler();
$manager = new ManagerHandler();

// Build the chain: basic → technician → manager
$basic->setNextHandler($technician)->setNextHandler($manager);

// Process tickets
$ticket1 = new SupportTicket('T001', 1, 'Billing inquiry');
$ticket2 = new SupportTicket('T002', 2, 'Software bug');
$ticket3 = new SupportTicket('T003', 4, 'System outage');

$basic->handle($ticket1);
$basic->handle($ticket2);
$basic->handle($ticket3);
```

### Request Logging Chain Example

```php
<?php
declare(strict_types=1);

readonly class LogEntry {
    public function __construct(
        private string $message,
        private string $level,
    ) {}

    public function getMessage(): string {
        return $this->message;
    }

    public function getLevel(): string {
        return $this->level;
    }
}

abstract class Logger {
    protected ?Logger $nextLogger = null;

    public function setNext(Logger $logger): Logger {
        $this->nextLogger = $logger;
        return $logger;
    }

    public function log(LogEntry $entry): void {
        if ($this->shouldHandle($entry)) {
            $this->writeLog($entry);
        }

        if ($this->nextLogger !== null) {
            $this->nextLogger->log($entry);
        }
    }

    abstract protected function shouldHandle(LogEntry $entry): bool;
    abstract protected function writeLog(LogEntry $entry): void;
}

class ConsoleLogger extends Logger {
    protected function shouldHandle(LogEntry $entry): bool {
        return in_array($entry->getLevel(), ['DEBUG', 'INFO']);
    }

    protected function writeLog(LogEntry $entry): void {
        echo "[CONSOLE] {$entry->getLevel()}: {$entry->getMessage()}\n";
    }
}

class FileLogger extends Logger {
    protected function shouldHandle(LogEntry $entry): bool {
        return in_array($entry->getLevel(), ['WARNING', 'ERROR']);
    }

    protected function writeLog(LogEntry $entry): void {
        echo "[FILE] {$entry->getLevel()}: {$entry->getMessage()}\n";
    }
}

class EmailLogger extends Logger {
    protected function shouldHandle(LogEntry $entry): bool {
        return $entry->getLevel() === 'CRITICAL';
    }

    protected function writeLog(LogEntry $entry): void {
        echo "[EMAIL] {$entry->getLevel()}: {$entry->getMessage()}\n";
    }
}

// Usage
$console = new ConsoleLogger();
$file = new FileLogger();
$email = new EmailLogger();

$console->setNext($file)->setNext($email);

$console->log(new LogEntry('Application started', 'INFO'));
$console->log(new LogEntry('Low disk space', 'WARNING'));
$console->log(new LogEntry('Database connection failed', 'CRITICAL'));
```

## Real-World Analogies

**Customer Support Pipeline**: A customer support request starts with basic support. If they cannot resolve it, it goes to a technician. If the technician cannot resolve it, it escalates to a manager. Each level handles what it can and passes unsolved tickets up the chain.

**Document Approval Workflow**: A document starts with a department manager. If approved, it moves to the director. If the director approves, it goes to the executive level. Each person approves or rejects based on their authority level.

**Event Handling in UI Frameworks**: When you click a button in a web page, the event propagates up the DOM tree. Each element can handle the event or let it bubble up to parent elements.

## Pros and Cons

### Advantages
- **Loose Coupling**: Senders don't need to know about specific receivers
- **Dynamic Chains**: Build and modify chains at runtime
- **Single Responsibility**: Each handler focuses on one task
- **Flexible Processing**: Easy to add, remove, or reorder handlers
- **Open/Closed Principle**: New handlers can be added without modifying existing code

### Disadvantages
- **No Guarantee of Handling**: Request might not be handled if no handler accepts it
- **Performance Overhead**: Traversing the chain can impact performance
- **Debugging Difficulty**: Hard to trace which handler actually processed a request
- **Chain Visibility**: Difficult to understand which handler will process a request
- **Memory Overhead**: Chain of references consumes memory

## Relations with Other Patterns

- **Command**: Can be combined to encapsulate requests
- **Observer**: Both can be used for event handling but differ in approach
- **Strategy**: Both encapsulate algorithms but Strategy is typically chosen upfront
- **Composite**: Often used together when building tree structures
- **Responsibility Pattern**: Chain of Responsibility implements the Single Responsibility Principle

## Examples in Other Languages

### Java

Before and after comparison showing how the Chain of Responsibility pattern eliminates explicit handler selection logic:

```java
// After: handlers are linked in a chain and delegate automatically
class Handler {
    private final static Random RANDOM = new Random();
    private static int nextID = 1;
    private int id = nextID++;
    private Handler nextInChain;

    public void add(Handler next) {
        if (nextInChain == null) {
            nextInChain = next;
        } else {
            nextInChain.add(next);
        }
    }

    public void wrapAround(Handler root) {
        if (nextInChain == null) {
            nextInChain = root;
        } else {
            nextInChain.wrapAround(root);
        }
    }

    public void execute(int num) {
        if (RANDOM.nextInt(4) != 0) {
            System.out.println("   " + id + "-busy  ");
            nextInChain.execute(num);
        } else {
            System.out.println(id + "-handled-" + num);
        }
    }
}

public class ChainDemo {
    public static void main(String[] args) {
        Handler rootChain = new Handler();
        rootChain.add(new Handler());
        rootChain.add(new Handler());
        rootChain.add(new Handler());
        rootChain.wrapAround(rootChain);
        for (int i = 1; i < 6; i++) {
            System.out.println("Operation #" + i + ":");
            rootChain.execute(i);
            System.out.println();
        }
    }
}
```

### Python

```python
import abc


class Handler(metaclass=abc.ABCMeta):
    """
    Define an interface for handling requests.
    Implement the successor link.
    """

    def __init__(self, successor=None):
        self._successor = successor

    @abc.abstractmethod
    def handle_request(self):
        pass


class ConcreteHandler1(Handler):
    """
    Handle request, otherwise forward it to the successor.
    """

    def handle_request(self):
        if True:  # if can_handle:
            pass
        elif self._successor is not None:
            self._successor.handle_request()


class ConcreteHandler2(Handler):
    """
    Handle request, otherwise forward it to the successor.
    """

    def handle_request(self):
        if False:  # if can_handle:
            pass
        elif self._successor is not None:
            self._successor.handle_request()


def main():
    concrete_handler_1 = ConcreteHandler1()
    concrete_handler_2 = ConcreteHandler2(concrete_handler_1)
    concrete_handler_2.handle_request()


if __name__ == "__main__":
    main()
```

### C++

```cpp
#include <iostream>
#include <vector>
#include <ctime>
using namespace std;

class Base
{
    Base *next;
  public:
    Base()
    {
        next = 0;
    }
    void setNext(Base *n)
    {
        next = n;
    }
    void add(Base *n)
    {
        if (next)
          next->add(n);
        else
          next = n;
    }
    virtual void handle(int i)
    {
        next->handle(i);
    }
};

class Handler1: public Base
{
  public:
     void handle(int i)
    {
        if (rand() % 3)
        {
            cout << "H1 passed " << i << "  ";
            Base::handle(i);
        }
        else
          cout << "H1 handled " << i << "  ";
    }
};

class Handler2: public Base
{
  public:
     void handle(int i)
    {
        if (rand() % 3)
        {
            cout << "H2 passed " << i << "  ";
            Base::handle(i);
        }
        else
          cout << "H2 handled " << i << "  ";
    }
};

class Handler3: public Base
{
  public:
     void handle(int i)
    {
        if (rand() % 3)
        {
            cout << "H3 passed " << i << "  ";
            Base::handle(i);
        }
        else
          cout << "H3 handled " << i << "  ";
    }
};

int main()
{
  srand(time(0));
  Handler1 root;
  Handler2 two;
  Handler3 thr;
  root.add(&two);
  root.add(&thr);
  thr.setNext(&root);
  for (int i = 1; i < 10; i++)
  {
    root.handle(i);
    cout << '\n';
  }
}
```

## Overview

The Command pattern is a behavioral design pattern that encapsulates operations as standalone objects, making them storable, transferable, queueable, loggable, and reversible. By reifying a request into an object, it draws a clean line between the code that initiates an action and the code that performs it.

## Intent

- Turn an operation into a first-class object that can be passed, stored, or serialized like any other value
- Let callers issue, defer, or enqueue operations without knowing who ultimately executes them
- Support undo and redo by keeping a trail of executed command objects
- Provide a natural foundation for operation logging, auditing, and transactional rollback
- Decouple the responsibility of requesting work from the responsibility of carrying it out

## Problem/Solution

### Problem
Many applications share a common set of needs:
- Deferring or scheduling operations for later execution
- Providing undo and redo capabilities for user actions
- Maintaining a complete audit log of every operation performed
- Transmitting requests across process or network boundaries
- Routing operations between loosely coupled subsystems

Wiring clients directly to the business logic that fulfills these requests makes all of these requirements difficult to retrofit and painful to maintain.

### Solution
Define a Command interface that represents a request as an object. Each concrete command bundles together:
- The specific operation to carry out
- The receiver object that performs the work
- All parameters the operation requires
- The logic to execute the operation and, optionally, to reverse it

## Structure

```
┌──────────────┐
│   Client     │
└──────────────┘
       │
       │ creates
       ↓
┌──────────────────┐      ┌────────────────┐
│  Command (I)     │◄─────│  ConcreteCmd   │
└──────────────────┘      └────────────────┘
   execute()                  receiver
   undo()                      execute()
       ▲                       undo()
       │
       │ executes
       │
┌──────────────┐
│  Invoker     │
└──────────────┘
   commands: []
   execute()
   undo()
```

### Key Components

- **Command**: Interface defining execute() and optional undo() methods
- **ConcreteCommand**: Implements Command, holds receiver reference and parameters
- **Invoker**: Requests command execution, may queue or schedule commands
- **Receiver**: Performs actual work; command knows how to invoke receiver methods

## When to Use

- You need to parameterize objects with operations
- Queue, schedule, or execute operations at different times
- Support undo/redo functionality
- Log and audit all operations performed
- Support transactional operations (all-or-nothing)
- Build macro commands from simpler commands
- Decouple command senders from executors

## Implementation (PHP 8.3+)

```php
<?php

declare(strict_types=1);

// Command Interface
interface Command
{
    public function execute(): void;
    public function undo(): void;
}

// Receiver - Document class
readonly class Document
{
    private string $content;

    public function __construct(string $initialContent = '')
    {
        $this->content = $initialContent;
    }

    public function getContent(): string
    {
        return $this->content;
    }
}

// Mutable Document with history
class EditableDocument
{
    private string $content = '';
    /** @var string[] */
    private array $history = [];

    public function write(string $text): void
    {
        $this->history[] = $this->content;
        $this->content .= $text;
    }

    public function clear(): void
    {
        $this->history[] = $this->content;
        $this->content = '';
    }

    public function undo(): void
    {
        if (!empty($this->history)) {
            $this->content = array_pop($this->history);
        }
    }

    public function getContent(): string
    {
        return $this->content;
    }
}

// Concrete Commands
final class WriteCommand implements Command
{
    public function __construct(
        private readonly EditableDocument $document,
        private readonly string $text
    ) {}

    public function execute(): void
    {
        $this->document->write($this->text);
    }

    public function undo(): void
    {
        $this->document->undo();
    }
}

final class ClearCommand implements Command
{
    public function __construct(
        private readonly EditableDocument $document
    ) {}

    public function execute(): void
    {
        $this->document->clear();
    }

    public function undo(): void
    {
        $this->document->undo();
    }
}

// Invoker - Command Queue
final class CommandInvoker
{
    /** @var Command[] */
    private array $history = [];
    /** @var Command[] */
    private array $undoStack = [];

    public function execute(Command $command): void
    {
        $command->execute();
        $this->history[] = $command;
        $this->undoStack = [];
    }

    public function undo(): void
    {
        if (empty($this->history)) {
            return;
        }

        $command = array_pop($this->history);
        $command->undo();
        $this->undoStack[] = $command;
    }

    public function redo(): void
    {
        if (empty($this->undoStack)) {
            return;
        }

        $command = array_pop($this->undoStack);
        $command->execute();
        $this->history[] = $command;
    }

    /** @return Command[] */
    public function getHistory(): array
    {
        return $this->history;
    }
}

// Usage Example
$document = new EditableDocument();
$invoker = new CommandInvoker();

$invoker->execute(new WriteCommand($document, 'Hello '));
$invoker->execute(new WriteCommand($document, 'World'));
echo $document->getContent(); // "Hello World"

$invoker->undo();
echo $document->getContent(); // "Hello "

$invoker->redo();
echo $document->getContent(); // "Hello World"
```

## Real-World Analogies

**Diner Order Ticket**: A customer scribbles their order on a slip and passes it to the counter. The slip waits in a queue until a cook picks it up and prepares the meal. The ticket is the command - it records what to make, who asked, and can be tracked or cancelled before cooking starts.

**Air Traffic Control Clearances**: A controller issues takeoff and landing clearances as discrete instructions. Each instruction is logged, can be revoked, and is carried out by the pilot independently of the controller's subsequent decisions.

**Spreadsheet Macro Recording**: Recording a macro captures each user action as an individual command object. Playback re-executes the sequence in order, and the user can edit, reorder, or delete individual steps afterward.

## Pros and Cons

### Pros
- Draws a sharp boundary between the requester and the executor, so neither depends on the other
- Makes undo and redo natural by preserving a history stack of executed command objects
- Lends itself to batching, scheduling, and deferred execution without additional infrastructure
- New command types slot in without modifying existing invoker or receiver code
- Produces a built-in audit trail of every operation the system has performed
- Commands are portable values - they can be serialized, persisted, or transmitted across process boundaries

### Cons
- Generates a high number of small classes, one per operation, which can fragment a codebase
- The extra indirection layer between invoker and receiver adds abstraction overhead and memory use
- Excessive for simple method calls that need neither queuing nor reversal
- Reliable undo requires disciplined state tracking or snapshot management that complicates implementation

## Relations with Other Patterns

- **Prototype**: Commands can be cloned to produce copies for batch processing or deferred execution
- **Chain of Responsibility**: Commands can travel through a handler chain where each link decides whether to act or delegate
- **Observer**: The invoker can notify subscribers when a command completes, enabling reactive workflows
- **Memento**: Captures the receiver's state before execution, letting commands undo changes without deep-copying entire object graphs
- **Composite**: Several commands can be assembled into a macro command that executes them as a single unit
- **Template Method**: Provides a fixed execution skeleton while individual command subclasses override specific steps
- **Strategy**: Both objectify behavior, but Strategy swaps interchangeable algorithms while Command encapsulates discrete requests

## Examples in Other Languages

### Java

Decoupling producer from consumer using a command queue:

```java
interface Command {
    void execute();
}

class DomesticEngineer implements Command {
    public void execute() {
        System.out.println("take out the trash");
    }
}

class Politician implements Command {
    public void execute() {
        System.out.println("take money from the rich, take votes from the poor");
    }
}

class Programmer implements Command {
    public void execute() {
        System.out.println("sell the bugs, charge extra for the fixes");
    }
}

public class CommandDemo {
    public static List produceRequests() {
        List<Command> queue = new ArrayList<>();
        queue.add(new DomesticEngineer());
        queue.add(new Politician());
        queue.add(new Programmer());
        return queue;
    }

    public static void workOffRequests(List queue) {
        for (Object command : queue) {
            ((Command)command).execute();
        }
    }

    public static void main(String[] args) {
        List queue = produceRequests();
        workOffRequests(queue);
    }
}
```

### Python

```python
import abc


class Invoker:
    """
    Ask the command to carry out the request.
    """

    def __init__(self):
        self._commands = []

    def store_command(self, command):
        self._commands.append(command)

    def execute_commands(self):
        for command in self._commands:
            command.execute()


class Command(metaclass=abc.ABCMeta):
    """
    Declare an interface for executing an operation.
    """

    def __init__(self, receiver):
        self._receiver = receiver

    @abc.abstractmethod
    def execute(self):
        pass


class ConcreteCommand(Command):
    """
    Define a binding between a Receiver object and an action.
    Implement Execute by invoking the corresponding operation(s) on
    Receiver.
    """

    def execute(self):
        self._receiver.action()


class Receiver:
    """
    Know how to perform the operations associated with carrying out a
    request. Any class may serve as a Receiver.
    """

    def action(self):
        pass


def main():
    receiver = Receiver()
    concrete_command = ConcreteCommand(receiver)
    invoker = Invoker()
    invoker.store_command(concrete_command)
    invoker.execute_commands()


if __name__ == "__main__":
    main()
```

### C++

Before and after: using member function pointers to encapsulate commands:

```cpp
class Giant
{
  public:
    Giant()
    {
        m_id = s_next++;
    }
    void fee()
    {
        cout << m_id << "-fee  ";
    }
    void phi()
    {
        cout << m_id << "-phi  ";
    }
    void pheaux()
    {
        cout << m_id << "-pheaux  ";
    }
  private:
    int m_id;
    static int s_next;
};
int Giant::s_next = 0;

class Command
{
  public:
    typedef void(Giant:: *Action)();
    Command(Giant *object, Action method)
    {
        m_object = object;
        m_method = method;
    }
    void execute()
    {
        (m_object-> *m_method)();
    }
  private:
    Giant *m_object;
    Action m_method;
};

template <typename T> class Queue
{
  public:
    Queue()
    {
        m_add = m_remove = 0;
    }
    void enque(T *c)
    {
        m_array[m_add] = c;
        m_add = (m_add + 1) % SIZE;
    }
    T *deque()
    {
        int temp = m_remove;
        m_remove = (m_remove + 1) % SIZE;
        return m_array[temp];
    }
  private:
    enum
    {
        SIZE = 8
    };
    T *m_array[SIZE];
    int m_add, m_remove;
};

int main()
{
  Queue<Command> que;
  Command *input[] =
  {
    new Command(new Giant, &Giant::fee),
    new Command(new Giant, &Giant::phi),
    new Command(new Giant, &Giant::pheaux),
    new Command(new Giant, &Giant::fee),
    new Command(new Giant, &Giant::phi),
    new Command(new Giant, &Giant::pheaux)
  };

  for (int i = 0; i < 6; i++)
    que.enque(input[i]);

  for (int i = 0; i < 6; i++)
    que.deque()->execute();
  cout << '\n';
}
```

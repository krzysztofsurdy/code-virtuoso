## Overview

The Command design pattern is a behavioral pattern that converts requests or operations into standalone objects that can be parameterized, queued, logged, or undone. It decouples the object that issues an operation from the objects that actually perform it.

## Intent

- Encapsulate a request as an object
- Parameterize clients with different requests, queue requests, and support undoable operations
- Support logging changes and transaction rollback
- Queue operations for delayed or batch execution
- Decouple command senders from command executors

## Problem/Solution

### Problem
In many applications, you need to:
- Queue operations for later execution
- Schedule operations to run at specific times
- Undo and redo user actions
- Log all operations performed
- Support remote execution of commands
- Pass requests between different parts of the application

Traditional approach of tightly coupling clients directly to business logic makes these requirements difficult to implement and maintain.

### Solution
Create a Command abstraction that wraps requests as objects. Each command encapsulates:
- The operation to perform
- The receiver of the operation
- The parameters needed
- The ability to execute and potentially undo

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

✓ You need to parameterize objects with operations
✓ Queue, schedule, or execute operations at different times
✓ Support undo/redo functionality
✓ Log and audit all operations performed
✓ Support transactional operations (all-or-nothing)
✓ Build macro commands from simpler commands
✓ Decouple command senders from executors

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

**Restaurant Orders**: A customer (client) places an order (command) with a waiter (invoker), who gives it to the kitchen (receiver) to prepare the dish. The order can be queued, modified before execution, or documented for history.

**Remote Control**: Buttons on a remote encapsulate commands (power on, volume up, channel change) that are sent to a TV or receiver without the remote needing to know TV internals.

**Undo in Text Editors**: Each keystroke or formatting change is a command that can be undone/redone by maintaining a command history stack.

**Transaction Logs**: Database transactions log all commands before execution, enabling rollback and audit trails.

## Pros and Cons

### Pros
✓ Decouples sender from receiver—invoker doesn't know command details
✓ Enables undo/redo functionality with history tracking
✓ Supports queuing, scheduling, and macro operations
✓ Easy to add new commands without modifying existing code
✓ Simplifies logging and auditing of operations
✓ Commands can be passed around and executed later

### Cons
✗ Can create many command classes, increasing code complexity
✗ Extra layer of indirection adds memory overhead
✗ May be overkill for simple operation calls
✗ Undo/redo requires maintaining complete state or history

## Relations with Other Patterns

- **Prototype**: Commands can be cloned to create copies for batch execution
- **Chain of Responsibility**: Commands can be chained in a handler sequence
- **Observer**: Invoker can notify observers when commands execute
- **Memento**: Captures command state for undo/redo without deep object copying
- **Macro Command**: Composite pattern combines multiple commands into one
- **Template Method**: Defines execution skeleton; Command defines variations
- **Strategy**: Both encapsulate behavior, but Strategy is for algorithm families; Command wraps requests

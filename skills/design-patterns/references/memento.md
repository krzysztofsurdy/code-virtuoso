## Overview

The Memento design pattern is a behavioral pattern that captures and externalizes an object's internal state at a particular moment without violating encapsulation. It allows you to restore the object to its previous state later. The pattern is essential for implementing undo/redo functionality, transaction rollback, and checkpoint management in applications.

## Intent

The Memento pattern addresses the need to save and restore object state while maintaining encapsulation:

- Capture an object's state without exposing its internal structure
- Restore objects to previous states
- Implement undo/redo functionality
- Create checkpoints for complex operations
- Maintain state history for audit trails

## Problem and Solution

**Problem:** You need to save and restore an object's state, but accessing its private fields violates encapsulation. Creating backup copies by exposing all attributes is dangerous and coupling implementations.

**Solution:** Create a Memento object that stores the internal state. The originating object creates mementos when state needs saving. A Caretaker manages the collection of mementos. The originating object can restore itself from a memento without the caretaker knowing details about the state structure.

## Structure

The Memento pattern involves three key participants:

- **Originator:** The object whose state needs to be saved (creates mementos)
- **Memento:** Stores the internal state of the originator (immutable snapshot)
- **Caretaker:** Manages a collection of mementos without modifying them

The pattern maintains a clear separation between the originator (knows state details), memento (stores state), and caretaker (manages history without knowing state).

## When to Use

Use the Memento pattern when:

- Implementing undo/redo functionality in editors or applications
- You need to save and restore object state at different points
- Implementing transaction rollback mechanisms
- Creating checkpoint/save system functionality
- Building audit trails of state changes
- You want to maintain encapsulation while managing state history
- Complex objects need state snapshots without exposing internals

## Implementation (PHP 8.3+)

```php
<?php declare(strict_types=1);

namespace DesignPatterns\Behavioral\Memento;

// Memento: Stores the internal state snapshot
readonly class EditorMemento {
    public function __construct(
        private string $content,
        private int $cursorPosition,
        private array $selection
    ) {}

    public function getContent(): string {
        return $this->content;
    }

    public function getCursorPosition(): int {
        return $this->cursorPosition;
    }

    public function getSelection(): array {
        return $this->selection;
    }
}

// Originator: Creates and uses mementos
class TextEditor {
    private string $content = '';
    private int $cursorPosition = 0;
    private array $selection = [];

    public function write(string $text): void {
        $this->content .= $text;
        $this->cursorPosition += strlen($text);
    }

    public function delete(int $count): void {
        $this->content = substr($this->content, 0, -$count);
        $this->cursorPosition = max(0, $this->cursorPosition - $count);
    }

    public function moveCursor(int $position): void {
        $this->cursorPosition = max(0, min($position, strlen($this->content)));
    }

    public function select(int $start, int $end): void {
        $this->selection = ['start' => $start, 'end' => $end];
    }

    public function createMemento(): EditorMemento {
        return new EditorMemento(
            $this->content,
            $this->cursorPosition,
            $this->selection
        );
    }

    public function restoreFromMemento(EditorMemento $memento): void {
        $this->content = $memento->getContent();
        $this->cursorPosition = $memento->getCursorPosition();
        $this->selection = $memento->getSelection();
    }

    public function getState(): string {
        return "Content: {$this->content} | " .
               "Cursor: {$this->cursorPosition} | " .
               "Selection: " . json_encode($this->selection);
    }
}

// Caretaker: Manages memento history
class EditorHistory {
    /** @var EditorMemento[] */
    private array $history = [];
    private int $currentIndex = -1;

    public function save(TextEditor $editor): void {
        // Remove any redo history when new change is made
        $this->history = array_slice($this->history, 0, $this->currentIndex + 1);
        $this->history[] = $editor->createMemento();
        $this->currentIndex++;
    }

    public function undo(TextEditor $editor): bool {
        if ($this->currentIndex > 0) {
            $this->currentIndex--;
            $editor->restoreFromMemento($this->history[$this->currentIndex]);
            return true;
        }
        return false;
    }

    public function redo(TextEditor $editor): bool {
        if ($this->currentIndex < count($this->history) - 1) {
            $this->currentIndex++;
            $editor->restoreFromMemento($this->history[$this->currentIndex]);
            return true;
        }
        return false;
    }

    public function canUndo(): bool {
        return $this->currentIndex > 0;
    }

    public function canRedo(): bool {
        return $this->currentIndex < count($this->history) - 1;
    }
}

// Client code
$editor = new TextEditor();
$history = new EditorHistory();

$editor->write('Hello');
$history->save($editor);
echo $editor->getState() . "\n"; // Content: Hello | Cursor: 5 | Selection: []

$editor->write(' World');
$history->save($editor);
echo $editor->getState() . "\n"; // Content: Hello World | Cursor: 11 | Selection: []

$editor->select(0, 5);
$history->save($editor);
echo $editor->getState() . "\n"; // Content: Hello World | Cursor: 11 | Selection: {"start":0,"end":5}

// Undo operations
if ($history->canUndo()) {
    $history->undo($editor);
    echo "After undo: " . $editor->getState() . "\n";
}

if ($history->canUndo()) {
    $history->undo($editor);
    echo "After undo: " . $editor->getState() . "\n";
}

// Redo operation
if ($history->canRedo()) {
    $history->redo($editor);
    echo "After redo: " . $editor->getState() . "\n";
}
```

## Real-World Analogies

- **Save/Load in Video Games:** Saving game progress creates a memento; loading restores the exact state including position, inventory, and quests.
- **Ctrl+Z in Text Editors:** Each keystroke creates a memento; undo/redo navigates through the history.
- **Database Transaction Rollback:** Savepoints act as mementos; rollback restores the state before a transaction.
- **Photography:** Taking a photo captures a moment in time; you can look back at past photographs without modifying the present.
- **Version Control Systems:** Commits are mementos of project state; you can checkout previous versions.

## Pros and Cons

**Pros:**
- Maintains Encapsulation: State is captured without exposing internal structure
- Simplifies Originator: Doesn't manage its own history
- Clear Responsibility: Each class has a single, well-defined role
- Enables Undo/Redo: Natural implementation of history-based features
- Immutable Mementos: Prevents accidental state modification
- Flexible History: Caretaker can implement various history strategies

**Cons:**
- Memory Overhead: Storing many mementos consumes significant memory
- Performance Impact: Creating mementos can be expensive for large objects
- Complex Management: Caretaker logic can become complicated
- Serialization Issues: Deep copying large objects is resource-intensive
- Limited Granularity: Captures entire state; can't selectively save properties
- Cleanup Challenges: Managing memory when history grows unbounded

## Relations with Other Patterns

- **Command:** Often works with Memento; commands create mementos before execution
- **Iterator:** Caretaker can use Iterator to traverse memento history
- **Prototype:** Similar intent (copying state); Memento maintains encapsulation better
- **Singleton:** Caretaker is often a singleton managing global undo/redo
- **Strategy:** Can combine to implement different history management strategies
- **Observer:** Notify observers when state changes and mementos are created

## Additional Considerations

**Memory Management:**
- Limit history size to prevent unbounded memory growth
- Implement lazy copying for large objects
- Consider compression for stored mementos

**Serialization:**
- Use `readonly` properties for immutability
- Consider serializing mementos for persistent storage
- Handle version compatibility when deserializing

**Thread Safety:**
- Synchronize access to shared history in concurrent environments
- Use immutable mementos to prevent race conditions

**Advanced Techniques:**
- Implement delta-based mementos storing only changes
- Use weak references for automatic cleanup
- Combine with Command pattern for sophisticated transaction systems

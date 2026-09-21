# Memento Pattern

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem and solution](#problem-and-solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation (PHP 8.3+)](#implementation-php-83)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Additional considerations](#additional-considerations)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Memento is a behavioral design pattern that captures an object's internal state at a specific moment and stores it externally without breaking encapsulation. The object can later be rolled back to any captured snapshot. It underlies undo/redo systems, transaction rollback, and checkpoint-based recovery.

## Intent

Memento preserves and restores object state while keeping internal details private:

- Capture an object's complete state in an opaque token that outsiders cannot inspect or tamper with
- Restore the object to any previously saved state on demand
- Support undo, redo, and multi-level rollback
- Create named checkpoints before risky or complex operations
- Build audit trails by recording sequential state changes

## Problem and solution

**Problem:** An application needs to save an object's state and later rewind to it, but exposing internal fields through public getters to make copies breaks encapsulation. Callers become coupled to the object's implementation details, and any structural change breaks every backup site.

**Solution:** Let the object produce a memento, a sealed snapshot of its own internals. A separate caretaker stores and retrieves mementos without knowing what is inside them. To roll back, the originator accepts a memento and restores itself from it, so all state management stays behind its own API.

## Structure

Memento involves three participants:

- **Originator:** the object whose state is saved (it creates mementos)
- **Memento:** an immutable snapshot of the originator's internal state
- **Caretaker:** manages a collection of mementos without modifying them

The originator knows the state details, the memento stores them, and the caretaker manages history without knowing what the state contains.

## When to use

Use Memento when:

- You are implementing undo/redo in an editor or application
- You need to save and restore object state at different points
- You are implementing transaction rollback
- You are building checkpoint or save-game functionality
- You are building audit trails of state changes
- State history must be managed without breaking encapsulation
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
$history->save($editor); // initial empty state, so the first undo can return to it

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

## Real-world analogies

- **Bookmark in a book**: a bookmark captures your exact position. You can read ahead and then return to the bookmarked page without remembering the page number yourself, because the bookmark holds that state.
- **Database savepoints**: before running a batch of risky SQL statements, you create a savepoint. If anything goes wrong, you roll back to it and the database reverts to its earlier state without losing unrelated work.
- **Time Machine backups**: macOS Time Machine takes periodic snapshots of the disk. You can browse to any past snapshot and restore individual files or the whole system without knowing the internal file-system layout.

## Pros and cons

**Pros:**
- State is saved and restored without exposing or coupling to internal structure
- The originator does not have to manage its own history stack
- Each participant has a narrow, well-defined responsibility
- Undo and redo follow naturally from a sequence of mementos
- Readonly mementos prevent accidental or malicious state tampering
- The caretaker can implement different retention policies (fixed window, time-based, and so on)

**Cons:**
- Storing many complete snapshots can use a lot of memory
- Deep-copying large or complex objects has a real performance cost
- History management logic in the caretaker can grow complicated
- Serializing rich object graphs into mementos is non-trivial
- The pattern captures all-or-nothing state; selective field-level snapshots take extra work
- Unbounded history growth needs an explicit eviction or pruning strategy

## Relations with other patterns

- **Command:** commands often create mementos before execution so they can undo their effects
- **Iterator:** the caretaker can use an iterator to walk through stored mementos
- **Prototype:** both copy object state, but Memento preserves encapsulation while Prototype focuses on cloning
- **Singleton:** a global caretaker is sometimes implemented as a singleton
- **Strategy:** different memento retention strategies (keep the last N, compress old snapshots) can be swapped via Strategy
- **Observer:** observers can be notified whenever a new memento is created or a rollback occurs

## Additional considerations

**Memory management:**
- Limit history size to prevent unbounded memory growth
- Use lazy copying for large objects
- Consider compressing stored mementos

**Serialization:**
- Use `readonly` properties for immutability
- Consider serializing mementos for persistent storage
- Handle version compatibility when deserializing

**Thread safety:**
- Synchronize access to shared history in concurrent environments
- Use immutable mementos to prevent race conditions

**Advanced techniques:**
- Use delta-based mementos that store only changes
- Use weak references for automatic cleanup
- Combine with Command for transaction-style systems

## Examples in other languages

### Java

```java
import java.util.ArrayList;

class Memento {
    private String state;

    public Memento(String state) {
        this.state = state;
    }

    public String getState() {
        return state;
    }
}

class Originator {
    private String state;

    public void setState(String state) {
        System.out.println("Originator: Setting state to " + state);
        this.state = state;
    }

    public Memento save() {
        System.out.println("Originator: Saving to Memento.");
        return new Memento(state);
    }

    public void restore(Memento m) {
        state = m.getState();
        System.out.println("Originator: State after restoring from Memento: " + state);
    }
}

class Caretaker {
    private ArrayList<Memento> mementos = new ArrayList<>();

    public void addMemento(Memento m) {
        mementos.add(m);
    }

    public Memento getMemento() {
        return mementos.get(1);
    }
}

public class MementoDemo {
    public static void main(String[] args) {
        Caretaker caretaker = new Caretaker();
        Originator originator = new Originator();
        originator.setState("State1");
        originator.setState("State2");
        caretaker.addMemento(originator.save());
        originator.setState("State3");
        caretaker.addMemento(originator.save());
        originator.setState("State4");
        originator.restore(caretaker.getMemento());
    }
}
```

### C++

```cpp
#include <iostream>
using namespace std;

class Number;

class Memento {
  public:
    Memento(int val) {
        _state = val;
    }
  private:
    friend class Number;
    int _state;
};

class Number {
  public:
    Number(int value) {
        _value = value;
    }
    void dubble() {
        _value = 2 * _value;
    }
    void half() {
        _value = _value / 2;
    }
    int getValue() {
        return _value;
    }
    Memento *createMemento() {
        return new Memento(_value);
    }
    void reinstateMemento(Memento *mem) {
        _value = mem->_state;
    }
  private:
    int _value;
};

class Command {
  public:
    typedef void(Number::*Action)();
    Command(Number *receiver, Action action) {
        _receiver = receiver;
        _action = action;
    }
    virtual void execute() {
        _mementoList[_numCommands] = _receiver->createMemento();
        _commandList[_numCommands] = this;
        if (_numCommands > _highWater)
            _highWater = _numCommands;
        _numCommands++;
        (_receiver->*_action)();
    }
    static void undo() {
        if (_numCommands == 0) {
            cout << "*** Attempt to run off the end!! ***" << endl;
            return;
        }
        _commandList[_numCommands - 1]->_receiver->reinstateMemento(
            _mementoList[_numCommands - 1]);
        _numCommands--;
    }
    void static redo() {
        if (_numCommands > _highWater) {
            cout << "*** Attempt to run off the end!! ***" << endl;
            return;
        }
        (_commandList[_numCommands]->_receiver
            ->*(_commandList[_numCommands]->_action))();
        _numCommands++;
    }
  protected:
    Number *_receiver;
    Action _action;
    static Command *_commandList[20];
    static Memento *_mementoList[20];
    static int _numCommands;
    static int _highWater;
};

Command *Command::_commandList[];
Memento *Command::_mementoList[];
int Command::_numCommands = 0;
int Command::_highWater = 0;

int main() {
    int i;
    cout << "Integer: ";
    cin >> i;
    Number *object = new Number(i);

    Command *commands[3];
    commands[1] = new Command(object, &Number::dubble);
    commands[2] = new Command(object, &Number::half);

    cout << "Exit[0], Double[1], Half[2], Undo[3], Redo[4]: ";
    cin >> i;

    while (i) {
        if (i == 3)
            Command::undo();
        else if (i == 4)
            Command::redo();
        else
            commands[i]->execute();
        cout << "   " << object->getValue() << endl;
        cout << "Exit[0], Double[1], Half[2], Undo[3], Redo[4]: ";
        cin >> i;
    }
}
```

### Python

```python
import pickle


class Originator:
    """
    Create a memento containing a snapshot of its current internal state.
    Use the memento to restore its internal state.
    """

    def __init__(self):
        self._state = None

    def set_memento(self, memento):
        previous_state = pickle.loads(memento)
        vars(self).clear()
        vars(self).update(previous_state)

    def create_memento(self):
        return pickle.dumps(vars(self))


def main():
    originator = Originator()
    memento = originator.create_memento()
    originator._state = True
    originator.set_memento(memento)


if __name__ == "__main__":
    main()
```

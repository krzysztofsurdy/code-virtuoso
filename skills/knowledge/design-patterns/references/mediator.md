# Mediator Pattern

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

Mediator is a behavioral design pattern that routes all communication between a group of collaborating objects through a single coordinator. Instead of holding references to every peer it talks to, each object notifies the mediator, which decides how to route and handle the interaction. A tangled mesh of point-to-point connections becomes a hub-and-spoke layout.

## Intent

- Centralize the rules governing how a group of objects interact in one dedicated object
- Remove direct references between collaborating objects so they stay independent
- Consolidate scattered interaction logic in one inspectable place
- Make components reusable in other contexts by removing peer dependencies
- Simplify testing by isolating coordination logic from component behavior

## Problem and solution

### Problem

When several objects need to communicate, direct references between them create tight coupling:

1. **Tight coupling**: every object knows about every other object it talks to
2. **Difficult reuse**: objects cannot be reused elsewhere because they depend on specific communication partners
3. **Scattered logic**: communication logic is spread across several classes, which makes it hard to understand and modify
4. **Costly changes**: changing how objects communicate means modifying several classes

### Solution

Create a mediator class that encapsulates all communication logic between the objects. The objects talk to the mediator instead of to each other, and the mediator coordinates the interactions. Individual objects stay independent and reusable.

## Structure

```
┌─────────────────────────────────────────────────────────────┐
│                        Mediator                             │
│                    (interface/abstract)                     │
│                                                             │
│  + createColleagues()                                       │
│  + send(message, colleague)                                │
└─────────────────────────────────────────────────────────────┘
                          △
                          │
                          │ implements/extends
                          │
         ┌────────────────┴────────────────┐
         │                                 │
    ConcreteMediator              ConcreteMediator2
    + createColleagues()          + createColleagues()
    + send(msg, colleague)        + send(msg, colleague)
         △                             △
         │ uses                        │ uses
         │                             │
    ┌────┴─────┐                   ┌───┴────┐
    │           │                   │        │
 Colleague  Colleague            Colleague Colleague
   (base)      impl               (base)    impl
```

## When to use

- A cluster of objects communicates in ways that produce dependencies that are hard to follow or modify
- A component cannot be reused because it carries references to many specific peers
- Interaction behavior spread across several classes must be customizable without deep subclassing
- You want a single place to inspect and adjust how components coordinate
- Components should be testable in isolation, without wiring up all their communication partners

## Implementation

### PHP 8.3+ example: chat room mediator

```php
<?php
declare(strict_types=1);

// Abstract Mediator
interface ChatRoomMediator {
    public function displayMessage(User $user, string $message): void;
    public function addUser(User $user): void;
}

// Concrete Mediator
class ChatRoom implements ChatRoomMediator {
    private array $users = [];

    public function addUser(User $user): void {
        $this->users[$user->getName()] = $user;
        $user->setMediator($this);
    }

    public function displayMessage(User $user, string $message): void {
        $timestamp = date('Y-m-d H:i:s');
        $formattedMessage = "[{$timestamp}] {$user->getName()}: {$message}";
        echo "{$formattedMessage}\n";

        // Notify other users
        foreach ($this->users as $recipient) {
            if ($recipient->getName() !== $user->getName()) {
                $recipient->notify($formattedMessage);
            }
        }
    }
}

// Abstract Colleague
abstract class User {
    protected ChatRoomMediator $mediator;
    private readonly string $name;

    public function __construct(string $name) {
        $this->name = $name;
    }

    public function setMediator(ChatRoomMediator $mediator): void {
        $this->mediator = $mediator;
    }

    public function getName(): string {
        return $this->name;
    }

    public function send(string $message): void {
        $this->mediator->displayMessage($this, $message);
    }

    abstract public function notify(string $message): void;
}

// Concrete Colleague
class ChatUser extends User {
    public function notify(string $message): void {
        echo "[{$this->getName()} received]: {$message}\n";
    }
}

// Usage
$chatRoom = new ChatRoom();

$user1 = new ChatUser('Alice');
$user2 = new ChatUser('Bob');
$user3 = new ChatUser('Charlie');

$chatRoom->addUser($user1);
$chatRoom->addUser($user2);
$chatRoom->addUser($user3);

$user1->send('Hello everyone!');
$user2->send('Hi Alice!');
$user3->send('Hey there!');
```

### Real-world example: dialog box with controls

```php
<?php
declare(strict_types=1);

interface DialogMediator {
    public function notify(DialogElement $sender, string $event): void;
}

readonly class LoginDialog implements DialogMediator {
    public function __construct(
        private TextBox $loginUsername,
        private TextBox $loginPassword,
        private Checkbox $rememberMe,
        private Button $okBtn,
        private Button $cancelBtn
    ) {
        $this->okBtn->setMediator($this);
        $this->cancelBtn->setMediator($this);
        $this->loginUsername->setMediator($this);
        $this->loginPassword->setMediator($this);
        $this->rememberMe->setMediator($this);
    }

    public function notify(DialogElement $sender, string $event): void {
        match ($sender::class . '::' . $event) {
            TextBox::class . '::editingFinished' => $this->validateInput($sender),
            Button::class . '::clicked' => $this->handleButtonClick($sender),
            default => null,
        };
    }

    private function validateInput(DialogElement $sender): void {
        if ($sender === $this->loginUsername && empty($this->loginUsername->getText())) {
            echo "Username cannot be empty\n";
        }
    }

    private function handleButtonClick(DialogElement $sender): void {
        if ($sender === $this->okBtn) {
            echo "Logging in: {$this->loginUsername->getText()}\n";
        } elseif ($sender === $this->cancelBtn) {
            echo "Cancel button pressed\n";
        }
    }
}

abstract class DialogElement {
    protected ?DialogMediator $mediator = null;

    public function setMediator(DialogMediator $mediator): void {
        $this->mediator = $mediator;
    }
}

class TextBox extends DialogElement {
    private string $text = '';

    public function setText(string $text): void {
        $this->text = $text;
        $this->mediator?->notify($this, 'editingFinished');
    }

    public function getText(): string {
        return $this->text;
    }
}

class Checkbox extends DialogElement {
    private bool $checked = false;

    public function setChecked(bool $checked): void {
        $this->checked = $checked;
        $this->mediator?->notify($this, 'stateChanged');
    }
}

class Button extends DialogElement {
    public function click(): void {
        $this->mediator?->notify($this, 'clicked');
    }
}
```

## Real-world analogies

**Airport control tower**: pilots never negotiate runway access directly with other aircraft. Every request goes through the tower, which has the full picture of traffic, weather, and runway status.

**Stock exchange trading floor**: buyers and sellers do not find each other individually. The exchange acts as mediator, matching orders, enforcing rules, and settling trades on behalf of all participants.

**Event coordinator at a conference**: speakers, sponsors, and attendees do not organize sessions among themselves. The coordinator schedules talks, assigns rooms, and relays changes, so everyone has a single point of contact.

## Pros and cons

### Advantages

- **Loose coupling**: components interact without holding references to one another
- **Single coordination point**: all interaction rules live in one class, so they are easy to audit and change
- **Simpler relationships**: a web of many-to-many links becomes a star of one-to-many links
- **Portable components**: an object can be moved to a different mediator without modification
- **Focused responsibilities**: each object handles its own behavior while the mediator handles coordination

### Disadvantages

- **Bloated mediator**: a mediator that manages too many interactions can turn into a god object
- **Testing complexity**: a mediator with elaborate routing logic can be hard to unit test in isolation
- **Indirection cost**: the extra hop through the mediator adds latency on performance-sensitive paths
- **Premature abstraction**: a simple two-object interaction does not warrant a mediator
- **Rigid evolution**: changing the coordination rules may require significant rework inside the mediator

## Relations with other patterns

- **Observer**: both decouple communicating objects, but Observer broadcasts while Mediator routes centrally
- **Command**: mediators can receive command objects instead of raw messages, which makes interactions storable and undoable
- **Facade**: Facade simplifies a subsystem's interface for external callers; Mediator coordinates internal interactions among peers
- **State**: often combined so that state transitions trigger coordinated behavior across colleagues
- **Strategy**: Strategy swaps algorithms within a single object; Mediator swaps coordination rules across a group of objects

## Examples in other languages

### Java

Producer-consumer coordination through a mediator with a synchronized slot:

```java
class Mediator {
    private boolean slotFull = false;
    private int number;

    public synchronized void storeMessage(int num) {
        while (slotFull == true) {
            try {
                wait();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        slotFull = true;
        number = num;
        notifyAll();
    }

    public synchronized int retrieveMessage() {
        while (slotFull == false) {
            try {
                wait();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
        slotFull = false;
        notifyAll();
        return number;
    }
}

class Producer implements Runnable {
    private Mediator med;
    private int id;
    private static int num = 1;

    public Producer(Mediator m) {
        med = m;
        id = num++;
    }

    @Override
    public void run() {
        int num;
        while (true) {
            med.storeMessage(num = (int)(Math.random() * 100));
            System.out.print("p" + id + "-" + num + "  ");
        }
    }
}

class Consumer implements Runnable {
    private Mediator med;
    private int id;
    private static int num = 1;

    public Consumer(Mediator m) {
        med = m;
        id = num++;
    }

    @Override
    public void run() {
        while (true) {
            System.out.print("c" + id + "-" + med.retrieveMessage() + "  ");
        }
    }
}

public class MediatorDemo {
    public static void main(String[] args) {
        Mediator mb = new Mediator();
        new Thread(new Producer(mb)).start();
        new Thread(new Producer(mb)).start();
        new Thread(new Consumer(mb)).start();
        new Thread(new Consumer(mb)).start();
    }
}
```

### Python

```python
class Mediator:
    """
    Implement cooperative behavior by coordinating Colleague objects.
    Know and maintains its colleagues.
    """

    def __init__(self):
        self._colleague_1 = Colleague1(self)
        self._colleague_2 = Colleague2(self)


class Colleague1:
    """
    Know its Mediator object.
    Communicate with its mediator whenever it would have otherwise
    communicated with another colleague.
    """

    def __init__(self, mediator):
        self._mediator = mediator


class Colleague2:
    """
    Know its Mediator object.
    Communicate with its mediator whenever it would have otherwise
    communicated with another colleague.
    """

    def __init__(self, mediator):
        self._mediator = mediator


def main():
    mediator = Mediator()


if __name__ == "__main__":
    main()
```

### C++

File selection dialog mediator coordinating widget interactions:

```cpp
#include <iostream>
#include <cstring>
using namespace std;

class FileSelectionDialog;

class Widget
{
  public:
    Widget(FileSelectionDialog *mediator, char *name)
    {
        _mediator = mediator;
        strcpy(_name, name);
    }
    virtual void changed();
    virtual void updateWidget() = 0;
    virtual void queryWidget() = 0;
  protected:
    char _name[20];
  private:
    FileSelectionDialog *_mediator;
};

class List: public Widget
{
  public:
    List(FileSelectionDialog *dir, char *name): Widget(dir, name){}
    void queryWidget()
    {
        cout << "   " << _name << " list queried" << endl;
    }
    void updateWidget()
    {
        cout << "   " << _name << " list updated" << endl;
    }
};

class Edit: public Widget
{
  public:
    Edit(FileSelectionDialog *dir, char *name): Widget(dir, name){}
    void queryWidget()
    {
        cout << "   " << _name << " edit queried" << endl;
    }
    void updateWidget()
    {
        cout << "   " << _name << " edit updated" << endl;
    }
};

class FileSelectionDialog
{
  public:
    enum Widgets
    {
        FilterEdit, DirList, FileList, SelectionEdit
    };
    FileSelectionDialog()
    {
        _components[FilterEdit] = new Edit(this, "filter");
        _components[DirList] = new List(this, "dir");
        _components[FileList] = new List(this, "file");
        _components[SelectionEdit] = new Edit(this, "selection");
    }
    virtual ~FileSelectionDialog();
    void handleEvent(int which)
    {
        _components[which]->changed();
    }
    virtual void widgetChanged(Widget *theChangedWidget)
    {
        if (theChangedWidget == _components[FilterEdit])
        {
            _components[FilterEdit]->queryWidget();
            _components[DirList]->updateWidget();
            _components[FileList]->updateWidget();
            _components[SelectionEdit]->updateWidget();
        }
        else if (theChangedWidget == _components[DirList])
        {
            _components[DirList]->queryWidget();
            _components[FileList]->updateWidget();
            _components[FilterEdit]->updateWidget();
            _components[SelectionEdit]->updateWidget();
        }
        else if (theChangedWidget == _components[FileList])
        {
            _components[FileList]->queryWidget();
            _components[SelectionEdit]->updateWidget();
        }
        else if (theChangedWidget == _components[SelectionEdit])
        {
            _components[SelectionEdit]->queryWidget();
            cout << "   file opened" << endl;
        }
    }
  private:
    Widget *_components[4];
};

FileSelectionDialog::~FileSelectionDialog()
{
  for (int i = 0; i < 4; i++)
    delete _components[i];
}

void Widget::changed()
{
  _mediator->widgetChanged(this);
}

int main()
{
  FileSelectionDialog fileDialog;
  int i;
  cout << "Exit[0], Filter[1], Dir[2], File[3], Selection[4]: ";
  cin >> i;
  while (i)
  {
    fileDialog.handleEvent(i - 1);
    cout << "Exit[0], Filter[1], Dir[2], File[3], Selection[4]: ";
    cin >> i;
  }
}
```

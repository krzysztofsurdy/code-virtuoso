# Mediator Pattern

## Overview

The Mediator pattern is a behavioral design pattern that promotes loose coupling by keeping objects from referring to each other explicitly, instead letting them communicate through a mediator object. This pattern is particularly useful when a set of objects need to communicate in complex ways, and the resulting interdependencies are unstructured and difficult to understand.

## Intent

- Define an object that encapsulates how a set of objects interact
- Promote loose coupling by keeping objects from referring to each other explicitly
- Centralize complex communication and control logic
- Make it easier to maintain, test, and modify interaction logic
- Enable reuse of individual components in different contexts

## Problem & Solution

### Problem

When multiple objects need to communicate with each other, direct references between them create tight coupling:

1. **Tight Coupling**: Every object knows about every other object it needs to communicate with
2. **Difficult Reuse**: Objects cannot be reused in different contexts because they depend on specific communication partners
3. **Complex Logic**: Communication logic is scattered across multiple classes, making it hard to understand and modify
4. **Maintenance Nightmare**: Changes to how objects communicate require modifications to multiple classes

### Solution

Create a mediator class that encapsulates all the communication logic between objects. Instead of objects communicating directly with each other, they communicate through the mediator. The mediator becomes responsible for coordinating interactions, allowing individual objects to be independent and reusable.

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

## When to Use

- A set of objects need to communicate in complex ways that result in dependencies that are unstructured and difficult to understand
- Reusing an object is difficult because it refers to many other objects
- Behavior distributed between several classes should be customizable without a lot of subclassing
- You want to centralize control and decision-making about interactions
- Objects should not directly reference each other because this makes them harder to test and reuse

## Implementation

### PHP 8.3+ Example: Chat Room Mediator

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

### Real-World Example: Dialog Box with Controls

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

## Real-World Analogies

**Air Traffic Control**: Aircraft don't communicate directly with each other. Instead, they communicate with the control tower (mediator), which coordinates takeoffs, landings, and flight paths to prevent collisions.

**Chat Application**: Users don't send messages directly to each other. Messages go through a chat server (mediator) which routes messages and maintains conversation history.

**Restaurant Kitchen**: Instead of cooks communicating directly with each other, they communicate through the head chef (mediator) who coordinates tasks and manages timing.

## Pros and Cons

### Advantages
- **Decouples Objects**: Objects no longer need to know about each other directly
- **Centralizes Control Logic**: All communication rules are in one place, making them easier to modify
- **Simplifies Object Relationships**: Converts many-to-many relationships into one-to-many
- **Improves Reusability**: Individual objects can be used in different contexts with different mediators
- **Single Responsibility**: Each object focuses on its own behavior, not coordination

### Disadvantages
- **God Object Problem**: Mediator can become overly complex if managing too many interactions
- **Difficult Testing**: Complex mediators can be hard to unit test
- **Performance**: Additional layer of indirection can impact performance in high-frequency communications
- **Overkill for Simple Cases**: Can introduce unnecessary complexity for simple interactions
- **Harder to Extend**: Changing communication patterns may require modifying the mediator extensively

## Relations with Other Patterns

- **Observer**: Similar loose coupling but Observer is push-based while Mediator is more centralized
- **Command**: Mediator can use Command objects to encapsulate requests
- **Facade**: Both simplify complex subsystems, but Facade exposes a simpler interface while Mediator manages object interactions
- **State**: Often used together; Mediator defines how state transitions trigger object communications
- **Strategy**: Both encapsulate logic but Strategy is about behavior algorithms, Mediator is about interaction coordination

## Examples in Other Languages

### Java

Producer-Consumer coordination through a mediator with synchronized slot:

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

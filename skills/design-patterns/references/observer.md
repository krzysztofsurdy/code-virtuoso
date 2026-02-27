## Overview

The Observer pattern is a behavioral design pattern that establishes a subscription mechanism between a subject (observable) and multiple observers. When the subject's state changes, all registered observers are automatically notified and updated. This pattern is fundamental to event-driven systems and reactive programming.

## Intent

- Define a one-to-many dependency between objects
- Maintain loose coupling between communicating objects
- Provide a clean interface for event notification
- Enable dynamic subscription and unsubscription of observers

## Problem

In systems with multiple objects that need to react to state changes:
- Tight coupling occurs when objects directly reference each other
- Hard-coding dependencies makes the system inflexible
- Adding new observers requires modifying existing code
- Managing multiple notifications becomes complex and error-prone

## Solution

Separate the subject (observable) from the observers through a subscription mechanism:
- The subject maintains a list of observer references
- Observers define a common interface for receiving notifications
- When state changes, the subject notifies all observers automatically
- Observers remain decoupled from the subject and each other

## Structure

```
┌─────────────┐              ┌──────────────┐
│  Subject    │              │  Observer    │
├─────────────┤              ├──────────────┤
│ - observers │◄─────────────│ + update()   │
│ + attach()  │   notifies   └──────────────┤
│ + detach()  │                      ▲
│ + notify()  │                      │
└─────────────┘              ┌───────┴────────┐
       ▲                      │                │
       │              ┌───────────────┐  ┌──────────────┐
       │              │ConcreteObserverA │ConcreteObserverB│
       │              └───────────────┘  └──────────────┘
       │
┌──────┴──────────┐
│ConcreteSubject  │
└─────────────────┘
```

## When to Use

- Event-driven systems (UI event handling, user interactions)
- Real-time data updates (stock prices, sensor readings, weather)
- Model-View-Controller (MVC) architectures
- Pub-Sub systems and message brokers
- Change notifications in domain models
- Reactive programming frameworks
- Observer-based logging and monitoring systems

## Implementation

### PHP 8.3+ Strict Types

```php
<?php
declare(strict_types=1);

namespace DesignPatterns\Observer;

interface Observer
{
    public function update(Subject $subject): void;
}

interface Subject
{
    public function attach(Observer $observer): void;
    public function detach(Observer $observer): void;
    public function notify(): void;
}

/**
 * Concrete Subject (Observable)
 *
 * @readonly - PHP 8.1+ property immutability where applicable
 */
class ConcreteSubject implements Subject
{
    /** @var list<Observer> */
    private array $observers = [];

    private int $state = 0;

    public function __construct(private readonly string $name) {}

    public function attach(Observer $observer): void
    {
        if (!in_array($observer, $this->observers, true)) {
            $this->observers[] = $observer;
        }
    }

    public function detach(Observer $observer): void
    {
        $key = array_search($observer, $this->observers, true);
        if ($key !== false) {
            unset($this->observers[$key]);
            $this->observers = array_values($this->observers);
        }
    }

    public function notify(): void
    {
        foreach ($this->observers as $observer) {
            $observer->update($this);
        }
    }

    public function setState(int $state): void
    {
        if ($this->state !== $state) {
            $this->state = $state;
            $this->notify();
        }
    }

    public function getState(): int
    {
        return $this->state;
    }

    public function getName(): string
    {
        return $this->name;
    }
}

/**
 * Concrete Observer A
 */
class ObserverA implements Observer
{
    public function __construct(private readonly string $id) {}

    public function update(Subject $subject): void
    {
        if ($subject instanceof ConcreteSubject) {
            echo "Observer A (ID: {$this->id}) notified of state change in "
                . "{$subject->getName()}: {$subject->getState()}\n";
        }
    }
}

/**
 * Concrete Observer B
 */
class ObserverB implements Observer
{
    public function __construct(private readonly string $id) {}

    public function update(Subject $subject): void
    {
        if ($subject instanceof ConcreteSubject) {
            echo "Observer B (ID: {$this->id}) performing action on "
                . "{$subject->getName()}: {$subject->getState()}\n";
        }
    }
}

// Usage
$subject = new ConcreteSubject('DataModel');
$observerA = new ObserverA('A1');
$observerB = new ObserverB('B1');

$subject->attach($observerA);
$subject->attach($observerB);

$subject->setState(42); // Both observers are notified
$subject->detach($observerA);
$subject->setState(100); // Only observerB is notified
```

## Real-World Analogies

- **Magazine Subscription**: Magazine publisher (subject) maintains subscriber list. When a new issue is published, all subscribers (observers) receive a copy automatically.
- **Event Listeners**: GUI button (subject) notifies all registered click handlers (observers) when clicked.
- **Weather Station**: Weather service (subject) broadcasts temperature changes to all weather apps (observers).
- **Stock Price Updates**: Stock exchange (subject) notifies brokers and traders (observers) of price changes.

## Pros and Cons

### Pros
- Loose coupling between subject and observers
- Runtime subscription and unsubscription
- New observers can be added without modifying subject
- Supports dynamic relationships between components
- Facilitates event-driven architecture
- Follows Open/Closed Principle

### Cons
- Observers are notified in unpredictable order
- Memory leaks possible if observers not properly detached
- Performance overhead with many observers
- Can make code flow difficult to trace
- Risk of circular dependencies
- All observers receive all notifications (filter logic needed)

## Relations with Other Patterns

- **Mediator**: Similar decoupling but mediator is more active in controlling communication
- **Pub-Sub**: Observer is instance-level; Pub-Sub typically operates across system/network
- **Event Sourcing**: Uses observer pattern for event notification
- **Model-View-Controller**: View observes Model changes
- **Singleton**: Subject is often a Singleton
- **Iterator**: Often used to iterate over observers when notifying
- **Command**: Can be combined where commands trigger observer notifications
- **Strategy**: Observer can use strategies for different notification behaviors

## Key Takeaways

The Observer pattern is essential for building loosely-coupled, reactive systems. It's the foundation of event-driven architectures and is particularly valuable in modern PHP applications using frameworks that implement MVC or event-driven patterns. Proper implementation requires careful cleanup to prevent memory leaks and consideration of notification order and performance with large observer lists.

## Examples in Other Languages

### Java

Example 1: Observers that display a number in hex, octal, and binary formats.

```java
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

abstract class Observer {
    protected Subject subject;
    public abstract void update();
}

class Subject {
    private List<Observer> observers = new ArrayList<>();
    private int state;

    public void add(Observer o) {
        observers.add(o);
    }

    public int getState() {
        return state;
    }

    public void setState(int value) {
        this.state = value;
        execute();
    }

    private void execute() {
        for (Observer observer : observers) {
            observer.update();
        }
    }
}

class HexObserver extends Observer {
    public HexObserver(Subject subject) {
        this.subject = subject;
        this.subject.add(this);
    }

    public void update() {
        System.out.print(" " + Integer.toHexString(subject.getState()));
    }
}

class OctObserver extends Observer {
    public OctObserver(Subject subject) {
        this.subject = subject;
        this.subject.add(this);
    }

    public void update() {
        System.out.print(" " + Integer.toOctalString(subject.getState()));
    }
}

class BinObserver extends Observer {
    public BinObserver(Subject subject) {
        this.subject = subject;
        this.subject.add(this);
    }

    public void update() {
        System.out.print(" " + Integer.toBinaryString(subject.getState()));
    }
}

public class ObserverDemo {
    public static void main(String[] args) {
        Subject sub = new Subject();
        new HexObserver(sub);
        new OctObserver(sub);
        new BinObserver(sub);
        Scanner scan = new Scanner(System.in);
        for (int i = 0; i < 5; i++) {
            System.out.print("\nEnter a number: ");
            sub.setState(scan.nextInt());
        }
    }
}
```

Example 2: Alarm system with sensor observers.

```java
import java.util.*;

interface AlarmListener {
    void alarm();
}

class SensorSystem {
    private Vector listeners = new Vector();

    public void register(AlarmListener alarmListener) {
        listeners.addElement(alarmListener);
    }

    public void soundTheAlarm() {
        for (Enumeration e = listeners.elements(); e.hasMoreElements();) {
            ((AlarmListener) e.nextElement()).alarm();
        }
    }
}

class Lighting implements AlarmListener {
    public void alarm() {
        System.out.println("lights up");
    }
}

class Gates implements AlarmListener {
    public void alarm() {
        System.out.println("gates close");
    }
}

class CheckList {
    public void byTheNumbers() {
        localize();
        isolate();
        identify();
    }

    protected void localize() {
        System.out.println("   establish a perimeter");
    }

    protected void isolate() {
        System.out.println("   isolate the grid");
    }

    protected void identify() {
        System.out.println("   identify the source");
    }
}

class Surveillance extends CheckList implements AlarmListener {
    public void alarm() {
        System.out.println("Surveillance - by the numbers:");
        byTheNumbers();
    }

    protected void isolate() {
        System.out.println("   train the cameras");
    }
}

public class ObserverDemo2 {
    public static void main(String[] args) {
        SensorSystem sensorSystem = new SensorSystem();
        sensorSystem.register(new Gates());
        sensorSystem.register(new Lighting());
        sensorSystem.register(new Surveillance());
        sensorSystem.soundTheAlarm();
    }
}
```

### C++

Example 1: Before and after refactoring to Observer pattern.

```cpp
#include <iostream>
#include <vector>
using namespace std;

class Observer {
  public:
    virtual void update(int value) = 0;
};

class Subject {
    int m_value;
    vector<Observer*> m_views;
  public:
    void attach(Observer *obs) {
        m_views.push_back(obs);
    }
    void set_val(int value) {
        m_value = value;
        notify();
    }
    void notify() {
        for (int i = 0; i < m_views.size(); ++i)
            m_views[i]->update(m_value);
    }
};

class DivObserver : public Observer {
    int m_div;
  public:
    DivObserver(Subject *model, int div) {
        model->attach(this);
        m_div = div;
    }
    void update(int v) {
        cout << v << " div " << m_div << " is " << v / m_div << '\n';
    }
};

class ModObserver : public Observer {
    int m_mod;
  public:
    ModObserver(Subject *model, int mod) {
        model->attach(this);
        m_mod = mod;
    }
    void update(int v) {
        cout << v << " mod " << m_mod << " is " << v % m_mod << '\n';
    }
};

int main() {
    Subject subj;
    DivObserver divObs1(&subj, 4);
    DivObserver divObs2(&subj, 3);
    ModObserver modObs3(&subj, 3);
    subj.set_val(14);
}
```

Example 2: Alarm system with multiple inheritance.

```cpp
#include <iostream>
#include <vector>
using namespace std;

class AlarmListener {
  public:
    virtual void alarm() = 0;
};

class SensorSystem {
    vector<AlarmListener*> listeners;
  public:
    void attach(AlarmListener *al) {
        listeners.push_back(al);
    }
    void soundTheAlarm() {
        for (int i = 0; i < listeners.size(); i++)
            listeners[i]->alarm();
    }
};

class Lighting : public AlarmListener {
  public:
    void alarm() {
        cout << "lights up" << '\n';
    }
};

class Gates : public AlarmListener {
  public:
    void alarm() {
        cout << "gates close" << '\n';
    }
};

class CheckList {
    virtual void localize() {
        cout << "   establish a perimeter" << '\n';
    }
    virtual void isolate() {
        cout << "   isolate the grid" << '\n';
    }
    virtual void identify() {
        cout << "   identify the source" << '\n';
    }
  public:
    void byTheNumbers() {
        localize();
        isolate();
        identify();
    }
};

class Surveillance : public CheckList, public AlarmListener {
    void isolate() {
        cout << "   train the cameras" << '\n';
    }
  public:
    void alarm() {
        cout << "Surveillance - by the numbers:" << '\n';
        byTheNumbers();
    }
};

int main() {
    SensorSystem ss;
    Lighting lighting;
    Gates gates;
    Surveillance surveillance;
    ss.attach(&gates);
    ss.attach(&lighting);
    ss.attach(&surveillance);
    ss.soundTheAlarm();
}
```

### Python

```python
import abc


class Subject:
    """
    Know its observers. Any number of Observer objects may observe a
    subject.
    Send a notification to its observers when its state changes.
    """

    def __init__(self):
        self._observers = set()
        self._subject_state = None

    def attach(self, observer):
        observer._subject = self
        self._observers.add(observer)

    def detach(self, observer):
        observer._subject = None
        self._observers.discard(observer)

    def _notify(self):
        for observer in self._observers:
            observer.update(self._subject_state)

    @property
    def subject_state(self):
        return self._subject_state

    @subject_state.setter
    def subject_state(self, arg):
        self._subject_state = arg
        self._notify()


class Observer(metaclass=abc.ABCMeta):
    """
    Define an updating interface for objects that should be notified of
    changes in a subject.
    """

    def __init__(self):
        self._subject = None
        self._observer_state = None

    @abc.abstractmethod
    def update(self, arg):
        pass


class ConcreteObserver(Observer):
    """
    Implement the Observer updating interface to keep its state
    consistent with the subject's.
    """

    def update(self, arg):
        self._observer_state = arg


def main():
    subject = Subject()
    concrete_observer = ConcreteObserver()
    subject.attach(concrete_observer)
    subject.subject_state = 123


if __name__ == "__main__":
    main()
```

## Contents

- [Overview](#overview)
- [Intent](#intent)
- [Problem](#problem)
- [Solution](#solution)
- [Structure](#structure)
- [When to use](#when-to-use)
- [Implementation](#implementation)
- [Real-world analogies](#real-world-analogies)
- [Pros and cons](#pros-and-cons)
- [Relations with other patterns](#relations-with-other-patterns)
- [Key takeaways](#key-takeaways)
- [Examples in other languages](#examples-in-other-languages)

## Overview

Observer is a behavioral design pattern that sets up a notification system between a subject and its dependents. When the subject's state changes, every registered observer is told and can react. It is the basis of event-driven architectures and reactive programming.

## Intent

- Establish a one-to-many relationship where a change in one object propagates to many
- Keep communicating objects loosely coupled
- Provide a defined interface for broadcasting events
- Allow observers to be registered and removed at any time

## Problem

Several objects must stay in sync with a changing data source:
- Direct references between objects create rigid dependencies
- Notification logic embedded in the source class limits extensibility
- Adding a new listener means editing existing code
- Coordinating many notifications by hand is fragile

## Solution

Decouple the data source from its dependents with a publish-subscribe mechanism:
- The subject holds a collection of observer references
- All observers share one update interface
- On a state change, the subject iterates over its observers and calls their update method
- Neither side needs to know the other's internals

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

## When to use

- Event-driven applications (GUI interactions, user actions)
- Live data feeds (financial tickers, IoT sensor streams, weather updates)
- MVC architectures where views must reflect model changes
- Publish-subscribe messaging and event bus systems
- Domain model change propagation
- Reactive and stream-based programming frameworks
- Centralized logging and health-monitoring pipelines

## Implementation

### PHP 8.3+ strict types

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

## Real-world analogies

- **Newsletter subscription**: A publisher keeps a mailing list. Each new edition goes to every subscriber, and the publisher needs no details about individual readers.
- **Event listeners**: A GUI button keeps a registry of click handlers. When the button is pressed, it calls each handler in turn.
- **Weather station**: A meteorological service pushes temperature readings to every connected weather app when conditions change.
- **Stock price updates**: A trading platform sends real-time price changes to brokers and automated trading systems.

## Pros and cons

### Pros
- Subject and observers remain decoupled; either side can evolve independently
- Observers can subscribe or unsubscribe dynamically at runtime
- New observer types can be introduced without altering the subject
- Relationships between components can change at runtime
- Fits event-driven and reactive designs
- Follows the Open/Closed Principle

### Cons
- The order in which observers are notified is generally undefined
- Forgetting to unregister observers can cause memory leaks
- A large number of observers can slow down notification
- Tracing program flow through observer chains is hard
- A careless design can create circular notification loops
- Without filtering, every observer receives every event, relevant or not

## Relations with other patterns

- **Mediator**: Both reduce direct coupling, but a mediator coordinates interactions while an observer subject only broadcasts
- **Pub-Sub**: Observer works at the object level; Pub-Sub usually spans processes or network boundaries
- **Event Sourcing**: Builds on the observer idea to persist and replay event streams
- **Model-View-Controller**: The view layer observes and reacts to model state changes
- **Singleton**: The subject is frequently implemented as a singleton
- **Iterator**: Often used internally to walk the observer list during notification
- **Command**: Commands can trigger observer notifications as a side effect
- **Strategy**: Observers can use different strategies to handle incoming notifications

## Key takeaways

Observer underpins MVC frameworks and reactive libraries and is one of the most widely used patterns in PHP. Clean up observers you no longer need to avoid memory leaks, decide whether notification order matters, and watch performance as the observer list grows.

## Examples in other languages

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

---
name: Observer Design Pattern
description: Define a one-to-many dependency between objects so that when one object changes state, all its dependents are notified automatically. A behavioral pattern enabling loose coupling and event-driven architectures.
---

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

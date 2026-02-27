---
name: design-patterns
description: Comprehensive skill for all 26 Gang of Four design patterns with PHP 8.3+ implementations. Covers creational (Abstract Factory, Builder, Factory Method, Prototype, Singleton), structural (Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy), and behavioral patterns (Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor) plus Null Object, Object Pool, and Private Class Data.
---

# Design Patterns

Complete reference for 26 design patterns — creational, structural, and behavioral — with PHP 8.3+ implementations, UML guidance, and real-world use cases.

## Pattern Index

### Creational Patterns
- **Abstract Factory** — Create families of related objects without specifying concrete classes → [reference](references/abstract-factory.md)
- **Builder** — Construct complex objects step by step → [reference](references/builder.md)
- **Factory Method** — Define an interface for creating objects, let subclasses decide → [reference](references/factory-method.md)
- **Prototype** — Clone existing objects without coupling to their classes → [reference](references/prototype.md)
- **Singleton** — Ensure a class has only one instance → [reference](references/singleton.md)
- **Object Pool** — Reuse expensive-to-create objects → [reference](references/object-pool.md)

### Structural Patterns
- **Adapter** — Convert an interface into another interface clients expect → [reference](references/adapter.md)
- **Bridge** — Decouple abstraction from implementation → [reference](references/bridge.md)
- **Composite** — Compose objects into tree structures → [reference](references/composite.md)
- **Decorator** — Attach new behaviors dynamically via wrapping → [reference](references/decorator.md)
- **Facade** — Provide a simplified interface to a subsystem → [reference](references/facade.md)
- **Flyweight** — Share common state between many objects → [reference](references/flyweight.md)
- **Proxy** — Control access to an object via a surrogate → [reference](references/proxy.md)
- **Private Class Data** — Restrict access to class attributes → [reference](references/private-class-data.md)

### Behavioral Patterns
- **Chain of Responsibility** — Pass requests along a chain of handlers → [reference](references/chain-of-responsibility.md)
- **Command** — Encapsulate requests as objects → [reference](references/command.md)
- **Interpreter** — Define a grammar representation and interpreter → [reference](references/interpreter.md)
- **Iterator** — Traverse elements without exposing internals → [reference](references/iterator.md)
- **Mediator** — Reduce chaotic dependencies via a central coordinator → [reference](references/mediator.md)
- **Memento** — Capture and restore object state without violating encapsulation → [reference](references/memento.md)
- **Null Object** — Provide a do-nothing default to avoid null checks → [reference](references/null-object.md)
- **Observer** — Notify dependents automatically on state changes → [reference](references/observer.md)
- **State** — Alter behavior when internal state changes → [reference](references/state.md)
- **Strategy** — Define interchangeable algorithms → [reference](references/strategy.md)
- **Template Method** — Define algorithm skeleton, let subclasses fill in steps → [reference](references/template-method.md)
- **Visitor** — Add operations to objects without modifying them → [reference](references/visitor.md)

## When to Use Which Pattern

| Problem | Pattern |
|---------|---------|
| Need to create families of related objects | Abstract Factory |
| Complex object construction with many options | Builder |
| Want to defer instantiation to subclasses | Factory Method |
| Need copies of complex objects | Prototype |
| Need exactly one instance globally | Singleton |
| Incompatible interfaces need to work together | Adapter |
| Want to vary abstraction and implementation independently | Bridge |
| Tree structures with uniform treatment | Composite |
| Add responsibilities dynamically without subclassing | Decorator |
| Simplify a complex subsystem interface | Facade |
| Many similar objects consuming too much memory | Flyweight |
| Control access, add lazy loading, or log access | Proxy |
| Multiple handlers for a request, unknown which handles it | Chain of Responsibility |
| Queue, log, or undo operations | Command |
| Need to interpret a simple language/grammar | Interpreter |
| Traverse a collection without exposing internals | Iterator |
| Reduce coupling between many communicating objects | Mediator |
| Need undo/snapshot capability | Memento |
| One-to-many event notification | Observer |
| Object behavior depends on its state | State |
| Need to switch algorithms at runtime | Strategy |
| Algorithm skeleton with customizable steps | Template Method |
| Add operations to object structures without modification | Visitor |

## Best Practices

- Prefer **composition over inheritance** — use Decorator, Strategy, or Bridge instead of deep hierarchies
- Apply patterns to solve **actual problems**, not hypothetical ones
- Use PHP 8.3+ features: **enums** for State, **readonly classes** for Value Objects, **first-class callables** for Strategy
- Combine patterns when appropriate (e.g., Builder + Fluent Interface, Strategy + Factory Method)
- Keep pattern implementations **simple** — if the pattern adds more complexity than it solves, reconsider

---
name: design-patterns
description: Comprehensive skill for all 26 Gang of Four design patterns with PHP 8.3+ implementations. Covers creational (Abstract Factory, Builder, Factory Method, Prototype, Singleton), structural (Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy), and behavioral patterns (Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Observer, State, Strategy, Template Method, Visitor) plus Null Object, Object Pool, and Private Class Data.
user-invocable: false
---

# Design Patterns

A thorough reference covering 26 design patterns organized by intent — creational, structural, and behavioral — featuring PHP 8.3+ implementations, UML guidance, and practical use cases.

## Pattern Index

### Creational Patterns
- **Abstract Factory** — Produce families of related objects without specifying their concrete classes → [reference](references/abstract-factory.md)
- **Builder** — Assemble complex objects through a step-by-step process → [reference](references/builder.md)
- **Factory Method** — Declare an interface for object creation, letting subclasses determine the concrete type → [reference](references/factory-method.md)
- **Prototype** — Duplicate existing objects without coupling to their concrete classes → [reference](references/prototype.md)
- **Singleton** — Guarantee that a class has exactly one instance → [reference](references/singleton.md)
- **Object Pool** — Recycle expensive-to-create objects for repeated use → [reference](references/object-pool.md)

### Structural Patterns
- **Adapter** — Translate one interface into another that clients expect → [reference](references/adapter.md)
- **Bridge** — Separate an abstraction from its implementation so both can evolve independently → [reference](references/bridge.md)
- **Composite** — Arrange objects into tree structures for uniform treatment → [reference](references/composite.md)
- **Decorator** — Layer new behaviors onto objects dynamically through wrapping → [reference](references/decorator.md)
- **Facade** — Offer a streamlined interface to a complex subsystem → [reference](references/facade.md)
- **Flyweight** — Minimize memory usage by sharing common state across many objects → [reference](references/flyweight.md)
- **Proxy** — Manage access to an object through a surrogate → [reference](references/proxy.md)
- **Private Class Data** — Limit access to class attributes → [reference](references/private-class-data.md)

### Behavioral Patterns
- **Chain of Responsibility** — Route requests through a chain of handlers → [reference](references/chain-of-responsibility.md)
- **Command** — Represent requests as standalone objects → [reference](references/command.md)
- **Interpreter** — Establish a grammar representation and an interpreter for it → [reference](references/interpreter.md)
- **Iterator** — Walk through elements without revealing the underlying structure → [reference](references/iterator.md)
- **Mediator** — Tame chaotic dependencies through a central coordinator → [reference](references/mediator.md)
- **Memento** — Snapshot and restore object state without breaking encapsulation → [reference](references/memento.md)
- **Null Object** — Supply a do-nothing default to eliminate null checks → [reference](references/null-object.md)
- **Observer** — Automatically inform dependents when state changes → [reference](references/observer.md)
- **State** — Change behavior when internal state transitions → [reference](references/state.md)
- **Strategy** — Make algorithms interchangeable at runtime → [reference](references/strategy.md)
- **Template Method** — Outline an algorithm skeleton and let subclasses fill in specific steps → [reference](references/template-method.md)
- **Visitor** — Introduce operations to objects without altering their classes → [reference](references/visitor.md)

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

- Favor **composition over inheritance** — reach for Decorator, Strategy, or Bridge before resorting to deep class hierarchies
- Apply patterns to address **real problems**, not hypothetical ones
- Leverage PHP 8.3+ features: **enums** for State, **readonly classes** for Value Objects, **first-class callables** for Strategy
- Combine patterns when it makes sense (e.g., Builder + Fluent Interface, Strategy + Factory Method)
- Keep pattern implementations **minimal** — if the pattern introduces more complexity than it resolves, reconsider the approach

# DDD Tactical Patterns

Tactical patterns from Domain-Driven Design are building blocks for expressing domain logic. Each has a specific purpose, placement, and set of rules.

## Contents

- [Entity](#entity)
- [Value Object](#value-object)
- [Aggregate](#aggregate)
- [Repository](#repository)
- [Domain Service](#domain-service)
- [Domain Event](#domain-event)
- [Application Service](#application-service)
- [Factory](#factory)

## Entity

An object defined by its **identity** rather than its attributes. Two entities are equal if they have the same identity, even if all other attributes differ.

**Characteristics:**
- Has a unique identifier that persists across time and state changes
- Mutable: its attributes can change while its identity stays constant
- Has a lifecycle (creation, modification, possibly deletion or archival)
- Enforces its own invariants and rejects state transitions that violate business rules

**When to use:**
- The object has a meaningful lifecycle that the business cares about
- The object must be tracked and distinguished from similar objects
- Business rules govern how the object changes over time

**When not to use:**
- The concept is described by its attributes alone with no meaningful identity
- The object is immutable and interchangeable with others sharing the same attributes
- Use a Value Object instead

**Design guidelines:**
- Keep entities focused. They should not accumulate unrelated responsibilities
- Enforce invariants inside the entity, not in external services
- Expose behavior through intention-revealing methods, not raw setters
- An entity should always be in a valid state. Make invalid states unrepresentable

## Value Object

An object defined entirely by its **attributes**. It has no identity, so two value objects with the same attributes are interchangeable.

**Characteristics:**
- Immutable: once created, its state never changes
- Equality is determined by comparing all attributes
- Side-effect free: operations return new instances instead of modifying the existing one
- Self-validating: rejects invalid attribute combinations at construction time

**Common examples:** Money (amount + currency), EmailAddress, DateRange, Coordinates, Temperature, PostalCode, Color

**When to use:**
- The concept is described completely by its attributes
- Interchangeability is natural: any two instances with the same values are equivalent
- You want to eliminate primitive obsession (replacing raw strings, numbers, or booleans with meaningful types)

**Design guidelines:**
- Make all fields required at construction; validate immediately
- Return new instances from operations (e.g., Money.add() returns a new Money)
- Prefer Value Objects over primitives for domain concepts, since they carry meaning and validation
- Value Objects work well as building blocks inside entities and aggregates

## Aggregate

A cluster of related entities and value objects treated as a **single unit for data changes**. The Aggregate defines a consistency boundary: all invariants within it are consistent after each transaction.

**Characteristics:**
- Has a single **Aggregate Root**, the only entity through which external code interacts with the aggregate
- Enforces all invariants within its boundary
- Is the unit of persistence: load and save the entire aggregate, not individual parts
- Transactional consistency within, eventual consistency between aggregates

**Rules:**
1. **Reference other aggregates by ID only.** Never hold direct object references to other aggregates
2. **One aggregate per transaction.** Do not modify multiple aggregates in a single transaction. Use domain events for cross-aggregate coordination
3. **Keep aggregates small.** Large aggregates create contention and performance problems. Prefer smaller boundaries
4. **The root controls all access.** External objects may not hold references to inner entities. All operations go through the root

**Identifying aggregate boundaries:**
- What must be immediately consistent? That forms one aggregate
- What can be eventually consistent? That belongs in a separate aggregate
- If two things are frequently modified independently, they are likely separate aggregates

## Repository

A **collection-like interface** for accessing and persisting aggregates. The repository provides the illusion that all aggregates of a given type are held in an in-memory collection.

**Characteristics:**
- Interface is defined in the domain layer
- Implementation lives in the infrastructure layer
- One repository per aggregate root, never for entities that are not roots
- Methods reflect domain language, not database operations

**Interface design guidelines:**
- Use domain-oriented method names (findByEmail, findActiveOrders), not queryWithJoinOnTableX
- Accept and return domain objects (aggregates), not raw data structures
- Keep the interface minimal: only methods the domain actually needs
- Avoid exposing query-building or criteria APIs that leak persistence concepts

**What a repository does not do:**
- It does not contain business logic
- It does not manage transactions (that is the application service's responsibility)
- It does not return partial aggregates or projections (use a separate read model or query service for that)

## Domain Service

A **stateless operation** that represents a domain concept but does not belong to any single entity or value object.

**Characteristics:**
- Stateless: no instance variables that change between calls
- Named after a domain activity or process (e.g., FundsTransferService, PricingService)
- Operates on domain objects passed as arguments
- Lives in the domain layer

**When to use:**
- The operation spans multiple entities or aggregates
- Placing the operation on one entity would feel forced or create an awkward dependency
- The operation represents a significant domain concept that deserves its own name

**When not to use:**
- The logic belongs on an entity or value object. Place it there first
- The operation is purely technical (e.g., sending an email, logging): use an infrastructure service
- The operation is orchestration/coordination: use an application service

**Domain Service vs Application Service:**
- Domain Service: contains business rules, lives in the domain layer
- Application Service: orchestrates use cases, lives in the application layer, delegates to domain objects

## Domain Event

An **immutable record** of something that happened in the domain. Domain events capture meaningful state changes and enable decoupled communication between aggregates and bounded contexts.

**Characteristics:**
- Named in **past tense**: OrderPlaced, PaymentReceived, InventoryReserved
- Immutable: once created, the event's data never changes
- Contains all information a consumer needs to react to what happened
- Carries a timestamp indicating when the event occurred

**Payload design:**
- Include the aggregate ID that produced the event
- Include relevant data so consumers do not need to call back to the producer
- Avoid including the entire aggregate state unless necessary
- Use primitive types and value objects to avoid coupling consumers to the producer's internal model

**Handling patterns:**
- **In-process synchronous**: handlers execute in the same transaction. Simple, but it couples timing.
- **In-process asynchronous**: handlers execute after the transaction commits. Better decoupling.
- **Out-of-process (messaging)**: events are published to a message broker. Full decoupling and support for cross-context communication, but you must handle eventual consistency.

**Design guidelines:**
- Aggregates produce events as a result of state changes
- Application services (or event dispatchers) are responsible for publishing events
- Consumers should be idempotent, because the same event may be delivered more than once
- Do not use events to replace direct method calls within the same aggregate

## Application Service

An **orchestrator** for a specific use case. It coordinates domain objects, manages transaction scope, and translates between external input and domain operations. It contains **no business logic**.

**Characteristics:**
- One service (or handler) per use case
- Lives in the application layer
- Accepts commands/queries and returns DTOs or simple results
- Manages transaction boundaries (begin, commit, rollback)
- Calls domain objects to perform business operations

**What it does:**
1. Receive input (command, query, or DTO)
2. Load required aggregates from repositories
3. Call domain methods to execute business logic
4. Persist changes through repositories
5. Dispatch domain events
6. Return result to caller

**What it does not do:**
- Contain if/else business logic. Delegate to domain objects
- Directly access databases, APIs, or external systems. Use ports
- Know about HTTP, CLI, or other delivery mechanisms

## Factory

Encapsulates **complex object creation** when constructing a domain object requires significant logic, coordination, or conditional decisions.

**When to use:**
- Object creation involves complex validation or multi-step setup
- The creation logic would clutter the aggregate or entity
- Different creation paths produce the same type of object (e.g., creating an order from a cart vs. from a reorder request)

**Placement:**
- Factory methods on the aggregate root, for creating the aggregate itself or its internal entities
- Standalone factory classes in the domain layer, for complex cross-aggregate creation scenarios
- Repository factory methods, for reconstituting aggregates from persistence (infrastructure layer)

**Design guidelines:**
- A factory must produce a valid object or fail. Never return a half-initialized object
- Use intention-revealing names that describe the creation scenario
- Factories in the domain layer should not depend on infrastructure

# Architecture Layers

Guidance for each layer in a Clean Architecture / Hexagonal Architecture system. The fundamental rule is that **dependencies always point inward**. Outer layers know about inner layers, never the reverse.

## Contents

- [Domain layer (innermost)](#domain-layer-innermost)
- [Application layer](#application-layer)
- [Infrastructure layer](#infrastructure-layer)
- [Presentation layer (outermost)](#presentation-layer-outermost)
- [Crossing boundaries](#crossing-boundaries)

## Domain layer (innermost)

The core of the system. It contains all business rules, invariants, and domain concepts. This layer has **zero external dependencies**: no framework, no database driver, no HTTP library.

### Responsibilities

- Define core business rules and invariants
- Model domain concepts as Entities, Value Objects, and Aggregates
- Express domain operations through Domain Services
- Emit Domain Events when meaningful state changes occur
- Declare Repository interfaces (the "what," not the "how")

### What belongs here

- **Entities**: objects with identity and lifecycle (e.g., Order, Customer, Invoice)
- **Value Objects**: immutable, identity-less concepts (e.g., Money, EmailAddress, DateRange)
- **Aggregates**: consistency boundaries with a root entity that enforces invariants
- **Domain Services**: stateless operations spanning multiple entities
- **Domain Events**: immutable records of something that happened (e.g., OrderPlaced, PaymentReceived)
- **Repository Interfaces**: contracts for retrieving and persisting aggregates
- **Specifications/Policies**: encapsulated business rules that can be composed
- **Exceptions**: domain-specific error types (e.g., InsufficientFundsException)

### What does not belong here

- Database queries, ORM annotations, or table/column references
- HTTP request/response objects
- Framework-specific base classes or annotations
- File system access, network calls, or message queue operations
- Logging implementations (a logging interface may be acceptable in some designs)
- Transaction management

### Dependency direction

The domain layer depends on **nothing**. It defines interfaces that outer layers implement.

## Application layer

Orchestrates the use of domain objects to fulfill specific use cases. This layer defines the **application's behavior** but contains **no business logic**. It delegates all business decisions to the domain layer.

### Responsibilities

- Define and execute use cases (application services / command handlers / query handlers)
- Coordinate domain objects to accomplish tasks
- Manage transaction boundaries (declare, not implement)
- Define ports (interfaces) for infrastructure capabilities
- Transform data between external representations and domain objects

### What belongs here

- **Application Services / Use Case Handlers**: one per use case, orchestrating domain objects
- **Command and Query objects**: input structures representing user intent
- **DTOs (Data Transfer Objects)**: simple structures for crossing boundaries
- **Port interfaces**: abstractions for infrastructure needs (e.g., notification sender, payment gateway, file storage)
- **Input validation**: structural validation (is this a valid email format?) as opposed to business validation
- **Event dispatching coordination**: deciding when to publish domain events

### What does not belong here

- Business rules, calculations, or conditional logic that belongs in the domain
- Direct database queries or ORM calls
- HTTP-specific concepts (status codes, headers, request objects)
- Framework annotations or base classes
- Complex data transformations that represent business logic

### Dependency direction

Depends on the **Domain layer** only. Defines port interfaces that the Infrastructure layer implements.

## Infrastructure layer

Provides technical capabilities by implementing the interfaces (ports) defined by inner layers. This is where all external system integrations live.

### Responsibilities

- Implement repository interfaces using a specific persistence technology
- Implement port interfaces for external services (email, payment, storage)
- Handle serialization and deserialization for external formats
- Manage technical cross-cutting concerns (logging, monitoring, caching)
- Provide adapters for message queues, event buses, and third-party APIs

### What belongs here

- **Repository implementations**: translate between domain aggregates and database operations
- **External service adapters**: clients for APIs, message brokers, file systems
- **ORM configuration**: entity mappings, migration definitions
- **Event publishing infrastructure**: message queue producers, event bus adapters
- **Caching implementations**: cache adapters implementing port interfaces
- **Security infrastructure**: authentication/authorization mechanism implementations
- **Configuration readers**: environment-specific settings and secret management

### What does not belong here

- Business rules or domain logic
- Use case orchestration
- Direct references from domain objects (the domain never calls infrastructure)
- Controller or presentation logic

### Dependency direction

Depends on **Application and Domain layers**. Implements interfaces defined in those layers.

## Presentation layer (outermost)

The entry point for users or external systems. Translates external input into application commands/queries and formats application output for the consumer.

### Responsibilities

- Accept and parse external input (HTTP requests, CLI arguments, message payloads)
- Validate input format (not business rules)
- Delegate to application services
- Format and return responses
- Handle authentication/authorization checks (is this user allowed to attempt this action?)

### What belongs here

- **Controllers / Action handlers**: receive input, call application service, return output
- **API endpoint definitions**: route configuration, request/response mapping
- **CLI command definitions**: argument parsing, output formatting
- **View Models / Response DTOs**: structures shaped for the consumer's needs
- **Input format validation**: type checking, required fields, format constraints
- **Error mapping**: translating domain/application exceptions into appropriate responses

### What does not belong here

- Business logic of any kind
- Direct database access or queries
- Domain object construction (use application services or factories)
- Complex data transformations

### Dependency direction

Depends on the **Application layer**. Never directly depends on Infrastructure (except through dependency injection wiring at the composition root).

## Crossing boundaries

When data moves between layers, follow these rules:

1. **Data crosses boundaries as simple structures**: primitives, DTOs, or data transfer objects. Never pass framework-specific objects inward.
2. **The inner layer defines the interface.** The outer layer implements or calls it.
3. **Mapping happens at the boundary.** Each layer has its own representation of data. Map between them explicitly instead of sharing one structure across layers.
4. **The Composition Root wires everything together.** It is a single place, usually at application startup, where concrete implementations are bound to interfaces. It is the only place that knows about all layers at once.

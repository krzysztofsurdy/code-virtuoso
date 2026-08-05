---
name: clean-architecture
description: Clean Architecture, Hexagonal Architecture (Ports and Adapters), and Domain-Driven Design fundamentals. Use when the user asks to design system architecture, define layer boundaries, apply DDD tactical patterns (entities, value objects, aggregates, repositories), structure a hexagonal application, enforce dependency rules, or evaluate whether a codebase needs architectural refactoring. Covers bounded contexts, use cases, domain services, and framework-independent design.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Clean Architecture & DDD

Architectural patterns and tactical design techniques for building systems where business logic is isolated, testable, and independent of frameworks, databases, and delivery mechanisms. Rooted in the work of Robert C. Martin, Alistair Cockburn, and Eric Evans.

## When to use

- The domain has business rules that deserve explicit modeling
- The system must survive framework upgrades, database migrations, or delivery mechanism changes
- Multiple entry points (API, CLI, message consumer, scheduled jobs) share the same business logic
- Long-lived product where maintenance cost outweighs initial development speed
- Team size or turnover demands clear boundaries and enforceable conventions
- Testability is a priority: business rules must be verifiable without infrastructure

## When not to use

Not every system needs this much structure. Avoid over-engineering when:

- The application is a simple CRUD wrapper with no real business logic
- The project is a short-lived prototype or proof of concept
- The team is small and the domain is well understood with few rules
- The overhead of layer separation exceeds the complexity of the problem
- A simple framework-centric approach (e.g., MVC with active records) covers the need

The key question: **does the domain have enough complexity to justify the investment?** If not, choose a simpler architecture. You can introduce boundaries later as complexity grows.

## Architecture styles

Three well-known styles share one core principle: **dependencies point inward**, and the domain sits at the center.

| Style | Origin | Key metaphor | Distinguishing idea |
|---|---|---|---|
| **Clean Architecture** | Robert C. Martin (2012) | Concentric circles | Explicit layer names: Entity, Use Case, Interface Adapter, Framework |
| **Hexagonal (Ports & Adapters)** | Alistair Cockburn (2005) | Hexagon with ports | Symmetry between driving (primary) and driven (secondary) adapters |
| **Onion Architecture** | Jeffrey Palermo (2008) | Onion layers | Domain model at the core, infrastructure at the outer ring |

**What they share:**

- Domain logic at the center, free of external dependencies
- The **Dependency Rule**: source code dependencies always point inward
- Infrastructure and delivery concerns live in outer layers
- Communication crosses boundaries through abstractions (interfaces/ports)

In practice the differences are naming conventions. The principles below apply to all three.

### Ports & Adapters concept

Hexagonal Architecture supplies a vocabulary that works across all three styles:

- **Ports** are interfaces defined by the application. They describe what the application needs from the outside world (driven/secondary ports) or what the outside world can ask of the application (driving/primary ports).
- **Adapters** are implementations that connect a port to a specific technology. A database adapter implements a repository port. An HTTP controller is an adapter for a driving port.
- **Driving (primary) adapters** initiate interaction with the application: HTTP controllers, CLI commands, message consumers, scheduled jobs.
- **Driven (secondary) adapters** are called by the application: database repositories, email senders, payment gateways, file storage.

The application does not know whether a REST API or a CLI command is driving it, or whether it persists to a relational database or an in-memory store.

## The Dependency Rule

> Source code dependencies must point inward. Nothing in an inner layer can know anything about an outer layer: no names, types, interfaces, or concepts.

This is the most important rule. Every other guideline follows from it.

**What "inward" means:**

- Inner layers define interfaces (ports); outer layers implement them
- Data crosses boundaries as simple structures (DTOs, primitives), never as framework objects
- The domain layer never imports from infrastructure, presentation, or application layers
- The application layer never imports from infrastructure or presentation layers

**Why it matters:**

- The domain can be tested without a database, HTTP server, or message broker
- Frameworks become replaceable implementation details
- Business rules are readable without understanding deployment topology

**How to enforce it:**

- Use static analysis or architecture testing tools to verify import directions
- Organize code into modules or packages that mirror the layers, so violations are visible
- Flag any inner-layer import of outer-layer types in code review
- The Composition Root (application entry point) is the only place that wires all layers together, so it is the one place allowed to know about everything

## Layer reference

| Layer | Direction | Responsibility | What belongs here | What does not belong |
|---|---|---|---|---|
| **Domain** (innermost) | Depends on nothing | Business rules, invariants | Entities, Value Objects, Aggregates, Domain Services, Domain Events, Repository interfaces | Framework imports, database queries, HTTP concepts |
| **Application** | Depends on Domain | Use case orchestration | Application Services, Command/Query objects, DTOs, Port interfaces | Business logic, direct infrastructure calls |
| **Infrastructure** | Depends on Application + Domain | Technical capabilities | Repository implementations, API clients, message queue adapters, file system access | Business rules, use case orchestration |
| **Presentation** (outermost) | Depends on Application | User/system interaction | Controllers, CLI commands, API endpoints, View Models | Business logic, direct database access |

See [Layer Details](references/layers.md) for in-depth guidance on each layer.

## DDD tactical patterns

Tactical patterns give structure to the domain layer. Each has a specific role and place in the architecture.

| Pattern | Purpose | Layer | Key rule |
|---|---|---|---|
| **Entity** | Object with identity and lifecycle | Domain | Identity determines equality |
| **Value Object** | Immutable, identity-less concept | Domain | Attribute equality, no side effects |
| **Aggregate** | Consistency boundary | Domain | One aggregate per transaction, reference others by ID |
| **Repository** | Collection-like access to aggregates | Interface in Domain, implementation in Infrastructure | One repository per aggregate root |
| **Domain Service** | Stateless cross-entity logic | Domain | Only when logic doesn't belong to a single entity |
| **Domain Event** | Record of something that happened | Domain | Named in past tense, immutable payload |
| **Application Service** | Use case orchestrator | Application | No business logic, delegates to domain objects |
| **Factory** | Complex object creation | Domain | Encapsulates construction invariants |

See [DDD Tactical Patterns](references/ddd-patterns.md) for detailed guidance on each pattern.

## DDD strategic patterns

Strategic patterns deal with the large-scale structure of a system: how to divide a complex domain into manageable parts and how those parts interact.

### Bounded Context

A Bounded Context is a boundary within which a particular domain model is defined and consistent. Each context has its own **Ubiquitous Language**, and the same word can mean different things in different contexts.

**Identifying boundaries:**

- Different teams or departments often indicate different contexts
- When the same term (e.g., "Account") means different things to different stakeholders, they belong in separate contexts
- A context should be small enough for one team to own
- Align contexts with business capabilities, not technical layers

### Ubiquitous Language

Within each Bounded Context, developers and domain experts share a precise vocabulary. Code uses that language directly: class names, method names, and variable names reflect domain concepts exactly as the domain expert would describe them.

**Tips for maintaining it:**

- If a developer cannot explain a class name to a domain expert, the name is wrong
- Refactor code when the language evolves. Renaming is a design activity, not a cosmetic one
- Avoid technical jargon in domain layer code. Use business terms, not implementation terms
- Document the language in a glossary shared between developers and domain experts

### Context Map

A Context Map documents the relationships between Bounded Contexts. It makes integration strategies explicit instead of accidental.

| Pattern | Relationship | When to use |
|---|---|---|
| **Shared Kernel** | Two contexts share a subset of the model | Closely collaborating teams willing to coordinate changes |
| **Customer-Supplier** | Upstream context serves downstream context | Downstream can negotiate with upstream |
| **Conformist** | Downstream conforms to upstream model | No negotiating power; upstream won't change |
| **Anti-Corruption Layer** | Translation layer protects downstream | Integrating with legacy or external systems |
| **Open Host Service** | Upstream provides a well-defined protocol | Multiple consumers need stable access |
| **Published Language** | Shared interchange format | Cross-context communication via standard schemas |

See [Context Mapping](references/context-mapping.md) for integration patterns and boundary decisions.

### Anti-Corruption Layer

When integrating with external or legacy systems, an Anti-Corruption Layer (ACL) translates between the external model and the internal domain model, so foreign concepts do not leak into the domain.

**Structure:** External system -> ACL (adapter + translator) -> Domain model

The ACL belongs in the infrastructure layer and implements a port defined by the application or domain layer.

## CQRS (Command Query Responsibility Segregation)

CQRS pairs well with Clean Architecture and DDD. It separates the write model (commands) from the read model (queries) so each can be optimized independently.

**How it fits the architecture:**

- **Commands** flow through the application layer, modify aggregates, and persist through repositories
- **Queries** can bypass the domain layer entirely and read from optimized projections or views
- The write side enforces business rules through the domain model
- The read side is shaped for the consumer, with no need to reconstruct full aggregates for display

**When to consider CQRS:**

- Read and write patterns differ a lot (e.g., complex writes but simple reads, or vice versa)
- Performance requirements differ between reads and writes
- The read model needs denormalized views that do not map to the domain model
- Event sourcing is in use (CQRS is usually paired with event sourcing)

**When to avoid CQRS:**

- Simple CRUD applications where reads and writes are symmetric
- The added complexity is not justified by the domain's needs

## Event Sourcing: brief overview

Event Sourcing stores the state of an aggregate as a sequence of domain events instead of a current-state snapshot. The current state is derived by replaying the events.

**Relationship to Clean Architecture:**

- Events are part of the domain layer
- The event store is an infrastructure concern (a specialized repository)
- Projections (read models) are built from events in the infrastructure or application layer
- The domain model does not depend on the event store implementation

**When to consider it:** audit requirements, complex state transitions, temporal queries ("what was the state at time X"), or when domain events are already central to the design.

## Common misconceptions

- **"Clean Architecture means lots of boilerplate."** The layers add some structural code in exchange for explicit boundaries. If the boilerplate is overwhelming, the domain may not be complex enough to justify the approach.
- **"Every application needs all four layers."** Small applications may collapse the application and presentation layers. The critical boundary is between domain and infrastructure.
- **"DTOs everywhere means Clean Architecture."** DTOs are a mechanism for crossing boundaries, not the architecture itself. The architecture is about dependency direction.
- **"The domain model must mirror the database schema."** The opposite is true. The domain model reflects business concepts, and the infrastructure layer maps between it and the storage schema.
- **"Hexagonal and Clean Architecture are different things."** They describe the same core idea in different words. Pick the vocabulary your team prefers.
- **"DDD requires Clean Architecture."** DDD tactical patterns can be used without strict layer separation, though they work best together. Conversely, Clean Architecture does not require DDD patterns.
- **"One bounded context = one microservice."** A bounded context is a logical boundary. It may map to a microservice, a module within a monolith, or any other deployment unit.

## Common violations

| Violation | Symptoms | Fix |
|---|---|---|
| **Domain depends on framework** | Domain classes import HTTP, ORM, or framework annotations | Move infrastructure concerns to outer layers; use plain objects in domain |
| **Business logic in controller** | Controllers contain conditional logic, validation rules, calculations | Extract logic into domain objects or application services |
| **Anemic domain model** | Entities are data bags with only getters/setters; all logic lives in services | Push behavior into entities and value objects; enforce invariants inside aggregates |
| **Application service contains business rules** | Application layer has complex conditionals, domain calculations | Move rules into domain services or entity methods |
| **Infrastructure leaking inward** | Domain layer references database column names, API response shapes | Introduce mapping in infrastructure; keep domain model pure |
| **God aggregate** | One aggregate handles too many concerns, grows without limit | Split into smaller aggregates; use domain events for cross-aggregate communication |
| **Shared database between contexts** | Multiple bounded contexts read/write the same tables | Separate storage per context; integrate through events or APIs |
| **Circular dependencies between layers** | Inner layer imports from outer layer; compile errors or runtime coupling | Re-examine which layer owns the interface; invert the dependency |
| **DTO reuse across boundaries** | Same data structure used in API response, use case input, and domain logic | Create separate DTOs per boundary; map between them |
| **Missing Anti-Corruption Layer** | External system's model pollutes the domain vocabulary | Add a translation layer in infrastructure |

## Testing strategy

The layered architecture gives each layer its own testing approach:

| Layer | Test type | Dependencies | What to verify |
|---|---|---|---|
| **Domain** | Unit tests | None, pure logic | Business rules, invariants, value object equality, aggregate consistency |
| **Application** | Unit tests with mocked ports | Domain layer + mocked infrastructure ports | Use case orchestration, correct domain method calls, transaction boundaries |
| **Infrastructure** | Integration tests | Real external systems (database, API, queue) | Correct mapping, query behavior, adapter fidelity |
| **Presentation** | Functional / acceptance tests | Full stack or mocked application layer | Request parsing, response formatting, error handling, status codes |

**Key principle:** most tests should be fast domain unit tests. Infrastructure integration tests are fewer but confirm that real systems behave as expected. End-to-end tests cover critical paths and should stay minimal.

## Quality checklist

Use this checklist to evaluate whether the architecture is sound:

**Dependency Rule**
- [ ] Domain layer has zero imports from application, infrastructure, or presentation layers
- [ ] Application layer has zero imports from infrastructure or presentation layers
- [ ] All cross-boundary communication uses interfaces/ports defined by the inner layer

**Domain layer**
- [ ] Entities enforce their own invariants, so invalid state is unrepresentable
- [ ] Value Objects are immutable
- [ ] Aggregates are the unit of consistency, one aggregate per transaction
- [ ] Repository interfaces are defined in the domain, not in infrastructure
- [ ] Domain events capture meaningful state changes

**Application layer**
- [ ] Application services orchestrate but contain no business logic
- [ ] Use cases are explicit: each has a clear input, output, and single responsibility
- [ ] DTOs are used to cross boundaries, and domain objects do not leak to outer layers

**Infrastructure layer**
- [ ] Repository implementations live here, not in the domain
- [ ] External service integrations use adapters that implement ports
- [ ] Framework-specific code is isolated and replaceable

**Presentation layer**
- [ ] Controllers are thin and delegate to application services immediately
- [ ] No business logic in controllers, views, or CLI commands
- [ ] Input validation (format, type) happens here; business validation happens in the domain

**Bounded contexts**
- [ ] Each context has its own ubiquitous language
- [ ] Contexts communicate through well-defined interfaces (events, APIs), not shared databases
- [ ] Anti-Corruption Layers protect against external model pollution

**Testing**
- [ ] Domain logic is testable without any infrastructure
- [ ] Application services are testable with mocked ports
- [ ] Infrastructure adapters have integration tests against real dependencies
- [ ] No test requires a running framework to verify business rules

## Best practices

- Start with the domain: model business rules first, add infrastructure later
- Name things after domain concepts, not technical patterns (avoid SomethingManager, SomethingHelper)
- Keep aggregates small. Large aggregates are a design smell that points to misplaced boundaries
- Prefer composition over inheritance across all layers
- Use domain events to communicate between aggregates instead of direct coupling
- Make invalid state unrepresentable by pushing validation into value objects and entity constructors
- Keep the application layer thin. If it contains business logic, the domain layer is anemic
- Refactor toward deeper insight. The first domain model is rarely the best one, so evolve it as understanding grows
- Apply architecture testing to enforce dependency rules in CI
- Introduce Clean Architecture incrementally, starting with the most complex subdomain and expanding from there

---
name: clean-architecture
description: Clean Architecture, Hexagonal Architecture (Ports & Adapters), and Domain-Driven Design fundamentals. Layer boundaries, dependency rules, and tactical patterns for maintainable systems.
user-invocable: false
---

# Clean Architecture & DDD

Architectural patterns and tactical design techniques for building systems where business logic is isolated, testable, and independent of frameworks, databases, and delivery mechanisms. Rooted in the work of Robert C. Martin, Alistair Cockburn, and Eric Evans.

## When to Use

- The domain has meaningful business rules that deserve explicit modeling
- The system must survive framework upgrades, database migrations, or delivery mechanism changes
- Multiple entry points (API, CLI, message consumer, scheduled jobs) share the same business logic
- Long-lived product where maintenance cost outweighs initial development speed
- Team size or turnover demands clear boundaries and enforceable conventions
- Testability is a priority — business rules must be verifiable without infrastructure

## When NOT to Use

Not every system benefits from this level of architectural rigor. Avoid over-engineering when:

- The application is a simple CRUD wrapper with no meaningful business logic
- The project is a short-lived prototype or proof of concept
- The team is very small and the domain is well understood with few rules
- The overhead of layer separation exceeds the complexity of the problem
- A simple framework-centric approach (e.g., MVC with active records) adequately serves the need

The key question: **Does the domain have enough complexity to justify the investment?** If the answer is no, a simpler architecture is the right choice. You can always introduce boundaries later as complexity grows.

## Architecture Styles

Three well-known styles share the same core principle: **dependencies point inward**, and the domain sits at the center.

| Style | Origin | Key Metaphor | Distinguishing Idea |
|---|---|---|---|
| **Clean Architecture** | Robert C. Martin (2012) | Concentric circles | Explicit layer names: Entity, Use Case, Interface Adapter, Framework |
| **Hexagonal (Ports & Adapters)** | Alistair Cockburn (2005) | Hexagon with ports | Symmetry between driving (primary) and driven (secondary) adapters |
| **Onion Architecture** | Jeffrey Palermo (2008) | Onion layers | Emphasis on domain model at the core, infrastructure at the outer ring |

**What they share:**

- Domain logic at the center, free of external dependencies
- The **Dependency Rule**: source code dependencies always point inward
- Infrastructure and delivery concerns live in outer layers
- Communication crosses boundaries through abstractions (interfaces/ports)

For practical purposes, the differences are naming conventions. The principles below apply to all three.

### Ports & Adapters Concept

The Hexagonal Architecture introduces a useful vocabulary that applies across all three styles:

- **Ports** are interfaces defined by the application. They describe what the application needs from the outside world (driven/secondary ports) or what the outside world can ask of the application (driving/primary ports).
- **Adapters** are implementations that connect a port to a specific technology. A database adapter implements a repository port. An HTTP controller is an adapter for a driving port.
- **Driving (primary) adapters** initiate interaction with the application: HTTP controllers, CLI commands, message consumers, scheduled jobs.
- **Driven (secondary) adapters** are called by the application: database repositories, email senders, payment gateways, file storage.

This symmetry is powerful: the application does not know whether it is being driven by a REST API or a CLI command, and it does not know whether it is persisting to a relational database or an in-memory store.

## The Dependency Rule

> Source code dependencies must point inward. Nothing in an inner layer can know anything about an outer layer — no names, types, interfaces, or concepts.

This is the single most important rule. Every other guideline flows from it.

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
- Organize code into modules or packages that reflect layers, making violations visible
- Code reviews should flag any inner-layer import of outer-layer types
- The Composition Root (application entry point) is the only place that wires all layers together — it is the exception that knows about everything

## Layer Reference

| Layer | Direction | Responsibility | What Belongs Here | What Does NOT Belong |
|---|---|---|---|---|
| **Domain** (innermost) | Depends on nothing | Business rules, invariants | Entities, Value Objects, Aggregates, Domain Services, Domain Events, Repository interfaces | Framework imports, database queries, HTTP concepts |
| **Application** | Depends on Domain | Use case orchestration | Application Services, Command/Query objects, DTOs, Port interfaces | Business logic, direct infrastructure calls |
| **Infrastructure** | Depends on Application + Domain | Technical capabilities | Repository implementations, API clients, message queue adapters, file system access | Business rules, use case orchestration |
| **Presentation** (outermost) | Depends on Application | User/system interaction | Controllers, CLI commands, API endpoints, View Models | Business logic, direct database access |

See [Layer Details](references/layers.md) for in-depth guidance on each layer.

## DDD Tactical Patterns

Tactical patterns give structure to the domain layer. Each pattern has a specific role and placement within the architecture.

| Pattern | Purpose | Layer | Key Rule |
|---|---|---|---|
| **Entity** | Object with identity and lifecycle | Domain | Identity determines equality |
| **Value Object** | Immutable, identity-less concept | Domain | Attribute equality, no side effects |
| **Aggregate** | Consistency boundary | Domain | One aggregate per transaction, reference others by ID |
| **Repository** | Collection-like access to aggregates | Interface in Domain, implementation in Infrastructure | One repository per aggregate root |
| **Domain Service** | Stateless cross-entity logic | Domain | Only when logic doesn't belong to a single entity |
| **Domain Event** | Record of something that happened | Domain | Named in past tense, immutable payload |
| **Application Service** | Use case orchestrator | Application | No business logic — delegates to domain objects |
| **Factory** | Complex object creation | Domain | Encapsulates construction invariants |

See [DDD Tactical Patterns](references/ddd-patterns.md) for detailed guidance on each pattern.

## DDD Strategic Patterns

Strategic patterns address the large-scale structure of a system — how to divide a complex domain into manageable parts and how those parts interact.

### Bounded Context

A Bounded Context is a boundary within which a particular domain model is defined and consistent. Each context has its own **Ubiquitous Language** — the same word can mean different things in different contexts.

**Identifying boundaries:**

- Different teams or departments often indicate different contexts
- When the same term (e.g., "Account") means different things to different stakeholders, they belong in separate contexts
- A context should be small enough for one team to own
- Align contexts with business capabilities, not technical layers

### Ubiquitous Language

Within each Bounded Context, the team (developers and domain experts) shares a precise vocabulary. Code should use this language directly — class names, method names, and variable names reflect domain concepts exactly as the domain expert would describe them.

**Practical tips for maintaining Ubiquitous Language:**

- If a developer cannot explain a class name to a domain expert, the name is wrong
- Refactor code when the language evolves — renaming is not cosmetic, it is a design activity
- Avoid technical jargon in domain layer code — use business terms, not implementation terms
- Document the language in a glossary shared between developers and domain experts

### Context Map

A Context Map documents the relationships between Bounded Contexts. It makes integration strategies explicit rather than accidental.

| Pattern | Relationship | When to Use |
|---|---|---|
| **Shared Kernel** | Two contexts share a subset of the model | Closely collaborating teams willing to coordinate changes |
| **Customer-Supplier** | Upstream context serves downstream context | Downstream can negotiate with upstream |
| **Conformist** | Downstream conforms to upstream model | No negotiating power; upstream won't change |
| **Anti-Corruption Layer** | Translation layer protects downstream | Integrating with legacy or external systems |
| **Open Host Service** | Upstream provides a well-defined protocol | Multiple consumers need stable access |
| **Published Language** | Shared interchange format | Cross-context communication via standard schemas |

See [Context Mapping](references/context-mapping.md) for integration patterns and boundary decisions.

### Anti-Corruption Layer

When integrating with external or legacy systems, an Anti-Corruption Layer (ACL) translates between the external model and the internal domain model. The ACL prevents foreign concepts from leaking into the domain.

**Structure:** External system -> ACL (adapter + translator) -> Domain model

The ACL belongs in the infrastructure layer and implements a port defined by the application or domain layer.

## CQRS — Command Query Responsibility Segregation

CQRS is a natural companion to Clean Architecture and DDD. It separates the write model (commands) from the read model (queries), allowing each to be optimized independently.

**How it fits the architecture:**

- **Commands** flow through the application layer, modify aggregates, and persist through repositories
- **Queries** can bypass the domain layer entirely and read from optimized projections or views
- The write side enforces business rules through the domain model
- The read side is optimized for the consumer's needs — no need to reconstruct full aggregates for display purposes

**When to consider CQRS:**

- Read and write patterns are significantly different (e.g., complex writes but simple reads, or vice versa)
- Performance requirements differ between reads and writes
- The read model needs denormalized views that do not map to the domain model
- Event sourcing is in use (CQRS is nearly always paired with event sourcing)

**When to avoid CQRS:**

- Simple CRUD applications where reads and writes are symmetric
- The added complexity is not justified by the domain's needs

## Event Sourcing — Brief Overview

Event Sourcing stores the state of an aggregate as a sequence of domain events rather than a current-state snapshot. The current state is derived by replaying events.

**Relationship to Clean Architecture:**

- Events are part of the domain layer
- The event store is an infrastructure concern (a specialized repository)
- Projections (read models) are built from events in the infrastructure or application layer
- The domain model does not depend on the event store implementation

**When to consider:** audit requirements, complex state transitions, temporal queries ("what was the state at time X"), or when domain events are already central to the design.

## Common Misconceptions

- **"Clean Architecture means lots of boilerplate"** — The layers add some structural code, but the trade-off is explicit boundaries. If the boilerplate is overwhelming, the domain may not be complex enough to justify the approach.
- **"Every application needs all four layers"** — Small applications may collapse the application and presentation layers. The critical boundary is between domain and infrastructure.
- **"DTOs everywhere means Clean Architecture"** — DTOs are a mechanism for crossing boundaries, not the architecture itself. The architecture is about dependency direction.
- **"The domain model must mirror the database schema"** — The opposite is true. The domain model reflects business concepts. The infrastructure layer maps between the domain model and the storage schema.
- **"Hexagonal and Clean Architecture are different things"** — They are different descriptions of the same core idea. Pick the vocabulary that resonates with your team.
- **"DDD requires Clean Architecture"** — DDD tactical patterns can be used without strict layer separation, though they work best together. Conversely, Clean Architecture does not require DDD patterns.
- **"One bounded context = one microservice"** — A bounded context is a logical boundary. It may map to a microservice, a module within a monolith, or any other deployment unit.

## Common Violations

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

## Testing Strategy

The layered architecture enables a clear testing strategy where each layer has a distinct testing approach:

| Layer | Test Type | Dependencies | What to Verify |
|---|---|---|---|
| **Domain** | Unit tests | None — pure logic | Business rules, invariants, value object equality, aggregate consistency |
| **Application** | Unit tests with mocked ports | Domain layer + mocked infrastructure ports | Use case orchestration, correct domain method calls, transaction boundaries |
| **Infrastructure** | Integration tests | Real external systems (database, API, queue) | Correct mapping, query behavior, adapter fidelity |
| **Presentation** | Functional / acceptance tests | Full stack or mocked application layer | Request parsing, response formatting, error handling, status codes |

**Key principle:** The majority of tests should be fast domain unit tests. Infrastructure integration tests are fewer but ensure real systems behave as expected. End-to-end tests cover critical paths but should be minimal.

## Quality Checklist

Use this checklist to evaluate whether the architecture is properly structured:

**Dependency Rule**
- [ ] Domain layer has zero imports from application, infrastructure, or presentation layers
- [ ] Application layer has zero imports from infrastructure or presentation layers
- [ ] All cross-boundary communication uses interfaces/ports defined by the inner layer

**Domain Layer**
- [ ] Entities enforce their own invariants — invalid state is unrepresentable
- [ ] Value Objects are immutable
- [ ] Aggregates are the unit of consistency — one aggregate per transaction
- [ ] Repository interfaces are defined in the domain, not in infrastructure
- [ ] Domain events capture meaningful state changes

**Application Layer**
- [ ] Application services orchestrate but contain no business logic
- [ ] Use cases are explicit — each has a clear input, output, and single responsibility
- [ ] DTOs are used to cross boundaries — domain objects do not leak to outer layers

**Infrastructure Layer**
- [ ] Repository implementations live here, not in the domain
- [ ] External service integrations use adapters that implement ports
- [ ] Framework-specific code is isolated and replaceable

**Presentation Layer**
- [ ] Controllers are thin — they delegate to application services immediately
- [ ] No business logic in controllers, views, or CLI commands
- [ ] Input validation (format, type) happens here; business validation happens in the domain

**Bounded Contexts**
- [ ] Each context has its own ubiquitous language
- [ ] Contexts communicate through well-defined interfaces (events, APIs), not shared databases
- [ ] Anti-Corruption Layers protect against external model pollution

**Testing**
- [ ] Domain logic is testable without any infrastructure
- [ ] Application services are testable with mocked ports
- [ ] Infrastructure adapters have integration tests against real dependencies
- [ ] No test requires a running framework to verify business rules

## Best Practices

- Start with the domain — model business rules first, add infrastructure later
- Name things after domain concepts, not technical patterns (avoid SomethingManager, SomethingHelper)
- Keep aggregates small — large aggregates are a design smell indicating misplaced boundaries
- Prefer composition over inheritance across all layers
- Use domain events to communicate between aggregates rather than direct coupling
- Make invalid state unrepresentable — push validation into value objects and entity constructors
- Keep the application layer thin — if it contains business logic, the domain layer is anemic
- Refactor toward deeper insight — the first domain model is rarely the best one; evolve it as understanding grows
- Apply architecture testing to enforce dependency rules automatically
- Introduce Clean Architecture incrementally — start with the most complex subdomain and expand

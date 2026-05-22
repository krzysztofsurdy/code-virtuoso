---
name: microservices
description: Microservices and distributed systems architecture patterns for scalable, resilient services. Use when the user asks to decompose a monolith, design service boundaries, implement saga orchestration, apply CQRS or event sourcing, configure circuit breakers, set up API gateways, handle eventual consistency, or evaluate monolith vs microservices trade-offs. Covers service decomposition strategies, inter-service communication (sync and async), data isolation, resilience patterns, and observability.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Microservices and Distributed Systems

Microservices architecture splits a system into independently deployable services, each owning a specific business capability. This approach trades the simplicity of a monolith for flexibility in scaling, deployment, and technology choice - but only when the organizational and technical complexity is justified.

## When to Use Microservices vs Monolith

There is no universal answer. The decision depends on team size, domain complexity, and operational maturity.

| Factor | Monolith Favored | Microservices Favored |
|---|---|---|
| **Team size** | Small team (fewer than 10 developers) | Multiple autonomous teams that need independent release cycles |
| **Domain complexity** | Simple or poorly understood domain | Well-understood domain with clear bounded contexts |
| **Deployment cadence** | Infrequent releases are acceptable | Different parts of the system need to ship at different speeds |
| **Scaling needs** | Uniform load across the application | Specific components need independent scaling |
| **Operational maturity** | Limited infrastructure automation | Mature CI/CD, monitoring, and container orchestration |
| **Data isolation** | Shared database is manageable | Services need independent data stores and schemas |

**Start monolithic unless you have a clear reason not to.** A well-structured modular monolith can be decomposed later. A premature microservices architecture adds distributed systems complexity without proportional benefit.

---

## Service Decomposition Strategies

Deciding where to draw service boundaries is the hardest part. Get it wrong and you end up with a distributed monolith - all the costs of distribution with none of the benefits.

### By Business Capability

Align services to what the organization does rather than how the software is structured. Each service maps to a business function: order management, inventory, billing, notifications. Services change when the business capability they represent changes.

### By Subdomain (Domain-Driven Design)

Use bounded contexts from domain-driven design to identify natural boundaries. Each bounded context has its own ubiquitous language and internal model. A "Customer" in the billing context may carry different attributes than a "Customer" in the shipping context - and that is fine.

### Strangler Fig Migration

When migrating from a monolith, extract services incrementally rather than doing a big-bang rewrite. Route traffic through a facade that delegates to the monolith by default but redirects specific capabilities to new services as they are built. Over time, the monolith shrinks until it can be retired entirely. An anti-corruption layer translates between old and new models during the transition.

### Decomposition Heuristics

- **High coupling between candidates** - keep them together, they are likely one service
- **Different rates of change** - separate them, they will benefit from independent deployment
- **Different scaling profiles** - separate them, they need different resource allocation
- **Shared data** - if two candidates always read and write the same tables, splitting them creates unnecessary network chatter

---

## Communication Patterns

Services must communicate, and the choice between synchronous and asynchronous interaction shapes the entire system's behavior.

| Style | Mechanism | Strengths | Weaknesses |
|---|---|---|---|
| **Synchronous request-reply** | REST, gRPC, GraphQL | Simple mental model, immediate response | Temporal coupling, cascading failures |
| **Asynchronous messaging** | Message queues (point-to-point) | Decouples sender from receiver, buffering under load | Added infrastructure, eventual consistency |
| **Event-driven** | Event bus, pub/sub | Loose coupling, multiple consumers possible | Harder to debug, event ordering challenges |

**Rule of thumb:** Use synchronous calls for queries that need an immediate answer. Use asynchronous messaging for commands and events where the sender does not need to wait for the result.

See [Communication Patterns Reference](references/communication-patterns.md) for detailed coverage of API gateways, service discovery, gRPC, service mesh, and sidecar patterns.

---

## Data Management in Distributed Systems

Each service should own its data. Shared databases create hidden coupling that defeats the purpose of service independence. This creates new challenges around consistency and cross-service transactions.

### Key Principles

- **Database per service** - each service has its own data store, accessed only through its API
- **No direct database sharing** - if another service needs data, it requests it through the owning service's interface
- **Eventual consistency is the norm** - strong consistency across services requires distributed transactions, which are fragile and slow
- **Choose the right data store** - different services may use different database technologies based on their access patterns

### Core Data Patterns

| Pattern | Purpose |
|---|---|
| **CQRS** | Separate read and write models to optimize each independently |
| **Event Sourcing** | Store state as a sequence of immutable events instead of overwriting current state |
| **Saga** | Coordinate multi-service transactions using a sequence of local transactions with compensating actions |
| **Outbox** | Guarantee reliable event publishing by writing events to a local table within the same database transaction |
| **Eventual Consistency** | Accept that data across services will converge over time rather than being immediately consistent |

See [Data Patterns Reference](references/data-patterns.md) for implementation details with multi-language examples.

---

## Resilience Patterns

In a distributed system, failures are inevitable. Network partitions, slow dependencies, and overloaded services are normal operating conditions, not exceptional events. Resilience patterns prevent localized failures from cascading through the entire system.

### Pattern Summary

| Pattern | Purpose |
|---|---|
| **Circuit Breaker** | Stop calling a failing dependency; fail fast and give it time to recover |
| **Bulkhead** | Isolate resource pools so one slow dependency cannot exhaust resources needed by others |
| **Retry with Backoff** | Automatically retry transient failures with increasing delays and randomized jitter |
| **Timeout** | Set upper bounds on how long to wait for a response; never block indefinitely |
| **Fallback** | Provide degraded but functional behavior when a dependency is unavailable |
| **Health Checks** | Expose liveness and readiness endpoints so orchestrators can route traffic and restart unhealthy instances |

See [Resilience Patterns Reference](references/resilience-patterns.md) for implementation details with multi-language examples.

---

## Reference Files

| Reference | Contents |
|---|---|
| [Data Patterns](references/data-patterns.md) | CQRS, event sourcing, saga orchestration vs choreography, outbox pattern, eventual consistency with multi-language examples |
| [Resilience Patterns](references/resilience-patterns.md) | Circuit breaker, bulkhead, retry with backoff, timeout, fallback, health checks with multi-language examples |
| [Communication Patterns](references/communication-patterns.md) | REST, gRPC, GraphQL federation, message queues, API gateway, service discovery, sidecar and service mesh with multi-language examples |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Domain modeling and bounded context design | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for clean architecture guidance |
| Testing microservices (contract tests, integration tests) | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies |
| API design for service interfaces | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design principles |
| Performance tuning individual services | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for performance optimization |

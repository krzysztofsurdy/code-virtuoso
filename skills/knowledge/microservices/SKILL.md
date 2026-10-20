---
name: microservices
description: "Microservices and distributed systems patterns: service boundaries, sagas, CQRS, resilience, and monolith trade-offs. Use to decompose a monolith or design service communication."
allowed-tools: Read Grep Glob Bash
user-invocable: true
disable-model-invocation: true
---

# Microservices and Distributed Systems

Microservices architecture splits a system into independently deployable services, each owning a business capability. It trades the simplicity of a monolith for flexibility in scaling, deployment, and technology choice. That trade only pays off when the organizational and technical complexity is justified.

## When to use microservices vs monolith

The decision depends on team size, domain complexity, and operational maturity.

| Factor | Monolith favored | Microservices favored |
|---|---|---|
| **Team size** | Small team (fewer than 10 developers) | Multiple autonomous teams that need independent release cycles |
| **Domain complexity** | Simple or poorly understood domain | Well-understood domain with clear bounded contexts |
| **Deployment cadence** | Infrequent releases are acceptable | Different parts of the system need to ship at different speeds |
| **Scaling needs** | Uniform load across the application | Specific components need independent scaling |
| **Operational maturity** | Limited infrastructure automation | Mature CI/CD, monitoring, and container orchestration |
| **Data isolation** | Shared database is manageable | Services need independent data stores and schemas |

**Start monolithic unless you have a clear reason not to.** A well-structured modular monolith can be decomposed later. A premature microservices architecture adds distributed systems complexity without matching benefit.

---

## Service decomposition strategies

Drawing service boundaries is the hardest part. Get it wrong and you get a distributed monolith: all the costs of distribution and none of the benefits.

### By business capability

Align services to what the organization does, not to how the software is structured. Each service maps to a business function: order management, inventory, billing, notifications. Services change when the business capability they represent changes.

### By subdomain (Domain-Driven Design)

Use bounded contexts from domain-driven design to identify natural boundaries. Each bounded context has its own ubiquitous language and internal model. A "Customer" in the billing context may carry different attributes than a "Customer" in the shipping context. That is fine.

### Strangler Fig migration

When migrating from a monolith, extract services one at a time instead of doing a big-bang rewrite. Route traffic through a facade that delegates to the monolith by default but redirects specific capabilities to new services as they are built. Over time the monolith shrinks until it can be retired. An anti-corruption layer translates between old and new models during the transition.

### Decomposition heuristics

- **High coupling between candidates**: keep them together, they are likely one service
- **Different rates of change**: separate them so they can deploy independently
- **Different scaling profiles**: separate them, they need different resource allocation
- **Shared data**: if two candidates always read and write the same tables, splitting them adds network chatter for no gain

---

## Communication patterns

Services must communicate, and the choice between synchronous and asynchronous interaction shapes how the whole system behaves.

| Style | Mechanism | Strengths | Weaknesses |
|---|---|---|---|
| **Synchronous request-reply** | REST, gRPC, GraphQL | Simple mental model, immediate response | Temporal coupling, cascading failures |
| **Asynchronous messaging** | Message queues (point-to-point) | Decouples sender from receiver, buffering under load | Added infrastructure, eventual consistency |
| **Event-driven** | Event bus, pub/sub | Loose coupling, multiple consumers possible | Harder to debug, event ordering challenges |

**Rule of thumb:** Use synchronous calls for queries that need an immediate answer. Use asynchronous messaging for commands and events where the sender does not need to wait for the result.

See [Communication Patterns Reference](references/communication-patterns.md) for API gateways, service discovery, gRPC, service mesh, and sidecar patterns.

---

## Data management in distributed systems

Each service should own its data. Shared databases create hidden coupling that defeats service independence. Owning data raises new problems with consistency and cross-service transactions.

### Key principles

- **Database per service**: each service has its own data store, accessed only through its API
- **No direct database sharing**: if another service needs data, it requests it through the owning service's interface
- **Eventual consistency is the norm**: strong consistency across services requires distributed transactions, which are fragile and slow
- **Match the data store to the service**: different services may use different database technologies based on their access patterns

### Core data patterns

| Pattern | Purpose |
|---|---|
| **CQRS** | Separate read and write models to optimize each independently |
| **Event Sourcing** | Store state as a sequence of immutable events instead of overwriting current state |
| **Saga** | Coordinate multi-service transactions using a sequence of local transactions with compensating actions |
| **Outbox** | Publish events reliably by writing them to a local table in the same database transaction |
| **Eventual Consistency** | Accept that data across services converges over time instead of being consistent immediately |

See [Data Patterns Reference](references/data-patterns.md) for implementation details with multi-language examples.

---

## Resilience patterns

In a distributed system, failures happen. Network partitions, slow dependencies, and overloaded services are normal operating conditions. Resilience patterns keep a local failure from cascading through the system.

### Pattern summary

| Pattern | Purpose |
|---|---|
| **Circuit Breaker** | Stop calling a failing dependency; fail fast and give it time to recover |
| **Bulkhead** | Isolate resource pools so one slow dependency cannot exhaust resources needed by others |
| **Retry with Backoff** | Retry transient failures with increasing delays and randomized jitter |
| **Timeout** | Set upper bounds on how long to wait for a response; never block indefinitely |
| **Fallback** | Provide reduced but working behavior when a dependency is unavailable |
| **Health Checks** | Expose liveness and readiness endpoints so orchestrators can route traffic and restart unhealthy instances |

See [Resilience Patterns Reference](references/resilience-patterns.md) for implementation details with multi-language examples.

---

## Reference Files

| Reference | Contents |
|---|---|
| [Data Patterns](references/data-patterns.md) | CQRS, event sourcing, saga orchestration vs choreography, outbox pattern, eventual consistency, with multi-language examples |
| [Resilience Patterns](references/resilience-patterns.md) | Circuit breaker, bulkhead, retry with backoff, timeout, fallback, health checks with multi-language examples |
| [Communication Patterns](references/communication-patterns.md) | REST, gRPC, GraphQL federation, message queues, API gateway, service discovery, sidecar and service mesh with multi-language examples |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Domain modeling and bounded context design | `clean-architecture` |
| Testing microservices (contract tests, integration tests) | `testing` |
| API design for service interfaces | `api-design` |
| Performance tuning individual services | `performance` |

# Architecture Decision Record Template

A template for documenting significant architecture decisions. Each ADR records the context, the decision, and its consequences so future teams know why the system is built the way it is.

## Contents

- [When to write an ADR](#when-to-write-an-adr)
- [Template](#template)
- [Example: Message Queue for Async Processing](#example-message-queue-for-async-processing)
- [File naming convention](#file-naming-convention)
- [Status lifecycle](#status-lifecycle)
- [Review checklist](#review-checklist)

---

## When to write an ADR

Write an ADR when a decision:

- Affects multiple components or services
- Is difficult or expensive to reverse
- Involves trade-offs between quality attributes (performance vs maintainability, for example)
- Introduces a new technology, library, or infrastructure component
- Changes an established pattern or convention in the codebase
- Will be questioned by future team members ("why did we do it this way?")

Do not write an ADR for:

- Trivial implementation choices within a single component
- Decisions that follow an already-documented convention
- Choices that are easily reversible with no impact

---

## Template

### ADR-[NNN]: [Short Title Describing the Decision]

**Status**: Proposed | Accepted | Deprecated | Superseded by ADR-[NNN]

**Date**: YYYY-MM-DD

**Deciders**: [Names or roles of people involved in the decision]

---

#### Context

Describe the situation that led to this decision. Include:

- What problem or need triggered the decision
- What constraints exist (technical, organizational, timeline)
- What quality attributes are most important (performance, scalability, maintainability, security)
- What the current state of the system is, if relevant

Keep it factual. This section should read like a problem statement, not a justification for the decision.

**Template paragraph**:

> We need to [accomplish what] because [reason]. The current system [does/does not] handle this because [current state]. Key constraints are [constraint list]. The most important quality attributes for this decision are [attributes].

#### Decision

State the decision clearly in one or two sentences. Then explain the approach in detail.

**Template**:

> We will [decision].

Follow with:

- How the decision will be implemented at a high level
- What patterns or technologies are involved
- How this integrates with existing components

#### Alternatives considered

Document each alternative that was seriously evaluated. For each:

| Alternative | Description | Pros | Cons | Reason Rejected |
|---|---|---|---|---|
| [Alternative A] | [Brief description] | [Advantages] | [Disadvantages] | [Why not chosen] |
| [Alternative B] | [Brief description] | [Advantages] | [Disadvantages] | [Why not chosen] |

#### Consequences

**Positive**:

- [Benefit 1]
- [Benefit 2]

**Negative**:

- [Trade-off or cost 1]
- [Trade-off or cost 2]

**Risks**:

- [Risk and its mitigation]

**Follow-up actions**:

- [ ] [Action needed to implement this decision]
- [ ] [Action needed to implement this decision]

---

## Example: Message Queue for Async Processing

### ADR-007: Use a Message Queue for Asynchronous Job Processing

**Status**: Accepted

**Date**: 2025-09-15

**Deciders**: Lead Architect, Backend Team Lead

---

#### Context

The application processes invoice generation synchronously during the HTTP request cycle. As invoice volume grows, response times have increased to 3-5 seconds for bulk operations, causing timeouts and poor user experience. We need to move invoice generation to asynchronous processing.

Key constraints:
- The team has strong experience with the existing framework
- Infrastructure runs on AWS with RDS and ElastiCache already provisioned
- We need message retry capabilities for transient failures
- The solution must support monitoring and dead-letter handling

The most important quality attributes are reliability (invoices must not be lost) and observability (we must know when processing fails).

#### Decision

We will use a message queue (Amazon SQS) with our framework's message bus abstraction for asynchronous invoice processing.

The implementation approach:
- Define message classes as simple DTOs (e.g., `GenerateInvoiceMessage`)
- Create message handlers that contain the business logic
- Configure SQS transport with dead-letter queue for failed messages
- Use the framework's built-in retry mechanism with exponential backoff
- Add middleware for logging and monitoring

#### Alternatives considered

| Alternative | Description | Pros | Cons | Reason Rejected |
|---|---|---|---|---|
| RabbitMQ | Self-managed message broker | More routing flexibility, team has some experience | Requires managing RabbitMQ infrastructure, operational overhead | Infrastructure team prefers managed services |
| Celery / Sidekiq / similar | Language-specific task queue | Good dashboard, mature ecosystem | Different tech stack from our backend | Mixing ecosystems adds complexity |
| Direct SQS SDK | Use AWS SDK without framework abstraction | Full control over SQS features | No retry abstraction, no middleware pipeline, more boilerplate | Framework message bus provides the abstractions we need out of the box |

#### Consequences

**Positive**:
- Invoice generation no longer blocks HTTP responses
- Built-in retry with exponential backoff handles transient failures
- Dead-letter queue captures permanently failed messages for investigation
- Middleware pipeline gives consistent logging and monitoring
- Team stays within the framework ecosystem they know well

**Negative**:
- Adds infrastructure dependency on SQS
- Async processing makes debugging harder than synchronous code
- Message serialization needs care with entity references

**Risks**:
- SQS message size limit (256KB) may be exceeded for very large invoice payloads. Mitigation: store payload in S3, pass reference in message.

**Follow-up actions**:
- [ ] Configure SQS queues and dead-letter queue in infrastructure-as-code
- [ ] Implement GenerateInvoiceMessage and handler
- [ ] Add CloudWatch alarms for dead-letter queue depth
- [ ] Update deployment pipeline to run message consumer as a managed process

---

## File naming convention

Store ADRs in a dedicated directory with sequential numbering:

```
docs/
  adr/
    001-use-web-framework.md
    002-postgresql-as-primary-database.md
    003-jwt-for-api-authentication.md
    007-message-queue-for-async.md
```

## Status lifecycle

```
Proposed --> Accepted --> [Deprecated | Superseded by ADR-NNN]
```

- **Proposed**: Decision is written but not yet agreed upon
- **Accepted**: Decision is agreed upon and in effect
- **Deprecated**: Decision is no longer relevant (system changed)
- **Superseded**: A newer ADR replaces this one (link to the replacement)

Never delete an ADR. Mark it as deprecated or superseded. The history of decisions is worth keeping.

---

## Review checklist

Before finalizing an ADR:

- [ ] The title clearly states what was decided (not the problem)
- [ ] Context describes the situation without justifying the decision
- [ ] The decision is stated in one clear sentence before elaboration
- [ ] At least two alternatives were considered and documented
- [ ] Each alternative has specific pros, cons, and rejection reason
- [ ] Consequences include both positive and negative impacts
- [ ] Risks have mitigations defined
- [ ] Follow-up actions are listed with clear ownership
- [ ] The ADR can be understood by someone not involved in the discussion

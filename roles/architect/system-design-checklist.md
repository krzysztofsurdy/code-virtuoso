# System Design Review Checklist

A checklist for reviewing system designs before implementation begins. Use it during design reviews to catch gaps early.

## Contents

- [How to use this checklist](#how-to-use-this-checklist)
- [1. Requirements coverage](#1-requirements-coverage)
- [2. Component architecture](#2-component-architecture)
- [3. API design](#3-api-design)
- [4. Data model](#4-data-model)
- [5. Scalability](#5-scalability)
- [6. Reliability](#6-reliability)
- [7. Security](#7-security)
- [8. Observability](#8-observability)
- [9. Deployment and operations](#9-deployment-and-operations)
- [10. Testing strategy](#10-testing-strategy)
- [Framework-specific checks](#framework-specific-checks)
- [Review outcomes](#review-outcomes)

---

## How to use this checklist

1. The architect completes a self-review against this checklist before the design review meeting
2. Reviewers use it as a guide during the review - not every item applies to every design
3. Mark each item as: Pass / Fail / N/A
4. Any Fail item must have a follow-up action assigned before the design is approved

---

## 1. Requirements coverage

| # | Check | Status |
|---|---|---|
| 1.1 | Every P0 functional requirement from the PRD is addressed in the design | |
| 1.2 | Non-functional requirements have specific, measurable targets (latency, throughput, availability) | |
| 1.3 | Security requirements are explicitly addressed, not assumed | |
| 1.4 | Accessibility requirements are considered where applicable | |
| 1.5 | Out-of-scope items from the PRD are not accidentally included in the design | |

## 2. Component architecture

| # | Check | Status |
|---|---|---|
| 2.1 | Each component has a single, clearly defined responsibility | |
| 2.2 | Component boundaries are documented - what each component owns and does not own | |
| 2.3 | Dependencies between components are explicit and minimized | |
| 2.4 | No circular dependencies exist between components | |
| 2.5 | Shared logic is extracted into a common module or service, not duplicated | |
| 2.6 | Components communicate through well-defined interfaces, not internal implementation details | |

## 3. API design

| # | Check | Status |
|---|---|---|
| 3.1 | API endpoints follow consistent naming conventions (RESTful resources, verb usage) | |
| 3.2 | Request and response shapes are fully specified (field names, types, required/optional) | |
| 3.3 | Error response format is consistent across all endpoints | |
| 3.4 | HTTP status codes are used correctly (201 for creation, 204 for no content, 422 for validation) | |
| 3.5 | Pagination strategy is defined for list endpoints | |
| 3.6 | API versioning strategy is defined | |
| 3.7 | Rate limiting is specified for public-facing endpoints | |
| 3.8 | Request validation rules are documented | |

## 4. Data model

| # | Check | Status |
|---|---|---|
| 4.1 | Entity relationships are defined (one-to-one, one-to-many, many-to-many) | |
| 4.2 | Primary keys and foreign keys are specified | |
| 4.3 | Indexes are planned for query patterns (WHERE clauses, JOIN conditions, ORDER BY) | |
| 4.4 | Nullable fields are explicitly decided, not defaulted | |
| 4.5 | Unique constraints are defined where business rules require them | |
| 4.6 | Soft delete vs hard delete strategy is decided | |
| 4.7 | Audit fields are included where needed (createdAt, updatedAt, createdBy) | |
| 4.8 | Data migration strategy is defined for schema changes to existing tables | |
| 4.9 | Large text/blob fields have a storage strategy (inline vs external storage) | |

## 5. Scalability

| # | Check | Status |
|---|---|---|
| 5.1 | Expected load is quantified (requests/second, concurrent users, data volume) | |
| 5.2 | Bottlenecks are identified and mitigation strategies defined | |
| 5.3 | Caching strategy is defined - what is cached, where, for how long, and how invalidated | |
| 5.4 | Database query patterns are reviewed for N+1 problems and unbounded result sets | |
| 5.5 | Background processing is used for operations that do not need synchronous response | |
| 5.6 | Connection pooling is configured for database and external service connections | |
| 5.7 | The design supports horizontal scaling if load grows beyond single-instance capacity | |

## 6. Reliability

| # | Check | Status |
|---|---|---|
| 6.1 | Single points of failure are identified and addressed | |
| 6.2 | Failure modes are documented - what happens when each dependency is unavailable | |
| 6.3 | Retry strategy is defined for transient failures (with backoff and max attempts) | |
| 6.4 | Circuit breaker pattern is used for external service calls where appropriate | |
| 6.5 | Timeout values are specified for all external calls | |
| 6.6 | Data consistency model is defined (strong vs eventual consistency, with rationale) | |
| 6.7 | Transaction boundaries are explicit - which operations must be atomic | |
| 6.8 | Rollback strategy exists for deployments | |

## 7. Security

| # | Check | Status |
|---|---|---|
| 7.1 | Authentication mechanism is specified (JWT, session, API key) | |
| 7.2 | Authorization model is defined (role-based, attribute-based, resource ownership) | |
| 7.3 | Input validation is planned at every system boundary | |
| 7.4 | SQL injection is prevented (parameterized queries, ORM usage) | |
| 7.5 | XSS prevention is addressed for any user-generated content displayed in the UI | |
| 7.6 | CSRF protection is in place for state-changing endpoints | |
| 7.7 | Sensitive data is encrypted at rest and in transit | |
| 7.8 | PII handling complies with relevant regulations (GDPR, etc.) | |
| 7.9 | API endpoints do not expose internal IDs or system details in error messages | |
| 7.10 | Secrets management approach is defined (environment variables, vault, not hardcoded) | |
| 7.11 | Rate limiting is configured to prevent abuse | |

## 8. Observability

| # | Check | Status |
|---|---|---|
| 8.1 | Structured logging is planned with correlation IDs for request tracing | |
| 8.2 | Key business operations have log entries (not just errors) | |
| 8.3 | Error logging includes enough context for debugging (but no sensitive data) | |
| 8.4 | Health check endpoints are defined for load balancers and monitoring | |
| 8.5 | Metrics are planned for critical paths (response time, error rate, queue depth) | |
| 8.6 | Alerting thresholds are defined for key metrics | |
| 8.7 | Distributed tracing is configured for cross-service requests | |

## 9. Deployment and operations

| # | Check | Status |
|---|---|---|
| 9.1 | Deployment strategy supports zero-downtime releases | |
| 9.2 | Database migrations are backward-compatible with the previous application version | |
| 9.3 | Feature flags are used for risky changes that may need quick rollback | |
| 9.4 | Environment-specific configuration is externalized (not hardcoded) | |
| 9.5 | Required infrastructure changes are documented | |
| 9.6 | Runbook exists for common operational scenarios (restart, scale, rollback) | |

## 10. Testing strategy

| # | Check | Status |
|---|---|---|
| 10.1 | Unit test boundaries are identified (what is tested in isolation) | |
| 10.2 | Integration test scope is defined (which component interactions to test) | |
| 10.3 | Test data strategy is defined (fixtures, factories, seeding) | |
| 10.4 | Performance test scenarios are identified for critical paths | |
| 10.5 | Contract tests are planned for API boundaries between services | |

---

## Framework-specific checks

Extra items for designs built on a web framework. Adapt them to your stack:

| # | Check | Status |
|---|---|---|
| F.1 | Authorization logic beyond simple roles uses dedicated policy/guard objects | |
| F.2 | ORM entity mappings use suitable fetch modes (lazy vs eager loading) | |
| F.3 | Async operations are configured with transport, retry, and dead-letter handling | |
| F.4 | Cache invalidation strategy uses tags or versioned keys where appropriate | |
| F.5 | Cross-cutting concerns (logging, auditing) use middleware or event hooks, not controller logic | |
| F.6 | Validation rules are defined on DTOs/models, not scattered in controllers | |
| F.7 | Serialization configuration controls API response shaping | |
| F.8 | CLI commands exist for operational tasks (data migration, cleanup) | |

---

## Review outcomes

| Outcome | Definition | Next step |
|---|---|---|
| **Approved** | All applicable checks pass or have acceptable N/A justification | Proceed to implementation |
| **Approved with conditions** | Minor issues found that can be fixed during implementation | Proceed, track conditions as tasks |
| **Revise and re-review** | Significant issues found that change the design | Architect revises, schedule another review |
| **Rejected** | Fundamental problems with the approach | Return to design phase, consider alternatives |

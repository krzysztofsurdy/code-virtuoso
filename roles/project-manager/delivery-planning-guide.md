# Delivery Planning Guide

A guide to planning project delivery with stage-gate principles. Covers work breakdown, dependency mapping, critical path identification, stage planning, and estimation.

## Contents

- [Planning approach](#planning-approach)
- [Work breakdown structure](#work-breakdown-structure)
- [Dependency mapping](#dependency-mapping)
- [Critical path](#critical-path)
- [Stage planning](#stage-planning)
- [Estimation guidelines](#estimation-guidelines)
- [Planning checklist](#planning-checklist)

---

## Planning approach

### Product-based planning

Plan what to deliver before planning how to deliver it. This PRINCE2 approach keeps the team focused on outcomes instead of activities.

| Step | Activity | Output |
|---|---|---|
| 1 | Identify the products (deliverables) needed | Product list |
| 2 | Write a product description for each | Product descriptions |
| 3 | Identify dependencies between products | Product flow diagram |
| 4 | Estimate effort for each product | Effort estimates |
| 5 | Assign products to stages | Stage plan |

### Product description template

| Field | Content |
|---|---|
| **Product** | [Name of the deliverable] |
| **Purpose** | [Why this product is needed] |
| **Composition** | [What this product consists of: its parts] |
| **Quality criteria** | [How to determine if the product is acceptable] |
| **Quality method** | [How quality will be checked - review, test, demo] |
| **Dependencies** | [What must exist before this product can be created] |
| **Produced by** | [Role responsible for creating it] |
| **Approved by** | [Role responsible for accepting it] |

### Example product descriptions

**Product: Order API Endpoints**

| Field | Content |
|---|---|
| **Purpose** | Enable frontend to create, view, and manage customer orders |
| **Composition** | POST /orders, GET /orders, GET /orders/{id}, PATCH /orders/{id}/status |
| **Quality criteria** | All endpoints match API contract; unit test coverage > 80%; integration tests pass; API documentation is accurate |
| **Quality method** | Code review by architect; automated test suite; QA functional testing |
| **Dependencies** | Data model (Product entity, Order entity), API contract from architect |
| **Produced by** | Backend developer |
| **Approved by** | Architect (technical), QA (functional) |

---

## Work breakdown structure

### How to break down work

1. Start with the final deliverable
2. Decompose into major components
3. Decompose each component into work packages
4. Stop when each work package can be estimated with reasonable confidence (typically 1-5 days of effort)

### Work breakdown template

```
1. [Project/Feature Name]
   1.1 [Component A]
       1.1.1 [Work package: specific deliverable]
       1.1.2 [Work package: specific deliverable]
   1.2 [Component B]
       1.2.1 [Work package]
       1.2.2 [Work package]
   1.3 [Cross-cutting]
       1.3.1 [Work package]
```

### Example: e-commerce order feature

```
1. Order Management Feature
   1.1 Data Model
       1.1.1 Order entity and migration
       1.1.2 OrderItem entity and migration
       1.1.3 Order status enum and transitions
   1.2 Backend API
       1.2.1 Create order endpoint (POST /orders)
       1.2.2 List orders endpoint (GET /orders)
       1.2.3 Order detail endpoint (GET /orders/{id})
       1.2.4 Update order status endpoint (PATCH /orders/{id}/status)
       1.2.5 Order validation and business rules
   1.3 Frontend
       1.3.1 Order creation form
       1.3.2 Order list view with pagination
       1.3.3 Order detail view
       1.3.4 Order status management UI
   1.4 Integration
       1.4.1 Payment gateway integration
       1.4.2 Email notification on order status change
   1.5 Testing
       1.5.1 Backend unit and integration tests
       1.5.2 Frontend component tests
       1.5.3 End-to-end test suite
       1.5.4 QA test plan and execution
   1.6 Documentation
       1.6.1 API documentation
       1.6.2 Deployment runbook
```

---

## Dependency mapping

### Dependency types

| Type | Description | Example |
|---|---|---|
| **Finish-to-Start (FS)** | B cannot start until A finishes | Cannot build API endpoints until data model is complete |
| **Start-to-Start (SS)** | B cannot start until A starts | Frontend and backend can start simultaneously after design is done |
| **Finish-to-Finish (FF)** | B cannot finish until A finishes | Documentation cannot be finalized until implementation is complete |
| **External** | Dependency on something outside the team's control | Third-party API must be available; infrastructure must be provisioned |

### Dependency matrix

| Work Package | Depends On | Dependency Type | Risk if Delayed |
|---|---|---|---|
| 1.2.1 Create order endpoint | 1.1.1 Order entity | Finish-to-Start | Blocks all API work |
| 1.3.1 Order creation form | 1.2.1 Create order endpoint | Finish-to-Start | Frontend can mock, but integration delayed |
| 1.4.1 Payment integration | External: Payment API sandbox | External | Blocks checkout flow testing |
| 1.5.4 QA test execution | 1.2.x All API endpoints | Finish-to-Start | Delays quality sign-off |

### Reducing dependency risk

| Strategy | When to use |
|---|---|
| **Parallelize** | Start items that have no dependency between them at the same time |
| **Mock dependencies** | Frontend develops against mock API while backend builds the real one |
| **Interface-first** | Agree on API contracts early so both sides can work independently |
| **Decouple** | Design components so they can be built and tested independently |
| **Early integration** | Integrate early and often instead of waiting until everything is done |

---

## Critical path

### Identifying the critical path

The critical path is the longest sequence of dependent tasks. Any delay on the critical path delays the entire project.

1. List all work packages with their dependencies and estimated durations
2. Trace all possible paths from start to finish
3. Calculate the total duration of each path
4. The longest path is the critical path

### Example

```
Path A: Data Model (3d) -> API Endpoints (8d) -> API Tests (3d) -> QA (5d) = 19 days
Path B: Data Model (3d) -> API Endpoints (8d) -> Frontend Integration (4d) -> E2E Tests (2d) = 17 days
Path C: Design (2d) -> Frontend Components (6d) -> Frontend Integration (4d) -> E2E Tests (2d) = 14 days

Critical Path: A (19 days)
```

### Managing the critical path

| Action | Effect |
|---|---|
| Add resources to critical path tasks | May reduce duration (diminishing returns beyond a point) |
| Overlap critical path tasks where possible | Reduces overall duration (increases risk) |
| Reduce scope of critical path tasks | Directly reduces duration |
| Move tasks off the critical path | Does not help, because they are not the bottleneck |
| Monitor critical path tasks closely | Early warning of delays |

---

## Stage planning

### Stage boundaries

A stage is a natural breakpoint where the project board reviews progress and decides whether to proceed.

| Guideline | Rationale |
|---|---|
| Each stage produces at least one deliverable | Stages must show progress |
| Stage duration is 2-6 weeks | Short enough to keep control, long enough to deliver value |
| Stage boundary aligns with a decision point | Natural time to reassess business case and plan |
| Each stage has clear entry and exit criteria | Objective basis for stage gate decisions |

### Stage plan template

| Field | Content |
|---|---|
| **Stage** | [Stage name/number] |
| **Objective** | [What this stage achieves] |
| **Duration** | [Start date to end date] |
| **Deliverables** | [List of products delivered in this stage] |
| **Resources** | [Team members and their allocation] |
| **Dependencies** | [External dependencies for this stage] |
| **Risks** | [Top risks for this stage] |
| **Tolerances** | [Schedule: +/- X days; Scope: Y items can be deferred] |
| **Entry criteria** | [What must be true to start this stage] |
| **Exit criteria** | [What must be true to end this stage] |

### Example stage plan

**Stage 2: Backend Implementation**

| Field | Content |
|---|---|
| **Objective** | Deliver working API endpoints for order management |
| **Duration** | 2025-10-01 to 2025-10-18 (3 weeks) |
| **Deliverables** | Order API (CRUD), data migrations, API tests, API documentation |
| **Resources** | 2 backend developers (full-time), architect (20% for review) |
| **Dependencies** | Stage 1 complete (design approved, API contracts finalized) |
| **Risks** | R-003: Payment API integration complexity (mitigation: PoC in week 1) |
| **Tolerances** | Schedule: +3 days; Scope: payment integration can be deferred to Stage 3 |
| **Entry criteria** | API contracts approved; data model design approved; test environment ready |
| **Exit criteria** | All CRUD endpoints pass API tests; code review complete; QA signs off on test readiness |

---

## Estimation guidelines

### Estimation techniques

| Technique | When to use | Accuracy |
|---|---|---|
| **Expert judgment** | Familiar work with experienced team | Medium-High |
| **Analogous** | Similar to previous work | Medium |
| **Three-point** | Uncertain work | Medium-High |
| **T-shirt sizing** | Early planning, relative comparison | Low-Medium |

### Three-point estimation

For each work package, estimate three values:

| Estimate | Definition |
|---|---|
| **Optimistic (O)** | Everything goes right, no surprises |
| **Most Likely (M)** | Normal conditions, typical obstacles |
| **Pessimistic (P)** | Major problems arise (but the task is still feasible) |

**Expected duration**:

```
Expected = (O + 4M + P) / 6
```

### Common estimation mistakes

| Mistake | Fix |
|---|---|
| Estimating only the "happy path" | Use three-point estimation; always include testing and review time |
| Forgetting non-coding work | Include: code review, documentation, deployment, bug fixing, meetings |
| Confusing effort with duration | 5 days of effort from someone at 50% allocation = 10 calendar days |
| Anchoring on previous estimates | Re-estimate based on current understanding, not old numbers |
| Not including buffer | Add 20-30% contingency for unknowns in unfamiliar work |
| Estimating in isolation | Estimate as a team; discuss assumptions and risks |

---

## Planning checklist

Before presenting a stage plan:

- [ ] All deliverables have product descriptions with quality criteria
- [ ] Work breakdown is detailed enough for a confident estimate (1-5 day packages)
- [ ] Dependencies are mapped and external dependencies have owners
- [ ] Critical path is identified and the total duration is understood
- [ ] Estimates include coding, testing, review, documentation, and deployment
- [ ] Tolerances are defined for schedule and scope
- [ ] Entry and exit criteria are specified
- [ ] Top risks are identified with response strategies
- [ ] Resource assignments match availability (not over-allocated)
- [ ] The plan is reviewed by the team that will execute it

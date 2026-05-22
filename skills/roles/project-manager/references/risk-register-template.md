# Risk Register Template

A structured approach to identifying, assessing, and managing project risks. The risk register is a living document updated throughout the project lifecycle.

---

## Risk Register Template

### [Project Name] - Risk Register

**Last Updated**: [YYYY-MM-DD]

**Owner**: [Project Manager]

---

| ID | Risk | Category | Probability | Impact | Score | Response | Owner | Status | Date Identified |
|---|---|---|---|---|---|---|---|---|---|
| R-001 | [Risk description] | [Category] | [H/M/L] | [H/M/L] | [Score] | [Response strategy and action] | [Name] | Open / Mitigating / Closed / Materialized | [Date] |
| R-002 | [Risk description] | [Category] | [H/M/L] | [H/M/L] | [Score] | [Response strategy and action] | [Name] | Open / Mitigating / Closed / Materialized | [Date] |

---

## Probability/Impact Matrix

### Scoring Guide

| Level | Probability | Definition |
|---|---|---|
| **High (3)** | > 70% | Very likely to occur based on evidence or past experience |
| **Medium (2)** | 30-70% | Could occur; some indicators suggest it might |
| **Low (1)** | < 30% | Unlikely but possible |

| Level | Impact | Definition |
|---|---|---|
| **High (3)** | Major impact on at least one tolerance dimension | Schedule slip > 1 week, scope reduction of P0 items, budget overrun > 15% |
| **Medium (2)** | Noticeable impact, manageable within tolerances | Schedule slip 2-5 days, P1 items deferred, budget pressure |
| **Low (1)** | Minor impact, absorbed within normal operations | Schedule slip < 2 days, cosmetic items deferred |

### Risk Score

```
Risk Score = Probability x Impact
```

| Score | Risk Level | Action Required |
|---|---|---|
| **9 (H x H)** | Critical | Immediate mitigation action required. Escalate to project board. |
| **6 (H x M or M x H)** | High | Active mitigation plan. Review weekly. |
| **4 (M x M)** | Medium | Monitor. Mitigation plan defined but may not be activated yet. |
| **3 (H x L or L x H)** | Medium | Monitor. Trigger response if probability or impact changes. |
| **2 (M x L or L x M)** | Low | Monitor at regular intervals. |
| **1 (L x L)** | Low | Accept. Review monthly. |

### Visual Matrix

```
              Low Impact (1)    Medium Impact (2)    High Impact (3)
           +------------------+------------------+------------------+
High (3)   |   3 - Medium     |   6 - High       |   9 - Critical   |
           +------------------+------------------+------------------+
Medium (2) |   2 - Low        |   4 - Medium     |   6 - High       |
           +------------------+------------------+------------------+
Low (1)    |   1 - Low        |   2 - Low        |   3 - Medium     |
           +------------------+------------------+------------------+
```

---

## Risk Categories

| Category | Description | Examples |
|---|---|---|
| **Technical** | Technology, architecture, infrastructure risks | New technology fails to meet performance targets; integration complexity underestimated |
| **Resource** | Team capacity, skills, availability | Key team member unavailable; skill gap in required technology |
| **Schedule** | Timeline, dependencies, estimation risks | Dependencies delayed; estimates too optimistic; external deadlines fixed |
| **Scope** | Requirements, scope changes, ambiguity | Requirements change mid-stage; acceptance criteria are ambiguous |
| **External** | Third parties, vendors, regulations | Vendor API changes; regulatory requirement changes; external service outage |
| **Quality** | Testing, defects, technical debt | Insufficient test coverage; accumulated technical debt slows development |
| **Operational** | Deployment, infrastructure, monitoring | Production deployment fails; monitoring gaps hide issues |

---

## Risk Response Strategies

| Strategy | When to Use | Example |
|---|---|---|
| **Avoid** | Change the plan to eliminate the risk entirely | Use a proven library instead of building custom; remove the risky feature from scope |
| **Mitigate** | Reduce probability or impact through proactive action | Add a proof of concept to reduce technical uncertainty; cross-train team members to reduce key-person risk |
| **Transfer** | Shift the risk to a third party | Use a managed service instead of self-hosting; outsource a specialized component |
| **Accept** | The risk is low enough or the cost of response exceeds the impact | Document the risk and monitor it; set aside contingency time |
| **Escalate** | The risk is beyond the project manager's authority to manage | Escalate budget risks to the project board; escalate regulatory risks to legal |

---

## Common Software Project Risks

Pre-populated risks to consider at the start of any project. Evaluate each for applicability.

### Technical Risks

| Risk | Typical Probability | Typical Impact | Default Response |
|---|---|---|---|
| Underestimated integration complexity | High | High | Proof of concept early; time buffer in estimates |
| Performance targets not met | Medium | High | Performance testing early; define fallback approach |
| Data migration more complex than expected | Medium | High | Dry-run migration on production-scale data before go-live |
| Third-party API changes during development | Low | Medium | Pin API version; build adapter layer |
| Security vulnerability in dependency | Medium | Medium | Automated dependency scanning in CI; update policy |

### Resource Risks

| Risk | Typical Probability | Typical Impact | Default Response |
|---|---|---|---|
| Key developer unavailable (illness, departure) | Low | High | Cross-training; documentation; no single-person dependencies |
| Team lacks expertise in required technology | Medium | Medium | Training or spike time budgeted; pair programming |
| Team context-switching between projects | Medium | Medium | Dedicated allocation agreement; protect focus time |

### Schedule Risks

| Risk | Typical Probability | Typical Impact | Default Response |
|---|---|---|---|
| Estimates too optimistic | High | Medium | Add 20-30% buffer; compare with historical data |
| External dependency delivers late | Medium | High | Identify alternatives; decouple where possible; early integration testing |
| Scope creep during implementation | High | Medium | Change control process; explicit out-of-scope documentation |
| Testing takes longer than planned | Medium | Medium | Start testing earlier; automate regression tests |

### External Risks

| Risk | Typical Probability | Typical Impact | Default Response |
|---|---|---|---|
| Regulatory or compliance requirement change | Low | High | Monitor regulatory updates; build flexibility into the design |
| Vendor/provider outage during critical period | Low | High | Identify backup providers; design for graceful degradation |
| Stakeholder changes priorities mid-project | Medium | Medium | Formal change control; regular stakeholder alignment meetings |

---

## Risk Register Maintenance

### Review Cadence

| Activity | Frequency | Who |
|---|---|---|
| Review all open risks | Weekly during stage | Project manager |
| Update risk scores | At each review | Project manager |
| Identify new risks | Weekly + at stage boundaries | Entire team |
| Close resolved risks | As they resolve | Project manager |
| Report top risks | Each highlight report | Project manager |
| Full risk review | Stage boundaries | Project manager + project board |

### Risk Register Hygiene

| Check | Frequency |
|---|---|
| Every risk has an owner | Every review |
| Every high/critical risk has an active response | Every review |
| Materialized risks are converted to issues | When they occur |
| Closed risks include the resolution | When closing |
| No stale risks (unchanged for 3+ reviews without justification) | Monthly |
| Risk descriptions are specific enough to act on | Every review |

### Bad Risk Descriptions vs Good

| Bad | Good |
|---|---|
| "Technical issues" | "PostgreSQL query performance degrades beyond 500ms for the product search endpoint when catalog exceeds 100K products" |
| "Team might not deliver on time" | "Backend developer is splitting time with Project X, reducing availability to 60%, which may delay API delivery by 1 week" |
| "Security risk" | "User-generated content is rendered without sanitization in the admin dashboard, creating an XSS vulnerability" |
| "Dependencies" | "Payment gateway v2 API is in beta; breaking changes before our go-live date (March 15) would require rework of the checkout flow" |

# Sprint Goal Writing

A Sprint Goal is a concise statement that gives the Sprint purpose, direction, and focus. Think of it as the Commander's Intent: what are we trying to achieve, and why does it matter? The Sprint Goal does not change during a Sprint. If discoveries invalidate it entirely, the Product Owner may cancel the Sprint.

## Contents

- [Five templates](#five-templates)
- [SMART criteria applied to Sprint Goals](#smart-criteria-applied-to-sprint-goals)
- [Common anti-patterns and fixes](#common-anti-patterns-and-fixes)
- [Practical tips](#practical-tips)

## Five templates

### 1. Focus / Impact / Confirmation Template

The most widely used format. Its three parts cover outcome, value, and verification.

**Format:**
```
Our focus is on [outcome].
We believe it delivers [impact] to [stakeholder/customer].
This will be confirmed when [measurable event happens].
```

**Examples:**

```
Our focus is on enabling self-service password reset.
We believe it delivers reduced support burden to the helpdesk team.
This will be confirmed when a user can reset their password without contacting support.
```

```
Our focus is on automated invoice generation for monthly billing.
We believe it delivers time savings to the finance team.
This will be confirmed when the system generates and emails invoices on the 1st of each month.
```

```
Our focus is on consolidating user data from the legacy system.
We believe it delivers a single source of truth to all product teams.
This will be confirmed when all active users exist in the new system with verified data integrity.
```

---

### 2. Goal / Method / Metrics Template

A three-part structure connecting what to build, how to achieve it, and how to measure success.

**Format:**
```
Goal:    [what specifically to build or achieve]
Method:  [how to achieve it - must be viable in the actual product]
Metrics: [what data demonstrates success]
```

**Examples:**

```
Goal:    Allow customers to track their order status in real time
Method:  Build an order tracking page with webhook-driven status updates
Metrics: 80% of customers check tracking at least once per order; support tickets about order status drop by 50%
```

```
Goal:    Reduce page load time for the product catalog
Method:  Implement CDN caching and lazy-load images below the fold
Metrics: P95 load time drops from 4.2s to under 2s; bounce rate decreases
```

---

### 3. Feature-Advantage-Benefit (FAB) Template

Three components from the stakeholder's perspective: what, how it helps, why it matters.

**Format:**
```
Feature:   [the "what" - what is being built]
Advantage: [the "how" - what makes it distinctive or useful]
Benefit:   [the "why" - business outcome achieved]
```

**Examples:**

```
Feature:   One-click export of dashboard data to presentation format
Advantage: Users share results with clients without manual formatting
Benefit:   Sales team saves 2 hours per week on report preparation
```

```
Feature:   Role-based access control for the admin panel
Advantage: Granular permissions replace the all-or-nothing approach
Benefit:   Security team grants the minimum access needed, which reduces risk
```

---

### 4. FOCUS evaluation framework

An acronym for evaluating Sprint Goal quality after drafting. Similar to INVEST for User Stories.

| Letter | Criterion | Question to Ask |
|---|---|---|
| **F** | Fun | Is the title memorable? Would the team remember it without looking? |
| **O** | Outcome-oriented | Can multiple approaches achieve the same result? (If yes, it describes an outcome, not a task.) |
| **C** | Collaborative | Was the team involved in crafting it? |
| **U** | Ultimate | Is relevant context provided explaining why it matters to the business? |
| **S** | Singular | Is it one objective, not a list? |

**Process:**

1. Split the team into two groups during Sprint Planning
2. Group 1 answers the "what" and "why" of the goal
3. Group 2 addresses supporting questions (capacity, risks, dependencies)
4. Reunite and formulate the Sprint Goal together
5. Evaluate against FOCUS criteria before committing

---

### 5. Headline Format

Write the Sprint Goal as a news headline capturing the successful Sprint outcome. Short, memorable, and results-oriented.

**Format:** Write a headline (under 15 words) that a stakeholder would understand without context.

**Examples:**

```
"One-click checkout goes live, cutting cart abandonment by 30%"
```

```
"Platform migration complete: all active users now on new infrastructure"
```

```
"Real-time notifications replace manual status checking"
```

**When to use:** Teams that struggle with verbose or abstract goals. The headline constraint forces brevity and clarity.

---

## SMART criteria applied to Sprint Goals

### Specific

Bad: "Improve site performance"
Good: "Reduce product catalog page load time to under 2 seconds at P95"

The specific version tells the team exactly what to target and how to measure it.

### Measurable

Bad: "Make the checkout better"
Good: "Increase checkout completion rate from 62% to 75% by simplifying the payment step"

Include a number, percentage, or observable event that confirms success.

### Achievable

Bad: "Rebuild the entire authentication system" (in a 2-week sprint with 3 developers)
Good: "Implement OAuth2 login for Google accounts alongside existing email/password auth"

Base on actual team velocity. If the team averages 30 story points per sprint, do not plan for 50.

### Relevant

Bad: "Add dark mode to the admin panel" (when the business priority is reducing churn)
Good: "Add a cancellation flow that captures reasons and offers retention incentives"

The goal must connect to the current Product Goal and business priorities.

### Time-bound

Every Sprint Goal is inherently time-bound by the Sprint duration. Fit the scope to the timebox. If it does not fit, reduce scope rather than extending the Sprint.

---

## Common anti-patterns and fixes

| Anti-Pattern | Example | Why It Fails | Fix |
|---|---|---|---|
| **Task list** | "Complete PBI-101, PBI-102, PBI-103" | No strategic focus; team cannot negotiate scope | "Enable users to manage their own subscriptions" |
| **Vague aspiration** | "Improve quality" | No direction, no way to confirm completion | "Reduce critical bugs in checkout to zero by adding integration tests for payment flow" |
| **Multiple objectives** | "Build search AND implement notifications" | Splits focus, harder to negotiate scope | Pick the higher-priority one; defer the other |
| **Solution-focused** | "Migrate to PostgreSQL 16" | Describes implementation, not business value | "Eliminate query timeout errors that block monthly reporting" |
| **Copy of previous sprint** | Same goal every sprint | Indicates the goal is too large or not meaningful | Break into smaller outcomes; each Sprint should deliver distinct value |
| **No goal at all** | Team skips goal during planning | Lost focus, no way to prioritize during the Sprint | Always define a Sprint Goal - it is a required element of Sprint Planning |

---

## Practical tips

1. **Treat the Sprint Goal as an elevator pitch** - if you had 30 seconds with an executive, could you explain what the team is doing and why?
2. **Show progression across sprints** - Sprint 1: "Basic shopping cart with add/remove", Sprint 2: "Checkout with payment processing", Sprint 3: "Order confirmation and email receipts"
3. **The Product Owner proposes, the team refines** - the PO brings a draft goal; the team adjusts based on capacity and technical reality
4. **Include the Sprint Goal in review invitations** - stakeholders can decide whether to attend based on whether the goal is relevant to them
5. **Sprint Goals are not always possible** - teams handling unrelated client work or pure maintenance sprints may struggle to craft a single meaningful goal. That is OK. Do not force a bad goal for the sake of having one.
6. **Reference the goal daily** - if no one mentions the Sprint Goal during the Daily Scrum, it is not doing its job

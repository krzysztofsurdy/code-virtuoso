# Chaining Patterns

When a single skill or agent is not enough, chain them. These patterns describe common multi-step flows. They are templates, not prescriptions - skip steps that do not apply, add steps that do.

If a pre-composed team exists that matches the chain, use the team instead of assembling ad-hoc.

## Pattern Index

| Pattern | Shape | When to use |
|---|---|---|
| Investigation | Read-only agents in sequence | Changing unfamiliar code or debugging |
| Feature delivery | Requirements -> Design -> Implementation -> QA | Building a new user-facing capability |
| Code health | Scanner -> Reviewer -> (optional) Implementer | Improving code quality and reducing tech debt |
| Migration | Planner -> Reviewer -> Implementer | Non-trivial schema or data migration |
| Coverage | Gap analyzer -> Implementer -> Reviewer | Raising test coverage strategically |
| Idea to ship | Brainstorming -> Planning -> Execution | Going from a vague idea to shipped code |

## Investigation Chain

```
Investigator -> Architect -> Implementer -> Reviewer
```

Start when the code area is unfamiliar. Investigator maps the landscape (dependencies, call paths, data flow). Architect decides what to change. Implementer executes with TDD. Reviewer verifies.

**Skip Architect** if the change is small and the Investigator's findings are sufficient to implement directly.

## Feature Delivery Chain

```
Product Manager -> Architect -> Backend Dev + Frontend Dev (parallel) -> QA Engineer
```

Start when a new feature needs to be built end-to-end. PM defines requirements and acceptance criteria. Architect designs the solution and API contract. Dev roles implement in parallel worktrees. QA writes test plan and signs off.

**Use the `development-team`** if it is installed - it wraps this chain with coordination rules and spawning protocol.

**Skip Frontend Dev** for backend-only features. **Skip Architect** if the feature fits an existing pattern with no new design decisions.

## Code Health Chain

```
Refactor Scout -> Reviewer -> Implementer
```

Start when improving code quality. Scout scans for smells and structural issues. Reviewer validates findings against actual code context. Implementer applies refactorings with TDD.

**Skip Implementer** if the goal is an audit report, not a fix.

## Migration Chain

```
Migration Planner -> Reviewer -> Implementer
```

Start before running non-trivial database migrations. Planner classifies risk, checks rollback paths, and produces an execution plan. Reviewer checks that application code handles both old and new schemas. Implementer applies code changes.

## Coverage Chain

```
Test Gap Analyzer -> Implementer -> Reviewer
```

Start when test coverage needs targeted improvement. Analyzer identifies missing tests by priority. Implementer writes the tests. Reviewer verifies they are meaningful.

## Idea to Ship Chain

```
Brainstorming -> Writing-Plans -> Subagent-Driven-Development
```

Start when the user has a vague idea. Brainstorming produces a spec. Writing-Plans turns the spec into an ordered implementation plan. Subagent-Driven-Development executes the plan with one agent per task and two-stage review gates.

## When NOT to Chain

- The task fits a single specialist agent - do not add a chain for ceremony
- The user asked for reference, not execution - recommend a knowledge skill, not an agent chain
- The chain would have only two steps with no real dependency - just dispatch the two agents independently

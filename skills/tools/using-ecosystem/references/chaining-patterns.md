# Chaining patterns

When one skill or agent is not enough, chain them. These are templates: skip steps that do not apply and add steps that do. If a workflow matches the chain, run the workflow instead of assembling it by hand.

## Contents

- [Pattern index](#pattern-index)
- [Investigation chain](#investigation-chain)
- [Feature delivery chain](#feature-delivery-chain)
- [Code health chain](#code-health-chain)
- [Migration chain](#migration-chain)
- [Coverage chain](#coverage-chain)
- [Idea to ship chain](#idea-to-ship-chain)
- [Review chain](#review-chain)
- [When not to chain](#when-not-to-chain)

## Pattern index

| Pattern | Shape | When to use |
|---|---|---|
| Investigation | Investigator, architect, implementer, reviewer | Changing unfamiliar code or debugging |
| Feature delivery | Requirements, design, implementation, QA | Building a new user-facing capability |
| Code health | Scanner, reviewer, implementer | Reducing tech debt |
| Migration | Planner, reviewer, implementer | A non-trivial schema or data migration |
| Coverage | Gap analyzer, implementer, reviewer | Raising test coverage where it counts |
| Idea to ship | Brainstorming, spec-driven development, tdd | Going from a vague idea to shipped code |
| Review | Reviewer or review squad, pr-feedback, finishing-branch | Getting a change merged |

## Investigation chain

```
investigator -> architect -> implementer -> reviewer
```

The investigator maps dependencies, call paths, and data flow. The architect decides what to change. The implementer executes with `tdd`. The reviewer verifies. Skip the architect when the findings are enough to implement directly.

## Feature delivery chain

```
product-manager -> architect -> plan-auditor -> backend-dev + frontend-dev (parallel) -> qa-engineer
```

The product manager writes requirements and acceptance criteria. The architect designs the solution and API contract. The plan auditor checks that requirements, design, and tasks line up before anyone builds. The dev agents implement in separate worktrees. QA writes the test plan and signs off.

The `development-team` workflow runs this chain with its gates. Skip `frontend-dev` for backend-only work and the architect when the feature fits an existing pattern.

## Code health chain

```
refactor-scout -> reviewer -> implementer
```

The scout scans for smells and maps each to a technique from `refactoring`. The reviewer checks the findings against real context. The implementer applies the refactorings with `tdd`. Stop after the reviewer if the goal is an audit, not a fix.

## Migration chain

```
migration-planner -> reviewer -> implementer
```

The planner classifies risk, checks rollback paths, and writes the execution plan. The reviewer checks that application code works with both the old and new schema. The implementer applies the code changes.

## Coverage chain

```
test-gap-analyzer -> implementer -> reviewer
```

The analyzer ranks missing tests by priority. The implementer writes them. The reviewer checks they are meaningful.

## Idea to ship chain

```
brainstorming -> spec-driven-development -> tdd (per task) -> finishing-branch
```

Brainstorming produces an approved spec. `spec-driven-development` turns it into a plan and task list and runs the tasks one at a time with a progress log. Each task follows `tdd`. `finishing-branch` merges. For several independent tasks, add `agent-orchestration`. For a long plan that should run without supervision, compile it with the `loop-virtuoso` backlog compiler and run the loop (Claude Code only).

From a ticket, `ticket-delivery` covers the same ground and ends with the PR.

## Review chain

```
reviewer (or review-squad workflow) -> implementer -> pr-feedback -> finishing-branch
```

Use the review squad for a significant change: cold reviewer, acceptance verifier, and an optional smell scan feed one full-context reviewer. After the PR is open, `pr-feedback` works through comments and failing CI.

## When not to chain

- The task fits one specialist agent. Do not add steps for ceremony.
- The user asked for reference, not execution. Recommend a knowledge skill.
- The chain has two steps with no real dependency. Run the two agents independently.

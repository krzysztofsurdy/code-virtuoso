---
name: development-team
description: "Full-stack feature delivery from requirements to merged PR. Use when implementing a new feature end-to-end, building a user-facing capability, or delivering a ticket that spans backend and frontend."
lead: product-manager
agents:
  - product-manager
  - architect
  - backend-dev
  - frontend-dev
  - qa-engineer
skills:
  - ticket-delivery
  - subagent-driven-development
  - verification-before-completion
  - api-design
  - testing
workflow: hybrid
---

# Development Team

## Purpose

Deliver a feature from a rough requirement through implementation to a verified, merged pull request. The team works requirements first, design second, TDD implementation third. Backend and frontend work in parallel once the API contract is agreed.

## Workflow

1. **Product Manager**: analyse the requirement. Write acceptance criteria in Given/When/Then form. Clarify scope, non-goals, and edge cases. Output: refined ticket with acceptance criteria.
2. **Architect**: design the solution. Define API contracts, data model changes, and component boundaries. Write an ADR if the design introduces a new pattern. Output: design document or ADR.
3. **Backend Dev + Frontend Dev** (parallel): implement in isolated worktrees using TDD. Backend builds the API and data layer. Frontend builds the UI against the agreed contract. Each commits after every green test. Output: working code with tests.
4. **QA Engineer**: write a test plan against the acceptance criteria. Execute tests. Report bugs with severity. Sign off when all criteria pass. Output: test report and sign-off.

## Entry Criteria

- A ticket or requirement with a clear goal exists
- A stakeholder is available to answer clarification questions
- The codebase is in a stable state (CI green, no blocking incidents)

## Exit Criteria

- All acceptance criteria verified by QA
- Code reviewed and approved
- Tests pass in CI
- PR merged to the target branch
- Documentation updated where applicable

## Coordination Rules

- Product Manager owns the task list and resolves scope questions
- Architect must approve the design before implementation starts
- Backend Dev and Frontend Dev work in separate worktrees, with no shared file edits
- QA blocks merge until sign-off is granted
- If the API contract changes during implementation, Architect must re-approve before work continues
- Use `subagent-driven-development` for the implementation phase: one task per agent, two-stage review gates
- Use `verification-before-completion` before claiming any phase is done

## Skill Usage

| Agent | Consult |
|---|---|
| Product Manager | `ticket-delivery` for ticket analysis workflow |
| Architect | `api-design` for contract design, `clean-architecture` for structure |
| Backend Dev / Frontend Dev | `testing` for TDD patterns, `design-patterns` for implementation |
| QA Engineer | `testing` for test strategy, `verification-before-completion` for sign-off |

## Spawning

**Peer mode** (platforms with agent-to-agent messaging):
1. Create a team with Product Manager as lead
2. Add Architect, Backend Dev, Frontend Dev, QA Engineer as teammates
3. Create tasks for each workflow phase with dependencies: Requirements (no deps) -> Design (blocked by Requirements) -> Backend Implementation + Frontend Implementation (both blocked by Design) -> QA Sign-off (blocked by both implementations)
4. Teammates claim tasks as they unblock, message each other for clarifications (e.g., Frontend asks Backend about API response shape)

**Sequential mode** (sub-agent dispatch):
1. Product Manager (lead) runs Phase 1 inline - writes acceptance criteria
2. Spawn Architect as sub-agent with the criteria. Collect design output
3. Spawn Backend Dev and Frontend Dev as parallel sub-agents with the design. Collect implementation output
4. Spawn QA Engineer as sub-agent with the acceptance criteria and implementation. Collect sign-off

## Variants

- **Backend-only**: Drop Frontend Dev. Architect designs API only, Backend Dev implements, QA verifies.
- **Spike mode**: Drop QA. Product Manager + Architect + one Dev explore feasibility. Output is a decision, not shippable code.

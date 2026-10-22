# Compass mode

When the user has just finished work with an agent, skill, or workflow and asks "what next?" or "where do I go from here?", recommend the next step.

## Contents

- [How it works](#how-it-works)
- [Recommendation map](#recommendation-map)
- [Handling ambiguity](#handling-ambiguity)
- [Dead ends](#dead-ends)
- [Workflows over chains](#workflows-over-chains)

## How it works

Compass is conversational. Ask what the user completed, then match it against the map. Do not scan the filesystem for artifacts.

## Recommendation map

| Just finished with | Likely next step | Why |
|---|---|---|
| **brainstorming** (spec approved) | `spec-driven-development`, or `ticket-delivery` from a ticket | The spec needs a plan and tasks |
| **spec-driven-development** (plan and tasks written) | `plan-auditor` agent, then `tdd` per task | Gate the plan, then build |
| **tdd** (task done) | `verification-before-completion`, then the next task or `finishing-branch` | Prove it, then continue or merge |
| **investigator** (report) | `architect` or `implementer` | Findings need a design or a direct fix |
| **researcher** (report) | `architect` to decide, `brainstorming` to shape a feature, or `skill-writer` to turn it into a skill | The findings feed a decision or a document |
| **product-manager** (requirements) | `architect` | Requirements need technical design |
| **architect** (ADR or design) | `plan-auditor`, then `backend-dev`, `frontend-dev`, or the `development-team` workflow | Check the plan, then build |
| **plan-auditor** (READY) | `implementer`, `backend-dev`, or `frontend-dev` | The gate passed |
| **plan-auditor** (NEEDS WORK or a change proposal) | The role that owns the gap, usually `product-manager` or `architect` | Fix the artifact, then re-audit |
| **backend-dev / frontend-dev** (code written) | `reviewer` or the `review-squad` workflow | Review before merging |
| **reviewer** (report) | `implementer` for fixes, or `finishing-branch` if approved | Apply fixes or merge |
| **cold-reviewer** (report) | `reviewer` to triage, then `implementer` | Cold findings need context to triage |
| **acceptance-verifier** (matrix) | `implementer` for FAIL or UNTESTED rows, or `finishing-branch` | Close the gaps or ship |
| **refactor-scout** (smell report) | `reviewer`, then `implementer` | Confirm findings, then refactor |
| **test-gap-analyzer** (gap report) | `implementer` | Write the missing tests |
| **migration-planner** (plan) | `reviewer`, then `implementer` | Validate the plan, then execute |
| **qa-engineer** (test plan or sign-off) | `finishing-branch` or `project-manager` | Ship, or update delivery tracking |
| **review-squad** (triaged report) | `implementer` for fixes, then `finishing-branch` | Address the items, then merge |
| **war-room** (synthesis) | `architect` to record the decision, then build | Turn the decision into an ADR and work |
| **dependency-auditor** (report) | `implementer` for upgrades, or `ticket-writer` to track them | Fix or track |
| **doc-writer** (docs) | `reviewer` or `finishing-branch` | Review, then ship |
| **finishing-branch** (PR open) | `pr-feedback` when comments or CI failures arrive | Work through feedback |
| **a session ending mid-task** | `handoff` | Leave a note the next session can resume from |

## Handling ambiguity

When the next step is unclear:

1. Present two or three options with one line of reasoning each.
2. Let the user choose.
3. If the user is unsure, recommend the safer path: more analysis before more action.

## Dead ends

Not every interaction needs a next step. Say "That looks complete. Nothing chains naturally from here unless you have a new task" when the user has:

- Finished a standalone task, such as a dependency audit with no findings.
- Completed a full workflow, such as a merged PR.
- Used a tool skill for a one-off output, such as `ticket-writer` or `report-writer`.

## Workflows over chains

If the compass would recommend three or more agents in sequence, check whether a workflow covers it (`development-team`, `review-squad`, `war-room`). Workflows include gates that an ad-hoc chain lacks.

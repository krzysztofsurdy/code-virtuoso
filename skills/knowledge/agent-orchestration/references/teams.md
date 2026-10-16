# Teams

A team is a fixed recipe: which agents take part, what each receives, and which gates apply. This file holds the three bundled recipes in plain Markdown so you can run them in any harness. On Claude Code each also exists as a workflow script in the plugin's `workflows/` directory, which runs the same recipe deterministically.

## Contents

- [Choosing a team](#choosing-a-team)
- [How to run a team](#how-to-run-a-team)
- [Review squad](#review-squad)
- [Development team](#development-team)
- [War room](#war-room)
- [Writing your own team](#writing-your-own-team)

## Choosing a team

| Situation | Use |
|---|---|
| Deliver a feature from ticket to merge-ready branch | Development team |
| Review a significant change from several angles | Review squad |
| Choose between options with real trade-offs | War room |
| A plain diff review | One `reviewer` agent, no team |
| Understand an area of code | One `investigator` agent, no team |

A team costs several agents' worth of tokens. If one agent can do the job, use one.

## How to run a team

| Harness | Run it as |
|---|---|
| Claude Code, plugin installed | The workflow: `/agents-virtuoso:review-squad`, `/agents-virtuoso:development-team`, `/agents-virtuoso:war-room`. Pass the inputs named in each section as `args` |
| Claude Code, agent teams flag on | Ask the lead to spawn teammates for the roster. Restate each teammate's skills and file ownership in its spawn prompt. Best for the war room and for review with cross-challenge. See [platform-notes.md](platform-notes.md) |
| Codex | Ask for the roster as subagents in one prompt: how to split, wait for all, what to return. Define the roster as custom agents in `.codex/agents/` first if you want fixed roles |
| Cursor | Launch the roster as parallel subagents from one message. Agent files in `.claude/agents/` load as they are |
| Anything else | Run the phases in order yourself, handing each agent only its brief, and play the lead's steps inline |

The "Run sequentially" lines below are the lowest common denominator. Parallel phases may still run in parallel wherever the harness can start several agents at once.

Teams that report to a decision-maker (the war room) end with a person choosing. A workflow cannot ask mid-run, so it returns the synthesis and stops. In other harnesses, stop at the same point.

## Review squad

Three reviewers look at the same change at three context levels, then a lead merges the findings into one triaged report. Comparing the views catches what a single reviewer misses.

| Role | Agent | Receives |
|---|---|---|
| Cold reviewer | `cold-reviewer` | The diff only. No spec, no docs, no history |
| Acceptance verifier | `acceptance-verifier` | The diff and the acceptance criteria. No project docs |
| Lead | `reviewer` | Full project context, plus both reports |
| Optional smell scan | `refactor-scout` | The touched files |

Inputs: the change (branch, PR, or range) and, when they exist, acceptance criteria.

Phases:

1. Cold review and acceptance check, in parallel. The cold reviewer returns findings from the code alone. The verifier returns a PASS, FAIL, PARTIAL, or UNTESTED row per criterion and lists changes no criterion asks for.
2. Lead review. The lead runs its own full review (correctness, design, security, performance, smells, tests), merges duplicates, and notes which reviewers found each issue. On a severity disagreement it keeps the higher one.

Tag each finding **fix**, **discuss**, **defer**, or **dismiss**.

Entry: a diff exists and tests pass. Without acceptance criteria, drop the verifier (the two-reviewer variant). Exit: one deduplicated report with every finding tagged.

Run sequentially: cold review, then acceptance check, then the lead with both reports.

Codex prompt:

```text
Review this branch against main with subagents. Spawn one cold reviewer that sees only
the diff and no docs, and one verifier that sees the diff plus these acceptance criteria:
[criteria]. Wait for both. Then review it yourself with full context, merge duplicates,
keep the higher severity on disagreement, and tag each finding fix, discuss, defer, or dismiss.
```

Variant: deep mode adds a refactor scout before the lead review.

## Development team

Takes a ticket to a verified, integrated branch. Requirements first, design second, then backend and frontend in parallel once the contract is fixed, then QA.

| Role | Agent |
|---|---|
| Product manager | `product-manager` |
| Architect | `architect` |
| Plan auditor | `plan-auditor` (gate mode) |
| Backend developer | `backend-dev` |
| Frontend developer | `frontend-dev` |
| QA engineer | `qa-engineer` |

Input: a ticket with a clear goal.

Phases:

1. **Requirements** (product manager): acceptance criteria in Given/When/Then form, scope, non-goals, open questions. Stop and ask the stakeholder if an open question would change the design.
2. **Design** (architect): API contract, data model changes, component boundaries, an ADR if a new pattern appears, and a task list. Each task has one owner, the exact files it may touch, and the criteria it satisfies. No file belongs to two tasks.
3. **Readiness gate** (plan auditor): every criterion traces to a design element and a task. Proceed only on READY.
4. **Implementation** (backend and frontend in parallel, one isolated worktree each): strict TDD, a commit after every green test, files limited to the task list. A task that cannot work with the contract is reported blocked, not worked around.
5. **Integration**: merge the branches one at a time, running the full suite after each. Stop on a conflict.
6. **QA sign-off** (QA engineer): verify every criterion with evidence, file bugs as P0 to P3, approve only with all criteria passing and no open P0 or P1.

Gates: the architect's design is approved before implementation, a changed contract goes back to the architect, and QA blocks the merge until sign-off. Use `agent-orchestration` review gates for the implementation tasks if they are many or sequential.

Entry: the ticket exists, CI is green, a stakeholder can answer questions. Exit: all criteria verified, the branch integrated and green. After exit, run the review squad on the branch, then follow `finishing-branch` to open the pull request.

Run sequentially: phases 1 to 3 in order, backend then frontend (or both at once if the harness allows), then integration, then QA.

Variants: backend-only drops the frontend developer. Spike mode drops QA and ends with a decision, not code.

Note for worktrees: they may branch from the default branch and miss unmerged work. See [isolation-and-merging.md](isolation-and-merging.md).

## War room

A decision forum, not a delivery pipeline. Roles argue from their own domain, challenge each other once, and a person decides. Nothing is written or run during the debate.

| Role | Agent | Argues from |
|---|---|---|
| Architect (lead) | `architect` | System design, maintainability, technical debt |
| Product manager | `product-manager` | User impact, business value, time to market |
| Backend developer | `backend-dev` | Implementation complexity, developer experience, operational burden |
| QA engineer | `qa-engineer` | Testability, risk surface, failure modes |

Input: the decision question, and the options if you know them.

Phases:

1. **Frame** (architect): state the question, constraints, and 2 to 4 options. With fewer than two real options, stop: there is nothing to debate.
2. **Position**: each role picks one option and argues for it, with the main risks. No hedging.
3. **Challenge**: each role attacks the weakest point of one other role's position. One round, no back-and-forth.
4. **Synthesize** (architect): agreements, disagreements, and per option the supporters, trade-offs, and risks. The architect does not recommend.
5. **Decide**: the person chooses. Record the question, options, arguments, choice, and rationale.

Rules: roles answer from knowledge, with no tools. A role with nothing to add says so in one sentence instead of inventing an opinion. Ties go to the person.

Entry: at least two viable options with real trade-offs, and someone available to decide. A trivial choice does not need a war room.

Run sequentially: ask each role for its position (give each the frame only), then ask each for its challenge (give each all positions), then synthesize. Roles are independent within a round, so run each round in parallel when you can.

Variants: lightweight is the architect plus one other role for a yes/no decision. Extended adds a frontend developer and a scrum master when UI or delivery cadence is affected.

## Writing your own team

1. Name the roster and give every agent one job and one context level.
2. Write each phase as: agent, input, output, and whether it runs in parallel with another.
3. State the gates: which phase blocks which, and who can send work back.
4. State entry and exit criteria so a run can end cleanly.
5. Add at least one decision point (a phase to skip, a variant to pick).
6. For Claude Code, encode it as `workflows/<name>.js` following https://github.com/krzysztofsurdy/code-virtuoso/blob/main/spec/team-spec.md. Keep this Markdown recipe as the fallback for other harnesses.

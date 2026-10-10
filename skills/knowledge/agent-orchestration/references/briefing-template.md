# Briefing template

A brief is the contract between you and a subagent. The agent starts with no memory of your conversation, so anything the brief leaves out does not exist for it. A good brief makes the result predictable and easy to merge with the results of other agents.

## Contents

- [The template](#the-template)
- [Field guidance](#field-guidance)
- [A complete example](#a-complete-example)
- [Emphasis by agent type](#emphasis-by-agent-type)
- [Output formats that merge well](#output-formats-that-merge-well)
- [Sizing a brief](#sizing-a-brief)
- [Common mistakes](#common-mistakes)

## The template

```
TASK: [One sentence. What must be true when the agent finishes.]

CONTEXT: [Why this matters and the constraints that apply. Only what this task needs.]

INPUTS:
- [Exact file paths, interface signatures, fixtures, or links]
- Prior work: [hand-off summary from the previous task, or "none"]

ACCEPTANCE CRITERIA:
1. [An observable condition a reviewer can check without judgment]
2. [...]

OUTPUT FORMAT: [The exact structure of the final report]

BOUNDARIES:
- In scope: [files or directories the agent may change]
- Out of scope: [what it must not touch, and who owns it]

IF STUCK: [Report and stop, skip and continue, or use a named fallback. Never guess.]
```

Drop ACCEPTANCE CRITERIA for pure research, where OUTPUT FORMAT carries the success test. Keep every other field.

## Field guidance

| Field | Good | Bad |
|---|---|---|
| **Task** | "List public methods in `src/orders/` that have no test." | "Look at the orders module and see what needs testing." |
| **Context** | One or two facts that change how the agent works ("audit is next week, focus on injection") | The whole conversation, or notes about other agents |
| **Inputs** | Concrete paths: `src/orders/service.*`, `tests/orders/` | "Check the order module" (where does it start and end?) |
| **Acceptance criteria** | "POST with a missing `customer_id` returns 422 with a field-level error" | "Validation works correctly" |
| **Output format** | A table with named columns and allowed values | "Tell me what you find" |
| **Boundaries** | "Modify only these three files. Do not touch the payment module." | None stated, so the agent helpfully fixes adjacent code |
| **If stuck** | "If a file cannot be parsed, mark it `unknown`, note why, and continue." | None stated, so the agent guesses past the blocker |

Tell the agent how to report status when it is a task in a sequence: `done`, `done with concerns`, `needs context` (name the missing fact), or `blocked` (name the blocker). The orchestrator reacts differently to each, see [review-gates.md](review-gates.md).

## A complete example

```
TASK: Find OWASP injection, broken-authentication, and data-exposure issues in the auth module.

CONTEXT: A security audit starts next week. The module changed a lot since the last review.

INPUTS:
- src/auth/controller.*, src/auth/token_service.*, src/auth/user_repository.*
- src/auth/middleware/rate_limiter.*, config/auth.yaml

OUTPUT FORMAT:
One section per OWASP category. Each finding has: file:line, severity
(critical/high/medium/low), what is wrong, a specific fix. Write "No issues
found." for an empty category.

BOUNDARIES:
- Read only. Do not modify files.
- Out of scope: authorization in other modules, gateway config, style and performance.

IF STUCK: If a file cannot be read, say so in the report and continue. If you are
unsure a finding is real, include it as severity low, marked "needs verification".
```

## Emphasis by agent type

Every brief has all the fields. What changes is where you spend the words.

| Agent type | Spend the words on |
|---|---|
| Investigator | Scope limits (depth, directories to skip) and a fixed output structure. Investigators follow every dependency chain unless told to stop. |
| Implementer | Acceptance criteria, the exact files it owns, and the test expectations. It works test first, so it needs to know what "done" looks like as a test. |
| Reviewer | The standard to apply, severity definitions, and the change to review. Include the acceptance criteria so it does not hunt for them. |
| Refactor scout | Target directories, smell categories to prioritize, and what to ignore because it is already tracked. |
| Doc writer | What changed, the audience, the format, and where the output goes. |

## Output formats that merge well

Choose the format before dispatching. When agents return different shapes, merging becomes manual work.

| Result type | Format |
|---|---|
| Findings | Table with columns File, Line, Finding, Severity, Category |
| Investigation | Fixed sections: Entry points, Code flow, Dependencies, Observations |
| Implementation | Completed (commit hash and summary), Blocked (what and why), Test results |
| Analysis | Counts first (files, issues by severity), then per-file detail |

Where the platform supports structured output (a JSON schema on the agent call), use it for findings. It removes parsing and makes deduplication a plain data operation.

## Sizing a brief

A brief describes work that fits one agent session without exhausting its context. Signs of an oversized task:

| Signal | Action |
|---|---|
| More than 5 files to change | Split by component or layer |
| More than 8 acceptance criteria | Split into two tasks with a clear boundary |
| The goal needs the word "and" between two behaviors | One task per behavior |
| Prior-work context runs past 20 lines | The task depends on too much earlier work, add a checkpoint |
| You cannot state the goal in one sentence | The task has several goals |

## Common mistakes

| Mistake | Effect | Fix |
|---|---|---|
| Pasting the conversation or the full plan | Dilutes focus, agent starts on the wrong task | Extract the facts and the current task only |
| No file paths | Agent spends its budget searching | Give entry points |
| "Tell me what you find" | Unstructured output that cannot be merged | Define columns or sections |
| No boundaries | Scope creep into adjacent code | List in-scope and out-of-scope |
| No failure instruction | Silent skips or invented answers | State what to do when stuck |
| Two objectives in one brief | Neither done well | One brief per objective |
| Referring to other agents | Creates implicit dependencies | Each agent works as if it were alone |

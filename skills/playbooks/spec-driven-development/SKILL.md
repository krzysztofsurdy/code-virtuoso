---
name: spec-driven-development
description: Turns an approved idea or ticket into spec artifacts saved in the repo (spec, plan, tasks), then executes them one task at a time with a progress log. Scales the ceremony to change size. Use to write a spec, plan this feature, break work into tasks, execute the plan, or resume multi-session work.
user-invocable: true
argument-hint: "[spec slug, ticket id, or path to an approved brainstorming spec]"
---

# Spec-driven development

A spec is a file in the repo that says what to build and how to know it works. A plan says how. A task list says in what order. Writing them down lets a fresh session, a sub-agent, or a teammate pick up the work with no memory of the conversation that produced it. Chat history is lost at compaction and between sessions; files are not.

This playbook starts where `brainstorming` or a ticket ends: the idea is approved, and the question is how to build it. It does not explore vague ideas (use `brainstorming`) or drive a ticket through branch and PR (use `ticket-delivery`, which can call this playbook for its planning and execution phases).

## Core principles

| Principle | Meaning |
|---|---|
| **Scale the ceremony** | A one-line fix does not need three documents. Pick the lightest artifact set that still lets a stranger finish the work. |
| **Specs are files, not chat** | Anything a later session needs goes in the repo. |
| **Ambiguity blocks planning** | Unresolved questions are marked in the spec and must be answered before the plan is written. |
| **Every requirement is testable** | Each has an ID and at least one WHEN/THEN criterion. If you cannot write the criterion, the requirement is not ready. |
| **One task, one verified commit** | A task is done when its check has run and passed, not when code exists. |
| **Specs outlive the change** | After merge, update the spec or archive it. A stale spec is worse than none. |

## Step 0: Find the project's layout

Before creating anything, look for an existing convention and follow it:

| If the repo has | Use |
|---|---|
| `.specify/` or `specs/<nnn-name>/` with `spec.md`, `plan.md`, `tasks.md` (GitHub Spec Kit) | Spec Kit layout and templates |
| `.kiro/specs/<name>/` with `requirements.md`, `design.md`, `tasks.md` (Kiro) | Kiro layout, EARS-style requirements |
| `openspec/` with `specs/` and `changes/` (OpenSpec) | OpenSpec change folders and delta specs |
| None of these | `specs/<slug>/spec.md`, `plan.md`, `tasks.md` (default used below) |

Also read the project's agent instructions (`AGENTS.md`, `CLAUDE.md`) for rules the spec must respect. Do not mix layouts in one repo.

## Step 1: Size the change

Pick the tier from the change itself, not from the ticket label. When two tiers fit, take the lighter one and escalate if the spec keeps growing.

| Tier | Typical signs | Artifacts |
|---|---|---|
| **Tiny** | One file or one behavior, no new interface, no data change, reviewable in minutes | Skip to tasks: a short checklist in the ticket or `specs/<slug>/tasks.md`, each item with its check |
| **Feature** | New behavior across several files, a new endpoint, screen, or job, one new or changed interface | `spec.md`, `plan.md`, `tasks.md` |
| **Large or brownfield** | Changes existing behavior across modules, touches contracts others rely on, or spans several sessions or people | Delta specs against the current specs, plus plan and tasks. See [delta-specs](references/delta-specs.md) |

Say which tier you chose and why, in one sentence, before writing. If the user disagrees, switch.

## Step 2: Write the spec

Use [spec-template](references/spec-template.md). The spec describes behavior and constraints, never file names or libraries; those belong in the plan.

1. **Pull from the source.** If a brainstorming spec or ticket exists, carry its goals, non-goals, and acceptance criteria over. Do not re-ask what is already answered.
2. **Number the requirements.** `FR-1`, `FR-2` for behavior; `NFR-1` for limits such as latency, security, accessibility. IDs never change once a plan references them.
3. **Write criteria as WHEN/THEN.** `WHEN a user submits an expired token THEN the API returns 401 with error code token_expired`. One behavior per criterion. Include the unhappy paths that are likely in production: invalid input, empty state, permission denied, upstream failure.
4. **Mark every unknown.** Write `[NEEDS CLARIFICATION: question]` next to the requirement it affects. Do not guess a default to keep moving. A guessed requirement becomes a bug that passes review.
5. **Record non-goals.** At least one. They stop scope creep during implementation.

**Gate:** planning does not start while any `[NEEDS CLARIFICATION]` marker remains. Ask the user the questions one at a time, update the spec, remove the marker. Then get the spec approved.

## Step 3: Write the plan

Use [plan-template](references/plan-template.md). Before writing, read the code the change touches: existing patterns, test layout, conventions. A plan that ignores the codebase produces new abstractions next to old ones.

1. Map each requirement ID to the components, files, and interfaces that satisfy it.
2. Record decisions with the alternatives you rejected and why. Keep this short; a decision that needs a page belongs in an ADR (`architect` role).
3. List risks and the order that retires the riskiest first.
4. State how each requirement will be verified (unit, integration, end-to-end, manual).

## Step 4: Break the plan into tasks

Use [tasks-template](references/tasks-template.md). Task format:

```
- [ ] T003 [P] [FR-2] Reject expired tokens in src/Auth/TokenValidator.php (test: tests/Auth/TokenValidatorTest.php)
```

| Part | Rule |
|---|---|
| `T003` | Sequential ID, never reused |
| `[P]` | Optional. Marks a task safe to run in parallel with its neighbors: different files, no dependency on unfinished tasks |
| `[FR-2]` | The requirement it serves. A task with no requirement is scope creep; a requirement with no task is a gap |
| Path | Every task names the files it creates or changes |
| Check | Every task names how to verify it: a test to pass or a command to run |

Order tasks so each one leaves the build green and the repo committable. Foundational tasks first, then one slice per requirement, then cleanup and docs. Write the test task before the code task it covers; the code task is done only through the loop in `tdd`.

## Step 5: Audit the artifacts

Before any implementation, delegate to the `plan-auditor` agent in **gate mode** with the spec, plan, and tasks. It traces each requirement to a design element and a task and returns READY, NEEDS WORK, or NOT READY.

- READY: proceed.
- NEEDS WORK: fix the blocking gaps, re-run the audit.
- NOT READY: go back to the spec; do not patch around it.

If no sub-agent is available, do the same trace yourself with the table in [tasks-template](references/tasks-template.md) (requirement to task coverage) and state the result.

## Step 6: Execute task by task

The rule that makes multi-session work reliable: **one task per session or per loop pass. Verify. Commit. Update progress.**

1. Read `tasks.md` and the progress log. Pick the first unchecked task whose dependencies are done. Never start from memory of what was "probably" finished.
2. Implement it with the `tdd` playbook.
3. Run the task's check, then the broader test suite. Capture the output; apply `verification-before-completion` before ticking the box.
4. Commit using the project's commit convention, one task per commit.
5. Tick the task in `tasks.md` and append an entry to the progress log ([progress-log-template](references/progress-log-template.md)): what was done, evidence, anything the next session must know.
6. Stop, or take the next task if the session has room. Do not batch several unverified tasks.

`[P]` tasks can go to parallel sub-agents only when their files do not overlap (see `dispatching-parallel-agents`). Each sub-agent gets one task ID, the spec path, and the check; the coordinator merges and updates the log.

### When the plan breaks

If implementation shows the spec is wrong or incomplete, stop coding. Update the spec first (new requirement ID or a revised criterion), then the plan and tasks, then continue. For a large mid-flight change, run `plan-auditor` in change-impact mode. Code that quietly diverges from the spec makes the artifacts worthless.

## Step 7: Close out

When every task is checked and the acceptance criteria pass:

| Layout | Action |
|---|---|
| Default `specs/<slug>/` | Set `Status: Implemented` in `spec.md`. Keep the folder if the feature will evolve; move it to `specs/archive/` if it is finished history. |
| OpenSpec | Merge deltas into `openspec/specs/` and archive the change (`openspec archive`, or follow the project's process). |
| Spec Kit or Kiro | Mark the spec implemented per the tool's convention. |

If behavior changed during implementation, update the spec to match what shipped. Link the spec from the PR description.

## Quick checklist

- [ ] Existing spec layout found and followed, or default chosen
- [ ] Tier chosen and stated
- [ ] Requirements numbered, each with WHEN/THEN criteria
- [ ] No `[NEEDS CLARIFICATION]` left; spec approved
- [ ] Plan maps every requirement to files and a verification method
- [ ] Tasks have IDs, requirement tags, paths, and checks; `[P]` only where safe
- [ ] `plan-auditor` gate returned READY
- [ ] Each task: tdd loop, verified, committed, progress logged
- [ ] Spec updated or archived after merge

## Reference files

| Reference | Contents |
|---|---|
| [spec-template](references/spec-template.md) | Spec skeleton with requirement IDs, WHEN/THEN criteria, clarification markers |
| [plan-template](references/plan-template.md) | Plan skeleton: requirement mapping, decisions, risks, verification |
| [tasks-template](references/tasks-template.md) | Task list format, ordering rules, coverage table |
| [progress-log-template](references/progress-log-template.md) | Session log for multi-session work and resume procedure |
| [delta-specs](references/delta-specs.md) | Writing ADDED, MODIFIED, REMOVED changes against existing specs |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| The idea is still vague, no approved spec yet | `brainstorming` |
| Starting from a ticket and going through to a PR | `ticket-delivery` |
| Implementing a task | `tdd` |
| Claiming a task or the whole change is done | `verification-before-completion` |
| Gate check before implementation, or a mid-flight change | `plan-auditor` agent |
| Several independent `[P]` tasks | `dispatching-parallel-agents` |
| A design decision needs an ADR | `architect` role |

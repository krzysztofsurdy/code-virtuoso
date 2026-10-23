# Slicing work into tasks

How to cut a plan into slices that a fresh session can finish, demo and merge on its own. Use it in Step 4 when you write the task list, and in the ticket writer when you split a story.

## Contents

- [Prefer vertical slices](#prefer-vertical-slices)
- [What a good slice looks like](#what-a-good-slice-looks-like)
- [Declare blocking edges](#declare-blocking-edges)
- [Size to one context window](#size-to-one-context-window)
- [Wide mechanical refactors](#wide-mechanical-refactors)
- [Slicing checklist](#slicing-checklist)

## Prefer vertical slices

A horizontal slice finishes one layer for the whole feature: all the schema, then all the services, then all the endpoints, then the UI. Nothing works until the last layer lands, integration problems show up at the end, and no slice can be demoed.

A vertical slice, also called a tracer bullet, cuts a thin but complete path through every layer the feature touches: storage, logic, interface and test. The first slice is deliberately narrow (one field, one happy path) and proves the layers connect. Later slices widen it.

| | Horizontal | Vertical |
|---|---|---|
| First thing you can run | After the last layer | After the first slice |
| Integration risk found | Late | Early |
| Each slice demoable | No | Yes |
| Review unit | A layer, with no behavior to judge | A behavior, with its tests |
| Parallel work | Blocked on lower layers | Slices on separate paths run in parallel |

Example, "customers can export their invoices":

- Horizontal: T1 export table and repository, T2 export service, T3 export endpoint, T4 download button.
- Vertical: T1 export one invoice as CSV, from button to file. T2 export a date range. T3 add PDF format. T4 large exports run as a background job.

After T1 the feature exists and can be shown. Each later task adds one visible behavior.

Horizontal work is fine when a layer change has no behavior of its own and several slices need it. Keep that to a small foundation task at the top of the list, and keep it as small as the first slice allows.

## What a good slice looks like

| Property | Test |
|---|---|
| **Complete path** | It touches every layer needed for one behavior, not part of a layer. |
| **Demoable** | Someone can run it and see the behavior, or a test shows it, without the other slices. |
| **Independently mergeable** | The build and the full suite stay green with only this slice merged. Unfinished work sits behind a flag or is simply not reachable yet. |
| **Tied to a requirement** | It serves one requirement ID or a clear part of one. |
| **Checkable** | It names the test or command that proves it works. |

Cut by behavior, not by file: one rule, one state, one user path, one input type, one output format. When a slice needs the word "and" to describe it, look for a seam.

## Declare blocking edges

Every slice lists what must be done before it can start. Write it in the task, next to the ID:

```
- [ ] T004 [FR-2] Export a date range (blocked by: T002)
- [ ] T005 [FR-3] Add PDF format (blocked by: T002)
- [ ] T006 [FR-4] Run large exports in the background (blocked by: T004, T005)
```

Rules:

- A blocker is a real dependency: the slice needs code, data or an interface the other slice creates. Shared files alone are a merge risk, not a blocker.
- Prefer few edges. A slice with five blockers is usually cut in the wrong place.
- No cycles. If two slices block each other, merge them or extract the shared part into its own earlier slice.
- Slices with no blockers between them can run in parallel, if their files do not overlap. That is what `[P]` marks.
- The first unblocked, unchecked slice is the next task. A session picks it from the edges, not from memory.

## Size to one context window

A slice should fit in one fresh session: the agent reads the spec, the task and the files it touches, writes the test and the code, runs the check and commits, with room to spare. A slice that needs a compaction half way is too big, and the summary will drop details that matter.

Signs a slice is too big:

- Its file list does not fit on a few lines.
- The check needs several unrelated tests.
- The task description needs sub-steps.
- It has more than one behavior.

Split by the next seam: the next input type, the next state, the next requirement ID. Signs it is too small: it changes no behavior and no one could tell if it were missing. Fold it into a neighbor.

For context budget rules in the session itself, see the `context-engineering` skill.

## Wide mechanical refactors

Some changes cut across the whole codebase and add no behavior: renaming a widely used type, changing a function signature, moving to a new library, swapping an API. They do not fit vertical slices, because one change touches many unrelated paths. Carve them out of the feature list and plan them as their own sequence, so CI stays green at every step.

Use expand, migrate, contract:

| Phase | What happens | State after |
|---|---|---|
| **Expand** | Add the new form next to the old one. Both work. Nothing uses the new one yet. | Green, no caller changed |
| **Migrate in batches** | Move callers over in batches, by directory, module or owner. One batch per commit, each small enough to review. | Green after every batch, old and new coexist |
| **Contract** | When no caller uses the old form, remove it. | Green, only the new form remains |

Rules:

- Never combine phases in one commit. A change that adds the new form and removes the old one has no safe midpoint.
- Make each batch independent, so batches can be merged and reverted on their own.
- Add a check that finds the remaining old uses (a search, a lint rule, a deprecation warning), and use it as the exit test for the migrate phase.
- Do not mix feature slices into the sequence. Land the refactor first, or after, and keep the diff mechanical so reviewers can skim it.
- The migrate batches are good candidates for parallel agents when their files do not overlap.

In the task list, write the three phases as separate tasks, with the contract task blocked by every migrate batch.

## Slicing checklist

- [ ] The first slice is a thin path through every layer, and it runs
- [ ] Each slice delivers one behavior and can be demoed alone
- [ ] Each slice leaves the build and the suite green
- [ ] Every slice lists its blockers, with no cycles
- [ ] Each slice fits one fresh session
- [ ] Wide mechanical changes are pulled out and sequenced expand, migrate, contract
- [ ] Horizontal work is limited to a small foundation task

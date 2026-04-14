---
name: subagent-driven-development
description: Execute a multi-task implementation plan by dispatching one fresh subagent per task with isolated context, then applying a two-stage review (spec compliance and code quality) before advancing. Use when you have a written plan with 3+ tasks, when tasks would otherwise cause context bleed, when you need reproducible per-task output, or when review gates are non-negotiable. Covers per-task briefing templates, the two-stage review rubric, structured hand-off between dependent tasks, and anti-patterns like shared long-context drift and skipped reviews. Complements dispatching-parallel-agents (for fan-out work) and executing-plans. Triggers: 'execute this plan', 'work through these tasks', 'dispatch per task', 'one-task-at-a-time', 'review-gated implementation'.
user-invocable: false
allowed-tools: Read Grep Glob Bash
---

# Subagent-Driven Development

An orchestration pattern for executing multi-task implementation plans by dispatching one fresh subagent per task, reviewing each task through two gates (spec compliance, then code quality), and advancing only after both gates pass. The orchestrator stays lean -- it coordinates, briefs, reviews, and hands off. It never implements.

## Core Principles

| Principle | Meaning |
|---|---|
| **One fresh agent per task** | Each task gets a new subagent with curated context. No inherited conversation history, no accumulated drift. The agent sees only what the brief provides. |
| **Two-stage review** | Every task passes through spec compliance (does it match the brief?) and then code quality (is it correct, clean, and tested?). Both must pass before advancing. |
| **Structured hand-offs** | When task N produces artifacts that task N+1 needs, pass a compressed summary (diff, test manifest, notes) -- never raw conversation history. |
| **Orchestrator stays lean** | The orchestrator reads the plan, dispatches agents, reviews output, and decides next steps. It does not implement, debug, or accumulate working-memory bloat. |
| **Fail fast, fix forward** | When a review gate fails, return specific feedback to the subagent for a focused fix cycle. After two failed fix attempts, re-scope or escalate -- do not loop indefinitely. |

## When to Use

| Situation | Why this pattern fits |
|---|---|
| Written plan with 3+ sequential tasks | Each task benefits from isolated execution and a review checkpoint |
| Tasks that build on each other (feature branches, migrations) | Structured hand-offs prevent context corruption between steps |
| Long implementation sessions that risk context exhaustion | Fresh agents per task keep each execution window small and precise |
| Quality-sensitive work requiring audit trails | Two-stage review produces documented accept/reject decisions per task |
| Delegating to less capable models for mechanical work | Tight briefs and review gates compensate for reduced reasoning capacity |

## When NOT to Use

| Situation | Better alternative |
|---|---|
| Single task or trivial change | Direct execution -- the overhead of briefing and review is not justified |
| Fully independent tasks with no ordering dependency | `dispatching-parallel-agents` -- fan them out simultaneously |
| Exploratory or research work with unclear scope | Manual iteration -- you need to discover the shape before you can brief it |
| Tasks that require deep shared state across every step | Single long-running session with periodic checkpoints |
| Fewer than 3 tasks | Execute directly and self-review -- the ceremony exceeds the value |

## The Loop

Execute one task at a time through this seven-phase cycle. The orchestrator drives each phase.

### Phase 1: Brief the Subagent

Compose a task brief containing everything the subagent needs to execute independently. The brief is the subagent's entire world -- anything not in the brief does not exist for it.

Include:
- Task identifier and goal (one sentence)
- Input artifacts (file paths, interface signatures, test fixtures)
- Context from prior tasks (hand-off summary, not full history)
- Acceptance criteria (observable, testable conditions)
- Out-of-scope boundaries (what the agent must NOT touch)
- Failure handling instructions (what to do when stuck)

See [Task Brief Template](references/task-brief-template.md) for the full structure.

### Phase 2: Dispatch with Isolation

Launch the subagent with a fresh context window. Provide the brief as the initial prompt. If the platform supports worktree isolation, use it -- the subagent should not be able to corrupt the main working tree.

Key rules:
- Never paste the full plan into the subagent -- only the current task brief
- Never let the subagent inherit the orchestrator's conversation history
- Preload only the skills the subagent needs for this specific task

### Phase 3: Receive Artifacts

The subagent completes work and reports back with one of four statuses:

| Status | Orchestrator action |
|---|---|
| **Done** | Proceed to Stage 1 review |
| **Done with concerns** | Read concerns, assess whether they affect correctness or scope, then proceed to review |
| **Needs context** | Provide the missing information and re-dispatch (do NOT guess on the subagent's behalf) |
| **Blocked** | Assess the blocker -- provide context, re-scope the task, or escalate to a human |

### Phase 4: Stage 1 Review -- Spec Compliance

Verify that the output matches the brief's acceptance criteria. This is a mechanical check: does the artifact do what was asked?

Checklist:
- Every acceptance criterion from the brief is satisfied
- No out-of-scope changes were introduced
- Files modified match the expected scope
- Tests exist for the specified behavior
- No unrelated regressions in the test suite

If Stage 1 fails: return specific findings to the subagent with the failing criteria. The subagent fixes and resubmits. After two failed attempts, re-scope the task or escalate.

See [Review Rubric](references/review-rubric.md) for the full spec compliance checklist.

### Phase 5: Stage 2 Review -- Code Quality

Once spec compliance passes, evaluate the quality of the implementation. This is a judgment call: is the code correct, clean, and maintainable?

Checklist:
- Correctness beyond the spec (edge cases, error handling, concurrency)
- Code style and conventions match the project
- No code smells (duplication, long methods, feature envy)
- Security considerations addressed (input validation, injection prevention)
- Performance is reasonable (no N+1 queries, no unbounded allocations)
- Tests are meaningful (behavior-focused, not implementation-coupled)

If Stage 2 fails: return prioritized findings. Critical issues must be fixed. Suggestions can be deferred if the orchestrator judges them non-blocking.

See [Review Rubric](references/review-rubric.md) for the full quality checklist.

### Phase 6: Decide

The orchestrator makes one of three decisions:

| Decision | When | Action |
|---|---|---|
| **Accept** | Both review stages pass | Mark task complete, proceed to hand-off |
| **Return with feedback** | Review found fixable issues | Send specific feedback, subagent fixes and resubmits for re-review |
| **Abort** | Task is fundamentally mis-scoped or blocked | Stop, re-plan the task, or escalate to a human |

Never accept with known open issues. Never defer critical findings to "clean up later."

### Phase 7: Hand Off to Next Task

Prepare the hand-off summary for the next task's brief. Include only what the next subagent needs:

- What changed (files modified, interfaces added)
- What was tested (test names, coverage scope)
- Decisions made during implementation that affect downstream tasks
- Any deviations from the original plan

See [Handoff Patterns](references/handoff-patterns.md) for structured hand-off formats.

---

## Task Brief

A task brief is the contract between the orchestrator and the subagent. It must be self-contained -- the subagent should be able to execute the task using only the brief and the codebase, with no additional conversation.

Essential sections:
1. **Task ID and goal** -- what to accomplish in one sentence
2. **Inputs** -- file paths, interface contracts, test fixtures
3. **Context** -- relevant decisions from prior tasks (hand-off summary)
4. **Acceptance criteria** -- observable conditions that define "done"
5. **Out of scope** -- explicit boundaries on what NOT to change
6. **Failure handling** -- what to do when stuck (report back, do not guess)

See [Task Brief Template](references/task-brief-template.md) for the complete template with examples.

---

## Two-Stage Review Rubric

The two stages serve different purposes and must not be combined or skipped:

| Stage | Purpose | Character |
|---|---|---|
| **Stage 1: Spec Compliance** | Does the output match the brief? | Mechanical -- checkable against acceptance criteria |
| **Stage 2: Code Quality** | Is the implementation well-crafted? | Judgmental -- requires expertise and context |

Stage 1 must pass before Stage 2 begins. There is no value in reviewing code quality on an implementation that does not meet its specification.

See [Review Rubric](references/review-rubric.md) for the detailed rubric with severity levels.

---

## Handoff Patterns

When tasks have sequential dependencies, the orchestrator must pass structured state from task N to task N+1. The goal is minimal, precise context -- not a dump of everything that happened.

Three formats, chosen by dependency depth:

| Format | When to use | Contents |
|---|---|---|
| **Diff summary** | Light dependency (new file, new interface) | Changed files, added signatures, test names |
| **Decision log** | Design choices affect downstream tasks | Decisions made, alternatives rejected, rationale |
| **Full hand-off** | Deep dependency (task N+1 modifies what task N created) | Diff summary + decision log + architectural notes |

See [Handoff Patterns](references/handoff-patterns.md) for templates and examples.

---

## Anti-Patterns

| Anti-Pattern | Why it fails | Fix |
|---|---|---|
| **Shared long context** | Accumulated conversation history causes drift, hallucination, and contradictions | One fresh agent per task with curated brief |
| **Skipped review gates** | Errors compound across tasks, discovered late when fixing is expensive | Both stages are mandatory -- no exceptions |
| **"Looks fine" reviews** | Without a rubric, reviews are superficial and miss systematic issues | Use the structured rubric for both stages |
| **Oversized tasks** | Tasks too large for a single agent to hold in context, leading to partial or incorrect output | Split until each task fits comfortably in one execution window |
| **Pasting the full plan** | Subagent is overwhelmed with irrelevant context from other tasks | Provide only the current task brief and hand-off summary |
| **Infinite fix loops** | Subagent cannot resolve an issue after repeated attempts, wasting tokens and time | Cap at two fix attempts, then re-scope or escalate |
| **Skipping hand-offs** | Next subagent lacks critical context from the previous task, leading to inconsistencies | Always produce a hand-off summary, even when dependency seems light |
| **Orchestrator implements** | Orchestrator starts writing code instead of delegating, accumulating context bloat | The orchestrator coordinates. Subagents implement. No exceptions. |

See [Anti-Patterns](references/anti-patterns.md) for detailed analysis and recovery strategies.

---

## Quality Checklist

Before advancing from one task to the next:

- [ ] Task brief was self-contained (subagent did not ask for plan-level context)
- [ ] Subagent executed with fresh context (no inherited history)
- [ ] Stage 1 review confirmed all acceptance criteria are met
- [ ] Stage 2 review confirmed code quality standards are satisfied
- [ ] All critical and warning findings are resolved (not deferred)
- [ ] Tests pass -- both new tests and the full existing suite
- [ ] Hand-off summary is prepared for the next task
- [ ] No out-of-scope changes were introduced
- [ ] Orchestrator context remains lean (no implementation details accumulated)

---

## Critical Rules

1. **One agent, one task.** Never reuse a subagent across tasks. Fresh context prevents drift and ensures each task is evaluated on its own merits.

2. **Both review stages are mandatory.** Spec compliance and code quality serve different purposes. Skipping either one allows a different class of defect to pass through.

3. **Stage 1 before Stage 2.** Do not review code quality on an implementation that does not meet its specification. Fix the spec gap first.

4. **Brief is the contract.** If it is not in the brief, the subagent is not responsible for it. Write complete briefs.

5. **Cap fix attempts at two.** If the subagent cannot resolve an issue after two rounds of feedback, the task scope is wrong or the agent lacks capability. Re-scope or escalate.

6. **Orchestrator never implements.** The moment the orchestrator starts writing code, it accumulates context that degrades its coordination ability. Delegate everything.

7. **Hand-off summaries, not history dumps.** Pass compressed, structured state between tasks. The next subagent needs decisions and artifacts, not a transcript of what happened.

8. **Fail fast on blockers.** When a subagent reports blocked status, address it immediately. Do not queue it for later or hope the next task will unblock it.

9. **Scope discipline.** Each task should be completable in a single agent session. If it requires multiple sessions, it is too large -- split it.

10. **Audit trail.** Record the accept/reject decision for each review stage on each task. This is your implementation log.

---

## Reference Files

| Reference | Contents |
|---|---|
| [Task Brief Template](references/task-brief-template.md) | Complete template for per-task subagent briefs with field descriptions and examples |
| [Review Rubric](references/review-rubric.md) | Two-stage review rubric with checklists, severity levels, and decision criteria |
| [Handoff Patterns](references/handoff-patterns.md) | Structured formats for passing state between dependent tasks |
| [Anti-Patterns](references/anti-patterns.md) | Detailed analysis of common failures with detection signals and recovery strategies |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Creating the plan this skill executes | `writing-plans` |
| Tasks are fully independent -- parallelize instead of sequencing | `dispatching-parallel-agents` |
| Stage 2 review technique and structured feedback | `requesting-code-review` |
| Verifying task output with evidence before accepting | `verification-before-completion` |
| Implementing a task using TDD inside the subagent | `testing` / `design-patterns` |
| Natural dispatch target for implementation tasks | `implementer` agent |
| Natural dispatch target for review tasks | `reviewer` agent |
| Completing the branch after all tasks pass | `finishing-branch` |

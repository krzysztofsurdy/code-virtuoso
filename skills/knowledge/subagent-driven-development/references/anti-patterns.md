# Anti-Patterns

Common failure modes when executing plans with subagents. Each anti-pattern includes detection signals, why it causes problems, and how to recover.

## 1. Shared Long Context

**What it looks like:** The orchestrator reuses a single agent across multiple tasks, or pastes the full conversation history into each new subagent's brief.

**Detection signals:**
- Subagent references details from a previous task that were not in its brief
- Subagent output quality degrades as task number increases
- Subagent confuses requirements from different tasks
- Agent starts hallucinating file paths or interfaces that existed in a prior task but were refactored

**Why it fails:** Context windows are finite and attention degrades with length. As accumulated history grows, the agent prioritizes recent tokens over earlier ones. Requirements from task 1 get lost by task 5. Worse, stale context from completed tasks can contradict the current state of the code, leading to implementations that reference deleted files or obsolete interfaces.

**Recovery:**
1. Dispatch a fresh agent for the current task
2. Prepare a proper task brief with only the relevant context
3. Use structured handoff summaries instead of history dumps
4. If the fresh agent needs context from a much earlier task, provide it as an explicit handoff reference - not as conversation replay

---

## 2. Skipped Review Gates

**What it looks like:** The orchestrator advances to the next task without running one or both review stages. Common rationalizations: "this change is small," "I can see it is correct," "we are behind schedule."

**Detection signals:**
- Tasks marked complete without review documentation
- Bugs discovered in later tasks that originate from earlier unchecked work
- No accept/reject decisions recorded in the implementation log
- Orchestrator says "looks good" without referencing specific acceptance criteria

**Why it fails:** Small errors compound. A missed edge case in task 2 becomes a data corruption bug discovered in task 7, when the cost of fixing it is 10x higher. Review gates exist precisely for the "obviously correct" changes - those are where assumptions go unchecked.

**Recovery:**
1. Stop forward progress
2. Go back to the unreviewed task output
3. Run both review stages retroactively
4. If issues are found, fix them before continuing - do not add them to a "tech debt" list
5. Re-run dependent tasks if the fix changes interfaces or behavior they rely on

---

## 3. "Looks Fine" Reviews

**What it looks like:** The review consists of a quick glance and a verdict of "looks good" without systematically checking the rubric.

**Detection signals:**
- Review output is under 5 lines
- No specific file paths or line numbers referenced
- No acceptance criteria mapped to evidence
- Review time is under 30 seconds for non-trivial changes
- Review says "all criteria met" without listing which criteria

**Why it fails:** Without a rubric, reviews rely on the reviewer's attention span and mood. Systematic issues are missed because the reviewer is not looking for them. The review becomes a rubber stamp that provides false confidence.

**Recovery:**
1. Re-run the review using the full rubric from the review reference
2. For Stage 1: map every acceptance criterion to specific evidence (file path, test name, or observable behavior)
3. For Stage 2: check every item in the quality checklist - correctness, design, security, performance, test quality
4. Document findings in the standard output format
5. If the original "looks fine" review allowed issues through, treat them as findings in the current re-review

---

## 4. Oversized Tasks

**What it looks like:** A single task requires modifying 10+ files, has 15 acceptance criteria, or cannot be described in a one-sentence goal.

**Detection signals:**
- Subagent asks multiple clarifying questions before starting
- Subagent produces partial output and reports it was unable to complete everything
- Review takes longer than the implementation
- The task brief exceeds 50 lines
- The goal sentence contains "and" connecting two distinct behaviors

**Why it fails:** Large tasks exceed what a single agent can hold in working memory. The agent loses track of earlier acceptance criteria while working on later ones. Quality drops because the agent is context-fatigued by the time it reaches the last items. Reviews become superficial because the reviewer is overwhelmed by the volume of changes.

**Recovery:**
1. Split the oversized task into smaller tasks, each with a single clear goal
2. Use the sizing guidance from the task brief template:
   - One goal per task (if the goal has "and," split it)
   - Under 5 files modified per task
   - Under 8 acceptance criteria per task
3. Establish dependencies between the new sub-tasks
4. Create handoff summaries between them
5. Re-dispatch starting from the first sub-task

---

## 5. Pasting the Full Plan

**What it looks like:** The orchestrator copies the entire implementation plan into the subagent's context, rather than extracting only the current task's brief.

**Detection signals:**
- Subagent starts working on a task other than the assigned one
- Subagent references future tasks or past tasks not relevant to its work
- Subagent attempts to "optimize" by doing multiple tasks at once
- Agent context usage is disproportionately high relative to task complexity

**Why it fails:** The plan contains 10-20 tasks. The subagent has no way to know which one it should focus on without explicit direction, and the irrelevant tasks consume context window that the agent needs for implementation. Worse, the agent may attempt to "help" by addressing concerns from future tasks, violating scope boundaries.

**Recovery:**
1. Prepare an isolated task brief containing only the current task
2. Include handoff context from the previous task, not the plan
3. Re-dispatch the subagent with the focused brief
4. If the subagent has already started, discard its work and start fresh - partial work from a confused agent is more dangerous than starting over

---

## 6. Infinite Fix Loops

**What it looks like:** The subagent fails a review, fixes the issue, fails again on the same or a new issue, fixes again, and the cycle continues past two iterations.

**Detection signals:**
- Same issue appears in consecutive review rounds
- New issues appear in each fix round (fixing one thing breaks another)
- Subagent's fixes become increasingly desperate or random
- Total fix cycles exceed two for a single review stage

**Why it fails:** If the subagent cannot resolve an issue after two focused attempts with specific feedback, one of three things is true: (1) the task is mis-scoped and the agent lacks the context or capability to complete it, (2) the issue is more complex than the task anticipated, or (3) the feedback is ambiguous. Continuing to loop wastes tokens and time without converging on a solution.

**Recovery:**
1. Stop the loop after the second fix attempt fails
2. Diagnose the root cause:
   - Is the feedback specific enough? (Vague feedback produces vague fixes)
   - Is the task within the agent's capability? (Re-dispatch with a more capable model)
   - Is the task properly scoped? (Split into smaller pieces)
   - Is there a design issue the agent cannot see? (Escalate to a human or architect)
3. Choose: re-scope the task, escalate, or re-dispatch with better context
4. Do NOT simply tell the agent to "try again" without changing something

---

## 7. Skipping Handoffs

**What it looks like:** The orchestrator moves to the next task without preparing a handoff summary, assuming the next subagent will "figure it out" from the codebase.

**Detection signals:**
- Next subagent asks what the previous task changed
- Next subagent implements something that conflicts with a decision from the prior task
- Next subagent duplicates work the prior task already completed
- The brief's "Context from Prior Tasks" is empty for a non-first task

**Why it fails:** The fresh subagent has zero knowledge of what happened before. Without a handoff, it must rediscover context from the codebase - which is slow, error-prone, and may miss decisions that are not reflected in code (e.g., "we chose approach A over approach B because..."). Inconsistencies between tasks go undetected until integration.

**Recovery:**
1. Pause before dispatching the next task
2. Write the handoff summary for the completed task (diff summary, decision log, or full handoff depending on dependency depth)
3. Include the handoff in the next task's brief
4. If the next task has already been dispatched without a handoff, evaluate its output carefully for inconsistencies with the prior task

---

## 8. Orchestrator Implements

**What it looks like:** The orchestrator, instead of dispatching a subagent, starts writing code directly. Often begins with "let me just quickly fix this" or "this is a one-line change."

**Detection signals:**
- Orchestrator's context grows with implementation details
- Orchestrator starts referencing specific lines of code or variable names
- Orchestrator loses track of the overall plan progress
- Later task dispatches receive degraded briefs because the orchestrator's context is bloated

**Why it fails:** The orchestrator's value is coordination: reading the plan, composing briefs, reviewing output, and deciding next steps. Every line of code the orchestrator writes consumes context that could be used for coordination. Once the orchestrator accumulates implementation details, it becomes less effective at all of its primary tasks. Additionally, self-implemented changes bypass the review gates.

**Recovery:**
1. Stop implementing immediately
2. Take whatever was started and convert it into a task brief
3. Dispatch a subagent to complete the work properly
4. Run both review stages on the output
5. If the orchestrator has already accumulated significant implementation context, consider summarizing the current state and continuing in a fresh orchestrator session

---

## Pattern Summary

| # | Anti-Pattern | Core Failure | Prevention |
|---|---|---|---|
| 1 | Shared long context | Drift, hallucination, contradictions | Fresh agent per task |
| 2 | Skipped review gates | Errors compound undetected | Both stages mandatory |
| 3 | "Looks fine" reviews | Systematic issues missed | Use structured rubric |
| 4 | Oversized tasks | Context exhaustion, partial output | Split until single-session |
| 5 | Pasting the full plan | Scope confusion, wasted context | Brief contains current task only |
| 6 | Infinite fix loops | Wasted tokens, no convergence | Cap at two, then re-scope |
| 7 | Skipping handoffs | Inconsistencies between tasks | Always prepare handoff summary |
| 8 | Orchestrator implements | Context bloat, bypassed reviews | Orchestrator coordinates only |

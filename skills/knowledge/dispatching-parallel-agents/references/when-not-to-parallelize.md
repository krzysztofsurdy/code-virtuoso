# When Not to Parallelize

Parallel dispatch is a tool, not a default. Many tasks are faster and simpler when run sequentially. This reference covers when sequential execution wins and how to decide.

---

## Contents

- [The dispatch overhead](#the-dispatch-overhead)
- [Sequential is better when...](#sequential-is-better-when)
- [Decision tree](#decision-tree)
- [Cost-benefit analysis](#cost-benefit-analysis)
- [Hybrid approaches](#hybrid-approaches)

## The dispatch overhead

Every parallel dispatch has fixed costs that sequential execution avoids:

| Cost | Description |
|---|---|
| **Briefing** | Writing precise, self-contained briefs for each agent |
| **Context transfer** | Extracting and packaging relevant information for each brief |
| **Launch** | Spinning up subagent sessions with clean context |
| **Synthesis** | Reviewing, deduplicating, and merging N outputs |
| **Conflict resolution** | Handling merge conflicts, contradictions, or failed agents |
| **Verification** | Testing the merged result for coherence and correctness |

For these costs to be justified, the parallel execution must save more time than the overhead consumes. The break-even point depends on task complexity, but as a rule of thumb, if each task would take less than a few minutes sequentially, the dispatch overhead likely exceeds the time saved.

---

## Sequential is better when...

### 1. tasks have pipeline dependencies

If Task B needs Task A's output as input, they must run sequentially. Making Agent B guess what Agent A will produce creates waste and rework.

**Test**: "Can Agent B write its final output right now, without waiting for Agent A?" If no, sequence them.

**Common pipeline dependencies**:
- Investigation before implementation (need to understand before building)
- Design before coding (need API contracts before writing endpoints)
- Implementation before review (need code before reviewing it)
- Migration planning before migration execution

### 2. the problem is not yet understood

Parallelization requires knowing what the independent units are. If the problem space has not been explored, you cannot decompose it reliably. Dispatching investigators to "figure out what is going on" in 5 different places when the problem might be in one place wastes 4 agents.

**Test**: "Can I draw a complete dependency map of the subtasks?" If no, investigate first.

**Better approach**: Dispatch a single investigator (or 2-3 for clearly independent subsystems). Use the investigation results to plan the parallel dispatch.

### 3. tasks modify overlapping files

When two agents need to modify the same file, parallelization creates merge conflicts. Even with worktree isolation, the merge step reintroduces the coordination you were trying to avoid.

**Test**: "Can I assign exclusive file ownership to each agent with zero overlap?" If no, sequence the overlapping parts.

**Exceptions**: If the overlap is trivial (e.g., both agents add an import line), the merge is trivial and parallelization may still be worth it. This is the exception.

### 4. the orchestrator needs to learn

Sometimes the orchestrator itself needs to build understanding through the process. Dispatching agents outsources the learning. That works when the learning is parallelizable and fails when insights from one area change how you approach another.

**Test**: "Will understanding Area A change how I investigate Area B?" If yes, investigate sequentially.

**Example**: Debugging an intermittent failure. The first investigation may reveal that the problem is in the database layer, which changes what the second investigation should look at. Parallel dispatch would have the second agent investigating the wrong layer.

### 5. there are fewer than three independent units

Dispatch overhead includes briefing, launching, and synthesizing. For two tasks, the overhead may exceed the parallelization benefit. One agent doing two small tasks sequentially is often faster than two agents with the briefing and synthesis overhead.

**Test**: Count the independent units. If fewer than 3, do them sequentially.

**Exception**: If each task is individually long-running (heavy analysis, large codebase search), even 2 parallel agents save real time.

### 6. results must be strictly ordered

If the final deliverable requires items in a specific order that depends on the content (not just a sort key), sequential execution produces ordered output as a side effect. Parallel execution needs a post-processing ordering step, which may need information that only the sequential context has.

**Test**: "Can I sort the merged results by a simple key (severity, file path, timestamp)?" If yes, parallel is fine: sort after merge. If the ordering requires judgment or narrative flow, sequential is better.

### 7. the task requires conversational refinement

Some tasks benefit from iterative refinement where each step builds on feedback from the previous step. This is inherently sequential: the feedback loop is a pipeline dependency.

**Examples**:
- Writing that needs revision cycles
- Design exploration where each iteration narrows the options
- Debugging where each finding changes the investigation direction

---

## Decision tree

```
Is the task decomposable into subtasks?
  No  -> Do it yourself (single agent)
  Yes -> Are there 3+ independent subtasks?
           No  -> Sequential execution
           Yes -> Is the problem well understood?
                    No  -> Investigate first, then re-evaluate
                    Yes -> Do any subtasks share mutable state?
                             Yes -> Sequence the sharing parts
                             No  -> Will dispatch overhead exceed time saved?
                                      Yes -> Sequential execution
                                      No  -> Parallel dispatch
```

---

## Cost-benefit analysis

Before dispatching, estimate these quantities:

| Factor | Sequential cost | Parallel cost |
|---|---|---|
| **Execution time** | Sum of all task durations | Duration of longest task |
| **Briefing time** | None (context is already in your session) | N briefs to write |
| **Synthesis time** | None (results accumulate as you go) | Active merge and deduplication |
| **Failure recovery** | Retry the failed step | Retry the failed agent + re-synthesize |
| **Context usage** | One session, full context | N sessions with distributed context |
| **Risk of rework** | Low (sequential work catches issues early) | Higher (decomposition errors, merge conflicts) |

**Parallelize when**: Execution time savings clearly exceed (briefing + synthesis + failure recovery) overhead.

**Stay sequential when**: Tasks are short, interdependent, or require progressive understanding.

---

## Hybrid approaches

Work is rarely fully parallel or fully sequential. Often the right answer is a mix.

### Sequential then parallel

Investigate sequentially until the problem is understood, then fan out to parallel implementation.

```
Sequential: Investigator -> Architect -> Plan
Parallel:   [Implementer A, Implementer B, Implementer C]
Sequential: Reviewer -> Merge -> Final verification
```

### Parallel with sequential gates

Parallel execution within stages, sequential gates between stages.

```
Parallel Stage 1: [Investigator A, Investigator B]
Gate: Orchestrator reviews and plans
Parallel Stage 2: [Implementer A, Implementer B]
Gate: Orchestrator reviews and merges
Sequential: Final review and integration testing
```

### Mostly sequential with one parallel step

When only one phase of the work benefits from parallelization:

```
Sequential: Investigation -> Design -> Review
Parallel:   [Implementation backend, Implementation frontend]
Sequential: Integration testing -> Deployment
```

Parallelize where it saves time and stay sequential where it keeps the work coherent. Not every task needs an orchestration plan.

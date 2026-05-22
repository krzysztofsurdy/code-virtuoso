# When Not to Parallelize

Parallel dispatch is a tool, not a default. Many tasks are faster, simpler, and more reliable when executed sequentially. This reference covers the situations where sequential execution wins and how to make the decision.

---

## The Dispatch Overhead

Every parallel dispatch has fixed costs that sequential execution avoids:

| Cost | Description |
|---|---|
| **Briefing** | Writing precise, self-contained briefs for each agent |
| **Context transfer** | Extracting and packaging relevant information for each brief |
| **Launch** | Spinning up subagent sessions with clean context |
| **Synthesis** | Reviewing, deduplicating, and merging N outputs |
| **Conflict resolution** | Handling merge conflicts, contradictions, or failed agents |
| **Verification** | Testing the merged result for coherence and correctness |

For these costs to be justified, the parallel execution must save more time than the overhead consumes. The break-even point depends on task complexity, but a general rule: if the tasks would take less than a few minutes each sequentially, the dispatch overhead likely exceeds the time saved.

---

## Sequential Is Better When...

### 1. Tasks Have Pipeline Dependencies

If Task B needs Task A's output as input, they must run sequentially regardless of how much you want to parallelize. Forcing independence by having Agent B guess what Agent A will produce creates waste and rework.

**Test**: "Can Agent B write its final output right now, without waiting for Agent A?" If no, sequence them.

**Common pipeline dependencies**:
- Investigation before implementation (need to understand before building)
- Design before coding (need API contracts before writing endpoints)
- Implementation before review (need code before reviewing it)
- Migration planning before migration execution

### 2. The Problem Is Not Yet Understood

Parallelization requires knowing what the independent units are. If the problem space has not been explored, you cannot decompose it reliably. Dispatching investigators to "figure out what is going on" in 5 different places when the problem might be in one place wastes 4 agents.

**Test**: "Can I draw a complete dependency map of the subtasks?" If no, investigate first.

**Better approach**: Dispatch a single investigator (or 2-3 for clearly independent subsystems). Use the investigation results to plan the parallel dispatch.

### 3. Tasks Modify Overlapping Files

When two agents need to modify the same file, parallelization creates merge conflicts. Even with worktree isolation, the merge step reintroduces the coordination you were trying to avoid.

**Test**: "Can I assign exclusive file ownership to each agent with zero overlap?" If no, sequence the overlapping parts.

**Exceptions**: If the overlap is trivial (e.g., both agents add an import line), the merge is trivial and parallelization may still be worth it. But this is the exception, not the rule.

### 4. The Orchestrator Needs to Learn

Sometimes the orchestrator itself needs to build understanding through the process. Dispatching agents means outsourcing the learning, which works when the learning is parallelizable, but fails when insights from one area inform how you approach another.

**Test**: "Will understanding Area A change how I investigate Area B?" If yes, investigate sequentially.

**Example**: Debugging an intermittent failure. The first investigation may reveal that the problem is in the database layer, which completely changes what the second investigation should look at. Parallel dispatch would have the second agent investigating the wrong layer.

### 5. There Are Fewer Than Three Independent Units

Dispatch overhead includes briefing, launching, and synthesizing. For two tasks, the overhead may exceed the parallelization benefit. One agent doing two small tasks sequentially is often faster than two agents with the briefing and synthesis overhead.

**Test**: Count the truly independent units. If fewer than 3, do them sequentially.

**Exception**: If each task is individually long-running (heavy analysis, large codebase search), even 2 parallel agents save meaningful time.

### 6. Results Must Be Strictly Ordered

If the final deliverable requires items in a specific order that depends on the content (not just a sort key), sequential execution naturally produces ordered output. Parallel execution requires a post-processing ordering step that may need information only the sequential context provides.

**Test**: "Can I sort the merged results by a simple key (severity, file path, timestamp)?" If yes, parallel is fine - sort after merge. If the ordering requires judgment or narrative flow, sequential is better.

### 7. The Task Requires Conversational Refinement

Some tasks benefit from iterative refinement where each step builds on feedback from the previous step. This is inherently sequential - the "feedback loop" is a pipeline dependency.

**Examples**:
- Writing that needs revision cycles
- Design exploration where each iteration narrows the options
- Debugging where each finding changes the investigation direction

---

## Decision Tree

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

## Cost-Benefit Analysis

Before dispatching, estimate these quantities:

| Factor | Sequential Cost | Parallel Cost |
|---|---|---|
| **Execution time** | Sum of all task durations | Duration of longest task |
| **Briefing time** | None (context is already in your session) | N briefs to write |
| **Synthesis time** | None (results accumulate naturally) | Active merge and deduplication |
| **Failure recovery** | Retry the failed step | Retry the failed agent + re-synthesize |
| **Context usage** | One session, full context | N sessions with distributed context |
| **Risk of rework** | Low (sequential naturally catches issues) | Higher (decomposition errors, merge conflicts) |

**Parallelize when**: Execution time savings significantly exceed (briefing + synthesis + failure recovery) overhead.

**Stay sequential when**: Tasks are short, interdependent, or require progressive understanding.

---

## Hybrid Approaches

Not everything is fully parallel or fully sequential. Often the right answer is a mix:

### Sequential Then Parallel

Investigate sequentially until the problem is understood, then fan out to parallel implementation.

```
Sequential: Investigator -> Architect -> Plan
Parallel:   [Implementer A, Implementer B, Implementer C]
Sequential: Reviewer -> Merge -> Final verification
```

### Parallel With Sequential Gates

Parallel execution within stages, sequential gates between stages.

```
Parallel Stage 1: [Investigator A, Investigator B]
Gate: Orchestrator reviews and plans
Parallel Stage 2: [Implementer A, Implementer B]
Gate: Orchestrator reviews and merges
Sequential: Final review and integration testing
```

### Mostly Sequential With One Parallel Step

When only one phase of the work benefits from parallelization:

```
Sequential: Investigation -> Design -> Review
Parallel:   [Implementation backend, Implementation frontend]
Sequential: Integration testing -> Deployment
```

The goal is to parallelize where it saves time and stay sequential where it provides coherence. Not every task needs a grand orchestration plan.

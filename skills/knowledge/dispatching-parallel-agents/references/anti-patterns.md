# Anti-patterns

Common mistakes when dispatching parallel subagents. Each entry lists detection signals, consequences, and a concrete fix.

---

## Contents

- [Dependency masquerading as independence](#dependency-masquerading-as-independence)
- [Overlapping writes](#overlapping-writes)
- [Context bleed](#context-bleed)
- [Ambiguous brief](#ambiguous-brief)
- [Agent sprawl](#agent-sprawl)
- [Duplicate research](#duplicate-research)
- [No failure budget](#no-failure-budget)
- [Premature parallelization](#premature-parallelization)
- [Orchestrator as bottleneck](#orchestrator-as-bottleneck)
- [Prevention summary](#prevention-summary)

## Dependency masquerading as independence

### Description

Two tasks are dispatched in parallel, but one cannot complete without the other's output. The dependency is not obvious from the task descriptions alone.

### Detection signals

- Agent B's brief contains phrases like "based on the results of..." or "after understanding..."
- Agent A's expected output is the same type as Agent B's required input
- During execution, Agent B produces speculative or generic results because it lacked information only Agent A could provide
- After synthesis, Agent B's output needs to be redone in light of Agent A's findings

### Consequences

- Agent B's work is partly or wholly wasted
- The orchestrator spends extra time on a follow-up round
- Total elapsed time is longer than sequential execution would have been

### Fix

Draw the dependency graph before dispatching. For each pair of tasks, ask: "Can Task B produce a final, correct result without knowing Task A's output?" If no, sequence them. If only a small part of Task B depends on Task A, split Task B into an independent part (parallelize) and a dependent part (sequence after A).

---

## Overlapping writes

### Description

Two or more agents modify the same files or create files in the same directory, leading to merge conflicts or overwritten work.

### Detection signals

- Merge conflicts when integrating agent branches
- Agent briefs reference the same file paths in their "files to modify" sections
- Two agents both need to add entries to a shared configuration file
- An agent's changes disappear after merging another agent's branch

### Consequences

- Merge conflicts require manual resolution, often by someone who did not write either change
- One agent's work may be silently overwritten
- The merged result may contain logical inconsistencies even if the merge is conflict-free (e.g., two agents add the same dependency with different versions)

### Fix

Enforce exclusive file ownership. Each agent's brief must list the exact files it may modify, and no two briefs share files. If two agents must modify the same file, either:
1. Sequence them (Agent B works on Agent A's branch)
2. Merge them into one agent
3. Restructure the work so the shared file is modified by a dedicated follow-up agent

---

## Context bleed

### Description

A subagent receives context from the orchestrator's session that is irrelevant to its task. This includes conversation history, other agents' briefs, project background unrelated to the task, or the orchestrator's reasoning about why this agent was chosen.

### Detection signals

- Agent references information not in its brief
- Agent addresses concerns from the broader project context rather than its specific task
- Agent output includes disclaimers or caveats about areas outside its scope (indicating it saw those areas in the context)
- Agent produces verbose output that rehashes background information

### Consequences

- Tokens wasted on irrelevant context
- Reduced focus on the actual task
- Risk of the agent pursuing tangential investigations prompted by irrelevant context
- Unpredictable behavior that varies based on what the orchestrator was discussing before dispatch

### Fix

Write self-contained briefs. Extract only the facts relevant to this specific task. Do not pass conversation objects, session state, or "everything so far" context. Test your brief by asking: "Would this brief make sense to someone who knows nothing about this project except what is written here?"

---

## Ambiguous brief

### Description

The brief does not clearly define the task, scope, or expected output. The agent must interpret the orchestrator's intent, and its interpretation may differ from what was intended.

### Detection signals

- Agent asks clarifying questions (if the runtime supports it) or makes assumptions
- Agent's output does not match what the orchestrator expected
- Agent scope-creeps into adjacent areas because boundaries were not defined
- Two agents with similar briefs produce wildly different types of output

### Consequences

- Output requires significant rework
- The orchestrator spends more time on synthesis than the agents saved on parallel execution
- If the output is subtly wrong (agent interpreted scope differently), the error may propagate

### Fix

Every brief must have: a one-sentence task, explicit boundaries (in-scope and out-of-scope), a defined output format, and a failure mode. Before dispatching, mentally simulate receiving this brief as the agent. Would you know exactly what to do? If not, the brief needs revision.

---

## Agent sprawl

### Description

The orchestrator dispatches too many agents for the task at hand. Each agent has a narrow scope, but the overhead of briefing, dispatching, and synthesizing exceeds the benefit of parallelism.

### Detection signals

- More than 7 agents dispatched for a single task
- Some agents finish almost instantly because their scope is trivially small
- Synthesis takes longer than any individual agent's execution
- Several agents produce near-identical outputs because their scopes overlap
- The dispatch round has agents that each examine fewer than 5 files

### Consequences

- Dispatch and synthesis overhead dominates total time
- More briefs to write, more outputs to review, more potential for errors
- Context budget spent on coordination instead of work
- Diminishing returns on parallelism (Amdahl's law applied to agent orchestration)

### Fix

Start with 3-5 agents. Combine related tasks into fewer, broader agents. Ask "what is the natural grouping that keeps agents focused with the least coordination overhead?", not "what is the smallest unit I can dispatch?". A good heuristic: if two tasks would require the agent to read many of the same files, they belong in the same dispatch unit.

---

## Duplicate research

### Description

Two or more agents investigate the same files, trace the same code paths, or research the same topics because their scopes were not clearly separated.

### Detection signals

- Multiple agents report findings from the same files or line numbers
- Agent outputs contain identical or near-identical observations
- During synthesis, more time is spent deduplicating than adding new insights
- Agents list the same files in their "files examined" sections

### Consequences

- Wasted agent capacity (two agents doing the same work)
- Synthesis complexity increases with duplicate findings
- Risk of conflicting assessments of the same code from agents using different criteria

### Fix

Define scopes by non-overlapping file sets, directories, or modules, not by concern. If you want two perspectives on the same code (security + performance), use scatter-gather explicitly and plan for deduplication. If you want breadth, assign non-overlapping territories. When in doubt, check: "Will these two agents read any of the same files?" If yes, either separate by file set or merge into one agent.

---

## No failure budget

### Description

The dispatch plan assumes all agents will succeed. There is no plan for what happens when an agent fails, returns incomplete results, or produces unusable output.

### Detection signals

- No failure mode in any agent brief
- The synthesis plan requires all N agent outputs to produce a complete result
- A single agent failure causes the orchestrator to start over
- The orchestrator has no criteria for "acceptable partial result"

### Consequences

- One failure cascades into re-dispatching the entire batch
- Total time exceeds what sequential execution would have taken
- The orchestrator lacks decision criteria when faced with partial results

### Fix

Include a failure mode in every brief. Define "acceptable degradation" before dispatching: what does a good-enough result look like with one agent missing? Budget for one failure in every dispatch round. If the task absolutely requires all agents to succeed, the task may not be suitable for parallel dispatch - use sequential execution with checkpoints instead.

---

## Premature parallelization

### Description

The orchestrator parallelizes work before understanding the problem space. This leads to agents working on the wrong tasks, investigating the wrong areas, or implementing the wrong design.

### Detection signals

- Agents return results that reveal the decomposition was wrong
- Synthesis produces contradictions that indicate the problem was not well understood
- Multiple agents are re-dispatched with revised briefs after the first round
- The orchestrator could not write a clear dependency map before dispatching

### Consequences

- First round of agents is wasted
- Total time is longer than if the orchestrator had investigated first and parallelized second
- Agent outputs may be actively misleading if based on incorrect assumptions

### Fix

Follow the pattern: investigate first, parallelize second. The first dispatch should usually be a single investigator (or a small fan-out of investigators for clearly independent areas). Only after the investigation returns findings should the orchestrator decompose implementation or detailed analysis work into parallel units.

---

## Orchestrator as bottleneck

### Description

The orchestrator spends so much time writing briefs, managing dispatch, and synthesizing results that it becomes the limiting factor. The agents wait while the orchestrator coordinates.

### Detection signals

- Briefing time exceeds expected agent execution time
- Synthesis takes longer than the longest agent task
- The orchestrator rewrites briefs multiple times before dispatching
- Multiple dispatch rounds where each round has only 1-2 agents

### Consequences

- Parallelism benefits are negated by serial orchestration overhead
- The orchestrator's context fills with coordination state rather than problem-solving
- Simple tasks get complex workflows that slow everything down

### Fix

If briefing takes too long, the decomposition is too fine-grained. Combine units. If synthesis takes too long, the output format was not standardized. If you spend more time orchestrating than working, step back and ask whether parallel dispatch is the right approach for this task. Sometimes one well-focused agent (or doing the work yourself) is faster than coordinating three.

---

## Prevention summary

| Anti-pattern | Prevention technique |
|---|---|
| Dependency masquerading as independence | Draw dependency graph before dispatching |
| Overlapping writes | Assign exclusive file ownership per agent |
| Context bleed | Write self-contained briefs; test with "fresh eyes" check |
| Ambiguous brief | Use the standard brief template; simulate receiving the brief |
| Agent sprawl | Start with 3-5 agents; combine related scopes |
| Duplicate research | Define non-overlapping territories by file set or directory |
| No failure budget | Include failure mode in every brief; define acceptable degradation |
| Premature parallelization | Investigate first, parallelize known work second |
| Orchestrator as bottleneck | If orchestration time exceeds agent time, reduce dispatch granularity |

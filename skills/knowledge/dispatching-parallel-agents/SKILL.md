---
name: dispatching-parallel-agents
description: Patterns for effective subagent delegation and parallel execution. Use when a task decomposes into independent subtasks, when research spans multiple areas, when building features that require coordinated specialist work, or when sequential execution is wasting time. Covers work decomposition patterns (fan-out/fan-in, map-reduce, pipelines, scatter-gather), precise subagent briefing, context and filesystem isolation, result synthesis, failure handling, and anti-patterns like agent sprawl and context bleed. Platform-agnostic but integrates with this project's agent roster (investigator, implementer, reviewer, refactor-scout, etc.). Triggers: 'delegate', 'parallelize', 'fan out', 'multi-agent', 'subagent', 'split this work'.
user-invocable: false
allowed-tools: Read Grep Glob Bash
---

# Dispatching Parallel Agents

Effective orchestration means knowing when to do work yourself and when to delegate it to focused subagents working in parallel. The core insight is simple: independent work should happen concurrently, not sequentially. But "independent" is the load-bearing word -- getting decomposition wrong turns parallel execution into a coordination nightmare.

## Core Principles

| Principle | Meaning |
|---|---|
| **Independence over coordination** | If two tasks share state, they are one task. Only dispatch work that can complete without cross-agent communication. |
| **Precision over hope** | A subagent brief must be specific enough that the agent cannot misinterpret its scope. Vague briefs produce vague results. |
| **Isolation over sharing** | Each subagent starts with a clean context. It receives exactly what it needs -- nothing inherited, nothing ambient. |
| **Synthesis over concatenation** | The orchestrator's job is not to paste outputs together. It is to resolve conflicts, deduplicate, and produce a coherent whole. |
| **Fail fast over fail silent** | Every dispatch includes a failure mode. Subagents report blockers immediately rather than guessing past them. |

---

## When to Parallelize

| Signal | Example |
|---|---|
| Multiple independent areas of investigation | "How does auth work?" + "How does billing work?" -- no shared code path |
| Research spanning distinct topics | Investigating a framework upgrade requires checking breaking changes, dependency compatibility, and test coverage separately |
| Implementation across non-overlapping files | Backend API + frontend component + database migration touching different file sets |
| Review of independent subsystems | Running a reviewer on module A while running a refactor scout on module B |
| Repetitive tasks with different inputs | Auditing 5 services for security vulnerabilities -- same process, different targets |

## When NOT to Parallelize

| Signal | Why Sequential Is Better |
|---|---|
| Output of task A is input to task B | Pipeline dependency -- parallelize within stages, not across them |
| Tasks modify overlapping files | Merge conflicts are inevitable and expensive to resolve |
| Understanding requires full context | Splitting a single complex investigation loses the thread |
| The problem is not yet understood | Parallelize execution, not exploration of unknowns |
| Fewer than 3 independent units | Dispatch overhead exceeds time saved |
| Results must be strictly ordered | Sequential execution preserves natural ordering without post-processing |

---

## The Dispatch Cycle

### Phase 1: Identify Independent Work

Examine the task and list every subtask. For each pair, ask: "Can subtask A complete without knowing the result of subtask B?" If yes for all pairs in a group, that group is parallelizable.

**Actions**: Break the task into candidate subtasks. Draw dependency arrows between them. Groups with no inbound arrows from other groups are independent.

**Output**: A dependency map showing which subtasks are independent and which form pipelines.

### Phase 2: Decompose into Dispatch Units

Each dispatch unit is one subagent's complete assignment. A dispatch unit has a single objective, a bounded scope, and a defined output format. If a unit requires the agent to make judgment calls about scope, it is too vague.

**Actions**: For each independent group, define the dispatch unit. Choose the right decomposition pattern (see [Decomposition Patterns](references/decomposition-patterns.md)).

**Output**: A list of dispatch units, each with objective, scope boundary, and expected output.

### Phase 3: Brief Each Agent

Write a precise brief for each subagent. The brief is the contract between orchestrator and worker. See [Briefing Template](references/briefing-template.md) for the full format.

**Minimum brief contents**:
- Task objective (one sentence)
- Input data or file paths
- Expected output format
- Explicit out-of-scope boundaries
- Failure handling instructions

### Phase 4: Execute with Isolation

Launch subagents with clean context. Agents that modify files operate in isolated worktrees. Read-only agents can share the working tree safely.

**Actions**: Dispatch all units. Do not provide agents with your conversation history or context beyond their brief. See [Isolation and Merging](references/isolation-and-merging.md).

**Output**: Running subagents, each working independently.

### Phase 5: Synthesize Results

When all agents return, the orchestrator integrates their outputs into a coherent result. This is active work, not passive collection.

**Actions**: Review each output against its brief. Deduplicate overlapping findings. Resolve contradictions. Identify gaps where agents hit blockers. Produce the unified deliverable.

**Output**: Integrated result that is more than the sum of its parts.

### Phase 6: Handle Failures

Some agents will fail, hit blockers, or return incomplete results. Plan for this.

**Actions**: For each failed unit, decide: retry with a revised brief, reassign to a different agent type, absorb the work yourself, or accept the gap and document it.

**Output**: Complete result with any gaps documented and justified.

---

## Decomposition Patterns

| Pattern | Shape | Best For |
|---|---|---|
| **Fan-out / Fan-in** | One orchestrator dispatches N workers, collects all results | Independent tasks with a single synthesis step |
| **Pipeline** | A feeds B feeds C -- sequential stages, parallel within each stage | Work with clear phase dependencies |
| **Scatter-gather** | Same question to multiple specialists, best/merged answer wins | Getting diverse perspectives on the same problem |
| **Specialist-per-concern** | Each agent owns one domain (security, performance, correctness) | Multi-dimensional review or analysis |
| **Map-reduce** | Split input into chunks, process in parallel, merge results | Large-scale repetitive operations |

See [Decomposition Patterns Reference](references/decomposition-patterns.md) for detailed descriptions, decision criteria, and examples using this project's agent roster.

---

## Briefing a Subagent

A brief is not a wish list. It is a contract that constrains the agent's behavior. Good briefs produce predictable results; bad briefs produce creative surprises.

**What a good brief contains**:
- **Task**: One-sentence objective. What must be true when the agent finishes?
- **Context**: Relevant background -- just enough to understand the task, no more
- **Inputs**: File paths, data, references the agent needs to start working
- **Expected output**: The exact structure and format of the result
- **Boundaries**: What is explicitly out of scope. What the agent must NOT do.
- **Failure mode**: What to do when stuck -- report back, skip, or attempt a fallback

**What a good brief does NOT contain**:
- The orchestrator's full conversation history
- Unrelated context from other subagents
- Ambiguous scope ("look into this area and see what you find")
- Multiple unrelated objectives

See [Briefing Template Reference](references/briefing-template.md) for a complete template with examples.

---

## Isolation Strategies

| Strategy | When to Use | Trade-off |
|---|---|---|
| **Context isolation** | Always. Every subagent starts clean. | Requires explicit context transfer in the brief |
| **Filesystem isolation (worktree)** | When agents modify files | Branch management overhead, merge step required |
| **Read-only shared tree** | When agents only read (investigation, review, analysis) | No merge needed, but agents must not write |
| **Context + filesystem** | When agents modify files AND need independence from each other | Maximum isolation, maximum merge complexity |

**Rule**: If two agents might touch the same file, they must be in separate worktrees or run sequentially. There is no safe middle ground.

See [Isolation and Merging Reference](references/isolation-and-merging.md) for worktree setup, result synthesis, and conflict resolution strategies.

---

## Anti-Patterns

| Anti-Pattern | Symptom | Fix |
|---|---|---|
| **Dependency masquerading as independence** | Agent B blocks waiting for Agent A's output | Reorder as pipeline or merge into one unit |
| **Overlapping writes** | Merge conflicts after agents return | Enforce file-level ownership per agent |
| **Context bleed** | Agent inherits irrelevant history, gets confused | Start every agent with a clean brief, no inherited context |
| **Ambiguous brief** | Agent interprets scope differently than intended | Add explicit boundaries and out-of-scope list |
| **Agent sprawl** | 8+ agents dispatched for a task that needs 3 | Combine related work into fewer, focused units |
| **Duplicate research** | Two agents investigate the same files | Define non-overlapping investigation scopes |
| **No failure budget** | One agent failure stalls the entire workflow | Define fallback per agent; accept partial results |
| **Premature parallelization** | Splitting before understanding the problem | Investigate first, parallelize the known work |

See [Anti-Patterns Reference](references/anti-patterns.md) for detailed descriptions and recovery strategies.

---

## Practical Dispatch Patterns

These patterns map directly to the agent chaining flows defined in this project's agent roster:

### Investigation Fan-Out

```
Orchestrator -> [Investigator(auth), Investigator(billing), Investigator(notifications)]
            <- Merged findings
            -> Architect (design based on merged findings)
```

Dispatch multiple investigators in parallel when the task requires understanding several independent subsystems. Each gets a focused scope. The orchestrator merges findings before handing them to the architect.

### Feature Build with Parallel Implementation

```
Product Manager -> Architect -> [Backend Dev(API), Frontend Dev(UI), Implementer(migration)]
                             <- Integrated feature
                             -> QA Engineer
```

After requirements and design are sequential, implementation fans out to specialists working in isolated worktrees on non-overlapping file sets.

### Multi-Dimensional Review

```
Orchestrator -> [Reviewer(correctness), Refactor Scout(smells), Test Gap Analyzer(coverage)]
            <- Consolidated review report
```

Three specialists examine the same code from different angles simultaneously. Read-only agents sharing the working tree. The orchestrator consolidates findings by severity.

### Coverage Improvement Scatter

```
Orchestrator -> [Test Gap Analyzer(module-a), Test Gap Analyzer(module-b), Test Gap Analyzer(module-c)]
            <- Prioritized gap list
            -> [Implementer(module-a-tests), Implementer(module-b-tests)]
```

Fan-out analysis, then fan-out implementation -- two rounds of parallel dispatch.

---

## Quality Checklist

Before dispatching subagents:

- [ ] Each dispatch unit has a single, clear objective
- [ ] No two agents modify overlapping files
- [ ] Every brief includes explicit out-of-scope boundaries
- [ ] Expected output format is defined for each agent
- [ ] Failure mode is specified (report, skip, or fallback)
- [ ] File-modifying agents are assigned isolated worktrees
- [ ] Read-only agents have no write tools in their brief
- [ ] The synthesis plan is defined before dispatch (how will you merge results?)
- [ ] Dependencies between units are zero (or they are sequenced, not parallelized)
- [ ] The number of agents is justified (3-5 is typical; more needs strong rationale)

---

## Critical Rules

1. **Independence is a precondition, not an optimization.** If tasks share mutable state, they cannot run in parallel. Period.

2. **The brief is the contract.** Everything a subagent needs must be in the brief. If it is not in the brief, the agent does not know about it.

3. **Clean context only.** Never leak your conversation history, other agents' results, or ambient project context into a subagent's session.

4. **File ownership is exclusive.** Two agents must never modify the same file in the same dispatch round. Worktree isolation prevents accidents but does not prevent merge conflicts.

5. **Plan the synthesis before the dispatch.** If you cannot describe how outputs will be merged, you are not ready to parallelize.

6. **Failure is expected.** Budget for one agent failing. Define what "good enough" looks like with partial results.

7. **Fewer, focused agents beat many scattered ones.** Three well-briefed agents outperform seven vaguely-scoped ones.

8. **Investigate before parallelizing.** The first dispatch is usually a single investigator. Parallel execution comes after the problem space is mapped.

9. **The orchestrator synthesizes, not concatenates.** Pasting outputs together is not integration. Resolve conflicts, deduplicate, and produce a coherent whole.

10. **Match agent type to task type.** Use investigators for exploration, implementers for coding, reviewers for quality checks. Do not ask an investigator to write code or a reviewer to investigate.

---

## Reference Files

| Reference | Contents |
|---|---|
| [Decomposition Patterns](references/decomposition-patterns.md) | Fan-out/fan-in, pipeline, scatter-gather, specialist-per-concern, map-reduce -- decision criteria, examples with project agents |
| [Briefing Template](references/briefing-template.md) | Complete subagent brief template, good vs bad brief examples, output format specification |
| [Isolation and Merging](references/isolation-and-merging.md) | Context isolation, worktree isolation, result synthesis, conflict resolution, merge strategies |
| [Anti-Patterns](references/anti-patterns.md) | Detailed anti-pattern descriptions, detection signals, recovery strategies, prevention techniques |
| [When Not to Parallelize](references/when-not-to-parallelize.md) | Sequential workflow advantages, decision tree, cost-benefit analysis of dispatch overhead |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Planning the work before dispatching agents | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for the `writing-plans` skill |
| Understanding codebase before decomposition | Delegate to the `investigator` agent from `krzysztofsurdy/code-virtuoso` |
| Implementing features in isolated worktrees | Delegate to the `implementer` agent from `krzysztofsurdy/code-virtuoso` |
| Multi-dimensional code review | Delegate to `reviewer` and `refactor-scout` agents from `krzysztofsurdy/code-virtuoso` |
| Identifying test gaps across modules | Delegate to the `test-gap-analyzer` agent from `krzysztofsurdy/code-virtuoso` |
| Full feature delivery with agent team | See agent chaining patterns in `krzysztofsurdy/code-virtuoso` AGENTS.md |
| Structuring agent-driven development workflows | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for the `subagent-driven-development` skill |
| Designing system architecture before dispatch | Delegate to the `architect` agent from `krzysztofsurdy/code-virtuoso` |

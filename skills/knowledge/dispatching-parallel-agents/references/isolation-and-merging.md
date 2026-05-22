# Isolation and Merging

How to keep subagents independent during execution and integrate their results afterward. Isolation prevents interference; merging produces a coherent whole from parallel outputs.

---

## Context Isolation

Every subagent starts with a clean slate. It does not inherit the orchestrator's conversation history, memory, or accumulated context. This is not a limitation - it is a feature.

### Why Context Isolation Matters

- **Focus**: An agent with only its brief stays on task. An agent with full conversation history gets distracted by tangential context.
- **Token efficiency**: Subagents receive only what they need. Full context wastes capacity on irrelevant information.
- **Predictability**: The same brief produces the same behavior regardless of what the orchestrator discussed before dispatching.
- **Independence**: No agent can accidentally depend on another agent's intermediate output if it never sees it.

### How to Achieve Context Isolation

1. **Write self-contained briefs**: Every fact the agent needs is in the brief. If it is not in the brief, the agent does not know about it.
2. **Do not pass conversation history**: Extract relevant facts and include them as context in the brief. Discard the conversational wrapper.
3. **Do not share results between parallel agents**: If Agent B needs Agent A's output, they are not parallel - sequence them.
4. **Do not reference other agents**: Agent A should not know Agent B exists. Each agent believes it is the only one working on the problem.

### What to Include in Context

| Include | Why |
|---|---|
| Relevant architectural decisions | Agent needs to work within existing constraints |
| File paths and locations | Agent needs to find the code without searching |
| Domain terminology | Agent needs to understand the codebase's language |
| Recent relevant changes | Agent needs to know what changed and why |
| Acceptance criteria | Agent needs to know what "done" looks like |

### What to Exclude from Context

| Exclude | Why |
|---|---|
| Full conversation history | Dilutes focus, wastes tokens |
| Other agents' briefs | Creates implicit dependencies |
| Unrelated project context | Adds noise |
| The orchestrator's thought process | Agent does not need to know why it was chosen |
| Previous failed attempts | Unless the failure context is directly relevant to this agent's task |

---

## Filesystem Isolation

When agents modify files, they must work in separate filesystem spaces to prevent conflicts. The standard approach is git worktrees.

### Worktree Isolation

A git worktree creates a separate working directory backed by the same repository. Each worktree has its own branch. Agents modify files freely without affecting the main working tree or each other.

**When to use worktrees**:
- Agent will create, modify, or delete files
- Multiple agents modify files in the same dispatch round
- Changes need review before merging into the main branch

**When worktrees are unnecessary**:
- Agent is read-only (investigation, review, analysis)
- Only one agent modifies files in this dispatch round
- Agent modifies only files that no other agent touches

### Setting Up Worktree Isolation

For each file-modifying agent:

1. Create a worktree branch from the current branch
2. Assign the agent to work in that worktree directory
3. Include the worktree path in the agent's brief
4. After the agent completes, review changes before merging

### File Ownership Rules

Even with worktree isolation, merge conflicts can occur if two agents modify the same files on different branches. Prevent this with strict file ownership:

| Rule | Implementation |
|---|---|
| **Exclusive file ownership** | Each agent's brief lists the exact files or directories it may modify. No overlap allowed. |
| **Directory-level boundaries** | Assign entire directories to agents rather than individual files when possible. Cleaner ownership. |
| **Shared files are sequential** | If two agents must modify the same file, sequence them. The second agent works on the first agent's branch. |
| **New file convention** | If an agent needs to create a new file, the brief specifies the exact path. Two agents never create files in the same directory. |

### Read-Only Agents and Shared Trees

Agents that only read files (investigators, reviewers, auditors, test gap analyzers) can safely share the main working tree. They cannot interfere with each other because they make no modifications.

**Safety check**: Verify the agent's tool permissions do not include file editing or writing capabilities. A "read-only" agent with write tools is an accident waiting to happen.

---

## Result Synthesis

When parallel agents complete, the orchestrator receives multiple outputs that must be integrated into a single coherent result. Synthesis is the orchestrator's core responsibility - it cannot be delegated.

### Synthesis Steps

1. **Collect**: Gather all agent outputs. Note which agents completed successfully and which failed or returned partial results.

2. **Validate**: Check each output against its brief. Did the agent answer the right question? Is the output in the expected format? Flag outputs that deviate.

3. **Deduplicate**: Multiple agents may report the same finding, especially in scatter-gather patterns. Identify duplicates by comparing file paths, line numbers, and descriptions.

4. **Resolve conflicts**: When agents disagree, the orchestrator must decide. Common resolution strategies:

   | Conflict Type | Resolution Strategy |
   |---|---|
   | Severity disagreement | Use the higher severity (conservative) |
   | Contradictory findings | Re-investigate the specific point manually |
   | Overlapping recommendations | Keep the more specific recommendation |
   | Different categorizations | Use the more granular categorization |

5. **Fill gaps**: Identify what no agent covered. This happens when task decomposition missed an area or when an agent failed mid-task. Decide whether to dispatch another agent or investigate manually.

6. **Structure**: Organize the merged output into a coherent format. This often means:
   - Sorting findings by priority or severity
   - Grouping related items from different agents
   - Adding cross-references between findings
   - Writing a summary that no individual agent could have written

7. **Deliver**: Present the synthesized result. The final output should read as if one comprehensive agent produced it, not as a collage of separate reports.

### Synthesis by Pattern

| Pattern | Primary Synthesis Challenge |
|---|---|
| Fan-out / Fan-in | Merging N independent result sets into one ordered list |
| Pipeline | Validating that stage N output is suitable input for stage N+1 |
| Scatter-gather | Deduplicating and weighting findings from different perspectives |
| Specialist-per-concern | Organizing findings by concern while highlighting cross-cutting issues |
| Map-reduce | Aggregating chunk results and handling boundary overlaps |

---

## Merging Code Changes

When multiple agents produce code changes in separate worktrees, merging requires additional care.

### Merge Order Strategy

1. **Merge the smallest, most isolated change first**: Minimize the merge base complexity for subsequent merges.
2. **Run tests after each merge**: Do not batch merges. A test failure after merge 3 of 5 is much harder to diagnose than after merge 1.
3. **If a merge conflicts, stop**: Do not resolve merge conflicts mechanically. Conflicts indicate the decomposition had an overlap. Understand the conflict before resolving it.

### Pre-Merge Checklist

Before merging each agent's branch:

- [ ] Agent reported successful completion
- [ ] Output matches the expected format from the brief
- [ ] Changes are limited to the files assigned in the brief
- [ ] Test suite passes on the agent's branch
- [ ] No unexpected file modifications outside the assigned scope

### Post-Merge Verification

After all branches are merged:

- [ ] Full test suite passes on the merged branch
- [ ] No unresolved merge conflicts
- [ ] Linting and static analysis pass
- [ ] The merged result achieves the original task objective
- [ ] No duplicate or contradictory changes from different agents

### Handling Merge Conflicts

| Scenario | Response |
|---|---|
| **Trivial conflict** (imports, formatting) | Resolve manually and continue |
| **Logic conflict** (two agents changed the same logic differently) | Decomposition error. Understand both changes, choose one, and adapt the other. |
| **Architectural conflict** (two agents made incompatible design decisions) | Roll back both. Re-plan with a single agent or add an architect review step. |

---

## Failure Handling During Synthesis

Not every agent succeeds. The orchestrator's synthesis must account for incomplete results.

### Failure Categories

| Category | Description | Response |
|---|---|---|
| **Complete failure** | Agent returned nothing or errored out | Retry with a revised brief, reassign, or absorb the work |
| **Partial results** | Agent completed some tasks but hit blockers on others | Use what is available, dispatch a follow-up for the remainder |
| **Wrong scope** | Agent answered a different question than asked | Discard and re-dispatch with a clearer brief |
| **Low quality** | Agent returned results but they are superficial or inaccurate | Supplement with manual investigation of the weak areas |

### Decision Tree for Failed Agents

```
Agent failed?
  -> Was the brief clear? 
       No  -> Revise brief, re-dispatch
       Yes -> Was it a transient error?
                Yes -> Retry same brief
                No  -> Can another agent type handle this?
                         Yes -> Reassign to different agent type
                         No  -> Absorb the work into the orchestrator's own context
```

### Acceptable Degradation

Not every gap needs filling. Define in advance what constitutes an acceptable result:

- **Hard requirement**: Must be complete. Retry or absorb failures.
- **Soft requirement**: Nice to have. Document the gap and move on.
- **Informational**: If it is missing, note it for future work.

Budget for one agent failure in every dispatch round. If success depends on all N agents completing perfectly, the plan is too fragile.

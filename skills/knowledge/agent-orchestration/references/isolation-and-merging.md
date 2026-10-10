# Isolation and merging

How to keep agents from interfering while they run, and how to turn their separate outputs into one result.

## Contents

- [Context isolation](#context-isolation)
- [Filesystem isolation](#filesystem-isolation)
- [File ownership](#file-ownership)
- [Synthesizing results](#synthesizing-results)
- [Merging code](#merging-code)
- [Handling failed agents](#handling-failed-agents)

## Context isolation

Every agent starts clean. It does not see your conversation, and that is a feature: it stays on its task, spends its context on the work, and cannot depend on another agent's half-finished output.

To keep it that way:

1. Write self-contained briefs. Put every needed fact in the brief.
2. Extract facts from the conversation instead of forwarding it.
3. Do not share results between parallel agents. If B needs A's output, they are a sequence, not a fan-out.
4. Do not mention other agents. Each agent works as if it were alone.

| Include in context | Leave out |
|---|---|
| Architectural decisions and constraints that apply | Conversation history |
| File paths and entry points | Other agents' briefs |
| Domain terms the agent will meet | Unrelated project background |
| Acceptance criteria | Why you picked this agent |
| Recent changes that matter | Failed attempts, unless they change the task |

One exception is deliberate: some review patterns depend on an agent seeing less than the others (a zero-context reviewer) or more (a lead who reads all reports). Decide the context level per agent and write it down.

## Filesystem isolation

| Situation | Isolation |
|---|---|
| Agent only reads (research, review, audit) | Share the working tree. Check its tool list has no write tools, because a "read-only" agent with write tools will eventually write |
| One agent writes, the rest read | Share the tree, only if the readers do not need to see the writer's changes mid-run |
| Several agents write at once | One worktree (or clone) per writer, plus file ownership rules |
| Agents write and must build on each other's output | Run them in sequence, each on the previous branch |

A git worktree is a separate directory with its own branch on the same repository. Agents edit freely without touching your tree or each other.

Check where the worktree branches from. Some platforms start isolated worktrees from the repository's default branch, not from your current commit, so an agent working in isolation silently misses your unmerged changes. Before relying on isolation, either commit and merge what the agents need, set the platform's base to your current HEAD, or tell the agent to check out a named branch first. Platform specifics are in [platform-notes.md](platform-notes.md).

Isolation prevents accidental overwrites. It does not prevent merge conflicts. That is the job of ownership.

## File ownership

| Rule | How |
|---|---|
| Exclusive ownership | Each brief lists the exact files or directories the agent may change. No overlap |
| Directory-level boundaries | Give whole directories when possible. Ownership is easier to check |
| Shared files are sequential | If two agents must change one file (a route table, a lockfile, a config), run them in order, the second on the first's branch, or give the file to a dedicated follow-up agent |
| Named new files | The brief names the exact path of any file to create. Two agents never create files in one directory |

If you cannot divide the files without overlap, the work is not parallel. Merge the units or sequence them.

## Synthesizing results

Synthesis is your core job and you cannot delegate it. Concatenating reports is not synthesis.

1. **Collect.** Note which agents finished, which failed, and which returned partial work.
2. **Validate.** Check each output against its brief: right question, right format. Flag deviations.
3. **Deduplicate.** Match findings by file, line, and description.
4. **Resolve conflicts.**

   | Conflict | Resolution |
   |---|---|
   | Severity disagreement | Keep the higher severity |
   | Contradictory findings | Re-check the specific point yourself |
   | Overlapping recommendations | Keep the more specific one |
   | Different categories | Use the finer-grained category |

5. **Fill gaps.** Find what nobody covered, because the split missed it or an agent failed. Dispatch another agent or look yourself.
6. **Structure.** Sort by severity, group related items across agents, add cross-references, and write the summary no single agent could write.
7. **Deliver** one result that reads as if one author wrote it.

Plan the synthesis before you dispatch. If you cannot say how the outputs will combine, you are not ready to fan out.

## Merging code

When agents produce changes on separate branches:

1. Merge the smallest, most isolated change first. It keeps the base simple for the rest.
2. Run the tests after every merge. A failure after merge 3 of 5 is far harder to diagnose than one after merge 1.
3. If a merge conflicts, stop. A conflict means the split overlapped. Understand both changes before resolving.

| Conflict type | Response |
|---|---|
| Trivial (imports, formatting) | Resolve and continue |
| Logic (two agents changed the same logic differently) | Decomposition error. Understand both, keep one, adapt the other |
| Architectural (incompatible design decisions) | Roll back both. Re-plan with one agent, or add a design review step |

Before each merge: the agent reported success, the output matches the brief's format, changes stay inside the assigned files, and tests pass on the agent's branch.

After all merges: the full suite passes, lint and static analysis pass, the combined result meets the original objective, and no two agents made duplicate or contradictory changes (for example the same dependency at two versions).

## Handling failed agents

| Failure | Response |
|---|---|
| Nothing returned, or an error | Retry with a revised brief, reassign to another agent type, or absorb the work |
| Partial results | Use what exists. Dispatch a follow-up for the rest |
| Answered a different question | Discard and re-dispatch with a clearer brief |
| Superficial or wrong | Supplement with your own check of the weak areas |

```
Agent failed?
  Was the brief clear?
    No  -> revise the brief and re-dispatch
    Yes -> was the error transient?
             Yes -> retry the same brief
             No  -> can another agent type do it?
                      Yes -> reassign
                      No  -> do the work yourself
```

Decide in advance how complete the result must be. A hard requirement must be complete, so retry or absorb. A soft requirement can carry a documented gap. Plan for one agent failing in every round: if success needs all N agents to be perfect, the plan is too fragile.

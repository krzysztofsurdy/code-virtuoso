---
name: agent-orchestration
description: Decides how to split work across agents and runs it well. Use whenever the user wants to delegate, parallelize, fan out, split this work, do multi-agent or subagent work, set up an agent team, or execute a multi-task plan with one fresh agent per task and review gates. Covers briefs, isolation, merging, hand-offs, failure handling, and when not to parallelize.
user-invocable: false
---

# Agent orchestration

Delegating well starts with deciding whether to delegate at all. Agents cost tokens and add coordination work, and every hand-off loses context. Use the lightest mode that fits the work, write briefs that stand alone, keep writers out of each other's files, and check results before you build on them.

## Core principles

| Principle | Meaning |
|---|---|
| **Lightest mode first** | Do it yourself unless delegation buys isolation, parallelism, or a second opinion |
| **Independence is a precondition** | Tasks that share state or files are one task. Parallelize only what can finish without talking |
| **The brief is the contract** | The agent knows only the brief and the codebase. Anything not in it does not exist |
| **Exclusive file ownership** | Two agents never change the same file in the same round |
| **Synthesize, do not concatenate** | You deduplicate, resolve conflicts, and write one result |
| **Verify before building on it** | Check each result against its criteria before the next task depends on it |
| **Fail loudly** | Agents report blockers instead of guessing, and you plan for one agent failing |

## Choose a mode

Work down the list and stop at the first row that fits.

| Mode | Use when | Cost and risk |
|---|---|---|
| **1. Do it yourself** | The task is small, the problem is not understood yet, or it needs the whole conversation to make sense | None. Prefer it for under three independent units |
| **2. One subagent** | A noisy side task (search, log reading, test runs) would bury your context, or you want a fresh-eyes check | One brief and one result to read |
| **3. Parallel fan-out** | Three or more independent units, with no shared files, whose results you will merge | Brief and synthesis overhead. Merge conflicts if ownership slips |
| **4. Sequential with review gates** | A written plan of three or more tasks that build on each other and need a check after each | Slowest, most reliable. See [review-gates.md](references/review-gates.md) |
| **5. Team or workflow** | A known multi-role recipe (review squad, development team, war room), or hundreds of units, or agents that must challenge each other | Highest token cost. See [teams.md](references/teams.md) |

Three questions settle most cases:

1. Do you know what the units of work are? If not, investigate first (mode 1 or 2), then split.
2. Does any unit need another unit's output? Then those units are a sequence. Parallelize within a stage, not across stages.
3. Must the agents talk to each other, or only report back? Only reporting: fan-out or a workflow. Talking: a team, if the platform has one ([platform-notes.md](references/platform-notes.md)), otherwise a lead that relays.

Pick a team over a workflow only when the next step depends on what teammates tell each other. Pick a workflow when the control flow is known in advance. Without either, run the recipe's phases yourself.

## When not to parallelize

| Signal | Do this instead |
|---|---|
| Output of A feeds B | Pipeline: parallelize inside each stage |
| Tasks edit overlapping files | Sequence them, or merge them into one unit |
| The problem is not yet understood | One investigator first, split afterward |
| Fewer than three independent units | Do it yourself. Dispatch overhead exceeds the time saved |
| One complex investigation needs the whole picture | Keep it in one context |
| What you learn in area A changes how you look at area B (an intermittent failure, say) | Investigate in sequence |
| Each step needs feedback from the last (revision cycles, narrowing a design) | Iterate in one context |
| The result must come out in strict order | Run in order |

Most real work is a hybrid: investigate sequentially until you can draw the dependency map, fan out the known units, then review and integrate in sequence.

## Decompose

| Pattern | Shape | Best for |
|---|---|---|
| **Fan-out and fan-in** | N workers on N independent items, one merge | Audits of several modules, research across topics |
| **Pipeline** | Stage A feeds B feeds C, parallel inside each stage | Work with real phase dependencies |
| **Scatter-gather** | The same question to several specialists | Independent opinions, adversarial checks |
| **Specialist per concern** | One agent per lens (security, performance, correctness) | Multi-angle review |
| **Map-reduce** | Split a large input into chunks, process, merge | Repetitive work over many files |

Keep to three to five agents for most work. Past about seven, the briefing and merging cost usually exceeds the gain. If two units would read mostly the same files, they are one unit.

Match agent to task: investigators explore, implementers write code, reviewers review. Do not ask an investigator to write code or a reviewer to explore.

## Brief every agent

Every brief has six parts: task (one sentence), context (only what this task needs), inputs (exact paths), expected output (a fixed structure), boundaries (in scope, out of scope), and what to do when stuck. Add acceptance criteria when the agent builds something. Do not forward your conversation, other agents' briefs, or the whole plan.

Test a brief by asking: would this make sense to someone who knows nothing about the project except what is written here? Template, examples, and sizing rules are in [briefing-template.md](references/briefing-template.md).

## Run it

Start each agent with a clean context. Then decide isolation:

| Agents | Isolation |
|---|---|
| Read only | Share the working tree. Confirm they have no write tools |
| One writer | Share the tree if nothing else runs against it |
| Several writers | One worktree or clone each, plus file ownership lists in the briefs |

Isolated worktrees may start from the default branch instead of your current commit. Check this before relying on them. Details, merge order, and conflict handling are in [isolation-and-merging.md](references/isolation-and-merging.md).

Plan the synthesis before you dispatch. If you cannot say how the results will combine, you are not ready to fan out.

## Sequential task loop with review gates

For a written plan, run one fresh agent per task and check each result twice before moving on:

1. Brief the agent with the task and the hand-off from the previous task.
2. Dispatch with isolation. The agent reports done, done with concerns, needs context, or blocked.
3. **Gate 1, spec compliance:** does the output meet every acceptance criterion and stay in scope? Mechanical, per criterion.
4. **Gate 2, code quality:** correctness, design, security, performance, tests. Judgment, with severity.
5. Decide: accept, return with specific feedback, or abort and re-scope.
6. Hand off a compressed summary to the next task.

Gate 1 comes first because reviewing the quality of code that misses its spec is wasted effort. Both gates apply to small tasks too. Cap fix cycles at two per gate, then re-scope or escalate. You coordinate and review. Agents implement. Rubrics, report formats, and hand-off templates are in [review-gates.md](references/review-gates.md).

Hand-off format, kept under about 40 lines:

```
Hand-off: Task NN -> Task MM
Changes:   files created or modified, new signatures
Decisions: choice, rejected alternative, reason, impact on the next task
Tests:     counts and status
Deviations from the plan, open items
```

## Handle failures

| Failure | Response |
|---|---|
| Agent returned nothing or errored | Retry with a revised brief, reassign to another agent type, or do it yourself |
| Partial result | Keep what is usable and dispatch a follow-up for the rest |
| Answered a different question | Discard and re-dispatch with clearer scope |
| Needs context | Supply the fact and re-dispatch. Do not guess for it |
| Blocked | Handle it now: give context, re-scope, or ask a human |
| Fix loop past two rounds | The task is mis-scoped or the feedback is vague. Re-scope or escalate |

Decide up front which results are hard requirements (retry or absorb failures) and which are soft (document the gap). Budget for one agent failing per round.

## Anti-patterns

| Anti-pattern | Symptom | Fix |
|---|---|---|
| **Dependency posing as independence** | Agent B stalls or guesses without A's output | Sequence them, or split B into an independent part and a dependent part |
| **Overlapping writes** | Merge conflicts, vanished changes | Exclusive file lists per agent |
| **Context bleed** | The agent cites facts that were not in its brief | Self-contained briefs, no history |
| **Ambiguous brief** | Output does not match what you wanted | Boundaries, output format, failure mode |
| **Agent sprawl** | Seven or more agents on a three-agent task, synthesis slower than the work | Merge related units |
| **Duplicate research** | Two agents read the same files | Non-overlapping scopes |
| **Premature split** | You parallelize before you understand the problem | Investigate first |
| **Skipped or "looks fine" reviews** | Errors surface three tasks later | Both gates, against criteria with evidence |
| **Orchestrator implements** | Your context fills with detail | Delegate the work, keep the review |
| **Pasting the full plan** | The agent starts on the wrong task | Current task and hand-off only |

## Checklist

Before dispatching:

- [ ] A lighter mode was considered and rejected on purpose
- [ ] Each unit has one objective and an exact file list it may change
- [ ] No two writers share a file, and writers are isolated
- [ ] Every brief has output format, boundaries, and a failure instruction
- [ ] You know how the results will be merged
- [ ] The agent count is justified (three to five is typical)

Before accepting a result:

- [ ] It matches the brief's format and stays in scope
- [ ] Each acceptance criterion has evidence
- [ ] Tests pass on the agent's branch, and again after merging
- [ ] Gaps and failed agents are documented, not hidden

## Reference files

| Reference | Contents |
|---|---|
| [briefing-template.md](references/briefing-template.md) | Brief template, field guidance, examples by agent type, output formats, sizing |
| [review-gates.md](references/review-gates.md) | Two-gate rubric, decision matrix, re-review rules, hand-off formats |
| [isolation-and-merging.md](references/isolation-and-merging.md) | Context and filesystem isolation, file ownership, synthesis, merge order, failures |
| [platform-notes.md](references/platform-notes.md) | What Claude Code, Codex, Cursor, and Windsurf support, with limits and setup (verified 2026-10-21) |
| [teams.md](references/teams.md) | Review squad, development team, and war room as Markdown recipes for any harness |

## Integration with other skills

| Situation | Recommended skill or agent |
|---|---|
| Turning a ticket into a plan before dispatch | `ticket-delivery` |
| Mapping unfamiliar code before splitting | `investigator` agent |
| Implementing a task test first in isolation | `implementer` agent |
| Gate 2 reviews and multi-angle review | `reviewer` and `cold-reviewer` agents |
| Proving a task is done before accepting it | `verification-before-completion` |
| Finishing the branch after all tasks pass | `finishing-branch` |
| Choosing which agent or skill fits | `using-ecosystem` |

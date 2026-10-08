# Long task notes

How to keep a long job on track across compactions, new sessions and subagents, using files instead of conversation memory.

## Contents

- [Why notes beat history](#why-notes-beat-history)
- [Files to keep](#files-to-keep)
- [Progress file layout](#progress-file-layout)
- [Task list layout](#task-list-layout)
- [One feature per session](#one-feature-per-session)
- [Handoff note](#handoff-note)
- [Compaction checklist](#compaction-checklist)
- [Subagent offloading patterns](#subagent-offloading-patterns)
- [Common failures](#common-failures)

## Why notes beat history

Compaction summarizes the conversation. A summary keeps the gist and loses exact values, rejected options and the reason for a choice. A file keeps all three. Anthropic's context engineering guidance names structured note-taking, with a to-do list or a NOTES file the agent reads back later, as the technique for iterative work with clear milestones ([Effective context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)). Anthropic's long-running harness work uses the same idea: a feature list, a progress log and an init script that every session reads first ([Effective harnesses](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)).

## Files to keep

| File | Holds | Changes |
|---|---|---|
| Task list (`tasks.md` or `features.json`) | Every unit of work with a status | One status flips per finished unit |
| Progress file (`PROGRESS.md`) | What was done, what was learned, what is next | Appended at the end of each step |
| Decisions file or ADR | Choices with the reason and rejected options | Added when a choice is made |
| Start script (`init.sh`, `make dev`) | How to bring the environment to a known state | Rarely |

Put them in the repository, commit them with the work, and keep them out of the always-on instruction file. The instruction file only says where they are and to read them first.

## Progress file layout

Keep it short and current. Trim old entries into a dated archive when it passes about 100 lines.

```markdown
# Progress

## Current state
- Goal: migrate invoice export to the new queue
- Branch: feat/PROJ-412_invoice_queue
- Last green: `make test` at commit abc1234
- Blocked: none

## Next
1. Add retry policy to `ExportWorker` (test first)
2. Update runbook `docs/export.md`

## Done
- 2026-10-20 Added `ExportMessage` and handler (abc1234)
- 2026-10-20 Moved CSV writer behind `ExportWriter` interface (def5678)

## Learned
- The legacy cron job also writes to `exports/`. Do not delete that directory.
- Fixture `invoices.yaml` must keep ids above 1000 or the FK test fails.

## Open questions
- Does finance need the old column order? Asked in thread, no answer yet.
```

Rules for the file:

- "Current state" and "Next" are what a fresh session needs first, so they go on top.
- Record exact values (commit hashes, commands, error text), not impressions.
- Record rejected options and why, so the next session does not retry them.
- Write the update before moving on, not at the end of the day.

## Task list layout

Use a format the agent edits reliably. Anthropic's long-running harness used a JSON feature list because the model is less likely to inappropriately change or overwrite JSON than Markdown, and told agents to edit it only by changing a status field.

```json
[
  {"id": "T1", "title": "ExportMessage and handler", "status": "done"},
  {"id": "T2", "title": "Retry policy in ExportWorker", "status": "in_progress"},
  {"id": "T3", "title": "Runbook update", "status": "todo"}
]
```

- Define every task as a unit that can be tested end to end.
- Allow only the status field to change. Do not let the agent delete or reword tasks to make the list look done.
- Mark a task done only after its verification ran, not after the code was written.

## One feature per session

A session that tries to finish everything runs out of window mid-feature and leaves half-done work. A pattern that holds up:

1. Read the progress file, the task list and the last few commits.
2. Run the start script and the test suite to confirm a clean baseline.
3. Pick one task. Write the failing test first.
4. Implement, verify end to end, commit.
5. Update the task status and progress file.
6. Stop, or clear and start the next task.

Each session ends with a clean, committed state, so the next one starts from facts instead of from a summary.

## Handoff note

When pausing mid-task or passing work to another session or person, write a note that stands alone:

```markdown
## Handoff 2026-10-21
- Working on: T2 retry policy
- State: test `ExportWorkerRetryTest` written and failing, implementation not started
- Run: `make test-one T=tests/Export/ExportWorkerRetryTest.php`
- Next step: add `RetryPolicy` with 3 attempts and exponential delay, then make the test pass
- Watch out for: worker config is in `config/packages/messenger.yaml`, not `.env`
- Uncommitted: none
```

The test of a good handoff: a reader with no chat history can resume in two minutes.

## Compaction checklist

Before compacting by hand:

- [ ] Progress file and task list are current
- [ ] Decisions made this session are written down
- [ ] Work is committed or the diff state is noted
- [ ] You know what the next step is and put it in the focus text

Run it with a focus, for example `/compact focus on the retry policy and the failing test`. After it:

- [ ] Ask the agent to restate the goal, the next step and the constraints, and correct it if wrong
- [ ] Re-invoke any skill whose full text the task needs
- [ ] Re-read path-scoped rules if the agent starts ignoring them, since they may have been summarized away

Clear instead of compacting when the next task is unrelated.

## Subagent offloading patterns

| Pattern | Use when | Prompt shape |
|---|---|---|
| Research and return | The answer is small but the search is large | "Find every caller of `X`. Return paths, line numbers and one line each. No code dumps." |
| Parallel scan | Independent areas can be checked at once | One subagent per directory or concern, same output template, merge in the main window |
| Fresh-eyes review | You want a read not shaped by your assumptions | Give the diff only, not your conclusions |
| Verification | A long check would flood the window | "Run the suite and return failing test names with the first error line each." |

Rules that keep it cheap and honest:

- Ask for a fixed output template, so results are short and comparable.
- Require file paths and line numbers, so claims can be spot-checked.
- Do not paste the whole conversation into the prompt. State the goal, the files to start from and what is already ruled out.
- Treat the returned summary as a claim. Verify the one or two facts the next step depends on.

## Common failures

| Failure | Cause | Fix |
|---|---|---|
| Agent redoes finished work | No progress file, or it was not read first | Add "read PROGRESS.md first" to the always-on file |
| Task list marked done but nothing works | Status flipped before verification | Make verification part of the done definition |
| Progress file grows without bound | Nothing is trimmed | Archive entries older than the current phase |
| Notes contradict the code | Notes written from memory | Record commands and commit hashes, and re-check on resume |
| Agent loses a constraint after compaction | Constraint lived in chat only | Put it in the progress file or the always-on file |
| Summary from a subagent is wrong | Broad prompt, no paths required | Narrow the question, require evidence, verify key facts |

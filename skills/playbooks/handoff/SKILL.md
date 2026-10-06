---
name: handoff
description: "Writes a short handoff note when a session ends mid-task so the next session, agent, or person can continue without re-discovery, and resumes work from one. Use when asked to hand off, save progress, wrap up for now, or continue from a handoff note."
user-invocable: true
argument-hint: "[write | resume <path>]"
---

# Handoff

A new session starts with no memory. Whatever you learned, tried, and decided is gone unless it is written down. A handoff note is the shortest document that lets the next reader continue at the exact next step instead of re-reading the codebase and repeating dead ends. Write it from facts you checked, not from memory of what you meant to do.

## Write a handoff

1. **Capture state from the repo, not from recall.** Run `git status`, `git branch --show-current`, `git log --oneline <base>..HEAD`, and the test command. Uncommitted work is the main loss risk, so commit it as a WIP commit if the user agrees, or list the files.
2. **Fill the template** below. Leave a section out only if it is truly empty, and say "none" so the reader knows you did not forget it.
3. **Make the next step exact.** One action the reader can start in the first minute: a command to run, a file and function to open. "Continue the refactor" is not a next step.
4. **Record dead ends.** What you tried and why it failed is the most expensive thing to rediscover. Include the error text or the reason.
5. **Save it** (see below) and tell the user the path.

Keep it to one screen, about 40 lines. Link to files, commits, tickets, and PRs instead of pasting their content. If a section runs long, the detail belongs in the code, a commit message, or a ticket.

## Template

```markdown
# Handoff: <short title>

Date: <YYYY-MM-DD>   Branch: <branch>   Base: <commit or PR>

## Goal
<One or two sentences: what is being built or fixed, and why. Link the ticket.>

## Current state
<Where things stand now. Passing or failing, what works, what is half done. Uncommitted files.>

## Done
- <sha> <what it did>

## Tried and failed
- <approach>: <why it did not work, error text or evidence>

## Open questions
- <question>: <who can answer, what depends on it>

## Next step
<The single first action, with the exact command or file.>

## Files and commands
- `<path>`: <why it matters>
- `<command>`: <what it does>

## Verify
<How to confirm the work is correct: the commands and the expected result.>
```

## Where to save it

Save to the project, under the shared config folder from `spec/config-spec.md`:

```
<project root>/.code-virtuoso/handoff/<YYYY-MM-DD>-<slug>.md
```

- Project root is `git rev-parse --show-toplevel`, else the current directory.
- Use a short kebab-case slug from the task (`2026-10-21-checkout-retry.md`).
- Handoffs are session state, not team decisions, so keep them out of git by default. Make sure `.code-virtuoso/.gitignore` has a `handoff/` line, and append it if missing. Create the file with the spec's two default lines plus `handoff/` when the folder is new.
- If the user wants the note shared (another person picks it up), tell them to commit it with `git add -f`, or save it under a tracked path they name, such as `docs/`.
- If there is no repository or the user names a place, follow the user.
- Never put secrets, tokens, or `.env` values in the note. Name the variable, not its value.

## Resume from a handoff

1. **Find it.** Use the path the user gives, else the newest file in `.code-virtuoso/handoff/`. Read all of it.
2. **Verify the state matches.** The note describes the past. Check the branch name, that the listed commits exist (`git log`), what `git status` shows, and that the failing or passing tests are the same now. Someone may have pushed, rebased, or changed files since.
3. **Reconcile differences.** If the repo disagrees with the note, trust the repo, update your understanding, and tell the user what differs before continuing.
4. **Skip the dead ends.** Do not retry an approach listed under "Tried and failed" unless something changed. Say why if you do.
5. **Do the next step**, then run the Verify section. Resolve open questions with the user first when they block the step.
6. **Update the note** or write a new one if you stop again, so the chain stays current.

## Checklist

- [ ] State taken from `git status`, `git log`, and a test run
- [ ] Goal, done, failed, open questions, next step, files, verify all present
- [ ] Next step is one concrete action
- [ ] Note fits one screen and links instead of pasting
- [ ] No secrets in the note
- [ ] Saved under `.code-virtuoso/handoff/` and the path given to the user
- [ ] `handoff/` is in `.code-virtuoso/.gitignore` unless the user wants it shared

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Work is finished, not paused | `finishing-branch` |
| Paused while review feedback is open | `pr-feedback` |
| Claiming progress in the note | `verification-before-completion` |
| Dead ends came from a bug hunt | `debugging` |

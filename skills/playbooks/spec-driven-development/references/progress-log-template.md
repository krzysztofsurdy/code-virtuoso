# Progress log template

For work that spans sessions, people, or context resets. Keep it in `specs/<slug>/progress.md`. The log is how the next session knows where things stand without trusting anyone's memory, including its own.

## Contents

- [Template](#template)
- [Resume procedure](#resume-procedure)
- [Rules](#rules)

## Template

```markdown
# Progress: <feature name>

Spec: specs/<slug>/spec.md
Branch: <branch name>
Commands: test `<cmd>`, lint `<cmd>`, static analysis `<cmd>`

## Current state

- Done: T001, T002, T003
- Next: T004
- Blocked: none

## Log

### 2026-10-21 session 3

- Task: T003 implement expiry check
- Result: done, commit a1b2c3d
- Evidence: `<test command>` 42 passed, 0 failed; lint clean
- Notes for next session: middleware reads claims through ClaimsCache, which is stale in tests unless cleared (see tests/bootstrap.php)
- Spec changes: FR-1 criterion 2 reworded, expiry is inclusive

### 2026-10-20 session 2

...
```

## Resume procedure

1. Read `progress.md` (Current state first, then the latest log entry), then `tasks.md`.
2. Check the repo against the log: `git status`, `git log --oneline -10`, and the test command. If they disagree with the log, trust the repo and fix the log.
3. Run the test suite before touching code. A red start is a finding to record, not noise to ignore.
4. Pick the next unchecked task with its dependencies done. Work only on it.
5. After the task: verify, commit, tick `tasks.md`, append a log entry, update Current state.

## Rules

- Append entries, do not rewrite old ones. Corrections go in a new entry.
- Record evidence (command and result), not "tests pass".
- Write notes for a reader with no context: what surprised you, what you decided, what is half true.
- Record every spec change made during implementation, with the requirement ID.
- When the work is finished, mark the log closed and leave it with the spec, or archive both together.

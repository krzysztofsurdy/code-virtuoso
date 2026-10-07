# Tasks template

Copy this into `specs/<slug>/tasks.md`. A task is the unit of work for one session or one loop pass.

## Contents

- [Template](#template)
- [Task rules](#task-rules)
- [Coverage check](#coverage-check)
- [Tiny changes](#tiny-changes)

## Template

```markdown
# Tasks: <feature name>

Spec: specs/<slug>/spec.md
Plan: specs/<slug>/plan.md

## Foundation

- [ ] T001 Add token_expired error code in src/Auth/ErrorCode.php (check: tests/Auth/ErrorCodeTest.php passes)

## FR-1: Reject expired tokens

- [ ] T002 [FR-1] Test: expired token returns Claims error in tests/Auth/TokenValidatorTest.php (check: test fails for the right reason)
- [ ] T003 [FR-1] Implement expiry check in src/Auth/TokenValidator.php (check: T002 test passes, suite green)

## FR-2: Return 401 for invalid tokens

- [ ] T004 [P] [FR-2] Middleware test in tests/Http/AuthMiddlewareTest.php (check: fails for the right reason)
- [ ] T005 [P] [FR-2] Update API docs in docs/api/auth.md (check: docs lint passes)
- [ ] T006 [FR-2] Implement 401 response in src/Http/AuthMiddleware.php (check: T004 test passes, suite green)

## Wrap-up

- [ ] T007 Run full suite, lint, static analysis; update spec status (check: all green, output captured)
```

## Task rules

| Rule | Why |
|---|---|
| ID is sequential and never reused | Progress logs and commits refer to IDs |
| `[P]` only for tasks with disjoint files and no unfinished dependency | Parallel work that touches the same file produces merge conflicts and lost edits |
| Each task names a requirement ID, or sits under Foundation or Wrap-up | Traceability: no task without a reason, no requirement without a task |
| Each task names its files | The next session knows where to look without searching |
| Each task has a check: a test, a command, an observable result | "Done" means the check passed, not that code was written |
| Size: about one commit, one session | Bigger tasks hide unverified work; split them |
| Test tasks come before the code tasks they cover | Keeps the red step visible and separate |
| After each task the build is green | Any task can be the last one completed |

## Coverage check

Use this table when no `plan-auditor` is available, and to read its output when it is.

| Requirement | Plan row | Task IDs | Status |
|---|---|---|---|
| FR-1 | yes | T002, T003 | COVERED |
| FR-2 | yes | T004, T006 | COVERED |
| NFR-1 | yes | none | MISSING |

COVERED means both a plan row and a task. PARTIAL means one. MISSING means neither. Any MISSING or PARTIAL row blocks implementation.

## Tiny changes

For a tiny change, skip spec and plan. Write the list in the ticket or in `tasks.md`:

```markdown
- [ ] T001 Test: <behavior> in <test path>
- [ ] T002 Fix <behavior> in <source path> (check: T001 passes, suite green)
```

State the intended behavior in one sentence at the top so the checks have a source.

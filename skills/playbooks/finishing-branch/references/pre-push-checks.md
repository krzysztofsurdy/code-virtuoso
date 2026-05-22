# Pre-Push Checks

Verification before pushing ensures that CI will not fail on something you could have caught locally. Run checks in order from fastest to slowest - fail fast, fix early.

## Verification Order

The order matters. Linting takes seconds; integration tests take minutes. Do not wait for a slow test suite to discover a missing semicolon.

| Step | What It Catches | Typical Duration | Example Commands |
|---|---|---|---|
| 1. Lint | Formatting, style violations, syntax errors | 1-10 seconds | `make lint`, `npm run lint`, `cargo clippy`, `flake8` |
| 2. Type check | Type mismatches, missing interfaces, wrong signatures | 5-30 seconds | `npx tsc --noEmit`, `mypy .`, `phpstan analyse`, `cargo check` |
| 3. Unit tests | Logic errors, regressions in isolated units | 10-120 seconds | `make test`, `pytest -x`, `phpunit --testsuite=unit`, `cargo test` |
| 4. Integration tests | Wiring errors, service interaction failures | 30-300 seconds | `make test-integration`, `pytest -m integration`, `phpunit --testsuite=integration` |
| 5. Build | Compilation errors, missing assets, bundle failures | 10-120 seconds | `make build`, `npm run build`, `cargo build --release`, `docker build .` |
| 6. Smoke test | Obvious runtime failures after build | 10-60 seconds | `make smoke`, application-specific health check |

### When to Skip Steps

- **Skip integration tests** only if they require infrastructure you do not have locally (databases, external services) and CI will run them.
- **Skip the build step** if your language does not require a build (interpreted languages without a bundler).
- **Never skip lint, type check, or unit tests.** These are fast enough to always run.

---

## CI Parity

Local checks should mirror CI as closely as possible. If CI runs a check you do not run locally, you will push broken code and waste a CI cycle.

### Achieving Parity

```bash
# Option 1: Use the same Makefile targets locally and in CI
make ci          # runs lint, typecheck, test, build in sequence

# Option 2: Run the CI script directly
./scripts/ci.sh  # same script CI uses

# Option 3: Use a containerized environment
docker compose run --rm app make ci
```

### Common Parity Gaps

| Gap | Symptom | Fix |
|---|---|---|
| Different language version | Tests pass locally, fail in CI | Use `.tool-versions`, `Dockerfile`, or version manager to pin versions |
| Missing environment variables | Tests pass locally (vars in shell), fail in CI | Use `.env.test` or CI-specific config files |
| Different dependency versions | Behavior differs between local and CI | Always run `install` (not `update`) from the lock file |
| OS-specific behavior | Works on macOS, fails on Linux CI | Test in a container matching CI's OS |
| Database state | Tests pass on populated local DB, fail on clean CI DB | Always run from migrations, never assume existing data |

---

## Conflict Detection

Before pushing, verify your branch can merge cleanly into the target.

```bash
# Fetch latest target branch
git fetch origin main

# Check for conflicts without modifying your branch
git merge-tree $(git merge-base HEAD origin/main) HEAD origin/main

# Or: attempt a merge in a temporary index (dry run)
git merge --no-commit --no-ff origin/main
git merge --abort  # clean up the attempted merge
```

### Resolving Conflicts Before Push

```bash
# Option 1: Rebase onto the updated target (rewrites your commits)
git fetch origin main
git rebase origin/main
# Resolve conflicts per commit, then:
git rebase --continue

# Option 2: Merge the target into your branch (preserves history)
git fetch origin main
git merge origin/main
# Resolve conflicts, then:
git commit
```

After resolving conflicts, re-run the full verification suite. Conflict resolution can introduce bugs.

---

## Pre-Push Hook Setup

Automate verification so it runs on every `git push` without thinking about it.

### Using Git Hooks Directly

```bash
# .git/hooks/pre-push (must be executable: chmod +x)
#!/bin/sh

echo "Running pre-push checks..."

# Lint
make lint || exit 1

# Type check
make typecheck || exit 1

# Fast tests only (skip slow integration tests)
make test-unit || exit 1

echo "All pre-push checks passed."
```

### Using a Hook Manager

Hook managers make hooks portable across the team by storing configuration in the repository.

**Husky (Node.js projects):**

```json
// package.json
{
  "husky": {
    "hooks": {
      "pre-push": "npm run lint && npm run typecheck && npm test"
    }
  }
}
```

**Lefthook (language-agnostic):**

```yaml
# lefthook.yml
pre-push:
  parallel: false
  commands:
    lint:
      run: make lint
    typecheck:
      run: make typecheck
    test:
      run: make test-unit
```

**CaptainHook (PHP projects):**

```json
// captainhook.json
{
  "pre-push": {
    "actions": [
      {"action": "vendor/bin/phpstan analyse"},
      {"action": "vendor/bin/phpunit --testsuite=unit"}
    ]
  }
}
```

### Bypassing Hooks in Emergencies

```bash
# Skip pre-push hook (use sparingly and only with good reason)
git push --no-verify
```

This should be rare. If you find yourself bypassing hooks regularly, the hooks are too slow or too strict - fix the hooks, do not work around them.

---

## Checklist Before Every Push

- [ ] `git status` shows a clean working tree (all changes committed or stashed intentionally)
- [ ] Lint passes with zero errors
- [ ] Type checker passes with zero errors
- [ ] Unit tests pass
- [ ] Integration tests pass (or are confirmed to run in CI)
- [ ] Build succeeds (if applicable)
- [ ] No merge conflicts with the target branch
- [ ] No secrets or credentials in the diff
- [ ] Commit messages follow project conventions
- [ ] Branch is up to date with the target branch

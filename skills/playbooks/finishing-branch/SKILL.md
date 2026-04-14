---
name: finishing-branch
description: End-to-end workflow for finishing a development branch. Use when implementation is complete and the branch is ready to ship -- runs verification checks, reviews the diff, picks the integration path (direct merge, pull request, squash-and-merge, stacked PR), writes the PR/merge message, pushes to the remote, and cleans up branches and worktrees. Covers rebase vs merge vs squash decisions, pre-push checklists, stacked-branch handling, and recovery from common missteps like force-pushing the wrong branch or deleting an unmerged branch. Triggers: 'I'm done', 'ready to merge', 'ready to push', 'ready for review', 'wrap up this branch', 'finish this up'.
user-invocable: true
argument-hint: "[optional: branch name or PR target]"
---

# Finishing a Development Branch

The code is written. Tests are green locally. Now what? The gap between "done coding" and "merged to main" is where branches rot, conflicts accumulate, and mistakes happen. This playbook is the systematic bridge: verify, review, integrate, clean up. Every time, in order, nothing skipped.

**Never push without green. Never merge without review evidence.**

## When to Use

- Implementation is complete and you are ready to integrate
- You need to decide between merge, squash, rebase, or PR
- A branch has been sitting and needs to be wrapped up
- You are finishing work in a worktree and need to clean up
- You are managing stacked branches and need to land them in order

## Quick Start

```bash
# Verify everything passes
git diff --stat main...HEAD
make test && make lint && make typecheck

# Push and open a PR (adjust target as needed)
git push -u origin HEAD
gh pr create --fill
```

If you need more control, follow the phases below.

---

## Phase 1: Working-Tree Sanity

Before anything else, ensure the working tree is in a known-good state.

```bash
# Check for uncommitted changes
git status

# Check for forgotten stashes
git stash list

# Ensure you are on the right branch
git branch --show-current

# Verify upstream tracking is set
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

| Check | Pass Condition | Fix |
|---|---|---|
| No uncommitted changes | `git status` shows clean tree | Commit or stash intentionally |
| No orphaned stashes | `git stash list` is empty or all stashes are accounted for | Apply or drop stale stashes |
| Correct branch | Branch name matches your work | `git checkout <branch>` |
| Upstream set | Tracking branch exists | `git push -u origin HEAD` on first push |
| No untracked noise | No generated files, build artifacts, or editor files | Add to `.gitignore` or remove |

---

## Phase 2: Pre-Push Verification

Run the full verification suite before pushing. Order matters -- fail fast on the cheapest checks first.

```bash
# 1. Lint (fastest, catches formatting/style issues)
make lint            # or: npm run lint, cargo clippy, flake8, etc.

# 2. Type checking (catches type errors without running code)
make typecheck       # or: npx tsc --noEmit, mypy, phpstan, etc.

# 3. Unit tests (fast feedback on logic correctness)
make test            # or: npm test, pytest, phpunit, cargo test, etc.

# 4. Integration / end-to-end tests (slower, catches wiring issues)
make test-integration

# 5. Build (ensures the artifact compiles / bundles cleanly)
make build           # or: npm run build, cargo build --release, etc.
```

If any step fails, stop and fix before proceeding. Do not push broken code.

See [Pre-Push Checks Reference](references/pre-push-checks.md) for the full verification order, CI parity tips, and conflict detection.

---

## Phase 3: Diff Review

Self-review the full diff before handing it to others. You will catch things automated tools miss.

```bash
# Full diff against the target branch
git diff main...HEAD

# Commit-by-commit review (more granular)
git log --oneline main..HEAD
git show <commit-hash>

# Stat summary (spot unexpectedly large changes)
git diff --stat main...HEAD

# Check for secrets or sensitive data
git diff main...HEAD | grep -iE '(password|secret|token|api.key|private.key)' || true
```

### Self-Review Checklist

- [ ] No debug code left behind (`console.log`, `dd()`, `print_r`, `var_dump`, `TODO`)
- [ ] No commented-out code that should be deleted
- [ ] No secrets, tokens, or credentials in the diff
- [ ] No unrelated changes mixed into the branch
- [ ] Commit messages are clear and follow project conventions
- [ ] New files are in the correct directories
- [ ] Tests cover the changes (not just existing tests passing)

---

## Phase 4: Integration Strategy Selection

Choose how to integrate based on your team's workflow, the branch's history, and the target branch.

| Strategy | When to Use | Command |
|---|---|---|
| **Pull Request** | Team requires review, CI gates, or audit trail | Push + open PR (see Phase 6) |
| **Direct merge** | Trunk-based, solo project, or pre-approved change | `git checkout main && git merge --no-ff <branch>` |
| **Squash and merge** | Branch has messy intermediate commits | Via PR settings, or: `git merge --squash <branch>` |
| **Rebase and merge** | Linear history desired, clean commit discipline | `git rebase main && git checkout main && git merge --ff-only <branch>` |
| **Stacked PR** | Branch builds on another unmerged branch | Push + open PR targeting parent branch |

See [Integration Strategies Reference](references/integration-strategies.md) for the full decision matrix, rebase vs merge trade-offs, and stacked PR workflow.

---

## Phase 5: Message Writing

Write a clear, structured message whether you are creating a PR or a merge commit.

### PR Message Structure

```
## Summary
What changed and why (1-3 sentences).

## Changes
- Bullet list of specific changes

## Test Plan
- How to verify the changes work

## Risks
- What could go wrong, migration notes, rollback considerations

## Linked Tickets
- PROJ-123
```

For comprehensive PR messages, use the `pr-message-writer` skill which provides templates, structured sections, and verification queries.

See [PR Message Template Reference](references/pr-message-template.md) for the full template and guidance on writing effective messages.

---

## Phase 6: Push and PR Creation

### Push to Remote

```bash
# First push (sets upstream tracking)
git push -u origin HEAD

# Subsequent pushes
git push

# After rebase (use --force-with-lease, never --force)
git push --force-with-lease
```

### Open a Pull Request

**GitHub:**

```bash
# Basic PR
gh pr create --title "feat: add user email verification" --body-file pr-description.md

# PR targeting a specific branch (for stacked PRs)
gh pr create --base feat/parent-branch --title "feat: add verification UI"

# Draft PR (not ready for review yet)
gh pr create --draft --fill
```

**GitLab:**

```bash
glab mr create --title "feat: add user email verification" --description-file pr-description.md

# Target a specific branch
glab mr create --target-branch feat/parent-branch

# Draft MR
glab mr create --draft
```

**Bitbucket:**

```bash
# Using Bitbucket's REST API via curl
curl -X POST -H "Content-Type: application/json" \
  "https://api.bitbucket.org/2.0/repositories/{workspace}/{repo}/pullrequests" \
  -d '{"title": "feat: add email verification", "source": {"branch": {"name": "feat/email-verification"}}, "destination": {"branch": {"name": "main"}}}'
```

### Direct Merge (No PR)

```bash
# Fetch latest and merge with a merge commit
git checkout main
git pull
git merge --no-ff feat/my-branch -m "Merge feat/my-branch: add user email verification"

# Push main
git push
```

---

## Phase 7: Cleanup

After the branch is merged, clean up local and remote references.

```bash
# Delete the local branch
git branch -d feat/my-branch

# Delete the remote branch (if not auto-deleted by PR merge)
git push origin --delete feat/my-branch

# Prune remote tracking references
git fetch --prune

# If working in a worktree, remove it
git worktree remove /path/to/worktree
```

See [Cleanup Commands Reference](references/cleanup-commands.md) for pruning stale branches, worktree cleanup, and upstream maintenance.

---

## Recovery

Common mistakes and how to fix them.

| Mistake | Recovery |
|---|---|
| Force-pushed the wrong branch | `git reflog` to find the pre-push commit, then `git push --force-with-lease origin <sha>:<branch>` |
| Deleted an unmerged branch | `git reflog` to find the tip, then `git checkout -b <branch> <sha>` |
| Pushed secrets to remote | Rotate the secret immediately, then `git filter-repo` to purge from history |
| Merged to wrong target branch | `git revert -m 1 <merge-commit>` on the wrong target, then merge to the correct one |
| Rebase went wrong mid-way | `git rebase --abort` to return to pre-rebase state |
| Lost work after worktree removal | `git reflog` -- commits survive worktree deletion if they were committed |
| PR targets wrong base branch | Update the PR's base branch in the hosting platform UI or CLI |

See [Recovery Reference](references/recovery.md) for detailed walkthroughs of each recovery scenario.

---

## Quality Checklist

Run through this before considering the branch done.

- [ ] All tests pass (unit, integration, e2e as applicable)
- [ ] Linter and type checker report no errors
- [ ] Build completes without warnings
- [ ] Self-reviewed the full diff -- no debug code, secrets, or unrelated changes
- [ ] Commit messages follow project conventions
- [ ] PR description explains what, why, and how to verify
- [ ] Target branch is correct
- [ ] Branch is up to date with the target (rebased or merged)
- [ ] CI pipeline passes on the remote
- [ ] Reviewer(s) assigned (if PR workflow)
- [ ] Local branch and worktree cleaned up after merge

---

## Critical Rules

1. **Never force-push to main, master, or any shared long-lived branch.** Use `--force-with-lease` on feature branches only.
2. **Never skip verification.** A single untested push can break the pipeline for the entire team.
3. **Never delete an unmerged branch without explicit confirmation.** Recover with `git reflog` if it happens accidentally.
4. **Never push secrets.** Check the diff before every push. Rotate immediately if it happens.
5. **Always use `--force-with-lease` instead of `--force`.** It prevents overwriting someone else's work on a shared branch.
6. **Always clean up after merge.** Stale branches and orphaned worktrees accumulate and cause confusion.
7. **Always write a meaningful PR/merge message.** "Fix stuff" helps nobody -- explain what changed and why.
8. **Rebase only your own branches.** Rebasing shared branches rewrites history others depend on.

---

## Reference Files

| Reference | Contents |
|---|---|
| [Pre-Push Checks](references/pre-push-checks.md) | Verification command order, CI parity, conflict detection, pre-push hook setup |
| [Integration Strategies](references/integration-strategies.md) | Merge vs rebase vs squash decision matrix, stacked PRs, when each strategy fits |
| [PR Message Template](references/pr-message-template.md) | Structured PR template, writing guidance, cross-reference to `pr-message-writer` skill |
| [Cleanup Commands](references/cleanup-commands.md) | Branch pruning, worktree removal, upstream cleanup, batch operations |
| [Recovery](references/recovery.md) | Detailed recovery walkthroughs for force-push, deleted branch, lost stash, bad merge |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Writing a comprehensive PR message | `pr-message-writer` |
| Reviewing code before merging | `code-review-excellence` |
| Managing git worktrees | `worktree-start`, `worktree-list`, `worktree-switch`, `worktree-clean` |
| Choosing a branching strategy | `git-workflow` |
| Running verification before declaring done | `verification-before-completion` |
| Requesting a structured code review | `requesting-code-review` |

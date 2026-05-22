# Integration Strategies

Choosing the right integration strategy determines the shape of your history, the ease of reverting changes, and how much friction the team experiences during code review. There is no universally correct answer - the right choice depends on team size, release model, and commit discipline.

## Strategy Overview

### Direct Merge (--no-ff)

Creates a merge commit that preserves the branch's commit history as a visible branch in the graph.

```bash
git checkout main
git pull origin main
git merge --no-ff feat/my-branch -m "Merge feat/my-branch: add email verification"
git push origin main
```

**Pros:** Full history preserved. Easy to revert entire feature by reverting the merge commit. Branch topology visible in `git log --graph`.

**Cons:** Noisy history with many merge commits. Harder to bisect. History graph becomes complex with many parallel branches.

**Best for:** Open-source projects with audit requirements, teams that value seeing exactly how work was developed.

---

### Squash and Merge

Collapses all branch commits into a single commit on the target branch.

```bash
# Via command line
git checkout main
git pull origin main
git merge --squash feat/my-branch
git commit -m "feat: add email verification (#42)"
git push origin main

# Via PR (most hosting platforms support "Squash and merge" button)
```

**Pros:** Clean, linear history. Each commit on main represents one complete, reviewed change. Excellent for `git bisect`.

**Cons:** Loses individual commit attribution. Intermediate development steps are invisible. Cannot cherry-pick individual changes from the branch after squashing.

**Best for:** Teams where feature branches have messy, work-in-progress commits. Teams that want one commit per PR on main.

---

### Rebase and Merge (Fast-Forward)

Replays your branch commits on top of the target branch tip, then fast-forwards the target branch pointer.

```bash
git checkout feat/my-branch
git fetch origin main
git rebase origin/main

# Resolve any conflicts per commit
# After successful rebase:
git checkout main
git merge --ff-only feat/my-branch
git push origin main
```

**Pros:** Linear history with individual commits preserved. No merge commits. Clean `git log`. Good for `git bisect`.

**Cons:** Rewrites commit hashes (breaks references to old SHAs). Requires clean commit discipline - every commit should compile and pass tests. Conflicts must be resolved per commit during rebase.

**Best for:** Teams with strong commit discipline who want linear history without losing individual commits.

---

### Pull Request (Any Merge Strategy)

Push the branch to the remote and open a PR/MR for review. The merge strategy is then applied when the PR is approved.

```bash
git push -u origin feat/my-branch
# Open PR via CLI or web UI (see Phase 6 in SKILL.md)
```

The hosting platform applies the configured merge strategy (merge commit, squash, or rebase) when the PR is merged. Most teams configure a default and allow authors to choose per PR.

**Best for:** Any team that requires code review, CI gates, or an audit trail of approvals.

---

## Decision Matrix

Use this matrix to pick the right strategy for your situation.

| Factor | Direct Merge | Squash | Rebase | PR (any) |
|---|---|---|---|---|
| Requires code review | No | No | No | Yes |
| Preserves individual commits | Yes | No | Yes | Depends on merge strategy |
| Linear history | No | Yes | Yes | Depends on merge strategy |
| Easy to revert entire feature | Yes (revert merge) | Yes (revert single commit) | Harder (revert each commit) | Depends on merge strategy |
| Commit discipline required | Low | Low | High | Low-High (depends) |
| CI gate enforcement | No (manual) | No (manual) | No (manual) | Yes (automated) |
| Works with stacked branches | Awkward | No (destroys intermediate SHAs) | Yes (with care) | Yes |

### Quick Decision Guide

1. **Does the team require review before merge?** - Use a PR workflow with your preferred merge strategy.
2. **Is the branch history clean and meaningful?** - Use rebase and merge to preserve commits linearly.
3. **Is the branch history messy with WIP commits?** - Use squash and merge to collapse into one clean commit.
4. **Do you need to see branch topology in the graph?** - Use direct merge with `--no-ff`.
5. **Solo project or pre-approved change?** - Direct merge or rebase, depending on history preference.

---

## Rebase vs Merge: When to Use Each

### Use Rebase When

- You are the only author on the branch
- The branch has not been shared with others (or others are not basing work on it)
- You want a linear history without merge commits
- You need to clean up commits before merging (interactive rebase)

### Use Merge When

- The branch is shared and others have based work on it
- You need to preserve the exact branch topology for audit purposes
- You want easy single-commit reverts of entire features
- The team is not comfortable with rebase workflows

### The Golden Rule of Rebase

**Never rebase commits that exist on a remote branch that others are working from.** Rebasing rewrites commit hashes. If someone else has based work on the old hashes, their history will diverge and they will need to force-reconcile.

```bash
# Safe: rebase your local-only commits onto updated main
git fetch origin main
git rebase origin/main

# Safe: rebase and force-push YOUR OWN feature branch
git push --force-with-lease origin feat/my-branch

# DANGEROUS: rebase a branch others have checked out
# This rewrites shared history - do not do this
```

---

## Stacked PRs

Stacked PRs break a large feature into a chain of dependent pull requests. Each PR builds on the previous one and is reviewable independently.

### When to Stack

- The full feature would produce a PR over 400 lines
- Changes span multiple layers (database, service, API, UI)
- Earlier parts can be reviewed and merged independently
- The team is comfortable with rebase workflows

### Workflow

```bash
# PR 1: Foundation layer
git checkout main
git checkout -b feat/user-validation-extract
# ... implement and commit ...
git push -u origin feat/user-validation-extract
# Open PR #1 targeting main

# PR 2: Build on PR 1
git checkout -b feat/user-email-verification
# ... implement and commit ...
git push -u origin feat/user-email-verification
# Open PR #2 targeting feat/user-validation-extract (not main)

# PR 3: Build on PR 2
git checkout -b feat/user-verification-ui
# ... implement and commit ...
git push -u origin feat/user-verification-ui
# Open PR #3 targeting feat/user-email-verification
```

### Maintaining the Stack

When a reviewer requests changes to an earlier PR:

```bash
# Fix the issue on the base PR
git checkout feat/user-validation-extract
# ... make fixes, commit ...
git push

# Rebase downstream branches onto the updated base
git checkout feat/user-email-verification
git rebase feat/user-validation-extract
git push --force-with-lease

git checkout feat/user-verification-ui
git rebase feat/user-email-verification
git push --force-with-lease
```

### After the Base PR Merges

```bash
# Update main
git checkout main
git pull

# Rebase the next PR onto main and retarget the PR
git checkout feat/user-email-verification
git rebase main
git push --force-with-lease

# Update the PR's base branch to main (via hosting platform CLI or UI)
# GitHub:
gh pr edit <pr-number> --base main
# GitLab:
glab mr update <mr-number> --target-branch main
```

### Pitfalls

- **Squash-merging breaks the stack.** If the base PR is squash-merged, downstream branches still reference the old individual commits. You must rebase onto main after squash. Prefer merge commits or rebase-merge for stacked workflows.
- **Review burden shifts.** Each PR is small, but reviewers must understand the full context. Include a link to the overall design in each PR description.
- **Force-push cascades.** A change to PR 1 requires rebasing PR 2 and PR 3. Automate this or accept the overhead.

---

## Handling Upstream Changes

Before integrating, ensure your branch is current with the target.

```bash
# Option 1: Rebase (produces linear history)
git fetch origin main
git rebase origin/main
# Re-run verification after rebase

# Option 2: Merge target into branch (preserves topology)
git fetch origin main
git merge origin/main
# Re-run verification after merge
```

After either operation, re-run the full verification suite. Merging or rebasing can introduce subtle bugs even without textual conflicts - a clean merge does not guarantee correct behavior.

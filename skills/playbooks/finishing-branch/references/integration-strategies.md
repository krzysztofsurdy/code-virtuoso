# Integration Strategies

The integration strategy decides the shape of your history, how easy it is to revert a change, and how much friction the team feels during code review. No answer is right everywhere. The best choice depends on team size, release model, and commit discipline.

## Contents

- [Strategy overview](#strategy-overview)
- [Decision matrix](#decision-matrix)
- [Choosing the merge strategy](#choosing-the-merge-strategy)
- [Rebase vs merge: when to use each](#rebase-vs-merge-when-to-use-each)
- [Stacked PRs](#stacked-prs)
- [Branching model context](#branching-model-context)
- [Handling upstream changes](#handling-upstream-changes)

## Strategy overview

### Direct merge (--no-ff)

Creates a merge commit that keeps the branch's commit history visible as a branch in the graph.

```bash
git checkout main
git pull origin main
git merge --no-ff feat/my-branch -m "Merge feat/my-branch: add email verification"
git push origin main
```

**Pros:** Full history is preserved. You can revert the whole feature by reverting the merge commit. Branch topology is visible in `git log --graph`.

**Cons:** Many merge commits make the history noisy and harder to bisect. The graph gets complex with many parallel branches.

**Best for:** Open-source projects with audit requirements, and teams that want to see exactly how work was developed.

---

### Squash and merge

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

**Pros:** Clean, linear history. Each commit on main is one complete, reviewed change. Works well with `git bisect`.

**Cons:** Individual commit attribution is lost. Intermediate development steps are invisible. After squashing, you cannot cherry-pick individual changes from the branch.

**Best for:** Teams whose feature branches have messy, work-in-progress commits, and teams that want one commit per PR on main.

---

### Rebase and merge (fast-forward)

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

**Cons:** Commit hashes change, which breaks references to old SHAs. Every commit should compile and pass tests. Conflicts must be resolved per commit during the rebase.

**Best for:** Teams with strong commit discipline who want linear history and keep their individual commits.

---

### Pull request (any merge strategy)

Push the branch to the remote and open a PR/MR for review. The merge strategy is applied when the PR is approved.

```bash
git push -u origin feat/my-branch
# Open PR via CLI or web UI (see Phase 6 in SKILL.md)
```

The hosting platform applies the configured merge strategy (merge commit, squash, or rebase) when the PR is merged. Most teams set a default and let authors choose per PR.

**Best for:** Any team that requires code review, CI gates, or an audit trail of approvals.

---

## Decision matrix

Use this matrix to pick the right strategy for your situation.

| Factor | Direct merge | Squash | Rebase | PR (any) |
|---|---|---|---|---|
| Requires code review | No | No | No | Yes |
| Preserves individual commits | Yes | No | Yes | Depends on merge strategy |
| Linear history | No | Yes | Yes | Depends on merge strategy |
| Easy to revert entire feature | Yes (revert merge) | Yes (revert single commit) | Harder (revert each commit) | Depends on merge strategy |
| Commit discipline required | Low | Low | High | Low-High (depends) |
| CI gate enforcement | No (manual) | No (manual) | No (manual) | Yes (automated) |
| Works with stacked branches | Awkward | No (destroys intermediate SHAs) | Yes (with care) | Yes |

### Quick decision guide

1. **Does the team require review before merge?** Use a PR workflow with your preferred merge strategy.
2. **Is the branch history clean and meaningful?** Use rebase and merge to keep the commits in a line.
3. **Is the branch history messy with WIP commits?** Use squash and merge to collapse it into one clean commit.
4. **Do you need to see branch topology in the graph?** Use direct merge with `--no-ff`.
5. **Solo project or pre-approved change?** Use direct merge or rebase, depending on your history preference.

---

## Choosing the merge strategy

Check the repository settings first: the platform often allows only some strategies, and the project's default is the answer unless you have a reason.

| Situation | Use | Why |
|---|---|---|
| Commits are WIP, fixups, or review churn | Squash | One clean commit on the target. Write the squash message by hand |
| Each commit is atomic, builds, and has a good message | Rebase and merge | Keeps useful history, stays linear |
| Long-running or shared branch, audit trail needed | Merge commit | Preserves topology, reverts as one unit |
| Branch is the base of a stack | Merge commit or rebase, not squash | Squash rewrites the base, so downstream branches need a rebase |
| Hotfix on a release line | Rebase or cherry-pick, then merge forward | Keeps the fix small and traceable |

Rules of thumb: squash is the safe default for feature branches; never squash a branch you still plan to build on; after a squash merge, delete the branch instead of reusing it.

---

## Rebase vs merge: when to use each

### Use rebase when

- You are the only author on the branch
- The branch has not been shared with others (or others are not basing work on it)
- You want a linear history without merge commits
- You need to clean up commits before merging (interactive rebase)

### Use merge when

- The branch is shared and others have based work on it
- You need to keep the exact branch topology for audit purposes
- You want to revert a whole feature with a single commit
- The team is not comfortable with rebase workflows

### The golden rule of rebase

**Never rebase commits that exist on a remote branch that others are working from.** Rebasing rewrites commit hashes. If someone else has based work on the old hashes, their history diverges and they have to reconcile it by force.

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

Stacked PRs break a large feature into a chain of dependent pull requests. Each PR builds on the previous one and can be reviewed on its own.

### When to stack

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

### Maintaining the stack

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

### After the base PR merges

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

- **Squash-merging breaks the stack.** If the base PR is squash-merged, downstream branches still reference the old individual commits. You must rebase onto main after the squash. Prefer merge commits or rebase-merge for stacked workflows.
- **Review burden shifts.** Each PR is small, but reviewers must understand the full context. Link the overall design in each PR description.
- **Force-push cascades.** A change to PR 1 requires rebasing PR 2 and PR 3. Automate this or accept the overhead.

---

## Branching model context

The model sets the target branch and how long a branch may live. Use the repository's model; do not change it while finishing a branch.

| Model | Target of your PR | Branch lifetime | Release |
|---|---|---|---|
| Trunk-based | `main` | Hours to a day, flags hide unfinished work | Every merge |
| GitHub Flow | `main` | Days | Every merge |
| Git Flow | `develop` (hotfixes go to `main` and `develop`) | Days to weeks | Release branches |
| GitLab Flow | `main`, promoted to environment branches | Days | Environment promotion |

If you are unsure of the target, read the contributing guide or ask. A PR against the wrong base is a common avoidable mistake.

---

## Handling upstream changes

Before integrating, bring your branch up to date with the target.

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

After either operation, re-run the full verification suite. A merge or rebase can introduce subtle bugs even without textual conflicts, because a clean merge does not guarantee correct behavior.

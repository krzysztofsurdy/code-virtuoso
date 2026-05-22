# Recovery

Things go wrong. Branches get force-pushed, unmerged work gets deleted, rebases go sideways. Git is designed to be recoverable - almost nothing is truly lost if you know where to look. The reflog is your safety net.

## Understanding the Reflog

The reflog records every change to every branch tip and HEAD in your local repository. Even after a branch is deleted, the commits it pointed to remain in the reflog for at least 30 days.

```bash
# View the reflog for HEAD (all recent operations)
git reflog

# View the reflog for a specific branch
git reflog show feat/my-branch

# Search the reflog by commit message
git reflog --all --grep="the commit message"

# View reflog with timestamps
git reflog --date=iso
```

**Key principle:** If it was committed, it is recoverable from the reflog. If it was only in the working directory (never committed or stashed), it is gone.

---

## Recovery Scenarios

### Force-Pushed the Wrong Branch

You ran `git push --force` and overwrote commits on a branch - either your own or someone else's.

**If you overwrote your own branch:**

```bash
# Find the commit before the force push
git reflog show feat/my-branch

# Output example:
# abc1234 feat/my-branch@{0}: push (force): updating HEAD   <-- after force push
# def5678 feat/my-branch@{1}: commit: implement feature      <-- before force push

# Reset the remote to the correct commit
git push --force-with-lease origin def5678:feat/my-branch
```

**If you overwrote a shared branch (main, develop):**

```bash
# CRITICAL: Act immediately. Others may pull the broken state.

# Find the correct commit from reflog
git reflog show main

# Force-push the correct commit back
git push --force-with-lease origin <correct-sha>:main

# Notify the team to reset their local main
# They should run:
git fetch origin
git reset --hard origin/main
```

**Prevention:** Always use `--force-with-lease` instead of `--force`. It refuses to push if the remote has commits you have not fetched, preventing accidental overwrites.

---

### Deleted an Unmerged Branch

You ran `git branch -D feat/important-work` and the branch had commits not merged anywhere.

```bash
# Find the branch tip in the reflog
git reflog | grep "feat/important-work"

# If the branch name does not appear, search by recent checkouts
git reflog | grep "checkout: moving from feat/important-work"

# Or look at all reflog entries from around the time of deletion
git reflog --date=iso | head -30

# Recreate the branch at the recovered commit
git checkout -b feat/important-work <sha>

# Verify the recovered branch has the expected content
git log --oneline feat/important-work
```

**If the reflog does not help** (e.g., the branch was on a different machine):

```bash
# Search for dangling commits (commits not reachable from any branch)
git fsck --no-reflogs --unreachable | grep commit

# Inspect each dangling commit to find yours
git show <sha>

# Recreate the branch
git checkout -b feat/important-work <sha>
```

---

### Lost a Stash

You ran `git stash drop` or `git stash clear` and lost work.

```bash
# Find dangling commits that look like stash entries
git fsck --no-reflogs --unreachable | grep commit

# Stash entries are merge commits with a specific structure
# Inspect candidates:
git show <sha>

# Apply the recovered stash
git stash apply <sha>
```

**Prevention:** Prefer committing WIP changes on a branch over stashing. Branches are easier to track and recover.

---

### Rebase Went Wrong

A rebase is producing conflicts on every commit and you want to start over.

**During the rebase (before completing):**

```bash
# Abort the rebase entirely - returns to pre-rebase state
git rebase --abort
```

**After completing a bad rebase:**

```bash
# Find the pre-rebase state in the reflog
git reflog

# Output example:
# abc1234 HEAD@{0}: rebase (finish): ...
# def5678 HEAD@{1}: rebase (pick): ...
# ghi9012 HEAD@{2}: rebase (start): ...
# jkl3456 HEAD@{3}: checkout: moving from feat/my-branch  <-- pre-rebase

# Reset to the pre-rebase commit
git reset --hard jkl3456

# If the branch was already pushed with the bad rebase
git push --force-with-lease origin feat/my-branch
```

---

### Merged to the Wrong Target Branch

You merged your feature branch into `develop` instead of `main` (or vice versa).

**If the merge has not been pushed:**

```bash
# Undo the merge commit (reset the target branch to before the merge)
git checkout develop
git reset --hard HEAD~1

# Now merge into the correct branch
git checkout main
git merge --no-ff feat/my-branch
```

**If the merge has been pushed:**

```bash
# Revert the merge on the wrong branch (creates a new commit that undoes the merge)
git checkout develop
git revert -m 1 <merge-commit-sha>
git push

# Merge into the correct branch
git checkout main
git merge --no-ff feat/my-branch
git push
```

Note: `-m 1` tells `git revert` to treat the first parent (the target branch before merge) as the mainline.

---

### Accidentally Reset --hard and Lost Uncommitted Changes

You ran `git reset --hard` and lost changes that were staged but not committed.

**For staged changes (added with `git add`):**

```bash
# Staged file contents are stored as blobs in the object database
git fsck --lost-found

# Look in .git/lost-found/other/ for recovered blobs
ls .git/lost-found/other/

# Inspect each blob to find your content
git show <blob-sha>

# Redirect to a file
git show <blob-sha> > recovered-file.ext
```

**For unstaged changes (never added or committed):** These are gone. Git only tracks content that has been staged or committed.

**Prevention:** Commit early and often. Even a `git commit -m "WIP"` is recoverable; unstaged edits are not.

---

### PR Branch Diverged from Base After Force-Push

You rebased and force-pushed your PR branch. Now the PR shows unexpected changes because the base branch has moved.

```bash
# Update your branch to be based on the latest target
git fetch origin main
git rebase origin/main
git push --force-with-lease

# If the PR diff still looks wrong, check the merge base
git merge-base HEAD origin/main
```

On most hosting platforms, the PR will recalculate the diff after the force-push. If it does not, close and reopen the PR.

---

## Recovery Checklist

When something goes wrong:

1. **Do not panic.** If it was committed, it is almost certainly recoverable.
2. **Stop executing commands.** Do not compound the mistake with more actions.
3. **Check the reflog** - `git reflog` is always the first step.
4. **Identify the target commit** - the SHA of the state you want to return to.
5. **Restore the state** - `git reset`, `git checkout -b`, or `git push --force-with-lease` as appropriate.
6. **Verify the recovery** - check `git log`, `git diff`, and run tests.
7. **Communicate** - if the mistake affected a shared branch, notify the team immediately.

## Reflog Expiry

By default, reflog entries expire after 90 days (reachable commits) or 30 days (unreachable commits). After expiry, commits may be garbage collected and become unrecoverable.

```bash
# Check current reflog expiry settings
git config gc.reflogExpire          # default: 90 days
git config gc.reflogExpireUnreachable  # default: 30 days

# Extend if needed (e.g., for safety on critical repositories)
git config gc.reflogExpireUnreachable "90 days"
```

To force garbage collection (rarely needed, and risky if you have unrecovered work):

```bash
git gc --prune=now  # CAUTION: removes unreachable objects immediately
```

# Cleanup Commands

After a branch is merged, leftovers pile up: local branches that no longer exist on the remote, remote tracking branches for deleted remotes, orphaned worktrees, and upstream configurations that point nowhere. Regular cleanup avoids confusion and keeps the local repository small.

## Contents

- [Branch cleanup](#branch-cleanup)
- [Worktree cleanup](#worktree-cleanup)
- [Upstream cleanup](#upstream-cleanup)
- [Batch cleanup operations](#batch-cleanup-operations)
- [Recovering from cleanup mistakes](#recovering-from-cleanup-mistakes)
- [Configuration for automatic cleanup](#configuration-for-automatic-cleanup)

## Branch cleanup

### Delete a single merged branch

```bash
# Delete local branch (safe - refuses if branch has unmerged commits)
git branch -d feat/my-branch

# Delete remote branch
git push origin --delete feat/my-branch
```

### Delete all merged local branches

```bash
# List branches merged into main (excluding main itself and current branch)
git branch --merged main | grep -vE '^\*|main|master|develop' 

# Delete them (review the list first)
git branch --merged main | grep -vE '^\*|main|master|develop' | xargs git branch -d
```

### Prune remote tracking references

Remote branches that were deleted on the server still appear locally as `origin/feat/old-branch` until you prune them.

```bash
# Remove stale remote tracking branches
git fetch --prune

# Or set auto-prune globally
git config --global fetch.prune true

# Verify: list all remote tracking branches
git branch -r
```

### Find branches that were never merged

```bash
# List branches NOT merged into main
git branch --no-merged main

# Review carefully before deleting - these have unmerged work
# Use -D (uppercase) to force delete, but only after confirming the work is not needed
git branch -D feat/abandoned-experiment
```

---

## Worktree cleanup

Worktrees are lightweight checkouts that share one repository. If a worktree directory is deleted without `git worktree remove`, stale metadata stays behind.

### Remove a specific worktree

```bash
# Clean removal (removes the directory and metadata)
git worktree remove /path/to/worktree

# Force removal if the worktree has uncommitted changes
git worktree remove --force /path/to/worktree
```

### List all worktrees

```bash
git worktree list
```

The output shows the path, HEAD commit, and branch for each worktree.

### Prune stale worktree metadata

If a worktree directory was deleted by hand (e.g., `rm -rf`), the metadata in `.git/worktrees/` becomes stale.

```bash
# Dry run: see what would be pruned
git worktree prune --dry-run

# Prune stale entries
git worktree prune
```

### Clean up all worktrees after a feature

```bash
# List worktrees to identify which to remove
git worktree list

# Remove each finished worktree
git worktree remove /path/to/worktree-1
git worktree remove /path/to/worktree-2

# Prune any stale metadata
git worktree prune
```

---

## Upstream cleanup

### Remove a stale upstream tracking reference

If a remote branch was deleted but your local branch still tracks it:

```bash
# Check what the current branch tracks
git rev-parse --abbrev-ref --symbolic-full-name @{u}

# Unset the upstream reference
git branch --unset-upstream feat/my-branch
```

### Remove a remote entirely

If a fork or temporary remote is no longer needed:

```bash
# List all remotes
git remote -v

# Remove a remote
git remote remove fork-origin
```

---

## Batch cleanup operations

### Full post-merge cleanup sequence

Run this after merging a feature branch:

```bash
# 1. Switch to main and pull latest
git checkout main
git pull

# 2. Delete the merged local branch
git branch -d feat/my-branch

# 3. Delete the remote branch (if not auto-deleted by PR merge)
git push origin --delete feat/my-branch

# 4. Prune all stale remote tracking references
git fetch --prune

# 5. Remove the worktree if one was used
git worktree remove /path/to/worktree 2>/dev/null || true

# 6. Prune stale worktree metadata
git worktree prune
```

### Weekly maintenance sweep

Run periodically so leftovers do not build up:

```bash
# Prune remote references
git fetch --prune

# Show merged branches that can be safely deleted
echo "=== Merged branches (safe to delete) ==="
git branch --merged main | grep -vE '^\*|main|master|develop'

# Show stale worktrees
echo "=== Stale worktrees ==="
git worktree prune --dry-run

# Show branches with no remote counterpart
echo "=== Local branches with no remote ==="
git branch -vv | grep ': gone]'

# Delete local branches whose remote was already deleted
git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d
```

---

## Recovering from cleanup mistakes

### Accidentally deleted an unmerged branch

A branch is only a pointer to a commit. The commits stay in the reflog for at least 30 days (default `gc.reflogExpire`).

```bash
# Find the commit the branch pointed to
git reflog | grep "feat/accidentally-deleted"

# Or search by commit message
git reflog --all | grep "the commit message"

# Recreate the branch at that commit
git checkout -b feat/accidentally-deleted <sha>
```

### Accidentally removed a worktree with uncommitted changes

If the changes were committed, they are in the reflog and you can recover them. Uncommitted changes (only in the working directory) are lost, so always commit or stash before removing a worktree.

```bash
# Find commits that were in the worktree
git reflog --all

# Recreate the branch if it was deleted with the worktree
git checkout -b recovered-branch <sha>
```

### Accidentally deleted a remote branch

If the remote branch is gone but the local branch still exists:

```bash
# Push the local branch back to the remote
git push -u origin feat/my-branch
```

If both local and remote are gone, recreate the local branch with the reflog method above, then push.

---

## Configuration for automatic cleanup

### Auto-prune on fetch

```bash
git config --global fetch.prune true
```

### Auto-delete remote branch on PR merge

Most hosting platforms support this:

- **GitHub:** Repository Settings > General > "Automatically delete head branches"
- **GitLab:** Project Settings > Merge Requests > "Enable 'Delete source branch' option by default"
- **Bitbucket:** Repository Settings > Merge Strategies > "Close source branch"

With auto-delete on, manual cleanup is limited to local branches and worktrees.

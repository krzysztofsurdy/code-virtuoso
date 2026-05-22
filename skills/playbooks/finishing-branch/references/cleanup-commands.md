# Cleanup Commands

After a branch is merged, leftover references accumulate: local branches that no longer exist on the remote, remote tracking branches for deleted remotes, orphaned worktrees, and upstream configurations that point nowhere. Regular cleanup prevents confusion and keeps the local repository lean.

## Branch Cleanup

### Delete a Single Merged Branch

```bash
# Delete local branch (safe - refuses if branch has unmerged commits)
git branch -d feat/my-branch

# Delete remote branch
git push origin --delete feat/my-branch
```

### Delete All Merged Local Branches

```bash
# List branches merged into main (excluding main itself and current branch)
git branch --merged main | grep -vE '^\*|main|master|develop' 

# Delete them (review the list first)
git branch --merged main | grep -vE '^\*|main|master|develop' | xargs git branch -d
```

### Prune Remote Tracking References

Remote branches that were deleted on the server still appear locally as `origin/feat/old-branch` until pruned.

```bash
# Remove stale remote tracking branches
git fetch --prune

# Or set auto-prune globally
git config --global fetch.prune true

# Verify: list all remote tracking branches
git branch -r
```

### Find Branches That Were Never Merged

```bash
# List branches NOT merged into main
git branch --no-merged main

# Review carefully before deleting - these have unmerged work
# Use -D (uppercase) to force delete, but only after confirming the work is not needed
git branch -D feat/abandoned-experiment
```

---

## Worktree Cleanup

Worktrees are lightweight checkouts that share the same repository. Orphaned worktrees (where the directory was deleted without `git worktree remove`) leave stale metadata.

### Remove a Specific Worktree

```bash
# Clean removal (removes the directory and metadata)
git worktree remove /path/to/worktree

# Force removal if the worktree has uncommitted changes
git worktree remove --force /path/to/worktree
```

### List All Worktrees

```bash
git worktree list
```

Output shows the path, HEAD commit, and branch for each worktree.

### Prune Stale Worktree Metadata

If a worktree directory was manually deleted (e.g., `rm -rf`), the metadata in `.git/worktrees/` becomes stale.

```bash
# Dry run: see what would be pruned
git worktree prune --dry-run

# Prune stale entries
git worktree prune
```

### Clean Up All Worktrees After a Feature

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

## Upstream Cleanup

### Remove a Stale Upstream Tracking Reference

If a remote branch was deleted but your local branch still tracks it:

```bash
# Check what the current branch tracks
git rev-parse --abbrev-ref --symbolic-full-name @{u}

# Unset the upstream reference
git branch --unset-upstream feat/my-branch
```

### Remove a Remote Entirely

If a fork or temporary remote is no longer needed:

```bash
# List all remotes
git remote -v

# Remove a remote
git remote remove fork-origin
```

---

## Batch Cleanup Operations

### Full Post-Merge Cleanup Sequence

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

### Weekly Maintenance Sweep

Run periodically to prevent accumulation:

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

## Recovering from Cleanup Mistakes

### Accidentally Deleted an Unmerged Branch

Branches are just pointers to commits. The commits still exist in the reflog for at least 30 days (default `gc.reflogExpire`).

```bash
# Find the commit the branch pointed to
git reflog | grep "feat/accidentally-deleted"

# Or search by commit message
git reflog --all | grep "the commit message"

# Recreate the branch at that commit
git checkout -b feat/accidentally-deleted <sha>
```

### Accidentally Removed a Worktree with Uncommitted Changes

If changes were committed, they are in the reflog and recoverable. If changes were uncommitted (only in the working directory), they are lost - this is why you should always commit or stash before removing a worktree.

```bash
# Find commits that were in the worktree
git reflog --all

# Recreate the branch if it was deleted with the worktree
git checkout -b recovered-branch <sha>
```

### Accidentally Deleted a Remote Branch

If the remote branch is gone but the local branch still exists:

```bash
# Push the local branch back to the remote
git push -u origin feat/my-branch
```

If both local and remote are gone, use the reflog recovery method above to recreate the local branch, then push.

---

## Configuration for Automatic Cleanup

### Auto-Prune on Fetch

```bash
git config --global fetch.prune true
```

### Auto-Delete Remote Branch on PR Merge

Most hosting platforms support this:

- **GitHub:** Repository Settings > General > "Automatically delete head branches"
- **GitLab:** Project Settings > Merge Requests > "Enable 'Delete source branch' option by default"
- **Bitbucket:** Repository Settings > Merge Strategies > "Close source branch"

Enabling auto-delete reduces manual cleanup to local branches and worktrees only.

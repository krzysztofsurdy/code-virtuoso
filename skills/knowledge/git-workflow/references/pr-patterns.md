# PR Patterns

## Why PR Size Matters

Large pull requests are the single biggest cause of slow reviews, missed defects, and reviewer burnout. Research consistently shows that review quality drops sharply as the diff grows.

### Size Thresholds

| Lines Changed | Review Effectiveness | Typical Review Time |
|---|---|---|
| < 50 | Very high -- reviewer catches most issues | 5-15 minutes |
| 50-200 | High -- manageable cognitive load | 15-30 minutes |
| 200-400 | Moderate -- requires dedicated focus | 30-60 minutes |
| 400-800 | Low -- reviewer fatigue sets in | 1-2 hours, often delayed |
| 800+ | Very low -- superficial review likely | Often abandoned or rubber-stamped |

### Strategies to Keep PRs Small

- **One concern per PR** -- A single feature, a single bug fix, or a single refactor. Never mix.
- **Separate mechanical changes** -- Renames, formatting fixes, and import reorganization go in their own PR.
- **Extract preparatory refactors** -- If a feature requires restructuring existing code, do the refactor first in a separate PR.
- **Use feature flags** -- Merge partial implementations behind a flag rather than waiting for the full feature.
- **Stacked PRs** -- Break large features into a chain of dependent, reviewable PRs (see Stacked PRs section below).

---

## PR Description Templates

A good PR description answers three questions: what changed, why it changed, and how to verify it.

### Standard Template

```markdown
## What

Brief summary of the changes (1-3 sentences).

## Why

Link to the ticket or issue. Explain the motivation if the ticket does not capture it fully.

## How to Verify

- [ ] Step-by-step instructions for manual testing
- [ ] Note any specific test cases added
- [ ] Mention environment requirements if applicable

## Notes

Any trade-offs, follow-up work, or context reviewers should know.
```

### Minimal Template (for small PRs)

```markdown
## Summary

One-line description of the change and its purpose.

Closes #123
```

### What Makes a Good Description

- Links to the relevant ticket or issue
- Explains the "why" -- reviewers can see the "what" in the diff
- Includes screenshots or recordings for UI changes
- Calls out areas where feedback is specifically wanted
- Lists any follow-up work that was intentionally deferred

---

## Review Workflow Patterns

### Required Reviewers

Configure your repository to require a minimum number of approvals before merge. Common configurations:

| Team Size | Required Approvals | Rationale |
|---|---|---|
| 2-4 | 1 | Small team, everyone has context |
| 5-10 | 1-2 | Balance between speed and oversight |
| 10+ | 2 | Ensures at least two perspectives |
| Critical paths (auth, payments) | 2 + domain expert | High-risk code needs specialist review |

### CODEOWNERS

A CODEOWNERS file automatically assigns reviewers based on which files a PR touches. This ensures domain experts review changes to code they own.

```
# .github/CODEOWNERS (GitHub) or CODEOWNERS at repo root

# Default owner for everything
*                           @team-leads

# Backend ownership by domain
src/Auth/                   @security-team
src/Billing/                @payments-team
src/Notification/           @platform-team

# Infrastructure
docker/                     @devops-team
.github/workflows/          @devops-team

# Documentation
docs/                       @tech-writers

# Database migrations require DBA review
migrations/                 @dba-team @backend-team
```

### Review Assignment Strategies

- **Round-robin** -- Distributes reviews evenly across team members
- **Load-balanced** -- Assigns to the person with the fewest open reviews
- **Domain-based** -- CODEOWNERS routes to the relevant expert
- **Random from pool** -- Selects randomly from eligible reviewers

Most teams combine CODEOWNERS for critical paths with round-robin for general code.

---

## Merge Strategies

### Merge Commit (--no-ff)

Preserves full branch history with an explicit merge node. Easy to revert entire features. Best for open-source projects and audit trails. Downside: noisy history with many merge commits.

### Squash and Merge

Collapses all branch commits into a single commit on main. Clean, linear history where each commit represents a complete reviewed change. Best for teams where intermediate commits are noisy. Downside: loses granular commit attribution.

### Rebase and Merge

Replays branch commits onto main tip, creating linear history without merge commits while preserving individual commits. Best for teams with clean commit discipline. Downside: rewrites commit hashes.

### Choosing a Default Strategy

| Factor | Merge Commit | Squash | Rebase |
|---|---|---|---|
| History readability | Low (noisy) | High (one commit per PR) | Medium (linear but verbose) |
| Revert granularity | Entire PR (easy) | Entire PR (easy) | Individual commits (harder) |
| Commit hygiene required | Low | Low | High |
| Bisect effectiveness | Low | High | High |
| Branch topology visible | Yes | No | No |

---

## Branch Protection Rules

Branch protection prevents direct pushes to important branches and enforces quality gates.

### Common Configurations by Risk Level

| Risk Level | Approvals | CI Required | Up-to-date | Dismiss Stale |
|---|---|---|---|---|
| Low (docs, internal tools) | 1 | Yes | No | No |
| Medium (application code) | 1 | Yes | Yes | Yes |
| High (auth, payments, infra) | 2 | Yes | Yes | Yes |
| Critical (production config) | 2 + CODEOWNERS | Yes | Yes | Yes |

---

## Stacked PRs

Stacked PRs break a large feature into a series of small, dependent pull requests that build on each other. Each PR in the stack is reviewable and mergeable independently.

### How Stacking Works

```
main
  └── PR #1: refactor(user): extract validation service     [200 lines]
        └── PR #2: feat(user): add email verification        [150 lines]
              └── PR #3: feat(user): add verification UI      [180 lines]
```

Each PR targets the previous PR's branch (not main). After PR #1 merges to main, PR #2 is retargeted to main, and so on.

### Workflow

```bash
# PR 1: Foundation refactor
git checkout main
git checkout -b feat/user-validation-extract
# ... work and commit ...
git push -u origin feat/user-validation-extract
# Open PR #1 targeting main

# PR 2: Build on PR 1
git checkout -b feat/user-email-verification
# ... work and commit ...
git push -u origin feat/user-email-verification
# Open PR #2 targeting feat/user-validation-extract

# PR 3: Build on PR 2
git checkout -b feat/user-verification-ui
# ... work and commit ...
git push -u origin feat/user-verification-ui
# Open PR #3 targeting feat/user-email-verification
```

### Managing the Stack

When a reviewer requests changes to an earlier PR, update it and rebase downstream branches with `git rebase <parent-branch>` followed by `git push --force-with-lease`. After a PR merges to main, retarget the next PR to `main` and rebase it onto the updated main.

### When to Use Stacked PRs

- Large features that would otherwise produce a 1000+ line PR
- Changes that touch multiple layers (database, service, API, UI)
- Work that benefits from incremental review -- earlier PRs inform later design
- Teams where review bottlenecks are caused by PR size

### When to Avoid Stacked PRs

- Simple features that fit in a single small PR
- Teams unfamiliar with rebase workflows (the overhead is not worth it)
- Changes where the full context is needed to review any part

---

## Rebase vs Merge for Updating Feature Branches

| Approach | Command | Best For |
|---|---|---|
| **Merge main in** | `git merge main` | Shared branches, preserving integration history |
| **Rebase onto main** | `git rebase main` | Local or single-author branches, clean linear history |

**Key rule:** Never rebase commits that others have based work on -- it rewrites shared history and causes divergence. Use `--force-with-lease` (not `--force`) when pushing rebased branches to catch unexpected upstream changes.

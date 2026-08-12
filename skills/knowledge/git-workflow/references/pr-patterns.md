# PR Patterns

## Contents

- [Why PR size matters](#why-pr-size-matters)
- [PR description templates](#pr-description-templates)
- [Review workflow patterns](#review-workflow-patterns)
- [Merge strategies](#merge-strategies)
- [Branch protection rules](#branch-protection-rules)
- [Stacked PRs](#stacked-prs)
- [Rebase vs merge for updating feature branches](#rebase-vs-merge-for-updating-feature-branches)

## Why PR size matters

Large pull requests are the biggest cause of slow reviews, missed defects, and reviewer burnout. Review quality drops fast as the diff grows.

### Size thresholds

| Lines changed | Review effectiveness | Typical review time |
|---|---|---|
| < 50 | Very high: reviewer catches most issues | 5-15 minutes |
| 50-200 | High: manageable cognitive load | 15-30 minutes |
| 200-400 | Moderate: needs dedicated focus | 30-60 minutes |
| 400-800 | Low: reviewer fatigue sets in | 1-2 hours, often delayed |
| 800+ | Very low: superficial review likely | Often abandoned or rubber-stamped |

### Strategies to keep PRs small

- **One concern per PR**: a single feature, bug fix, or refactor. Never mix them.
- **Separate mechanical changes**: renames, formatting fixes, and import reorganization go in their own PR.
- **Extract preparatory refactors**: if a feature needs existing code restructured, do the refactor first in a separate PR.
- **Use feature flags**: merge partial implementations behind a flag instead of waiting for the full feature.
- **Stacked PRs**: break large features into a chain of dependent, reviewable PRs (see the Stacked PRs section below).

---

## PR description templates

A good PR description answers three questions: what changed, why it changed, and how to verify it.

### Standard template

```markdown
## What

Brief summary of the changes (1-3 sentences).

## Why

Link to the ticket or issue. Explain the motivation if the ticket does not capture it.

## How to Verify

- [ ] Step-by-step instructions for manual testing
- [ ] Note any specific test cases added
- [ ] Mention environment requirements if applicable

## Notes

Any trade-offs, follow-up work, or context reviewers should know.
```

### Minimal template (for small pRs)

```markdown
## Summary

One-line description of the change and its purpose.

Closes #123
```

### What makes a good description

- Links to the relevant ticket or issue
- Explains the "why", since reviewers can see the "what" in the diff
- Includes screenshots or recordings for UI changes
- Calls out areas where feedback is specifically wanted
- Lists any follow-up work that was intentionally deferred

---

## Review workflow patterns

### Required reviewers

Configure the repository to require a minimum number of approvals before merge. Common setups:

| Team size | Required approvals | Rationale |
|---|---|---|
| 2-4 | 1 | Small team, everyone has context |
| 5-10 | 1-2 | Balances speed and oversight |
| 10+ | 2 | At least two perspectives |
| Critical paths (auth, payments) | 2 + domain expert | High-risk code needs specialist review |

### CODEOWNERS

A CODEOWNERS file assigns reviewers based on which files a PR touches, so domain experts review changes to code they own.

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

### Review assignment strategies

- **Round-robin**: spreads reviews evenly across team members
- **Load-balanced**: assigns to the person with the fewest open reviews
- **Domain-based**: CODEOWNERS routes to the relevant expert
- **Random from pool**: picks randomly from eligible reviewers

Most teams combine CODEOWNERS for critical paths with round-robin for general code.

---

## Merge strategies

### Merge commit (--no-ff)

Keeps the full branch history with an explicit merge node. Entire features are easy to revert. Best for open-source projects and audit trails. Downside: noisy history with many merge commits.

### Squash and merge

Collapses all branch commits into a single commit on main. The history is linear and each commit is a complete reviewed change. Best for teams where intermediate commits are noisy. Downside: loses granular commit attribution.

### Rebase and merge

Replays branch commits onto the tip of main. History stays linear, there are no merge commits, and individual commits are kept. Best for teams with clean commit discipline. Downside: rewrites commit hashes.

### Choosing a default strategy

| Factor | Merge commit | Squash | Rebase |
|---|---|---|---|
| History readability | Low (noisy) | High (one commit per PR) | Medium (linear but verbose) |
| Revert granularity | Entire PR (easy) | Entire PR (easy) | Individual commits (harder) |
| Commit hygiene required | Low | Low | High |
| Bisect effectiveness | Low | High | High |
| Branch topology visible | Yes | No | No |

---

## Branch protection rules

Branch protection blocks direct pushes to important branches and enforces quality gates.

### Common configurations by risk level

| Risk level | Approvals | CI required | Up-to-date | Dismiss stale |
|---|---|---|---|---|
| Low (docs, internal tools) | 1 | Yes | No | No |
| Medium (application code) | 1 | Yes | Yes | Yes |
| High (auth, payments, infra) | 2 | Yes | Yes | Yes |
| Critical (production config) | 2 + CODEOWNERS | Yes | Yes | Yes |

---

## Stacked PRs

Stacked PRs break a large feature into a series of small, dependent pull requests that build on each other. Each PR in the stack can be reviewed and merged on its own.

### How stacking works

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

### Managing the stack

When a reviewer requests changes to an earlier PR, update it and rebase downstream branches with `git rebase <parent-branch>` followed by `git push --force-with-lease`. After a PR merges to main, retarget the next PR to `main` and rebase it onto the updated main.

### When to use stacked PRs

- Large features that would otherwise produce a 1000+ line PR
- Changes that touch multiple layers (database, service, API, UI)
- Work that benefits from incremental review, where earlier PRs inform later design
- Teams where review bottlenecks are caused by PR size

### When to avoid stacked PRs

- Simple features that fit in a single small PR
- Teams unfamiliar with rebase workflows (the overhead is not worth it)
- Changes where the full context is needed to review any part

---

## Rebase vs merge for updating feature branches

| Approach | Command | Best for |
|---|---|---|
| **Merge main in** | `git merge main` | Shared branches, preserving integration history |
| **Rebase onto main** | `git rebase main` | Local or single-author branches, clean linear history |

**Key rule:** Never rebase commits that others have based work on, because it rewrites shared history and causes divergence. Use `--force-with-lease` (not `--force`) when pushing rebased branches, so unexpected upstream changes are caught.

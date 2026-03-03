---
name: git-workflow
description: Git workflow patterns and version control best practices — branching strategies, commit conventions, PR workflows, release management, and monorepo patterns. Use when establishing team git conventions, reviewing branching strategies, or improving version control practices.
user-invocable: false
---

# Git Workflow

Effective version control is not just about tracking changes -- it is about enabling teams to collaborate predictably, release confidently, and maintain a history that tells a coherent story. The right workflow depends on team size, release cadence, and how much process the project can absorb without slowing down.

## Choosing a Branching Strategy

No single branching model fits every team. The right choice depends on how often you release, how large your team is, and how much ceremony you can tolerate.

### Strategy Comparison

| Strategy | Release Cadence | Team Size | Complexity | Best For |
|---|---|---|---|---|
| **Trunk-Based** | Continuous (multiple per day) | Any (works best with strong CI) | Low | SaaS, cloud-native, teams with mature CI/CD |
| **GitHub Flow** | On-demand (per merged PR) | Small to medium | Low | Web apps, startups, teams wanting simplicity |
| **Git Flow** | Scheduled / versioned releases | Medium to large | High | Packaged software, mobile apps, multiple supported versions |
| **GitLab Flow** | Environment-promoted | Medium to large | Medium | Teams needing environment-specific branches (staging, production) |

### Decision Guide

1. **Do you deploy continuously?** -- Use trunk-based development. Short-lived branches (hours, not days), feature flags for incomplete work, and strong CI are prerequisites.
2. **Do you deploy on merge but want review gates?** -- Use GitHub Flow. One long-lived branch (main), feature branches, pull requests as the merge gate.
3. **Do you ship versioned releases on a schedule?** -- Use Git Flow. Separate develop and main branches, release branches for stabilization, hotfix branches for emergency patches.
4. **Do you promote through environments?** -- Use GitLab Flow. Environment branches (staging, production) sit downstream of main, and merges flow in one direction.

See [Branching Strategies Reference](references/branching-strategies.md) for detailed mechanics, feature flag integration, and migration paths between strategies.

---

## Commit Message Conventions

Good commit messages serve three audiences: reviewers reading the PR, developers reading `git log` next month, and automation tools generating changelogs and version bumps.

### The Conventional Commits Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Common Commit Types

| Type | Purpose | Version Impact |
|---|---|---|
| `feat` | New feature visible to users | Minor bump |
| `fix` | Bug fix | Patch bump |
| `refactor` | Code restructuring with no behavior change | None |
| `perf` | Performance improvement | Patch bump |
| `test` | Adding or updating tests | None |
| `docs` | Documentation only | None |
| `chore` | Tooling, dependencies, build config | None |
| `ci` | CI/CD pipeline changes | None |
| `build` | Build system or dependency changes | None |

### Breaking Changes

Append `!` after the type or add a `BREAKING CHANGE:` footer to signal incompatible changes. Either notation triggers a major version bump when used with automated release tooling.

```
feat(api)!: remove deprecated /v1/users endpoint

BREAKING CHANGE: The /v1/users endpoint has been removed. Use /v2/users instead.
```

### Semantic Versioning Alignment

| Commit Contains | Version Bump | Example |
|---|---|---|
| `fix:` | Patch (1.0.0 -> 1.0.1) | Bug corrections |
| `feat:` | Minor (1.0.0 -> 1.1.0) | New capabilities |
| `BREAKING CHANGE` or `!` | Major (1.0.0 -> 2.0.0) | Incompatible changes |

See [Commit Conventions Reference](references/commit-conventions.md) for scope naming patterns, multi-line body guidelines, changelog automation setup, and git hook validation.

---

## Pull Request Workflow

Pull requests are the primary collaboration point in most git workflows. Their quality directly affects review speed, defect discovery, and team velocity.

### PR Size Guidelines

| PR Size (lines changed) | Review Quality | Recommended |
|---|---|---|
| < 50 | Excellent -- reviewer catches most issues | Ideal for stacked PRs |
| 50-200 | Good -- manageable cognitive load | Sweet spot for most changes |
| 200-400 | Acceptable -- requires focused review time | Upper bound for single reviews |
| 400+ | Poor -- reviewer fatigue, defects slip through | Split into smaller PRs |

### Core PR Practices

- **One concern per PR** -- A PR should do one thing: add a feature, fix a bug, refactor a module. Mixing concerns makes review harder and reverts riskier.
- **Write a clear description** -- State what changed, why it changed, and how to verify it. Link to the relevant ticket or issue.
- **Keep the diff reviewable** -- Move large mechanical changes (renames, formatting) into separate PRs from logic changes.
- **Respond to feedback promptly** -- Stale PRs accumulate merge conflicts and block dependent work.

### Merge Strategies

| Strategy | History Shape | Best For |
|---|---|---|
| **Merge commit** | Preserves branch topology, creates merge node | Open-source projects, audit trails |
| **Squash and merge** | Collapses branch into single commit on main | Feature branches with messy intermediate commits |
| **Rebase and merge** | Linear history, no merge commits | Teams wanting clean, linear logs |

See [PR Patterns Reference](references/pr-patterns.md) for description templates, CODEOWNERS configuration, branch protection rules, stacked PR workflows, and review assignment strategies.

---

## Release Management

Release management bridges development and deployment. The approach depends on whether releases are continuous, scheduled, or versioned.

### Release Models

| Model | How It Works | When to Use |
|---|---|---|
| **Continuous release** | Every merged PR deploys automatically | SaaS with strong CI/CD and monitoring |
| **Scheduled release** | Changes accumulate, release on a cadence (weekly, biweekly) | Teams needing coordination windows |
| **Versioned release** | Explicit version tags, release branches for stabilization | Libraries, APIs, packaged software |

### Git Tags for Releases

Tags mark specific commits as release points. Use annotated tags for releases because they store author, date, and message metadata.

```bash
# Create an annotated release tag
git tag -a v1.2.0 -m "Release 1.2.0: Add user dashboard and fix auth timeout"

# Push tags to remote
git push origin v1.2.0

# List existing tags matching a pattern
git tag -l "v1.*"
```

### Automated Release Pipeline

When conventional commits are combined with release automation tooling, the pipeline can:

1. Analyze commits since the last tag to determine the next version
2. Generate or update the changelog from commit messages
3. Create the git tag
4. Build and publish artifacts
5. Create a release entry on the hosting platform (GitHub/GitLab)

This eliminates manual version decisions and ensures the changelog stays synchronized with actual changes.

### Hotfix Workflow

When a critical bug is found in production:

1. Branch from the release tag (not from the development branch)
2. Apply the minimal fix
3. Tag the new patch release
4. Merge the fix forward into the main development line to prevent regression

```bash
# Branch from the release tag
git checkout -b hotfix/fix-auth-crash v1.2.0

# After fixing and committing
git tag -a v1.2.1 -m "Hotfix: prevent auth crash on expired tokens"
git push origin v1.2.1

# Merge fix back to main
git checkout main
git merge hotfix/fix-auth-crash
```

---

## Quick Reference: Common Workflow Problems

| Problem | Likely Cause | Resolution |
|---|---|---|
| Frequent merge conflicts | Long-lived branches, infrequent integration | Merge main into feature branches daily, or switch to trunk-based |
| Broken main branch | No CI on PRs, insufficient test coverage | Require passing CI before merge, add branch protection |
| Unclear release contents | No commit conventions, manual changelogs | Adopt conventional commits, automate changelog generation |
| Slow PR reviews | PRs too large, no clear ownership | Set size guidelines, configure CODEOWNERS, use stacked PRs |
| Accidental commits to main | No branch protection | Enable branch protection rules, require PR reviews |

---

## Reference Files

| Reference | Contents |
|---|---|
| [Branching Strategies](references/branching-strategies.md) | Trunk-based, GitHub Flow, Git Flow, GitLab Flow -- mechanics, feature flags, comparison matrix |
| [Commit Conventions](references/commit-conventions.md) | Conventional commits format, scope patterns, semantic versioning, changelog automation, git hooks |
| [PR Patterns](references/pr-patterns.md) | Size guidelines, description templates, CODEOWNERS, merge strategies, branch protection, stacked PRs |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Setting up CI/CD pipelines for branch protection | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies |
| API versioning aligned with git release tags | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design principles |
| Coordinating releases across microservices | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for microservices patterns |
| Sprint-aligned release planning | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for scrum workflows |

# Branching Strategies

## Trunk-Based Development

Trunk-based development centers on a single long-lived branch -- typically called `main` or `trunk`. All developers integrate their work into this branch frequently, ideally multiple times per day. The goal is to keep the integration cycle as short as possible so that merge conflicts stay small and feedback from CI arrives quickly.

### How It Works

1. Developers pull the latest `main` and create a short-lived branch (hours, rarely more than a day)
2. Work is done in small increments -- each commit should leave the codebase in a deployable state
3. The branch is merged back to `main` through a pull request (or directly for very small teams)
4. CI runs on every push to `main`, and deployment follows automatically

```bash
# Typical trunk-based workflow
git checkout main
git pull origin main
git checkout -b feat/add-email-notifications

# Work in small commits
git add src/Notification/EmailSender.php
git commit -m "feat(notification): add email sender service"

# Merge back quickly -- ideally same day
git checkout main
git pull origin main
git merge feat/add-email-notifications
git push origin main
git branch -d feat/add-email-notifications
```

### Feature Flags for Incomplete Work

When a feature takes longer than a single integration cycle, use feature flags to merge incomplete work safely:

- Code is merged to main but hidden behind a flag
- The flag is toggled on for testing in staging or for specific users
- Once the feature is complete and verified, the flag is enabled for everyone
- After full rollout, remove the flag and the old code path

This avoids long-lived branches while keeping main deployable at all times.

### When Trunk-Based Works Well

- Strong CI/CD pipeline with fast, reliable tests
- Team has high test coverage and confidence in automated checks
- Deployments are frequent and low-risk (blue-green, canary)
- Team members are experienced with small, incremental changes

### When Trunk-Based Struggles

- No CI pipeline or slow test suites (broken main becomes common)
- Team members are not comfortable with feature flags
- Regulatory requirements demand formal release branches
- Multiple product versions must be maintained simultaneously

---

## GitHub Flow

GitHub Flow is a simplified branching model built around one rule: `main` is always deployable. Feature work happens on branches, goes through pull request review, and merges back to `main`.

### How It Works

1. Create a descriptively named branch from `main`
2. Make commits on the branch, push regularly
3. Open a pull request when the work is ready for review (or earlier as a draft)
4. Discuss and review the code in the PR
5. Merge to `main` after approval and passing CI
6. Deploy from `main`

```bash
# Create a feature branch
git checkout -b feat/user-profile-avatars
git push -u origin feat/user-profile-avatars

# Work and commit
git add .
git commit -m "feat(profile): add avatar upload endpoint"
git push

# After PR approval, merge via the platform UI (or CLI)
# gh pr merge --squash
```

### Key Characteristics

- Only one long-lived branch (`main`)
- No separate develop, release, or hotfix branches
- PRs are the quality gate -- CI and review happen here
- Deployment happens from `main` after every merge (or on demand)

### When GitHub Flow Fits

- Web applications deployed on merge
- Small to medium teams (2-15 developers)
- Teams that want minimal branching ceremony
- Products that do not maintain multiple release versions

---

## Git Flow

Git Flow uses multiple long-lived branches with specific roles. It provides structure for teams with scheduled releases and the need to maintain older versions.

### Branch Roles

| Branch | Purpose | Lifetime |
|---|---|---|
| `main` | Production-ready code, tagged with release versions | Permanent |
| `develop` | Integration branch for the next release | Permanent |
| `feature/*` | New feature development, branched from `develop` | Until merged to develop |
| `release/*` | Release stabilization, branched from `develop` | Until merged to main and develop |
| `hotfix/*` | Emergency fixes, branched from `main` | Until merged to main and develop |

### Workflow

```bash
# Start a feature
git checkout develop
git checkout -b feature/shopping-cart

# Complete feature -- merge back to develop
git checkout develop
git merge --no-ff feature/shopping-cart
git branch -d feature/shopping-cart

# Prepare a release
git checkout develop
git checkout -b release/2.1.0

# Stabilize (bug fixes only on release branch)
git commit -m "fix(checkout): correct tax calculation rounding"

# Finalize release
git checkout main
git merge --no-ff release/2.1.0
git tag -a v2.1.0 -m "Release 2.1.0"
git checkout develop
git merge --no-ff release/2.1.0
git branch -d release/2.1.0

# Emergency hotfix
git checkout main
git checkout -b hotfix/payment-timeout
git commit -m "fix(payment): increase gateway timeout to 30s"
git checkout main
git merge --no-ff hotfix/payment-timeout
git tag -a v2.1.1 -m "Hotfix: payment timeout"
git checkout develop
git merge --no-ff hotfix/payment-timeout
git branch -d hotfix/payment-timeout
```

### When Git Flow Fits

- Software shipped as versioned packages (libraries, SDKs, mobile apps)
- Multiple versions in production simultaneously
- Release cycles measured in weeks or months
- Dedicated QA phase before each release

### When Git Flow Is Overkill

- Web apps that deploy on every merge
- Small teams where the branch overhead slows development
- Products with a single production version

---

## GitLab Flow

GitLab Flow sits between GitHub Flow and Git Flow. It adds environment branches that represent deployment targets, creating a promotion path from development to production.

### Environment Branch Model

```
main  ->  staging  ->  production
```

- `main` -- latest development work, always tested by CI
- `staging` -- mirrors what is deployed to the staging environment
- `production` -- mirrors what is deployed to production

Merges flow in one direction: main -> staging -> production. You never merge production back into main.

```bash
# Develop on feature branches, merge to main via PR
git checkout -b feat/dashboard-widgets
# ... work and push ...
# PR merged to main

# Promote to staging
git checkout staging
git merge main
git push origin staging
# CI deploys to staging environment

# After staging validation, promote to production
git checkout production
git merge staging
git push origin production
# CI deploys to production
```

### When GitLab Flow Fits

- Teams needing explicit environment promotion (dev -> staging -> production)
- Organizations with compliance requirements for environment sign-off
- Projects where staging validation is a mandatory step before production

---

## Comparison Matrix

| Factor | Trunk-Based | GitHub Flow | Git Flow | GitLab Flow |
|---|---|---|---|---|
| **Long-lived branches** | 1 (main) | 1 (main) | 2 (main + develop) | 2-3 (main + environments) |
| **Feature branches** | Very short-lived (hours) | Short-lived (days) | Medium-lived (days to weeks) | Short-lived (days) |
| **Release process** | Continuous from main | On merge to main | Release branch, then tag | Environment promotion |
| **Hotfix path** | Fix on main directly | Fix on main via PR | Hotfix branch from main | Fix on main, promote forward |
| **CI/CD dependency** | Critical | Important | Helpful | Important |
| **Feature flag need** | High | Low to medium | Low | Low to medium |
| **Learning curve** | Low (process), high (discipline) | Low | High | Medium |
| **Merge conflict frequency** | Very low | Low | Medium to high | Low |

---

## Migrating Between Strategies

### From Git Flow to GitHub Flow

1. Stop creating new feature branches from `develop` -- branch from `main` instead
2. Set up CI to run on all PRs targeting `main`
3. Enable branch protection on `main` (require CI pass, require review)
4. Merge `develop` into `main` one final time and delete `develop`
5. Adopt feature flags for work-in-progress that would previously sit on `develop`

### From GitHub Flow to Trunk-Based

1. Invest in CI speed -- trunk-based requires fast feedback
2. Establish feature flag infrastructure
3. Set team guidelines for maximum branch lifetime (target: same day)
4. Practice breaking large features into small, independently mergeable increments
5. Consider allowing direct pushes to `main` for trivial changes (with CI gate)

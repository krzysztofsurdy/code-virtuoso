# Done Definitions

A multi-tiered definition of done. Work moves through tiers, and each tier has specific evidence requirements. Claiming a higher tier without meeting the evidence requirements of all lower tiers is a verification failure.

---

## Contents

- [Why tiers exist](#why-tiers-exist)
- [Tier 1: Local done](#tier-1-local-done)
- [Tier 2: Review-ready done](#tier-2-review-ready-done)
- [Tier 3: Merged done](#tier-3-merged-done)
- [Tier 4: Deployed done](#tier-4-deployed-done)
- [Tier 5: Verified-in-production done](#tier-5-verified-in-production-done)
- [Tier escalation rules](#tier-escalation-rules)
- [Mapping tiers to workflow stages](#mapping-tiers-to-workflow-stages)

## Why tiers exist

"Done" is ambiguous without context. Code that passes local tests is not "done" in the same way as code running in production with verified metrics. Each tier is a boundary crossing: from the developer's machine to a shared branch, from a shared branch to a deployment target, from a deployment target to real users. Each crossing adds new failure surfaces that need new evidence.

Naming the tier prevents the most common miscommunication: one person says "done" meaning "local tests pass" while another hears "done" meaning "deployed and working in production."

---

## Tier 1: Local done

**Definition:** The change works on the development machine, verified by automated checks.

**When to claim:** After completing implementation and before pushing to a remote branch.

### Evidence requirements

| Check | Required Evidence |
|---|---|
| Tests pass | Test runner output with counts: passed, failed, skipped. Exit code 0. |
| Linter clean | Linter output showing 0 errors. Exit code 0. |
| Type checker clean | Type checker output showing 0 errors (for typed languages). Exit code 0. |
| Build succeeds | Build command output. Exit code 0. Artifacts exist. |
| No unintended changes | `git diff --stat` showing only intended files modified. |
| Changes committed | `git status` showing clean working tree (or only intentionally untracked files). |

### Example claim

```
Local done.
- Tests: `pytest -v` - 56 passed, 0 failed, 0 skipped. Exit code 0.
- Lint: `ruff check .` - 0 errors. Exit code 0.
- Types: `mypy .` - Success: no issues found in 31 source files. Exit code 0.
- Build: `python -m build` - exit code 0, dist/mypackage-1.2.0.tar.gz created.
- Git: `git status` - working tree clean. `git diff --stat HEAD~1` - 4 files changed.
```

### Common mistakes at Tier 1

- Running tests for only one module instead of the full suite
- Forgetting to run the type checker after a refactor
- Claiming done with uncommitted changes
- Not checking for untracked files that should be committed

---

## Tier 2: Review-ready done

**Definition:** The change is ready for a peer to evaluate. All local checks pass and the change is packaged for review.

**When to claim:** After pushing to a remote branch and before requesting review.

### Evidence requirements

Everything from Tier 1, plus:

| Check | Required Evidence |
|---|---|
| Pushed to remote | `git push` output or `git log --oneline origin/branch..HEAD` showing zero commits ahead. |
| PR/MR description accurate | Description matches actual changes. No stale or misleading text. |
| No merge conflicts | `git merge-base --is-ancestor` or equivalent check. Clean merge possible. |
| Self-review complete | Diff has been read. No debug code, no commented-out blocks, no TODO items left unresolved. |
| Commit history clean | Commits are logical, messages are descriptive. No "fix typo" chains, no "WIP" commits. |

### Example claim

```
Review-ready done.
- All Tier 1 checks pass (see above).
- Pushed to origin/feat/add-user-export. `git log --oneline origin/main..HEAD` shows 3 commits.
- PR #142 created with description matching changes.
- Self-reviewed diff: no debug code, no TODOs, no commented-out blocks.
- No merge conflicts with main.
```

### Common mistakes at Tier 2

- PR description mentions planned changes that were not implemented
- Leaving debugging statements or temporary logging in the code
- Forgetting to push the latest commit (local is ahead of remote)
- Unresolved merge conflicts masked by a local-only merge

---

## Tier 3: Merged done

**Definition:** The change has been accepted into the main branch and passes all automated checks in the shared environment.

**When to claim:** After the PR is approved and merged.

### Evidence requirements

Everything from Tier 2, plus:

| Check | Required Evidence |
|---|---|
| CI pipeline passes | CI status showing all jobs green (tests, lint, type check, build, security scan). |
| Peer review approved | At least one approval from a reviewer who read the diff. |
| Merged to main | Merge commit or squash commit visible in main branch history. |
| No post-merge failures | CI on main passes after the merge. |

### Example claim

```
Merged done.
- All Tier 2 checks pass.
- CI pipeline: all 4 jobs green (test, lint, typecheck, build).
- Approved by @reviewer in PR #142.
- Squash-merged to main. Commit: abc1234.
- CI on main: green after merge.
```

### Common mistakes at Tier 3

- Merging with CI failures ("it's just a flaky test")
- Merging with a stale approval (code changed since the approval was given)
- Merging to main but not checking that CI passes on main afterward
- Auto-merging without verifying that all required checks completed

---

## Tier 4: Deployed done

**Definition:** The change is running in a target environment (staging or production) and the deployment is healthy.

**When to claim:** After deployment completes and health checks pass.

### Evidence requirements

Everything from Tier 3, plus:

| Check | Required Evidence |
|---|---|
| Deployment succeeded | Deployment command output or deployment pipeline status. |
| Correct version deployed | Version endpoint, deployment tag, or artifact hash matches the merged commit. |
| Health check passes | Health endpoint returns expected status (e.g., HTTP 200 with correct body). |
| No startup errors | Application logs show clean startup, no error-level entries. |
| Rollback path verified | Rollback procedure is documented and has been tested at least once for this deployment pipeline. |

### Example claim

```
Deployed done (staging).
- Deployed via CI pipeline, job #789 succeeded.
- Version endpoint: `curl staging.example.com/version` returns {"version":"2.3.1","commit":"abc1234"}.
- Health check: `curl staging.example.com/health` returns 200, {"status":"UP"}.
- Logs: no error-level entries in the first 60 seconds after deploy.
- Rollback: documented in runbook, last tested 2 weeks ago.
```

### Common mistakes at Tier 4

- Claiming deployed without checking health
- Checking health immediately but not after the service has been running for a few minutes (startup vs steady-state)
- Deploying to staging and claiming "deployed" without specifying the environment
- No rollback plan or untested rollback

---

## Tier 5: Verified-in-production done

**Definition:** The change is running in production, confirmed working for real users, and metrics are stable.

**When to claim:** After production deployment with verified metrics and user-facing behavior.

### Evidence requirements

Everything from Tier 4, plus:

| Check | Required Evidence |
|---|---|
| Smoke tests pass in production | Key user flows work against the production environment. |
| Error rates stable | Error monitoring shows no increase in error rate after deployment. |
| Performance stable | Latency and throughput metrics show no degradation. |
| Feature verified | The specific feature or fix is confirmed working in production (e.g., user can perform the new action). |
| No alerts triggered | Monitoring and alerting systems show no new alerts related to the change. |
| Observation period complete | Sufficient time has passed post-deploy (team-defined, typically 15 minutes to 24 hours depending on traffic). |

### Example claim

```
Verified-in-production done.
- All Tier 4 checks pass (production environment).
- Smoke tests: `curl prod.example.com/api/export/users` returns 200 with CSV data.
- Error rate: 0.02% (baseline: 0.02%) over 30 minutes post-deploy.
- P95 latency: 180ms (baseline: 175ms) - within tolerance.
- Feature verified: user export button visible, CSV download completes.
- No new alerts in monitoring dashboard over the observation period.
```

### Common mistakes at Tier 5

- Checking metrics too soon (within seconds of deployment, before traffic reaches the new version)
- Comparing to a wrong baseline (metrics from a different time of day or traffic pattern)
- Declaring done before the observation period completes
- Not monitoring for delayed effects (memory leaks, connection pool exhaustion, log volume growth)

---

## Tier escalation rules

1. **Always state the tier.** "Done" without a tier is ambiguous. Say "Local done" or "Deployed done (staging)."

2. **Lower tiers are prerequisites.** You cannot claim Tier 3 (merged) if Tier 1 (local) evidence is missing.

3. **Each tier has its own failure modes.** Passing Tier 1 does not guarantee Tier 2. Passing Tier 4 does not guarantee Tier 5.

4. **The required tier depends on the task.** A local refactor may only need Tier 1-3. A production hotfix needs Tier 5.

5. **When in doubt, state the tier you have achieved and the tier you have NOT yet achieved.** "Local done. Not yet review-ready (PR not created)."

---

## Mapping tiers to workflow stages

| Workflow Stage | Required Tier | Who Verifies |
|---|---|---|
| Task implementation | Tier 1: Local done | Developer / agent |
| Pull request creation | Tier 2: Review-ready done | Developer / agent |
| Code review approval | Tier 3: Merged done | Reviewer + CI |
| Staging deployment | Tier 4: Deployed done | DevOps + automated checks |
| Production release | Tier 5: Verified-in-production done | On-call / release manager |

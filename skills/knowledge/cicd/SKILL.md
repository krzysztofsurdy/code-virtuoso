---
name: cicd
description: CI/CD pipeline patterns and deployment strategies — pipeline design, deployment models (blue-green, canary, rolling), environment promotion, artifact management, and zero-downtime deployment. Use when designing build pipelines, choosing deployment strategies, or improving delivery workflows.
user-invocable: false
---

# CI/CD Pipeline Patterns and Deployment Strategies

Continuous Integration, Continuous Delivery, and Continuous Deployment form a spectrum of automation practices. Each builds on the previous one, progressively reducing manual intervention between a code change and its availability to users.

## CI vs CD vs CD

| Practice | What It Automates | Gate to Next Stage |
|---|---|---|
| **Continuous Integration** | Merging, building, and testing code on every commit | Automated tests must pass before merge |
| **Continuous Delivery** | Packaging and promoting artifacts through environments | Manual approval before production deployment |
| **Continuous Deployment** | Full path from commit to production without manual steps | Automated quality gates replace human approval |

Continuous Integration is the foundation. Without reliable, fast integration, neither delivery nor deployment is sustainable. Start here and expand outward.

---

## Pipeline Design Principles

A well-designed pipeline gives developers fast, trustworthy feedback while preventing broken code from reaching users.

| Principle | Meaning |
|---|---|
| **Fast feedback** | Run the cheapest, fastest checks first -- lint and unit tests before integration tests and builds |
| **Fail early** | Stop the pipeline at the first failure -- do not waste time on downstream stages when upstream checks fail |
| **Reproducibility** | Every pipeline run with the same inputs must produce the same outputs -- pin dependencies, use immutable base images |
| **Idempotency** | Re-running a pipeline stage should be safe and produce the same result |
| **Isolation** | Each pipeline run operates in a clean environment -- no shared state between runs |
| **Security by default** | Secrets are injected at runtime, never stored in source -- scan for vulnerabilities early |

---

## Deployment Strategies Overview

| Strategy | Downtime | Rollback Speed | Infrastructure Cost | Complexity | Best For |
|---|---|---|---|---|---|
| **Blue-Green** | Zero | Instant (traffic switch) | 2x production | Low | Major releases, risk-averse teams |
| **Canary** | Zero | Fast (route traffic back) | 1x + small canary slice | Medium | Data-driven teams, high-traffic services |
| **Rolling** | Zero (if surge configured) | Slow (reverse rollout) | 1x (reuses existing) | Low | Stateless services, frequent small changes |
| **Recreate** | Yes (brief) | Slow (full redeploy) | 1x | Minimal | Dev/staging environments, stateful apps that cannot run two versions |
| **Feature Flags** | Zero | Instant (toggle off) | 1x | Medium | Progressive rollout, A/B testing, trunk-based development |

No single strategy fits every situation. Many teams combine approaches -- for example, canary releases with feature flags for granular control over who sees new functionality.

---

## Environment Management Overview

A typical promotion path moves artifacts through increasingly production-like environments:

```
dev -> staging -> production
```

Key principles:
- **Artifact immutability** -- Build once, deploy the same artifact everywhere. Never rebuild for each environment.
- **Configuration separation** -- Environment-specific values (database URLs, API keys, feature toggles) live outside the artifact.
- **Parity** -- Staging should mirror production as closely as possible in infrastructure, data shape, and scale.
- **Ephemeral environments** -- Spin up isolated environments per pull request for testing and review, then tear them down automatically.

---

## Quick Reference: Pipeline Anti-Patterns

| Anti-Pattern | Problem | Fix |
|---|---|---|
| Rebuilding artifacts per environment | Different binary in staging vs production | Build once, promote the same artifact |
| Long-running monolithic pipeline | Slow feedback, developers context-switch | Parallelize stages, split into focused pipelines |
| Secrets in source control | Credential leaks, compliance violations | Use a secrets manager, inject at runtime |
| Manual environment setup | Configuration drift, "works on my machine" | Infrastructure as code, containerized builds |
| No rollback plan | Extended outages when deployments fail | Automate rollback, test it regularly |
| Skipping staging | Production-only bugs discovered too late | Always promote through at least one pre-production environment |

---

## Reference Files

| Reference | Contents |
|---|---|
| [Pipeline Design](references/pipeline-design.md) | Pipeline stages, parallelization, caching, monorepo patterns, secrets management with multi-format examples |
| [Deployment Strategies](references/deployment-strategies.md) | Blue-green, canary, rolling deployments, feature flags, zero-downtime migrations, rollback strategies |
| [Environment Management](references/environment-management.md) | Environment promotion, infrastructure as code, ephemeral environments, artifact versioning, health checks |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Monitoring and observability for deployments | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for microservices patterns (circuit breakers, health checks) |
| Security scanning in pipelines | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for security practices (OWASP, secure coding) |
| Testing strategy for CI pipelines | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing pyramid and test design |
| API versioning during deployments | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design and evolution strategies |

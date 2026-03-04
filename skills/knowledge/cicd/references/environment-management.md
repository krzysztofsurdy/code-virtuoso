# Environment Management

## Environment Promotion

Artifacts move through increasingly production-like environments. Each gate adds confidence.

| Environment | Purpose | Data | Access |
|---|---|---|---|
| **Dev** | Integration testing, feature validation | Synthetic / seeded | Developers |
| **Staging** | Pre-production validation, performance testing | Production-like (anonymized) | Dev team, QA |
| **Production** | Live user traffic | Real | Restricted, audited |

### Promotion Gates

| Gate | Automated? |
|---|---|
| Unit + integration tests pass | Yes |
| Security scan clean | Yes |
| Smoke tests in target environment | Yes |
| Performance within baseline | Yes |
| Manual approval (continuous delivery) | No |

**GitHub Actions -- environment promotion:**
```yaml
jobs:
  deploy-staging:
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - run: deploy --env staging --version ${{ github.sha }}
      - run: run-smoke-tests --env staging

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
    steps:
      - run: deploy --env production --version ${{ github.sha }}
```

**GitLab CI:**
```yaml
deploy-staging:
  stage: deploy
  script: deploy --env staging --version $CI_COMMIT_SHA
  environment: { name: staging }

deploy-production:
  stage: deploy
  script: deploy --env production --version $CI_COMMIT_SHA
  environment: { name: production }
  when: manual
  needs: [deploy-staging]
```

---

## Infrastructure as Code

| Tenet | Meaning |
|---|---|
| **Declarative** | Describe desired state, not steps |
| **Idempotent** | Applying twice produces the same result |
| **Version-controlled** | Full history, same repo or dedicated one |
| **Reviewable** | Changes go through pull requests |
| **Testable** | Lint, dry-run plans, integration tests before applying |

Run periodic plan/diff commands to detect drift. Alert when actual state diverges from declared state.

---

## Configuration Management

### Per-Environment Configuration

The same artifact runs everywhere; only configuration changes.

**Shell -- environment config loading:**
```bash
#!/usr/bin/env bash
ENV="${DEPLOY_ENV:-dev}"
CONFIG_FILE="config/${ENV}.env"
[ ! -f "$CONFIG_FILE" ] && { echo "No config for: $ENV"; exit 1; }
set -a && source "$CONFIG_FILE" && set +a
```

### Configuration Hierarchy

```
defaults.env        <- shared across all environments
config/dev.env      <- development overrides
config/staging.env  <- staging overrides
config/prod.env     <- production overrides
runtime injection   <- secrets from secrets manager
```

| Category | Storage |
|---|---|
| Non-sensitive config | Config files in version control |
| Sensitive config | Secrets manager, injected at runtime |
| Infrastructure secrets | Secrets manager with restricted access |

---

## Ephemeral Environments

Short-lived, isolated environments created per pull request for testing and review.

### Lifecycle

```
PR opened   -> environment created
PR updated  -> environment redeployed
PR merged   -> environment destroyed
PR closed   -> environment destroyed
```

**GitHub Actions:**
```yaml
on:
  pull_request:
    types: [opened, synchronize, closed]

jobs:
  deploy-preview:
    if: github.event.action != 'closed'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          ENV_NAME="pr-${{ github.event.pull_request.number }}"
          deploy --env "$ENV_NAME" --version ${{ github.sha }}

  cleanup-preview:
    if: github.event.action == 'closed'
    runs-on: ubuntu-latest
    steps:
      - run: destroy-environment --env "pr-${{ github.event.pull_request.number }}"
```

| Concern | Approach |
|---|---|
| Database | Fresh DB per environment, seeded with fixtures |
| External services | Stubs or sandboxed instances |
| Cost control | TTL on environments; auto-destroy on PR closure |
| Naming | Predictable names (e.g., `pr-123`) |
| Resources | Reduced replicas, smaller instances |

---

## Artifact Versioning and Immutability

Build once, deploy the same artifact everywhere. Never rebuild per environment.

| Practice | Why It Matters |
|---|---|
| Tag with commit SHA | Direct traceability to source |
| Never use `latest` in deployments | Mutable and ambiguous |
| Sign artifacts | Verify pipeline origin, detect tampering |
| Store in a registry | Not local builds |

| Versioning Strategy | Format | Use Case |
|---|---|---|
| Commit SHA | `abc1234` | Every build |
| Semantic version | `v2.3.1` | Released packages, APIs |
| Date-based | `2026.03.06-1` | Frequent releases |

**GitLab CI -- build and publish:**
```yaml
build:
  stage: build
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

---

## Post-Deploy Verification

### Health Check Endpoints

| Check | Verifies | On Failure |
|---|---|---|
| **Liveness** | Process is running | Restart instance |
| **Readiness** | Can serve traffic | Remove from load balancer |
| **Dependencies** | DB, cache, queues reachable | Block deployment |

### Smoke Test Script

```bash
#!/usr/bin/env bash
BASE_URL="$1"
FAILURES=0
check_endpoint() {
  local actual=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${1}")
  if [ "$actual" != "$2" ]; then
    echo "FAIL: ${1} returned ${actual} (expected ${2})"
    FAILURES=$((FAILURES + 1))
  else
    echo "PASS: ${1}"
  fi
}
check_endpoint "/health" "200"
check_endpoint "/api/v1/status" "200"
[ "$FAILURES" -gt 0 ] && { echo "${FAILURES} test(s) failed"; exit 1; }
echo "All smoke tests passed"
```

### Verification Order

1. Health endpoint returns 200
2. Core API endpoints respond correctly
3. Critical user flows work
4. Metrics baselines within range
5. No new error log entries in the first minutes

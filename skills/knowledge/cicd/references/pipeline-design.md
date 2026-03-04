# Pipeline Design

## Pipeline Stages

Order stages so the cheapest, fastest checks run first.

| Stage | Purpose | Typical Duration |
|---|---|---|
| **Lint / Static Analysis** | Catch formatting, style, and type errors | Seconds |
| **Unit Tests** | Verify isolated logic | Seconds to low minutes |
| **Build** | Compile, bundle, or package the artifact | Minutes |
| **Integration Tests** | Verify component interactions, API contracts | Minutes |
| **Publish** | Push artifact to registry | Seconds to minutes |
| **Deploy** | Release to target environment | Minutes |

---

## Parallelization

Identify stages with no dependencies and run them concurrently.

**GitHub Actions -- parallel jobs:**
```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make lint

  unit-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make test-unit

  build:
    needs: [lint, unit-test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: make build
```

**GitLab CI -- parallel stages (jobs in the same stage run concurrently):**
```yaml
stages: [check, build, deploy]

lint:
  stage: check
  script: make lint

unit-test:
  stage: check
  script: make test-unit

build:
  stage: build
  script: make build
```

**Shell -- split tests across parallel runners:**
```bash
#!/usr/bin/env bash
TOTAL_RUNNERS=4
RUNNER_INDEX=${CI_NODE_INDEX:-0}
find tests/ -name '*Test.php' | sort | awk "NR % $TOTAL_RUNNERS == $RUNNER_INDEX" | xargs phpunit
```

---

## Caching

Cache dependencies and build outputs between runs to reduce execution time.

**GitHub Actions:**
```yaml
- uses: actions/cache@v4
  with:
    path: vendor
    key: composer-${{ hashFiles('composer.lock') }}
    restore-keys: composer-
```

**GitLab CI:**
```yaml
cache:
  key:
    files: [composer.lock]
  paths: [vendor/]
```

| Cache Target | Key Strategy | Impact |
|---|---|---|
| Package dependencies | Hash of lock file | High |
| Build outputs | Hash of source files | Medium |
| Docker layers | Dockerfile hash | High |

Do not cache secrets, test results, or deployment artifacts.

---

## Monorepo Patterns

### Affected Detection

Only build, test, and deploy packages that changed.

**GitHub Actions -- path-based triggers:**
```yaml
on:
  push:
    paths: ['services/api/**', 'packages/shared/**']
```

**GitLab CI -- rules with changes:**
```yaml
build-api:
  stage: build
  script: make -C services/api build
  rules:
    - changes: [services/api/**/*, packages/shared/**/*]
```

**Shell -- git-based change detection:**
```bash
#!/usr/bin/env bash
CHANGED=$(git diff --name-only origin/main...HEAD | cut -d'/' -f1-2 | sort -u)
for dir in $CHANGED; do
  [ -f "$dir/Makefile" ] && make -C "$dir" ci
done
```

Simple path filtering misses transitive dependencies. If package A depends on B, changes to B should trigger A's pipeline. Use workspace-aware tools that analyze import/dependency graphs.

---

## Pipeline as Code

### Reusable Workflows

**GitHub Actions:**
```yaml
# .github/workflows/reusable-test.yml
on:
  workflow_call:
    inputs:
      working-directory:
        type: string
        required: true
jobs:
  test:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: ${{ inputs.working-directory }}
    steps:
      - uses: actions/checkout@v4
      - run: make test
```

**GitLab CI -- extends and includes:**
```yaml
include:
  - local: templates/test.yml

api-test:
  extends: .test-template
  variables:
    WORKING_DIR: services/api
```

Store pipeline definitions in the same repository as the code. Review pipeline changes through pull requests.

---

## Secrets Management

| Principle | Implementation |
|---|---|
| **Never commit secrets** | Use `.gitignore`, pre-commit hooks, secret scanning |
| **Inject at runtime** | Environment variables or mounted files during execution |
| **Least privilege** | Each job accesses only the secrets it needs |
| **Rotate regularly** | Automate rotation; use short-lived credentials |
| **Audit access** | Log every secret read; alert on anomalies |

**GitHub Actions:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: deploy --token "${{ secrets.DEPLOY_TOKEN }}"
```

**GitLab CI:**
```yaml
deploy:
  stage: deploy
  script: deploy --token "$DEPLOY_TOKEN"
```

**Shell -- vault integration:**
```bash
#!/usr/bin/env bash
export DB_PASSWORD=$(vault kv get -field=password secret/myapp/db)
php bin/console doctrine:migrations:migrate --no-interaction
```

Dynamic secrets are generated on demand with built-in expiration. The pipeline requests a credential, uses it for the run, and it expires automatically -- eliminating manual rotation and limiting blast radius.

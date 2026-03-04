# Deployment Strategies

## Blue-Green Deployment

Two identical production environments. One serves traffic (blue), the other receives the new version (green). After verification, traffic switches.

### How It Works

1. Blue serves all production traffic
2. Deploy new version to green
3. Run smoke tests against green
4. Switch load balancer to green
5. Green is now live; blue becomes standby

### Rollback

Switch traffic back to the previous environment. No redeployment needed -- the old version is still running.

### Database Considerations

Both environments share a database. Schema changes must be backward-compatible with both versions. Use the expand-contract pattern: add new structures first, migrate data, remove old structures in a later release.

**Shell -- load balancer switch:**
```bash
#!/usr/bin/env bash
CURRENT=$(get-active-environment)
TARGET=$( [ "$CURRENT" = "blue" ] && echo "green" || echo "blue" )
update-load-balancer --target "$TARGET"
run-smoke-tests --environment "$TARGET" || { update-load-balancer --target "$CURRENT"; exit 1; }
echo "Active environment: $TARGET"
```

---

## Canary Releases

Route a small percentage of traffic to the new version. If metrics stay healthy, gradually shift all traffic.

### Traffic Splitting

```
Phase 1:  2% canary  |  98% stable
Phase 2: 10% canary  |  90% stable
Phase 3: 50% canary  |  50% stable
Phase 4: 100% canary (promote)
```

### Promotion Criteria

| Metric | What to Watch |
|---|---|
| **Error rate** | HTTP 5xx, exception counts |
| **Latency** | P50, P95, P99 vs baseline |
| **Saturation** | CPU, memory, connection pools |
| **Business** | Conversion rate, order completions |

If any metric degrades beyond threshold, route all traffic back to stable.

**GitHub Actions -- canary workflow:**
```yaml
jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - run: |
          deploy --version ${{ github.sha }} --traffic-weight 5
          sleep 300
          check-metrics --threshold error_rate=0.01,p99_latency=500ms
      - run: |
          deploy --version ${{ github.sha }} --traffic-weight 50
          sleep 300
          check-metrics --threshold error_rate=0.01,p99_latency=500ms
      - run: deploy --version ${{ github.sha }} --traffic-weight 100
```

---

## Rolling Updates

Replace instances incrementally. Both old and new versions run simultaneously during the rollout.

| Parameter | Meaning | Example |
|---|---|---|
| **Max surge** | Extra instances during update | 25% |
| **Max unavailable** | Instances that can be down at once | 1 |
| **Readiness probe** | Must pass before receiving traffic | HTTP 200 on /health |

Rollback requires a reverse rolling update (slower than blue-green). The application must handle mixed-version traffic.

**GitLab CI:**
```yaml
deploy-rolling:
  stage: deploy
  script:
    - kubectl set image deployment/myapp myapp=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - kubectl rollout status deployment/myapp --timeout=300s
```

---

## Feature Flags for Progressive Delivery

Decouple deployment from release. Code is deployed but hidden behind a flag.

### Rollout Pattern

1. Deploy with flag OFF
2. Enable for internal team
3. Enable for 5% of users
4. Monitor, expand to 25%, 50%, 100%
5. Remove flag and dead code

| Strategy | Use Case |
|---|---|
| **Boolean toggle** | Simple on/off |
| **Percentage rollout** | Gradual exposure |
| **User segment** | Beta testers, internal staff, region |
| **Context-based** | Device type, plan tier |

Set expiration dates on flags, track them in a registry, and remove flag code promptly after full rollout.

---

## Zero-Downtime Database Migrations

### Expand-Contract Pattern

**Expand (add new, keep old):**
```sql
ALTER TABLE users ADD COLUMN display_name VARCHAR(255) NULL;
```

**Migrate (backfill in batches):**
```sql
UPDATE users SET display_name = username WHERE display_name IS NULL LIMIT 1000;
```

**Transition:** Deploy code writing to both columns, reading from new with fallback.

**Contract (remove old):**
```sql
ALTER TABLE users DROP COLUMN username;
```

| Rule | Rationale |
|---|---|
| Never rename a column in one step | Running code references the old name |
| Never add NOT NULL without a default | Existing rows fail the constraint |
| Never drop a column running code reads | Old instances crash |
| Run migrations before deploying new code | Old code must tolerate new schema |
| Use online DDL for large tables | Standard ALTER locks the table |

---

## Rollback Strategies

| Strategy | Mechanism | Speed |
|---|---|---|
| **Blue-Green** | Switch traffic back | Instant |
| **Canary** | Route all to stable | Fast |
| **Rolling** | Reverse rolling update | Slow |
| **Feature Flag** | Toggle off | Instant |

### Automated Rollback Triggers

- Error rate exceeds 2x pre-deployment baseline
- P99 latency exceeds SLO
- Health check failures on >N% of instances
- Business metric drops below threshold

**Shell -- automated rollback:**
```bash
#!/usr/bin/env bash
DEPLOY_VERSION="$1"
PREVIOUS_VERSION="$2"
MAX_ERROR_RATE=0.02
deploy --version "$DEPLOY_VERSION"
for i in $(seq 1 10); do
  sleep 30
  ERROR_RATE=$(get-error-rate --window 30s)
  if (( $(echo "$ERROR_RATE > $MAX_ERROR_RATE" | bc -l) )); then
    echo "Rolling back to $PREVIOUS_VERSION (error rate: $ERROR_RATE)"
    deploy --version "$PREVIOUS_VERSION"
    exit 1
  fi
done
echo "Deployment verified"
```

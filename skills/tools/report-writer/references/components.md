# Report HTML components

Copy-paste HTML for every component that `template.html` styles. All components go inside the `{{REPORT_CONTENT}}` placeholder of a narrative report.

## Contents

- [Core components](#core-components): section with icon, icon reference, info and highlighted cards, timeline, code block, impact grid, decision log, file list, stats bar
- [Advanced components](#advanced-components): horizontal timeline, phased vertical timeline, data table, arrow annotation

## Core components

### Section with icon

Icons come from [Bootstrap Icons](https://icons.getbootstrap.com/) via CDN (already included in the template).

```html
<div class="section mb-9">
    <h2 class="text-xl font-bold text-slate-900 mb-4 pb-2 border-b border-slate-200 flex items-center gap-2">
        <i class="bi bi-search"></i> Root Cause Analysis
    </h2>
    <p>Description text here...</p>
</div>
```

### Section icon reference

| Icon class | Use for |
|------|---------|
| `bi bi-bullseye` | Overview, Objective, Problem Statement |
| `bi bi-search` | Root Cause, Investigation, Analysis |
| `bi bi-tools` | Solution, Implementation, Approach |
| `bi bi-folder2-open` | Files Changed, Scope |
| `bi bi-check-circle` | Testing, Verification |
| `bi bi-bar-chart` | Impact, Metrics, Statistics |
| `bi bi-rocket-takeoff` | Deployment, Next Steps |
| `bi bi-clock-history` | Timeline, Chronology |
| `bi bi-lightbulb` | Recommendations, Insights |
| `bi bi-exclamation-triangle` | Risks, Warnings, Caveats |
| `bi bi-building` | Architecture, Design |
| `bi bi-card-checklist` | Summary, Configuration |
| `bi bi-gear` | Configuration, Setup |
| `bi bi-pencil-square` | Notes, Documentation |

### Info card

```html
<div class="card">
    <strong>Key Finding:</strong> The timeout was caused by a missing index
    on the <code>payments</code> table, leading to full table scans under load.
</div>
```

### Highlighted card (warning/important)

```html
<div class="card highlight">
    <strong>⚠️ Important:</strong> This change requires a database migration
    to be run before deployment.
</div>
```

### Timeline

```html
<div class="timeline">
    <div class="timeline-item">
        <div class="timeline-marker"></div>
        <div class="timeline-content">
            <strong>Step 1: Reproduced the issue</strong>
            <p>Confirmed the timeout occurs on orders with 50+ line items...</p>
        </div>
    </div>
    <div class="timeline-item">
        <div class="timeline-marker"></div>
        <div class="timeline-content">
            <strong>Step 2: Identified slow query</strong>
            <p>Used <code>EXPLAIN ANALYZE</code> to find the missing index...</p>
        </div>
    </div>
</div>
```

### Code block

```html
<pre><code># Before: N+1 query pattern
for order in orders:
    items = order_repo.find_by_order_id(order.id)

# After: Eager loading with single query
orders = order_repo.find_with_items(criteria)</code></pre>
```

### Impact grid

```html
<div class="impact-grid">
    <div class="impact-item low">
        <strong>Performance</strong>
        <span>Query time: 2.3s → 45ms</span>
    </div>
    <div class="impact-item medium">
        <strong>Risk Level</strong>
        <span>Medium - new index on production table</span>
    </div>
    <div class="impact-item high">
        <strong>Urgency</strong>
        <span>High - affecting 12% of checkouts</span>
    </div>
</div>
```

Impact item classes: `low` (green), `medium` (amber), `high` (red).

### Decision log

```html
<div class="decision-log">
    <div class="decision">
        <div class="decision-title">Accepted: Use composite index instead of separate indexes</div>
        <div class="decision-detail">
            <strong>Rationale:</strong> Composite index covers both the WHERE clause
            and ORDER BY, avoiding a filesort. Benchmarked 3x faster than two
            separate indexes.
        </div>
    </div>
    <div class="decision">
        <div class="decision-title">Rejected: Caching layer</div>
        <div class="decision-detail">
            <strong>Reason:</strong> Would add complexity and staleness risk.
            The index fix resolves the root cause without adding infrastructure.
        </div>
    </div>
</div>
```

### File list

```html
<div class="file-list">
    <div class="file-item">
        <span class="file-name">src/repository/order_repository.ext</span>
        <span class="file-badge modified">Modified</span>
        <div class="file-detail">Added eager loading for order items</div>
    </div>
    <div class="file-item">
        <span class="file-name">migrations/20250115_add_order_index.ext</span>
        <span class="file-badge added">Added</span>
        <div class="file-detail">Composite index on (user_id, created_at)</div>
    </div>
    <div class="file-item">
        <span class="file-name">src/service/legacy_order_loader.ext</span>
        <span class="file-badge deleted">Deleted</span>
        <div class="file-detail">Replaced by repository method</div>
    </div>
</div>
```

File badge classes: `added` (green), `modified` (blue), `deleted` (red).

### Stats bar

```html
<div class="stats-bar">
    <div class="stat">
        <div class="stat-value">7</div>
        <div class="stat-label">Files Changed</div>
    </div>
    <div class="stat">
        <div class="stat-value">+142</div>
        <div class="stat-label">Lines Added</div>
    </div>
    <div class="stat">
        <div class="stat-value">-89</div>
        <div class="stat-label">Lines Removed</div>
    </div>
    <div class="stat">
        <div class="stat-value">5</div>
        <div class="stat-label">Tests Added</div>
    </div>
</div>
```

## Advanced components

### Horizontal timeline (phase overview)

```html
<div class="horizontal-timeline">
    <div class="ht-phase completed">
        <div class="ht-marker">1</div>
        <div class="ht-label">Discovery</div>
    </div>
    <div class="ht-connector completed"></div>
    <div class="ht-phase completed">
        <div class="ht-marker">2</div>
        <div class="ht-label">Analysis</div>
    </div>
    <div class="ht-connector active"></div>
    <div class="ht-phase active">
        <div class="ht-marker">3</div>
        <div class="ht-label">Implementation</div>
    </div>
    <div class="ht-connector"></div>
    <div class="ht-phase">
        <div class="ht-marker">4</div>
        <div class="ht-label">Verification</div>
    </div>
</div>
```

Phase classes: (none) = pending, `active` = current, `completed` = done.

### Phased vertical timeline

```html
<div class="phase-timeline">
    <div class="phase-group">
        <div class="phase-header">Phase 1: Discovery</div>
        <div class="timeline">
            <div class="timeline-item">
                <div class="timeline-marker"></div>
                <div class="timeline-content">
                    <strong>Identified failing tests</strong>
                    <p>3 integration tests failing intermittently on CI...</p>
                </div>
            </div>
        </div>
    </div>
    <div class="phase-group">
        <div class="phase-header">Phase 2: Root Cause</div>
        <div class="timeline">
            <div class="timeline-item">
                <div class="timeline-marker"></div>
                <div class="timeline-content">
                    <strong>Race condition in event handler</strong>
                    <p>Two listeners processing the same event concurrently...</p>
                </div>
            </div>
        </div>
    </div>
</div>
```

### Data table

```html
<table class="data-table">
    <thead>
        <tr>
            <th>Endpoint</th>
            <th>Before</th>
            <th>After</th>
            <th>Improvement</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td><code>/api/orders</code></td>
            <td>2,340ms</td>
            <td>45ms</td>
            <td class="positive">98% faster</td>
        </tr>
        <tr>
            <td><code>/api/users</code></td>
            <td>180ms</td>
            <td>165ms</td>
            <td class="neutral">8% faster</td>
        </tr>
    </tbody>
</table>
```

Table cell classes: `positive` (green), `negative` (red), `neutral` (gray).

### Arrow annotation

```html
<div class="arrow-annotation">
    <div class="arrow-from">
        <code>OrderService.checkout()</code>
    </div>
    <div class="arrow-line">→</div>
    <div class="arrow-to">
        <code>PaymentGateway.charge()</code>
    </div>
    <div class="arrow-label">Timeout occurs here (>30s)</div>
</div>
```

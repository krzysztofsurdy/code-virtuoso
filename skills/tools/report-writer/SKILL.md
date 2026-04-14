---
name: report-writer
description: Generate a polished standalone HTML report summarizing changes, findings, debug investigations, or architectural decisions. Opens automatically in the browser. Use after completing work on a ticket, investigation, or debug session.
user-invocable: true
argument-hint: "[optional: ticket-id or report-name]"
---

# Report Generator

Generate a professional, standalone HTML report summarizing the work you just completed -- bug fixes, features, refactoring, investigations, or debug sessions. The report opens automatically in the default browser.

## When to Use

- After completing work on a ticket (use with the `ticket-delivery` skill)
- After a debug/investigation session
- To document architectural decisions
- To summarize a refactoring effort
- Whenever you want a polished record of what was done and why

## Quick Start

```
/report-writer PROJ-1234
/report-writer auth-migration-investigation
/report-writer                  # auto-names from branch
```

## Report Types

### Bug Fix Report

Sections to include:
1. **Problem Statement** -- What was broken, who was affected, symptoms
2. **Root Cause Analysis** -- Why it happened, the chain of events
3. **Investigation Timeline** -- Steps taken to diagnose
4. **Solution** -- What was changed and why this approach
5. **Files Changed** -- List of modified files with brief descriptions
6. **Testing** -- How the fix was verified
7. **Impact Assessment** -- Risk level, rollback plan, monitoring

### Feature Report

Sections to include:
1. **Overview** -- What the feature does, business context
2. **Architecture** -- How it fits into the system, design decisions
3. **Implementation Details** -- Key components, patterns used
4. **Files Changed** -- New and modified files
5. **Configuration** -- Any new config, env vars, feature flags
6. **Testing** -- Test coverage, edge cases considered
7. **Deployment Notes** -- Migration steps, dependencies, rollout plan

### Refactoring Report

Sections to include:
1. **Motivation** -- Why the refactoring was needed
2. **Scope** -- What was refactored, what was left untouched
3. **Approach** -- Strategy used (e.g., strangler fig, parallel implementation)
4. **Before/After** -- Key structural comparisons
5. **Files Changed** -- Renamed, moved, deleted, created
6. **Risk Assessment** -- What could break, how it was mitigated
7. **Follow-Up** -- Remaining tech debt, future improvements

### Investigation / Debug Report

Sections to include:
1. **Objective** -- What was being investigated
2. **Hypothesis** -- Initial theories
3. **Investigation Timeline** -- Chronological steps and findings
4. **Evidence** -- Logs, metrics, code snippets
5. **Conclusions** -- What was found
6. **Recommendations** -- Suggested actions
7. **Open Questions** -- Unresolved items

## Generating the Report

### Step 1: Gather Data

Collect information from your working session:

```bash
# Detect the main branch dynamically
MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Get the merge base
MERGE_BASE=$(git merge-base HEAD "$MAIN_BRANCH")

# Changed files
git diff --name-status "$MERGE_BASE"..HEAD

# Full diff
git diff "$MERGE_BASE"..HEAD

# Commit log
git log --oneline "$MERGE_BASE"..HEAD

# Stats
git diff --stat "$MERGE_BASE"..HEAD
```

### Step 2: Build the HTML

Use the template at `references/template.html` as the base. Replace the placeholder tokens:

| Token | Replace With |
|-------|-------------|
| `{{REPORT_TITLE}}` | Report title (e.g., "PROJ-1234: Fix payment timeout") |
| `{{REPORT_SUBTITLE}}` | Short subtitle or ticket summary |
| `{{REPORT_DATE}}` | Date in format "January 15, 2025" |
| `{{REPORT_CONTENT}}` | All HTML content sections (see components below) |
| `{{TICKET_ID}}` | Ticket identifier (e.g., "PROJ-1234") |
| `{{BRANCH_NAME}}` | Git branch name |
| `{{AUTHOR_NAME}}` | Author name |
| `{{GENERATED_BY}}` | "report-writer" |

### Step 3: Save and Open

```bash
# Save to /tmp
REPORT_PATH="/tmp/report-$(date +%Y%m%d-%H%M%S).html"

# Write the HTML content to the file
cat > "$REPORT_PATH" << 'REPORT_EOF'
... generated HTML ...
REPORT_EOF

# Open in the default browser
# macOS:    open "$REPORT_PATH"
# Linux:    xdg-open "$REPORT_PATH"
# Windows:  start "$REPORT_PATH"
```

## HTML Components Reference

All components go inside the `{{REPORT_CONTENT}}` placeholder.

### Section with Icon

Uses [Bootstrap Icons](https://icons.getbootstrap.com/) via CDN (already included in the template).

```html
<div class="section mb-9">
    <h2 class="text-xl font-bold text-slate-900 mb-4 pb-2 border-b border-slate-200 flex items-center gap-2">
        <i class="bi bi-search"></i> Root Cause Analysis
    </h2>
    <p>Description text here...</p>
</div>
```

### Section Icon Reference

| Icon class | Use For |
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

### Info Card

```html
<div class="card">
    <strong>Key Finding:</strong> The timeout was caused by a missing index
    on the <code>payments</code> table, leading to full table scans under load.
</div>
```

### Highlighted Card (Warning/Important)

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

### Code Block

```html
<pre><code># Before: N+1 query pattern
for order in orders:
    items = order_repo.find_by_order_id(order.id)

# After: Eager loading with single query
orders = order_repo.find_with_items(criteria)</code></pre>
```

### Impact Grid

```html
<div class="impact-grid">
    <div class="impact-item low">
        <strong>Performance</strong>
        <span>Query time: 2.3s → 45ms</span>
    </div>
    <div class="impact-item medium">
        <strong>Risk Level</strong>
        <span>Medium -- new index on production table</span>
    </div>
    <div class="impact-item high">
        <strong>Urgency</strong>
        <span>High -- affecting 12% of checkouts</span>
    </div>
</div>
```

Impact item classes: `low` (green), `medium` (amber), `high` (red).

### Decision Log

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

### File List

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

### Stats Bar

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

## Advanced Components

### Horizontal Timeline (Phase Overview)

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

### Phased Vertical Timeline

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

### Data Table

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

### Arrow Annotation

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

## Design Principles

1. **Standalone** -- The HTML file must work with zero external dependencies. All CSS and JS are inlined.
2. **Professional** -- Clean typography, consistent spacing, subtle color palette. No garish colors.
3. **Informative** -- Every section should add value. Don't pad with boilerplate.
4. **Scannable** -- Use headers, cards, and visual hierarchy so readers can skim.
5. **Printable** -- The report should look good when printed (the template includes print styles).
6. **Accurate** -- All file names, line counts, and code snippets must match the actual work done.

## Integration with ticket-delivery

When using `report-writer` after completing a ticket with `ticket-delivery`:

```
# 1. Complete the ticket work
/ticket-delivery PROJ-1234

# 2. Generate a report summarizing what was done
/report-writer PROJ-1234
```

The report generator will automatically gather git diff data, commit history, and file changes from your working branch.

## Reference Files

| Reference | Contents |
|---|---|
| [template.html](references/template.html) | Full standalone HTML template with all CSS, JS, and component styles baked in |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| When completing a ticket end-to-end | `ticket-delivery` |
| When writing a PR description | `pr-message-writer` |

## Examples

```
/report-writer PROJ-1234          # Bug fix report for ticket PROJ-1234
/report-writer PROJ-5678          # Feature report for ticket PROJ-5678
/report-writer PROJ-9012          # Refactoring report for ticket PROJ-9012
/report-writer auth-investigation  # Investigation report (no ticket)
/report-writer                     # Auto-detect from branch name
```

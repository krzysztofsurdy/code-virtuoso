---
name: report-writer
description: Generate a polished standalone HTML report summarizing changes, findings, debug investigations, or architectural decisions. Opens automatically in the browser. Use after completing work on a ticket, investigation, or debug session.
user-invocable: true
argument-hint: "[optional: ticket-id or report-name]"
---

# Report Generator

Generate a professional, standalone HTML report summarizing the work you just completed - bug fixes, features, refactoring, investigations, or debug sessions. The report opens automatically in the default browser.

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
1. **Problem Statement** - What was broken, who was affected, symptoms
2. **Root Cause Analysis** - Why it happened, the chain of events
3. **Investigation Timeline** - Steps taken to diagnose
4. **Solution** - What was changed and why this approach
5. **Files Changed** - List of modified files with brief descriptions
6. **Testing** - How the fix was verified
7. **Impact Assessment** - Risk level, rollback plan, monitoring

### Feature Report

Sections to include:
1. **Overview** - What the feature does, business context
2. **Architecture** - How it fits into the system, design decisions
3. **Implementation Details** - Key components, patterns used
4. **Files Changed** - New and modified files
5. **Configuration** - Any new config, env vars, feature flags
6. **Testing** - Test coverage, edge cases considered
7. **Deployment Notes** - Migration steps, dependencies, rollout plan

### Refactoring Report

Sections to include:
1. **Motivation** - Why the refactoring was needed
2. **Scope** - What was refactored, what was left untouched
3. **Approach** - Strategy used (e.g., strangler fig, parallel implementation)
4. **Before/After** - Key structural comparisons
5. **Files Changed** - Renamed, moved, deleted, created
6. **Risk Assessment** - What could break, how it was mitigated
7. **Follow-Up** - Remaining tech debt, future improvements

### Investigation / Debug Report

Sections to include:
1. **Objective** - What was being investigated
2. **Hypothesis** - Initial theories
3. **Investigation Timeline** - Chronological steps and findings
4. **Evidence** - Logs, metrics, code snippets
5. **Conclusions** - What was found
6. **Recommendations** - Suggested actions
7. **Open Questions** - Unresolved items

### Data Explorer / Interactive Dashboard Report

For when the report is *data*, not a narrative - e.g. a CSV export, a compliance audit, an error-frequency dump. Output is a single standalone HTML file that lets the reader filter, slice, chart, and export the dataset themselves. Use this instead of a narrative report when the reader is going to do `awk` / `grep` / pivot-table work.

#### Default path

For most cases use the generic files in this skill directly - you do NOT need to write new HTML or JS:

- **[data-explorer-template.html](references/data-explorer-template.html)** - domain-agnostic template with `{{TOKEN}}` placeholders (filter builder, Chart.js charts, dynamic stat cards, sortable records table, CSV export - all dark-themed).
- **[data-explorer-generator.py](references/data-explorer-generator.py)** - ~60-line script that fills the template:

  ```bash
  python references/data-explorer-generator.py --csv data.csv --out report.html --config report_config.json
  ```

  The config JSON declares title, requirements HTML, default filters, charts, stat cards, search fields, multi-valued columns, and a fixed value-to-color map.

If the dataset has quirks (synthetic derived fields, custom reason categorization, bespoke charts), copy `data-explorer-template.html` and inline-edit the JS.

#### Page layout (top to bottom)

1. **Header** - title, source filename, generation timestamp, total record count.
2. **What this report measures** - three collapsible `<details>` blocks: (a) every check the dataset encodes, (b) requirements we deliberately cannot measure and why, (c) checks the upstream system runs but does not persist. The reader has to know what is and is not in the data before slicing it. This is the single biggest difference from narrative reports.
3. **Filters** (see Filter Builder below). Pre-load at least one sensible default (e.g. `teacher_type is one of [b2c]`); Reset returns to the default, not to empty.
4. **Records table** - placed directly under the filters so the reader sees their filter changes reflected immediately. ALL columns from the CSV (horizontal scroll; do not pre-pick). Includes the "Export filtered CSV" button so the reader can grab the filtered subset without leaving the page.
5. **Summary stat cards** - live counts that re-render on every filter change. Color cards by polarity (`good` / `bad` / `warn`).
6. **Breakdowns / charts** - `repeat(auto-fit, minmax(380px, 1fr))` so it reflows on resize.

**Order matters:** filters → records → summary → charts. The reader's first instinct is to filter, then verify the filtered rows look right in the table, *then* check the aggregates and visuals. The table is the source of truth.

#### Source format

Take a CSV (or any tabular export) and a generator script that emits one HTML file. Keep the generator tiny - the page does all the work.

```
src/scripts/<topic>_report_html.py     # generator (or use the generic one)
<topic>.csv                            # input
<topic>_report.html                    # output (1-2 MB is fine)
```

The generator should:

1. `csv.DictReader` the input.
2. Embed the rows as JSON in a `<script type="application/json">` tag (do NOT inline as a JS literal - the browser parses JSON faster and quoting is safer).
3. Embed the column order as a separate JSON tag so the table and CSV-export reuse it.
4. Replace `{{TOKEN}}` placeholders in the HTML template.

Reading the embedded JSON in the page:

```js
const RECORDS = JSON.parse(document.getElementById("data-records").textContent);
const COLUMNS = JSON.parse(document.getElementById("data-columns").textContent);
```

#### Filter Builder (Kibana-style)

Each filter is a row: `[enable toggle] [field] [operator] [value] [×]`. Filters are AND-combined. Disabling a row keeps its config but stops applying it - this is the "ignore value" affordance.

**Operators to ship:**

| Operator key | Label | Value UI | Notes |
|---|---|---|---|
| `is` | is | text + datalist | exact match |
| `is_not` | is not | text + datalist | exact non-match |
| `contains` | contains | text + datalist | case-insensitive substring |
| `not_contains` | does not contain | text + datalist | |
| `one_of` | is one of | multi-select | values list from the field |
| `not_one_of` | is not one of | multi-select | |
| `exists` | exists | (none) | non-empty value |
| `not_exists` | does not exist | (none) | |
| `gt` / `gte` / `lt` / `lte` | `>`, `>=`, `<`, `<=` | number input | for numeric columns |

**State shape:**

```js
let filters = [
  { id: 1, field: "teacher_type", op: "one_of", value: ["b2c"], enabled: true }
];
```

`field` may be a real column, a multi-valued column, or a synthetic field that you compute from a row (e.g. `(probe state)` for a derived bucket). Treat both in `fieldValue(record, field)`.

**Multi-valued field handling:** if a column packs multiple values (e.g. `"german|english|spanish"`), split at lookup time and make `is` / `contains` / `one_of` match if ANY element qualifies. Document this in the filter-builder hint text; it surprises users otherwise. The generic template handles this via a `MULTI_VALUED` config map (`{"languages": "|"}`).

**Why not five separate dropdowns?** You can ship narrow reports with hard-coded filters (teacher type, language, state). The moment the reader asks "what about CPU thread count >= 4 AND browser contains Chrome AND state is non_compliant" you have to ship the builder anyway. Build it once.

#### Charts (Chart.js)

Load from CDN: `<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>`. No npm, no bundler.

**Container CSS - the gotcha.** Chart.js with `responsive: true` + `maintainAspectRatio: false` expands the canvas to fill its parent. If the parent has no fixed height, you get a 2000px-tall chart. **Always** wrap the canvas in a `position: relative` div with an explicit height:

```css
.chart .canvas-wrap { position: relative; flex: 1 1 auto; height: 300px; }
.chart canvas { max-width: 100%; }
.chart.tall .canvas-wrap { height: 420px; }   /* horizontal bars with many rows */
```

```html
<div class="chart"><h3>...</h3><div class="canvas-wrap"><canvas id="..."></canvas></div></div>
```

**Re-render, don't recreate.** Cache chart instances by id and call `chart.update()` when filters change. Recreating destroys the canvas context every time and leaks memory.

**Chart mix that usually pays off:**

| Visual | Use for |
|---|---|
| Doughnut | Pass/fail status, vendor distribution, single categorical breakdown |
| Stacked bar (vertical) | Compliance broken down by another category (e.g. by teacher type) |
| Stacked bar (`indexAxis: "y"`) | Top-N reasons, long category labels |
| Plain bar | Quality levels with semantic colors (GOOD = green, BAD = red) |

**Categorizing free-text reasons.** If your dataset has a `reason` column with delimited atoms (`"completion_type=partial; unsupported:Virtual Background; build_bitness=32-bit"`), bucket them in JS before charting so the top-N bar is readable:

```js
function categorizeReason(atom) {
  const s = atom.trim();
  if (s.startsWith("unsupported:")) return "Unsupported feature: " + s.slice(12);
  if (s.startsWith("build_bitness=")) return "Not 64-bit OS";
  if (s.startsWith("hardware_acceleration=")) return "Hardware acceleration off";
  return s;
}
```

#### Records table conventions

- Render ALL CSV columns (`TABLE_COLUMNS = COLUMNS`). Horizontal scroll handles width.
- Click-to-sort by any column (toggle ascending / descending).
- Cap visible rows at 500 for performance; show `"500 of 12345 (sorted by X)"` in a pager line.
- Position `<th>` as `position: sticky; top: 0` so headers stay visible while scrolling.

#### Search vs filter builder

Keep a free-text search input in addition to the builder. It is faster than building `contains` filters across five identity fields:

```js
const hay = SEARCH_FIELDS.map(c => r[c] || "").join(" ").toLowerCase();
if (!hay.includes(search)) return false;
```

#### CSV export

```js
function exportCsv() {
  const rows = applyFilters();
  const out = [COLUMNS.join(",")];
  for (const r of rows) {
    out.push(COLUMNS.map(c => {
      const v = (r[c] || "").toString();
      return /[",\n]/.test(v) ? '"' + v.replace(/"/g, '""') + '"' : v;
    }).join(","));
  }
  const blob = new Blob([out.join("\n")], { type: "text/csv" });
  const a = document.createElement("a");
  a.href = URL.createObjectURL(blob);
  a.download = "filtered.csv";
  a.click();
}
```

#### Theming

Dark theme works better for dense data screens (less eye strain over a 30-minute filtering session). CSS custom properties for swappable palettes:

```css
:root {
  --bg: #0f172a;
  --panel: #1e293b;
  --panel2: #273449;
  --text: #e2e8f0;
  --muted: #94a3b8;
  --border: #334155;
  --good: #34d399;
  --bad: #f87171;
  --warn: #fbbf24;
}
```

Keep all dark-bg charts grid + tick text in `--muted` (`#94a3b8`) so axes don't dominate.

#### Pitfalls worth naming

- **Don't embed data as a JS literal** - escaping breaks on quotes / newlines. Use `<script type="application/json">` and `JSON.parse`.
- **Don't forget the canvas wrapper height** - you'll think the charts are broken; they're just unbounded.
- **Don't ship per-feature columns AND a feature donut AND a feature stacked bar.** Pick one place for that dimension; redundancy clutters the page.
- **Don't pre-filter the data in Python.** Embed the full dataset and let the page filter. The reader will want to slice it differently than you predicted.
- **Don't forget the documentation `<details>`.** A reader without context will misread the chart axes and you'll get the wrong follow-up question.

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
        <span>Medium - new index on production table</span>
    </div>
    <div class="impact-item high">
        <strong>Urgency</strong>
        <span>High - affecting 12% of checkouts</span>
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

1. **Standalone** - The HTML file must work with zero external dependencies. All CSS and JS are inlined.
2. **Professional** - Clean typography, consistent spacing, subtle color palette. No garish colors.
3. **Informative** - Every section should add value. Don't pad with boilerplate.
4. **Scannable** - Use headers, cards, and visual hierarchy so readers can skim.
5. **Printable** - The report should look good when printed (the template includes print styles).
6. **Accurate** - All file names, line counts, and code snippets must match the actual work done.

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
| [template.html](references/template.html) | Standalone HTML template for narrative-style reports (bug fixes, features, investigations). All CSS, JS, and component styles inlined. |
| [data-explorer-template.html](references/data-explorer-template.html) | Generic, domain-agnostic data-explorer template - filter builder, configurable charts, dynamic stat cards, sortable records table, CSV export. Fill the `{{TOKEN}}` placeholders. |
| [data-explorer-generator.py](references/data-explorer-generator.py) | Tiny Python generator that takes any CSV + a JSON config and produces a ready-to-open data-explorer HTML report from the template. |

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

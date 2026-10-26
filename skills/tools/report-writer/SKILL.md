---
name: report-writer
description: Generates a standalone HTML report summarizing changes, findings, debug investigations, or architectural decisions, and opens it in the browser. Use after completing work on a ticket, investigation, or debug session.
user-invocable: true
argument-hint: "[optional: ticket-id or report-name]"
---

# Report generator

Generate a standalone HTML report summarizing the work you just completed: bug fixes, features, refactoring, investigations, or debug sessions. The report opens in the default browser.

## When to use

- After completing work on a ticket
- After a debug/investigation session
- To document architectural decisions
- To summarize a refactoring effort
- Whenever you want a record of what was done and why

## Quick start

```
/report-writer PROJ-1234
/report-writer auth-migration-investigation
/report-writer                  # auto-names from branch
```

## Report types

### Bug fix report

Sections to include:
1. **Problem statement** - What was broken, who was affected, symptoms
2. **Root cause analysis** - Why it happened, the chain of events
3. **Investigation timeline** - Steps taken to diagnose
4. **Solution** - What was changed and why this approach
5. **Files changed** - List of modified files with brief descriptions
6. **Testing** - How the fix was verified
7. **Impact assessment** - Risk level, rollback plan, monitoring

### Feature report

Sections to include:
1. **Overview** - What the feature does, business context
2. **Architecture** - How it fits into the system, design decisions
3. **Implementation details** - Key components, patterns used
4. **Files changed** - New and modified files
5. **Configuration** - Any new config, env vars, feature flags
6. **Testing** - Test coverage, edge cases considered
7. **Deployment notes** - Migration steps, dependencies, rollout plan

### Refactoring report

Sections to include:
1. **Motivation** - Why the refactoring was needed
2. **Scope** - What was refactored, what was left untouched
3. **Approach** - Strategy used (e.g., strangler fig, parallel implementation)
4. **Before/After** - Key structural comparisons
5. **Files changed** - Renamed, moved, deleted, created
6. **Risk assessment** - What could break, how it was mitigated
7. **Follow-up** - Remaining tech debt, future improvements

### Investigation / debug report

Sections to include:
1. **Objective** - What was being investigated
2. **Hypothesis** - Initial theories
3. **Investigation timeline** - Chronological steps and findings
4. **Evidence** - Logs, metrics, code snippets
5. **Conclusions** - What was found
6. **Recommendations** - Suggested actions
7. **Open questions** - Unresolved items

### Data explorer / interactive dashboard report

Use this when the report is data, not a narrative: a CSV export, a compliance audit, an error-frequency dump. The output is a single standalone HTML file that lets the reader filter, slice, chart, and export the dataset. Pick it over a narrative report when the reader is going to do `awk`, `grep`, or pivot-table work.

#### Default path

In most cases use the generic files in this skill directly. You do not need to write new HTML or JS:

- **[data-explorer-template.html](references/data-explorer-template.html)** - domain-agnostic template with `{{TOKEN}}` placeholders (filter builder, Chart.js charts, dynamic stat cards, sortable records table, CSV export, all dark-themed).
- **[data-explorer-generator.py](references/data-explorer-generator.py)** - ~60-line script that fills the template:

  ```bash
  python references/data-explorer-generator.py --csv data.csv --out report.html --config report_config.json
  ```

  The config JSON declares title, requirements HTML, default filters, charts, stat cards, search fields, multi-valued columns, and a fixed value-to-color map.

If the dataset has quirks (synthetic derived fields, custom reason categorization, bespoke charts), copy `data-explorer-template.html` and edit the JS inline.

#### Page layout (top to bottom)

1. **Header** - title, source filename, generation timestamp, total record count.
2. **What this report measures** - three collapsible `<details>` blocks: (a) every check the dataset encodes, (b) requirements we deliberately cannot measure and why, (c) checks the upstream system runs but does not persist. The reader needs to know what is and is not in the data before slicing it. This is the biggest difference from narrative reports.
3. **Filters** (see Filter builder below). Pre-load at least one sensible default (e.g. `teacher_type is one of [b2c]`); Reset returns to the default, not to empty.
4. **Records table** - placed directly under the filters so the reader sees their filter changes reflected immediately. All columns from the CSV (horizontal scroll; do not pre-pick). Include the "Export filtered CSV" button so the reader can grab the filtered subset without leaving the page.
5. **Summary stat cards** - live counts that re-render on every filter change. Color cards by polarity (`good` / `bad` / `warn`).
6. **Breakdowns / charts** - `repeat(auto-fit, minmax(380px, 1fr))` so it reflows on resize.

**Order matters:** filters → records → summary → charts. The reader filters first, checks the filtered rows in the table, and only then looks at the aggregates and visuals. The table is the source of truth.

#### Source format

Take a CSV (or any tabular export) and a generator script that emits one HTML file. Keep the generator small. The page does the work.

```
src/scripts/<topic>_report_html.py     # generator (or use the generic one)
<topic>.csv                            # input
<topic>_report.html                    # output (1-2 MB is fine)
```

The generator should:

1. `csv.DictReader` the input.
2. Embed the rows as JSON in a `<script type="application/json">` tag (do not inline as a JS literal: the browser parses JSON faster and quoting is safer).
3. Embed the column order as a separate JSON tag so the table and CSV-export reuse it.
4. Replace `{{TOKEN}}` placeholders in the HTML template.

Reading the embedded JSON in the page:

```js
const RECORDS = JSON.parse(document.getElementById("data-records").textContent);
const COLUMNS = JSON.parse(document.getElementById("data-columns").textContent);
```

#### Filter builder (Kibana-style)

Each filter is a row: `[enable toggle] [field] [operator] [value] [×]`. Filters are AND-combined. Disabling a row keeps its config but stops applying it, which gives the reader an "ignore value" switch.

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

`field` may be a real column, a multi-valued column, or a synthetic field that you compute from a row (e.g. `(probe state)` for a derived bucket). Handle both in `fieldValue(record, field)`.

**Multi-valued field handling:** if a column packs multiple values (e.g. `"german|english|spanish"`), split at lookup time and make `is` / `contains` / `one_of` match if any element qualifies. Say so in the filter-builder hint text, or users will be surprised. The generic template handles this via a `MULTI_VALUED` config map (`{"languages": "|"}`).

**Why not five separate dropdowns?** A narrow report can ship with hard-coded filters (teacher type, language, state). As soon as the reader asks "what about CPU thread count >= 4 AND browser contains Chrome AND state is non_compliant", you need the builder anyway. Build it once.

#### Charts (Chart.js)

Load from the CDN: `<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>`. No npm, no bundler.

**Container CSS.** Chart.js with `responsive: true` and `maintainAspectRatio: false` expands the canvas to fill its parent. If the parent has no fixed height, you get a 2000px-tall chart. Always wrap the canvas in a `position: relative` div with an explicit height:

```css
.chart .canvas-wrap { position: relative; flex: 1 1 auto; height: 300px; }
.chart canvas { max-width: 100%; }
.chart.tall .canvas-wrap { height: 420px; }   /* horizontal bars with many rows */
```

```html
<div class="chart"><h3>...</h3><div class="canvas-wrap"><canvas id="..."></canvas></div></div>
```

**Re-render, don't recreate.** Cache chart instances by id and call `chart.update()` when filters change. Recreating a chart destroys the canvas context each time and leaks memory.

**Chart mix that usually works:**

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

- Render all CSV columns (`TABLE_COLUMNS = COLUMNS`). Horizontal scroll handles width.
- Click-to-sort by any column (toggle ascending / descending).
- Cap visible rows at 500 for performance; show `"500 of 12345 (sorted by X)"` in a pager line.
- Position `<th>` as `position: sticky; top: 0` so headers stay visible while scrolling.

#### Search vs filter builder

Keep a free-text search input in addition to the builder. It is quicker than building `contains` filters across five identity fields:

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

A dark theme suits dense data screens and is easier on the eyes over a 30-minute filtering session. Use CSS custom properties so palettes can be swapped:

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

Set chart grid lines and tick text on dark backgrounds to `--muted` (`#94a3b8`) so the axes don't dominate.

#### Pitfalls

- **Don't embed data as a JS literal.** Escaping breaks on quotes and newlines. Use `<script type="application/json">` and `JSON.parse`.
- **Don't forget the canvas wrapper height.** The charts will look broken when they are just unbounded.
- **Don't ship per-feature columns and a feature donut and a feature stacked bar.** Pick one place for each dimension. Redundancy clutters the page.
- **Don't pre-filter the data in Python.** Embed the full dataset and let the page filter. The reader will want to slice it differently than you expect.
- **Don't forget the documentation `<details>`.** A reader without context will misread the chart axes and ask the wrong follow-up question.

## Generating the report

### Step 1: Gather data

Collect information from the working session:

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

| Token | Replace with |
|-------|-------------|
| `{{REPORT_TITLE}}` | Report title (e.g., "PROJ-1234: Fix payment timeout") |
| `{{REPORT_SUBTITLE}}` | Short subtitle or ticket summary |
| `{{REPORT_DATE}}` | Date in format "January 15, 2025" |
| `{{REPORT_CONTENT}}` | All HTML content sections (see the [HTML components reference](#html-components-reference)) |
| `{{TICKET_ID}}` | Ticket identifier (e.g., "PROJ-1234") |
| `{{BRANCH_NAME}}` | Git branch name |
| `{{AUTHOR_NAME}}` | Author name |
| `{{GENERATED_BY}}` | "report-writer" |

### Step 3: Save and open

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

## HTML components reference

All components go inside the `{{REPORT_CONTENT}}` placeholder. Every component is styled by `references/template.html`; use only the class names listed in the component reference.

**Tables:** write every table as the `table-wrap` + `data-table` HTML from components.md, never a markdown pipe table: nothing renders markdown in the report. Escape `&`, `<` and `>` in every cell, code included. Every row has the header's cell count, an empty cell is `<td></td>`, and there is no `rowspan` or `colspan`.

Read [references/components.md](references/components.md) before writing the report body. It has copy-paste HTML and class variants for:

- Core: section with icon (plus the icon-to-section table), info card, highlighted card, timeline, code block, impact grid (`low`/`medium`/`high`), decision log, file list (`added`/`modified`/`deleted` badges), stats bar
- Advanced: horizontal timeline for phase overviews, phased vertical timeline, data table (`positive`/`negative`/`neutral` cells), arrow annotation

## Design principles

1. **Standalone** - The HTML file must work with no external dependencies. All CSS and JS are inlined.
2. **Plain** - Clean typography, consistent spacing, a subtle color palette.
3. **Informative** - Every section should add something. Don't pad with boilerplate.
4. **Scannable** - Use headers, cards, and visual hierarchy so readers can skim.
5. **Printable** - The report should look right when printed (the template includes print styles).
6. **Accurate** - File names, line counts, and code snippets must match the work actually done.

## After a ticket

Once the ticket work is done, run `/report-writer PROJ-1234`. The report generator gathers git diff data, commit history, and file changes from your working branch.

## Reference files

| Reference | Contents |
|---|---|
| [components](references/components.md) | Copy-paste HTML for every report component (cards, timelines, impact grid, decision log, file list, stats bar, data table, arrow annotation) and the section icon table. Load before writing `{{REPORT_CONTENT}}`. |
| [template.html](references/template.html) | Standalone HTML template for narrative-style reports (bug fixes, features, investigations). All CSS, JS, and component styles are inlined. |
| [data-explorer-template.html](references/data-explorer-template.html) | Generic, domain-agnostic data-explorer template: filter builder, configurable charts, dynamic stat cards, sortable records table, CSV export. Fill the `{{TOKEN}}` placeholders. |
| [data-explorer-generator.py](references/data-explorer-generator.py) | Small Python generator that takes any CSV and a JSON config and produces a data-explorer HTML report from the template. |

## Integration with other skills

| Situation | Recommended Skill |
|---|---|
| When writing a PR description | `pr-message-writer` |

## Examples

```
/report-writer PROJ-1234          # Bug fix report for ticket PROJ-1234
/report-writer PROJ-5678          # Feature report for ticket PROJ-5678
/report-writer PROJ-9012          # Refactoring report for ticket PROJ-9012
/report-writer auth-investigation  # Investigation report (no ticket)
/report-writer                     # Auto-detect from branch name
```

"""Generic generator that fills `data-explorer-template.html` from a CSV.

Usage:
    python data-explorer-generator.py --csv data.csv --out report.html \\
        --config report_config.json

The config JSON declares everything domain-specific (title, requirement docs,
default filters, charts, stat cards, etc.). The template is dataset-agnostic.

Example report_config.json:
{
    "title": "Service Compliance Report",
    "subtitle_format": "Source: {source} - generated {generated} - {total} services",
    "requirements_html": "<details open><summary>What this report measures</summary><p>...</p></details>",
    "default_filters": [
        {"field": "tier", "op": "one_of", "value": ["production"]}
    ],
    "stats": [
        {"label": "In view", "type": "total"},
        {"label": "Healthy", "type": "count", "field": "status", "match": "healthy", "color": "good"},
        {"label": "Degraded", "type": "count", "field": "status", "match": "degraded", "color": "warn"},
        {"label": "Healthy %", "type": "percent", "field": "status", "match": "healthy"}
    ],
    "charts": [
        {"id": "ch_status", "title": "Status", "type": "doughnut", "groupBy": "status"},
        {"id": "ch_tier_status", "title": "Status by tier", "type": "bar", "groupBy": "tier", "stackedBy": "status"},
        {"id": "ch_reasons", "title": "Top failure reasons", "type": "bar-horizontal", "groupBy": "reason", "topN": 12, "tall": true}
    ],
    "search_fields": ["service_id", "name", "owner"],
    "multi_valued_fields": {"tags": ","},
    "color_map": {"status": {"healthy": "#34d399", "degraded": "#fbbf24", "down": "#f87171"}}
}
"""

from __future__ import annotations

import argparse
import csv
import json
from datetime import UTC, datetime
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv", type=Path, required=True, help="Input CSV file")
    parser.add_argument("--out", type=Path, required=True, help="Output HTML file")
    parser.add_argument("--template", type=Path, default=Path(__file__).parent / "data-explorer-template.html")
    parser.add_argument("--config", type=Path, required=True, help="JSON report config")
    args = parser.parse_args()

    config = json.loads(args.config.read_text(encoding="utf-8"))

    with args.csv.open(encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        columns = list(reader.fieldnames or [])
        records = list(reader)

    template = args.template.read_text(encoding="utf-8")

    generated = datetime.now(UTC).strftime("%Y-%m-%d %H:%M UTC")
    subtitle = (config.get("subtitle_format") or "Source: {source} - generated {generated} - {total} records").format(
        source=str(args.csv),
        generated=generated,
        total=len(records),
    )

    dumps = lambda v: json.dumps(v, separators=(",", ":"), ensure_ascii=False)  # noqa: E731

    html = (
        template
        .replace("{{REPORT_TITLE}}", str(config.get("title") or "Data Explorer"))
        .replace("{{REPORT_SUBTITLE}}", subtitle)
        .replace("{{REQUIREMENTS_HTML}}", config.get("requirements_html") or "")
        .replace("{{DEFAULT_FILTERS_JSON}}", dumps(config.get("default_filters") or []))
        .replace("{{CHARTS_CONFIG_JSON}}", dumps(config.get("charts") or []))
        .replace("{{STATS_CONFIG_JSON}}", dumps(config.get("stats") or []))
        .replace("{{SEARCH_FIELDS_JSON}}", dumps(config.get("search_fields") or []))
        .replace("{{MULTI_VALUED_FIELDS_JSON}}", dumps(config.get("multi_valued_fields") or {}))
        .replace("{{COLOR_MAP_JSON}}", dumps(config.get("color_map") or {}))
        .replace("{{RECORDS_JSON}}", dumps(records))
        .replace("{{COLUMNS_JSON}}", dumps(columns))
    )
    args.out.write_text(html, encoding="utf-8")
    print(f"wrote {args.out} ({len(records)} records)")


if __name__ == "__main__":
    main()

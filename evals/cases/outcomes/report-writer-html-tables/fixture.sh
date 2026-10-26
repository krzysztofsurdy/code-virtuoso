#!/usr/bin/env bash
set -euo pipefail
cat > notes.md <<'MD'
# PAY-311 invoice export latency

The export endpoint loaded invoices one by one. It now batches the lookup with
`fetchMany(ids: Array<string>)` and the p95 dropped. Branch fix/PAY-311-batch-invoices.
MD
cat > latency.csv <<'CSV'
endpoint,method,handler,p95_before_ms,p95_after_ms,change,owner,notes
/api/v2/invoices/{invoiceId}/line_items_export_with_tax_breakdown_and_currency_conversion,GET,"fetchMany(ids: Array<string>): Promise<Map<string, Invoice>>",2340,45,-98%,billing | finance,"status = 'open' && amount > 0"
/api/v2/invoices,GET,InvoiceController::list,180,165,-8%,,renders one <td> per column
/api/v2/invoices/{invoiceId},DELETE,,95,,,billing,
CSV

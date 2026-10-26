---
type: regex
target:
  source: file
  path: report.html
flags: i
pattern: '<table\b(?:(?!</table>)[\s\S])*line_items_export(?:(?!</table>)[\s\S])*</table>'
---

---
type: regex
target:
  source: file
  path: report.html
flags: i
match: not_contains
pattern: '<table\b(?=(?:(?!</table>)[\s\S])*?line_items_export)(?:(?!</table>)[\s\S])*?<tr\b[^>]*>(?:(?:(?:(?!</t(?:r|able)>|<t[dh]\b)[\s\S])*<t[dh]\b){0,7}(?:(?!</t(?:r|able)>|<t[dh]\b)[\s\S])*</tr>|(?:(?:(?!</t(?:r|able)>|<t[dh]\b)[\s\S])*<t[dh]\b){9})'
weight: 3
---

#!/usr/bin/env bash
set -euo pipefail
cat > toolbar.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Editor</title>
<style>
  .toolbar { display: flex; gap: 0; }
  .toolbar button { width: 16px; height: 16px; padding: 0; border: 0; background: none; }
  .toolbar button:focus { outline: none; }
</style>
</head>
<body>
<div class="toolbar" role="toolbar" aria-label="Formatting">
  <button aria-label="Bold"><svg width="12" height="12"></svg></button>
  <button aria-label="Italic"><svg width="12" height="12"></svg></button>
  <button aria-label="Underline"><svg width="12" height="12"></svg></button>
  <button aria-label="Link"><svg width="12" height="12"></svg></button>
</div>
</body>
</html>
HTML

#!/usr/bin/env bash
set -euo pipefail
cat > login.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Sign in</title>
<style>
  body { font-family: system-ui, sans-serif; }
  input { padding: 8px; border: 1px solid #888; }
  input:focus { outline: none; }
  button { padding: 8px 16px; }
</style>
</head>
<body>
<main>
  <h1>Sign in</h1>
  <form action="/login" method="post" autocomplete="off">
    <input type="email" name="email" placeholder="Email address">
    <input type="password" name="password" placeholder="Password" onpaste="return false">
    <button type="submit">Sign in</button>
  </form>
</main>
</body>
</html>
HTML

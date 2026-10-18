#!/usr/bin/env bash
set -euo pipefail
cat > composer.json <<'JSON'
{"require": {"php": ">=8.2", "symfony/http-client": "^6.4 || ^7.0"}}
JSON
cat > composer.lock <<'JSON'
{"packages": [{"name": "symfony/http-client", "version": "v6.4.13"}], "packages-dev": []}
JSON

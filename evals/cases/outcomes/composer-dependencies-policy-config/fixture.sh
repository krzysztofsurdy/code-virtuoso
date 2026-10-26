#!/usr/bin/env bash
set -euo pipefail
cat > composer.json <<'JSON'
{
    "name": "acme/shop",
    "type": "project",
    "require": {
        "php": ">=8.4",
        "acme/legacy-lib": "^2.3",
        "symfony/framework-bundle": "^8.1"
    },
    "config": {
        "sort-packages": true,
        "audit": {
            "abandoned": "report"
        }
    }
}
JSON

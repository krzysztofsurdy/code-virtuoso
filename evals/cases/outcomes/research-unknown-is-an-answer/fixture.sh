#!/usr/bin/env bash
set -euo pipefail
mkdir -p docs/adr app
cat > requirements.txt <<'TXT'
requests==2.31.0
flask==3.0.3
TXT
cat > app/client.py <<'PY'
import requests


def fetch_rates(base_url):
    resp = requests.get(f"{base_url}/rates", timeout=5)
    resp.raise_for_status()
    return resp.json()
PY
cat > docs/adr/0003-http-client.md <<'MD'
# ADR 0003: HTTP client

Status: accepted (2022-03)

We use requests for all outbound calls. It is synchronous, which matches our
Flask workers. We would revisit if we move to async handlers.
MD

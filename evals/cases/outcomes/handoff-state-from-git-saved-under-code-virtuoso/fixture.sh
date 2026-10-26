#!/usr/bin/env bash
set -euo pipefail
git init -q -b main
git config user.email dev@example.com
git config user.name Dev
cat > client.py <<'PY'
def fetch(url, send):
    return send(url)
PY
cat > test_client.py <<'PY'
import unittest

from client import fetch


class FetchTest(unittest.TestCase):
    def test_returns_response(self):
        self.assertEqual(fetch("u", lambda url: "ok"), "ok")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "Add fetch client"
git checkout -q -b feat/client-retry
cat > client.py <<'PY'
def fetch(url, send, attempts=3):
    last = None
    for _ in range(attempts):
        try:
            return send(url)
        except ConnectionError as exc:
            last = exc
    raise last
PY
git commit -q -am "Retry fetch on ConnectionError"
python3 - <<'PY'
p = open("test_client.py").read()
p = p.replace('\n\nif __name__', '''
    def test_retries_then_succeeds(self):
        calls = []

        def flaky(url):
            calls.append(url)
            if len(calls) < 3:
                raise ConnectionError("down")
            return "ok"

        self.assertEqual(fetch("u", flaky), "ok")

    def test_backoff_between_attempts(self):
        self.assertTrue(hasattr(__import__("client"), "backoff_seconds"))


if __name__''', 1)
open("test_client.py", "w").write(p)
PY
echo "# TODO: add backoff_seconds(attempt) with exponential delay, then wire it into fetch" > NOTES.txt

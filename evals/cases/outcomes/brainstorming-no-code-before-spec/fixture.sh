#!/usr/bin/env bash
set -euo pipefail
cat > contacts.py <<'PY'
class Contact:
    def __init__(self, name, email):
        self.name = name
        self.email = email


CONTACTS = []


def add_contact(name, email):
    CONTACTS.append(Contact(name, email))
PY

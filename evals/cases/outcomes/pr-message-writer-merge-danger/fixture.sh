#!/usr/bin/env bash
set -euo pipefail
cat > ticket.txt <<'TXT'
PAY-482: Store phone numbers in one format

Support cannot search customers by phone because numbers are stored in many
formats. Normalize every stored phone number to E.164 and keep a single
column. The old free-text column can go once the data is migrated.
TXT
cat > change.patch <<'PATCH'
diff --git a/migrations/0042_phone_e164.py b/migrations/0042_phone_e164.py
new file mode 100644
--- /dev/null
+++ b/migrations/0042_phone_e164.py
@@ -0,0 +1,26 @@
+from phones import to_e164
+
+
+def upgrade(conn):
+    conn.execute("ALTER TABLE customers ADD COLUMN phone_e164 TEXT")
+    for row_id, raw in conn.execute("SELECT id, phone FROM customers").fetchall():
+        conn.execute(
+            "UPDATE customers SET phone_e164 = ? WHERE id = ?",
+            (to_e164(raw), row_id),
+        )
+    conn.execute("ALTER TABLE customers DROP COLUMN phone")
+    conn.execute("CREATE UNIQUE INDEX idx_customers_phone ON customers(phone_e164)")
+
+
+def downgrade(conn):
+    conn.execute("ALTER TABLE customers ADD COLUMN phone TEXT")
+    conn.execute("UPDATE customers SET phone = phone_e164")
+    conn.execute("ALTER TABLE customers DROP COLUMN phone_e164")
diff --git a/phones.py b/phones.py
new file mode 100644
--- /dev/null
+++ b/phones.py
@@ -0,0 +1,12 @@
+import re
+
+
+def to_e164(raw, default_country="1"):
+    digits = re.sub(r"\D", "", raw or "")
+    if not digits:
+        return None
+    if raw.strip().startswith("+"):
+        return "+" + digits
+    return "+" + default_country + digits[-10:]
diff --git a/search.py b/search.py
--- a/search.py
+++ b/search.py
@@ -4,3 +4,4 @@
 def find_customer_by_phone(conn, raw):
-    return conn.execute("SELECT * FROM customers WHERE phone = ?", (raw,)).fetchone()
+    from phones import to_e164
+    return conn.execute("SELECT * FROM customers WHERE phone_e164 = ?", (to_e164(raw),)).fetchone()
PATCH
cat > test_output.txt <<'TXT'
$ python3 -m unittest
....
Ran 4 tests in 0.012s

OK
TXT

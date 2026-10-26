---
type: llm
focus: last_message
---

PASS if the pasted config uses config.policy (Composer 2.10) with an advisories section (block true, the PKSA id under ignore-id with a reason string) and an abandoned section (block true, acme/legacy-lib under ignore with a reason string), and does not use the deprecated config.audit keys for these.
FAIL if the pasted config uses config.audit keys such as block-insecure, block-abandoned or ignore for these rules, or records exceptions without a reason.

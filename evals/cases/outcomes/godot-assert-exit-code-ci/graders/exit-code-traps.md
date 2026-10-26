---
type: llm
focus: last_message
---

PASS if the reply explains all of these: a failed assert() in the SceneTree script does not give a non-zero exit code (the run hangs, and with --quit-after it ends with exit 0, so --quit-after is not a timeout and CI needs an outside timeout); --check-only exits 0 even on broken scripts so the output must be read for SCRIPT ERROR or Parse Error; the fix is to count failures yourself with a check helper and end with quit(1 if failures > 0 else 0).
FAIL if the reply says assert() or --check-only fail the process, relies on --quit-after as the safety net, or only rewrites assert into another assert.

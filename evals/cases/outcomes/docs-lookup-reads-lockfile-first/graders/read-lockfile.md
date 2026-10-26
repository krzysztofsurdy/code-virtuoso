---
type: llm
focus: trace
---

PASS if the answer's version came from the project's lockfile or manifest: the reply cites composer.lock (or the installed/locked version), or the trace shows the file being read by any means (Read, cat, grep, sed). FAIL only if the version appears to be guessed from memory with no file consulted.

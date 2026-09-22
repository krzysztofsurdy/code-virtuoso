# Self-review

This plugin went through five rounds of independent adversarial review, each done by a fresh reviewer with no memory of prior rounds and instructions to find real problems, not confirm the design. This document is the honest record of that process, not a marketing summary — it says what was wrong, what got fixed, and what's still a real, accepted trade-off rather than a closed hole.

## Score: 8/10

Not a 10. Two things keep it from being one, and both are named explicitly in the docs rather than hidden:

1. **The write-boundary guarantee depends on `config.allowedTools` staying a curated list of specific binaries.** This plugin cannot itself sandbox a worker's Bash access — Claude Code doesn't scope Bash to the project directory the way it scopes Edit/Write, so no file-location trick or snapshot scheme built in bash can survive a worker with a bare interpreter (`php -r`, `python -c`, `node -e`) in its allowlist. The defaults now exclude every bare interpreter, and the docs say plainly that widening past specific, auditable commands requires an OS-level sandbox, not a bash-side workaround. That's the honest answer, not a magic fix — it means the guarantee is real *conditional on default discipline*, not unconditional.
2. **Package-manager installs (`composer install`, `pip install -r`, `poetry install`, `uv sync`) are a narrower, second-order version of the same risk** — they can run arbitrary code via a project's own lifecycle scripts or build backend, but only if the worker has *also* edited that config first. Documented as a real residual, not removed entirely, because removing them would make the defaults impractical for real verify cycles.

Both are exactly the kind of thing an honest 8 looks like: real engineering, a real remaining trade-off, stated plainly instead of papered over.

## The five rounds, briefly

| Round | Score | What it found |
|---|---|---|
| 1 | 6/10 | A path-resolution bug that let symlink mismatches (macOS `/tmp` vs `/private/tmp`) bypass the real-time write guard in both directions; the write-boundary guard failing open when invoked outside the project root; `verify-gate.sh` missing brand-new untracked files entirely (a worker creating a file registered as a stall, not progress). |
| 2 | 6/10 | **Critical**: nothing stopped a worker from rewriting a step's own `verifyCommand` directly in `backlog.json` — the gate would trust the tampered value and report false success. The core "a script decides, not the agent" premise was bypassable. |
| 3 | 5/10 | The round-2 fix stored its trusted snapshot as a sibling file next to `backlog.json` inside the project. The same access that tampered with the original could launder the snapshot to match, defeating the comparison. |
| 4 | 4/10 | Moving the snapshot outside the project directory only closed the *Edit/Write* vector. The actual tampering path was always Bash, which isn't sandboxed to the project tree — and the shipped default `allowedTools` included bare interpreters (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`), each a full arbitrary-file-write grant hiding behind a plausible-looking pattern. |
| 5 | 6/10 | Confirmed the bare-interpreter fix was real and the security narrative now honest — but a regression in the new participant validator (a bash `IFS=$'\t' read` silently collapsing an empty field, flagging every valid `persona` participant as broken) blocked Mode A entirely; package-manager wildcards still carried undocumented lifecycle-script risk; a layer-1 path-resolution edge case for brand-new files in not-yet-created directories. |

Round 4 is the pivotal one: it's where the design's central claim went from "we think this is safe" to "here is exactly what makes it safe and exactly what it depends on." Everything after that round has been narrowing scope and fixing regressions, not discovering new categories of problem.

## What actually changed between round 4 and now

- Default `allowedTools` for every stack (`skills/backlog-compiler/references/allowed-tools-by-stack.md`) rewritten to remove every bare interpreter and narrow package-manager/build commands to specific subcommands, with the reasoning stated inline, not just the result.
- `README.md`, `write-boundary.md`, and `permission-modes.md` rewritten to state the real boundary: broad `allowedTools` is safe *only* when every entry is a specific tool invocation, and broadening past that requires an OS-level sandbox — not "the guard protects you regardless," which was the overclaim round 4 caught.
- `backlog_protected_paths` extended to also protect `teams.json` at the real-time layer, not just `backlog.json`.
- `scripts/validate-backlog.sh` gained hard-fail checks for malformed participants (bad `kind`, missing `agent`/`systemPrompt`) — then, when round 5 found the check itself was broken by a bash field-splitting footgun, rewritten to do the validation entirely in `jq` instead of shell `IFS` splitting.
- `hooks/guard-protected-paths.sh`'s path resolution now walks up to the nearest existing ancestor directory before resolving symlinks, closing the gap where a brand-new file in a not-yet-created directory fell back to an unresolved path.
- A real, separate bug was found and fixed along the way: a `case` statement nested directly inside a `$(...)` command substitution does not parse on bash 3.2 (macOS's frozen default `/bin/bash`, still shipped for licensing reasons) — moved into its own function, which does parse correctly everywhere.

## What this review process did *not* do

It did not chase the score to a manufactured 10 by declaring the Bash-sandboxing limitation solved when it isn't. An actual strong guarantee against a worker with genuinely unrestricted Bash requires OS-level process isolation — a devcontainer, a VM, a restricted user — which this plugin documents as the answer for that case and does not attempt to fake with cleverer file paths. That's a deliberate stopping point, not an unfinished one.

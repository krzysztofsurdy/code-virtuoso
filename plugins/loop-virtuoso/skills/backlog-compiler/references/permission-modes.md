# Choosing a permission mode

`config.permissionMode` controls how the worker invocation in each iteration is allowed to act. Default to `acceptEdits` with a stack-appropriate `allowedTools` list (see `allowed-tools-by-stack.md`). Only consider `bypassPermissions` as a documented, deliberate exception.

## `acceptEdits` (default)

Auto-approves file writes and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`). Every other Bash command needs an explicit `allowedTools` entry or the call is denied. This is what makes the loop's permission posture legible: the allowlist names exactly what the worker can run.

**The real boundary is what kind of command is on that list, not how long the list is.** The write-boundary guard (`iteration-loop`'s `write-boundary.md`) stops the worker's Edit/Write tool calls from touching `config.protectedPaths` or the loop's own control files, and its content-tamper check catches edits to those files regardless of which tool made them. Both of those assume the worker's Bash access is a set of *specific, auditable binaries and subcommands* — `vendor/bin/phpunit`, `npm run test`, `git add`. A single bare-interpreter pattern (`Bash(php *)`, `Bash(python *)`, `Bash(node *)`) breaks that assumption completely: an interpreter with a code-execution flag (`php -r`, `python -c`, `node -e`) can read or write any file the OS user can reach, including the guard's own trusted state, since Claude Code does not sandbox Bash to the project directory the way it scopes Edit/Write. No amount of file-location cleverness on the plugin's side closes that gap once the worker can execute arbitrary code — see `allowed-tools-by-stack.md`'s "Why no bare interpreters" for the specifics. Keep every `allowedTools` entry a specific tool invocation and this is a genuinely strong guarantee; add one general-purpose interpreter and it isn't.

## `bypassPermissions`, or any allowlist wider than specific binaries

Skips permission prompts entirely, or otherwise grants Bash access broader than a curated list of specific commands. Only appropriate when a project's verification or build pipeline genuinely needs more than a reasonable allowlist can enumerate — package installs that shell out further, Docker, multi-step build tooling, or codegen. If you reach for this, the write-boundary guard is no longer a sufficient defense on its own, because it can't be — do this instead:

1. Run the worker inside an OS-level sandbox where its write access is physically confined to the project directory: a devcontainer with an egress-allowlist firewall, or a disposable cloud sandbox (Daytona, E2B). This is not optional hardening at this point, it's the actual replacement for the guarantee the narrow-allowlist case gets from the write-boundary guard.
2. Never on a machine holding real credentials.
3. Document in the backlog's `description` field why this project needed it, so a future run doesn't inherit it by copy-paste without the same justification and the same sandboxing.

Never default to this. Both well-known reference implementations of this technique default to a full permission bypass — that is exactly the failure mode this plugin exists to avoid.

# Choosing a permission mode

`config.permissionMode` controls how the worker invocation in each iteration is allowed to act. Default to `acceptEdits` with a stack-appropriate `allowedTools` list (see `allowed-tools-by-stack.md`). Only consider `bypassPermissions` as a documented, deliberate exception.

## `acceptEdits` (default)

Auto-approves file writes and common filesystem commands (`mkdir`, `touch`, `mv`, `cp`). Every other Bash command needs an explicit `allowedTools` entry or the call is denied. This is what makes the loop's permission posture legible: the allowlist names exactly what the worker can run.

This is safe to make reasonably broad (see the stack defaults) because **the protected-paths guard, not the allowlist's narrowness, is the actual safety control.** A worker with `vendor/bin/* *` allowed still cannot edit a file under `tests/**` — the `PreToolUse` hook denies that regardless of which Bash command or built-in tool tries it, and the post-iteration git-diff audit catches anything that slips past.

## `bypassPermissions` (opt-in only)

Skips permission prompts entirely. Only appropriate when a project's verification or build pipeline genuinely needs commands no reasonable allowlist can enumerate in advance — package installs that shell out further, Docker, multi-step build tooling. If you reach for this:

1. Confirm the protected-paths guard is still configured and covers the project's real test/CI locations — it is the only remaining backstop once the allowlist stops being a meaningful boundary.
2. Run Mode B inside a disposable sandbox (a devcontainer with an egress-allowlist firewall, or a cloud sandbox like Daytona/E2B), never on a machine holding real credentials.
3. Document in the backlog's `description` field why this project needed it, so a future run doesn't inherit it by copy-paste without the same justification.

Never default to this. Both well-known reference implementations of this technique default to a full permission bypass — that is exactly the failure mode this plugin exists to avoid.

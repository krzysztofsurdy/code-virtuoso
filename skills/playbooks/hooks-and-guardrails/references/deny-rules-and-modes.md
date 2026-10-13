## Contents

- [Permission modes in Claude Code](#permission-modes-in-claude-code)
- [Sandbox in Claude Code](#sandbox-in-claude-code)
- [Deny rule limits](#deny-rule-limits)
- [Sandbox and approvals in Codex](#sandbox-and-approvals-in-codex)
- [Choosing a baseline](#choosing-a-baseline)
- [Sources](#sources)

## Permission modes in Claude Code

| Mode | What runs without asking | Use for |
|---|---|---|
| `default` (shown as Manual) | Reads only | Sensitive work, unfamiliar code |
| `acceptEdits` | Reads, file edits, common filesystem commands | Iterating on code you are reviewing |
| `plan` | Reads. Edits blocked until you approve a plan | Exploring before changing |
| `auto` | Everything, with a classifier reviewing actions | Long tasks, fewer prompts. Needs a supported model |
| `dontAsk` | Reads in the working directories and pre-approved tools. Anything else is denied | Locked-down CI and scripts |
| `bypassPermissions` | Everything | Isolated containers and VMs only |

Deny rules block in every mode, including `bypassPermissions`. Set a default with `permissions.defaultMode` or per run with `--permission-mode`. Project settings cannot set `auto` or `bypassPermissions` as the starting mode. Managed settings can switch bypass off with `permissions.disableBypassPermissionsMode`.

Hands-off CI example:

```bash
claude -p "run the test suite" --permission-mode dontAsk --allowedTools "Bash(npm test)" "Read"
```

## Sandbox in Claude Code

The sandbox is an operating-system boundary around shell commands and the processes they start. It runs on macOS, Linux, and WSL2, and is off by default. Turn it on with `/sandbox` or `sandbox.enabled`.

| Setting | Effect |
|---|---|
| `sandbox.filesystem.denyRead` | Blocks shell processes from reading a path, for example `["~/.aws", "~/.ssh"]` |
| `sandbox.filesystem.allowWrite` | Extra writable paths beyond the working directory and temp |
| `sandbox.network.allowedDomains` | Hosts shell commands may reach. The list starts empty |
| `sandbox.allowUnsandboxedCommands` | Set to `false` so a blocked command cannot retry outside the sandbox |

The sandbox covers shell commands only. The Read, Edit, Write, WebFetch, and WebSearch tools, MCP servers, and hooks run outside it, so a `denyRead` entry does not stop the Read tool. Cover both: a `Read` deny rule for the file tools and `denyRead` for processes.

## Deny rule limits

| Rule | Covers | Does not cover |
|---|---|---|
| `Read(./.env)` | The Read tool, and `cat`, `head`, `tail`, `sed`, `tee` when named in Bash, and redirects | `grep -r pattern .` run in the directory, or a script that opens the file itself |
| `Bash(curl *)` | `curl ...` as written | `/usr/bin/curl`, `sh -c 'curl ...'`, option and variable variants |
| Hook exit 2 | Anything the hook checks before the tool runs | Anything the hook does not parse |

Layer them: deny rules for the file tools, the sandbox for processes, a hook for custom logic, and no secrets mounted in high-risk runs.

Path prefixes in rules: `//path` is absolute, `~/path` is from home, `/path` is relative to the settings file's location, and `./path` or a bare name is relative to the current directory. A single leading slash is not an absolute path.

## Sandbox and approvals in Codex

| Setting | Values |
|---|---|
| `sandbox_mode` | `read-only` (inspect only), `workspace-write` (edit inside the workspace, default for local work), `danger-full-access` (no boundaries) |
| `approval_policy` | `on-request` (ask to go beyond the sandbox), `never` (no prompts) |
| `approvals_reviewer` | `user` (default) or `auto_review` (a reviewer agent handles eligible prompts) |
| `sandbox_workspace_write.writable_roots` | Extra writable directories |

Full access means `danger-full-access` with `never`. Treat it like Claude Code's bypass mode: only in an isolated environment. Lower-risk local automation is `workspace-write` with `on-request`.

## Choosing a baseline

| Situation | Claude Code | Codex |
|---|---|---|
| Daily work on your own repo | `default` or `acceptEdits`, sandbox on, deny rules | `workspace-write`, `on-request` |
| Reading issues, docs, or web pages that may be hostile | Add: sandbox network allowlist, no secrets reachable, ask rules on push and deploy | Same, plus trimmed network access |
| Unattended or CI | `dontAsk` with an exact allowlist, or `bypassPermissions` inside a container with no secrets | Container with `danger-full-access` only if the container is the boundary |

## Sources

- https://code.claude.com/docs/en/permission-modes
- https://code.claude.com/docs/en/permissions
- https://code.claude.com/docs/en/sandboxing
- https://code.claude.com/docs/en/settings-reference
- https://learn.chatgpt.com/docs/sandboxing

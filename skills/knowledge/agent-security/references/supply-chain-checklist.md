## Contents

- [Why this matters](#why-this-matters)
- [Review steps before installing](#review-steps-before-installing)
- [Copy-paste scans](#copy-paste-scans)
- [What to read in each artifact type](#what-to-read-in-each-artifact-type)
- [MCP server checks](#mcp-server-checks)
- [Pinning and updates](#pinning-and-updates)
- [Sources](#sources)

## Why this matters

| Incident | What happened |
|---|---|
| Rules File Backdoor (Pillar Security, March 2025) | Hidden Unicode in rules files for AI code editors carried instructions the reviewer could not see |
| s1ngularity, Nx packages (August 2025) | Malicious npm versions ran locally installed AI CLIs with `--dangerously-skip-permissions`, `--yolo`, and `--trust-all-tools` to search for secrets |
| Snyk ToxicSkills (February 2026) | 13.4% of 3,984 scanned public agent skills (534) had at least one critical issue, and 76 malicious payloads were confirmed by human review |

## Review steps before installing

1. Identify the source and the maintainer. Prefer official providers over community copies.
2. Download without running. Clone or fetch into an empty directory. Do not install through a one-line command you have not read.
3. List every file, including hidden ones: `find . -type f | sort`.
4. Run the scans below.
5. Read `SKILL.md`, every script, every hook definition, every MCP config, and every file under `bin/`.
6. Check what it is allowed to do: `allowed-tools`, hook events, MCP server commands and environment variables.
7. Pin to a commit SHA or exact version.
8. First run in a sandbox with no secrets and no network. Watch what it tries.
9. Record what you approved and where you got it, so an update can be diffed.

## Copy-paste scans

Run from the root of the downloaded content. Each command was tested against sample files that contained the patterns.

Hidden Unicode (zero-width characters, bidirectional controls, word joiners, byte order marks, tag characters). Perl works on macOS and Linux:

```bash
find . -type f -not -path './.git/*' -print0 | xargs -0 perl -CSD -ne \
  'print "$ARGV:$.: hidden Unicode\n" if /[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{2069}\x{FEFF}\x{E0000}-\x{E007F}]/; close ARGV if eof'
```

The same check with `grep -P`. It needs GNU grep (or ugrep) and a UTF-8 locale. The BSD grep on macOS has no `-P` and prints an "invalid option" error:

```bash
LC_ALL=C.UTF-8 grep -rnIP '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2060}-\x{2064}\x{2066}-\x{2069}\x{FEFF}\x{E0000}-\x{E007F}]' --exclude-dir=.git .
```

A hit means look at the file with a hex view, for example `perl -CSD -ne 'print if /[\x{200B}-\x{E007F}]/' file | cat -v`. A byte order mark at the start of an old Windows file is usually harmless. Zero-width characters inside Markdown prose are not.

Red-flag commands and paths (portable `grep -E`):

```bash
grep -rnEI 'curl[^|]*\|[[:space:]]*(ba)?sh|base64[[:space:]]+(-d|--decode)|eval[[:space:]]*\(|dangerously-skip-permissions|--yolo|--trust-all-tools|\.ssh/|\.aws/|(^|[^A-Za-z0-9_])\.env([^A-Za-z0-9_]|$)' --exclude-dir=.git .
```

Every hit needs a reason you can state. Documentation that warns about these flags will also match, so read the context.

## What to read in each artifact type

| Artifact | Where code or steering text hides |
|---|---|
| Skill | `SKILL.md` body, `scripts/`, `allowed-tools` (does a doc-writing skill need `Bash`?), reference files the body tells the agent to load |
| Plugin | Hook definitions (run on every tool call or session start), bundled MCP servers, `bin/` executables, default settings |
| Agent definition | Tool list, preloaded skills, memory settings, permission overrides |
| Rules file | Hidden characters, instructions that widen permissions or tell the agent to fetch and run remote content |
| MCP server | Startup command, environment variables it asks for, tool descriptions (the model reads them), requested OAuth scopes |

Red flags in intent: a skill that needs network but has no network purpose, a formatter that reads your home directory, obfuscated or minified scripts in a text skill, instructions to disable confirmation or skip checks, instructions to hide actions from the user.

## MCP server checks

From the MCP security best practices (spec 2026-07-28):

| Risk | Check |
|---|---|
| Local server compromise | A local server runs with your privileges. The client should show the exact startup command, including arguments, before running it. Prefer a sandbox with limited filesystem and network access. Treat `sudo`, `rm -rf`, and network calls in startup commands as red flags |
| Token passthrough | A server must not accept tokens that were not issued for it, and must not forward client tokens to downstream APIs |
| Confused deputy in OAuth proxies | A proxy server needs per-client consent, exact `redirect_uri` matching, and a validated `state` value |
| SSRF in OAuth discovery | A client that follows server-supplied URLs should require HTTPS, block private and link-local ranges, and check redirects |
| Scope minimization | Start with minimal scopes and step up on demand. Avoid wildcard or all-access scopes |
| State handle hijacking | Possession of a handle is not authentication. Handles must be unguessable and bound to the verified user |

Also: read the tool descriptions yourself. They are model-visible text, so a description that contains instructions is an injection.

## Pinning and updates

| Source | Pin with |
|---|---|
| Git repository | Full commit SHA, not a branch or tag |
| npm, PyPI, Composer | Exact version plus a lockfile with hashes |
| Marketplace plugin | Exact version, and review the diff on every bump |
| Container image | Digest, not `latest` |

Set a review rule: no update merges without a diff read of the files listed above. Remove skills and servers nobody uses. Each one adds attack surface and context cost.

## Sources

- https://snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub
- https://wiz.io/blog/s1ngularity-supply-chain-attack
- https://thehackernews.com/2025/03/new-rules-file-backdoor-attack-lets.html (Rules File Backdoor coverage)
- https://modelcontextprotocol.io/specification/2026-07-28/basic/security_best_practices

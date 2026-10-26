---
description: "Copy a starter template into the repo: devcontainer, issue-to-PR workflow, or pilot backlog"
argument-hint: "<devcontainer|issue-to-pr|pilot-backlog> [--force]"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh:*)"]
---

# Scaffold a template

Run the scaffold script with the user's arguments:

```
${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh $ARGUMENTS
```

| Kind | Writes |
|---|---|
| `devcontainer` | `.devcontainer/devcontainer.json`, `Dockerfile` and `init-firewall.sh`: a non-root user, a default-deny egress firewall with an allowlist, no host credential mounts, Claude Code installed |
| `issue-to-pr` | `.github/workflows/claude-issue-to-pr.yml`: a labelled issue or an `@claude` mention becomes a draft pull request from a `claude/issue-<n>` branch |
| `pilot-backlog` | `.code-virtuoso/loop/backlog.json`: two low-risk items for a first `/loop-virtuoso:start` run |

Files go to the git root. The script refuses to overwrite an existing file and writes nothing in that case; with `--force` it first copies each existing file to `<file>.bak.<timestamp>`. It never replaces the backlog while a loop is active.

Relay the output verbatim: the files written, any backups, and the next steps. If the script refuses, tell the user which files exist and that `--force` replaces them after a backup. Do not pass `--force` unless the user asked for it. Do not edit the written files unless the user asks; the next steps say what to customize.

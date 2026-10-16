# Code Virtuoso for Codex

Codex reads this repository's `.claude-plugin/marketplace.json`, so the skills install through the normal Codex plugin flow. Codex plugins cannot ship agents, so the agents install separately from the TOML files in `codex/agents/`.

## Install the skills

```
codex plugin marketplace add krzysztofsurdy/code-virtuoso
```

Then open the Plugins Directory in Codex, choose the `code-virtuoso` marketplace, and install the plugins you want. To update later, run `codex plugin marketplace upgrade`.

Sources: [Package your plugin](https://developers.openai.com/plugins/build/plugins).

## Install the agents

Clone the repository and run the installer from its root:

```
scripts/install-codex-agents.sh             # user level: ~/.codex/agents/
scripts/install-codex-agents.sh --project   # current project: ./.codex/agents/
```

The script:

- copies `codex/agents/*.toml` to the agents directory,
- copies `roles/` and the skill reference directories the agents read to `${CODE_VIRTUOSO_HOME:-~/.codex/code-virtuoso}`,
- stores a checksum of every file it installs, and skips any file you changed since then (pass `--force` to overwrite),
- prints one line per file: installed, updated, unchanged, skipped, or overwritten.

Run it again after pulling a new version. Untouched files update, edited files stay as you left them.

Each agent's instructions refer to library files as `${CODE_VIRTUOSO_HOME}/roles/...`. Codex does not expand that variable, so the agent reads the path from the default location. If you install somewhere else, set `CODE_VIRTUOSO_HOME` before running the installer and in the shell Codex runs in.

Once installed, ask Codex to use an agent by name, for example "use the reviewer agent on this diff". Codex identifies agents by the `name` field in each file. See [Subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents).

## How the agent files are made

`scripts/build-codex-agents.py` generates `codex/agents/<name>.toml` from `agents/<name>.md`. Do not edit the TOML files by hand. Run the script after changing an agent:

```
python3 scripts/build-codex-agents.py          # regenerate
python3 scripts/build-codex-agents.py --check  # exit 1 if codex/agents/ is out of date
```

The conversion:

- keeps `name` and `description`, and uses the agent body as `developer_instructions`,
- sets no `model`, so Codex uses the model you configured,
- adds "Do not modify files." to agents whose tool list has no `Edit` or `Write` and that set no `memory` (Claude Code lets a memory agent write its notes and records),
- rewrites `${CLAUDE_PLUGIN_ROOT}` to `${CODE_VIRTUOSO_HOME}`.

## Limits

- No peer teams. Codex subagents are managed by the parent session: the parent spawns them, collects their results, and relays anything between them. Agents cannot message each other, so team-style workflows that rely on direct peer messaging run as parent-driven delegation instead.
- Read-only is an instruction, not a sandbox. A custom agent file cannot set `sandbox_mode` or `approval_policy`. Subagents inherit them from the parent session, so "Do not modify files." only asks the agent to behave. Use a read-only sandbox on the parent session when you need it enforced.
- The `tools` and `skills` fields in the Claude agent files have no Codex equivalent and are dropped. Skills come from the plugin install.
- Codex does not apply the Claude Code worktree isolation some agents declare. Create a worktree yourself before delegating write work.

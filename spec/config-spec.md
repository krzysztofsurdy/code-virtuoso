# Config Specification

This document defines where Code Virtuoso skills and agents store saved choices (tool names, branch patterns, test commands, agent tuning) and how they read them. One convention covers every consumer, so a choice is saved once and survives reinstalls, plugin updates, and new sessions.

Saved choices must not live next to a skill or agent file. In a plugin install that directory is a version cache that is replaced on update. In a skills.sh install it is deleted on reinstall. It is also global even when the value belongs to one project, and teammates cannot share it. The plugin data directory (`${CLAUDE_PLUGIN_DATA}`) is no fix: it is deleted on uninstall, it is not set in the shell tool environment, and Codex, Cursor, and skills.sh installs do not have it.

## Contents

- [Layers](#layers)
- [Paths](#paths)
- [Precedence](#precedence)
- [Format](#format)
- [Namespaces](#namespaces)
- [Reading config](#reading-config)
- [Writing config](#writing-config)
- [Behavior rules](#behavior-rules)
- [Migration from legacy files](#migration-from-legacy-files)
- [Security](#security)

## Layers

| Layer | Path | Git | Holds |
|---|---|---|---|
| Defaults | Inside the skill or agent (its defaults or setup table) | n/a | Fallback values |
| User | `$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json` (Windows: `%APPDATA%\code-virtuoso\config.json`) | Never in a repo | Personal preferences: CLI choice (`gh` or `glab`), MCP tool names, personal agent tuning, commit habits |
| Project shared | `<project root>/.code-virtuoso/config.json` | Committed | Team decisions: tracker type, ticket ID pattern, branch pattern, commit format, main branch, test, lint, and static analysis commands, architecture notes, shared agent tuning |
| Project local | `<project root>/.code-virtuoso/config.local.json` | Ignored | Personal per-project overrides |
| Project runtime | `<project root>/.code-virtuoso/loop/state/` | Ignored | Volatile run state (loop progress, attempts, events, session) |
| Machine state | `${XDG_STATE_HOME:-$HOME/.local/state}/code-virtuoso/` | Outside the repo | Snapshots and caches |

Only the first four layers hold configuration. Runtime and machine state are for data a tool produces, never for choices a person made.

## Paths

- **Project root:** the output of `git rev-parse --show-toplevel`, else the current directory.
- **`.gitignore`:** whoever first creates `.code-virtuoso/` also writes `.code-virtuoso/.gitignore` with this content:

  ```
  *.local.json
  loop/state/
  handoff/
  ```

- **Plugin data directory:** use `${CLAUDE_PLUGIN_DATA}` only for disposable caches. Never store a choice there.

## Precedence

Highest first:

1. Explicit argument (a value the user passes in this invocation)
2. Project local
3. Project shared
4. User
5. Defaults

Objects deep-merge. Arrays and scalars replace. A missing file is normal and is skipped.

## Format

JSON with a top-level `"version": 1` and one namespace per consumer.

```json
{
  "version": 1,
  "ticket-delivery": {
    "tracker": "jira",
    "ticketIdPattern": "PROJ-\\d+",
    "branchPattern": "feat/{ticket}_{slug}",
    "commitFormat": "{ticket}: {summary}",
    "mainBranch": "main",
    "commands": { "test": "composer test", "lint": "composer lint", "staticAnalysis": "vendor/bin/phpstan" }
  },
  "agents": {
    "reviewer": { "reviewDepth": "standard" },
    "architect": { "adrFormat": "madr" }
  },
  "loop": {
    "maxIterations": 20,
    "permissionMode": "acceptEdits",
    "allowedPaths": ["src/", "tests/"],
    "protectedPaths": [".env", ".github/workflows/"]
  }
}
```

- Keys are camelCase.
- Writers preserve unknown keys. Read the file, change the keys you own, write it back. Never overwrite the whole file blindly.
- Writers write indented JSON with one trailing newline so diffs stay small.

## Namespaces

| Namespace | Owner | Holds |
|---|---|---|
| `ticket-delivery` | Ticket workflow settings, read by the loop plugin | Tracker, VCS, tooling, test, and PR conventions for the ticket workflow |
| `agents.<agent-name>` | The agent with that name | The agent's tuning settings, one object per agent |
| `loop` | The loop plugin | Delivery loop settings: `maxIterations`, `permissionMode`, `allowedPaths`, `protectedPaths`. `guard` holds the opt-in guard hooks, all off by default: `blockSecrets` (boolean), `protectTests` (`"ask"`, `"deny"` or `false`), `testGlobs` (array of globs), `stopGate` (boolean; runs `ticket-delivery.commands`; stopGate is read only from the user and local layers). `evalSetup.vanillaArgs` (array of strings) replaces the default `["--safe-mode"]` arguments of the eval-setup vanilla arm |

`protectedPaths` is the one exception to the array-replace rule: the loop plugin combines the lists from every layer instead of replacing them, so a project can add protected paths but never remove a user's.

The loop plugin stores its pipelines in separate files, not in `config.json`:

| Layer | Path | Git |
|---|---|---|
| User | `${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/loop/pipelines.json` | Never in a repo |
| Project | `<project root>/.code-virtuoso/loop/pipelines.json` | Committed |

When both files define a pipeline with the same name, the project entry wins.

A new consumer picks a namespace that matches its skill or plugin name and documents its keys in its own reference file.

## Reading config

Resolve the three file layers in order, merge, then pick the namespace you need.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
home="${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}"
files=()
for f in "$home/config.json" "$root/.code-virtuoso/config.json" "$root/.code-virtuoso/config.local.json"; do
  [ -f "$f" ] && files+=("$f")
done
if [ ${#files[@]} -gt 0 ]; then
  jq -s 'reduce .[] as $x ({}; . * $x)' "${files[@]}"
else
  echo '{}'
fi
```

Pipe the result to `jq '.["ticket-delivery"] // {}'` or `jq '.agents.reviewer // {}'` to get one namespace.

In plain words, for agents that cannot run shell commands:

1. Find the project root: the top folder of the git repository, or the current folder if there is none.
2. Look for three files in this order: the user file (`config.json` in `$CODE_VIRTUOSO_CONFIG_HOME`, else in `~/.config/code-virtuoso/`), then `<project root>/.code-virtuoso/config.json`, then `<project root>/.code-virtuoso/config.local.json`. Skip any that do not exist.
3. Start with an empty object. For each file you found, in that order, copy its values on top. Where both sides hold an object, merge them key by key. Where either side holds a list or a single value, the later file wins.
4. Read your namespace from the result. For every key that is still missing, use the default from your skill or agent.

## Writing config

Writing happens only during setup in the main session. Reuse `root` and `home` from the read recipe. Create the layer file if needed, then change only your keys.

```bash
f="$root/.code-virtuoso/config.json"
mkdir -p "$root/.code-virtuoso"
[ -f "$root/.code-virtuoso/.gitignore" ] || printf '*.local.json\nloop/state/\nhandoff/\n' > "$root/.code-virtuoso/.gitignore"
[ -f "$f" ] || echo '{"version":1}' > "$f"
jq --arg v "main" '.["ticket-delivery"].mainBranch = $v' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
```

For the user layer, set `f` to `$home/config.json` and run `mkdir -p "$home"` first. For a nested key such as `commands.test`, use `.["ticket-delivery"].commands.test = $v`.

## Behavior rules

1. **Read.** Resolve all layers, merge, use the result. Missing files are normal.
2. **Interactive setup runs only in the main session, never inside a subagent.** Every question is tagged `scope: user` or `scope: project`. Write the answer to that layer and show the user the path of the file written. Team decisions go to the project layer. Personal choices go to the user layer.
3. **Subagents never prompt.** If a needed value is missing, use the default and end the report with: `Defaults used for: <keys>. Run <skill> setup to save them.`
4. **Discoverability.** The setup flow offers to add one line to the project `AGENTS.md` (or `CLAUDE.md`): `Shared tool decisions: .code-virtuoso/config.json`. Add it only if the user agrees.
5. **Show what changed.** After a write, name the file and the keys written.

## Migration from legacy files

Earlier versions saved choices in files next to the skill or agent. On first run, if the namespace is empty in every layer, look for legacy files and import them.

| Consumer | Legacy locations | Parse |
|---|---|---|
| `ticket-delivery` | `.supplement.md` next to the skill, `~/.agents/skills/ticket-delivery/.supplement.md`, `~/.agents/skills/ticket-workflow/.supplement.md`, `~/.claude/skills/*/ticket-delivery/.supplement.md` | `KEY: value` lines and `- **Label**: value` bullets |
| Agent `<agent>` | `.<agent>.tune.md` next to the agent file, `~/.agents/skills/<agent>/.<agent>.tune.md`, `~/.claude/skills/*/<agent>/.<agent>.tune.md` | `KEY: value` lines |

- Convert each legacy key to its camelCase config key (each consumer lists its mapping).
- Imported values go to the user layer. That keeps today's global behavior.
- If the run is inside a git project with no `.code-virtuoso/config.json`, offer to move the project-scope keys there.
- Leave the legacy file in place and tell the user it can be deleted. After migration there are no fallback reads of legacy files.

## Security

- Never store secrets. A writer must reject any key whose name matches `token`, `secret`, `password`, or `apikey` (case-insensitive), and must not write values that look like credentials.
- The project shared file is committed, so it holds nothing personal and nothing sensitive. Put tool names and commands there, never credentials or tokens.
- Never read or print `.env` files to fill in config values.

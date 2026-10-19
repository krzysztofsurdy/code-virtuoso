# Phase 6: Validate and write

**Progress: Phase 6 of 6**

## Purpose

Run the validation checklist, write the agent file, and register it when it ships in this library.

## Steps

1. Run the checklist from [validation.md](../references/validation.md):
   - [ ] Description contains both "what it does" and "when to delegate"
   - [ ] Tool allowlist is the minimum needed
   - [ ] `isolation: worktree` is set when the agent changes source code, and absent otherwise
   - [ ] `memory` is set only on purpose, and the user knows it grants Write and Edit
   - [ ] System prompt has Input, Process, Rules, and Output sections
   - [ ] Output section contains a concrete template
   - [ ] Body contains no persona bloat or filler
   - [ ] Name matches the file name and is kebab-case

2. If any check fails, state which and offer to fix it before writing.

3. Write the agent markdown file at the chosen path.

4. If the target is this library:
   - Add the agent file path to the `agents` list of the `agents-virtuoso` entry in `.claude-plugin/marketplace.json` (the only entry with `"source": "./"`) and bump `metadata.version` (minor for a new agent, patch for an edit)
   - Add a row to the agent tables in `README.md` and `AGENTS.md`
   - Run `python3 scripts/build-codex-agents.py` to generate `codex/agents/<name>.toml`
   - Run `python3 scripts/validate-agents.py` and `python3 scripts/validate-marketplace.py`

   Other projects need no marketplace entry: the agent file in the chosen directory is enough.

5. Echo the final path and line count to the user.

6. Offer: "Do you want to test-invoke this agent now?"

## Gate

**Advances when:** the file is written, registered, and the user is satisfied.
**Returns to a previous phase when:** validation fails and the user wants to fix the issue at its source.

This is the final phase. After writing, confirm: "Agent `[name]` created at `[path]` ([line count] lines). Want to test-invoke it?"

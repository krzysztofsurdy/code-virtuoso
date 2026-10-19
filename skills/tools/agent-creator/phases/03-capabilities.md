# Phase 3: Capabilities

**Progress: Phase 3 of 6**

## Purpose

Decide tool permissions, isolation, memory, role reference files, and preloaded skills for the agent.

## Steps

Present the decisions as one batched question set.

1. **Tool permissions**: start from read-only and add only what the workflow requires. Use the decision tree in [tool-selection.md](../references/tool-selection.md):

   | Needs | Typical allowlist |
   |---|---|
   | Investigation / review / audit | File reading, code search, shell |
   | Documentation or planning documents | File reading, code search, shell, file editing (runs in place) |
   | Implementation | File reading, code search, shell, file editing, plus `isolation: worktree` |
   | Coordination | File reading, code search, shell, plus sub-agent spawning pinned to named agents |

2. **Isolation**: set `isolation: worktree` when the agent changes source code. Read-only agents, documentation-only writers, and planning roles that write only planning documents run in place.

3. **Memory**: most specialists are stateless. Role agents that accumulate cross-session context use `memory: project`. Say plainly that Claude Code then enables Read, Write, and Edit for the agent so it can manage its notes. A read-only agent with `memory` is no longer read-only. Skip for specialists.

4. **Role reference files** (role archetype only): list the templates and checklists the agent reads on demand. They live in `roles/<role>/` as plain files without frontmatter, and the body points to each by path with `${CLAUDE_PLUGIN_ROOT}/roles/<role>/<file>` plus a repository-relative fallback. Do not create a role skill and do not preload one.

5. **Preloaded skills**: list skills the agent needs on every run, at most four, by bare `name`. Names resolve across all installed plugins. A skill that is not installed is skipped silently, and preloads do not load when the agent runs as the main session (`claude -p --agent`), so the agent must still work without them. Skills marked run-by-name (`disable-model-invocation: true`) cannot be preloaded: point the body at their reference files instead. If the skill ships in a different bundle, say which bundle to install.

## Gate

**Advances when:** the user has confirmed tools, isolation, memory, and skills.
**Returns to this phase when:** the user wants to adjust permissions.

Ask the user: "Capabilities summary. Tools: [list], Isolation: [worktree/none], Memory: [scope/none], Role files: [list/none], Skills: [list]. Confirm or adjust?"

Do not proceed to Phase 4 until the user confirms capabilities.

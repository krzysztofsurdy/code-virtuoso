# Phase 3: Capabilities

**Progress: Phase 3 of 6**

## Purpose

Decide tool permissions, isolation, memory, and preloaded skills for the agent.

## Steps

Present four decisions as one batched question set.

1. **Tool permissions**: start from read-only and add only what the workflow requires. Use the decision tree in [tool-selection.md](../references/tool-selection.md):

   | Needs | Typical allowlist |
   |---|---|
   | Investigation / review / audit | File reading, code search, shell |
   | Documentation | File reading, code search, shell, file editing |
   | Implementation | File reading, code search, shell, file editing |
   | Coordination | File reading, code search, shell, plus sub-agent spawning |

2. **Isolation**: if the agent writes source code, set `isolation: worktree`. Read-only agents never need isolation.

3. **Memory**: most specialists are stateless. Role agents that accumulate cross-session context use project-level memory. Skip for specialists; offer for role and team-lead archetypes.

4. **Preloaded skills**: list skills whose reference content the agent needs at startup. One to four is typical. Reference by `name` field, not path.

## Gate

**Advances when:** the user has confirmed tools, isolation, memory, and skills.
**Returns to this phase when:** the user wants to adjust permissions.

Ask the user: "Capabilities summary. Tools: [list], Isolation: [worktree/none], Memory: [scope/none], Skills: [list]. Confirm or adjust?"

Do not proceed to Phase 4 until the user confirms capabilities.

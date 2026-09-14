# Phase 5: Placement and scope

**Progress: Phase 5 of 6**

## Purpose

Decide where the agent file lives and what scope it has.

## Steps

1. Ask the user where the agent should be placed:

   | Scope | Location | Use when |
   |---|---|---|
   | **Project** | Project agent directory | Agent is specific to this codebase, committed with the repo |
   | **User / personal** | User-level agent directory | Personal agent reused across all projects |
   | **Plugin / marketplace** | Inside the plugin's `agents/` directory | Agent ships as part of a distributable bundle |
   | **Session-only** | Passed inline via CLI flag | One-off testing or automation |

   See [platforms.md](../references/platforms.md) for exact paths per platform.

2. Project scope is the safest default for team-shared work. Recommend it unless the user has a specific reason for another scope.

3. If the target is a marketplace-style project, note that marketplace registration will be handled in Phase 6.

## Gate

**Advances when:** the user has chosen a scope and confirmed the target location.
**Returns to this phase when:** the user is unsure about scope and needs guidance.

Ask the user: "Agent will be placed at [path] with [scope] scope. Confirm?"

Do not proceed to Phase 6 until the user confirms placement.

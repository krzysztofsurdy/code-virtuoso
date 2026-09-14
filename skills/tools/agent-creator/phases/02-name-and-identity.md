# Phase 2: Name and identity

**Progress: Phase 2 of 6**

## Purpose

Derive a kebab-case name that describes the agent's role, then confirm it with the user.

## Steps

1. Derive a name from the purpose defined in Phase 1. The name describes the role, not the task:
   - Good: `investigator`, `reviewer`, `migration-planner`, `backend-dev`
   - Bad: `agent1`, `helper`, `do-stuff`, `claude-assistant`

2. Check for collisions: if the name matches an existing agent in the target scope (see Phase 5), append a qualifier (`reviewer-security`, `reviewer-frontend`) rather than overwriting.

3. Present the proposed name to the user.

## Gate

**Advances when:** the user confirms the name.
**Returns to this phase when:** the user wants a different name, or a collision was found.

Ask the user: "Proposed name: `[name]`. This will be the filename (`[name].md`) and the `name` field in frontmatter. Confirm or suggest an alternative?"

Do not proceed to Phase 3 until the user confirms the name.

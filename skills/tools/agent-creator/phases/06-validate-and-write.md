# Phase 6: Validate and write

**Progress: Phase 6 of 6**

## Purpose

Run the validation checklist, write the agent file, and register it.

## Steps

1. Run the checklist from [validation.md](../references/validation.md):
   - [ ] Description contains both "what it does" and "when to delegate"
   - [ ] Tool allowlist is the minimum needed
   - [ ] `isolation: worktree` is set if and only if the agent modifies files
   - [ ] System prompt has Input, Process, Rules, and Output sections
   - [ ] Output section contains a concrete template
   - [ ] Body contains no persona bloat or filler
   - [ ] Name matches the file name and is kebab-case

2. If any check fails, state which and offer to fix it before writing.

3. Write the agent markdown file at the chosen path.

4. If the target is a marketplace project:
   - Register the agent in the appropriate plugin entry of the marketplace manifest
   - Add the agent row to any README or agent index

5. Echo the final path and line count to the user.

6. Offer: "Do you want to test-invoke this agent now?"

## Gate

**Advances when:** the file is written, registered, and the user is satisfied.
**Returns to a previous phase when:** validation fails and the user wants to fix the issue at its source.

This is the final phase. After writing, confirm: "Agent `[name]` created at `[path]` ([line count] lines). Want to test-invoke it?"

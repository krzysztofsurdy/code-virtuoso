# Phase 5: Approval Gate

**Progress: Phase 5 of 5**

## Purpose

Get explicit user approval before anything proceeds. This is the hardest rule in the skill. No exceptions.

## Steps

1. Wait for the user's response to the spec presented in Phase 4.
2. Handle the response:

   **If the user requests changes:**
   - Return to the relevant phase (Phase 2 for new scope, Phase 3 for boundary changes, Phase 4 for spec revisions)
   - Revise and re-present

   **If the user introduces new scope:**
   - Return to Phase 2 for that scope, then re-converge in Phase 3

   **If the user says "approve", "looks good", "ship it", "yes", or equivalent:**
   - Verify: all must-have acceptance criteria are present and testable
   - Verify: no unresolved contradictions remain
   - If both checks pass: the spec is approved

3. After approval:
   - The spec is the contract. Implementation must satisfy its acceptance criteria.
   - Hand off to the appropriate next step (planning, architecture, or implementation skill)

## Rules

**Before approval, you must NOT:**
- Write any code (not even pseudocode presented as "just an example")
- Create project files or directories
- Choose specific technologies, libraries, or frameworks
- Produce architecture diagrams or system designs
- Invoke any implementation, planning, or code-generation skill

## Exit Criteria

Brainstorming is complete when ALL of the following are true:
- The spec is written and covers all mandatory sections
- The user has explicitly approved the spec
- No unresolved contradictions exist
- All must-have acceptance criteria are present and testable
- The scope boundary (goals + non-goals) is clear

See [when-to-exit](../references/when-to-exit.md) for detailed guidance on "done" vs. "needs more rounds."

## Gate

This is the final phase. After approval, confirm: "Spec approved. Ready to hand off to [recommended next step based on the spec's complexity and scope]."

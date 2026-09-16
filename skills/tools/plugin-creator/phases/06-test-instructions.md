# Phase 6: Test and install instructions

**Progress: Phase 6 of 6**

## Purpose

Print test commands, reload instructions, and next steps so the user can verify their plugin works.

## Steps

1. Print the **full tree of what was created** (relative paths only).

2. Print **test commands:**
   - Local test: `claude --plugin-dir ./<plugin-name>`
   - Reload during development: `/reload-plugins`
   - Validation: `claude plugin validate`

3. Print **next steps** based on distribution choice:
   - **Standalone:** "Push to a git host, then share the repo URL with users."
   - **New marketplace:** "Push the marketplace repo, then users install via the plugin manager."
   - **Existing marketplace:** "Commit the updated marketplace.json, push, and users update to pick up the new entry."

4. Print **distribution considerations** (only if relevant):
   - Semantic versioning rules
   - How to pin to branch/tag/sha
   - Plugin caching caveat (files outside the plugin root are not cached; use symlinks)

## Gate

This is the final phase. There is no gate.

Confirm: "Plugin `[name]` scaffolded successfully. Run the test command above to verify."

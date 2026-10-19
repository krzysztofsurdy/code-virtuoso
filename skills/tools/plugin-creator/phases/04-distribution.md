# Phase 4: Distribution decision

**Progress: Phase 4 of 6**

## Purpose

Determine how the plugin will be distributed: standalone, new marketplace, or added to an existing marketplace.

## Steps

1. Ask: **"How will this plugin be distributed?"** (single-select)
   - **Standalone**: just the plugin directory, tested locally
   - **New marketplace**: create a sibling marketplace.json listing this plugin
   - **Add to existing marketplace**: append to an existing marketplace.json

2. **If Standalone:** No further questions. Go to the gate.

3. **If New marketplace:**
   - Marketplace name (kebab-case; reject reserved names - see [references/marketplace-manifest.md](../references/marketplace-manifest.md))
   - Marketplace owner name (free text)
   - Marketplace owner email (optional)
   - Layout: Flat (single-plugin repo) or Nested (multi-plugin repo, recommended). In a multi-entry repository, every entry whose `source` is `"./"` registers the root `agents/`, `commands/`, `workflows/`, and hooks, so give each plugin its own directory or use a narrower source such as `"./skills"` for skill-only bundles

4. **If Add to existing marketplace:**
   - Path to existing marketplace.json
   - Read it, preserve existing fields, append new plugin entry, bump minor version
   - Check the sources of existing entries. If another entry already uses `"./"` and the new plugin has `agents/`, `commands/`, `workflows/`, or hooks, do not add a second `"./"` entry

5. Ask where the version lives: one place only, either `plugin.json` or the marketplace entry. If neither sets one, the commit SHA is the version and every commit counts as an update.

See [references/marketplace-manifest.md](../references/marketplace-manifest.md) for the full schema and [references/distribution.md](../references/distribution.md) for versions, Codex, and uninstall behavior.

## Gate

**Advances when:** Distribution choice is confirmed and any marketplace details are complete.
**Returns to this phase when:** User wants to change distribution method.

Ask the user: "Distribution: [choice]. [details if marketplace]. Confirm?"

Do not proceed to Phase 5 until the user confirms.

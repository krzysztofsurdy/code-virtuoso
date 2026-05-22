# Phase 4: Distribution Decision

**Progress: Phase 4 of 6**

## Purpose

Determine how the plugin will be distributed: standalone, new marketplace, or added to an existing marketplace.

## Steps

1. Ask: **"How will this plugin be distributed?"** (single-select)
   - **Standalone** - just the plugin directory, tested locally
   - **New marketplace** - create a sibling marketplace.json listing this plugin
   - **Add to existing marketplace** - append to an existing marketplace.json

2. **If Standalone:** No further questions. Proceed to gate.

3. **If New marketplace:**
   - Marketplace name (kebab-case; reject reserved names - see [references/marketplace-manifest.md](../references/marketplace-manifest.md))
   - Marketplace owner name (free text)
   - Marketplace owner email (optional)
   - Layout: Flat (single-plugin repo) or Nested (multi-plugin repo, recommended)

4. **If Add to existing marketplace:**
   - Path to existing marketplace.json
   - Read it, preserve existing fields, append new plugin entry, bump minor version

See [references/marketplace-manifest.md](../references/marketplace-manifest.md) for the complete schema.

## Gate

**Advances when:** Distribution choice is confirmed and any marketplace details are complete.
**Returns to this phase when:** User wants to change distribution method.

Ask the user: "Distribution: [choice]. [details if marketplace]. Confirm?"

Do NOT proceed to Phase 5 until the user confirms.

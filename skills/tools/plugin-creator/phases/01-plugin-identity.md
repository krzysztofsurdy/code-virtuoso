# Phase 1: Plugin Identity

**Progress: Phase 1 of 6**

## Purpose

Collect the plugin's core metadata: name, description, version, and author.

## Steps

1. If the user provided a plugin name as argument, use it as the default (still confirm).

2. Ask up to 4 questions in a single batch:
   - **Q1. Plugin name** (free text, required) - Must be kebab-case, no spaces. Becomes the namespace: `/plugin-name:skill-name`. Reject spaces, uppercase, or non-alphanumeric characters other than `-`.
   - **Q2. Short description** (free text, required) - One sentence shown in the plugin manager.
   - **Q3. Starting version** (options) - `1.0.0` (stable, recommended), `0.1.0` (pre-stable), or `Other` (must match MAJOR.MINOR.PATCH).
   - **Q4. Author** (free text, optional) - Format: `Name <email>` or just `Name`. Blank to omit.

3. After Q1-Q4, ask a single yes/no: **"Add optional metadata (homepage, repository, license, keywords)?"** If yes, batch:
   - Homepage URL (optional)
   - Repository URL (optional)
   - License SPDX identifier (MIT, Apache-2.0, GPL-3.0, BSD-3-Clause, UNLICENSED, Other)
   - Keywords (comma-separated, optional)

See [references/plugin-manifest.md](../references/plugin-manifest.md) for the complete field list.

## Gate

**Advances when:** User confirms name, description, version, and author.
**Returns to this phase when:** Name is not valid kebab-case, or user wants to change metadata.

Ask the user: "Plugin identity - name: `[name]`, version: [version], description: [desc]. Confirm?"

Do NOT proceed to Phase 2 until the user confirms.

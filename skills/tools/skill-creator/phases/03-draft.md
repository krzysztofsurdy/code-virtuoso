# Phase 3: Draft

**Progress: Phase 3 of 4**

## Purpose

Write SKILL.md and references from the ledger and the baseline gaps, with no unsourced claim.

## Steps

1. Write the frontmatter. The description is third person, says what the skill does and when to use it, leads with the phrases a person types, and stays near 300 characters (hard limit 1024). Put all "when to use" text there, not in the body. Add `user-invocable` as chosen in Phase 2, and `argument-hint` only if the skill takes arguments. No `model` field.
2. Write the body in order: a short statement of the skill's purpose, the rules or procedure, gotchas, and a table of reference files. Open with the problem, not a definition. Explain why a rule exists instead of shouting MUST. Add a Core Principles table or an Integration table only when it carries information the body does not.
3. Move detail into `references/`, one level deep and linked from SKILL.md, each file on one topic. Start any file over 100 lines with a `## Contents` list of H2 links. Reference files have no frontmatter. Keep SKILL.md under 500 lines.
4. For every checkable claim, take it from the ledger or leave it out. Where a fact is volatile, write the decision rule and link the official page. Remove dates and "latest" wording.
5. Keep the content agent-agnostic: name capabilities, not one product's tools. Put product specifics in a short Platform Notes table near the bottom, and give each row a source. Mark an unknown platform `(TBD)`.
6. Write plainly: short sentences, no filler or hype words, sentence-case headings, no em or en dashes, at most one blank line in a row, file ends with one newline.
7. Cut anything the model already knows, then read the draft as a stranger would. A section that traces to neither a baseline gap nor a ledger fact goes.

## Gate

**Advances when:** the draft is written and the user has seen it.
**Returns to this phase when:** the user asks for changes, or Phase 4 finds a wrong fact.

Ask the user: "Draft is at [path] ([line count] lines, [n] reference files). Review it, then I will verify the commands and links and register it. Changes first?"

Do not proceed to Phase 4 until the user confirms.

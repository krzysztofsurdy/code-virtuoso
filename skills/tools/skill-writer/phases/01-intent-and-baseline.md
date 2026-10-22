# Phase 1: Intent and baseline

**Progress: Phase 1 of 4**

## Purpose

Decide what the skill must change, when it should fire, and whether it should exist at all.

## Steps

1. Pull answers from the conversation first (steps taken, corrections the user made, formats seen). Then ask only for what is missing, in one batch:
   - What should the agent do differently once the skill is loaded?
   - What would a person type that should trigger it? Ask for three real phrasings
   - What should not trigger it (the nearest neighbors)?
   - What does good output look like?
2. Run the baseline. Give the agent two or three realistic prompts without the skill and note what it gets wrong: missed steps, wrong versions, invented flags, generic advice. Use the research notes to spot errors. If the agent does the task correctly, stop and tell the user a skill is not needed.
3. Check for existing skills to extend instead of duplicate: search this repo (`skills/`), the installed skills, and `npx skills find "<topic>"`. If one covers most of the need, propose editing it.
4. Write the failures from step 2 down as the skill's reason to exist. Every section of the draft should trace to one of them or to a ledger fact.

## Gate

**Advances when:** the user confirms purpose, trigger phrases, non-goals, and the baseline gaps, and no existing skill should be extended instead.
**Returns to this phase when:** the baseline shows no gap, or an existing skill fits.

Ask the user: "Here is what I captured: [purpose, triggers, non-goals, baseline gaps, overlap check]. Does this describe the skill you want?"

Do not proceed to Phase 2 until the user confirms.

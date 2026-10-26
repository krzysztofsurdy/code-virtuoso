# Phase 4: Verify and register

**Progress: Phase 4 of 4**

## Purpose

Prove the draft is correct, make sure it triggers, and register it.

## Steps

1. Verify facts. Walk the draft claim by claim against the ledger. Run every command and snippet in a scratch directory and compare the output with what the skill says. Open every external link and confirm it resolves to the page the skill describes. Fix or cut anything that fails, and update the ledger.
2. Check structure with [checklist.md](../references/checklist.md): description rules, size budget, one-level references, Contents lists, agnostic content.
3. Add trigger eval cases in `evals/cases/triggers/` as `<skill>-fires-1`, `<skill>-fires-2`, and `<skill>-near-miss`, following `evals/README.md`. Prompts are what a person would type and never name the skill or quote its description. The near miss is a neighboring task that should not call the skill. Each case has `prompt.md` and `graders/skill-fired.md` (a `tool_used` grader on `Skill`; the near miss adds `min: 0` and `max: 0`). Run `evals/run.sh check`.
4. Register the skill when it ships in this library. Add its path to the matching `*-virtuoso` plugin in `.claude-plugin/marketplace.json` and bump the version (minor for a new skill, patch for an edit). Add it to the README skill tables and structure. Other projects need no registration.
5. Run `python3 scripts/validate-skills.py` and `python3 scripts/validate-markdown.py`, and fix what they report. A new skill that is not yet registered shows an orphan error, which step 4 clears.
6. Hand off the evals. If Anthropic's `skill-creator` is available, give it the finished skill to run the with-and-without comparison and tune the description. If it is not, run `evals/run.sh triggers --case '<skill>-*'` and read the transcripts.
7. Save the final research notes next to the PR or in the place the user chose. If research was skipped, repeat "research skipped at user request" in the PR description.

## Gate

**Advances when:** every ledger claim is confirmed or marked, commands and links were checked, validators pass, and the skill is registered.
**Returns to a previous phase when:** a fact fails (Phase 3 or 0), or the trigger cases misfire (Phase 3, description).

This is the final phase. Report: skill path, line count, research depth and the not-confirmed list, validator results, and which eval tool the description went through.

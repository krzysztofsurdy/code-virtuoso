---
name: retro
description: Reviews an agent coding session for friction (repeated mistakes, wasted tool calls, missing checks, ignored rules) and turns each finding into the cheapest durable fix, preferring a lint rule, hook or CI check over prose. Use for 'run a retro', 'we keep making the same mistake', 'improve my agent setup'.
user-invocable: true
argument-hint: "[optional: what went wrong, or a path to notes or a transcript]"
---

# Retro

An agent session ends and the lessons go with it. The same correction gets typed again next week, and the usual fix, one more line in a rules file, is the weakest one: the file grows, the agent skips lines, and the mistake returns. This playbook looks back at a session, finds where it lost time or quality, and picks for each finding the cheapest fix that lasts. Default to a deterministic check. Write a prose rule only when no check can catch the problem.

This is for the agent's working environment, not a team ceremony. For a Scrum sprint retrospective use the `scrum` skill.

**A repeated mistake with no guardrail is itself a finding.** Fixing the code once does not count as a fix.

## Procedure

1. **Gather the friction.** Work from evidence, not a feeling that it went badly:
   - The current conversation: corrections the user made, errors, retries, dead ends.
   - `git log` and `git diff` for the session: reverted edits, fix-up commits, files touched twice.
   - Command output: failing checks, slow steps, commands that were run and changed nothing.
   - Progress or handoff notes if they exist.

   If the session is not in front of you, ask the user for the three or four moments that hurt most. Do not invent findings. Seven real ones beat twenty guesses. Scan the categories in [categories](references/categories.md) so nothing obvious is missed.

2. **Write each finding as one fact.** What happened, how many times, what it cost (turns, retries, a wrong commit). "Agent imported from the old module path in 3 files, user corrected it twice" is a finding. "Agent was sloppy" is not.

3. **Classify the fix.** Take the first row that fits.

   | The problem is | Fix | Lands in |
   |---|---|---|
   | A fixed pattern a program can recognise: banned API, import shape, file location, naming, formatting, a missing step before commit | **Deterministic check** | Linter or static-analysis rule, formatter config, pre-commit hook, agent hook, CI job, or a test |
   | A call that needs taste or context a program cannot judge | **One short rule** | The project's rules file, or a path-scoped rule if it applies to one area |
   | The agent could not find something, or loaded too much | **Navigation or context fix** | A pointer in the rules file, a doc moved or renamed, an instruction file trimmed or split |
   | A step that changed nothing, or a tool call repeated | **Remove or cache it** | Drop the step from the workflow, script, or skill, or record the answer where the agent finds it |

   Take the decision details, the check types, and the cases where a check is the wrong tool from [check-vs-rule](references/check-vs-rule.md).

4. **Propose, do not apply.** Present one table and wait for the user to approve:

   | # | Finding | Category | Cheapest durable fix | Where it lands | Permanent or one-off |
   |---|---|---|---|---|---|

   Under the table show the actual content of each change: the lint config, the hook script, the rule line, the doc edit. The user approves what they can read. Group the table by fix type so the user can accept all checks and decline a rule in one reply.

5. **Apply what was approved.** Build checks first, then rules. For an agent hook or a settings change use `hooks-and-guardrails`, which has tested scripts and the exit-code rules. For a rules-file edit use `agentic-rules-writer` and keep to the size budgets in `context-engineering`. Run each new check against the code that caused the finding. If it does not fail on the old mistake, it is not a check yet. Run it on the rest of the repo too, to see what else it flags.

6. **Decide what is permanent.** For each applied change say whether it stays (a check on a recurring pattern, a rule about a real convention) or was a one-off (a workaround for this task, a note that belongs in a handoff). One-offs go to a `handoff` note or nowhere. Nothing one-off goes into an always-on file.

## Pitfalls

- **Rules by default.** Adding a line to the rules file is the cheapest to write and the most expensive to keep. Ask "can a program catch this?" before every rule.
- **A check that never failed.** A guardrail you have not seen fire is a guess. Reproduce the old mistake once and watch it get caught.
- **Noisy checks.** A check with many false positives gets disabled, and then the mistake has no guardrail again. Narrow it or leave it out.
- **Blaming the agent for a bad setup.** If the agent could not find the test command, the fix is a line saying where it is, not a lecture about trying harder.
- **Rewriting the instruction files wholesale.** A retro adds, moves, or removes specific lines tied to specific findings. For a full audit of the files, hand it to the `instruction-auditor` agent (read-only) and take its findings into step 3.
- **Applying without approval.** Hooks and CI changes affect everyone who works in the repo. Always get a yes first.

## Reference files

| Reference | Open when |
|---|---|
| [categories](references/categories.md) | Step 1, to scan the seven friction categories with the signs to look for in each |
| [check-vs-rule](references/check-vs-rule.md) | Step 3, to choose between check, rule and context fix, to pick the kind of check, and to see worked examples |

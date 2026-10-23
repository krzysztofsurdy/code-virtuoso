# Check, rule, or context fix

How to pick the cheapest durable fix for a finding, what kind of check to build, and when a check is the wrong tool.

## Contents

- [Decision questions](#decision-questions)
- [Kinds of check](#kinds-of-check)
- [Writing a check that holds](#writing-a-check-that-holds)
- [When a check is the wrong tool](#when-a-check-is-the-wrong-tool)
- [Writing the rule that remains](#writing-the-rule-that-remains)
- [Worked examples](#worked-examples)
- [Permanent or one-off](#permanent-or-one-off)

## Decision questions

Ask in this order and stop at the first yes.

1. Can a program recognise the mistake from the code, the file path, or the command alone? Build a check.
2. Can a program recognise the missing step, such as tests not run, formatter not run, or the stop-time state being red? Build a hook or CI job.
3. Does the agent only lack a fact, such as where something lives or how to run it? Add a pointer.
4. Is it taste, trade-off, or context that changes case by case? Write one short rule.
5. Would the line ever be consulted again? If not, it is a one-off. Keep it out of the setup.

"Cheapest" counts the whole life of the fix: writing it, running it, reviewing it, and the context it uses on every future session. A check costs no context. A rule costs context in every session.

## Kinds of check

Pick the one that fires closest to the mistake and is already in your toolchain. Names below are examples. Confirm options in the tool's documentation before writing config.

| Kind | Catches | Examples | Feedback speed |
|---|---|---|---|
| Linter or static-analysis rule | Banned API, import shape, naming, type misuse, layer boundaries | A restricted-imports rule, a banned-API list, a custom static-analysis rule, an architecture or dependency-boundary tool | Per edit or per run |
| Formatter | Layout and style | The project formatter in a post-edit hook | Per edit |
| Test | Behaviour that went wrong once | A regression test for the reported bug | Per run |
| Small script | Paths, names, forbidden strings, required files | A script that greps the diff for a forbidden pattern and exits non-zero | Per commit or per run |
| Pre-commit hook | Anything above, before it reaches the branch | The project's pre-commit tool running the linter and the script | Per commit |
| Agent hook | A rule for the agent's own actions: blocked paths, checks after edits, tests before stopping | See `hooks-and-guardrails` for scripts and exit codes | Per tool call or per stop |
| CI job | Everything that must hold for every contributor | The same commands as local, run on every pull request | Per push |

Prefer the checks that also help humans (linter, tests, CI). Use an agent hook only for something specific to how the agent works.

## Writing a check that holds

- **Reproduce first.** Create the old mistake, run the check, and confirm it fails. Then fix the code and confirm it passes.
- **Run it on the whole repo.** If it flags many existing files, decide now: fix them, baseline them, or narrow the rule. A check that is red on day one gets turned off.
- **Make the message do the teaching.** The failure text is read by the agent in the same turn. Name the problem and the replacement ("import from `app/clock`, not `datetime`"), not just "rule violated".
- **Keep it fast.** A per-edit check that takes seconds gets disabled. Slow checks go to commit time or CI.
- **Put it where everyone gets it.** A rule in the committed linter config reaches people and agents alike. A local-only hook reaches one machine.

## When a check is the wrong tool

| Case | Why | Do instead |
|---|---|---|
| The rule needs judgement ("keep functions small", "name things well") | A threshold lint produces false positives and teaches the agent to game it | One short rule, or leave it to code review |
| The pattern has many legitimate exceptions | Exceptions pile up as ignore comments | A rule that states the exception, or no rule |
| The mistake happened once and is unlikely again | The check costs more than the mistake | Note it as a one-off |
| The tool cannot express the pattern without a custom plugin that nobody will maintain | A fragile check is worse than none | A rule, plus a test for the worst case |
| It would block an action that is sometimes right | The agent or user will route around it | A warning, not a block |

## Writing the rule that remains

When a rule is the right fix, keep it to one line that names the behaviour and, if short, the reason.

- State what to do, not what to avoid, when you can.
- Put it in the narrowest place that loads when it matters: a path-scoped rule or nested file beats the always-on file.
- Before adding, check the file for a line it makes redundant, and delete that line in the same change.
- Stay inside the size budgets in `context-engineering`. A retro that grows the rules file has failed.
- For where it goes per tool, see `agentic-rules-writer` and `context-engineering`.

## Worked examples

| Finding | Category | Fix | Lands in |
|---|---|---|---|
| Agent called the raw HTTP client in 4 files, user corrected twice. The project has a wrapper. | Coding standard, mechanical | Banned-import rule in the linter that names the wrapper in its message | Linter config, runs in CI |
| Agent said "done" with a failing type check | Missing check | Stop-time hook that runs the type check and tests | Agent hook via `hooks-and-guardrails` |
| Agent edited files under `generated/` three times | Navigation, mechanical | Block writes to that path, and mark it generated in the rules pointer | Agent hook plus one pointer line |
| Agent searched 11 times for the test command | Navigation | One line with the exact commands | Rules file |
| Agent over-abstracted a small helper | Coding standard, judgement | One line: "Prefer a plain function until a third caller exists" | Rules file |
| Formatter re-run after every edit with no diff | No-op | Remove the manual step, run the formatter in a post-edit hook only | Workflow or skill text |
| Agent guessed a library signature for the wrong version | Information gap | Point to the lockfile and use docs lookup | Rules pointer, `docs-lookup` |
| Rules file is 400 lines and half is ignored | Instruction size | Hand to the `instruction-auditor` agent, delete and split by its findings | Rules files |

## Permanent or one-off

| Keep in the setup | Leave out of the setup |
|---|---|
| A check on a pattern that can recur | A workaround for this one task |
| A rule about a real, lasting convention | A note about this week's branch or ticket |
| A pointer to a stable doc or command | A fact that will be wrong after the next refactor |
| A fix to a process step that is always wasted | A one-time manual correction |

One-offs belong in a `handoff` note if the next session needs them, and nowhere else.

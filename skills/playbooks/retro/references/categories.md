# Friction categories

Use this list in step 1 as a scan, not a form to fill. Skip a category with no evidence. Each row says what the friction looks like and where the fix usually goes.

## Contents

- [Navigation friction](#navigation-friction)
- [Missing or weak automated checks](#missing-or-weak-automated-checks)
- [Coding-standard violations](#coding-standard-violations)
- [Instruction file size and drift](#instruction-file-size-and-drift)
- [Tool economy](#tool-economy)
- [No-ops](#no-ops)
- [Information access gaps](#information-access-gaps)

## Navigation friction

The agent got lost in the repository.

| Sign | Usual fix |
|---|---|
| Many searches before it found the file that owns a feature | A pointer in the rules file to the entry point, or a rename that matches the vocabulary people use |
| It edited the wrong copy (generated file, vendored code, an old duplicate) | Mark the path read-only in a hook or deny rule, or delete the duplicate |
| It did not know how to run one test, the build, or the linter | The exact command in the rules file, or a script with an obvious name |
| It read a huge file to find one function | Split the file, or add an outline or index it can read first |

## Missing or weak automated checks

A mistake reached the user because nothing automatic stood in the way.

| Sign | Usual fix |
|---|---|
| The user found a bug the test suite did not | A regression test for it, written before the fix |
| Tests pass but the code does not build, lint, or type check | Run all of them in one command and in CI, then point the agent at it |
| The agent said "done" while a check was failing | A stop-time hook that runs the checks, see `hooks-and-guardrails` |
| The check exists but takes minutes, so it was skipped | A fast subset for per-edit feedback, the full run in CI |
| The suite is flaky and the agent learned to ignore red | Fix or quarantine the flaky test. Ignored red hides real red |

## Coding-standard violations

The code broke a convention that the project already knows.

| Sign | Usual fix |
|---|---|
| Same pattern corrected by the user more than once | A lint or static-analysis rule. This is the main target of a retro |
| Formatting corrected by hand | Formatter on save or in a post-edit hook |
| A layer boundary crossed (domain code importing infrastructure) | An architecture or import-boundary rule in the linter |
| A naming or file-location convention broken | A small script in pre-commit or CI that checks paths and names |
| A judgement call, such as how much to abstract | One short rule, or nothing. Taste cannot be linted |

## Instruction file size and drift

The rules were there but did not hold.

| Sign | Usual fix |
|---|---|
| The agent followed the rules at the start and not later | Shorten the file, or add a prompt reminder hook (see `context-engineering`, "Instruction drift") |
| A rule was ignored and the file is long | Delete lines that do not prevent a mistake, move scoped rules to path-scoped files |
| Two files disagree | Keep one source of truth |
| A rule names a file, command, or skill that no longer exists | Delete or correct it. The `instruction-auditor` agent finds these in one pass |
| Rules duplicate what a linter already enforces | Delete the rule. The linter wins |

## Tool economy

Calls that cost time or context without moving the work forward.

| Sign | Usual fix |
|---|---|
| The same file read or the same search run several times | Note the answer where the agent will see it, or work from a short summary |
| A large command output pulled into context for one fact | A script that prints only that fact, or a filter in the command |
| Serial calls that could have run together | Say so in the workflow, or batch them in a script |
| A broad search that a better index or pointer would have avoided | Add the pointer |
| Reading the whole repository to answer a narrow question | Hand the search to a subagent that returns a short answer |

## No-ops

Steps that changed nothing.

| Sign | Usual fix |
|---|---|
| A formatter or generator re-run with no diff | Remove the step, or run it only when its inputs changed |
| An edit that was reverted or overwritten in the same session | Find why, often an unclear spec or two tools fighting over a file |
| A check run twice with nothing changed between | Drop one, or cache the result |
| A workflow step the agent always skips or always reports "nothing to do" | Remove it from the skill or script |

## Information access gaps

The answer existed but the agent could not reach it.

| Sign | Usual fix |
|---|---|
| It asked the user something the repo or ticket already answered | A pointer to the ticket, spec, or doc |
| It guessed an API or version instead of checking | Point to the lockfile or the docs, see `docs-lookup` |
| A needed tool, token, or service was not available in the session | Record the access need in setup notes. Never put secrets in rules files |
| Context lived only in chat or someone's head | Write it to a file in the repo, see `handoff` |
| The agent could not see the running app or the logs | Give it a command that shows them |

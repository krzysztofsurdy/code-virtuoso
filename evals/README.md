# Behavior evals

Tests for what the skills do, not only how they read. They use [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals), which needs Claude Code 2.1.269 or later (written and checked against 2.1.306) and git 2.31 or later. Every run is a real model call on your account.

## What is covered

| Suite | Cases | What it proves |
|---|---|---|
| `cases/triggers` | 53 | Eighteen skills each get up to two realistic prompts that should call the skill and one near miss that should not. |
| `cases/outcomes` | 33 | One behavior per case that the skill should cause, run with and without the plugin. For example, `verification-before-completion`: the agent runs the tests and reports the failure instead of claiming done. `docs-lookup`: the agent reads `composer.lock` and states the locked version. `tdd`: the agent sees a failing test before it writes `slug.py`. `agentic-rules-writer`: the generated `AGENTS.md` is short, keeps the user's own rules, and has no filler or routing table. |

Skills with trigger cases: verification-before-completion, docs-lookup, spec-driven-development, tdd, pr-feedback, finishing-branch, hooks-and-guardrails, context-engineering, skill-creator, skill-measure, research, agentic-rules-writer, ui-review, game-feature-loop, godot, godot-upgrade, security-research, communication-style.

Prompts are what a person would type. They never name the skill, and they do not quote a description, so you can reword a description without touching a case. A trigger case passes when the agent calls the Skill tool with that skill name. A near miss passes when it does not.

## How to run

```bash
evals/run.sh check      # free: stage the plugin and load every case, fails on a malformed case
evals/run.sh triggers   # trigger cases, no baseline arm
evals/run.sh outcomes   # outcome cases, with and without the plugin, Bash and file writes granted
evals/run.sh all        # triggers, then outcomes
```

Run all suites:

```bash
EVAL_MODEL=claude-sonnet-5-5 EVAL_JUDGE_MODEL=claude-haiku-5-5 evals/run.sh all --max-cost-usd 15
```

Extra arguments go to `claude plugin eval`, so these work:

```bash
evals/run.sh triggers --case 'tdd-*' --runs 1          # one skill, one run each
evals/run.sh outcomes --case docs-lookup-reads-lockfile-first --runs 1 --ablation none
evals/run.sh outcomes --verbose --keep-temp            # keep each run's sandbox and trace.jsonl
```

| Variable | Default | Effect |
|---|---|---|
| `EVAL_THRESHOLD` | `0.8` | A case passes when its score is at least this. The command exits 1 otherwise. |
| `EVAL_OUT` | new temp dir | Where `aggregate-result.json` and `report.html` go, one subdirectory per suite. |
| `EVAL_MODEL` | Claude Code default | Model under test. Pin it in CI. |
| `EVAL_JUDGE_MODEL` | Claude Code background model | Model for the one `llm` grader. |
| `EVAL_DRY_RUN` | unset | Print the `claude plugin eval` commands instead of running them. |

Cases run three times each by default and the score is the mean. Cost estimate: one short trigger run cost about $0.05 and the Bash outcome run about $0.15 in a trial, and the full set is roughly 210 trigger runs plus 24 outcome runs, so budget around $15 and cap it with `--max-cost-usd`.

The suite scripts run with `--scaffold`: each fixture is a short `fixture.sh` in its case directory that writes a few files into the empty workspace. Read them before you run (the CLI prints a reminder). The outcome pass grants `Write`, `Edit` and `Bash(python3 *)`. Claude Code runs granted Bash commands in its OS sandbox, which needs `bubblewrap` and `socat` on Linux.

## Layout and why it is staged

The docs require the eval directory to sit inside a plugin root that has a manifest (`.claude-plugin/plugin.json`). The marketplace bundles here have none:

| Marketplace plugin | `source` | Plugin root | Manifest |
|---|---|---|---|
| knowledge, tools, playbooks, frameworks, ai | `./skills` | `skills/` | none |
| agents-virtuoso | `./` | repo root | none |
| loop-virtuoso | `./plugins/loop-virtuoso` | that folder | yes |

Pointing `claude plugin eval` at the repo root prints `Plugin under test: none resolved`, runs every case as plain Claude Code, and no skill loads (tried; `skills/` has no manifest either). The CLI has no `--plugin-dir` flag. Targeting `name@marketplace` would mean adding this checkout as a local marketplace and installing from it in your own Claude Code config, where the name `code-virtuoso` is already taken by the published marketplace. So `evals/stage.sh` builds a throwaway plugin instead:

```
evals/
  README.md
  run.sh                 runs the suites against a staged plugin
  stage.sh               builds the staged plugin in a temp dir
  tests/test-stage.sh    tests for the scripts and the case layout
  cases/                 copied to <staged plugin>/evals/
    triggers/<skill>-fires-1, <skill>-fires-2, <skill>-near-miss
    outcomes/<name>
```

`stage.sh` reads `.claude-plugin/marketplace.json`, copies every skill and agent that any relative-source plugin lists into one plugin named `code-virtuoso-evals`, and writes a manifest. Three consequences:

- The staged plugin holds the skills of all bundles at once, which is what a user with several bundles installed has. A near miss can only pass if no other skill steals the prompt either, and trigger names appear as `code-virtuoso-evals:<skill>` (the graders accept any prefix).
- A skill missing from `marketplace.json` is missing from the eval, so a dropped skill fails its trigger cases.
- `loop-virtuoso` is not staged. It has its own manifest, so you can add `plugins/loop-virtuoso/evals/` and run `claude plugin eval plugins/loop-virtuoso` directly.

`cases/` follows the docs layout: one directory per case with `prompt.md` (frontmatter and prompt), `graders/<name>.md`, and `case.yaml` plus `fixture.sh` only where a fixture is needed. Tags are `trigger`, `near-miss`, `outcome`, plus the skill name, so `--tag tdd` selects one skill.

## Graders

| Case kind | Graders |
|---|---|
| Trigger | `tool_used` on `Skill` with an `input_match` for the skill name. |
| Near miss | The same grader with `min: 0` and `max: 0`. |
| verification outcome | `tool_used` Bash with `unittest` (weight 2), a `regex` on the final message that cites test output, and one short `llm` rubric that the reply does not call failing work done. |
| docs-lookup outcome | `tool_used` Read on `composer.lock`, and a `regex` for the locked version `6.4.13` in the final message. |
| tdd outcome | `tool_order` (a `unittest` run before the first write of `slug.py`), a `regex` over the trace that a test result showed a failure, and `file_exists` for `slug.py`. |

Under the default two-arm run the CLI treats `tool_used: Skill` graders as indicators, not score. That is why the trigger pass uses `--ablation none`: every grader there is a Skill check and the baseline arm would only double the cost.

Known limits: the tdd order check can fail a run that writes a stub `slug.py` before its first test run, and the verification case passes without the skill when the model already runs the tests, so read its `Δ` and not only its score.

## Baseline results (2026-10-21)

Model under test `claude-sonnet-5-5`, judge `claude-haiku-5-5`, three runs per case, `--ablation none`. The first full trigger run cost $7.95. Four of the trigger groups in the table below did not pass at first, and all four are background skills (`user-invocable: false`) except `tdd`: Claude undertriggers skills for tasks it believes it can do with its own tools, so the transcripts showed it answering from memory, grepping `composer.lock`, spawning agents directly, or even running the steps in an untrusted `issue.md`, without calling the Skill tool. The fix was to rewrite each description so it leads with the phrases a person types and says to use the skill even when it is not asked for by name. One round was run; the spend cap was reached before a second.

| Skill | First run (fires-1 / fires-2) | After round 1 (fires-1 / fires-2) | Near miss after | What changed in the description |
|---|---|---|---|---|
| verification-before-completion | 0.00 / 0.00 | 1.00 / 1.00 | 1.00 | Leads with 'mark it done', 'should work now', 'ready', PR summary and handoff note; run the check even if not asked. |
| docs-lookup | 0.00 / 0.00 | 0.33 / 1.00 | 1.00 | Leads with exact signature, argument order, 'our version', 'in 7.2'; check docs or lockfile even when sure. |
| tdd | 0.33 / 0.00 | 0.67 / 0.00 | not re-run | Leads with 'fix this bug', 'add a function', 'use TDD', 'write the test first'. |
| context-engineering | 0.33 / 1.00 | 1.00 / 1.00 | not re-run | Leads with trim, split or write AGENTS.md and CLAUDE.md ('CLAUDE.md is too long'), ignored instructions, drift. |
| research (10.1.0) | 0.67 / 0.00 | 1.00 / 1.00 | 1.00 | Leads with research, compare or choose between tools, best practice, what changed recently. The near-miss grader also lacked `min: 0, max: 0`. |
| skill-creator (10.1.0) | 1.00 / 1.00 | not needed | 1.00 | Passed on the first run. |

Re-runs cost $4.43 in total ($0.56 to $1.34 per skill). Still open:

- `tdd-fires-2` ("total() ignores the discount, fix it") names neither tests nor TDD, and the model fixes small bugs directly. Treat TDD as a user-invoked playbook (`/tdd`) or an always-on instruction line rather than expecting a description to override that.
- `docs-lookup-fires-1` improved but is flaky (1 of 3). Reword the case text only if it is unrealistic. Otherwise add 'the version in this project' to `docs-lookup`, then re-run.

## Adding a case

1. Add `evals/cases/<group>/<name>/prompt.md` with `tags`, `max_turns` and `allowed_tools` in the frontmatter, and the prompt as the body. Do not quote a skill description.
2. Add at least one file under `graders/`. Put a regex or tool check first and an `llm` grader only for short output.
3. If the prompt needs files, add `case.yaml` (`schema_version: "1.1"`, `name`, `context.scaffold_script: fixture.sh`) and a `fixture.sh`.
4. Run `bash evals/tests/test-stage.sh` and `evals/run.sh check`, then one run of the case with `--runs 1`.

## CI

Copy [`examples/ci/evals.yml`](../examples/ci/evals.yml) to `.github/workflows/evals.yml` and add the `ANTHROPIC_API_KEY` secret. It installs a pinned Claude Code, installs the Bash sandbox prerequisites, runs the free checks, then `evals/run.sh all --max-cost-usd 15`, and uploads the results. It runs on pull requests that touch skills, agents or evals, weekly, and on demand. Fork PRs are skipped because GitHub withholds secrets from them. If the sandbox cannot start on your runner image, the outcome cases show a run error and score 0: fix the runner (user namespaces for `bubblewrap`) or run only `evals/run.sh triggers`.

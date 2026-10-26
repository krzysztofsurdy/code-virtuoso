# Measuring the setup itself: `eval-setup`

A CLAUDE.md, a set of skills, plugins, hooks and MCP servers all cost context and attention on every call. Whether they pay for it is an empirical question: the same model with none of them may do as well on your work. `scripts/eval-setup.sh` (or `/loop-virtuoso:eval-setup`) answers it on a fixed task suite: each task runs k times with your setup and k times with a vanilla Claude Code, and a literal `verifyCommand` grades every trial.

## Contents

- [Pick the tasks](#pick-the-tasks)
- [Suite format](#suite-format)
- [Run it](#run-it)
- [Read the results](#read-the-results)
- [The vanilla arm](#the-vanilla-arm)
- [Cost control](#cost-control)
- [Going deeper](#going-deeper)

## Pick the tasks

About 20 tasks is enough to see a real difference and cheap enough to rerun. Take them from work that went wrong, not from invented exercises:

1. **Review traces.** Read recent session transcripts, PR review comments, and the `blocked` items in `.code-virtuoso/loop/state/progress.log`. Note each place the agent did the wrong thing (open coding), then group the notes into failure types.
2. **One task per failure type that your setup is meant to fix.** If a skill exists because the agent kept writing tests after the code, a task should catch that. A setup element with no task behind it is not being measured.
3. **Add a few tasks that vanilla already passes.** They catch a setup that makes easy work worse.
4. **Write the prompt as you would type it.** Do not add hints the setup would otherwise supply; that measures the hint, not the setup.
5. **Make the grader binary.** `verifyCommand` exits 0 for pass and anything else for fail: a test file, a `grep` for the required change, a script that checks the outcome. Grade the result, not the path the agent took. Run it once at HEAD (it must fail) and once against a known-good solution (it must pass) before trusting it.

`setup` (optional) runs in the fresh worktree before the agent starts: check out a commit, apply a patch, delete a file, seed a fixture. A failing setup stops the whole run with `setup_failed`, because it is a suite bug, not an agent result.

## Suite format

`<git root>/.code-virtuoso/loop/evals/suite.json`:

```json
{
  "version": 1,
  "tasks": [
    {
      "id": "T1",
      "prompt": "Add a --dry-run flag to bin/export that prints the rows instead of writing them",
      "setup": "git checkout -q 3f2a9c1",
      "verifyCommand": "bash tests/export_dry_run.sh"
    }
  ],
  "config": {
    "k": 3,
    "maxTurns": 40,
    "allowedTools": ["Read", "Edit", "Write", "Bash(npm test:*)"],
    "permissionMode": "acceptEdits",
    "maxCostUsd": 25
  }
}
```

Required per task: `id` (unique), `prompt`, `verifyCommand`. Every `config` key is optional; the defaults are `k` 3, `maxTurns` 40, `permissionMode` `acceptEdits`, no `allowedTools` flag and no cost cap. The script rejects an invalid suite before it invokes anything.

Worktrees are created from HEAD, so the agent sees committed files only. If the suite itself is committed, the agent can read every `verifyCommand`. That is the same for both arms, but it lets an agent aim at the grader. Keep the suite untracked, or point `verifyCommand` at a check script outside the repository.

## Run it

```
scripts/eval-setup.sh [suite.json] [-k N] [--arms setup,vanilla] [--max-cost-usd N] [--dry-run]
```

- `--dry-run` validates the suite and prints the trial count, the per-arm command line and the task list. It creates no worktree and invokes nothing. Run it first, every time.
- `-k` overrides `config.k`; `--max-cost-usd` overrides `config.maxCostUsd`; `--arms setup` runs one arm only (no delta).
- For each task the trials are interleaved: trial 1 of every arm, then trial 2, and so on. Each trial gets a new detached worktree at HEAD under a temp directory: `setup`, one `claude -p`, then `verifyCommand` in that worktree. The worktree is removed after every trial and on any exit.
- Both arms get the same call: `-p <prompt> --output-format json --permission-mode <mode> --max-turns <n> [--allowedTools ...]`. The vanilla arm adds its vanilla arguments, nothing else differs.

Exit status is 0 when every trial ran, 1 on an invalid suite or a stop: `cost_cap`, `setup_failed`, or `invocation_failed` (no JSON from `claude`, most often a usage or rate limit).

## Read the results

Per task and arm the report shows passes/k, pass@k and pass^k:

| Metric | Question | Use it for |
|---|---|---|
| pass@k | Did at least one of k trials pass? | The ceiling: can this arm do the task at all |
| pass^k | Did all k trials pass? | The floor: does it do the task every time |

Arm totals count tasks (pass@k 14/20 means 14 tasks passed at least once), plus passes over all trials. The delta line is setup minus vanilla for each total and for the overall pass rate.

A setup earns its cost when it raises pass^k: you rely on it to get the task right without a retry. A higher pass@k with no change in pass^k means the setup sometimes helps and the result is still a coin flip. A delta of one task on 20 tasks with k=3 is within run-to-run noise; trust a delta that holds over two or three runs of the same suite.

`.code-virtuoso/loop/evals/history.jsonl` gets one line per real run: `ts`, `gitSha`, `suite`, `suiteHash`, `k`, `maxTurns`, `armsRun`, `vanillaArgs`, `stopReason`, per-task rows (`tasks`), per-arm totals (`arms`), `delta` and `totalCostUsd`. Compare only runs with the same `suiteHash`; a changed suite is a new baseline.

```
jq -c 'select(.suiteHash == "<hash>") | [.ts, .gitSha[0:7], .arms.setup.passHatK, .arms.vanilla.passHatK, .delta.passRate]' \
  .code-virtuoso/loop/evals/history.jsonl
```

A run that stopped early (`stopReason` other than `complete`) has fewer trials; its totals cover only the tasks that ran.

## The vanilla arm

Default: `--safe-mode`. Per `claude --help` and the CLI reference, it starts Claude Code with CLAUDE.md, skills, plugins, hooks, MCP servers, custom commands and agents, output styles, workflows and auto memory disabled, while authentication, model selection, built-in tools and permissions work normally. Admin-managed policy settings still apply to both arms. That isolates exactly the customizations, with the same login and the same model on both sides.

Rejected alternatives:

- `--bare` reads auth only from `ANTHROPIC_API_KEY` or an `apiKeyHelper`, never OAuth or the keychain, so it fails on a subscription login.
- `--setting-sources` (with `--strict-mcp-config`) drops settings files, including the model and permission settings, so the arms would differ in more than the customizations, and it is not documented to skip CLAUDE.md or skills.
- An empty `CLAUDE_CONFIG_DIR` loses the login on macOS, where credentials live in the keychain.

Override with `loop.evalSetup.vanillaArgs` (an array of strings) in any config layer, for example `.code-virtuoso/config.json`:

```json
{ "loop": { "evalSetup": { "vanillaArgs": ["--safe-mode", "--strict-mcp-config"] } } }
```

The array replaces the default, so include `--safe-mode` when you still want it. The arguments go to the vanilla arm only and are recorded in every history line.

## Cost control

- A run makes tasks x arms x k calls. Start with `-k 1` to check the graders, then run k=3.
- Set `config.maxCostUsd` or pass `--max-cost-usd`. The cap is checked before each trial, so a run overshoots by at most one trial. Because trials interleave, a cap cuts every arm at the same depth and the comparison stays fair.
- `maxTurns` bounds each trial. A trial cut off by it is graded like any other: the `verifyCommand` decides.
- Cost comes from `total_cost_usd` in the JSON output. On a Claude subscription that is a notional figure, but the cap still works; hitting the plan's usage limit stops the run with `invocation_failed` instead.

## Going deeper

The `ai-virtuoso` plugin's `llm-evals` skill covers the method in depth: `references/error-analysis.md` for trace review and failure taxonomies, `references/agent-evals.md` for task design, trial isolation, pass@k versus pass^k, and suite saturation.

---
description: "Measure your Claude Code setup against vanilla Claude Code on a fixed task suite (costs money)"
argument-hint: "[suite.json] [-k N] [--arms setup,vanilla] [--max-cost-usd N] (default <git root>/.code-virtuoso/loop/evals/suite.json)"
allowed-tools: ["Bash(${CLAUDE_PLUGIN_ROOT}/scripts/eval-setup.sh:*)"]
---

# Evaluate the setup

Compares two arms on the tasks in `.code-virtuoso/loop/evals/suite.json`: **setup** (your CLAUDE.md, skills, plugins, hooks, MCP servers and settings) and **vanilla** (the same `claude -p` call with `--safe-mode`, or `loop.evalSetup.vanillaArgs` when set). Every trial is a real `claude -p` call in a throwaway git worktree, graded by the task's `verifyCommand`.

**A real run costs money.** It makes tasks x arms x k calls (20 tasks, 2 arms and k=3 is 120 agent runs). Never start one without the user's explicit approval.

1. Always start with a dry run, passing along any arguments the user gave:

   ```
   ${CLAUDE_PLUGIN_ROOT}/scripts/eval-setup.sh $ARGUMENTS --dry-run
   ```

   It validates the suite and prints the trial count, the per-arm command line, the cost cap and the task list. It invokes nothing. If it reports an invalid suite, relay the problems and stop.
2. Show the dry-run output to the user and ask whether to run it for real. Point out the trial count and the cost cap. If there is no cap (`Cost cap : none`), suggest one with `--max-cost-usd`. Wait for a clear yes.
3. After approval, run the same command without `--dry-run`. A full suite takes far longer than one tool call allows, so run it in the background and report when it finishes, or give the user the command to run in a terminal.
4. Relay the final report verbatim: passes/k, pass@k and pass^k per task and arm, the arm totals, the setup minus vanilla delta, total cost and the stop reason (`complete`, `cost_cap`, `setup_failed` or `invocation_failed`). Each run also appends one line to `.code-virtuoso/loop/evals/history.jsonl`.

For how to build the suite, read the results and compare runs over time, see the `iteration-loop` skill's `references/setup-evals.md`.

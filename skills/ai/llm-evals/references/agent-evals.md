## Contents

- [Vocabulary](#vocabulary)
- [Design a task](#design-a-task)
- [Isolate every trial](#isolate-every-trial)
- [Grade the outcome and the transcript](#grade-the-outcome-and-the-transcript)
- [Non-determinism: pass@k and pass^k](#non-determinism-passk-and-passk)
- [Capability and regression suites](#capability-and-regression-suites)
- [Saturation](#saturation)
- [Other signals to record](#other-signals-to-record)
- [Debug the eval, not only the agent](#debug-the-eval-not-only-the-agent)
- [Sources](#sources)

# Agent evals

An agent acts over many steps and changes the world as it goes. A single answer check is not enough. Agent evals run the agent on tasks, several times each, and check what actually happened.

## Vocabulary

| Term | Meaning |
|---|---|
| Task | One test case: inputs plus success criteria. Also called a problem or test case |
| Trial | One attempt at a task. Multiple trials per task, because runs differ |
| Grader | Logic that scores one aspect of a trial. A task can have several graders, each with several checks |
| Transcript | The full record of a trial: messages, reasoning, tool calls, tool results. Also called a trace or trajectory |
| Outcome | The final state of the environment after the trial |
| Harness | The code that sets up the environment, runs the agent, collects the transcript, and calls the graders |

The difference between transcript and outcome matters. A booking agent may say "your table is booked". The outcome is whether the reservation row exists.

## Design a task

A good task has an answer you can check without opinion.

- **Unambiguous.** Two experts reading the task would agree on what success means. If they would not, fix the task first.
- **Solvable.** Ideally you have a reference solution that passes the graders. A task nobody can pass tells you about the task, not the agent.
- **Realistic.** Copy it from a real failure, support ticket, or user request.
- **Balanced.** Include cases where the correct action is to do nothing or to refuse. Without them, an agent that always acts looks perfect.
- **Specific about stop conditions.** State the turn, time, or cost limit.

Start with 20 to 50 tasks drawn from real failures. Early changes have large effects, so a small set shows them.

## Isolate every trial

Each trial starts from the same clean state. Shared state creates correlated failures and can inflate scores. One reported case: an agent gained an unfair edge by reading version-control history left by earlier trials.

| Source of leakage | Fix |
|---|---|
| Files left in the working directory | Fresh directory or container per trial |
| Database rows from a previous trial | Reset or snapshot-restore the database |
| Cached tool results or memory stores | Clear caches. Namespace memory per trial |
| Network access to the answer | Block it or mock the services |
| Shared rate limits causing random errors | Throttle the harness and retry infra errors outside the score |

Separate harness failures from agent failures. If the harness crashes, mark the trial as an error and rerun it. Do not count it as an agent fail.

## Grade the outcome and the transcript

| What to check | How | Good for |
|---|---|---|
| End state | Query the database, run the test suite, read the file, call the API | Whether the task succeeded. Prefer this as the main grader |
| Tool calls | Assert a tool was called, was not called, got specific arguments, or ran in a required order | Hard rules (never delete, always confirm before payment) |
| Transcript quality | A validated judge over the transcript for one named failure | Behavior code cannot see (invented facts, ignored instruction) |
| Efficiency | Count steps, tokens, cost, wall time | Regressions in cost and latency |

Guidance:

- **Grade what the agent produced, not the path it took.** Agents often find valid routes you did not expect. Strict step-by-step checks fail good runs. Use path checks only for rules that must hold.
- **Use partial credit with care.** Several binary checks per task (file created, tests pass, no forbidden call) give a score between 0 and 1. Report the task as passed only when the critical checks pass.
- **Run code graders first.** If the outcome check fails, a judge opinion about the transcript adds little.
- **Keep judges short.** Long transcripts reduce judge accuracy. Hand the judge the relevant excerpt, not everything.
- **Record the transcript for every trial**, passing or not. You will read many of them.

## Non-determinism: pass@k and pass^k

The same agent on the same task can pass once and fail the next time. Run k trials and report a rate, not one run.

| Metric | Question it answers | Formula if trials are independent with success rate p |
|---|---|---|
| pass@k | Does at least one of k trials succeed? | 1 - (1 - p)^k |
| pass^k | Do all k trials succeed? | p^k |

pass@k goes up as k grows. pass^k goes down. For p = 0.75:

| k | pass@k | pass^k |
|---|---|---|
| 1 | 75 percent | 75 percent |
| 3 | 98 percent | 42 percent |
| 5 | 99.9 percent | 24 percent |

Pick by product promise:

| Product | Metric |
|---|---|
| Agent that generates candidates and a human or test picks the best (code suggestions with tests) | pass@k |
| Agent that acts alone for the user each time (customer support, payments, workflows) | pass^k |
| Mixed | Report both and say which one gates releases |

In real data trials are rarely independent, and each task has its own p. Treat the formulas as a guide and compute the metrics from observed trials per task. State k in every report.

Use enough trials to separate signal from noise. If two versions differ by less than the spread between repeat runs of the same version, you have no result. Run the same version twice to measure that spread.

## Capability and regression suites

| | Capability suite | Regression suite |
|---|---|---|
| Question | What can the agent do well? | Does it still do what it used to? |
| Starting pass rate | Low. Room to grow | Near 100 percent |
| Role of a drop | Normal while exploring | A failure. Something broke |
| Source of tasks | Hard cases, new features, stretch goals | Tasks the agent solves, fixed past failures |
| Runs | Nightly or per release | Every change |

Tasks move from capability to regression when the agent solves them reliably. Keep both. A suite that mixes them gives a score that is neither a progress meter nor a safety net.

## Saturation

Saturation happens when the agent passes every task it can pass. The suite then shows no improvement even when real capability improves. Near saturation, gains look like tiny score changes.

- Add harder tasks from new failures and new features.
- Retire or demote tasks that every version passes.
- Read transcripts of passing trials now and then. A pass that took a lucky route is a weak signal.
- Watch for graders that are too lenient. A 100 percent pass rate often means the grader is weak, not that the agent is perfect.

## Other signals to record

Capture these on every trial. They cost nothing and explain score changes.

| Signal | Why |
|---|---|
| Number of model calls and tool calls | Loops and wasted steps |
| Input, output, and cached tokens, and cost | Cost regressions |
| Wall time, time to first token for streaming UIs | Latency regressions |
| Stop reason (finished, hit step limit, error) | Separates "failed" from "ran out of budget" |
| Which tools were used | Detects a tool that never gets called |

The same fields should be in your production traces so offline and online numbers can be compared. See `llm-observability`.

## Debug the eval, not only the agent

When a task fails, read the transcript before changing the agent.

| Finding | Meaning | Action |
|---|---|---|
| Agent did something reasonable that the grader rejects | Grader too strict or task ambiguous | Fix the grader or the task |
| Environment error, missing file, flaky service | Harness problem | Fix the harness. Do not count it |
| Agent gave up or looped | Real failure | Fix prompt, tools, or limits |
| Passed for the wrong reason | Weak grader | Tighten the check |

A task that gets 0 percent across many trials usually has a broken task or grader. Check it with the reference solution before blaming the agent.

For Claude Code plugins and skills, `claude plugin eval` implements this model: cases with a prompt and graders, several runs per case, a no-plugin baseline, and a threshold that sets the exit code. See [tooling](tooling.md).

## Sources

- Anthropic, Demystifying evals for AI agents (2026-01-09): https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- Hamel Husain and Shreya Shankar, AI Evals FAQ (updated 2026-09-18): https://hamel.dev/blog/posts/evals-faq/

---
name: llm-evals
description: Evaluate and regression-test LLM features and agents with trace error analysis, binary graders, code assertions, validated judges, and CI thresholds. Use when building an eval suite, checking a prompt or model change, or measuring agent quality.
user-invocable: false
---

# LLM evals

An eval is a test for behavior you cannot specify with an exact expected output. The method is the same as any good test practice: look at real failures, write a check for each one, run the checks on every change. Most teams skip the first step and start with a dashboard of generic scores. Those scores look precise and tell you nothing about what breaks for your users.

## Core Principles

| Principle | Meaning |
|---|---|
| **Look at data first** | Read real traces before writing any grader. The failure list comes from the data, not from a metrics catalog. |
| **Binary verdicts** | Each grader answers pass or fail for one specific failure. Scales hide disagreement and invite the middle score. |
| **Code before models** | Use an assertion when the property is checkable in code. A model judge is a last resort for what code cannot see. |
| **One judge per failure** | A judge that scores "overall quality" cannot be validated. A judge for one named failure can. |
| **Validate the grader** | An unvalidated LLM judge is an opinion. Measure it against human labels before trusting its number. |
| **Grade outcomes** | Check the end state of the world, not only what the agent said or the path it took. |
| **Evals are code** | Version them, run them in CI, and treat a drop as a failing test. |

## Workflow

1. **Collect traces.** Use production logs if you have them. Before launch, write realistic inputs by hand or generate varied ones and run them through the system. Capture full transcripts: inputs, tool calls, outputs. See [error-analysis](references/error-analysis.md).
2. **Read and annotate.** Open-code roughly 30 or more traces yourself, noting the first thing that went wrong in each. Continue toward about 100 diverse traces until new ones reveal no new kinds of failure.
3. **Build a failure taxonomy.** Group the notes into named categories and count them. Fix the cheap ones first: a missing instruction or a broken tool is a bug, not an eval target.
4. **Pick a grader per remaining failure.** Code assertion if possible, otherwise one validated judge. See the table below.
5. **Validate every judge** against human labels with a train, dev, and test split. Report TPR and TNR on the held-out set. See [judge-calibration](references/judge-calibration.md).
6. **Assemble the regression suite.** Real failures that you fixed, plus a few critical happy paths. Start with 20 to 50 cases, not hundreds. Keep it cheap enough to run on every change.
7. **Gate changes in CI** with thresholds. Re-run error analysis on fresh traces every few weeks and after major changes, because the failure list drifts.

## Choosing a grader

| Property to check | Grader | Notes |
|---|---|---|
| Output is valid JSON, matches a schema, has required fields | Code | Parse and validate. Cheapest and exact. |
| Contains or avoids a string, pattern, or number | Code | Regex or exact match. |
| Right tool called, right arguments, right order, no forbidden call | Code on the transcript | See [agent-evals](references/agent-evals.md). |
| Task actually succeeded (record exists, tests pass, file changed) | Code on the final state | The strongest check an agent eval has. |
| Answer matches a reference fact | Code if the fact is atomic, else judge | Break the reference into small binary facts. |
| Tone, faithfulness to a source, policy compliance, helpfulness for a stated rubric | One LLM judge per failure | Needs validation. |
| Subtle, high-stakes, or new failure types | Human review | Use to create labels and spot-check judges. |

Generic metrics such as "helpfulness" scores, ROUGE, BERTScore, or cosine similarity are not quality measures for most LLM apps. At best they help you pick traces to read.

## Judge rules in brief

- Write the judge prompt for one failure with a clear definition, a pass example, and a fail example.
- Ask for a short reason, then a binary verdict. Parse the verdict with code.
- Label data once, by a domain expert, then split it. Never tune the prompt on the test set, and do not reuse test examples as few-shot examples.
- Track both TPR (real failures caught) and TNR (good outputs passed). One alone can be gamed by always answering the same way.
- Treat a judge score as an estimate with error. Correct it with the measured TPR and TNR, and report an interval. Details in [judge-calibration](references/judge-calibration.md).
- Re-check the judge when you change the judge model, the app, or the input distribution.

## Agent evals in brief

An agent eval runs the agent on a task several times (trials), grades the outcome and sometimes the transcript, and reports a rate.

| Term | Meaning |
|---|---|
| Task | One case with inputs and success criteria |
| Trial | One attempt at a task. Run several, since output varies |
| Transcript | Full record of a trial: messages, tool calls, results |
| Outcome | Final state of the environment after the trial |
| pass@k | Chance that at least one of k trials succeeds. Use when one success is enough |
| pass^k | Chance that all k trials succeed. Use when users need consistency |
| Capability suite | Hard tasks with a low starting pass rate, to measure progress |
| Regression suite | Tasks the agent already solves, expected near 100 percent |
| Saturation | The agent passes everything solvable, so the suite no longer shows gains |

A 75 percent per-trial success rate gives about 98 percent pass@3 and about 42 percent pass^3. Pick the metric that matches the product promise. Start each trial from a clean environment, or leftover state will correlate failures and inflate scores. Full guidance in [agent-evals](references/agent-evals.md).

## In CI and in production

- **Fast suite on every pull request.** Code assertions plus a small set of validated judges. Fail the build when a metric drops below its threshold. Pin the judge model and the dataset version so a score change means the app changed.
- **Deterministic where possible.** Code graders and recorded fixtures cost nothing and never flake. Spend model calls on what needs them, and use batch pricing for large offline runs.
- **Thresholds from baselines.** Set the gate from the current measured rate, with a margin for noise. Do not set it at 100 percent for a stochastic system, except for hard safety checks.
- **Nightly or release suite.** Larger sets, more trials, expensive judges.
- **Production sampling.** Each week, review 10 to 20 traces: a few random, plus outliers such as long traces, retries, unusual tool sequences, negative user feedback. Keep some random traces in every batch so you can still find failures your signals do not describe. Add confirmed failures to the regression suite.
- **Online judges** can flag suspect traces for review. Treat their output as a queue for humans, not as a quality score.

## Common mistakes

| Mistake | Fix |
|---|---|
| Starting with a metrics dashboard | Read 100 traces, build the taxonomy, then choose graders |
| 1-to-5 scores | Binary pass or fail per failure mode, or several binary sub-checks |
| One judge for "quality" | One judge per named failure, each validated |
| Judge never checked against humans | Label data, split it, report TPR and TNR on a test set |
| Tuning the judge on all labels | Keep a test split untouched until the end |
| 100 percent pass rate treated as success | The suite is too easy or saturated. Add harder cases |
| Grading only the final text of an agent | Also check the final state of the environment |
| Strict path checks on agents | Grade the outcome. Check steps only for hard rules |
| Shared state between trials | Reset the environment for every trial |
| Eval set built once and never refreshed | Re-run error analysis on new traces regularly |
| Raw judge pass rate reported as the truth | Correct for judge error and give an interval |

## Quality checklist

- [ ] At least 30 traces annotated by a human, taxonomy written down with counts
- [ ] Review continued until new traces showed nothing new
- [ ] Every grader is binary and tied to one named failure
- [ ] Code assertions used wherever the property is checkable in code
- [ ] Each LLM judge validated on a held-out split, TPR and TNR recorded
- [ ] Judge model, prompt, and dataset versions pinned
- [ ] Agent tasks have a clean environment per trial and an outcome check
- [ ] pass@k or pass^k chosen deliberately, with k stated
- [ ] Regression suite runs in CI with documented thresholds
- [ ] Production traces sampled on a schedule and fed back into the suite

## Reference Files

| Reference | Contents |
|---|---|
| [error-analysis](references/error-analysis.md) | Sampling, open coding, failure taxonomy, saturation, cold start, turning findings into evals |
| [judge-calibration](references/judge-calibration.md) | Judge prompt design, label splits, TPR and TNR, bias correction, intervals, drift |
| [agent-evals](references/agent-evals.md) | Tasks, trials, isolation, transcript and outcome grading, pass@k vs pass^k, suites, saturation |
| [tooling](references/tooling.md) | Eval tools and their status as of 2026-10-21, selection guide, CI wiring, plugin evals |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Tracing the app so there are traces to read | `llm-observability` |
| General test strategy, isolation, flaky tests | `testing` |
| Wiring the suite into a pipeline and quality gates | `cicd` |
| Diagnosing why an eval started failing | `debugging` |
| Designing the agent being evaluated | `agent-design` |
| Red-teaming and injection checks for LLM apps | `agent-security` |
| Building the app with the Vercel AI SDK or LangChain | `vercel-ai-sdk`, `langchain-components` |
| Latency and cost regressions found by evals | `performance` |
| Confirming a change works before calling it done | `verification-before-completion` |

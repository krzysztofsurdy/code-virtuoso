## Contents

- [Tool map](#tool-map)
- [Choosing a tool](#choosing-a-tool)
- [What every setup needs](#what-every-setup-needs)
- [Claude Code plugin evals](#claude-code-plugin-evals)
- [Migrating off the OpenAI Evals platform](#migrating-off-the-openai-evals-platform)
- [CI pattern](#ci-pattern)
- [Sources](#sources)

# Eval tooling

Tools change owners and shut down. Status below was checked on 2026-10-21. Verify before you commit to one. The method in the other files works with any of them, or with plain test code.

## Tool map

| Tool | What it is | Status and licence | Strength |
|---|---|---|---|
| Promptfoo | CLI and library for running eval and red-team suites from declarative config | Acquired by OpenAI (announced 2026-03-09). OpenAI says it keeps the open-source project, MIT licensed, and support for models beyond OpenAI | Config-driven suites, CI use, red teaming, provider-neutral |
| OpenAI Evals platform | Hosted dashboard and API from OpenAI | Read-only 2026-10-31. Dashboard and API shut down 2026-11-30 | Do not start new work here. See [migration](#migrating-off-the-openai-evals-platform) |
| Inspect | Python framework from the UK AI Security Institute and Meridian Labs | Open source, `pip install inspect-ai` | Datasets, solvers, scorers, agents, sandboxes (Docker, Kubernetes), log viewer, 200+ prebuilt evals |
| DeepEval | Pytest-style Python framework | Apache 2.0. Separate commercial platform (Confident AI) for production monitoring | Unit-test style evals, G-Eval judge metric, agent metrics |
| Braintrust | Hosted evals and observability | Commercial | Experiments, datasets, scorers, accepts OTLP traces |
| LangSmith | Hosted tracing, datasets, evals from LangChain | Commercial. Self-hosted option | Trace-to-dataset flow, accepts OTLP traces |
| Langfuse | Tracing, evals, prompt management | Open source and self-hostable. Acquired by ClickHouse (announced 2026-01-16) | Traces, datasets, scores, annotation, accepts OTLP |
| Phoenix (Arize) | Tracing and evals | Self-hostable. Elastic License 2.0, which is source-available rather than OSI open source | OpenTelemetry and OpenInference tracing, LLM evals package |
| `claude plugin eval` | Built into Claude Code v2.1.269 or later | Part of Claude Code | Tests Claude Code plugins and skills. See below |

Notes:

- Ownership changes do not change what a tool does, but they affect roadmaps and licences. Prefer an export path and plain data formats (JSONL for datasets and traces) so you can move.
- All of the hosted tools can store traces, datasets, and human labels. The grading logic can live in your own code regardless.

## Choosing a tool

| Need | Option |
|---|---|
| Few cases, one team, no vendor | Plain test code in your usual test runner plus a JSONL dataset |
| Many prompts and models compared in CI from config | Promptfoo |
| Python team that wants pytest-style evals | DeepEval, or Inspect for agent and sandbox work |
| Agents that run code or tools in sandboxes | Inspect |
| Traces, human annotation, and datasets in one place | Langfuse, LangSmith, Phoenix, or Braintrust |
| Testing a Claude Code plugin or skill | `claude plugin eval` |
| Data must stay on your infrastructure | Self-hosted Langfuse or Phoenix, Inspect, Promptfoo |

Selection checks that matter more than the feature list:

1. Can you export datasets, traces, and labels in an open format?
2. Can graders be plain code, so you are not locked into a hosted judge?
3. Does it run headless in CI and return a nonzero exit code on failure?
4. Can it pin the model and prompt versions it used for each result?
5. Where does production data go, and does that match your privacy rules?

## What every setup needs

Whatever the tool, make these true:

- Datasets are versioned files or tables, with an id per case.
- Each case keeps its source (production trace id, hand-written, synthetic) and the failure it covers.
- Graders are code or validated judges with recorded TPR and TNR.
- Every run stores the app version, prompt version, model id, judge model id, dataset version, and the full transcripts.
- Results are comparable over time. Pin versions so a score change has one cause.

## Claude Code plugin evals

`claude plugin eval` tests a Claude Code plugin by running realistic prompts with and without the plugin and grading the results. It needs Claude Code v2.1.269 or later. Runs call the model, so they use plan usage or API budget.

| Item | Detail |
|---|---|
| Suite layout | `evals/<case>/prompt.md` with the prompt and limits (`max_turns`, `allowed_tools`, `timeout_seconds`), and `evals/<case>/graders/*.md`, one file per grader. Optional `case.yaml` for fixtures |
| Grader types | `regex`, `tool_used`, `tool_order`, `file_exists` (computed, free), `llm` and `baseline` (judge model). No custom code graders |
| Runs | Three runs per case by default. A case passes when its score meets `--threshold` (default 1.0) |
| Baseline | Each case also runs with no plugin. `Δ` is the plugin's contribution. Graders that can only pass with the plugin (such as "skill was invoked") are shown but not scored in both arms |
| Isolation | Each run starts in a fresh, isolated non-interactive session in an empty working directory |
| Starting a suite | `claude plugin eval init` proposes cases and graders. `claude plugin eval init --bare <case>` writes a blank case |
| Running | `claude plugin eval .`, with `--case`, `--runs`, `--ablation none`, `--json`, `--judge-model`, `--model`, `--max-cost-usd`, `--no-publish`, `--trust-plugin` |
| Exit code | 1 if any case scores below the threshold or a run fails to start. The delta never changes the exit code |

Habits that keep scores stable, from the same docs:

- Grade long outputs such as generated files with `regex` over the file, and keep `llm` graders for short text with concrete PASS and FAIL conditions.
- Give each case one grader on the result and one on the steps taken (`tool_used` or `tool_order`).
- If a case shows the skill fired but `Δ` is negative, suspect the judge first. Try a stronger `--judge-model` and tighten the rubric.

The skill-creator plugin has a separate `evals/evals.json` format for iterating on one skill in a conversation. The two tools do not read each other's case files.

## Migrating off the OpenAI Evals platform

OpenAI announced on 2026-06-03 that the Evals platform is deprecated. Existing evals become read-only on 2026-10-31. The dashboard and API shut down on 2026-11-30. The deprecations page points to a cookbook guide, "Moving from OpenAI Evals to Promptfoo".

Steps:

1. Export datasets, grader definitions, and historical results through the API before the shutdown, since export depends on the API.
2. Recreate the graders in your new tool. Prefer code graders where you can.
3. Re-run the new graders on the exported data and compare with the old scores. Recreated graders can produce different numbers, so reset your baseline instead of reusing the old thresholds.
4. Re-validate any judge against human labels, see [judge-calibration](judge-calibration.md).

## CI pattern

1. Fast suite on every pull request: code assertions and a few validated judges, pinned model ids, a cost ceiling.
2. Store the result as a build artifact (JSON) and the transcripts for failures.
3. Fail the build when a case or metric falls below its threshold.
4. Run the larger suite on a schedule or before release.
5. Never let the CI job wait for an interactive prompt, such as a trust or login step. Pass the non-interactive flags your tool provides.

## Sources

- OpenAI deprecations page, Evals platform entry: https://developers.openai.com/api/docs/deprecations
- OpenAI announcement of the Promptfoo acquisition (2026-03-09): https://openai.com/index/openai-to-acquire-promptfoo/
- Promptfoo repository: https://github.com/promptfoo/promptfoo
- ClickHouse on acquiring Langfuse (2026-01-16): https://clickhouse.com/blog/clickhouse-acquires-langfuse-open-source-llm-observability
- Inspect: https://inspect.aisi.org.uk/
- DeepEval: https://github.com/confident-ai/deepeval
- Phoenix: https://github.com/Arize-ai/phoenix
- Claude Code plugin evals: https://code.claude.com/docs/en/plugin-evals

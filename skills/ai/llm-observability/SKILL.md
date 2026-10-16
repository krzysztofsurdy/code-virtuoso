---
name: llm-observability
description: Instrument LLM apps and agents with OpenTelemetry GenAI traces, token and cost attribution, sampling, and PII-safe capture. Use when adding tracing, debugging agent runs, or cutting LLM cost and latency.
user-invocable: false
---

# LLM observability

An LLM app fails in ways that logs and error rates do not show. The request returns 200, the answer is wrong, the agent looped nine times, and the bill doubled. To see these you need a trace of every model call and tool call, token counts on each, and a way to connect the trace to quality checks. This skill covers how to record that data, what to measure, and what to keep out of it.

## Core Principles

| Principle | Meaning |
|---|---|
| **Trace the whole run** | One trace per user request or agent run, with a span per model call and per tool call. A flat log of prompts cannot show where a run went wrong. |
| **Concepts over attribute names** | The OpenTelemetry GenAI conventions are still in Development status and names change. Learn the shape, then take exact names from the current spec. |
| **Tokens are the source of truth for cost** | Record input, output, cached, and reasoning tokens on every call. Compute money later from a versioned price table. |
| **Measure before optimizing** | Cache hit ratio, time to first token, and step count are numbers you read from traces. Do not tune on a guess. |
| **Content is opt-in** | Prompts and completions hold user data. Capture them only on purpose, with redaction, retention, and access rules. |
| **Keep the interesting traces** | Sample so that errors, slow runs, costly runs, and bad-feedback runs are always kept. |
| **Close the loop** | Production traces feed error analysis and the eval datasets. See `llm-evals`. |

## What a trace looks like

```text
invoke_agent support-bot                     (one user request)
  chat model-x                               (model call 1: plans, picks a tool)
  execute_tool search_orders                 (tool call)
  chat model-x                               (model call 2: reads result)
  execute_tool issue_refund                  (tool call)
  chat model-x                               (model call 3: final answer)
```

Span types to emit:

| Span | Covers | Key data |
|---|---|---|
| Workflow or agent run | One request through one agent or pipeline | Agent name, conversation id, step count, stop reason, total tokens |
| Model call | One request to a model | Provider, requested and actual model, token counts (input, output, cached read and write, reasoning), finish reason, parameters, error type |
| Tool call | One tool execution | Tool name, call id, duration, error. Arguments and results are content, so opt-in |
| Retrieval, embedding, guardrail | Supporting steps | Duration, counts, index or model used |

Parent-child links matter. A tool span nested under the agent span lets you see which step was slow or failed. Put the application's own fields on the run span: feature name, prompt version, release version, a hashed user or tenant id, experiment arm.

Details on the OpenTelemetry conventions and the metrics they define: [otel-genai](references/otel-genai.md).

## Standards status

- The OpenTelemetry GenAI semantic conventions have **Development** status. They are not stable. Operation names, attribute names, and metric names have changed and can change again.
- They now live in the `open-telemetry/semantic-conventions-genai` repository. The older pages on opentelemetry.io say they moved.
- Pin your instrumentation library version. Read its changelog before upgrading. Isolate GenAI attribute names in one module or collector config so a rename is a one-place change.
- Your backend may map several conventions (GenAI, OpenInference, vendor-specific). Check that token and cost fields land where you expect after you send a test trace.

## What to measure

| Question | Measure | From |
|---|---|---|
| How much does a feature cost? | Tokens by type, times the price table, grouped by feature and prompt version | Model call spans |
| Is caching working? | Cache hit ratio, cache write share | Cached token counts |
| Is it slow for the user? | Time to first token, total duration, p50 and p95 | Streaming timestamps, span duration |
| Is an agent wandering? | Steps per run, tool calls per run, repeated identical tool calls, stop reason | Agent span and children |
| Which tool is the problem? | Tool duration and error rate per tool | Tool spans |
| Did a change hurt quality? | Eval scores and user feedback per prompt version | Scores attached to traces |
| Are we hitting limits? | Rate-limit errors, retries, queue time | Error type, retry count |

Use percentiles for latency and per-run totals for cost. A mean hides the 5 percent of runs that loop and cost ten times the average. Details: [cost-and-latency](references/cost-and-latency.md).

## Cost and latency levers

Prompt caching and batching are the two big levers. Both are measurable from traces.

| Lever | When it helps | How to measure |
|---|---|---|
| Prompt caching | Large stable prefix (system prompt, tool definitions, documents) reused across requests | Cache hit ratio: cached read tokens divided by all input tokens, per prompt version |
| Batch API | Work that can wait: evals, backfills, bulk classification | Share of tokens sent by batch, turnaround time, expiry and failure rate |
| Smaller model for easy steps | Routing, extraction, classification | Cost and eval score per step, before and after |
| Shorter context | Long histories and big tool results | Input tokens per call over a run |
| Fewer steps | Agents that retry or re-read | Steps per run |

Provider price multipliers and rules differ by model and change over time. Read the current provider docs for the model in use, see [cost-and-latency](references/cost-and-latency.md).

## Sampling

Head sampling decides when the trace starts and cannot know whether the run will fail or be slow. Tail sampling decides after the trace is complete. For LLM apps use tail sampling in a collector: keep every trace with an error, high latency, high cost, a human flag, or negative feedback, and a random slice of the rest as a baseline. Compute rates and cost totals from metrics that see all traffic, so sampling does not skew them. See [privacy-and-sampling](references/privacy-and-sampling.md).

## Privacy

- Message content, system prompts, tool arguments, and tool results are sensitive. The conventions mark message content as opt-in. Leave it off by default and turn it on per environment.
- Redact before data leaves your process or at a collector you control: emails, phone numbers, names, account numbers, secrets, tokens.
- Hash user identifiers. Never use a raw email as a trace attribute.
- Set retention shorter for content than for metadata. Restrict who can open traces.
- Remember the backend is a data processor. Pick its region and contract to match your data rules.

Full checklist in [privacy-and-sampling](references/privacy-and-sampling.md). For wider security concerns, use `security`.

## Backends

Most LLM observability tools accept OTLP, so you can instrument once and choose a backend later, or send to two through a collector.

| Backend | OTLP support |
|---|---|
| Langfuse | OTLP over HTTP, JSON or protobuf. No gRPC. Basic auth with project keys |
| LangSmith | OTLP endpoint. API key in headers. Maps GenAI conventions and several vendor formats |
| Phoenix | OTLP. Built around OpenInference instrumentation. Self-hostable |
| Braintrust | OTLP over HTTP with bearer auth and a project header |

Endpoints, headers, and regions change. Copy them from each vendor's current docs. Details and the eval loop: [backends-and-eval-loop](references/backends-and-eval-loop.md).

## Linking traces to evals

1. Give every production trace a stable id and a release and prompt version.
2. Sample traces for human review and add confirmed failures to the regression dataset, with the trace id as the source.
3. Run the eval suite with the same instrumentation, tagged as an eval run with a case id, so offline and production data share one shape.
4. Attach scores (human labels, judge verdicts, user feedback) to traces and filter by them.
5. Compare prompt versions on the same metrics: cost, latency, steps, score.

## Quality checklist

- [ ] One trace per request, a span per model call and tool call, parent links correct
- [ ] Input, output, cached, and reasoning tokens recorded on each model call
- [ ] Cost computed from a versioned price table, grouped by feature and prompt version
- [ ] Time to first token and total latency tracked as percentiles
- [ ] Agent runs record step count, tool call count, and stop reason, with a step limit
- [ ] Message content capture is off by default, redaction runs before export
- [ ] User ids hashed, retention and access rules written down
- [ ] Tail sampling keeps errors, slow, costly, and flagged traces
- [ ] GenAI attribute names confined to one place, instrumentation version pinned
- [ ] Test trace sent to the backend and the token and cost fields checked
- [ ] Production traces feed the eval dataset on a schedule

## Reference Files

| Reference | Contents |
|---|---|
| [otel-genai](references/otel-genai.md) | The GenAI convention model: operations, span hierarchy, attributes by concept, metrics, status and how to cope with change |
| [cost-and-latency](references/cost-and-latency.md) | Cost attribution, price tables, caching and batching measurement, latency and agent-loop metrics |
| [privacy-and-sampling](references/privacy-and-sampling.md) | Content capture, redaction, retention, head and tail sampling for LLM traces |
| [backends-and-eval-loop](references/backends-and-eval-loop.md) | OTLP backends, collector setup, mapping checks, connecting traces to eval datasets |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Reading traces to find failures and build graders | `llm-evals` |
| General latency and bottleneck diagnosis | `performance` |
| Designing the agent being traced | `agent-design` |
| Treating PII, secrets, and access control | `security`, `agent-security` |
| Instrumenting a Vercel AI SDK or LangChain app | `vercel-ai-sdk`, `langchain-components` |
| A slow or looping agent run to diagnose | `debugging` |
| Tracing and alerting in a delivery pipeline | `cicd` |
| Confirming instrumentation works before shipping | `verification-before-completion` |

## Contents

- [Status and where to read the spec](#status-and-where-to-read-the-spec)
- [Operations](#operations)
- [Span hierarchy](#span-hierarchy)
- [Attributes by concept](#attributes-by-concept)
- [Metrics](#metrics)
- [Content is opt-in](#content-is-opt-in)
- [Coping with change](#coping-with-change)
- [Sources](#sources)

# OpenTelemetry GenAI conventions

OpenTelemetry defines semantic conventions for generative AI: how to name spans, what attributes to set, and which metrics to emit. Using them makes traces portable across backends and instrumentation libraries. The sections below teach the model. The names given are a snapshot from 2026-10-21 and are examples, not a frozen contract.

## Status and where to read the spec

- Status of the GenAI conventions is **Development**. Every attribute and metric in the current pages carries that badge.
- The conventions moved to the `open-telemetry/semantic-conventions-genai` repository. The GenAI pages on opentelemetry.io now say they moved and are no longer maintained.
- The repo covers spans, metrics, and events for GenAI clients, agents, MCP, and provider-specific pages (Anthropic, AWS Bedrock, Azure AI Inference, OpenAI).
- Read the spec in `docs/gen-ai/` of that repo for current names before you hard-code anything.

## Operations

Every GenAI span carries an operation name that says what kind of work it is. Well-known values at the time of writing:

| Group | Values |
|---|---|
| Model calls | `chat`, `text_completion`, `generate_content`, `embeddings`, `fetch_response` |
| Agents and workflows | `create_agent`, `invoke_agent`, `invoke_workflow`, `plan` |
| Tools and retrieval | `execute_tool`, `retrieval` |
| Memory | `create_memory`, `update_memory`, `upsert_memory`, `search_memory`, `delete_memory`, plus store create and delete |

If one of the listed values applies, use it. Otherwise a custom value is allowed. Span names follow a pattern such as `invoke_agent {agent name}` or `execute_tool {tool name}`.

## Span hierarchy

| Span | Meaning | Kind per spec |
|---|---|---|
| `invoke_workflow` | A multi-step workflow or pipeline run | Internal |
| `invoke_agent` | One agent run. Client kind for a remote or hosted agent, internal kind for an in-process agent | Client or internal |
| `plan` | Planning or task decomposition step | Internal |
| `chat` and similar | One model request | Client |
| `execute_tool` | One tool execution | Internal |
| `create_agent` | Creating a hosted agent | Client |

A typical agent run is `invoke_agent` with `chat` and `execute_tool` children, repeated per step. If your agent framework emits its own spans, map them to these operations rather than inventing parallel names.

## Attributes by concept

Think in concepts. Look up the current attribute name for each in the spec.

| Concept | What to record | Note |
|---|---|---|
| Operation | Which operation this span is | Required |
| Provider | Which provider served the call | Stable string such as the provider name |
| Model | Requested model and the model that actually answered | They can differ. Record both |
| Request parameters | Max tokens, temperature, top-p, seed, stop sequences | Needed to reproduce and compare |
| Response | Response id, finish reasons | Finish reason distinguishes "done" from "cut off" |
| Usage | Input tokens, output tokens, and subsets: cache read, cache write, reasoning | See the note on token semantics below |
| Agent | Agent name, id, version, description | Names group runs in dashboards |
| Conversation | Conversation or session id | Joins turns of one conversation |
| Tool | Tool name, type, description, call id | Call id links a request to its result |
| Retrieval | Query, top-k, documents | Query and documents are content |
| Error | Error type on the span, span status set per the OTel error guidance | Use a low-cardinality type string |

**Token semantics.** The token metrics in the current spec treat cache read, cache write, and reasoning as **subsets** of the input and output totals. Provider usage objects do not always agree. For example, one provider reports uncached input separately from cache reads and writes, so total input is the sum of the three. Another reports cached tokens inside a detail object while the input total already includes them. Normalize in one place, write down your rule, and check it against a known request.

Add your own attributes under a namespace you control, not under `gen_ai.`:

| Application attribute | Use |
|---|---|
| Feature or product area | Cost and quality by feature |
| Prompt version or hash | Compare versions |
| Release version | Tie a regression to a deploy |
| Hashed user or tenant id | Per-tenant cost, no raw ids |
| Experiment arm | A/B comparisons |
| Eval run id and case id | Mark offline eval traffic, see [backends-and-eval-loop](backends-and-eval-loop.md) |

Keep attribute values low-cardinality on metrics (feature, model, operation). High-cardinality values such as user ids belong on spans, not metric labels.

## Metrics

Metric families in the current spec, as a guide to what is worth recording:

| Family | Examples of what it measures |
|---|---|
| Client operation duration | End-to-end duration of a model call as seen by the caller |
| Server-side timing | Request duration, time to first token, time per output token after the first |
| Token counters | Input and output tokens, with cache read, cache write, and reasoning as subsets |
| Per-operation token histograms | Distribution of tokens per call. For percentiles and outliers, not for totals or cost |
| Workflow and agent | Duration of a workflow or agent run, number of inference calls per agent run, number of tool calls per agent run |
| Tool | Duration of tool execution |

Notes:

- Use token counters for totals and cost. Use the per-operation histograms only to see outliers, as the spec itself says.
- Agent-level counts (inference calls and tool calls per run) are the quickest way to spot loops.
- Time to first token only exists for streaming responses. Record it where you control the client.

## Content is opt-in

Prompts, completions, system instructions, tool definitions, tool arguments, and tool results are all marked as opt-in in the spec, and several carry a warning that they likely contain sensitive or personal data. Instrumentations should not capture them by default. The spec gives an example environment variable for opting in to message content capture in instrumentation libraries. Check your library for its switch. Treat the switch as a data-protection decision. See [privacy-and-sampling](privacy-and-sampling.md).

## Coping with change

Because the status is Development:

1. Pin instrumentation packages. Upgrade on purpose and read the changelog.
2. Keep GenAI names in one place: a small mapping module in the app, or a collector transform. Dashboards and alerts should use your mapped names.
3. After each upgrade, send a test trace and diff the attributes against the last known good one.
4. Prefer dual emission, if your library offers it, during a rename period.
5. Do not build billing on attribute names that can change. Build it on token counts you normalize yourself.

## Sources

- GenAI semantic conventions repository: https://github.com/open-telemetry/semantic-conventions-genai (docs/gen-ai/: README, spans, agent spans, metrics, token metrics)
- Older location, now a notice that the pages moved: https://opentelemetry.io/docs/specs/semconv/gen-ai/

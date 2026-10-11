## Contents

- [Cost attribution](#cost-attribution)
- [Price tables](#price-tables)
- [Prompt caching](#prompt-caching)
- [Batching](#batching)
- [Other cost levers](#other-cost-levers)
- [Latency](#latency)
- [Agent loop metrics](#agent-loop-metrics)
- [Alerts](#alerts)
- [Sources](#sources)

# Cost and latency

Cost and latency in LLM apps come from a few numbers on each model call: tokens by type, time to first token, and total duration. Record them, then roll them up by run, feature, and prompt version.

## Cost attribution

Record tokens on each model call span, not money. Compute money in the pipeline or backend, so a price change does not require re-instrumenting.

```text
call_cost = uncached_input  * price_input
          + cache_write     * price_cache_write
          + cache_read      * price_cache_read
          + output          * price_output        # reasoning tokens usually bill as output
          then multiplied by the batch discount, if the call went through a batch API
```

Roll up:

| Group by | Answers |
|---|---|
| Run (trace) | What does one agent run cost? Cost per successful task is the number to watch |
| Feature | Which product area drives spend? |
| Prompt version and release | Did a change raise cost? |
| Model | Is the expensive model used where a cheap one would do? |
| Tenant (hashed) | Who drives spend? Needed for quotas and pricing |
| Step type | Is planning, retrieval, or the final answer the costly part? |

Rules:

- Cost per run includes every retry, every tool-loop step, and any judge calls you make in the path. Sum across the whole trace.
- Use cost per **successful** outcome, not per request. A cheap agent that fails half the time is not cheap. Join cost with the success signal from evals or feedback.
- Failed and retried calls still bill. Count them and report the retry share.
- Mind subset semantics: if cache tokens are already inside the input total, subtract them before applying the uncached price, or you bill them twice. See [otel-genai](otel-genai.md#attributes-by-concept).

## Price tables

Prices change, and differ by model, tier, region, and context length.

- Keep a price table as data (model id, token type, price, effective date) under version control or in the backend, not in code constants.
- Store the price table version used with each cost report. Historic numbers must be reproducible.
- Take prices from the provider's pricing page, not from memory or blog posts.
- Some backends compute cost from token usage and a model definition. Check that their table matches yours, and that custom or fine-tuned models are defined.
- Unknown model id means unknown cost. Alert on spans whose model has no price rather than counting them as zero.

## Prompt caching

Providers can reuse the processed form of a repeated prompt prefix at a lower price and lower latency. Two shapes exist: explicit (you mark breakpoints) and automatic (the provider detects the prefix). Rules and multipliers differ by provider and model, so read the current docs for the model you use.

Facts from Anthropic's docs as of 2026-10-21, as one concrete example:

| Item | Detail |
|---|---|
| Prefix order | Tools, then system, then messages. A change at one level invalidates it and everything after it |
| Prices | Cache write 1.25x base input price for a 5-minute lifetime, 2x for 1 hour. Cache read from 0.1x down to 0.025x depending on model |
| Usage fields | Cache creation tokens, cache read tokens, and input tokens after the last breakpoint, reported separately. Total input is the sum of the three |
| Minimum prefix | Varies by model, from 512 to 4,096 tokens. Below it, nothing is cached and no error is returned |
| Breakpoints | Up to 4 explicit |
| Invalidators | Changing tool definitions, `tool_choice`, adding or removing images, and some thinking or effort settings |

OpenAI's automatic caching, also as of 2026-10-21: enabled by default on supported models, with a minimum prefix length, a cached-input discount that depends on model, cached tokens reported in a usage detail field, and an optional cache key to improve routing and per-customer accounting.

**Measure it.** Compute per prompt version and feature:

```text
cache_hit_ratio = cache_read_tokens / (cache_read_tokens + cache_write_tokens + uncached_input_tokens)
```

| Symptom | Likely cause | Fix |
|---|---|---|
| Hit ratio near zero | Prefix below the minimum length, or the volatile part sits at the front | Move stable content first. Check minimum length for the model |
| Hits drop after a deploy | Tool definitions, order, or system text changed | Keep tool lists deterministic and stable. Diff the prefix between versions |
| Many writes, few reads | Requests are too far apart for the cache lifetime | Longer-lived cache option if offered, or batch related requests closer together |
| Hits drop for some users only | Per-user data placed in the shared prefix | Put user data after the breakpoint |
| Hit ratio fine but cost still high | Output tokens or uncached tail dominate | Look at output length and the tail |

Break-even example with Anthropic's standard multipliers (read 0.1x, 5-minute write 1.25x): one write plus one read costs 1.35 units against 2.0 for two uncached requests. Caching pays off from the second request inside the lifetime. A prefix that is never reused costs 25 percent more with caching than without. Check that your traffic reuses the prefix before you turn it on.

Caching also lowers time to first token on long prompts. Compare TTFT for cache hits and misses in your own traces.

## Batching

A batch API takes many requests, runs them asynchronously, and returns results later at a discount. Anthropic's Message Batches API lists a 50 percent cost reduction, with most batches finishing in under an hour. Its docs say the cache multipliers stack with the batch discount.

| Good fit | Poor fit |
|---|---|
| Offline evals and regression runs | A user waiting for the answer |
| Backfills, bulk classification, enrichment | Interactive agents |
| Nightly summaries | Steps that need the result of the previous call |

**Measure it:**

| Metric | Why |
|---|---|
| Share of tokens sent through batch | How much eligible work actually uses the discount |
| Turnaround time p50 and p95 | Does it meet the deadline? |
| Failed, expired, or canceled request rate | Hidden retries add cost |
| Cost per item, batch vs synchronous | Confirms the saving |

Mark batch calls on the span so cost rollups apply the discount.

## Other cost levers

- **Model routing.** Send simple steps to a smaller model. Measure eval score and cost for each step before and after.
- **Context control.** Trim history, truncate large tool outputs, return only fields the agent needs. Track input tokens per call over a run: steady growth means history is not being managed.
- **Output limits.** Set max output tokens. Watch the finish reason for cut-off answers.
- **Step budgets.** Cap agent steps and total tokens per run. Record the stop reason.
- **Dedupe.** Cache identical deterministic calls in your own layer when answers can be reused.

Each lever should be justified by a before-and-after number from traces plus an eval check that quality held. See `llm-evals`.

## Latency

| Measure | Meaning | Where it matters |
|---|---|---|
| Time to first token | Delay before streaming starts | Chat and any streamed UI |
| Time per output token | Speed after the first token | Long answers |
| Model call duration | Whole request | Non-streaming calls |
| Tool duration | Time inside each tool | Agent runs |
| Queue and retry time | Waiting on rate limits, backoff | Peak load |
| Run duration | User request to final answer | End-to-end SLO |

Report p50, p95, and p99, split by model, feature, and whether the cache hit. Break a slow run down by span: in a typical slow agent run, one slow tool or many sequential steps explains most of the time. Parallelize independent tool calls and independent model calls where the framework allows it.

## Agent loop metrics

| Metric | Healthy sign | Warning sign |
|---|---|---|
| Steps per run | Stable distribution per task type | Long tail, step limit hits |
| Tool calls per run | Matches task complexity | Many repeated calls with identical arguments |
| Model calls per run | Stable | Growth after a prompt change |
| Stop reason | Mostly "finished" | Rising "step limit" or "error" |
| Tokens per run | Flat or falling | Rising with history length |
| Cost per successful run | Flat | Up with no gain in success |

Emit a span event or attribute when a run hits a limit, so you can find these runs fast.

## Alerts

Alert on rates and percentiles, not single events:

- Error and rate-limit rate per model and provider
- p95 time to first token and run duration over a threshold
- Cost per run or per day over a budget, per feature
- Step-limit hits per hour
- Cache hit ratio drop after a deploy
- Spans with a model that has no price entry

## Sources

- Anthropic prompt caching docs (pricing multipliers, usage fields, minimum lengths, invalidation): https://platform.claude.com/docs/en/build-with-claude/prompt-caching
- Anthropic Message Batches API docs: https://platform.claude.com/docs/en/build-with-claude/batch-processing
- OpenAI prompt caching guide: https://developers.openai.com/api/docs/guides/prompt-caching
- OpenTelemetry GenAI metrics and token metrics: https://github.com/open-telemetry/semantic-conventions-genai

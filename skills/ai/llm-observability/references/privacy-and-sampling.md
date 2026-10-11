## Contents

- [What is sensitive in an LLM trace](#what-is-sensitive-in-an-llm-trace)
- [Content capture policy](#content-capture-policy)
- [Redaction](#redaction)
- [Retention and access](#retention-and-access)
- [Sampling](#sampling)
- [Tail sampling rules for LLM apps](#tail-sampling-rules-for-llm-apps)
- [Keep rates correct under sampling](#keep-rates-correct-under-sampling)
- [Checklist](#checklist)
- [Sources](#sources)

# Privacy and sampling

A trace of an LLM run can hold the user's whole conversation, documents pulled from private systems, and the arguments and results of every tool call. That is the most useful data for debugging and the riskiest to store. Decide what you capture, strip what you must, and keep only as much as you need.

## What is sensitive in an LLM trace

| Data | Why it is sensitive |
|---|---|
| User messages and model replies | Free text. Users paste names, emails, health and financial details |
| System prompts | May hold business rules, internal URLs, or secrets put there by mistake |
| Tool arguments | Queries, ids, file paths, account numbers |
| Tool results and retrieved documents | Private records, customer data, internal documents |
| Tool definitions | Can reveal internal API shape |
| Identifiers | User, session, device, and tenant ids link traces to people |
| Error messages | Often echo input values |

## Content capture policy

The OpenTelemetry GenAI conventions mark messages, system instructions, tool definitions, tool arguments, and tool results as opt-in, with warnings that they likely hold personal data. Instrumentations should leave them off unless a user turns them on.

Follow the same default:

1. **Metadata always.** Operation, model, token counts, durations, finish reason, error type, tool names, ids that are hashed. This is enough for cost, latency, and loop analysis.
2. **Content by decision.** Turn on content capture per environment and per feature. Development and test: on. Production: on only where error analysis needs it, with the controls below.
3. **Document the decision.** Write down what is captured, why, who can see it, and how long it is kept.

A middle path for production: capture content for a small random sample and for runs flagged as errors, drop it for the rest. Tail sampling makes this possible, see below.

## Redaction

Redact before data leaves your trust boundary: in the SDK or in a collector you operate. Redacting in the backend is too late, because the data has already crossed.

| Method | Use for |
|---|---|
| Pattern rules (regex) | Emails, phone numbers, card and account numbers, API key formats, bearer tokens |
| Dictionary and entity detection | Names, addresses, organization names. Use a detector and accept imperfect recall |
| Field allowlists | For tool arguments and results, keep only fields known to be safe |
| Hashing | Stable ids you need for grouping. Use a keyed hash so ids cannot be reversed by guessing |
| Truncation | Cap content length to limit exposure and storage |

Rules:

- Redaction is lossy and imperfect. Test it on real samples and measure misses.
- Redact tool results by default. They are the largest leak source.
- Never place secrets in prompts or tool arguments to begin with. Scan for them in traces as a safety net and alert on a hit.
- Keep a raw, unredacted copy only if there is a clear need. Then give it shorter retention and tighter access.

## Retention and access

| Control | Practice |
|---|---|
| Retention | Short for content (days to weeks), longer for metadata and metrics. Delete on schedule |
| Access | Role-based. Few people can open content. Log who views it |
| Region | Choose the backend region that fits your data rules. Several backends offer EU, US, and other regions or self-hosting |
| Vendor terms | Know whether the backend trains on or shares data, and what its data processing terms say |
| Deletion | Be able to delete one user's traces on request. That needs a hashed user id on the trace |
| Datasets | A trace copied into an eval dataset carries its data with it. Redact before copying, and apply the same retention rules |

Ask your legal or privacy team about rules that apply to you. This skill does not give legal advice. For wider application security, use `security`.

## Sampling

At scale you cannot keep every trace. Sampling chooses which to keep.

| Type | When it decides | Strength | Weakness |
|---|---|---|---|
| Head sampling | At the start of the trace, often by trace id and a percentage | Simple and cheap | Cannot know whether the trace will fail, be slow, or be costly, so it can drop the ones you need |
| Tail sampling | After most or all spans of the trace arrived | Can keep traces by error, latency, cost, or attribute | Needs a stateful collector with memory and storage, more to operate |

The OpenTelemetry Collector has a tail sampling processor. Teams sometimes combine both: head sampling first to cut volume, then tail sampling to decide with full information.

## Tail sampling rules for LLM apps

LLM traces are valuable because failures hide in them. Sample on what you want to read later.

| Rule | Keep |
|---|---|
| Error | 100 percent of traces with an error status or a failed tool call |
| Slow | Traces over a latency threshold, or in the top percentile of time to first token |
| Costly | Traces over a cost or token threshold |
| Looping | Traces that hit a step limit or show repeated identical tool calls |
| Flagged | Traces with a negative user rating, an escalation, or a failed online judge |
| New release | Higher rate for traces from a freshly deployed prompt or model version |
| Baseline | A random slice of everything else, so you still see the normal distribution and unknown failures |

Keep a random baseline always. Without it you only see failures your rules describe, and error analysis loses its fair view of reality.

Decide on whole traces. A kept trace needs all of its spans, or the tree is useless.

## Keep rates correct under sampling

Dropping boring traces makes the stored set skewed toward failures. Do not compute global error rates, cost totals, or token totals from the sampled traces.

- Emit metrics (counters and histograms) from the application or a collector stage that sees all traffic, before sampling.
- Use stored traces to explain and inspect, metrics to count.
- If you must estimate from samples, record the sampling rate on each trace and weight by its inverse.

## Checklist

- [ ] List of sensitive fields per span type written down
- [ ] Content capture off by default, enabled per environment on purpose
- [ ] Redaction runs in the SDK or your collector, tested on real samples
- [ ] Tool arguments and results redacted by default
- [ ] User and tenant ids hashed with a keyed hash
- [ ] Content retention shorter than metadata retention
- [ ] Access to content restricted and logged
- [ ] Backend region and data terms checked
- [ ] Per-user deletion possible
- [ ] Tail sampling keeps errors, slow, costly, looping, and flagged traces, plus a random baseline
- [ ] Rates and totals come from unsampled metrics

## Sources

- OpenTelemetry GenAI conventions, opt-in content attributes and sensitivity notes: https://github.com/open-telemetry/semantic-conventions-genai
- OpenTelemetry sampling concepts (head and tail sampling, tail sampling processor): https://opentelemetry.io/docs/concepts/sampling/
- Hamel Husain and Shreya Shankar, AI Evals FAQ, on keeping random traces in every sample: https://hamel.dev/blog/posts/evals-faq/

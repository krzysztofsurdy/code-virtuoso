# Structured output, tool schemas, and agent evals

Code that consumes model output needs it in a fixed shape. Providers offer schema-constrained decoding for this, and it removes one class of failure (unparseable text) while leaving others. This file lists the limits, the failure modes, a validation loop that handles them, and how to evaluate the result.

## Contents

- [Two features, not one](#two-features-not-one)
- [Schema limits to design around](#schema-limits-to-design-around)
- [Failure modes](#failure-modes)
- [Validation loop](#validation-loop)
- [Schema design rules](#schema-design-rules)
- [Tool schema rules](#tool-schema-rules)
- [Evals for agents](#evals-for-agents)
- [Sources](#sources)

## Two features, not one

| Feature | What it constrains | Use for |
|---|---|---|
| Structured output (response schema) | The model's final answer | Extraction, classification, routing decisions, payloads for other systems |
| Strict tool use | Tool names and tool inputs | Making tool arguments always match the tool's schema |

They are separate and can be combined in one request. Skip both for free-text chat answers. Do not confuse either with the MCP `structuredContent` field, which is server-produced result data and unrelated to schema-constrained generation.

## Schema limits to design around

Constrained decoding compiles your schema into a grammar, so providers support a subset of JSON Schema. From the Anthropic docs (checked 2026-10-21):

| Supported | Not supported |
|---|---|
| Objects, arrays, strings, numbers, booleans, null | Recursive schemas |
| `enum` and `const` with scalar values | External `$ref` |
| `anyOf`, `allOf` (not with `$ref`), internal `$ref` and `$defs` | Numeric bounds (`minimum`, `maximum`, `multipleOf`) |
| `required`, `default`, a short list of string formats | String length bounds, `minItems` or `maxItems` beyond 0 or 1 |
| Basic regex patterns | Regex backreferences, lookaround, word boundaries |
| | `additionalProperties` other than `false` on objects |

Unsupported keywords return a 400 error. SDK helpers can move unsupported constraints into field descriptions and validate locally, but raw schemas sent straight to the API get no such rewrite. OpenAI's strict mode has the same shape: every object sets `additionalProperties: false` and lists every property in `required`, with optional fields expressed as a union with null. Both providers publish the full supported subset, so read the current page for your provider before designing a large schema.

Other limits:

- The first request with a new schema pays a compilation delay. Anthropic caches compiled grammars for 24 hours from last use, and a structural schema change (not a description change) invalidates the cache.
- There are per-request ceilings on strict tools and on optional and union-typed parameters. A schema that is too complex fails with an error instead of degrading.

## Failure modes

| Failure | What happens | Handle it by |
|---|---|---|
| Refusal | The reply ignores the schema and says no. It can arrive with a success status and be billed | Check the stop reason or content type before parsing. Show or log the refusal |
| Truncation | The token limit cuts the JSON off and it no longer parses | Check for a max-token stop reason and treat it as an error. Raise the limit or shrink the schema |
| Unsupported schema | The API rejects the request | Simplify. Move numeric and length rules into descriptions and validate in code |
| Enum drift | Casing or spelling shifts in an enum value, with no error | Compare case-insensitively. Avoid values that differ only by case |
| Valid but wrong | The JSON matches the schema and the content is false | Validate semantics: referential checks, ranges, cross-field rules, a lookup against truth |
| Reasoning in a field | Asking for step-by-step reasoning inside a property can trigger a refusal on some models | Ask for a short explanation instead |
| Partial objects while streaming | Partial JSON cannot be validated against the full schema | Render partial data as a preview only. Validate when the stream ends |

## Validation loop

```text
for attempt in 1..2:
    reply = model(prompt, schema)
    if reply.refused:            return Refused(reply.text)
    if reply.truncated:          raise TooLong
    data = parse(reply)          # parse error -> next attempt
    errors = validate(data)      # schema AND business rules
    if no errors:                return data
    prompt = prompt + "Your last answer failed: " + errors
raise InvalidOutput
```

Rules: retry once or twice, never in an open loop. Feed the exact validation error back, because the model can fix a named problem. Log failures with the raw reply, since they are the best source of new eval cases. Libraries wrap this loop. The Vercel AI SDK throws `NoObjectGeneratedError` with the raw text, cause, and usage attached. Pydantic AI validates against Pydantic models and retries.

## Schema design rules

- Keep schemas small. Every field is a chance to be wrong, and large schemas hit complexity limits.
- Put a description on every field. The model reads it as an instruction.
- Use enums for closed sets and a nullable field (or an explicit `unknown` value) for information that may be absent. Without that escape, the model invents a value to satisfy `required`.
- Do not rely on field order. Anthropic emits required properties before optional ones regardless of schema order. If the model must reason before it decides, use a first call for the reasoning and a second call for the constrained answer.
- Use `additionalProperties: false` on every object.
- Version schemas that other systems read. Add fields, do not rename them.

## Tool schema rules

Treat each tool definition like a prompt, since the model reads the name, description, and parameter descriptions to decide when and how to call it ([Anthropic](https://www.anthropic.com/engineering/writing-tools-for-agents)).

- Name parameters unambiguously (`user_id`, not `user`).
- Say in the description what the tool does, when to use it, when not to, and how it differs from neighboring tools.
- Enforce inputs with a strict schema and make mistakes hard to make (Anthropic's SWE-bench tools required absolute file paths, which removed relative-path errors).
- Return high-signal fields (names, types) instead of raw IDs and MIME types, and offer a concise and a detailed response mode.
- Paginate, filter, and truncate with sensible defaults, and say how to narrow the search when a result is cut.
- Return errors that say what to do next.
- Prefer a few tools that match whole workflows over thin wrappers for every endpoint.

The full set of rules for MCP servers is in `mcp-server-development`.

## Evals for agents

Without a task set you cannot say whether a change helped. Anthropic's terms ([source](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents)):

| Term | Meaning |
|---|---|
| Task | One test with inputs and success criteria |
| Trial | One attempt at a task. Run several, because outputs vary |
| Grader | Logic that scores a trial: code, a model, or a person |
| Transcript | The full record of a trial (outputs, tool calls, reasoning) |
| Outcome | The final state of the environment, such as whether a record exists in the database |

Practice:

1. Start with 20 to 50 tasks drawn from real failures. Early changes have large effects, so small sets can show them.
2. Grade the outcome, not the path. Checking an exact tool sequence penalizes valid approaches.
3. Use pass@k when one success is enough, and pass^k (all k trials succeed) when consistency matters. A 75% per-trial rate gives about 42% for pass^3.
4. Keep two suites: capability tasks that start with a low pass rate, and regression tasks that sit near 100% and run on every change. Graduate solved capability tasks into the regression suite.
5. Read transcripts. Repeated invalid-argument errors point at unclear tool descriptions. Many redundant calls point at missing pagination or filters.
6. For model graders, use binary pass or fail per failure mode, and check the grader against human labels before trusting it.

## Sources

- Anthropic, Structured outputs: https://platform.claude.com/docs/en/build-with-claude/structured-outputs
- OpenAI, Structured outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- Vercel AI SDK, generating structured data (`NoObjectGeneratedError`): https://github.com/vercel/ai/blob/ai@7.0.0/content/docs/03-ai-sdk-core/10-generating-structured-data.mdx
- Anthropic, Writing effective tools for agents: https://www.anthropic.com/engineering/writing-tools-for-agents
- Anthropic, Demystifying evals for AI agents: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

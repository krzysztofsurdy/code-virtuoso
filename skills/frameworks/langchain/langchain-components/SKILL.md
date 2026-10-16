---
name: langchain-components
description: Decision guide for building agents with LangChain, LangGraph, and Deep Agents in Python, covering framework choice, multi-agent patterns, checkpointers, middleware, and tool safety. Use when designing, building, or reviewing LangChain agents or RAG apps.
user-invocable: false
---

# LangChain components

The LangChain stack changes every week: model IDs, streaming and interrupt interfaces, and Deep Agents backends all moved within months. This skill therefore holds no API listings. It holds the decisions the docs do not make for you, and it points to the live docs for syntax. Fetch the current API before writing code that calls it.

## Core principles

| Principle | Meaning |
|---|---|
| **Fetch, do not recall** | Treat any remembered signature, model ID, or import path as stale until the docs confirm it |
| **Match the installed version** | Read versions from the lockfile first, then fetch docs for that line |
| **Smallest layer that fits** | Start at the highest-level tool that covers the need and drop down only when it cannot |
| **One agent first** | Add multi-agent structure only after a single agent with good tools and prompt fails |
| **State must be persisted to pause** | Interrupts, resume, and multi-turn memory all depend on a checkpointer |
| **Model output is untrusted input** | Tool arguments and retrieved text can be wrong or hostile |

## Version matrix

Checked on 2026-10-21 against PyPI and the official release policy.

| Package | Current | Python | Stability |
|---|---|---|---|
| `langchain` | 1.4.6 | 3.10+ | v1 semver: breaking changes only in 2.0 |
| `langgraph` | 1.2.16 | 3.10+ | v1 semver: breaking changes only in 2.0 |
| `deepagents` | 0.7.29 | 3.11+ | 0.x: no stability promise, pin it and read changelogs |

The v1 promise, from the official release policy: minor releases add features without breaking changes, deprecated features keep working through the whole 1.x series, and 1.0 is a long-term-support release that stays active until 2.0. Legacy LangChain 0.3 and LangGraph 0.4 are in maintenance until December 2026. Code written for those lines (`AgentExecutor`, `create_react_agent`, legacy chains) needs migration, not patching.

Read installed versions before anything else:

```bash
grep -A1 -E '^name = "(langchain|langgraph|deepagents|langchain-core)"' uv.lock poetry.lock 2>/dev/null
pip show langchain langgraph deepagents 2>/dev/null | grep -E '^(Name|Version)'
```

If the project is on a 0.x line of langchain or langgraph, say so before suggesting v1 code, and offer the migration guide in the docs.

## Fetch API details through docs-lookup

Use the `docs-lookup` skill for the fetch procedure (resolve the library, query with a full question, fall back to the vendor site). Library IDs for this stack:

| Need | Context7 library ID |
|---|---|
| LangChain, LangGraph, models, tools, middleware, streaming, integrations | `/websites/langchain_oss` |
| Deep Agents (backends, subagents, skills, sandboxes, HITL) | `/websites/langchain_oss_python_deepagents` |
| Class and function reference across all packages | `/websites/reference_langchain` |

Pass the installed version in the query ("langgraph 1.2 interrupts"). If `docs-lookup` or Context7 is unavailable, read docs.langchain.com/oss/python directly. Never copy a model ID from memory: look up the provider's current list, or read it from project config.

## Choose the layer

Three layers of one stack. They compose: a compiled LangGraph graph can be a Deep Agents subagent.

| Need | Use | Why |
|---|---|---|
| Long, multi-step task with planning, file scratch space, delegation, context compression | Deep Agents | The harness bundles these; rebuilding them costs weeks |
| A tool-calling agent you will shape yourself (custom prompt, tools, middleware) | `create_agent` | Light harness, full control, middleware for cross-cutting needs |
| Steps are known in advance, or you mix deterministic code with model calls, or you need custom routing and parallel fan-out | LangGraph `StateGraph` | Explicit control flow, per-node retries, inspectable state |
| Existing Python code that needs persistence or interrupts with few changes | LangGraph Functional API | Plain control flow, same runtime |

Workflow versus agent: if you can draw the steps before the run, build a workflow (graph). Let the model choose steps only when the path cannot be predicted. Workflows are cheaper, faster, and easier to test.

Graph design rules that hold across versions:

- Store raw data in state and format prompts inside nodes.
- Keep nodes small enough that one external failure maps to one node with its own retry policy.
- Match the error to the handler: transient errors get retry policies, model-recoverable errors go back into state for another loop, user-fixable errors use an interrupt, unexpected errors bubble up.
- Changing a graph with live checkpoints: adding or removing state keys is safe, renaming a key loses its saved value in existing threads, and renaming or removing an interrupted node breaks those threads.

## Choose a multi-agent pattern

Multi-agent design is context engineering: it decides what each agent sees. A single agent with the right tools often does the same job with fewer model calls.

| Pattern | Pick it when | Cost profile | Watch out for |
|---|---|---|---|
| Single agent with tools | A manageable tool list, one domain | Lowest | Tool-choice quality drops as the tool list grows |
| Subagents as tools | A supervisor delegates, work parallelizes, subagents carry large context the supervisor should not see | Stateless, results flow back through the supervisor, one extra hop per task | Users cannot talk to a subagent directly |
| Handoffs | The active agent or its tools change as the conversation progresses (support triage, staged workflows) | Stateful, fewest calls on repeat requests | Sequential only, so multi-domain queries are slow |
| Skills (on-demand prompts) | One agent, many specializations, no ordering constraints between them | Stateful, but loading many skills inflates tokens | Cap how many skills load at once |
| Router | Input classifies cleanly into domains and you want parallel dispatch plus a combined answer | Stateless per request, parallel via `Send` | Wrap in an agent if the conversation needs memory |
| Custom graph | None of the above, or you need deterministic steps between agent steps | You own it | More code to maintain |

Rules that prevent common bugs:

- A handoff tool that updates state must also return a `ToolMessage` with the matching `tool_call_id`. Without it the history is malformed and the next model call fails.
- Do not pass a subagent's full history back to its caller. Return a summary, so isolation actually saves context.
- Give subagents narrow tool lists and action-oriented descriptions. The description is what the supervisor routes on.
- Use a dispatch tool with an enum of agent names for small fixed sets. Use search or list tools for large or changing registries.
- Patterns mix. A supervisor can call a router as a tool, and a subagent can load skills.

## Persistence, interrupts, and human-in-the-loop

| Question | Answer |
|---|---|
| What needs a checkpointer? | Interrupts and resume, multi-turn memory in a thread, time travel, crash recovery |
| What needs a `thread_id`? | Every invoke on a checkpointed graph. Reuse the same ID to resume |
| Which checkpointer in production? | A database-backed one (Postgres or SQLite packages). `InMemorySaver` is for tests and local work |
| What does HITL middleware do? | Pauses before listed tool calls so a person can approve, edit arguments, or reject |

An interrupt without a checkpointer cannot resume, so treat the checkpointer as part of the HITL feature, not an add-on. Gate by risk: interrupt on destructive or external-effect tools (send, delete, pay, deploy), auto-approve reads.

Design for resume, because a resumed node restarts from its beginning:

- Put `interrupt()` first in the node, before side effects.
- Make anything that runs before it idempotent.
- Never wrap `interrupt()` in `try/except`, since it works by raising.
- Pass only JSON-serializable values through interrupts.
- When several interrupts are pending at once (parallel branches), resume values are mapped by interrupt ID, not as one flat payload. Single tool-approval pauses use the decisions list in action order.

How an interrupt reaches your code depends on how you call the graph. The result of `invoke`, the `updates` stream, and `stream_events(version="v3")` expose it differently, and the v3 event stream replaced key checks with `stream.interrupted` and `stream.interrupts`. Look up the interface for your installed version and call style before writing the loop.

## Middleware

Middleware handles cross-cutting concerns (summarization, PII redaction, retries, limits, HITL) without touching agent logic. Use a built-in before writing your own, and keep each one to a single concern.

Order is by list position, and it matters:

- `before_*` hooks run first to last.
- `wrap_*` hooks nest: the first in the list is outermost and wraps all the others.
- `after_*` hooks run last to first.

Consequences: a retry wrapper listed first re-runs everything inside it, including other wrappers. A guard that must see the raw request (PII redaction, input limits) belongs early so everything later works on cleaned data. Anything that must observe the final result belongs outermost. When behavior surprises you, print the order before blaming the model. Declare `can_jump_to` on any hook that changes control flow so the intent is explicit.

## Structured output

Use it when code, not a person, consumes the result: extraction, classification, routing decisions, and payloads for other systems. Skip it for free-text chat answers.

| Situation | Use |
|---|---|
| One model call, no tools | `model.with_structured_output(Schema)` |
| An agent that must end with a typed answer | `response_format=` on `create_agent`; the result lands in `structured_response` |
| Model has native structured output | Let the framework pick, or choose `ProviderStrategy` explicitly (fewest failure modes) |
| Model lacks native support | `ToolStrategy`, which enforces the schema through a tool call |

Treat schema validation errors as normal runtime events and handle them. Keep schemas small and put field descriptions on them, since the model reads those.

## Memory

| Kind | Mechanism | Scope | Use for |
|---|---|---|---|
| Short-term | Checkpointer plus `thread_id` | One thread | Conversation history and in-flight state |
| Long-term | Store with namespaces | Across threads | Preferences, facts, learned notes |

- Namespace long-term memory by user ID so memories never leak across users.
- Long threads overflow the context window. Prefer summarization middleware over silent truncation, and use trimming in `before_model` hooks when you only need recent turns.
- When deleting or trimming messages, keep the history valid: a tool result must follow its tool call, and some providers require a user message first.
- For Deep Agents, files are thread-scoped by default. Keep the default backend thread-scoped so internal artifacts stay ephemeral, and route only a path such as `/memories/` to a store-backed backend for cross-thread memory. Backends that touch the host disk are for local development, not deployed agents.
- In Deep Agents, use skills for large task-specific context loaded on demand, and memory files for conventions that always apply.

## Retrieval

Use an agentic retriever (retrieval as a tool) when the model should decide whether to search and may search more than once. Use a fixed two-step chain (retrieve, then generate) when every query needs context and you want predictable cost and latency. Chunking, embeddings, and vector store choices are integration details: look them up for the store you use, and test retrieval quality separately from generation quality.

## Testing

| Layer | Approach |
|---|---|
| Unit | Replace the model with a fake that returns scripted messages, so tests are fast, free, and deterministic. Check the docs for how the fake handles tool binding |
| State | A fresh in-memory checkpointer per test, same `thread_id` across turns, to test multi-turn behavior and resume |
| Integration | Real model, assert on the trajectory (which tools, in which order) with a loose match for flexible flows and a strict match for critical paths |
| CI cost | Record and replay HTTP calls, and mask API keys in the recordings |
| Production | Turn on tracing in every environment and tag traces with environment and version |

Agent behavior is mostly integration behavior, so do not stop at mocked unit tests. Test middleware alone before stacking it.

## Tool safety

- Never `eval`, `exec`, or shell out with a string the model wrote. For math or filters, parse into a restricted grammar and allow only the node types you need. For real code execution, use a sandbox.
- Validate tool arguments with typed schemas and check authorization inside the tool. The model is not an authorization layer.
- Give each agent only the tools it needs. A smaller tool list is also safer and routes better.
- Treat tool results and retrieved documents as untrusted. They can carry prompt injection, so do not let them grant permissions or trigger destructive calls without a gate.
- Put human approval in front of destructive or external-effect tools.
- Keep secrets out of prompts, state, traces, and sandboxes. Pass them through runtime context to tool code that needs them.
- Return tool errors to the model as messages so it can recover, and log the detail separately.
- Use snake_case tool names and clear docstrings. The docstring is the description the model reads.

## Official framework skills

The LangChain team maintains agent skills for LangChain, LangGraph, and Deep Agents: https://github.com/langchain-ai/langchain-skills (MIT licensed, marked early development). Install with `npx skills add langchain-ai/langchain-skills --skill '*' --yes`, or as a Claude Code plugin with `/plugin marketplace add langchain-ai/langchain-skills`. For trace and dataset workflows the same team publishes https://github.com/langchain-ai/langsmith-skills. Use them alongside this guide when you want framework-maintained, task-level instructions.

## Quick reference: checklist

- [ ] Read installed versions from the lockfile
- [ ] Fetch current docs for those versions through `docs-lookup` before writing API calls
- [ ] Pick the layer: Deep Agents, `create_agent`, or LangGraph
- [ ] Start with one agent, and justify any multi-agent pattern against the table
- [ ] Add a durable checkpointer and `thread_id` handling if anything pauses or remembers
- [ ] Gate destructive tools with human approval, and make pre-interrupt code idempotent
- [ ] Review middleware order by reading the list top to bottom
- [ ] Use structured output only where code consumes the result
- [ ] Namespace long-term memory per user
- [ ] Test with fake models, a checkpointer, and at least one real-model trajectory test
- [ ] Confirm no model-written string reaches `eval`, `exec`, or a shell

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Fetching current library docs | `docs-lookup` |
| Designing the surrounding service or API | `api-design` |
| Test strategy beyond agents | `testing` |
| Designing the agent, caps, memory, multi-agent | `agent-design` |
| Building the MCP server the agent calls | `mcp-server-development` |
| Reviewing agent code for injection and secrets | `agent-security` |
| Evals and regression tests for the agent | `llm-evals` |
| Traces, token cost, and latency | `llm-observability` |
| The TypeScript equivalent | `vercel-ai-sdk` |
| Debugging a failing agent run | `debugging` |
| Tuning latency and token cost | `performance` |

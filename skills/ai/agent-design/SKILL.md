---
name: agent-design
description: Framework-agnostic guide to designing LLM agents and workflows. Covers workflow versus agent, loop and cost caps, tool permissions, approval, memory, and multi-agent trade-offs. Use before picking a framework or when reviewing an agent design.
user-invocable: false
---

# Agent design

An LLM agent is a loop: the model picks a tool, the harness runs it, the result goes back into context, and the loop repeats until a stop condition fires. Most of the quality, cost, and safety of the system comes from the harness around that loop, not from the prompt. This skill holds the design decisions that hold across frameworks and model vendors. Library syntax changes monthly, so fetch it through `docs-lookup` instead of recalling it.

## Core principles

| Principle | Meaning |
|---|---|
| **Simplest thing that works** | A single model call with good context beats a loop. A loop beats multi-agent. Add structure only when a measured failure demands it |
| **Workflow before agent** | If you can draw the steps before the run, write them as code. Let the model choose steps only when the path cannot be predicted |
| **The harness is the product** | Stop conditions, caps, permissions, and recovery decide whether the agent is safe to run unattended |
| **Context is a budget** | Reliability falls as context grows. Curate what the model sees at each step |
| **Output is untrusted input** | Tool arguments, structured output, and retrieved text can be wrong or hostile. Validate and authorize in code |
| **Evals before architecture changes** | Without a task set, you cannot tell whether a pattern, model, or framework helped |

## Workflow or agent

Anthropic's definitions: a workflow runs LLMs and tools through predefined code paths, and an agent lets the LLM direct its own process and tool use ([Building effective agents](https://www.anthropic.com/engineering/building-effective-agents)).

| Question | Workflow | Agent |
|---|---|---|
| Can you list the steps in advance? | Yes | No, the number of steps depends on what the tools return |
| Cost and latency | Predictable, lower | Variable, higher, with compounding-error risk |
| Testing | Test each step, then the chain | Test trajectories and outcomes, many trials per task |
| Failure mode | A step fails in a known place | The model wanders, loops, or stops early |
| Typical fit | Extraction, classification, report generation, support triage | Coding, open-ended research, multi-system operations |

Most production systems are a workflow with one or two agentic steps inside. Start there.

## The five workflow patterns

| Pattern | What it does | Pick it when | Watch out for |
|---|---|---|---|
| **Prompt chaining** | Fixed sequence, each call reads the previous output, code checks between steps | The task splits cleanly into fixed subtasks and you accept more latency for accuracy | Errors pass downstream, so gate each step with a programmatic check |
| **Routing** | Classify the input, send it to a specialized path | Categories are distinct and a classifier (LLM or ordinary code) is accurate | A wrong route is silent. Log the route and sample it |
| **Parallelization** | Sectioning (independent subtasks run at once) or voting (same task run several times) | Speed matters, or independent perspectives raise confidence | Voting multiplies cost. Sections must truly be independent |
| **Orchestrator-workers** | A lead model splits the task at run time and delegates | Subtasks cannot be predicted (multi-file code changes, broad research) | Workers lack the lead's context. Brief each one fully |
| **Evaluator-optimizer** | One model generates, another critiques, loop until the criteria pass | You have clear criteria and refinement measurably helps | Needs a hard iteration cap. Vague criteria make it loop forever |

Selection shortcut: fixed steps, use chaining. Many input types, use routing. Independent work, use parallelization. Unpredictable subtasks, use orchestrator-workers. Clear quality bar that iteration can reach, use evaluator-optimizer. If none fits and the path is open-ended, use an agent loop.

## Harness anatomy

| Part | Design rule |
|---|---|
| **Loop** | Call the model, run tool calls, append results, repeat. Keep it small enough to read in one sitting |
| **Stop conditions** | Natural finish (no tool call), a terminal tool, a step cap, a token or cost cap, a wall-clock timeout, repeat detection, human cancel. Combine several. On a cap, return a partial result with the reason |
| **Caps** | Per-run steps and spend, per-tool timeouts, concurrency limits. An uncapped loop is an unbounded bill |
| **Tool permissions** | Three tiers by effect: read-only (auto-allow), reversible write (allow with logging), irreversible or external (ask or deny). Check authorization inside the tool, not in the prompt |
| **Hooks** | Deterministic code at lifecycle points (before a tool call, after it, on stop). Use hooks for rules that must always hold, such as blocking a path or running a formatter. Prompts only make a rule likely |
| **Observability** | Record every step: input, tool calls, results, token use. You cannot debug a trajectory you did not keep |

Detail, loop sketch, and a stop-condition table are in [harness-and-control](references/harness-and-control.md).

## Human in the loop

Place approval points by consequence, not by step count. Gate sends, deletes, payments, deploys, and anything that leaves your system. Auto-approve reads. An approval is a pause that must survive time: the agent state has to be stored so the run can resume when the person answers, minutes or days later. A prompt that asks the model to "check with the user first" is not a control.

Pair this with the trifecta rule from security research: an agent that holds private data, reads untrusted content, and can communicate externally can be steered into leaking data ([Willison](https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/)). Meta's Agents Rule of Two says to give one session at most two of untrusted input, sensitive access, and state change or external communication ([Meta](https://ai.meta.com/blog/practical-ai-agent-security/)). Filters do not fix this. Remove one leg.

## Memory layers

| Layer | What it holds | Lifetime | Failure to guard |
|---|---|---|---|
| **Context window** | The current messages and tool results | One run | Context rot: recall drops as tokens grow |
| **Compaction** | A summary that replaces old turns | One long run | Summaries drop details. Tune for recall first, then trim. Clearing old tool results is the lightest safe form |
| **Stores** | Facts and preferences saved outside the context, keyed by user | Across runs | Cross-user leaks. Namespace every record by user |
| **Progress notes** | A file or record of done, pending, and decisions | Across sessions | Stale notes. Update them at the end of each unit of work |

Prefer just-in-time retrieval (keep identifiers, load content through tools) over stuffing everything up front. Details in [memory-multi-agent-durability](references/memory-multi-agent-durability.md), sourced from Anthropic's [context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) and [long-running harness](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) posts.

## Multi-agent: when it helps and when it hurts

Helps: breadth-first work that parallelizes, information that exceeds one context window, and subtasks whose raw exploration should stay out of the lead's context. Anthropic's research system (lead plus subagents) beat a single agent by 90.2% on its internal eval, at roughly 15 times the tokens of a chat, and token use explained about 80% of the variance on BrowseComp ([source](https://www.anthropic.com/engineering/multi-agent-research-system)).

Hurts: tasks that need shared context or have many dependencies between parts, which includes most coding. Parallel agents act on partial context and make conflicting assumptions ([Cognition](https://cognition.com/blog/dont-build-multi-agents)). Rule: use subagents for read-only exploration and isolated subtasks that return a short summary. Do not run parallel writers on one shared artifact.

## Durable execution

A loop that runs for minutes, waits for approval, or calls flaky tools needs to survive a crash. Persist state at each step (a checkpointer, a workflow engine, or a database row), make steps idempotent so a retry cannot double-charge or double-send, and resume from the last completed step instead of restarting. Pausing for a human is the same problem as surviving a restart. Options and the idempotency rules are in the memory-multi-agent-durability reference.

## Error recovery

| Error | Handle it by |
|---|---|
| Transient (timeout, rate limit, 5xx) | Retry with backoff in the harness. The model never sees it |
| Tool fails for a reason the model can fix (bad argument, not found) | Return a specific, actionable error as the tool result so the model can adjust |
| Malformed model output (bad JSON, schema miss) | Retry once with the validation error appended, then fail the step |
| Model loops or repeats a call | Repeat detection, then stop with a reason |
| Needs a decision only a person can make | Pause for approval or hand off |
| Unexpected (bug, corrupted state) | Fail fast, keep the transcript, alert |

## Structured outputs and tool schemas

Use constrained structured output when code consumes the result. Schema-constrained decoding makes the JSON parse, but it does not make it correct. Plan for these failures: a refusal that ignores the schema, truncation at the token limit that leaves invalid JSON, schema features the provider rejects (recursion, numeric bounds, open `additionalProperties`), extra latency on the first request with a new schema, and values that are valid but wrong. Validate semantics in code. Keep schemas small, put descriptions on fields, and give every strict object `additionalProperties: false`. Provider details are in [structured-output-and-tools](references/structured-output-and-tools.md). For MCP tool design see `mcp-server-development`.

## Model routing

Put a cheap, fast model on classification, routing, extraction, and summarization. Put the strongest model on planning and on steps where a mistake is expensive. Keep model IDs in one config layer (aliases such as `fast` and `strong`) so a swap is a config change, and add a fallback for provider outages. Do not swap models without running your eval set, because a cheaper model that needs more loop steps can cost more overall.

## Framework choice

Start without a framework: the loop is a few dozen lines, and frameworks can hide prompts and make failures harder to read. Adopt one when it removes work you would otherwise build: persistence, streaming to a UI, tracing, or approval flow. Read the code underneath before relying on it.

| Framework | Language | One-line fit |
|---|---|---|
| Vercel AI SDK | TypeScript | Provider switching, streaming to React and other UIs, `ToolLoopAgent`, and durable `WorkflowAgent`. See `vercel-ai-sdk` |
| LangChain and LangGraph | Python, JS | Explicit graphs with checkpointers and interrupts for workflows with loops and approval. See `langchain-components` |
| Claude Agent SDK | Python, TypeScript | Claude Code's agent loop as a library: built-in tools, hooks, subagents, MCP, permissions, sessions |
| OpenAI Agents SDK | Python, TypeScript | Small set of primitives: agents, handoffs, guardrails, sessions, tracing, sandbox agents. Non-OpenAI models via adapters |
| Pydantic AI | Python | Typed outputs, dependency injection, evals, OpenTelemetry, durable execution through Temporal, DBOS, or Prefect |
| Mastra | TypeScript | Agents, tools, memory, and a Studio UI in a Next.js or Node app |
| Google ADK | Python, TypeScript, Go, Java, Kotlin | Sequential, loop, and parallel workflow agents, A2A, evals, model-agnostic |

Facts above were checked on 2026-10-21 against each project's docs. Majors move fast, so pin versions and read release notes before upgrading.

## Quick reference: checklist

- [ ] Wrote down why a workflow cannot do the job before choosing an agent
- [ ] Picked the workflow pattern from the table, or a single call if none is needed
- [ ] Set stop conditions: step cap, cost cap, timeout, repeat detection
- [ ] Classified every tool by effect and gated the irreversible ones
- [ ] Checked the agent against the trifecta and Rule of Two
- [ ] Made side-effecting steps idempotent and state resumable
- [ ] Decided what lives in context, notes, and stores, and namespaced stores by user
- [ ] Justified any multi-agent split against the helps and hurts list
- [ ] Validated structured output and tool arguments in code
- [ ] Built 20 to 50 eval tasks from real failures before tuning

## Reference files

| Reference | Contents |
|---|---|
| [harness-and-control](references/harness-and-control.md) | Loop sketch, stop-condition table, caps, permission tiers, hooks, approval design, error handling |
| [memory-multi-agent-durability](references/memory-multi-agent-durability.md) | Context budget, compaction, notes, multi-agent patterns and briefs, durable execution and idempotency |
| [structured-output-and-tools](references/structured-output-and-tools.md) | Provider schema limits, failure modes, validation loop, tool schema rules, evals for agents |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Building or reviewing an MCP server or agent tools | `mcp-server-development` |
| Building agents in TypeScript with the Vercel AI SDK | `vercel-ai-sdk` |
| Building agents with LangChain, LangGraph, or Deep Agents | `langchain-components` |
| Fetching current library docs | `docs-lookup` |
| Prompt injection, secrets, and permission review for agents | `agent-security` |
| Web application security around the agent | `security` |
| Measuring whether the agent works, graders and regression suites | `llm-evals` |
| Tracing runs, token cost, and latency | `llm-observability` |
| Test strategy for agents | `testing` |
| General latency and bottleneck diagnosis | `performance` |
| Debugging a failing agent run | `debugging` |

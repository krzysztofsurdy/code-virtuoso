# Memory, multi-agent, and durable execution

Three topics that share one question: what does each model call see, and what survives between calls. This file covers the context budget, memory layers, when to split work across agents, and how to make a long run resumable.

## Contents

- [Context is a budget](#context-is-a-budget)
- [Memory layers in practice](#memory-layers-in-practice)
- [Long-running work across sessions](#long-running-work-across-sessions)
- [Multi-agent patterns](#multi-agent-patterns)
- [Briefing a subagent](#briefing-a-subagent)
- [Durable execution](#durable-execution)
- [Idempotency rules](#idempotency-rules)
- [Model routing](#model-routing)
- [Sources](#sources)

## Context is a budget

Anthropic defines context engineering as curating and maintaining the best set of tokens at inference time. Recall of earlier content falls as the token count grows (context rot), and each added token draws on a finite attention budget. The target is the smallest set of high-signal tokens that makes the next step succeed.

Practical rules:

- Keep identifiers, not content. Hold file paths, queries, and links, and load the data through tools when needed (just-in-time retrieval). It is slower than precomputed retrieval, so a hybrid works: load a small stable set up front and fetch the rest on demand.
- Put stable material (instructions, tool definitions) first and keep it byte-stable so provider prompt caching applies. Reordering tools between requests breaks the cache. Check the provider's caching docs for the exact prefix rules.
- Cap tool output. A single oversized result can consume the budget in one step.
- Shorter, human-written instructions beat long ones. Research on repository context files found they often did not improve task success and added more than 20% cost ([arXiv 2602.11988](https://arxiv.org/abs/2602.11988)). Add a line only when a failure you observed justifies it.

## Memory layers in practice

| Layer | Mechanism | Rules |
|---|---|---|
| Context | The message list for this run | Trim what the next step does not need |
| Compaction | Summarize old turns, start a fresh window with the summary | Tune for recall first so no needed detail is lost, then cut noise. Clearing stale tool results is the lightest safe step |
| Notes | The agent writes a to-do list or notes file outside the window and rereads it | Use for multi-hour tasks. Structure the file so it is easy to update without rewriting |
| Store | A database or key-value store with namespaces | Namespace by user ID so memories never cross users. Store facts with a source and date so stale ones can be dropped |
| Retrieval | Search over documents or past runs, as a tool | Test retrieval quality apart from generation quality |

When you delete or trim messages, keep the history valid: every tool result must follow its tool call, and some providers require the first message to come from the user. Trim in whole turns.

## Long-running work across sessions

Each new session starts with no memory of the last. Compaction alone does not carry a project across sessions. Anthropic's harness for long-running coding agents uses two roles with the same tools ([source](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)):

1. An initializer run creates an `init.sh` that starts the app, a progress log, a first commit, and a feature list with every feature marked failing.
2. Every later session reads the progress log and git history, picks the top unfinished feature, runs a basic end-to-end check, does one feature, tests it end to end, commits, and updates the log.

Why it works: the feature list stops premature victory, one feature per session stops one-shotting, commits make bad changes revertible, and the startup check catches breakage before new work piles on it. The feature list is JSON and agents may only flip the `passes` field, because models overwrite Markdown more readily than JSON.

## Multi-agent patterns

Start from one agent with good tools. Split only for a reason in this table.

| Pattern | Pick it when | Cost | Watch out for |
|---|---|---|---|
| Subagent as a tool | The lead delegates a bounded subtask and needs only a summary back | One extra hop per task. Subagents explore with tens of thousands of tokens but return roughly 1,000 to 2,000 tokens | The lead cannot see the subagent's reasoning. Brief it well |
| Parallel subagents | Breadth-first, independent, read-only work (research, scanning many files) | About 15 times chat token use in Anthropic's research system. Parallelism cut research time by up to 90% on complex queries | Duplicate work and gaps when briefs are vague |
| Handoff | The active agent should change as the conversation moves (triage to specialist) | Few extra calls | Sequential only. State must travel with the handoff |
| Router | Input classifies into domains and each domain has its own agent or prompt | One cheap classification call | A wrong route is silent. Log it |
| Orchestrator-workers | Subtasks are unknown until run time | Lead call plus worker calls | Workers lack the lead's context |
| Debate or critic | An independent check on high-stakes output | Doubles calls | Critics agree with the author unless given different instructions or tools |

When it hurts: shared context and many dependencies between parts, which describes most coding work. Subagents working in parallel on separate partial context make inconsistent choices, and agent-to-agent conversation is not yet reliable enough to repair that ([Cognition](https://cognition.com/blog/dont-build-multi-agents)). Two rules follow. Share the full relevant context with whoever acts, and treat each action as carrying hidden decisions that other agents cannot see. In practice: parallelize reads, serialize writes.

Token use explained about 80% of the performance variance on BrowseComp in Anthropic's study, so some of a multi-agent gain is simply more tokens spent. The task's value has to cover that cost.

## Briefing a subagent

Vague briefs caused duplicated work and gaps in Anthropic's system. Give each subagent:

- The objective in one sentence, and what done looks like
- The output format and maximum length
- Which tools and sources to use, and which to avoid
- Boundaries: what the neighboring agents cover, so work does not overlap
- An effort budget (for example, up to 10 tool calls)

Add effort-scaling rules to the lead's prompt, since a lead that cannot judge effort over-spawns: one agent with a few tool calls for a simple lookup, a few subagents for a comparison, many only for broad research.

## Durable execution

A run that takes minutes, waits for a person, or calls flaky services should survive a crash or deploy.

| Option | What it gives | Notes |
|---|---|---|
| Graph checkpointer (LangGraph) | Per-step state saved, resume by thread ID, interrupts for approval | Use a database-backed saver in production. See `langchain-components` |
| Workflow engine (Temporal, DBOS, Prefect) | Each step is a durable, retried unit | Pydantic AI integrates with all three |
| Framework durable agent (Vercel `WorkflowAgent`) | Survives restarts, tool retries as workflow steps, approvals that survive suspension | Context passed across steps must be serializable data, not clients or functions |
| Resumable sandboxes (OpenAI Agents sandbox agents) | Isolated workspaces with manifest-defined files and resumable state | For agents that work on files |
| Your own database | A row per run with step index and messages | Enough for simple cases. You write resume logic |

What to persist: the message list, the step index, pending tool calls, approval requests, and budget counters. Do not persist live objects.

## Idempotency rules

A resumed step may run again from its start. Design for that.

- Give every side-effecting call an idempotency key derived from the run and step, and pass it to the downstream API where one is supported.
- Record the effect before or with the step result, so a retry can see it already happened.
- Put the approval pause first in a step, before any side effect.
- Make read steps pure. Make write steps check whether the target state already exists.
- Treat approval payloads as untrusted input on resume, since they cross a trust boundary.

## Model routing

| Step | Model class | Reason |
|---|---|---|
| Classification, routing, extraction, formatting | Small and fast | Narrow tasks, high volume |
| Summarizing tool output for compaction | Small and fast | Recall matters more than reasoning |
| Planning, decomposition, hard reasoning | Strongest | Errors here propagate |
| Final answer for the user | Match to the stakes | A cheap draft plus a strong review can beat a strong single pass |
| Subagents doing bounded exploration | Mid-tier | Anthropic's research system used a stronger lead with cheaper subagents |

Implementation: keep model IDs in config behind role aliases (`fast`, `strong`), add a fallback provider for outages, and gate every change on your eval set. The Vercel AI SDK's `customProvider` shows the alias pattern. Check the provider's current model list instead of copying an ID from memory.

## Sources

- Anthropic, Effective context engineering for AI agents: https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Anthropic, Effective harnesses for long-running agents: https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Anthropic, How we built our multi-agent research system: https://www.anthropic.com/engineering/multi-agent-research-system
- Cognition, Do not build multi-agents: https://cognition.com/blog/dont-build-multi-agents
- Pydantic AI overview (durable execution integrations): https://pydantic.dev/docs/ai/overview/
- Vercel AI SDK WorkflowAgent: https://github.com/vercel/ai/blob/ai@7.0.0/content/docs/03-agents/07-workflow-agent.mdx
- OpenAI Agents SDK (sandbox agents): https://openai.github.io/openai-agents-python/

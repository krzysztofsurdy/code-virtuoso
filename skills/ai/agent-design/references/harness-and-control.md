# Harness and control

The harness is everything around the model: the loop, the limits, the permission checks, and the hooks. This file covers how to build each part so an agent can run without a person watching every step.

## Contents

- [The loop](#the-loop)
- [Stop conditions](#stop-conditions)
- [Caps](#caps)
- [Tool permissions](#tool-permissions)
- [Hooks](#hooks)
- [Approval design](#approval-design)
- [Error handling in the loop](#error-handling-in-the-loop)
- [Observability](#observability)
- [Sources](#sources)

## The loop

A language-neutral sketch. Every framework implements a version of this.

```text
messages = [instructions, task]
for step in 1..MAX_STEPS:
    reply = model(messages, tools)
    messages.append(reply)
    if reply.tool_calls is empty:
        return Done(reply)                      # natural finish
    for call in reply.tool_calls:
        verdict = policy(call)                  # allow, ask, deny
        if verdict == deny:  result = error("not permitted: <reason>")
        elif verdict == ask: return Paused(call, state=messages)
        else:                result = run_with_timeout(call)
        messages.append(tool_result(call, result))
    if over_budget() or repeating(messages):
        return Stopped(reason, partial=messages)
return Stopped("step cap", partial=messages)
```

Properties worth keeping in any version:

- The model never executes anything. It proposes tool calls, and the harness runs them after a policy check.
- Every exit returns a typed outcome (done, paused, stopped with a reason), so callers can tell success from a cap.
- A tool result is always appended, even on failure. A missing result leaves the history malformed and the next model call fails.
- Pausing returns the full state. Resuming feeds the person's answer back in as the pending tool result.

## Stop conditions

Use several at once. The first one to fire ends the run.

| Condition | How it works | Notes |
|---|---|---|
| Natural finish | The model replies without a tool call | The normal exit. Do not rely on it alone |
| Terminal tool | A tool such as `final_answer` ends the run when called | Gives a clean, checkable end. The Vercel AI SDK ships this as a `hasToolCall` stop condition |
| Step cap | Maximum model calls per run | The AI SDK defaults to 20 steps as a safeguard against runaway loops and cost. Pick your own number from eval data |
| Token or cost cap | Sum usage across steps, stop at a budget | Count all steps, including subagents |
| Timeout | Wall-clock limit per run and per tool | Protects against hung tools and slow loops |
| Repeat detection | Same tool with the same arguments N times, or no new information in N steps | Catches wandering. Return a reason so the caller can decide |
| Approval pending | A gated tool call needs a person | A pause, not a failure. State must be stored |
| Human cancel | User aborts | Pass an abort signal into the loop and into long tools |

On any cap, return what was done so far plus the reason. Silent truncation looks like success and produces wrong results that nobody notices.

Anthropic's guidance matches this: agents should get ground truth from the environment at each step (tool results, code execution), and a maximum iteration count keeps control ([source](https://www.anthropic.com/engineering/building-effective-agents)).

## Caps

| Cap | Why |
|---|---|
| Steps per run | Bounds latency and spend |
| Tokens or cost per run and per user per day | OWASP lists unbounded consumption as a risk in its 2025 LLM Top 10 ([LLM10](https://genai.owasp.org/llm-top-10/)) |
| Concurrent tool calls | Protects downstream APIs and your own rate limits |
| Subagent count and depth | A lead that spawns many subagents multiplies cost. Anthropic saw early failures where simple queries spawned 50 subagents, and fixed it with explicit effort-scaling rules in the prompt ([source](https://www.anthropic.com/engineering/multi-agent-research-system)) |
| Tool output size | Truncate large results and tell the model how to narrow the query. Large results consume the context budget in one step |

## Tool permissions

Classify every tool by what it can change, then decide the policy per tier.

| Tier | Examples | Default policy |
|---|---|---|
| Read-only | search, read file, list, get | Allow. Still log |
| Reversible write | create draft, write to a scratch path, add a label | Allow with logging, or allow inside a sandbox |
| Irreversible or external | send email, delete, pay, deploy, post publicly, run arbitrary shell | Ask a person, or deny. Never auto-allow on the model's say-so |

Rules that prevent the common holes:

- Authorize inside the tool, with the caller's identity from the session. The model is not an authorization layer, and it can be talked into anything by injected text.
- Give each agent only the tools its task needs. A shorter tool list is safer and routes better.
- Never pass a model-written string to `eval`, `exec`, or a shell. For code execution, use a sandbox with no credentials in it.
- Keep secrets out of prompts, state, and traces. Give tools access through runtime context or environment, not through messages.
- Mark tools with annotations (read-only, destructive, idempotent) where the protocol supports it, but treat annotations from a server you do not control as untrusted.
- Apply the Rule of Two per session: at most two of untrusted input, sensitive access, and state change or external communication ([Meta, 2025-10-31](https://ai.meta.com/blog/practical-ai-agent-security/)). A session that reads web pages and holds customer data should not also be able to send email.

## Hooks

A hook is code that the harness runs at a lifecycle point, whatever the model says. Typical points: before a tool call, after a tool call, when the agent is about to stop, and on session start.

| Use a hook for | Instead of a prompt instruction because |
|---|---|
| Blocking writes to protected paths or commands matching a pattern | A prompt rule is followed most of the time. A hook is followed every time |
| Running a formatter, linter, or test after each edit | The result comes back as feedback the model must handle |
| Refusing to stop until a check passes (tests green, file written) | The model tends to declare victory early |
| Redacting secrets or PII from tool results before the model sees them | The model cannot leak what it never received |
| Writing an audit log | Logging should not depend on model behavior |

Keep hooks fast and deterministic. A hook that calls another model is a second agent, with its own cost and failure modes, so budget for it.

## Approval design

- Gate by consequence. Interrupt on irreversible or external tools and auto-approve reads.
- Show the person the exact action and arguments, not the model's summary of them.
- Let the person approve, edit the arguments, or reject with a reason. A rejection goes back to the model as a tool result so it can try another route.
- Store the paused state outside process memory. The answer may arrive after a deploy or a restart.
- Do the work before the pause idempotently. When the run resumes, the step that paused often restarts from its beginning, so side effects placed before the pause can run twice.
- Time-box approvals. A request nobody answers should expire and fail safe.

## Error handling in the loop

| Error class | Owner | Action |
|---|---|---|
| Transient network, rate limit, 5xx | Harness | Retry with exponential backoff and jitter, within the step's time budget. The model never sees it |
| Argument errors the model can fix | Model | Return a specific message ("date must be in the future, today is 2026-10-21") as the tool result |
| Not found or permission denied | Model | Return it as a result and say what alternatives exist |
| Bad structured output | Harness | One retry with the validation error appended. Then fail the step |
| Loop or repeat | Harness | Stop with a reason |
| Needs judgment a person must give | Person | Pause |
| Bug or corrupt state | Operator | Fail fast, keep the transcript, alert |

Pair the model's adaptability with deterministic safeguards such as retries and checkpoints, as Anthropic's research system does, so a tool failure does not restart the whole run ([source](https://www.anthropic.com/engineering/multi-agent-research-system)).

## Observability

Record per step: the messages sent, the model and its parameters, the tool calls with arguments, results, token counts, latency, and the stop reason. Tag traces with environment and version. Trace content often holds user data, so make message capture opt-in and apply the same retention rules as other user data. OpenTelemetry publishes GenAI semantic conventions with agent and tool span types. Check their stability status before depending on attribute names, since they were still in development at the last check. Most tracing backends accept OTLP.

## Sources

- Anthropic, Building effective agents: https://www.anthropic.com/engineering/building-effective-agents
- Anthropic, How we built our multi-agent research system: https://www.anthropic.com/engineering/multi-agent-research-system
- Vercel AI SDK loop control (default `isStepCount(20)`, `hasToolCall`): https://github.com/vercel/ai/blob/ai@7.0.0/content/docs/03-agents/04-loop-control.mdx
- Meta, Agents Rule of Two: https://ai.meta.com/blog/practical-ai-agent-security/
- Simon Willison, The lethal trifecta: https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
- OWASP Top 10 for LLM Applications: https://genai.owasp.org/llm-top-10/

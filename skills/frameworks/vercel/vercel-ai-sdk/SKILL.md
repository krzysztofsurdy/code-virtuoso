---
name: vercel-ai-sdk
description: Decision guide for the Vercel AI SDK (`ai` and `@ai-sdk/*`) in TypeScript, covering the version matrix, agent loop, structured output, tool approval, streaming, testing, and migration traps. Use when building or upgrading AI SDK code.
user-invocable: false
---

# Vercel AI SDK

The AI SDK ships a new major about every five to eight months, and each one renames APIs that earlier code and model memory still use. This skill therefore holds no API listings. It holds the version facts, the decisions the docs do not make for you, and the traps between majors. Fetch the current API for the installed major before writing code that calls it.

## Core principles

| Principle | Meaning |
|---|---|
| **Read the installed major first** | `ai` 5, 6, and 7 differ in names and result shapes. Docs for the wrong major mislead |
| **Fetch, do not recall** | Treat any remembered import, option name, or model ID as stale until docs confirm it |
| **Cap every loop** | Agents stop on conditions you set. Combine a step cap with a terminal tool |
| **Gate side effects in code** | Use `toolApproval` for destructive tools. Do not rely on a prompt |
| **Client history is untrusted** | A browser can send any message list, including tool results |
| **Mock the model in unit tests** | Real-model calls belong in a small eval set, not in every test |

## Version matrix

Checked on 2026-10-21 against npm and Context7 `/vercel/ai`.

| Package | Current | Notes |
|---|---|---|
| `ai` | 7.0.148 | v7.0.0 released 2026-06-25. Node 22 or later, ESM-only. Peer: `zod` `^3.25.76 \|\| ^4.1.8` |
| `ai` earlier majors | 6.0.312 (`ai-v6` tag), 5.0.279 (`ai-v5` tag) | v6.0.0 on 2025-12-22, v5.0.0 on 2025-07-31. Both still publish patches |
| `@ai-sdk/react` | 4.0.152 | Vue 4.0.148, Svelte 5.0.148. Majors follow their own numbering: `ai` 6 pairs with `@ai-sdk/react` 3, `ai` 5 with 2 |
| Providers | `@ai-sdk/openai` 4.0.99, `@ai-sdk/anthropic` 4.0.85, `@ai-sdk/gateway` 4.0.121 | Install the version that matches your `ai` major |
| Add-ons | `@ai-sdk/mcp` 2.0.81, `@ai-sdk/workflow` 2.0.80, `@ai-sdk/otel` 1.0.148 | MCP client, durable `WorkflowAgent`, OpenTelemetry |

Read what the project actually runs:

```bash
npm ls ai @ai-sdk/react --depth=0 2>/dev/null
pnpm list ai "@ai-sdk/*" --depth=0 2>/dev/null
grep -E '"(ai|@ai-sdk/[a-z-]+)"' package.json
```

When the lockfile and `package.json` disagree, the lockfile wins. If the project is on `ai` 4 or 5, say so before suggesting v7 code, and offer the migration guides for each hop (for example [v6 to v7](https://github.com/vercel/ai/blob/ai@7.0.0/content/docs/08-migration-guides/23-migration-guide-7-0.mdx) and [v4 to v5](https://github.com/vercel/ai/blob/ai_5_0_0/content/docs/08-migration-guides/26-migration-guide-5-0.mdx)).

## Fetch API details through docs-lookup

Use the `docs-lookup` skill for the procedure. IDs for this library:

| Need | Context7 library ID |
|---|---|
| API for `ai` 7 | `/vercel/ai/ai_7.0.0` |
| API for `ai` 6, 5, 4 | `/vercel/ai/ai_6.0.0`, `/vercel/ai/ai_5_0_0`, `/vercel/ai/ai_4_3_19` |
| Docs site, any version, plus cookbook | `/websites/ai-sdk_dev` |

The version suffix format differs between majors, so copy it from the resolve result. Check the `Source:` URL in a snippet: it should say `ai@7.0.0` (or your major). Without Context7, read the docs site, or the migration guide and `skills/` folder in the vercel/ai repository, which the SDK team maintains per release.

## Core versus UI packages

| Layer | Package | Holds |
|---|---|---|
| Core | `ai` | `generateText`, `streamText`, `ToolLoopAgent`, `tool`, `Output`, stop conditions, message conversion, provider registry, `ai/test` mocks |
| UI hooks | `@ai-sdk/react`, `@ai-sdk/vue`, `@ai-sdk/svelte` | `useChat` and friends, tool-part states, approval responses |
| Providers | `@ai-sdk/openai`, `@ai-sdk/anthropic`, and others | Model constructors and `providerOptions` types |
| Gateway | `@ai-sdk/gateway`, or a `provider/model` string | One endpoint for many providers |
| Add-ons | `@ai-sdk/mcp`, `@ai-sdk/workflow`, `@ai-sdk/otel` | Opt in only when needed |

Keep the model code in server routes or workers. Client code receives UI messages and renders `parts`. UI messages cannot carry provider options, so convert them with `convertToModelMessages` before calling the model.

## Agent loop

`ToolLoopAgent` is the agent class. A `generateText` or `streamText` call with `tools` and `stopWhen` runs the same loop. Use the agent class when you reuse one configuration across calls or stream it to a UI.

The loop ends when the model finishes without a tool call, a called tool has no `execute`, a tool call needs approval, or a stop condition fires. The default is `isStepCount(20)`, a guard against runaway cost. An array of conditions stops when any one is met.

```ts
stopWhen: [isStepCount(10), hasToolCall('finalAnswer')]
```

- Set your own cap from eval data. Always pair a terminal tool with a step cap.
- `prepareStep` can change tools, instructions, or messages per step. In v7, returned `instructions` and `messages` carry into later steps. Code that relied on one-step overrides must rebuild them from the initial values.
- `activeTools` limits what the model may call without changing types. Use it to shrink the tool list per step.
- Check `result.steps` in tests to assert how many steps ran and which tools were called.

For runs that must survive restarts or pause for days, use `WorkflowAgent` from `@ai-sdk/workflow`. It runs inside a workflow, retries tool steps, and keeps approvals across suspension. Its context must be serializable: pass identifiers, not clients or functions.

## Structured output

Use `output: Output.object({ schema })` on `generateText` or `streamText` and read `result.output`. This replaced `generateObject` and `streamObject`, which were deprecated in v6. Zod is the usual schema library.

- Catch `NoObjectGeneratedError`. It carries `text`, `cause`, `response`, and `usage`, which is the raw evidence you need for evals.
- Streamed partial objects are not validated against the schema. Show them as a preview and validate at the end.
- Keep schemas small, with field descriptions.

## Tool approval

| Version | Where approval lives |
|---|---|
| v6 | `needsApproval` on the tool definition |
| v7 | `toolApproval` on the agent or the call. The v7 migration guide moves `needsApproval` out of `tool()` |

A `toolApproval` entry can be a status, or a function that gets the typed input and context. It returns `'user-approval'`, `{ type: 'denied', reason }`, or `undefined` to run normally. A single generic function can inspect any tool call. Gate by consequence and by input (for example, payments over a limit), and deny by role in the same function using `runtimeContext`.

In a chat UI, a gated call arrives as a tool part in state `approval-requested`. Respond with `addToolApprovalResponse({ id, approved })`, and set `sendAutomaticallyWhen: lastAssistantMessageIsCompleteWithApprovalResponses` so the chat resumes. Automatic decisions carry `approval.isAutomatic`, so do not answer those. Persist the messages server-side so an approval can arrive after a reload.

## Streaming to a UI

- For an agent, return `createAgentUIStreamResponse({ agent, uiMessages, abortSignal })` from the route.
- For `streamText`, v7 deprecates `result.toUIMessageStreamResponse()`. Build the stream with `toUIMessageStream({ stream: result.stream })` and `createUIMessageStreamResponse`. `fullStream` is now `stream`.
- Pass an abort signal so a closed tab stops the run and the spend.
- Do not trust the client's message list. Store history on the server, load it by chat ID, and accept only the new user message from the client. v7 moves system messages out of `messages` and into `instructions`. `allowSystemInMessages: true` is meant only for trusted persisted messages, so keep it off for client input.
- `onChunk` in v7 receives every part type. Check `chunk.type` first.

## Provider switching

| Option | Use when |
|---|---|
| `provider/model` string (AI Gateway) | You want one credential, many providers, and fast model swaps |
| Provider package (`openai('...')`) | You need provider-specific options, direct billing, or no gateway hop |
| `customProvider` or `createProviderRegistry` | You want role aliases (`fast`, `strong`) so model IDs live in one file |
| `wrapLanguageModel` with `defaultSettingsMiddleware` | You want default settings or provider options bound to an alias |

`providerOptions` are provider-specific, so a swap means rechecking them. Run your eval set after any swap. Never paste a model ID from memory or from a docs example: read the provider's current list or the project config. The registry and alias pattern also gives you a fallback provider for outages.

## Testing with mock models

Import from `ai/test`: `MockLanguageModelV4`, `MockEmbeddingModelV4`, `mockId`, `mockValues`. Add `simulateReadableStream` from `ai` to script streams. The mock class name tracks the provider spec version (V4 for `ai` 7), so a major upgrade changes it.

| Layer | Approach |
|---|---|
| Unit | Script `doGenerate` or `doStream` with fixed output. Fast, free, deterministic. Fetch the current chunk and usage shapes from the testing page, since they changed between specs |
| Agent loop | Script a tool call, then a final text. Assert tools called, step count, and that the stop condition fires |
| Structured output | Script invalid JSON and assert `NoObjectGeneratedError` handling |
| Integration | A small set of real-model tasks with outcome checks. See `llm-evals` if installed |
| Telemetry | Register `@ai-sdk/otel` once at startup with `registerTelemetry`. Telemetry is then on by default, and request and response bodies are excluded unless you opt in |

## Migration traps between majors

Read the official guide for each hop (v4 to v5, v5 to v6, v6 to v7) in order. The traps that bite most:

| Hop | Trap |
|---|---|
| v4 to v5 | `maxSteps` removed, use `stopWhen`. Tool `parameters` became `inputSchema`. `Message` became `UIMessage` with `parts`, and model-side messages are `ModelMessage`. Convert with `convertToModelMessages` |
| v5 to v6 | `ToolLoopAgent` and `needsApproval` appear in the v6 docs. `generateObject` and `streamObject` are deprecated in favor of `generateText` with `output` |
| v6 to v7 | Node 22 and ESM-only. `stepCountIs` is now `isStepCount`. `system` is now `instructions`. `fullStream` is now `stream`. `needsApproval` moves to `toolApproval`. Callbacks renamed (`onFinish` to `onEnd`, `onStepFinish` to `onStepEnd`) |
| v6 to v7, results | Top-level `usage`, `toolCalls`, `toolResults`, `content`, and `files` now cover all steps. Use `finalStep` for the old final-step values. `step.response.messages` no longer accumulates, so read `result.responseMessages` |
| v6 to v7, telemetry | OpenTelemetry left `ai`. Install `@ai-sdk/otel` and call `registerTelemetry`. `experimental_telemetry` became `telemetry`, and `experimental_*` aliases are deprecated |
| v6 to v7, context | `experimental_context` split into `runtimeContext` (orchestration state), per-tool `contextSchema`, and `toolsContext` |
| v6 to v7, usage | `cachedInputTokens` moved to `inputTokenDetails.cacheReadTokens`, `reasoningTokens` to `outputTokenDetails.reasoningTokens` |
| v6 to v7, MCP | `redirect` defaults to `'error'` on the MCP transport. Set `'follow'` only for trusted servers |
| Any hop | Provider and UI package majors do not match the `ai` major. Upgrade them together using the dist-tags (`ai-v6`, `ai-v5`) or latest |

The vercel/ai repository includes a migration skill for v6 to v7 that lists every rename. Run typecheck first, then smoke-test streaming, chat UI, tool execution, telemetry, and multi-step flows.

## MCP tools

`@ai-sdk/mcp` provides `createMCPClient`. Call `client.tools()`, pass the result as `tools`, and close the client in a `finally` block. Tool names and descriptions from a remote server are untrusted text that reaches your model: allowlist the tools you use through `activeTools`, and keep gated tools behind `toolApproval`.

## Quick reference: checklist

- [ ] Read the installed `ai` and `@ai-sdk/*` versions from the lockfile
- [ ] Fetched docs for that major through `docs-lookup`
- [ ] Set `stopWhen` with a step cap and, if useful, a terminal tool
- [ ] Used `Output.object` and handled `NoObjectGeneratedError`
- [ ] Put `toolApproval` on destructive tools and persisted messages server-side
- [ ] Kept client history out of the trust boundary
- [ ] Kept model IDs in config or a registry, and reran evals after a swap
- [ ] Unit-tested with `ai/test` mocks and checked `result.steps`
- [ ] Registered telemetry if you need traces
- [ ] Upgraded UI and provider packages together with `ai`

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Fetching current library docs | `docs-lookup` |
| Evals and regression tests for the app | `llm-evals` |
| OpenTelemetry traces, token cost, and latency | `llm-observability` |
| Tuning latency and token cost | `performance` |
| Debugging a failing run | `debugging` |

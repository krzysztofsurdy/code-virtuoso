---
name: mcp-server-development
description: Design and ship MCP servers and agent tools. Covers MCP versus CLI versus skill, tool design (few workflow-level tools, naming, response formats, pagination, actionable errors), spec 2026-07-28 changes and deprecations, OAuth 2.1 auth, security rules, evals, and SDK choice. Use when building, reviewing, or migrating an MCP server or any tool an LLM will call.
user-invocable: false
---

# MCP server development

An MCP server is a contract between your system and a model that reads your tool descriptions the way a new hire reads an API doc. Two things decide whether it works: how well the tools match what an agent is trying to do, and whether the server holds up as a network service (auth, statelessness, limits). Protocol details moved a lot in the 2026-07-28 revision, so fetch exact wire formats through `docs-lookup` instead of recalling them.

## Core principles

| Principle | Meaning |
|---|---|
| **Build only if MCP earns it** | A CLI or a skill often does the job with less machinery. Use MCP for typed contracts, OAuth identity, and multi-client or multi-tenant access |
| **Tools are prompts** | Names, descriptions, and parameter docs are read by a model. Write them with the same care as a system prompt |
| **Few tools, whole workflows** | One tool per user goal, not one per API endpoint |
| **Errors teach** | A failed call should say what to change. The model can then fix its own call |
| **Stateless by default** | No session on the wire. State lives behind explicit, authorized handles |
| **Least privilege** | Narrow scopes, tokens issued for your server only, authorization checked inside every tool |
| **Measure with evals** | Tool quality is an empirical question. Run realistic tasks and read the transcripts |

## MCP, CLI, or skill

| Situation | Use | Why |
|---|---|---|
| The agent has a shell, one user, a local tool with clear `--help`, JSON output, and predictable errors | CLI | Less overhead, and the agent already knows how to run commands |
| You are teaching a workflow, conventions, or domain judgment and adding no new capability | Skill | Instructions load on demand and cost no running process |
| Several different clients (IDE, chat apps, agents) need the same capability | MCP server | One contract, any client |
| The caller's identity matters: per-user OAuth, audit trail, revocation | MCP server | The authorization spec gives you a standard flow |
| Multi-tenant or governed access to a SaaS or internal system | MCP server | Central place for scopes, rate limits, logging |
| Structured, typed inputs and outputs with schema validation | MCP server | `inputSchema` and `outputSchema` are part of the protocol |
| Thin wrapper around a REST API that the agent could call with `curl` and a key | CLI or skill first | Protocol layers can lose fidelity, and the loss compounds on complex APIs |

Thoughtworks put "MCP by default" in the Caution ring of its April 2026 Radar and says to ask whether you need protocol-level interoperability before adding it ([source](https://www.thoughtworks.com/radar/techniques/mcp-by-default)). The usual best answer is a combination: a skill that explains when and how, over a CLI or MCP server that supplies the capability.

## Tool design rules

| Rule | Detail |
|---|---|
| Few, workflow-level tools | Replace `list_users` + `list_events` + `create_event` with `schedule_event`. Do not wrap every endpoint. Overlapping tools distract the model |
| Namespace | Group by service and resource (`asana_projects_search`). Aggregating clients hit collisions on names like `search`. Test prefix versus suffix with your target models |
| Meaningful identifiers | Return names and types the model can reason about. Keep raw IDs available in a detailed mode for follow-up calls |
| Response formats | Offer `concise` and `detailed` through a `response_format` parameter. Concise cut one example from 206 to 72 tokens |
| Pagination and truncation | Page, filter, and truncate with defaults. When you truncate, say how to narrow the query. Cap each response (Claude Code, for example, caps tool output at 25,000 tokens by default) |
| Actionable errors | Say what was wrong and what to try, with a valid example. Report execution errors as results with `isError: true`, not as protocol errors, so the model sees them |
| Unambiguous parameters | `user_id`, not `user`. Strict types, enums for closed sets |
| Tell tools apart in descriptions | Say what it does, when to use it, when not to, and how it differs from the neighbors |
| Deterministic `tools/list` | Return the same order each time so clients can cache and prompt caches hit |

Sources: Anthropic's [Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) and the spec's [tools page](https://modelcontextprotocol.io/specification/2026-07-28/server/tools). Examples, schema patterns, and an error catalog are in [tool-design](references/tool-design.md).

## Spec 2026-07-28 in one table

| Change | What to do |
|---|---|
| Stateless core: no `initialize` handshake, no `Mcp-Session-Id`, every request carries version and client capabilities in `_meta` | Do not store per-connection state. Return explicit handles for state that spans calls |
| `server/discover` is required | Implement it to advertise versions, capabilities, and identity |
| `tools/list` must not vary per connection and should be in deterministic order | It may vary by the credentials on the request. Sort the list |
| Multi Round-Trip Requests (MRTR) replace server-initiated requests | To ask the user or the client for input mid-call, return an `input_required` result and handle the retry. Integrity-protect `requestState` |
| Results carry `resultType` (`complete` or `input_required`) | Emit it on every result |
| Roots, Sampling, and Logging are deprecated | Do not add them. Pass paths as tool parameters, call your LLM provider directly, log to stderr or use OpenTelemetry |
| HTTP+SSE transport and Dynamic Client Registration are deprecated | Use Streamable HTTP and Client ID Metadata Documents |
| Tasks moved to an extension (`io.modelcontextprotocol/tasks`) | Opt in only if you need long-running calls, and expect a different shape than the 2025 experiment |
| `inputSchema` and `outputSchema` accept JSON Schema 2020-12 | Draft 2020-12 is the default dialect |
| Required `ttlMs` and `cacheScope` on list and read results | Set them so clients can cache |
| SSE resumability removed | A broken response stream loses the request. Clients retry with a new request ID, so make writes idempotent |

Deprecated features stay for at least twelve months under the spec's lifecycle policy. Full detail and a migration order are in [spec-2026-07-28](references/spec-2026-07-28.md).

## Auth in short

Authorization is optional in the spec and applies to HTTP transports. For stdio, read credentials from the environment. For a remote server:

- Act as an OAuth 2.1 resource server. Publish Protected Resource Metadata (RFC 9728) and point clients to your authorization server.
- Require PKCE. Clients send the `resource` parameter (RFC 8707) on authorization and token requests, and you accept only tokens issued for your server (audience check).
- Never pass the client's token through to a downstream API. Use a separate token for the downstream service.
- Return 401 with `WWW-Authenticate` when no valid token is present, and 403 with `insufficient_scope` when scopes fall short. Start with minimal scopes and step up per operation.

Details, the confused-deputy rules for proxies, SSRF, and a security checklist are in [auth-and-security](references/auth-and-security.md).

## Testing tools with evals

1. Write 20 to 50 realistic tasks that need several tool calls, each with a verifiable outcome.
2. Run each task as an agent loop against your server. Record accuracy, number of tool calls, tokens, runtime, and errors.
3. Read the transcripts. Repeated invalid-parameter errors point to unclear descriptions. Many redundant calls point to missing pagination or filters. Calls to the wrong tool point to overlapping tools.
4. Change one thing (a description, a name, a response format), rerun, and compare. Keep a held-out set so you do not overfit.
5. Also unit-test the server without a model: schema validation, auth rejection (wrong audience, expired, missing scope), pagination, and idempotent retries.

Detail and a harness sketch are in the tool-design reference. For the agent loop that runs the evals, see `agent-design`.

## SDKs

Checked on 2026-10-21 against npm and PyPI. Confirm which spec revision your SDK release implements before you target it.

| Language | Package | Version seen | Notes |
|---|---|---|---|
| TypeScript, new work | `@modelcontextprotocol/server`, `@modelcontextprotocol/client` | 2.3.1 | The v2 line. Its README says it implements the 2026-07-28 spec |
| TypeScript, existing code | `@modelcontextprotocol/sdk` | 1.32.1 | The v1 line. Bug and security fixes for at least six months after the v2 release on 2026-07-27 |
| Python, official | `mcp` | 2.3.0 | v2 renamed `FastMCP` to `MCPServer` (`from mcp.server import MCPServer`). Importing `mcp.server.fastmcp` raises `ModuleNotFoundError`. Read the migration guide |
| Python, separate framework | `fastmcp` (PrefectHQ) | 4.1.3 | Independent project at gofastmcp.com, not the official SDK. npm also has an unrelated `fastmcp` package |

Python 3.10 or later for both Python packages. Tier 1 official SDKs also exist for C#, Go, Rust, and Ruby, with Java at Tier 2 and PHP, Swift, and Kotlin at Tier 3 ([SDK list](https://modelcontextprotocol.io/docs/sdk)).

Fetch exact API details with `docs-lookup`. Context7 IDs:

| Need | ID |
|---|---|
| MCP specification, revision 2026-07-28 | `/websites/modelcontextprotocol_io_specification_2026-07-28` |
| Python SDK, pinned | `/modelcontextprotocol/python-sdk/v2.3.0` (also `/websites/py_sdk_modelcontextprotocol_io`) |
| TypeScript SDK, pinned to v2 | `/modelcontextprotocol/typescript-sdk/v2.3.1` (also `/websites/ts_sdk_modelcontextprotocol_io_v2`) |

After the first query, check that the `Source:` URL names the version you expect. The TypeScript v2 docs show a per-request server and transport pattern with `sessionIdGenerator: undefined`, which is the stateless setup the new spec expects.

## Quick reference: checklist

- [ ] Confirmed MCP is the right form: not a CLI or a skill
- [ ] Listed the user goals and mapped each to one workflow-level tool
- [ ] Namespaced tool names, sorted `tools/list`, wrote descriptions with when and when not
- [ ] Added `concise` and `detailed` response modes, pagination, and a response size cap
- [ ] Returned execution errors with `isError: true` and a next step
- [ ] Stored no per-connection state. Handles are random, expiring, and bound to the caller
- [ ] Implemented `server/discover`, `resultType`, and cache fields
- [ ] Avoided Roots, Sampling, Logging, HTTP+SSE, and DCR
- [ ] Validated token audience, refused passthrough, minimal scopes, step-up on demand
- [ ] Validated all inputs, rate limited, sanitized outputs, checked Origin on HTTP
- [ ] Ran an eval set and read the transcripts

## Reference files

| Reference | Contents |
|---|---|
| [tool-design](references/tool-design.md) | Tool rules with examples, schema patterns, response formats, error catalog, eval harness |
| [spec-2026-07-28](references/spec-2026-07-28.md) | Changes and deprecations, stateless server patterns, MRTR, handles, migration order from 2025-11-25 |
| [auth-and-security](references/auth-and-security.md) | OAuth 2.1 flow, RFC 9728 and 8707, client registration, confused deputy, SSRF, local servers, checklist |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Designing the agent that calls your tools | `agent-design` |
| Fetching current SDK or spec details | `docs-lookup` |
| REST contract design under the tools | `api-design` |
| Threat review, secrets, and input handling | `security` |
| Test strategy for the server | `testing` |
| Debugging a failing tool call or transport | `debugging` |

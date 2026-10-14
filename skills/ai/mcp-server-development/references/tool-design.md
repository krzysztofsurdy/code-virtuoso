# Tool design

Rules for tools that a model will call, with examples. The model sees only the name, the description, and the parameter schema, so those carry the whole design. The rules come from Anthropic's [Writing effective tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) and the MCP [tools page](https://modelcontextprotocol.io/specification/2026-07-28/server/tools), and apply to any tool interface, not only MCP.

## Contents

- [Start from tasks, not endpoints](#start-from-tasks-not-endpoints)
- [Names](#names)
- [Descriptions](#descriptions)
- [Input schemas](#input-schemas)
- [Responses](#responses)
- [Pagination and truncation](#pagination-and-truncation)
- [Errors](#errors)
- [Annotations](#annotations)
- [Stateful tools](#stateful-tools)
- [Eval harness](#eval-harness)
- [Sources](#sources)

## Start from tasks, not endpoints

List what a person would ask the agent to do, then give each goal one tool that completes it. A thin wrapper per endpoint forces the model to chain calls, carry IDs between them, and hold intermediate results in context.

| Instead of | Build |
|---|---|
| `list_users`, `list_events`, `create_event` | `schedule_event` (finds availability, then creates) |
| `read_logs` (returns everything) | `search_logs` (returns matching lines with surrounding context) |
| `get_customer`, `get_transactions`, `get_notes` | `get_customer_context` (one call, concise by default) |

Keep a low-level tool only when agents need it for cases the workflow tools cannot cover. Overlapping tools make the model hesitate between them, so remove duplicates. Every tool definition also costs context on every request, so a shorter list is cheaper.

## Names

- Use verbs that say what happens: `search_issues`, `create_invoice`.
- Namespace by service and resource when more than one server may be connected: `asana_projects_search`, `jira_issues_search`. Clients that merge several servers see collisions on generic names like `search`, and the server `name` is not guaranteed to be unique.
- Test prefix versus suffix naming (`asana_search` versus `search_asana`) against your target models. Results differ by model.
- Spec rules: 1 to 128 characters, case-sensitive, only ASCII letters, digits, underscore, hyphen, and dot, unique within the server.

## Descriptions

Write the description like onboarding a new colleague. State the implicit context: what the tool is for, niche terms, how resources relate.

```text
Search issues in the tracker by text, status, or assignee.
Use this to find existing work before creating an issue. To fetch one
issue by key, use get_issue instead. Returns at most 20 results, newest
first. Pass response_format="detailed" to include issue IDs, which
update_issue needs.
```

Include: what it does, when to use it, when not to (and the neighbor to use instead), input format requirements, and the limits on the output. Small wording changes can move accuracy a lot. Anthropic credits precise description changes for part of its SWE-bench Verified result, and rewriting tool descriptions with a model-driven test loop cut later task time by 40% in its research system.

## Input schemas

- Name parameters so they cannot be misread: `user_id`, not `user`. `start_date` and `end_date`, not `dates`.
- Use enums for closed sets, and `description` on every property, with an example value when the format is unusual.
- Make mistakes hard to make (poka-yoke). In Anthropic's SWE-bench agent, requiring absolute file paths removed a class of relative-path errors.
- Prefer formats the model has seen often (plain strings, ISO dates) over custom encodings.
- A tool with no parameters uses `{ "type": "object", "additionalProperties": false }`. The spec recommends this over a bare object.
- Schemas default to JSON Schema 2020-12. If you set `$schema` to another draft, say so explicitly.
- Keep schemas flat where you can. Deep unions and recursive structures confuse models and break strict-mode providers.

```json
{
  "name": "tracker_issues_search",
  "description": "Search issues by text, status, or assignee. ...",
  "inputSchema": {
    "type": "object",
    "properties": {
      "query": { "type": "string", "description": "Free text. Example: 'login timeout'" },
      "status": { "type": "string", "enum": ["open", "closed", "any"], "default": "open" },
      "assignee_id": { "type": "string", "description": "User ID from tracker_users_search" },
      "limit": { "type": "integer", "default": 20, "description": "1 to 50" },
      "cursor": { "type": "string", "description": "From a previous result's next_cursor" },
      "response_format": { "type": "string", "enum": ["concise", "detailed"], "default": "concise" }
    },
    "required": ["query"],
    "additionalProperties": false
  }
}
```

Validate every input on the server regardless of the schema. The spec requires servers to validate inputs, enforce access control, rate limit, and sanitize outputs.

## Responses

Return what the model needs for its next decision, and no more.

- Prefer high-signal fields (names, titles, statuses, relative times) over UUIDs, MIME types, and internal codes. Resolving identifiers to readable names reduced hallucinations in Anthropic's tests.
- Keep IDs available in a detailed mode, since later calls need them.
- Add a `response_format` enum (`concise`, `detailed`). In Anthropic's example a concise response used about 72 tokens against 206 for detailed.
- Test the response structure (JSON, Markdown, XML) with your target models. The best choice varies.
- If you declare an `outputSchema`, the result must match it, and clients should validate it. Also return the same data serialized as text in `content` for clients that read only text. `structuredContent` can be any JSON value.
- Every result carries `resultType`, which is `complete` for a finished call.

## Pagination and truncation

- Page, filter, and truncate by default. Use cursors for lists (`tools/list` supports pagination too).
- Set a hard size cap per response. Claude Code, for example, caps tool output at 25,000 tokens by default, so a larger response gets cut where you cannot control it.
- When you truncate, tell the model how to narrow: "Showing 20 of 340. Add a status or date filter, or pass the cursor."
- Watch the eval transcripts. Many redundant calls usually mean the default page is too small or filters are missing. Context blowups mean it is too large.

## Errors

The spec splits errors in two:

| Kind | Examples | How to report |
|---|---|---|
| Protocol error | Unknown tool, malformed request, server fault | JSON-RPC error. The model rarely recovers from these |
| Tool execution error | API failure, bad input, business rule violation | Result with `isError: true` and text the model can act on |

Report anything the model could fix as an execution error, or it never sees the cause. Make the text specific:

| Weak | Strong |
|---|---|
| `Error 422` | `start_date must be in the future. Today is 2026-10-21. Example: 2026-11-03` |
| `Not found` | `No issue with key PROJ-12. Use tracker_issues_search to find keys.` |
| `Permission denied` | `This token lacks issues:write. Ask the user to approve the extra scope.` |
| `Too many results` | `340 matches. Add a status or assignee filter and retry.` |

Never put stack traces, internal hostnames, or secrets in an error. Log the detail on the server and return the action.

## Annotations

Tool annotations describe behavior: `readOnlyHint`, `destructiveHint` (default true), `idempotentHint` (meaningful only when not read-only), and `openWorldHint`. Set them accurately, since clients use them to decide when to ask a person. Clients must treat annotations from servers they do not trust as untrusted, so never use an annotation as your own access control.

## Stateful tools

The protocol has no sessions. When tools need state across calls (a cart, an open transaction, a browser context), have a creation tool return an explicit handle and take it as an argument on later calls.

- Authorization: for authenticated servers, a handle names the state and does not prove permission. Check the caller against the handle on every call. Key stored state by `<user_id>:<handle>` with the user from the verified token.
- Opacity: use random, unguessable handles. Do not encode internals in them.
- Lifetime: state the retention in the creating tool's description ("baskets expire after 24 hours of inactivity").
- Expiry: a call with an expired or unknown handle returns an execution error that says so, so the model can create a new one.

## Eval harness

A small harness is enough. Sketch:

```text
for task in tasks:                      # 20-50 realistic, multi-call tasks
    for trial in 1..N:
        transcript = run_agent(task.prompt, tools=your_server)
        record(task, trial, transcript, outcome=check(task, environment))
report: accuracy, tool calls, tokens, runtime, tool errors per task
```

- Tasks need a verifiable outcome (a record exists, a value matches), not a keyword match. Avoid strict checks that reject a correct answer over wording.
- Make tasks long enough to need several tool calls. Simple tasks do not exercise tool choice.
- Ask the agent to write its reasoning before each tool call. It can improve tool use and makes transcripts easier to read.
- Track accuracy, runtime, number of tool calls, tokens, and tool errors per task.
- Read transcripts. Frequent invalid-parameter errors point to unclear descriptions or missing examples. Calls to the wrong tool point to overlapping tools. Many redundant calls point to pagination or filter defaults.
- Hand failing transcripts to a coding agent to propose tool changes, and keep a held-out task set so the changes do not overfit.
- Unit-test the server without a model as well: schema validation, auth rejection, pagination cursors, truncation messages, and idempotent retries.

For how to build the task set and grade it, see `agent-design` (structured-output-and-tools reference) and the `llm-evals` skill if installed.

## Sources

- Anthropic, Writing effective tools for agents: https://www.anthropic.com/engineering/writing-tools-for-agents
- MCP specification 2026-07-28, Tools: https://modelcontextprotocol.io/specification/2026-07-28/server/tools
- MCP specification 2026-07-28, schema (ToolAnnotations, CallToolResult): https://modelcontextprotocol.io/specification/2026-07-28/schema

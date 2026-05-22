# Validation Checklist

Run this checklist before writing the agent file. Most agent problems come from one of the items below.

## Identity

- [ ] `name` is kebab-case, lowercase, starts with a letter
- [ ] `name` describes the role, not the task (`reviewer`, not `review-pr-123`)
- [ ] File name matches the `name` field exactly
- [ ] No collision with an existing agent in the same or higher-priority scope

## Description

- [ ] Contains both "what it does" and "when to delegate"
- [ ] Includes trigger phrases an orchestrator can match
- [ ] Mentions any defining constraints ("read-only", "runs in a worktree")
- [ ] No marketing adjectives ("powerful", "comprehensive")
- [ ] No self-reference ("this agent is an agent that...")
- [ ] Under 300 characters if targeting platforms with strict description limits

## Tools

- [ ] `tools` is set explicitly - never inherits by omission
- [ ] Allowlist is the minimum that lets the workflow finish
- [ ] No `Edit` or `Write` unless the agent legitimately modifies files
- [ ] `Agent(...)` is scoped to specific sub-agent types, not bare `Agent`
- [ ] No hardcoded MCP tools the agent will not actually call

## Isolation and Memory

- [ ] `isolation: worktree` is set if and only if the agent writes or edits files
- [ ] `memory: project` is set only when the agent genuinely benefits from cross-session context
- [ ] Memory scope matches intent (user vs project vs local)

## Skills

- [ ] `skills` references by name, not path
- [ ] Four or fewer entries
- [ ] Every listed skill is actually used by the workflow

## Body

- [ ] Starts with a one-sentence role statement
- [ ] Has Input, Process, Rules, and Output sections
- [ ] Process has 3-7 numbered steps, each an action verb
- [ ] Rules are short imperatives, not paragraphs
- [ ] Output contains a concrete template, not vague prose
- [ ] No persona bloat ("elite senior engineer with 20 years...")
- [ ] No duplicated tool instructions (tools are in frontmatter)
- [ ] Portable - no "As Claude..." or platform-specific references
- [ ] Under 100 lines for most agents; under 200 for complex role agents

## Scope and Registration

- [ ] File placed in the correct scope (project / user / plugin / managed)
- [ ] If marketplace / plugin: registered in the plugin manifest
- [ ] If project has an agent index or README: added there
- [ ] If a template exists (`template/agent.md`, or equivalent): structure matches

## Portability

- [ ] `model` field omitted (unless agent is personal and pinned)
- [ ] No provider-specific phrasing in the body
- [ ] Tool names match the target platform's conventions

## Operational Sanity

- [ ] Delegating to the agent with a minimal prompt produces the documented output shape
- [ ] The agent refuses or flags out-of-scope work instead of drifting
- [ ] The agent respects its tool allowlist (no surprise shell calls)
- [ ] The agent does not "helpfully" do the task itself when asked to delegate or plan

## Common Rejection Reasons

| Problem | Fix |
|---|---|
| Description reads like marketing | Rewrite with trigger phrases |
| Agent does two things | Split into two agents |
| Tool allowlist is permissive-by-default | Trim to the minimum |
| Isolation missing on a writer | Add `isolation: worktree` |
| Output is "a summary" | Replace with a template |
| Role statement is missing | Add one sentence naming the role |
| Body contains provider name or tool names | Remove - body stays portable |
| `skills` list has ten entries | Trim to the essentials |

If any item is unchecked, stop and fix it before writing. A weak agent costs more in re-runs than the time saved by shipping early.

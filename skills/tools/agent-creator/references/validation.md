# Validation Checklist

Run this checklist before writing the agent file. Most agent problems trace back to one of these items.

## Research

- [ ] Research notes exist, or "research skipped at user request" is recorded in the notes and the PR
- [ ] Prior-art search done (repo, installed, harness docs, official plugins, agent collections, GitHub), or skipped at user request and recorded
- [ ] Prior-art table filled for 3 to 5 candidates, each read from its agent file
- [ ] Decision recorded: install or extend an existing agent, or design a new one
- [ ] If designing a new one: strengths adopted and weaknesses avoided are named, ideas are credited, no text was copied, licenses were checked
- [ ] Platform field, tool, and version facts in the agent's reference files each have a source URL
- [ ] No unverified platform fact is stated as settled in the agent body

## Identity

- [ ] `name` is kebab-case, lowercase, starts with a letter
- [ ] `name` describes the role, not the task (`reviewer`, not `review-pr-123`)
- [ ] File name matches the `name` field exactly
- [ ] No collision with an existing agent in the same or higher-priority scope

## Description

- [ ] Contains both "what it does" and "when to delegate"
- [ ] Includes trigger phrases an orchestrator can match
- [ ] Mentions any defining constraints ("read-only", "runs in a worktree")
- [ ] No marketing adjectives ("powerful", "full")
- [ ] No self-reference ("this agent is an agent that...")
- [ ] Under 300 characters if targeting platforms with strict description limits

## Tools

- [ ] `tools` is set explicitly and never inherited by omission
- [ ] Allowlist is the minimum that lets the workflow finish
- [ ] No `Edit` or `Write` unless the agent legitimately writes files (source code, documents, or planning notes)
- [ ] `Agent(...)` is scoped to specific sub-agent types, not bare `Agent`
- [ ] No hardcoded MCP tools the agent will not actually call

## Isolation and memory

- [ ] `isolation: worktree` is set when the agent changes source code. Read-only agents, documentation-only writers, and planning roles run in place
- [ ] `memory` is set only when the agent genuinely benefits from cross-session context
- [ ] The author knows `memory` enables Read, Write, and Edit, and the body says what the agent may write
- [ ] Memory scope matches intent (user vs project vs local)
- [ ] No `hooks`, `mcpServers`, or `permissionMode` on an agent that ships in a plugin (they are ignored)

## Skills

- [ ] `skills` references by bare name, not path
- [ ] Four or fewer entries
- [ ] Every listed skill is needed on every run
- [ ] No run-by-name skill (`disable-model-invocation: true`) and no role skill in the list
- [ ] The agent still works if a preload is missing or not injected (missing skills are skipped silently, and `claude -p --agent` does not inject them)
- [ ] If a skill ships in another bundle, the docs say which bundle to install
- [ ] A role agent lists its `roles/<role>/` files by path in a "Reference files" section

## Body

- [ ] Starts with a one-sentence role statement
- [ ] Has Input, Process, Rules, and Output sections
- [ ] Process has 3-7 numbered steps, each an action verb
- [ ] Rules are short imperatives, not paragraphs
- [ ] Output contains a concrete template, not vague prose
- [ ] No persona bloat ("elite senior engineer with 20 years...")
- [ ] No duplicated tool instructions (tools are in frontmatter)
- [ ] Portable, with no "As Claude..." or platform-specific references
- [ ] Under 100 lines for most agents; under 200 for complex role agents

## Scope and registration

- [ ] File placed in the correct scope (this library / project / user / plugin / managed)
- [ ] In this library: listed in the `agents` array of the `agents-virtuoso` entry, marketplace version bumped
- [ ] In this library: row added to the README and AGENTS agent tables
- [ ] In this library: `python3 scripts/build-codex-agents.py` run, so `codex/agents/<name>.toml` is current
- [ ] `expects` and `produces` use names from the artifact catalog, and the body handles missing input (harnesses ignore both fields)
- [ ] If a template exists (`template/agent-template.md`, or equivalent): structure matches

## Portability

- [ ] `model` field omitted (unless agent is personal and pinned)
- [ ] No provider-specific phrasing in the body
- [ ] Tool names match the target platform's conventions

## Operational sanity

- [ ] Delegating to the agent with a minimal prompt produces the documented output shape
- [ ] The agent refuses or flags out-of-scope work instead of drifting
- [ ] The agent respects its tool allowlist (no surprise shell calls)
- [ ] The agent does not "helpfully" do the task itself when asked to delegate or plan

## Common rejection reasons

| Problem | Fix |
|---|---|
| Description reads like marketing | Rewrite with trigger phrases |
| Agent does two things | Split into two agents |
| Tool allowlist is permissive-by-default | Trim to the minimum |
| Isolation missing on an agent that changes source code | Add `isolation: worktree` |
| Role has its own skill, or preloads one | Move the material to `roles/<role>/` files and point to them by path |
| Output is "a summary" | Replace with a template |
| Role statement is missing | Add one sentence naming the role |
| Body contains provider name or tool names | Remove them so the body stays portable |
| `skills` list has ten entries | Trim to the essentials |

If any item is unchecked, stop and fix it before writing. A weak agent costs more in re-runs than shipping early saves.

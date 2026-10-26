# Team specification

A team is a pre-composed recipe: a roster of agents, the phases they work in, and the gates between phases. Teams do not exist as runtime config files. A team is two artifacts that describe the same recipe:

| Artifact | Where | Runs on |
|---|---|---|
| **Workflow script** | `workflows/{name}.js` at the repository root | Claude Code, as `/{plugin}:{name}`. Deterministic: the script holds the loop, the gates, and the intermediate results |
| **Markdown recipe** | A section of `../workflows/teams.md` | Any harness. A person or a lead agent follows the phases, sequentially or with parallel subagents |

Write the recipe first. It is the source of truth for roster, phases, and gates. The workflow is the Claude Code encoding of it.

## Contents

- [Why no team config files](#why-no-team-config-files)
- [Markdown recipe](#markdown-recipe)
- [Workflow script](#workflow-script)
- [Naming](#naming)
- [Adding a team](#adding-a-team)
- [Validation checklist](#validation-checklist)

## Why no team config files

Claude Code keeps live team state under `~/.claude/teams/{team}/config.json` and recreates it each session. It is runtime state, not authored configuration, and a project-level `.claude/teams/teams.json` is not recognized. A team forms at runtime when the lead spawns named agents, and only with an experimental flag. Other harnesses have no team object at all. A workflow plus a Markdown recipe works everywhere without that dependency.

## Markdown recipe

Each team has an H2 section in `teams.md` with these parts, in order:

| Part | Content |
|---|---|
| Intro | One paragraph: what the team delivers and why several agents help |
| Roster | Table of role, agent `name`, and what each role receives. State context restrictions here (for example, the cold reviewer sees only the diff) |
| Inputs | What the person must supply |
| Phases | Numbered. Each names the agent, its input, its output, and whether it runs in parallel with another phase |
| Gates | Which phase blocks which, and who may send work back |
| Entry and exit | Conditions to start and to finish |
| Run sequentially | The lowest-common-denominator run order, and a Codex-style prompt where the team fans out |
| Variants | At least one lighter configuration or decision point |

Rules:

- Agent names are the `name` field of an agent in `agents/`. Each must exist.
- Stay agent-neutral. Do not name tools or models. Platform details belong in `platform-notes.md`.
- Use the people-in-the-loop step explicitly. A workflow cannot ask a question mid-run, so recipes that need a human decision end with the human decision and say so.
- Keep each team under about 40 lines.

## Workflow script

Workflows live in `workflows/` at the repository root. The `agents-virtuoso` plugin has `source: "./"`, so Claude Code scans that directory for it and no other bundle. A script runs as `/agents-virtuoso:{meta.name}`.

### Contract

1. The first statement is `export const meta = { name, description, whenToUse?, phases? }`, a pure literal. No variables, calls, spreads, or template interpolation. Otherwise the command drops out of autocomplete.
2. `meta.name` equals the file name without `.js`.
3. The body is plain JavaScript (not TypeScript) with top-level `await` and a final `return`. It uses `agent(prompt, opts)`, `parallel(thunks)`, `pipeline(items, ...stages)`, `phase(title)`, `log(message)`, and the `args` global.
4. `agent` options in use here: `label`, `phase`, `schema`, `agentType`, `isolation: 'worktree'`.
5. `meta.phases` titles match the `phase()` calls exactly.
6. No `Date.now()`, `Math.random()`, or `new Date()` with no argument (they throw, which keeps runs resumable), and no `import()` or `import` statements.
7. `args` may be `undefined`. Validate required input first and return `{status: 'error', reason}` instead of throwing.

### Design rules

| Rule | Why |
|---|---|
| `agentType` uses the plugin-scoped name, for example `agents-virtuoso:cold-reviewer` | The script resolves from the same registry as the Agent tool, and a bare name can collide with a user agent |
| Pass a JSON `schema` wherever a later step reads the result | Validated objects replace parsing, and deduplication becomes plain code |
| Use `parallel()` only where the next step needs all results, otherwise `pipeline()` | A barrier waits for the slowest agent |
| Filter `null` results | A stopped or failed agent resolves to `null` |
| Gates return a status object and stop. They do not loop | The run cannot ask the user. The user fixes the cause and re-runs |
| Write-capable agents running in parallel get `isolation: 'worktree'` and disjoint file lists, and the script checks the lists | Isolation stops overwrites, ownership stops conflicts |
| Debate and review roles get "no file writes" in the prompt | Agent definitions may carry write tools |
| Put the context restrictions of the recipe in each prompt | Workflow agents are told their text is the return value, so prompts must carry everything |

Return a status string (`approved`, `blocked`, `needs-clarification`, `awaiting-decision`) so a caller can branch on it.

## Naming

Lowercase letters, digits, and hyphens. Name the domain, not a task: `review-squad`, `development-team`, `war-room`. The Markdown section heading is the title-cased name. The workflow file name, `meta.name`, and the recipe heading all refer to the same team.

## Adding a team

1. Write the Markdown recipe in `teams.md` and confirm every agent exists.
2. Write `workflows/{name}.js` to the contract above. Start from [template/workflow-template.js](../template/workflow-template.js).
3. Test the script before committing: load it as an async function, check the `meta` literal and the phase titles, and run it against a mock `agent` that returns schema-shaped data. Cover each early return (missing input, failed gate), not only the happy path.
4. Run `claude plugin validate .` for the marketplace manifest. It does not read workflow bodies, so step 3 is not optional.
5. Register the team in the README team table and, if it adds a chaining pattern, in `AGENTS.md`. Bump the marketplace version.

## Validation checklist

- [ ] The recipe has every part in the table above and names only existing agents
- [ ] `workflows/{name}.js` starts with a pure-literal `meta` whose name matches the file
- [ ] `meta.phases` titles equal the `phase()` calls
- [ ] Every `agentType` is `agents-virtuoso:{agent name}` and the agent exists
- [ ] Missing `args` returns an error object, and every gate returns a status
- [ ] No forbidden APIs, no TypeScript syntax
- [ ] Parallel writers use worktrees and disjoint files
- [ ] The recipe and the script agree on roster, phases, and gates
- [ ] `claude plugin validate .` passes

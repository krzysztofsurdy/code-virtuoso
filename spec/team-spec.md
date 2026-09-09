# Team Specification

A team is a pre-composed recipe that bundles agents, skills, and a coordination protocol into a ready-to-use unit. Pick a team, invoke it, and the who-does-what is already defined.

## Contents

- [File location](#file-location)
- [Frontmatter fields](#frontmatter-fields)
- [Body sections](#body-sections)
- [Body guidelines](#body-guidelines)
- [Naming conventions](#naming-conventions)
- [Validation checklist](#validation-checklist)

## File location

Team files can live in two locations:

| Location | Purpose |
|---|---|
| `teams/{name}.md` at the user's project root | User-authored teams, discovered first |
| `skills/tools/agent-teams/teams/{name}.md` | Bundled teams that ship with the dispatching skill |

```
skills/tools/agent-teams/teams/    # bundled library
  development-team.md
  review-squad.md
  war-room.md

teams/                                          # optional, user-authored
  my-custom-team.md
```

The `dispatching-agent-teams` skill discovers teams from both locations. Project teams override bundled teams when names collide. Each team is a single Markdown file with YAML frontmatter and a Markdown body.

Teams ship alongside the skill that uses them. Installing `dispatching-agent-teams` gives the user a working team library with no separate setup.

## Frontmatter fields

| Field | Required | Type | Purpose |
|---|---|---|---|
| `name` | Yes | string | Kebab-case identifier matching the filename without `.md` |
| `description` | Yes | string | When to use this team. Include trigger phrases. Must be YAML-safe (wrap in double quotes if it contains colons) |
| `lead` | Yes | string | Agent `name` that coordinates the team. Must reference an existing agent in `agents/` |
| `agents` | Yes | list of strings | Agent `name` values participating in this team. Each must reference an existing agent in `agents/` |
| `skills` | No | list of strings | Skill `name` values the team should preload. Each must reference an existing skill |
| `workflow` | Yes | enum | `sequential`, `parallel`, `hybrid`, or `war-room` |

### Workflow types

| Type | When to use |
|---|---|
| `sequential` | Each phase depends on the previous. One agent works at a time. |
| `parallel` | Multiple agents work simultaneously on independent tasks. A lead dispatches and synthesizes. |
| `hybrid` | Some phases are sequential (requirements before design), some are parallel (frontend and backend implement simultaneously). |
| `war-room` | A decision forum. Agents take positions, challenge each other, and the user decides. Agents reason from knowledge only - no file modification or code execution. |

### Field rules

- `lead` must also appear in the `agents` list
- Agent names reference the `name` field in agent frontmatter, not the filename
- Skill names reference the `name` field in skill frontmatter
- Do not include provider-specific model names
- Descriptions must not contain unquoted colons followed by spaces (wrap in double quotes)

## Body sections

The body is the team's operational protocol - the instructions a lead agent follows to coordinate the team.

### Required sections

| Section | Purpose |
|---|---|
| **Purpose** | One paragraph describing what this team delivers and when to use it |
| **Workflow** | Numbered phases. Each phase names the agent, the input it receives, and the output it produces |
| **Entry Criteria** | Conditions that must be true before the team starts work |
| **Exit Criteria** | Conditions that must be true before the team is done |
| **Coordination Rules** | Hard constraints: who blocks whom, isolation requirements, handoff protocols |

### Optional sections

| Section | Purpose |
|---|---|
| **Skill Usage** | Which skills each agent should consult and when |
| **Spawning** | How to instantiate the team based on platform capabilities (see below) |
| **Escalation** | What to do when an agent is blocked or a phase fails |
| **Variants** | Lighter or heavier configurations (e.g., skip frontend for backend-only work) |

### Spawning section

Every team file should include a Spawning section that describes how to instantiate the team. Platform capabilities vary, so the spawning section covers both modes:

**Peer mode** (platforms with agent-to-agent messaging, e.g. experimental agent teams):
1. Create a team with the agents listed in the frontmatter
2. Assign the lead as coordinator
3. Create shared tasks matching the workflow phases with dependencies
4. Teammates claim tasks, message each other, and coordinate through the shared task list

**Sequential mode** (all other platforms):
1. Lead executes each workflow phase in order
2. Spawn one sub-agent per phase with the phase-specific brief
3. Collect the output and pass it as input to the next phase
4. Lead synthesizes the final result

Describe both modes in the team file. It then works on any platform and runs better where peer communication is available.

## Body guidelines

- Keep under 150 lines
- Use imperative mood for workflow steps
- Name concrete inputs and outputs for each phase (not vague "do the work")
- Specify which agents run in parallel vs sequentially
- Include at least one decision point (e.g., "if no API contract changes are needed, skip the Architect phase")
- Do not reference specific programming languages, frameworks, or platforms unless the team is framework-specific
- Do not reference specific AI coding tools or platform features
- Include a Spawning section describing peer and sequential instantiation modes
- If agents in a parallel phase need different context levels, specify the per-agent restrictions in Coordination Rules (e.g., "Cold Reviewer receives only the diff, no project docs")

## Naming conventions

- Lowercase letters, digits, and hyphens only
- Must end with `-team` (e.g., `development-team`, `code-review-team`)
- Describe the team's domain, not a specific task (`release-team`, not `release-v2-team`)

## Validation checklist

Before committing a team file:

- [ ] Filename matches the `name` frontmatter field plus `.md`
- [ ] `lead` agent exists in `agents/` and appears in the `agents` list
- [ ] Every agent in `agents` list has a matching `.md` file in `agents/`
- [ ] Every skill in `skills` list has a matching `SKILL.md` in `skills/`
- [ ] `workflow` is one of: `sequential`, `parallel`, `hybrid`, `war-room`
- [ ] Body has all required sections: Purpose, Workflow, Entry Criteria, Exit Criteria, Coordination Rules
- [ ] No provider-specific model names or platform-specific tool references
- [ ] Description is YAML-safe (no unquoted colons followed by spaces)
- [ ] Team file is under 150 lines

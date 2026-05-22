---
name: dispatching-agent-teams
description: "Spawn and coordinate a pre-composed agent team from a team definition file. Reads team files from teams/, resolves agents and skills, picks the best spawning mode (peer or sequential), and runs the workflow. Use when the user asks to run a team, dispatch a development team, start a feature delivery, or coordinate multiple agents for a multi-phase task."
user-invocable: true
argument-hint: "<team-name>"
---

# Dispatching Agent Teams

Read a team definition file, resolve its agents and skills, and execute the coordination protocol. The team file is the recipe - this skill is the cook.

## Core Principles

| Principle | Meaning |
|---|---|
| **Team file is the contract** | Follow the workflow, entry/exit criteria, and coordination rules defined in the team file. Do not improvise the process. |
| **Detect capabilities first** | Check what spawning mode the platform supports before dispatching. Peer mode if available, sequential fallback otherwise. |
| **Skills before agents** | Preload the team's bundled skills before spawning any agent. Agents need their reference material from the start. |
| **Respect coordination rules** | If the team file says "Architect must approve before implementation starts", enforce it. Do not skip gates. |
| **Fail early, not late** | If a required agent is not installed, stop before dispatching. Do not discover missing agents mid-workflow. |

---

## Workflow

### Phase 1: Resolve the Team

Teams are discovered from two locations in this order:

1. **Project teams** - `teams/{name}.md` at the user's project root (user-authored teams)
2. **Library teams** - bundled with the `agent-teams` skill at `skills/tools/agent-teams/teams/{name}.md` (or wherever the agent-teams skill is installed)

Resolution:

1. If the user provided a team name as argument, search project teams first, then the library. Project teams override library teams when names collide.
2. If no argument, scan both locations and present a selection menu showing which are library teams vs project teams.
3. Read the team file's YAML frontmatter: `name`, `lead`, `agents`, `skills`, `workflow`.
4. Verify every agent in the `agents` list exists as an installed agent definition.
5. Verify every skill in the `skills` list exists as an installed skill.
6. If any agent or skill is missing, report what is missing and stop. Do not proceed with a partial team.

### Team Library

The `agent-teams` skill catalogs the available pre-composed teams (development-team, review-squad, war-room) with their purpose and use cases. To browse what is available before dispatching, consult that skill first.

To author your own team, see [spec/team-spec.md](../../../spec/team-spec.md) and place the file at the project root's `teams/{name}.md`.

### Phase 2: Verify Entry Criteria

1. Read the team file's "Entry Criteria" section.
2. Check each criterion against the current state (e.g., "ticket exists", "CI is green", "stakeholder available").
3. If a criterion cannot be verified automatically, ask the user to confirm it.
4. Do not proceed until all entry criteria are met or explicitly waived by the user.

### Phase 3: Preload Skills

Load the skills listed in the team's `skills` frontmatter. These provide reference material that agents will need during their work (e.g., testing patterns, API design principles, verification checklists).

### Phase 4: Detect Spawning Mode and Workflow Variants

Check what the current platform supports:

| Capability | Detection | Mode |
|---|---|---|
| Platform supports agent teams with peer messaging and shared task lists | Team creation tools are available | **Peer mode** |
| Platform supports sub-agent spawning but no peer messaging | Agent delegation tools are available | **Sequential mode** |
| Neither | No delegation support | **Inline mode** - lead executes all phases in the current session |

Then check the team's `workflow` type for special handling:

| Workflow | Special protocol |
|---|---|
| `parallel` | Check Coordination Rules for per-agent context restrictions. If present, build differential briefs per agent (see [spawning-protocol](references/spawning-protocol.md)). |
| `war-room` | Use multi-pass rounds: position round, then challenge round, then synthesis. Agents respond with perspective only - no tool use during the debate (see [spawning-protocol](references/spawning-protocol.md)). |
| `sequential`, `hybrid` | Standard protocol. |

### Phase 5: Dispatch

#### Peer Mode

1. Create a team with the lead agent as coordinator.
2. Add all other agents as teammates.
3. Create shared tasks matching the workflow phases from the team file.
4. Set task dependencies based on the workflow order (e.g., "Implementation" is blocked by "Design").
5. The lead assigns the first unblocked task. Teammates claim tasks as they unblock.
6. Teammates message each other for clarifications as described in the coordination rules.

#### Sequential Mode

1. The lead agent runs in the current session.
2. For each workflow phase in order:
   a. Read the phase description from the team file (what this agent does, expected input/output).
   b. Spawn the phase's agent as a sub-agent with a brief containing: the phase description, the output from previous phases, and the relevant skills to consult.
   c. Collect the sub-agent's output.
   d. If the team file defines a gate between this phase and the next, verify the gate condition before proceeding.
3. Pass each phase's output as input to the next phase.

#### Inline Mode

1. Execute each workflow phase sequentially in the current session.
2. For each phase, adopt the role described in the team file and consult the relevant skills.
3. Produce the expected output before moving to the next phase.

### Phase 6: Verify Exit Criteria

1. Read the team file's "Exit Criteria" section.
2. Check each criterion against the current state.
3. Report results to the user with evidence for each criterion (pass/fail with proof).
4. If any exit criterion fails, report what remains and ask the user how to proceed.

---

## Handling Failures

| Failure | Action |
|---|---|
| Agent not installed | Stop before dispatching. List missing agents with install instructions. |
| Skill not installed | Stop before dispatching. List missing skills with install instructions. |
| Entry criterion not met | Ask user to confirm or waive. Do not silently skip. |
| Phase produces no output | Retry the phase once. If it fails again, report to the lead/user. |
| Gate condition not met | Block the next phase. Report what failed the gate and what needs to change. |
| Agent times out or errors | Report the error. Ask user whether to retry, skip, or abort the team. |

---

## Quality Checklist

Before claiming the team run is complete:

- [ ] All workflow phases were executed in the defined order
- [ ] All coordination gates were enforced (no skipped approvals)
- [ ] All exit criteria were verified with evidence
- [ ] Outputs from each phase were captured and passed forward
- [ ] Any failures were reported with context, not silently swallowed

---

## Platform Notes

Platform-specific tool names and conventions for executing this skill. The instructions above stay portable; the table below maps abstract capabilities to concrete tools per platform.

| Platform | Convention |
|---|---|
| Claude Code | Always create the team with the `TeamCreate` tool before dispatching any work. Never spawn multiple `Agent` tool calls directly when a team workflow is available. After `TeamCreate`, dispatch tasks through the team. |
| Cursor | (TBD) Use the platform's multi-agent coordination feature if available; otherwise fall back to sequential sub-agent dispatch. |
| Windsurf | (TBD) Use the platform's multi-agent coordination feature if available; otherwise fall back to sequential sub-agent dispatch. |
| Other | Use the platform's equivalent for instantiating a multi-agent team with a shared task list. If no such mechanism exists, run in sequential mode. |

## Reference Files

| Reference | Contents |
|---|---|
| [spawning-protocol](references/spawning-protocol.md) | Detailed spawning steps for peer, sequential, and inline modes |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Need to discover which teams are available | `using-ecosystem` |
| Need to create a new team definition | Use `template/team-template.md` and `spec/team-spec.md` |
| Need to dispatch agents without a team file | `dispatching-parallel-agents` or `subagent-driven-development` |
| Need to verify work before closing a phase | `verification-before-completion` |

---
name: agent-teams
description: "Pre-composed agent team library. Use when the user asks which teams are available, what a team does, when to pick one team over another, or to browse multi-agent compositions. Catalogs ready-to-run teams (development team, review squad, war room) with their purpose, agent roster, workflow type, and when to use each. The actual dispatching is handled by the dispatching-agent-teams skill."
user-invocable: true
argument-hint: "[optional: team name to describe]"
---

# Agent Teams Library

A catalog of pre-composed agent teams. Each team has a roster of agents, a coordination workflow, and entry and exit criteria. Pick a team and dispatch it with the `dispatching-agent-teams` skill.

## Available teams

| Team | Workflow | Lead | Use when |
|---|---|---|---|
| [development-team](teams/development-team.md) | hybrid | Product Manager | Delivering a full feature from requirements to merged PR |
| [review-squad](teams/review-squad.md) | parallel | Reviewer | Multi-perspective code review before merging significant changes |
| [war-room](teams/war-room.md) | war-room | Architect | Structured technical debate that ends in a decision (architecture choice, tech selection, design trade-off) |

## How to pick a team

| Situation | Recommended Team |
|---|---|
| "I need to ship feature X end-to-end" | development-team |
| "Code review this PR thoroughly" | review-squad |
| "We need to decide between X and Y" | war-room |
| "Just review the diff" | Skip the team, delegate to `reviewer` agent directly |
| "Investigate this area" | Skip the team, delegate to `investigator` agent directly |

If no team fits the work, skip the team and chain individual agents (see the `using-ecosystem` skill's chaining patterns).

## Team file format

Every team file follows the team specification (`spec/team-spec.md`):

- Frontmatter: `name`, `description`, `lead`, `agents`, `skills`, `workflow`
- Body: Purpose, Workflow, Entry/Exit Criteria, Coordination Rules, Spawning

The dispatcher reads these fields to resolve the team, check entry criteria, and run the workflow in the right spawning mode.

## Authoring your own team

User-authored teams live at the project root in `teams/{name}.md`. The dispatcher discovers project teams before falling back to the bundled library here, so a project team can override a bundled one with the same name.

See `spec/team-spec.md` for the full team format and `template/team-template.md` for a starter.

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Run a team you picked from this catalog | `dispatching-agent-teams` |
| Discover what agents and skills are available | `using-ecosystem` |
| Decide between teams and ad-hoc agent chaining | `using-ecosystem` |
| Author a new team definition | `spec/team-spec.md` and `template/team-template.md` |

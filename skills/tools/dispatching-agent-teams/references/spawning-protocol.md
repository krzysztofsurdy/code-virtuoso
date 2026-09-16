# Spawning protocol

Steps for each spawning mode. The dispatching skill detects the mode, and the lead agent follows the protocol below.

## Contents

- [Peer mode](#peer-mode)
- [Sequential mode](#sequential-mode)
- [Inline mode](#inline-mode)
- [Workflow-specific protocols](#workflow-specific-protocols)

## Peer mode

Peer mode is the preferred mode when the platform supports agent-to-agent messaging and shared task lists. Teammates work as peers. They claim tasks, message each other, and coordinate through the shared task list without the lead as intermediary.

### Setup

1. Read the team file frontmatter to get `lead`, `agents`, `skills`, and `workflow`.
2. Create a new team with the lead as coordinator.
3. Add each non-lead agent as a teammate.
4. For each workflow phase, create a shared task:
   - Task title: the phase name from the workflow section
   - Task description: the phase instructions from the team file body
   - Dependencies: set `blockedBy` to the previous phase's task (for sequential phases), or no blockers (for parallel phases)
5. Preload the team's skills so all teammates have access to reference material.

### Execution

1. Lead assigns the first unblocked task to the appropriate teammate (or claims it).
2. As tasks complete, dependent tasks unblock.
3. Teammates message each other for clarifications described in the coordination rules (e.g., "Frontend asks Backend about API response shape").
4. Lead monitors progress and resolves conflicts or blockers.
5. When a gate exists between phases (e.g., "Architect must approve design"), the lead verifies the gate before unblocking the next task.

### Completion

1. All tasks are marked complete.
2. Lead runs exit criteria checks.
3. Lead writes a summary of all phase outputs.

## Sequential mode

Sequential mode is the fallback when the platform supports sub-agent spawning but not peer messaging. The lead runs each phase by dispatching one sub-agent at a time.

### Setup

1. Read the team file frontmatter and body.
2. Preload the team's skills into the current session.
3. Build a phase queue from the workflow section.

### Execution

For each phase in order:

1. **Build the brief**: Combine the phase description from the team file with:
   - Outputs from all previous phases
   - The skills this agent should consult (from the Skill Usage section)
   - Any coordination constraints (e.g., "must produce an API contract document")
2. **Spawn the agent**: Dispatch the phase's agent as a sub-agent with the brief. If the agent writes files, use worktree isolation.
3. **Collect output**: When the sub-agent completes, capture its output.
4. **Check gates**: If the team file defines a gate before the next phase, verify it. If the gate fails, report to the user and do not proceed.
5. **Parallel phases**: If the workflow marks two phases as parallel (e.g., "Backend Dev + Frontend Dev"), spawn both sub-agents simultaneously and wait for both to complete before proceeding.

### Completion

1. All phases executed.
2. Lead runs exit criteria checks against accumulated outputs.
3. Lead reports results to the user.

## Inline mode

Inline mode is the last resort when no delegation is available. The lead executes all phases in the current session.

### Execution

1. Read the team file body.
2. For each workflow phase:
   a. Adopt the role described for that phase's agent.
   b. Consult the skills listed for that agent.
   c. Produce the expected output before moving on.
   d. If a gate exists, self-verify before proceeding.
3. Report results at the end.

### Limitations

- No parallel execution (all phases are sequential).
- Context accumulates in a single session (large teams risk context bloat).
- No isolation between phases (earlier phases' context may bleed into later ones).

For complex team workflows, inline mode works much worse than peer or sequential mode. If inline mode is the only option, recommend moving to a platform with sub-agent support.

## Workflow-specific protocols

The protocols above cover the general case. Certain workflow types require additional handling.

### Parallel with differential briefs

Some parallel teams need each agent to receive different context. The team file's Coordination Rules section specifies per-agent context restrictions. When dispatching:

1. Read the Coordination Rules for any context restrictions (e.g., "Cold Reviewer must not receive acceptance criteria").
2. Build a **separate brief per agent** in the parallel phase, including or excluding context as the rules specify.
3. Spawn agents simultaneously, each with its own brief.
4. The lead collects all outputs and handles deduplication or synthesis as described in the Workflow section.

This applies to teams like `review-squad` where agents deliberately operate at different context levels.

### War room

War-room teams run a multi-round debate, not a production pipeline. They differ from standard workflows in two ways:

**Perspective-only agents.** All non-lead agents in a war room produce text responses. They do not use tools, read files, or run commands during the debate. The brief for each agent should include: the decision question, constraints, and any prior positions (in challenge rounds). It should explicitly instruct the agent to respond with its perspective only.

**Multi-pass rounds.** War-room workflows have multiple passes over the same agents:

1. **Position round**: Spawn each agent once with the framed question. Collect their positions.
2. **Challenge round**: Spawn each agent again, this time including all positions from round 1. Ask each to challenge one other position.
3. **Synthesis**: Lead reads all positions and challenges and produces the synthesis. No spawning is needed, because the lead does this inline.

In peer mode, these rounds map to two task waves: position tasks (no dependencies) followed by challenge tasks (blocked by all position tasks).

In sequential mode, the lead spawns all agents for positions, collects outputs, then spawns all agents again for challenges with the accumulated positions.

In inline mode, the lead plays each agent's position, then each agent's challenge, then synthesizes.

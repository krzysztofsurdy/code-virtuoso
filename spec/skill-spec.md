# Skill Specification

This document defines the conventions for skills in the code-virtuoso marketplace. It extends the [Agent Skills Specification](https://agentskills.io/specification) with project-specific rules.

## Contents

- [Directory structure](#directory-structure)
- [SKILL.md format](#skillmd-format)
- [Categories](#categories)
- [References](#references)
- [Agents](#agents)
- [Progressive disclosure](#progressive-disclosure)
- [Guided phases](#guided-phases)
- [Platform-specific notes](#platform-specific-notes)
- [Content guidelines](#content-guidelines)
- [Naming conventions](#naming-conventions)

## Directory structure

```
skill-name/
  SKILL.md              # Required
  references/            # Optional - detailed reference material
  agents/                # Optional - agents that use this skill
  scripts/               # Optional - executable code
  assets/                # Optional - static resources
```

## SKILL.md format

### Frontmatter

```yaml
---
name: skill-name
description: What this skill does and when to use it.
user-invocable: false
---
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Must match the parent directory name. Lowercase, hyphens only, 1-64 chars. |
| `description` | Yes | What the skill does and when to use it. Max 1024 chars. Include trigger keywords. |
| `user-invocable` | No | Set to `false` for knowledge/reference skills not meaningful as slash commands. Omit for interactive skills. |
| `argument-hint` | No | Hint text shown after the slash command (e.g. `"[optional: agent-name]"`). |
| `license` | No | License name or reference to a bundled license file. |
| `metadata` | No | Arbitrary key-value mapping for additional metadata. |

### Body content

The markdown body after frontmatter contains skill instructions. Keep under 500 lines. Move detailed content to `references/`.

## Categories

Skills are organized into three categories:

| Category | Path | Purpose |
|----------|------|---------|
| `knowledge` | `skills/knowledge/` | Reference material on concepts, patterns, and practices |
| `frameworks` | `skills/frameworks/` | Framework-specific knowledge and component guides |
| `tools` | `skills/tools/` | Interactive workflows and setup utilities |

## References

- Place in `references/` subdirectory
- Keep each file focused on a single topic, between 100 and 700 lines
- Start any file over 100 lines with a `## Contents` list linking its H2 sections
- Use relative markdown links from SKILL.md: `[Topic](references/topic.md)`
- Agents load these on demand, so smaller files mean less context usage

## Agents

Agents that belong to a skill live in the skill's `agents/` subdirectory. See [agent-spec.md](agent-spec.md) for the agent format.

## Progressive disclosure

Skills load in three levels:

1. **Metadata** (~100 tokens) - `name` and `description` loaded at startup for all skills
2. **Instructions** (<5000 tokens) - Full SKILL.md body loaded when skill is activated
3. **Resources** (as needed) - Files in references/, scripts/, assets/ loaded only when required

## Guided phases

Interactive skills with 3+ phases where LLMs tend to rush through steps can use a **guided phase** structure. This is an internal pattern. Users get a better-paced interaction without needing to know how the files are organized.

### When to use

- The skill has 3+ distinct phases that each need user input before proceeding
- LLMs tend to merge, skip, or rush through the phases when they are inline
- Each phase has a natural checkpoint where the user should confirm before continuing

Skills with phases that share heavy context, or where inline flow works well, should keep phases inline in SKILL.md. Guided phases help when separating the phases prevents rushing. They do not help when they only reorganize the file.

### Directory structure

```
skill-name/
  SKILL.md              # Shared rules, principles, phase listing
  phases/               # One file per phase
    01-phase-name.md
    02-phase-name.md
    03-phase-name.md
  references/           # Deep-dive material (unchanged)
```

### SKILL.md role

In a guided-phase skill, SKILL.md holds shared rules, principles, and context ONCE. It does NOT duplicate phase instructions. It lists phases with one-line descriptions and links. On activation, the agent loads SKILL.md first, then enters phases sequentially.

### Phase file structure

Each phase file is lean (40-80 lines). It contains:

1. **Header** with phase number, name, and progress indicator
2. **Purpose** - one sentence describing what this phase accomplishes
3. **Steps** - numbered execution instructions
4. **Gate** - conditions for advancing, and the question to ask the user

The gate is what makes the structure work. Every phase file ends with a gate that forces the agent to stop and wait for user confirmation before loading the next phase.

See `template/phase-template.md` for the starter template.

## Platform-specific notes

The skill body must remain portable - it describes capabilities ("team creation tools", "interactive prompts", "file search") without naming any specific platform's tool, API, or runtime feature. Platform-specific guidance lives in a clearly marked optional section so it can be skipped on platforms it does not apply to.

### When to use

Use a Platform Notes section when:

- The skill describes a capability that platforms implement under different names (e.g., team creation, agent dispatching, interactive prompts)
- One platform has a strong convention or required tool that, if not used, leads to poor behavior on that platform (e.g., a platform has no team-creation tool, so teammates must be spawned as named agents)
- Skipping the platform-specific behavior would cause the skill to misbehave on that platform

Do NOT use Platform Notes to make the skill platform-specific. The body must still work on any agent CLI. Platform Notes are appendix-style hints, not the primary instructions.

### Structure

Place a `## Platform Notes` section near the bottom of the SKILL.md (before Reference Files and Integration sections). Use a table with one row per platform.

```markdown
## Platform Notes

Platform-specific tool names and conventions for executing this skill. The instructions above stay portable; the table below maps abstract capabilities to concrete tools per platform.

| Platform | Convention |
|---|---|
| Claude Code | Agent teams are experimental and need `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`. There is no `TeamCreate` tool. Spawn each teammate with the `Agent` tool and a `name`, and message teammates with `SendMessage` |
| Cursor | No peer-messaging team feature is documented. Subagents run in parallel and return results to the parent, so use sequential mode |
| Other | Use the platform's equivalent for creating a multi-agent team |
```

Keep entries factual and short. If a platform's behavior is unknown, list it with `(TBD)` rather than guessing. The point is to record verified conventions, not speculation.

### Rules

- Platform Notes never replace portable instructions in the body
- One section per SKILL.md, near the bottom
- One row per platform in a table
- Reference platform names as the user would recognize them (Claude Code, Cursor, Windsurf, Copilot)
- Do not write platform-specific behavior into the Process or Rules sections of the skill body

## Content guidelines

- Write original content. External sources serve as inspiration only.
- Do not mention authors, books, or specific sources by name.
- Do not copy content verbatim from external resources.
- Use generic template names (e.g. "Focus / Impact / Confirmation" not "Author's Template").
- Keep language concise and actionable.

## Naming conventions

- Lowercase letters, numbers, and hyphens only
- Must not start or end with a hyphen
- Must not contain consecutive hyphens
- Name must match the parent directory name

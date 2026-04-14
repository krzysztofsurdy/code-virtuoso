# Contributing

Code Virtuoso is a collection of AI agent skills and sub-agent definitions built on the [Agent Skills](https://agentskills.io) open standard. Contributions include new skills, new agents, improvements to existing content, and structural fixes.

## Getting Started

There is no build step, test suite, or runtime. "Development" means writing and editing markdown files that follow specific conventions. To contribute:

1. Clone the repository
2. Read this guide and the [README](README.md) for project context
3. Browse existing skills in `skills/` and agents in `agents/` to understand the format and depth expected
4. Check the `template/` directory for starter templates (`SKILL.md`, `agent.md`)
5. Check the `spec/` directory for format specifications (`skill-spec.md`, `agent-spec.md`, `agent-skills-spec.md`, `plugin-spec.md`)

## Project Structure

```
agents/              -- Sub-agent definitions (specialist and role agents)
skills/
  knowledge/         -- Conceptual reference material (SOLID, testing, debugging, etc.)
  tools/             -- Interactive tools (agentic-rules-writer, ticket-writer, agent-creator, plugin-creator)
  playbooks/         -- Step-by-step operational procedures (PHP upgrade, etc.)
  roles/             -- Team role reference skills (product manager, architect, etc.)
  frameworks/{name}/ -- Framework-specific skills (Symfony, Django, LangChain)
spec/                -- Format specifications
template/            -- Starter templates
.claude-plugin/      -- Marketplace configuration (Claude Code format; adaptable to other platforms)
```

See the [README](README.md) for the full directory tree and skill tables.

## Adding a New Skill

### 1. Choose the Right Category

| Category | When to use | Example |
|---|---|---|
| `skills/knowledge/` | Concepts, principles, reference material | SOLID, design patterns, testing theory |
| `skills/tools/` | Interactive tools that generate output | Rules writer |
| `skills/playbooks/` | Step-by-step procedures for recurring tasks | PHP upgrade, dependency updates |
| `skills/roles/` | Team role definitions with responsibilities and workflows | Product manager, QA engineer |
| `skills/frameworks/{name}/` | Framework-specific component references or upgrade guides | Symfony components, Django components |

### 2. Create the Directory Structure

```
skills/{category}/your-skill-name/
  SKILL.md
  references/
    topic-a.md
    topic-b.md
```

Every skill has a `SKILL.md` at the root and a `references/` directory for deep-dive content. Reference files do not have frontmatter.

### 3. Write SKILL.md

#### Frontmatter Fields

```yaml
---
name: your-skill-name          # Kebab-case, matches directory name
description: What this skill does. Use when {trigger condition}.
user-invocable: false           # true only if the skill is meant to be called directly by users
allowed-tools: Read Grep Glob Bash  # Optional: restrict tool access (platform-specific, see note below)
---
```

The `description` field is the most important field for discoverability. It controls when AI agents activate the skill. Write it to be keyword-rich and trigger-oriented.

**Note on platform-specific frontmatter:** The `name`, `description`, and `user-invocable` fields are part of the [Agent Skills](https://agentskills.io) open standard and work across platforms. The `allowed-tools` field is a platform-specific extension (e.g., Claude Code uses tool names like `Read`, `Grep`, `Glob`, `Bash`; other platforms may use different names or not support tool restrictions). If your skill needs tool restrictions, document them and adapt to your platform.

#### user-invocable Guidelines

The `user-invocable` field controls whether a skill appears as a runnable command (e.g., `/skill-name` or `@skill-name` depending on platform). Set it based on the skill category:

| Category | `user-invocable` | Reason |
|---|---|---|
| `knowledge/` | `false` | Background reference, auto-loaded by context or agents |
| `frameworks/` | `false` | Background reference, auto-loaded |
| `roles/` | `false` | Background reference, loaded by agents |
| `playbooks/` | `true` | User runs these as step-by-step procedures |
| `tools/` | `true` | User runs these directly to generate output |

Every SKILL.md **must** include this field. If omitted, behavior varies by platform.

#### No Provider-Specific Models

Do not include a `model` field in skill or agent definitions. Model selection is a user/platform decision, not a content decision. Hardcoding provider-specific model names (e.g., `sonnet`, `gpt-4o`, `gemini-pro`) makes skills and agents non-portable. Users configure model preferences in their own platform settings.

#### Description Guidelines

Descriptions should be 1-3 sentences that pack in relevant keywords and trigger conditions. The pattern is: what it covers + when to use it.

Good example (language-specific skill):

> Comprehensive skill for all 26 Gang of Four design patterns with idiomatic implementations and real-world examples. Use when the user asks to apply a design pattern, refactor code using patterns, choose between competing patterns, or review existing pattern usage.

Good example (procedural skill):

> Version upgrade guide -- step-by-step process for upgrading runtime/framework versions, automated refactoring, compatibility checking, breaking changes per version, and testing strategies. Use when planning or executing a version upgrade.

Bad example:

> A skill about design patterns.

#### SKILL.md Structure

Follow this order:

1. **Title** -- one paragraph summary of core philosophy
2. **Core Principles** -- table with `| Principle | Meaning |` columns
3. **Main sections** -- tables, commands, pattern indexes (varies by skill type)
4. **Quick Reference: Checklist** -- step-by-step checklist with `- [ ]` items
5. **Reference Files** -- table linking to `references/` files with `| Reference | Contents |` columns
6. **Integration with Other Skills** -- table with `| Situation | Recommended Skill |` columns

Minimal example:

```markdown
---
name: my-skill
description: One-line description. Use when {trigger condition}.
user-invocable: false
---

# My Skill

One paragraph summary.

## Core Principles

| Principle | Meaning |
|---|---|
| **Principle one** | What it means in practice |

## Reference Files

| Reference | Contents |
|---|---|
| [topic-a](references/topic-a.md) | Deep dive into topic A |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| When you need X | `other-skill` |
```

**Note on skill references:** In the Integration table, reference skills by name. How users invoke skills depends on their platform (e.g., `/skill-name` as a slash command in Claude Code, `@skill-name` in other tools, or automatic activation based on context).

### 4. Add Reference Files

Reference files live in `references/` and contain the deep content: code examples, detailed workflows, comparison tables. SKILL.md provides the overview; references provide the depth. This is the **progressive disclosure** pattern -- agents load SKILL.md first and only read reference files when they need detail on a specific topic.

### 5. Update marketplace.json (MANDATORY)

Every skill change requires a marketplace.json update. This is non-negotiable.

Add your skill path to the appropriate plugin's `skills` array in `.claude-plugin/marketplace.json`:

```json
{
  "name": "knowledge-virtuoso",
  "skills": [
    "./skills/knowledge/existing-skill",
    "./skills/knowledge/your-new-skill"
  ]
}
```

If no existing plugin fits your skill, create a new plugin entry. See [Marketplace Configuration](#marketplace-configuration) for details.

### 6. Update README.md

Add your skill to the appropriate table in `README.md` and update the Repository Structure tree if you created a new directory.

## Updating Existing Skills

- Make your content changes
- Bump the version in `marketplace.json` (see [Version Bumping Rules](#version-bumping-rules))
- Test that the skill activates correctly after your changes

## Adding a New Agent

Agents are sub-agent definitions usable by AI coding platforms that support delegation (e.g., Claude Code [sub-agents](https://code.claude.com/docs/en/sub-agents), Cursor agents, GitHub Copilot).

For a guided, interactive design flow, run the `agent-creator` skill in `skills/tools/agent-creator/`. This guide is the reference for contributors and reviewers; the canonical specification lives in [`spec/agent-spec.md`](spec/agent-spec.md).

### 1. Choose the Right Archetype

Pick the archetype that matches the scope of responsibility, not the size of the task.

| Archetype | When to use | Example |
|---|---|---|
| **Specialist** | Single, repeatable task type. Typically stateless and read-only. | Investigator, Reviewer, Dependency Auditor |
| **Role** | Entire domain of responsibility, often with persistent project memory. | Product Manager, Architect, QA Engineer |
| **Team-Lead** | Coordinates multiple sub-agents running in parallel. | Release lead, parallel-review dispatcher |

Decision tree:

1. Does the agent do **one repeatable task** with a clear result? -> **Specialist**
2. Does the agent **own a domain** a human team member would hold? -> **Role**
3. Does the agent **spawn and coordinate** other agents working in parallel? -> **Team-Lead**

See [`agent-creator/references/archetypes.md`](skills/tools/agent-creator/references/archetypes.md) for worked examples and anti-patterns.

### 2. Create the Agent Definition File

Create a Markdown file at the top level of `agents/`:

```
agents/your-agent-name.md
```

Naming rules:

- Lowercase letters, digits, and hyphens only; start with a letter
- File name matches the `name` frontmatter field (e.g. `migration-planner.md`)
- Describe the **role**, not the task (`reviewer`, not `review-pr-123`)
- Avoid generic names (`agent1`, `helper`, `assistant`)

### 3. Agent Frontmatter

```yaml
---
name: your-agent-name
description: What this agent does. Delegate when {trigger condition}.
tools: Read, Grep, Glob, Bash
isolation: worktree              # Optional: only when the agent modifies files
memory: project                  # Optional: only for role agents that accumulate context
skills:
  - related-skill-name           # Optional: preload skills at startup
---
```

| Field | Required | Portable | Notes |
|---|---|---|---|
| `name` | Yes | Yes | Matches the filename without `.md` |
| `description` | Yes | Yes | Pack with trigger phrases ("delegate when", "use after"). No marketing adjectives |
| `tools` | Yes | No | Allowlist the minimum needed. Never rely on inheritance |
| `disallowedTools` | No | No | Denylist applied before `tools` resolves |
| `isolation` | No | No | Set to `worktree` if and only if the agent creates or modifies files |
| `memory` | No | No | `user`, `project`, or `local`. Use for role agents that need cross-session context |
| `skills` | No | Yes | Reference by `name` field, not path. Keep to four or fewer |
| `mcpServers` | No | No | Scope MCP servers to this agent, keeping descriptions out of the parent conversation |
| `permissionMode` | No | No | Override permission prompts. Use sparingly |
| `model` | No | -- | **Do not include.** Model selection is a user/platform concern |

The same [no provider-specific models](#no-provider-specific-models) rule applies to agents as to skills.

See [`agent-creator/references/frontmatter-fields.md`](skills/tools/agent-creator/references/frontmatter-fields.md) for the full reference, including portability notes and common combination mistakes.

### 4. Agent Body (System Prompt)

The body is the agent's system prompt. Follow the five-section contract:

```markdown
You are a [role]. You [one-sentence responsibility].

## Input
What the agent receives when delegated to.

## Process
1. Numbered action-verb steps (3-7 steps).

## Rules
- Short imperative constraints.
- Explicit out-of-scope behaviours.

## Output
A concrete template the agent fills in. Not prose.
```

Body guidelines:

- Keep under 100 lines for most agents; under 200 for complex role agents
- Do not duplicate the tool list from the frontmatter
- Do not include persona bloat or provider-specific phrasing ("As Claude...")
- See `agents/investigator.md` or `agents/implementer.md` for complete examples

See [`agent-creator/references/system-prompts.md`](skills/tools/agent-creator/references/system-prompts.md) for worked examples per archetype and common rejection reasons.

### 5. Choose Tool Permissions

Start read-only and add write tools only when the workflow demands them.

| Archetype | Typical allowlist |
|---|---|
| Investigator / Reviewer / Auditor | `Read, Grep, Glob, Bash` |
| Doc Writer | `Read, Grep, Glob, Bash, Edit, Write` + `isolation: worktree` |
| Implementer / Dev Role | `Read, Grep, Glob, Bash, Edit, Write` + `isolation: worktree` |
| Team-Lead | `Read, Grep, Glob, Bash, Agent(specialist-a, specialist-b)` |

Rules:

- Every `Edit`/`Write` capability must pair with `isolation: worktree`
- `Agent(...)` allowlist pins which sub-agent types a team-lead can spawn
- Never leave `tools` unset -- agents that inherit all tools are not least-privileged

See [`agent-creator/references/tool-selection.md`](skills/tools/agent-creator/references/tool-selection.md) for the full decision tree.

### 6. Update marketplace.json (MANDATORY)

Every new agent requires a `marketplace.json` update. This is non-negotiable.

- Add the agent path to the `agents-virtuoso` plugin's `agents` array
- If it is a role agent, also add the matching role skill to `agents-virtuoso`
- Bump the marketplace version per the [Version Bumping Rules](#version-bumping-rules)

Example for a specialist:

```json
{
  "name": "agent-reviewer",
  "description": "...",
  "source": "./",
  "strict": false,
  "agents": ["./agents/reviewer.md"]
}
```

Example for a role (skill + agent paired):

```json
{
  "name": "role-architect",
  "description": "...",
  "source": "./",
  "strict": false,
  "skills": ["./skills/roles/architect"],
  "agents": ["./agents/architect.md"]
}
```

### 7. Update README.md and AGENTS.md

- Add a row to the appropriate agent table in [README.md](README.md) (Specialist Agents or Role Agents)
- Add a row to the matching table in [AGENTS.md](AGENTS.md), including a short description of when to delegate
- If the agent introduces a new category of work, update the top-level "Agents" bullet in README.md

### 8. Validate Before Committing

Run through the pre-publish checklist: [`agent-creator/references/validation.md`](skills/tools/agent-creator/references/validation.md).

The most common rejection reasons:

- Description lacks trigger phrases
- Tool allowlist is missing or overly permissive
- Agent modifies files but has no `isolation: worktree`
- Output section is vague prose instead of a template
- Body contains provider-specific or tool-specific phrasing
- Agent does two things -- should be split into two agents

## Updating Existing Agents

- Make your content changes
- Re-run the validation checklist in [`agent-creator/references/validation.md`](skills/tools/agent-creator/references/validation.md)
- Bump the version in `marketplace.json` (see [Version Bumping Rules](#version-bumping-rules))
- If the change alters the agent's output contract or tool permissions, note it in the commit message so reviewers can spot callers that may need updating

## Adding a New Plugin

There are two distinct uses of the word "plugin" in this repository. Know which one you are working on before you start.

| Meaning | File | Purpose |
|---|---|---|
| **Marketplace entry** | an object inside `.claude-plugin/marketplace.json` | Bundles existing skills and/or agents from this repo for installation. Most "add a plugin" work is this. |
| **Standalone Claude Code plugin** | its own directory with `.claude-plugin/plugin.json` | A self-contained plugin that can live in a separate repo and be distributed through any marketplace. |

For a guided, interactive scaffold, run the `plugin-creator` skill in `skills/tools/plugin-creator/`. This guide is the reference for contributors and reviewers; the canonical specification lives in [`spec/plugin-spec.md`](spec/plugin-spec.md).

### Adding a Marketplace Entry

Use this path when you want to expose existing skills or agents in this repo as an installable bundle.

1. Open `.claude-plugin/marketplace.json`
2. Add a new object to the `plugins` array following the [Plugin Naming Convention](#plugin-naming-convention) and [Distribution Tiers](#plugin-distribution-tiers)
3. Use `"source": "./"` and `"strict": false` -- the whole repo is the plugin source
4. Reference existing skill directories in `skills` and existing agent files in `agents`
5. Bump `metadata.version` per [Version Bumping Rules](#version-bumping-rules) (minor bump for a new plugin)
6. Update README.md if the new plugin introduces a new category

Minimal example:

```json
{
  "name": "tool-my-new-tool",
  "description": "Interactive tool that ...",
  "source": "./",
  "strict": false,
  "skills": ["./skills/tools/my-new-tool"]
}
```

See [Marketplace Configuration](#marketplace-configuration) below for the full rules.

### Adding a Standalone Claude Code Plugin

Use this path when the plugin should be its own repo or its own directory outside this marketplace -- for example, when shipping hooks, MCP servers, or LSP servers that do not belong inside the code-virtuoso content library.

1. **Scaffold with `plugin-creator`**. The skill generates the full directory structure, writes a validated `plugin.json`, and wires up any components you select (skills, agents, hooks, MCP servers, LSP servers, bin, output styles, default settings).
2. **Place the plugin directory** at the top of the plugin's own repository, or anywhere outside `skills/` and `agents/` in this repo.
3. **Follow [`spec/plugin-spec.md`](spec/plugin-spec.md)** for structural rules. Critical points:
   - Only `plugin.json` belongs inside `.claude-plugin/`. Every other directory (`skills/`, `agents/`, `hooks/`, etc.) lives at the plugin root.
   - All paths in `plugin.json` must be relative and start with `./`.
   - Use `${CLAUDE_PLUGIN_ROOT}` for bundled resources and `${CLAUDE_PLUGIN_DATA}` for state that must survive updates.
   - Plugin-shipped agents cannot set `hooks`, `mcpServers`, or `permissionMode` -- these are blocked for security.
4. **Validate locally** before committing:
   ```
   claude --plugin-dir ./your-plugin
   claude plugin validate
   ```
5. **Add a marketplace entry** if you want this marketplace to distribute it -- the entry's `source` can be a relative path (same repo), a `github` object, a `url` object, a `git-subdir` object, or an `npm` object. See `plugin-creator/references/marketplace-manifest.md` for all source types.
6. **Seed a `CHANGELOG.md`** with the initial `1.0.0` release entry. Standalone plugins track their own version independently of the marketplace version.

### Common Mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| Putting `skills/`, `agents/`, or `hooks/` inside `.claude-plugin/` | Components are invisible to Claude Code | Move them to the plugin root |
| Absolute paths in `plugin.json` or hook commands | Works locally, breaks once cached | Use `./` paths or `${CLAUDE_PLUGIN_ROOT}` |
| Referencing files outside the plugin root (`../shared`) | Files are not copied to the plugin cache | Use symlinks; they are preserved |
| Setting `version` in both `plugin.json` and the marketplace entry | Maintenance trap; `plugin.json` wins on conflict | Pick one authoritative location |
| Reserved marketplace name (e.g. `claude-plugins-official`) | Installation rejected | See reserved names in `plugin-creator/references/marketplace-manifest.md` |
| Content changed but version not bumped | Users never see the update due to caching | Always bump the version per [Version Bumping Rules](#version-bumping-rules) |

## Updating Existing Plugins

- Make your content changes (plugin directory, `plugin.json`, or the marketplace entry as appropriate)
- Re-run `claude plugin validate` if you touched a standalone plugin
- Bump the version in the authoritative location:
  - Marketplace entry: bump `metadata.version` in `marketplace.json`
  - Standalone plugin: bump `version` in `plugin.json`
  - Never both for the same plugin
- Record the change in the plugin's `CHANGELOG.md` if it has one
- If the change removes a skill, renames a skill, or changes a hook event, bump the **major** version -- these are breaking for installed users

## Marketplace Configuration

The file `.claude-plugin/marketplace.json` defines how skills and agents are packaged for installation. Each plugin groups related skills and/or agents that users can install together.

```json
{
  "name": "plugin-name",
  "description": "What this plugin provides",
  "source": "./",
  "strict": false,
  "skills": ["./skills/category/skill-name"],
  "agents": ["./agents/agent-name.md"]
}
```

**When to create a new plugin vs. add to an existing one:**

- Add to an existing plugin when your skill fits its theme (e.g., a new knowledge skill goes into `knowledge-virtuoso`)
- Create a new plugin only when adding an entirely new category that does not fit any existing bundle

### Plugin Naming Convention

All plugins follow the `{category}-virtuoso` pattern. One plugin per `skills/` subdirectory, plus one for agents.

| Plugin | Maps to | Contains |
|---|---|---|
| `knowledge-virtuoso` | `skills/knowledge/` | All knowledge reference skills |
| `tools-virtuoso` | `skills/tools/` | All interactive tool skills |
| `frameworks-virtuoso` | `skills/frameworks/` | All framework-specific skills (Symfony, Django, LangChain) |
| `playbooks-virtuoso` | `skills/playbooks/` | All operational playbook skills |
| `agents-virtuoso` | `skills/roles/` + `agents/` | All 15 agents + all 7 role skills |

When adding a new skill:
- Identify which `skills/` subdirectory it belongs to
- Add the skill path to the matching `*-virtuoso` plugin in `marketplace.json`
- Bump the version

When adding a new role:
- Create the role skill in `skills/roles/{name}/`
- Create the agent in `agents/{name}.md`
- Add both to `agents-virtuoso`

When adding a new specialist agent:
- Create the agent in `agents/{name}.md`
- Add to `agents-virtuoso`

## Version Bumping Rules

The version field lives in `metadata.version` inside `marketplace.json`.

| Change type | Version bump | Example |
|---|---|---|
| Content updates to existing skills | Patch | 7.13.0 -> 7.13.1 |
| New skills or agents added | Minor | 7.13.0 -> 7.14.0 |
| Restructuring, renames, breaking changes | Major | 7.13.0 -> 8.0.0 |

## Commit Conventions

- No AI co-author lines in commits
- Descriptive commit messages summarizing what was added or changed
- One logical change per commit
- Example: `Add Kubernetes deployment skill with 5 reference files`
- Example: `Update design-patterns skill with Specification pattern`

## Quality Standards

Skills should be production-grade reference material, not tutorials. They are consumed by AI agents that need precise, actionable information.

| Guideline | Target |
|---|---|
| Reference files | 100-700 lines each |
| SKILL.md | Under 500 lines (use progressive disclosure) |
| Tables | Use for all structured data (comparisons, commands, options) |
| Cross-references | Include an Integration section linking to related skills |
| Code examples | Idiomatic for the target language/framework, using current stable versions |
| Principles table | Required in every SKILL.md -- sets the mindset before details |
| Frontmatter | Only in SKILL.md and agent files, never in reference files |

### Language and Provider Agnosticism

All content must be **language-agnostic** and **LLM provider-agnostic** by default. Do not assume a specific programming language, framework, or AI provider unless the skill explicitly targets one.

| Content type | Rule |
|---|---|
| Knowledge skills | Fully language-agnostic. Use pseudocode or multi-language examples. |
| Role skills | Fully agnostic. No language-specific code. |
| Agent definitions | No provider-specific model names. No platform-specific tool names in the body. |
| Framework skills (`frameworks/`) | Language/framework-specific by definition. Target latest stable version. |
| Playbooks | May be language-specific if the procedure is (e.g., PHP upgrade). State the scope clearly. |

**The only exceptions** are skills that explicitly exist for a specific language, framework, or LLM provider (e.g., `symfony-components`, `django-components`, `php-upgrade`). These should state their scope in the description.

### Content Guidelines

- Show realistic, production-quality examples -- not toy code
- Include both the "happy path" and error handling where relevant
- Keep instructions actionable -- tell the agent what to do, not just what exists

### Research Process for New Skills

Before writing a new skill:

1. Search for existing skills: `npx skills find "{topic}"`
2. Search the web for official documentation and community best practices
3. Read 2-3 existing skills in this project to match structure and depth
4. Use the template in `template/SKILL.md` as a starting point

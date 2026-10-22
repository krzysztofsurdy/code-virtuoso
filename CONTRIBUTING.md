# Contributing

Code Virtuoso is a collection of AI agent skills and sub-agent definitions built on the [Agent Skills](https://agentskills.io) open standard. Contributions include new skills, new agents, improvements to existing content, and structural fixes.

## Contents

- [Getting started](#getting-started)
- [Project structure](#project-structure)
- [Adding a new skill](#adding-a-new-skill)
- [Updating existing skills](#updating-existing-skills)
- [Adding a new agent](#adding-a-new-agent)
- [Adding a team](#adding-a-team)
- [Updating existing agents](#updating-existing-agents)
- [Adding a new plugin](#adding-a-new-plugin)
- [Updating existing plugins](#updating-existing-plugins)
- [Marketplace configuration](#marketplace-configuration)
- [Version bumping rules](#version-bumping-rules)
- [Commit conventions](#commit-conventions)
- [Quality standards](#quality-standards)

## Getting started

The skills and agents have no build step, test suite, or runtime: "development" means writing and editing markdown files that follow specific conventions. The exception is `plugins/`, which holds Claude Code plugins with hooks and scripts. Run the validators in `scripts/` before you commit. To contribute:

1. Clone the repository
2. Read this guide and the [README](README.md) for project context
3. Browse existing skills in `skills/` and agents in `agents/` to understand the format and depth expected
4. Check the `template/` directory for starter templates (`skill-template.md`, `agent-template.md`, `workflow-template.js`, `phase-template.md`)
5. Check the `spec/` directory for format specifications (`skill-spec.md`, `agent-spec.md`, `team-spec.md`, `plugin-spec.md`, `config-spec.md`, `artifacts.md`)

## Project structure

```
agents/              - Sub-agent definitions (specialist and role agents)
roles/{role}/        - Templates and checklists that role agents read by path (not skills)
workflows/           - Team workflow scripts for Claude Code (review-squad, development-team, war-room)
skills/
  knowledge/         - Decision rules and pitfalls (security, debugging, agent orchestration, design references)
  tools/             - Interactive generators and headless agent wrappers
  playbooks/         - Step-by-step operational procedures (ticket delivery, TDD, PR feedback)
  frameworks/{name}/ - Framework-specific skills (Symfony, Django, LangChain, PHP, Vercel AI SDK)
  ai/                - Building with LLMs and agents (agent design, evals, observability, MCP servers)
codex/               - Codex support: generated agent TOML files and install notes
examples/ci/         - Example GitHub Actions workflows for headless agents
plugins/             - Self-contained Claude Code plugins with hooks and scripts (loop-virtuoso)
scripts/             - Repository validators and the Codex agent builder (python3 scripts/validate-*.py)
spec/                - Format specifications
template/            - Starter templates
.claude-plugin/      - Marketplace configuration (Claude Code format; adaptable to other platforms)
```

`plugins/` is the one deliberate exception to the agent-agnostic rule. Each plugin there is a Claude Code plugin with its own `.claude-plugin/plugin.json` and may ship hooks, scripts, commands, and skills. Everything else in the repo stays agent-agnostic.

See the [README](README.md) for the full directory tree and skill tables.

## Adding a new skill

### 1. Choose the right category

| Category | When to use | Example |
|---|---|---|
| `skills/knowledge/` | Decision rules, pitfalls, and reference the model needs on request | Security, debugging, agent orchestration |
| `skills/tools/` | Interactive tools that generate output, and headless agent wrappers | Rules writer, ticket writer |
| `skills/playbooks/` | Step-by-step procedures for recurring tasks | Ticket delivery, TDD, PR feedback |
| `skills/frameworks/{name}/` | Framework-specific version facts, opinions, and upgrade guides | Symfony components, PHP upgrade |
| `skills/ai/` | Building software with LLMs and agents | LLM evals, MCP server development |

There is no `skills/roles/`. Role material is reference files for a role agent, not a skill: put it in `roles/{role}/` and point to it from the agent (see [Adding a new agent](#adding-a-new-agent)).

### 2. Create the directory structure

```
skills/{category}/your-skill-name/
  SKILL.md
  references/
    topic-a.md
    topic-b.md
```

Every skill has a `SKILL.md` at the root and a `references/` directory for deep-dive content. Reference files do not have frontmatter.

### 3. Write SKILL.md

#### Frontmatter fields

```yaml
---
name: your-skill-name          # Kebab-case, matches directory name
description: What this skill does. Use when {trigger condition}.
user-invocable: false           # true only if the skill is meant to be called directly by users
disable-model-invocation: true  # optional: run by name only (see below)
allowed-tools: Read Grep Glob Bash  # Optional: restrict tool access (platform-specific, see note below)
---
```

The `description` field is the most important field for discoverability. It controls when AI agents activate the skill. Write it to be keyword-rich and trigger-oriented.

**Note on platform-specific frontmatter:** The `name`, `description`, and `user-invocable` fields are part of the [Agent Skills](https://agentskills.io) open standard and work across platforms. The `allowed-tools` field is a platform-specific extension (e.g., Claude Code uses tool names like `Read`, `Grep`, `Glob`, `Bash`; other platforms may use different names or not support tool restrictions). If your skill needs tool restrictions, document them and adapt to your platform.

#### user-invocable guidelines

The `user-invocable` field controls whether a skill appears as a runnable command (e.g., `/skill-name` or `@skill-name` depending on platform). Set it based on the skill category:

| Category | `user-invocable` | Reason |
|---|---|---|
| `knowledge/` | `false` | Background reference, auto-loaded by context or agents |
| `frameworks/` | `false` for reference skills, `true` for upgrade and update playbooks | Reference is auto-loaded background knowledge. `php-upgrade`, `symfony-upgrade` and `composer-dependencies` are step-by-step procedures a person starts on purpose |
| `ai/` | `false` | Background reference, auto-loaded |
| `playbooks/` | `true` | User runs these as step-by-step procedures |
| `tools/` | `true` | User runs these directly to generate output |

Every SKILL.md **must** include this field. If omitted, behavior varies by platform.

#### Run-by-name skills

Textbook references the model already knows (design patterns, SOLID, testing theory) and headless agent wrappers should not sit in every session's context. Mark them with both fields:

```yaml
user-invocable: true
disable-model-invocation: true
```

The skill stays installed and the user runs it as `/skill-name`. The model never loads it on its own, so it costs no context until called. The README lists these skills as "run by name". See [skill-spec.md](spec/skill-spec.md#run-by-name-skills).

#### No provider-specific models

Do not include a `model` field in skill or agent definitions. Model selection is a user/platform decision, not a content decision. Hardcoding provider-specific model names (e.g., `sonnet`, `gpt-4o`, `gemini-pro`) makes skills and agents non-portable. Users configure model preferences in their own platform settings.

#### Description guidelines

Descriptions should be 1-3 sentences that pack in relevant keywords and trigger conditions. The pattern is: what it covers + when to use it.

Good example (language-specific skill):

> Reference skill for all 26 Gang of Four design patterns with idiomatic implementations and real-world examples. Use when the user asks to apply a design pattern, refactor code using patterns, choose between competing patterns, or review existing pattern usage.

Good example (procedural skill):

> Version upgrade guide - step-by-step process for upgrading runtime/framework versions, automated refactoring, compatibility checking, breaking changes per version, and testing strategies. Use when planning or executing a version upgrade.

Bad example:

> A skill about design patterns.

#### SKILL.md structure

A skill must change what the model does. Keep what the model gets wrong without help: a procedure with gates, a decision rule, a version fact, a pitfall list. Leave out what it already knows.

1. **Title and summary** - one paragraph: the problem and what goes wrong without the skill
2. **Main sections** - procedure steps, decision tables, pitfalls (varies by skill type)
3. **Reference Files** - table linking to `references/` files, with when to open each one

**Core Principles**, **Quick Reference: Checklist**, and **Integration with Other Skills** sections are optional. Add one only when it holds information the body lacks. Sections of slogans and lists of sibling skills cost context and change nothing: an earlier version of this library required them, and testing showed that dropping them did not hurt results.

Minimal example:

```markdown
---
name: my-skill
description: One-line description. Use when {trigger condition}.
user-invocable: false
---

# My Skill

One paragraph summary.

## Pitfalls

- A mistake the model makes without this skill, and the fix.

## Reference Files

| Reference | Contents |
|---|---|
| [topic-a](references/topic-a.md) | Deep dive into topic A |
```

#### Evals

Show that the skill helps before you ship it: run the same task with and without the skill and compare the results. Keep the eval cases under `evals/`. The layout and the way to run them are described in `evals/README.md`. If the model already does the task right without the skill, do not add the skill.

### 4. Add reference files

Reference files live in `references/` and contain the deep content: code examples, detailed workflows, comparison tables. SKILL.md provides the overview; references provide the depth. This is the **progressive disclosure** pattern - agents load SKILL.md first and only read reference files when they need detail on a specific topic.

### 5. Update marketplace.json (MANDATORY)

Every skill change requires a marketplace.json update. This is non-negotiable.

Add your skill path to the appropriate plugin's `skills` array in `.claude-plugin/marketplace.json`. Skill-only bundles use `"source": "./skills"`, so paths are relative to `skills/`:

```json
{
  "name": "knowledge-virtuoso",
  "source": "./skills",
  "skills": [
    "./knowledge/existing-skill",
    "./knowledge/your-new-skill"
  ]
}
```

Headless wrapper skills that run an agent (`agent: agents-virtuoso:{name}`) belong to `agents-virtuoso` instead, whose source is `./`, so they are listed there as `./skills/tools/{name}`.

If no existing plugin fits your skill, create a new plugin entry. See [Marketplace Configuration](#marketplace-configuration) for details.

### 6. Update README.md

Add your skill to the appropriate table in `README.md` and update the Repository Structure tree if you created a new directory.

## Updating existing skills

- Make your content changes
- Bump the version in `marketplace.json` (see [Version Bumping Rules](#version-bumping-rules))
- Test that the skill activates correctly after your changes

## Adding a new agent

Agents are sub-agent definitions usable by AI coding platforms that support delegation (e.g., Claude Code [sub-agents](https://code.claude.com/docs/en/sub-agents), Cursor agents, GitHub Copilot).

For a guided, interactive design flow, run the `agent-creator` skill in `skills/tools/agent-creator/`. This guide is the reference for contributors and reviewers; the canonical specification lives in [`spec/agent-spec.md`](spec/agent-spec.md).

### 1. Choose the right archetype

Pick the archetype that matches the scope of responsibility, not the size of the task.

| Archetype | When to use | Example |
|---|---|---|
| **Specialist** | Single, repeatable task type. Typically stateless and read-only. | Investigator, Reviewer, Dependency Auditor |
| **Role** | Entire domain of responsibility, often with persistent project memory. The agent plus its `roles/{role}/` reference files. | Product Manager, Architect, QA Engineer |
| **Team-Lead** | Coordinates multiple sub-agents running in parallel. | Release lead, parallel-review dispatcher |

Decision tree:

1. Does the agent do **one repeatable task** with a clear result? -> **Specialist**
2. Does the agent **own a domain** a human team member would hold? -> **Role**
3. Does the agent **spawn and coordinate** other agents working in parallel? -> **Team-Lead**

See [`agent-creator/references/archetypes.md`](skills/tools/agent-creator/references/archetypes.md) for worked examples and anti-patterns.

### 2. Create the agent definition file

Create a Markdown file at the top level of `agents/`:

```
agents/your-agent-name.md
```

Naming rules:

- Lowercase letters, digits, and hyphens only; start with a letter
- File name matches the `name` frontmatter field (e.g. `migration-planner.md`)
- Describe the **role**, not the task (`reviewer`, not `review-pr-123`)
- Avoid generic names (`agent1`, `helper`, `assistant`)

### 3. Agent frontmatter

```yaml
---
name: your-agent-name
description: What this agent does. Delegate when {trigger condition}.
tools: Read, Grep, Glob, Bash
isolation: worktree              # Optional: only when the agent changes source code
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
| `isolation` | No | No | Set to `worktree` when the agent changes source code. Documentation-only writers and planning roles may run in place |
| `memory` | No | No | `user`, `project`, or `local`. Use for role agents that need cross-session context |
| `skills` | No | Yes | Reference by `name` field, not path. Keep to four or fewer. Names resolve across installed plugins, and a missing skill is skipped silently (see [agent-spec.md](spec/agent-spec.md#skill-preloading)) |
| `mcpServers` | No | No | Scope MCP servers to this agent, keeping descriptions out of the parent conversation |
| `permissionMode` | No | No | Override permission prompts. Use sparingly |
| `model` | No | - | **Do not include.** Model selection is a user/platform concern |

The same [no provider-specific models](#no-provider-specific-models) rule applies to agents as to skills.

See [`agent-creator/references/frontmatter-fields.md`](skills/tools/agent-creator/references/frontmatter-fields.md) for the full reference, including portability notes and common combination mistakes.

### 4. Agent body (system prompt)

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
- Role agents point to their `roles/{role}/` files by path. Do not create a role skill, and do not preload one

See [`agent-creator/references/system-prompts.md`](skills/tools/agent-creator/references/system-prompts.md) for worked examples per archetype and common rejection reasons.

### 5. Choose tool permissions

Start read-only and add write tools only when the workflow demands them.

| Archetype | Typical allowlist |
|---|---|
| Investigator / Reviewer / Auditor | `Read, Grep, Glob, Bash` |
| Doc Writer | `Read, Grep, Glob, Bash, Edit, Write` (documentation only, runs in place) |
| Implementer / Dev Role | `Read, Grep, Glob, Bash, Edit, Write` + `isolation: worktree` |
| Team-Lead | `Read, Grep, Glob, Bash, Agent(specialist-a, specialist-b)` |

Rules:

- Pair `Edit`/`Write` with `isolation: worktree` when the agent changes source code. Documentation-only writers and planning roles that write only planning documents may run in place
- `Agent(...)` allowlist pins which sub-agent types a team-lead can spawn
- Never leave `tools` unset - agents that inherit all tools are not least-privileged

See [`agent-creator/references/tool-selection.md`](skills/tools/agent-creator/references/tool-selection.md) for the full decision tree.

### 6. Update marketplace.json (MANDATORY)

Every new agent requires a `marketplace.json` update. This is non-negotiable.

- Add the agent path to the `agents` array of the `agents-virtuoso` plugin. That entry uses `"source": "./"` because agents and workflows live at the repository root
- A role agent needs no skill entry. Its `roles/{role}/` files are plain files that ship with the repository
- If you add a headless wrapper skill for the agent, add it to the same entry
- Bump the marketplace version per the [Version Bumping Rules](#version-bumping-rules)

```json
{
  "name": "agents-virtuoso",
  "description": "...",
  "source": "./",
  "strict": false,
  "skills": ["./skills/knowledge/agent-orchestration"],
  "agents": ["./agents/reviewer.md", "./agents/your-agent-name.md"]
}
```

Only `agents-virtuoso` uses `"source": "./"`. Every other bundle uses `"source": "./skills"`: Claude Code scans an entry's source for `agents/`, so a second entry with the repository root as its source would register every agent again under its own name.

### 7. Update README.md and AGENTS.md

- Add a row to the agent table in [README.md](README.md)
- Add a row to the matching table in [AGENTS.md](AGENTS.md), including a short description of when to delegate
- Run `python3 scripts/build-codex-agents.py` to regenerate the Codex TOML files in `codex/agents/`
- If the agent introduces a new category of work, update the top-level "Agents" bullet in README.md

### 8. Validate before committing

Run through the pre-publish checklist: [`agent-creator/references/validation.md`](skills/tools/agent-creator/references/validation.md).

The most common rejection reasons:

- Description lacks trigger phrases
- Tool allowlist is missing or overly permissive
- Agent changes source code but has no `isolation: worktree`
- Output section is vague prose instead of a template
- Body contains provider-specific or tool-specific phrasing
- Agent does two things - should be split into two agents

## Updating existing agents

- Make your content changes
- Re-run the validation checklist in [`agent-creator/references/validation.md`](skills/tools/agent-creator/references/validation.md)
- Bump the version in `marketplace.json` (see [Version Bumping Rules](#version-bumping-rules))
- If the change alters the agent's output contract or tool permissions, note it in the commit message so reviewers can spot callers that may need updating

## Adding a team

A team is a Markdown recipe plus a Claude Code workflow script that encodes it. Follow [`spec/team-spec.md`](spec/team-spec.md):

1. Add the recipe as a section of `skills/knowledge/agent-orchestration/references/teams.md`. Every agent it names must exist in `agents/`
2. Copy `template/workflow-template.js` to `workflows/{name}.js` and fill it in. `meta.name` equals the file name
3. Test the script against a mock `agent` before committing, including each early return
4. Add the team to the Teams table in [README.md](README.md) and [AGENTS.md](AGENTS.md), and bump the marketplace version. The `agents-virtuoso` entry picks `workflows/` up on its own, so `marketplace.json` needs no new path

## Adding a new plugin

There are two distinct uses of the word "plugin" in this repository. Know which one you are working on before you start.

| Meaning | File | Purpose |
|---|---|---|
| **Marketplace entry** | an object inside `.claude-plugin/marketplace.json` | Bundles existing skills and/or agents from this repo for installation. Most "add a plugin" work is this. |
| **Standalone Claude Code plugin** | its own directory with `.claude-plugin/plugin.json` | A self-contained plugin that can live in a separate repo and be distributed through any marketplace. Plugins that live in this repo go in `plugins/{name}/`. |

For a guided, interactive scaffold, run the `plugin-creator` skill in `skills/tools/plugin-creator/`. This guide is the reference for contributors and reviewers; the canonical specification lives in [`spec/plugin-spec.md`](spec/plugin-spec.md).

### Adding a marketplace entry

Use this path when you want to expose existing skills or agents in this repo as an installable bundle.

1. Open `.claude-plugin/marketplace.json`
2. Add a new object to the `plugins` array following the [Plugin Naming Convention](#plugin-naming-convention)
3. Use `"source": "./skills"` and `"strict": false` for a skill-only bundle, and list skill paths relative to `skills/`. Use `"source": "./"` only for the entry that ships agents or workflows (`agents-virtuoso`): every entry with the repository root as its source registers every agent in `agents/`, so a second one would duplicate them
4. Reference existing skill directories in `skills` and, for `agents-virtuoso`, existing agent files in `agents`
5. Bump `metadata.version` per [Version Bumping Rules](#version-bumping-rules) (minor bump for a new plugin)
6. Update README.md if the new plugin introduces a new category

Minimal example:

```json
{
  "name": "my-new-virtuoso",
  "description": "Interactive tool that ...",
  "source": "./skills",
  "strict": false,
  "skills": ["./tools/my-new-tool"]
}
```

See [Marketplace Configuration](#marketplace-configuration) below for the full rules.

### Adding a standalone Claude Code plugin

Use this path when the plugin should be its own repo or its own directory outside this marketplace - for example, when shipping hooks, MCP servers, or LSP servers that do not belong inside the code-virtuoso content library.

1. **Scaffold with `plugin-creator`**. The skill generates the full directory structure, writes a validated `plugin.json`, and wires up any components you select (skills, agents, hooks, MCP servers, LSP servers, bin, output styles, default settings).
2. **Place the plugin directory** at the top of the plugin's own repository, or in this repo under `plugins/{name}/`.
3. **Follow [`spec/plugin-spec.md`](spec/plugin-spec.md)** for structural rules. Critical points:
   - Only `plugin.json` belongs inside `.claude-plugin/`. Every other directory (`skills/`, `agents/`, `hooks/`, etc.) lives at the plugin root.
   - All paths in `plugin.json` must be relative and start with `./`.
   - Use `${CLAUDE_PLUGIN_ROOT}` for bundled resources and `${CLAUDE_PLUGIN_DATA}` for state that must survive updates.
   - Plugin-shipped agents cannot set `hooks`, `mcpServers`, or `permissionMode` - these are blocked for security.
4. **Validate locally** before committing:
   ```
   claude --plugin-dir ./your-plugin
   claude plugin validate
   ```
5. **Add a marketplace entry** if you want this marketplace to distribute it - the entry's `source` can be a relative path (same repo), a `github` object, a `url` object, a `git-subdir` object, or an `npm` object. See `plugin-creator/references/marketplace-manifest.md` for all source types. For a plugin under `plugins/`, use `{"name": "{name}", "source": "./plugins/{name}", "description": "..."}` and nothing else: because the plugin has its own `plugin.json`, adding `strict`, `skills`, `agents`, `hooks`, or `version` to the entry creates conflicting manifests (`scripts/validate-marketplace.py` rejects it). Users install it with `/plugin install {name}@code-virtuoso`.
6. **Seed a `CHANGELOG.md`** with the initial `1.0.0` release entry. Standalone plugins track their own version independently of the marketplace version.

### Common mistakes

| Mistake | Consequence | Fix |
|---|---|---|
| Putting `skills/`, `agents/`, or `hooks/` inside `.claude-plugin/` | Components are invisible to Claude Code | Move them to the plugin root |
| Absolute paths in `plugin.json` or hook commands | Works locally, breaks once cached | Use `./` paths or `${CLAUDE_PLUGIN_ROOT}` |
| Referencing files outside the plugin root (`../shared`) | Files are not copied to the plugin cache | Use symlinks; they are preserved |
| Setting `version` in both `plugin.json` and the marketplace entry | Maintenance trap; `plugin.json` wins on conflict | Pick one authoritative location |
| Reserved marketplace name (e.g. `claude-plugins-official`) | Installation rejected | See reserved names in `plugin-creator/references/marketplace-manifest.md` |
| Content changed but version not bumped | Users never see the update due to caching | Always bump the version per [Version Bumping Rules](#version-bumping-rules) |

## Updating existing plugins

- Make your content changes (plugin directory, `plugin.json`, or the marketplace entry as appropriate)
- Re-run `claude plugin validate` if you touched a standalone plugin
- Bump the version in the authoritative location:
  - Marketplace entry: bump `metadata.version` in `marketplace.json`
  - Standalone plugin: bump `version` in `plugin.json`
  - Never both for the same plugin
- Record the change in the plugin's `CHANGELOG.md` if it has one
- If the change removes a skill, renames a skill, or changes a hook event, bump the **major** version - these are breaking for installed users

## Marketplace configuration

The file `.claude-plugin/marketplace.json` defines how skills and agents are packaged for installation. Each plugin groups related skills and/or agents that users can install together.

```json
{
  "name": "plugin-name",
  "description": "What this plugin provides",
  "source": "./skills",
  "strict": false,
  "skills": ["./category/skill-name"]
}
```

Only `agents-virtuoso` also sets `agents` and uses `"source": "./"`, with skill paths written from the repository root (`./skills/tools/review-pr`).

**When to create a new plugin vs. add to an existing one:**

- Add to an existing plugin when your skill fits its theme (e.g., a new knowledge skill goes into `knowledge-virtuoso`)
- Create a new plugin only when adding an entirely new category that does not fit any existing bundle (the `ai` category is an example)

### Plugin naming convention

All plugins follow the `{category}-virtuoso` pattern. One plugin per `skills/` subdirectory, plus one for agents, plus one per self-contained plugin under `plugins/`.

| Plugin | Source | Contains |
|---|---|---|
| `knowledge-virtuoso` | `./skills` | Knowledge skills (security, debugging, design references, and so on) |
| `tools-virtuoso` | `./skills` | Interactive tool skills |
| `playbooks-virtuoso` | `./skills` | Operational playbook skills |
| `frameworks-virtuoso` | `./skills` | Framework skills (Symfony, Django, LangChain, PHP, Vercel AI SDK) |
| `ai-virtuoso` | `./skills` | AI engineering skills (agent design, evals, observability, MCP servers) |
| `agents-virtuoso` | `./` | All 19 agents, the team workflows in `workflows/`, `agent-orchestration`, `verification-before-completion`, and the headless wrapper skills |
| `loop-virtuoso` | `./plugins/loop-virtuoso` | Self-contained Claude Code plugin with its own `plugin.json` (not a bundle of repo skills) |

When adding a new skill:
- Identify which `skills/` subdirectory it belongs to
- Add the skill path to the matching `*-virtuoso` plugin in `marketplace.json`
- Bump the version

When adding a new role:
- Create the reference files in `roles/{name}/`
- Create the agent in `agents/{name}.md` and point it to those files
- Add the agent to `agents-virtuoso`

When adding a new specialist agent:
- Create the agent in `agents/{name}.md`
- Add to `agents-virtuoso`

## Version bumping rules

The version field lives in `metadata.version` inside `marketplace.json`.

| Change type | Version bump | Example |
|---|---|---|
| Content updates to existing skills | Patch | 10.0.0 -> 10.0.1 |
| New skills or agents added | Minor | 10.0.0 -> 10.1.0 |
| Restructuring, renames, breaking changes | Major | 10.0.0 -> 11.0.0 |

## Commit conventions

- No AI co-author lines in commits
- Descriptive commit messages summarizing what was added or changed
- One logical change per commit
- Example: `Add Kubernetes deployment skill with 5 reference files`
- Example: `Update design-patterns skill with Specification pattern`

## Quality standards

Skills are reference material for AI agents that need precise, actionable information. Write them as reference, not as tutorials.

| Guideline | Target |
|---|---|
| Reference files | 100-700 lines each, with a `## Contents` list of H2 links once a file passes 100 lines |
| SKILL.md | Under 500 lines (use progressive disclosure) |
| Tables | Use for all structured data (comparisons, commands, options) |
| Cross-references | Link related skills only where the body needs them. An Integration section is optional |
| Code examples | Idiomatic for the target language/framework, using current stable versions |
| Principles table | Optional. Skip it unless it carries information the body lacks |
| Frontmatter | Only in SKILL.md and agent files, never in reference files |

### Language and provider agnosticism

All content must be **language-agnostic** and **LLM provider-agnostic** by default. Do not assume a specific programming language, framework, or AI provider unless the skill explicitly targets one.

| Content type | Rule |
|---|---|
| Knowledge skills | Fully language-agnostic. Use pseudocode or multi-language examples. |
| AI skills (`ai/`) | Provider-agnostic. Name a provider only to state a fact about it. |
| Role references (`roles/`) | Fully agnostic. No language-specific code. |
| Agent definitions | No provider-specific model names. No platform-specific tool names in the body. |
| Framework skills (`frameworks/`) | Language/framework-specific by definition. Target latest stable version. |
| Playbooks | May be language-specific if the procedure is (e.g., PHP upgrade). State the scope clearly. |
| Plugins (`plugins/`) | Claude Code only, by design. They ship hooks and scripts that run inside Claude Code. State this in the plugin README. |

**The only exceptions** are skills that explicitly exist for a specific language, framework, or LLM provider (e.g., `symfony-components`, `django-components`, `php-upgrade`), and the self-contained plugins under `plugins/`. These should state their scope in the description.

### Content guidelines

- Show realistic, production-quality examples - not toy code
- Include both the "happy path" and error handling where relevant
- Keep instructions actionable - tell the agent what to do, not just what exists

### Research process for new skills

Before writing a new skill:

1. Search for existing skills: `npx skills find "{topic}"`
2. Search the web for official documentation and community best practices
3. Read 2-3 existing skills in this project to match structure and depth
4. Use the template in `template/skill-template.md` as a starting point

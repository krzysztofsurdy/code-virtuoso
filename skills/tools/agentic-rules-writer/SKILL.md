---
name: agentic-rules-writer
description: Interactive tool to generate tailored rules and instruction files for any AI coding agent. Use when the user asks to set up agent rules, configure Claude Code instructions, create Cursor rules, write Windsurf rules, generate Copilot instructions, or establish consistent AI coding standards for a team. Supports 13+ agents (Claude Code, Cursor, Windsurf, Copilot, Gemini, Codex, Cline, OpenCode, Continue, Trae, Roo Code, Amp) with global, team-shared, and dev-specific scopes. Defers to the `using-ecosystem` meta-skill for ecosystem discovery (skills, agents, recommendations) and runs an interactive questionnaire for workflow preferences.
user-invocable: true
argument-hint: "[optional: agent-name e.g. claude, cursor, windsurf, codex]"
---

# Agentic Rules Writer

Generate a tailored rules or instruction file for any AI coding agent. The skill runs an interactive questionnaire, takes the installed-skill and agent inventory from the `using-ecosystem` meta-skill, and writes the output in the format and location the chosen agent and scope require.

## When to use

- Setting up a new AI coding agent for the first time
- Creating team-shared project rules so developers get consistent behavior
- Adding personal dev-specific rules to a project (gitignored)
- After installing new skills to update the rules file with skill references

## Quick start

```
/agentic-rules-writer claude
/agentic-rules-writer cursor
/agentic-rules-writer codex
/agentic-rules-writer              # asks which agent
```

---

## Phase 1: Agent selection

If `$ARGUMENTS` is provided, map it to an agent from the table below (case-insensitive, partial match OK, e.g. "wind" matches Windsurf). If no argument or no match, present a selectable menu using `AskUserQuestion` (or the agent's equivalent interactive prompt tool).

### Tier 1: full support with dedicated format and paths

| Agent | Format notes |
|---|---|
| Claude Code | Plain Markdown, keep under 200 lines |
| Cursor | Requires YAML frontmatter: `alwaysApply: true`, `.mdc` extension |
| Windsurf | Plain Markdown, under 6,000 characters for the global file and 12,000 per workspace rule file |
| GitHub Copilot | Plain Markdown, `.github/copilot-instructions.md` |
| Gemini CLI | Plain Markdown |
| Roo Code | Plain Markdown |
| Amp | Same format as Claude Code |
| Codex (OpenAI) | Plain Markdown, uses `AGENTS.md` convention |
| Cline | Plain Markdown |
| OpenCode | Plain Markdown |
| Continue | Plain Markdown |
| Trae | Plain Markdown |

### Tier 2: supported with generic Markdown format

| Agent | Format notes |
|---|---|
| Goose | Plain Markdown |
| Augment | Plain Markdown |
| Kilo Code | Plain Markdown |

### Other / universal

For any agent not listed: write plain Markdown to a user-specified path. Ask the user for the output path.

See [references/agent-targets.md](references/agent-targets.md) for each agent's format, paths, limits, and testing instructions.

---

## Phase 2: Scope selection

Ask the user which scope to generate rules for, using a selectable menu (`AskUserQuestion` or the agent's equivalent):

| Scope | Description | Typical path (Claude Code example) |
|---|---|---|
| **Global** | User-level rules applied to every project. Personal workflow preferences. | `~/.claude/CLAUDE.md` |
| **Project (team-shared)** | Committed to the repo. Shared conventions the whole team follows. | `.claude/rules/team-rules.md` |
| **Project (dev-specific)** | Local to this dev, gitignored. Personal preferences layered on top of team rules. | `.claude/rules/dev-rules.md` |

See [references/agent-targets.md](references/agent-targets.md) for the exact path for each agent + scope combination.

**If the target file already exists**, present a selectable menu to ask the user:
1. **Overwrite**: replace the file entirely with generated content
2. **Merge**: append generated content below existing content (separated by `---`)
3. **Abort**: cancel and leave the file untouched

---

## Phase 3: Workflow questionnaire

Always present questions in a structured interactive menu, never as plain text. If `AskUserQuestion` is available, use it. Otherwise use the equivalent interactive prompt tool of the agent CLI. The user should pick from a list of options, not parse a wall of text and type answers. Batch up to 4 independent questions per call when the tool supports it. If a question has more than 4 options, present the 4 most common and let the "Other" or free-text fallback cover the rest.

Wait for the user's answers before proceeding to the next batch.

### Scope matrix

The scope decides which questions to ask:

| # | Question | Group | Global | Team-shared | Dev-specific |
|---|---|---|---|---|---|
| Q1 | Primary stack | A: Project context | Yes | Yes | Skip |
| Q2 | Directory structure | A: Project context | Yes | Yes | Skip |
| Q3 | Build/run commands | A: Project context | Yes | Yes | Skip |
| Q4 | Code quality bar | B: Code standards | Yes | Yes | Skip |
| Q5 | Testing philosophy | B: Code standards | Yes | Yes | Skip |
| Q6 | Error handling | B: Code standards | Yes | Yes | Skip |
| Q7 | Security & secrets | B: Code standards | Yes | Yes | Skip |
| Q8 | Dependency management | B: Code standards | Yes | Yes | Skip |
| Q9 | Branch conventions | C: Version control | Yes | Yes | Skip |
| Q10 | Commit conventions | C: Version control | Yes | Yes | Skip |
| Q11 | PR/MR creation | C: Version control | Yes | Yes | Skip |
| Q12 | Planning discipline | D: Agent workflow | Yes | Skip | Yes |
| Q13 | Autonomy level | D: Agent workflow | Yes | Skip | Yes |
| Q14 | Boundaries (never-do) | D: Agent workflow | Yes | Skip | Yes |
| Q15 | Agent parallelization | D: Agent workflow | Yes | Skip | Yes |
| Q16 | Task tracking | D: Agent workflow | Yes | Skip | Yes |
| Q17 | Self-improvement | D: Agent workflow | Yes | Skip | Yes |
| Q18 | Communication style | E: Communication | Yes | Skip | Yes |
| Q19 | Persona / roleplay | E: Communication | Yes | Skip | Yes |
| Q20 | Additional comments | F: Freeform | Yes | Yes | Yes |

Team-shared rules cover technical standards the whole team agrees on (stack, directory structure, commands, quality, testing, error handling, security, dependencies, branching, commits, PRs). Dev-specific rules cover personal workflow preferences (planning style, autonomy, boundaries, parallelization, task tracking, self-improvement, communication style, persona). Global includes everything.

See [references/questionnaire.md](references/questionnaire.md) for the question reference with descriptions, option mappings, and example outputs.

### Suggested batching

For global scope (all 20 questions), batch as follows:
- Batch 1 (Group A): Q1 (stack), Q2 (directory), Q3 (commands, free text)
- Batch 2 (Group B, part 1): Q4 (quality), Q5 (testing), Q6 (error handling), Q7 (security)
- Batch 2a (follow-ups): Q4 documentation follow-up
- Batch 3 (Group B+C): Q8 (dependencies), Q9 (branches), Q10 (commits), Q11 (PRs)
- Batch 3a (follow-ups): Q10 co-author follow-up
- Batch 4 (Group D, part 1): Q12 (planning), Q13 (autonomy), Q14 (boundaries), Q15 (parallelization)
- Batch 5 (Group D+E): Q16 (tracking), Q17 (self-improvement), Q18 (communication), Q19 (persona)
- Batch 5a (follow-ups): Q16 external tool follow-up
- Final: Q20 (additional comments, free text)

For other scopes, adjust the batches to skip questions the scope matrix marks as Skip.

### Question reference

Read [references/questionnaire.md](references/questionnaire.md) before asking. For each question it holds the exact question text, its purpose, the option table, and the rules each answer generates. Build each menu from those option tables.

Questions that need more than a single menu pick:

| Question | Handling |
|---|---|
| Q1 Primary stack | Offer the 4 most relevant stacks (PHP+Symfony, TypeScript+React, Python+Django, Go, Rust, Java+Spring); "Other" is added automatically. If "Other", ask the user to specify |
| Q3 Build/run commands | Free text, blank allowed. Include verbatim in a `## Commands` section; omit the section if blank |
| Q4 Code quality bar | Follow-up: documentation level |
| Q10 Commit conventions | Follow-up: should the agent add itself as co-author |
| Q14 Boundaries | If "Custom", ask for the never-do list and include it prefixed with NEVER |
| Q16 Task tracking | Follow-up: external tool (Jira, Linear, GitHub Issues, None). If one is selected, generate rules that reference it |
| Q19 Persona | If "Yes", ask the user to describe the persona (any input); use web search if it is obscure. Generate a one-paragraph description, 5-8 catchphrases, and the hard constraint that precision always comes first and the persona is flavor, not substance (at most one catchphrase per response, never repeated consecutively) |
| Q20 Additional comments | Free text. Include verbatim in an `## Additional Rules` section at the end; omit the section if the user skips |

---

## Phase 4: Ecosystem discovery

Scan installed skills, agents, and teams at runtime. Do not rely on hardcoded inventories.

### Scanning process

Scan for installed skills, agents, and teams using the platform's standard locations. Each AI coding tool stores skills in different places. Check the user-level and project-level directories for the agent chosen in Phase 1.

Common locations to scan for `SKILL.md` files (skills), `*.md` agent definitions, and `*.md` team definitions:

- User-level skill/agent/team directories (varies per platform)
- Project-level `.{agent}/skills/`, `.{agent}/agents/`, `.{agent}/teams/`
- Plugin cache directories (if the platform uses a plugin system)

If the `using-ecosystem` skill is installed, invoke it. It provides platform-aware discovery commands.

For each found file, read the YAML frontmatter (`name`, `description`) and build the rules sections:

1. **Skills section**: one bullet per installed skill: `When [trigger from description] -> use /skill-name`
2. **Custom Agents section**: agents with capability summary (read-only vs worktree, specialist vs role)
3. **Agent Roles section**: role agents with their domain of responsibility
4. **Teams section**: pre-composed teams with lead and use case

The AI coding agent itself is the primary discovery mechanism: it reads skill frontmatter (`name`, `description`) to decide when to activate each skill. The `using-ecosystem` skill is a secondary advisor for cases where the agent is unsure which skill or agent fits. If installed, it provides matching heuristics and chaining patterns.

### Parallelization add-on

If the user selected "Always parallelize" or "Parallel for large tasks" in Q15, add this line to the Custom Agents section:

```
When delegating to agent teams, prefer using custom agents over general-purpose when a matching agent exists.
```

---

## Phase 5: Assemble and write

Generate the rules file content from the questionnaire answers. The structure depends on the scope.

### Global scope structure

```markdown
# Global Rules

## Commands
[Build/run commands from Q3, only if provided; omit section if blank]

## Code Quality
[Quality bar from Q4 + documentation follow-up]
[Stack conventions from Q1]
[Directory structure from Q2]
[Error handling from Q6]
[Elegance check: "For non-trivial changes, pause and ask: is there a more elegant way?"]

## Testing
[Testing rules from Q5]

## Security
[Security practices from Q7]
[Dependency management from Q8]

## Version Control
[Branch rules from Q9]
[Commit rules from Q10 + co-authorship follow-up]
[PR creation from Q11]

## Workflow
[Planning rules from Q12]
[Autonomy rules from Q13]
[Boundaries from Q14]
[Parallelization rules from Q15]
[Re-plan rule: "If an approach fails or hits unexpected complexity, stop and re-plan immediately"]

## Communication
[Communication style from Q18]

## Task Management
[Tracking from Q16 + external tool follow-up]
[Self-improvement from Q17]

## Core Principles
- Simplicity first: make every change as simple as possible
- Root causes only: no temporary fixes, find and fix the real problem
- Minimal blast radius: touch only what's necessary
- Prove it works: never mark done without verification

## Code Change Hygiene
- Read before editing: always read and understand existing code before modifying it
- Minimal diffs: make the smallest change that solves the problem, no drive-by cleanups
- Follow existing patterns: match the codebase's style, naming, and structure
- One task at a time: complete the requested task, don't fix unrelated issues or "improve" adjacent code
- Prefer editing over creating: always prefer modifying an existing file over creating a new one
- Search before creating: before creating a new file, search for an existing one that serves a similar purpose
- Never create documentation files unless explicitly asked
- No premature abstractions: don't introduce interfaces, base classes, or design patterns unless the current task demands them
- No backwards-compatibility shims: when replacing code, remove the old version entirely
- Remove dead code: don't leave commented-out code, unused imports, or orphaned functions

## Don't Guess
- Don't fabricate URLs, file paths, API endpoints, or names. Search or ask if unsure
- Don't assume unstated requirements: implement only what was requested
- Don't assume project architecture: explore and verify before making decisions
- Ask when stuck: a clarifying question is cheaper than a wrong implementation
- If an approach fails or hits unexpected complexity, stop and re-plan immediately

## Safety Baseline
- Never commit secrets, .env files, API keys, or credentials to version control
- Never force push to main/master
- Never delete branches without explicit approval
- Never modify CI/CD pipelines without explicit approval

## Knowledge Sources
- When a topic is covered by an installed skill, use the skill first. It contains curated, verified content
- When a topic is NOT covered by installed skills, search the web for the official documentation of the technology (e.g., symfony.com for Symfony, php.net for PHP, react.dev for React)
- Prefer official docs over blog posts, Stack Overflow, or AI-generated summaries. Official sources are the most accurate and current
- When recommending MCPs, skills, or packages to install, always prefer official providers (e.g., Anthropic, Vercel, framework authors) over community alternatives
- When no official option exists, prefer well-maintained community options with high adoption and recent activity

## Skills

CRITICAL: When a situation matches an installed skill, you MUST use it. Do not rely on general knowledge when a dedicated skill exists. Skills contain curated reference material that is more precise than answers generated from scratch. Skipping a relevant skill is like ignoring documentation you already have open.

[Auto-generated from Phase 4 runtime scan. One line per installed skill.]
When [trigger from description] -> use /skill-name
...

## Custom Agents
[If specialist agents are found during Phase 4 scan, list them with descriptions and capabilities. If none found, omit this section entirely.]

## Agent Roles
[If role agents are installed (per Phase 4), list them here with the domain they own. If none, omit this section entirely.]

## Persona
[If Q19 = Yes: persona description, catchphrases, and constraint. If No, omit this section entirely.]

## Recommended (not installed)
- Install [skill] from krzysztofsurdy/code-virtuoso: [what it helps with]
```

### Project team-shared structure

```markdown
# Project Rules

## Commands
[Build/run commands from Q3, only if provided]

## Stack & Conventions
[Stack conventions from Q1]
[Quality bar from Q4 + documentation follow-up]
[Directory structure from Q2]
[Error handling from Q6]

## Testing
[Testing rules from Q5]

## Security
[Security practices from Q7]
[Dependency management from Q8]

## Version Control
[Branch rules from Q9]
[Commit rules from Q10 + co-authorship follow-up]
[PR creation from Q11]

## Core Principles
- Simplicity first: make every change as simple as possible
- Root causes only: no temporary fixes, find and fix the real problem
- Minimal blast radius: touch only what's necessary
- Prove it works: never mark done without verification

## Code Change Hygiene
- Read before editing: always read and understand existing code before modifying it
- Minimal diffs: make the smallest change that solves the problem, no drive-by cleanups
- Follow existing patterns: match the codebase's style, naming, and structure
- One task at a time: complete the requested task, don't fix unrelated issues or "improve" adjacent code
- Prefer editing over creating: always prefer modifying an existing file over creating a new one
- Search before creating: before creating a new file, search for an existing one that serves a similar purpose
- Never create documentation files unless explicitly asked
- No premature abstractions: don't introduce interfaces, base classes, or design patterns unless the current task demands them
- No backwards-compatibility shims: when replacing code, remove the old version entirely
- Remove dead code: don't leave commented-out code, unused imports, or orphaned functions

## Don't Guess
- Don't fabricate URLs, file paths, API endpoints, or names. Search or ask if unsure
- Don't assume unstated requirements: implement only what was requested
- Don't assume project architecture: explore and verify before making decisions
- Ask when stuck: a clarifying question is cheaper than a wrong implementation

## Safety Baseline
- Never commit secrets, .env files, API keys, or credentials to version control
- Never force push to main/master
- Never delete branches without explicit approval
- Never modify CI/CD pipelines without explicit approval

## Knowledge Sources
- When a topic is covered by an installed skill, use the skill first. It contains curated, verified content
- When a topic is NOT covered by installed skills, search the web for the official documentation of the technology
- Prefer official docs over blog posts, Stack Overflow, or AI-generated summaries
- When recommending MCPs, skills, or packages to install, always prefer official providers over community alternatives
- When no official option exists, prefer well-maintained community options with high adoption and recent activity
```

### Project dev-specific structure

```markdown
# Dev Rules

## Workflow
[Planning rules from Q12]
[Autonomy rules from Q13]
[Boundaries from Q14]
[Parallelization rules from Q15]

## Communication
[Communication style from Q18]

## Task Management
[Tracking from Q16 + external tool follow-up]
[Self-improvement from Q17]

## Persona
[If Q19 = Yes: persona description, catchphrases, and constraint. If No, omit.]
```

### Agent-specific formatting

Apply these transformations before writing:

**Cursor**: wrap the entire content in YAML frontmatter:
```
---
alwaysApply: true
---

[content here]
```

**Windsurf**: check the character count. The global file is limited to 6,000 characters and each workspace rule file to 12,000. If the file is over its limit, condense sections (remove examples, shorten descriptions) until it is under. Add a comment at the top: `<!-- Windsurf rules -->`.

**Claude Code / Amp (global)**: keep it under 200 lines. Add a note at the end: `For project-specific rules, use .claude/rules/*.md files.`

**Codex**: use the `AGENTS.md` filename convention at the project root.

**All others**: write plain Markdown as-is.

### Rule generation examples

Each answer maps to a short block of 2-5 rule bullets. [references/questionnaire.md](references/questionnaire.md) lists the generated rules for every answer of all 20 questions, plus full persona output examples (pirate captain, grumpy senior engineer). Load it while assembling the sections above and take the bullets from there instead of inventing wording.

---

## Phase 6: Confirmation

After writing the file, do the following:

1. Display the **full generated content** to the user
2. Show the **file path** where it was written
3. Show the **line count** and **character count**
4. If any agent-specific limits were applied (e.g., Windsurf char limit, Claude line limit), mention what was condensed
5. Offer: "Would you like to edit anything before we're done?"

---

## Error handling

- If a target directory doesn't exist, create it
- If the user aborts during the questionnaire, discard all progress and do not write a partial file
- If the user reports no installed code-virtuoso plugins in Phase 4, skip the Skills, Custom Agents, and Agent Roles sections entirely and include a short "Recommended (not installed)" list pointing to `tool-using-ecosystem` and `agents-virtuoso` as starting installs
- If `using-ecosystem` is not installed, do not fabricate the ecosystem inventory. Ask the user what they have
- For project scopes, verify you are inside a git repository before writing

---

## Reference files

| Reference | Contents |
|---|---|
| [agent-targets](references/agent-targets.md) | Output paths, format requirements, limits, and testing steps for each agent and scope (Phases 1, 2, and 5) |
| [questionnaire](references/questionnaire.md) | Question text, option tables, answer-to-rule mappings, and persona examples for Q1-Q20 (Phases 3 and 5) |

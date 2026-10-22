---
name: agentic-rules-writer
description: Interactive tool that generates rules and instruction files for AI coding agents (Claude Code, Cursor, Windsurf or Devin Desktop, Copilot, Gemini or Antigravity, Codex, and others). Use when asked to set up agent rules, write CLAUDE.md or AGENTS.md style instructions, or standardize AI coding rules for a team.
user-invocable: true
argument-hint: "[optional: agent-name e.g. claude, cursor, windsurf, antigravity, codex]"
---

# Agentic Rules Writer

Generate a tailored rules or instruction file for any AI coding agent. The skill runs an interactive questionnaire, checks that any skill it names is really installed, and writes the output in the format and location the chosen agent and scope require.

## When to use

- Setting up a new AI coding agent for the first time
- Creating team-shared project rules so developers get consistent behavior
- Adding personal dev-specific rules to a project (gitignored)
- Shrinking a bloated or drifting rules file, or fixing references to skills that are not installed

## Quick start

```
/agentic-rules-writer claude
/agentic-rules-writer cursor
/agentic-rules-writer codex
/agentic-rules-writer              # asks which agent
```

---

## Phase 1: Agent selection

If `$ARGUMENTS` is provided, map it to an agent from the table below (case-insensitive, partial match OK, e.g. "wind" or "devin" matches Windsurf, "gemini" or "anti" matches Gemini and Antigravity). If no argument or no match, present a selectable menu using `AskUserQuestion` (or the agent's equivalent interactive prompt tool).

### Tier 1: full support with dedicated format and paths

| Agent | Format notes |
|---|---|
| Claude Code | Plain Markdown, under 200 lines per file. Reads `AGENTS.md` when no `CLAUDE.md` exists |
| Cursor | Requires YAML frontmatter: `alwaysApply: true`, `.mdc` extension |
| Windsurf (now Devin Desktop) | Plain Markdown, under 6,000 characters for the global file and 12,000 per workspace rule file. Workspace rules in `.devin/rules/` with a `trigger` frontmatter field |
| GitHub Copilot | Plain Markdown, `.github/copilot-instructions.md` |
| Gemini CLI and Antigravity CLI | Plain Markdown. Antigravity CLI replaced Gemini CLI for unpaid and Google AI Pro and Ultra users on 2026-06-18 |
| Roo Code | Plain Markdown |
| Amp | Same format as Claude Code |
| Codex (OpenAI) | Plain Markdown, uses `AGENTS.md`, 32 KiB combined limit |
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
| **Project (team-shared)** | Committed to the repo. Shared conventions the whole team follows. | `AGENTS.md` at the repo root (see below) |
| **Project (dev-specific)** | Local to this dev, gitignored. Personal preferences layered on top of team rules. | `.claude/rules/dev-rules.md` |

See [references/agent-targets.md](references/agent-targets.md) for the exact path for each agent + scope combination.

### One source of truth for project rules

Write project rules once, in `AGENTS.md` at the repository root. Claude Code, Codex, Cursor, Copilot, Gemini or Antigravity, and Devin Desktop read it. Never copy the same rules into a second file.

| Situation | What to write |
|---|---|
| Only Claude Code is used | Write `AGENTS.md` and no `CLAUDE.md`. Claude Code 2.1.277 or later reads `AGENTS.md` when no `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` exists in the working directory or above it |
| Claude Code plus other tools | Write `AGENTS.md`, plus a thin `CLAUDE.md` that holds `@AGENTS.md` on the first line and only Claude-specific lines below it (for example plan mode for one directory) |
| A `CLAUDE.md` already exists with rules | Move the shared rules into `AGENTS.md`, then reduce `CLAUDE.md` to the import and Claude-only lines |
| Tool-specific scoping is needed (path-scoped rules, Cursor `alwaysApply` files) | Keep `AGENTS.md` as the base and add scoped files only for rules that apply to part of the repo |

An `@AGENTS.md` import keeps one copy of the text, but the imported file still loads at launch, so it does not cut context cost. Sources: [Claude Code memory](https://code.claude.com/docs/en/memory#agents-md), [Cursor rules](https://cursor.com/docs/context/rules), [Copilot repository instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions).

For global scope there is no shared file. Codex reads `~/.codex/AGENTS.md`. Claude Code documents `~/.claude/CLAUDE.md` as its user file and does not list a user-level `AGENTS.md`, so keep a separate global file per tool and do not assume one is read by the other. Keep both short.

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

## Phase 4: Environment check

Generated files hold rules only. They do not list skills, agents, or teams. Each skill and agent description already tells the agent when to use it, so a copy in a rules file goes stale, adds size, and can point at things that are not installed.

### What to write about skills

| Case | Write |
|---|---|
| Always (global scope) | At most one line: `Before acting, check the available skills and invoke any whose description matches the task.` |
| The user asks for a custom rule about a specific skill (for example "always use /communication-style before writing PR comments") | That one rule, only after confirming the skill is installed |
| The skill is not installed | Do not write the reference. Tell the user it was left out and why |
| Agents and teams | Nothing. Do not write an agent roster. Add a rule only when the user states one, such as "prefer custom agents over general-purpose when a matching agent exists" |

### Verify a skill exists before naming it

Check the user-level and project-level skill directories for the agent chosen in Phase 1, and the plugin cache if the platform has one. For Claude Code that means `~/.claude/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`, and installed plugins under `~/.claude/plugins/cache`; also check `~/.agents/skills` and `.agents/skills`. A name that resolves nowhere does not go in the file. Never write a reference to a skill you could not find.

### Many installed skills

While scanning, count the installed skills. If there are many (as a rough guide, more than 50), tell the user that Claude Code caps the skill listing (1% of the context window, 1,536 characters per skill), drops descriptions of the least-used skills first, and that dropped skills show as bare names and are rarely picked. Recommend:

1. Run `/context` to see the Skills row, and `/skill-doctor` (Claude Code 2.1.252 or later) for per-skill cost and use.
2. Disable plugins and skills that are not used. Plugin skills are managed through `/plugin`. `skillOverrides` does not apply to them.
3. Set low-value personal or project skills to `"name-only"` or `"off"` in `skillOverrides`.
4. Raise the budget only if needed, with `skillListingBudgetFraction` (for example `0.02`) or the `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable.

Source: [Claude Code skills, "Skill descriptions are cut short"](https://code.claude.com/docs/en/skills#skill-descriptions-are-cut-short). Other tools have their own limits, so check their docs.

---

## Phase 5: Assemble and write

Generate the rules file content from the questionnaire answers. The structure depends on the scope.

### Keep the output small

Instruction files are read on every turn, and long ones get followed less. Research on repository context files found that generated and hand-written files alike did not generally raise task success and cost more than 20% extra inference, while specific instructions were followed well. Apply the `context-engineering` skill when it is installed. In short:

- Every line must prevent a mistake the agent would make without it. Drop lines the agent would follow anyway, and anything a linter or formatter enforces.
- Do not add a repository overview, directory tree, or stack list the agent can read for itself. Commands, non-obvious conventions, and hard prohibitions earn their place.
- Treat the generic blocks in the templates below (Core Principles, Code Change Hygiene, Don't Guess, Knowledge Sources) as optional. Put them last and drop them first when the file nears its budget.
- Claude Code: stay under about 200 lines per file. Imports with `@path` organize a file but do not cut its cost. Move rules that matter for only part of the repo into path-scoped rules (`.claude/rules/*.md` with `paths:` frontmatter), which load only when matching files are touched. Other tools have similar scoping (Cursor `.cursor/rules`, Copilot `.github/instructions`, Devin `.devin/rules` with a `glob` trigger).
- A rule that must hold every time belongs in a hook, linter, or test, not in this file.
- Keep rules that must survive compaction in the always-on file.
- Do not list skills, agents, or teams. See Phase 4.
- Size check: the global file stays under about 200 lines. Count lines before writing. Above 200, cut the optional blocks first, then warn the user in Phase 6.
- Check the budget for the target tool in [agent-targets](references/agent-targets.md) and report the size in Phase 6.
- Point the user to the `instruction-auditor` agent to audit existing instruction files for size, contradictions, stale rules, secrets, and hidden Unicode.

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
- When a topic is NOT covered by installed skills, search the web for the official documentation of the technology (e.g., symfony.com for Symfony, php.net for PHP, react.dev for React)
- Prefer official docs over blog posts, Stack Overflow, or AI-generated summaries. Official sources are the most accurate and current
- When recommending MCPs, skills, or packages to install, always prefer official providers (e.g., Anthropic, Vercel, framework authors) over community alternatives
- When no official option exists, prefer well-maintained community options with high adoption and recent activity

## Skills
Before acting, check the available skills and invoke any whose description matches the task.
[Custom rule about a specific installed skill, only if the user asked for it]

## Persona
[If Q19 = Yes: persona description, catchphrases, and constraint. If No, omit this section entirely.]

```

### Project team-shared structure

Write this to `AGENTS.md` at the repository root (see "One source of truth for project rules" in Phase 2), not to a per-tool copy.

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

**Windsurf (Devin Desktop)**: check the character count. The global file is limited to 6,000 characters and each workspace rule file to 12,000. If the file is over its limit, condense sections (remove examples, shorten descriptions) until it is under. Workspace rule files start with frontmatter `trigger: always_on`. The global file and a root `AGENTS.md` take no frontmatter.

**Antigravity CLI**: `AGENTS.md` and `GEMINI.md` take no frontmatter. Files in `.agents/rules/` must start with frontmatter that declares a `trigger` (`always_on` for these rules), or Antigravity discards them. A rule file over 24 KB is truncated.

**Claude Code / Amp (global)**: keep it under 200 lines. Add a note at the end: `For project-specific rules, use .claude/rules/*.md files.`

**Claude Code (project)**: write the rules to `AGENTS.md`. With no `CLAUDE.md`, Claude Code reads `AGENTS.md` by itself. If a `CLAUDE.md` or `CLAUDE.local.md` is present or wanted, it makes Claude Code read the `CLAUDE.md` files only, so the `CLAUDE.md` must start with `@AGENTS.md` and hold only Claude-specific lines. Never duplicate the rules in both files.

**Codex**: use the `AGENTS.md` filename convention at the project root. Codex stops adding files once the combined chain reaches 32 KiB.

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
5. Say how large the file is against the tool's budget. For a global file, warn when it is over about 200 lines and name what was left out or could go
6. Offer, without pressing, a `UserPromptSubmit` reminder hook to counter drift: instructions load once at session start, so their influence fades in long sessions. The hook re-injects two or three critical rules on every prompt. The `hooks-and-guardrails` skill (`skills/playbooks/hooks-and-guardrails`) covers hook setup. Do not install it unless the user agrees
7. If Phase 4 found many installed skills, repeat the advice to check `/context` and disable unused plugins
8. Offer the `instruction-auditor` agent for a later audit, and ask: "Would you like to edit anything before we're done?"

---

## Error handling

- If a target directory doesn't exist, create it
- If the user aborts during the questionnaire, discard all progress and do not write a partial file
- If the user asks for a rule about a skill you cannot find installed, leave it out of the file and say so. Never write a skill reference you could not verify
- If no skills are installed, omit the `## Skills` section entirely
- For project scopes, verify you are inside a git repository before writing

---

## Reference files

| Reference | Contents |
|---|---|
| [agent-targets](references/agent-targets.md) | Output paths, format requirements, limits, and testing steps for each agent and scope (Phases 1, 2, and 5) |
| [questionnaire](references/questionnaire.md) | Question text, option tables, answer-to-rule mappings, and persona examples for Q1-Q20 (Phases 3 and 5) |

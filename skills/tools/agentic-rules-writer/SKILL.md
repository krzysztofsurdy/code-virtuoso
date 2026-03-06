---
name: agentic-rules-writer
description: Generate a rules file for any AI coding agent. Interactive setup that scans installed skills, asks about workflow preferences, and writes a tailored instruction file for Claude Code, Cursor, Windsurf, Copilot, Gemini, Codex, Cline, OpenCode, Continue, Trae, Roo Code, Amp, and more. Supports global (user-level), project team-shared, and project dev-specific scopes.
argument-hint: "[optional: agent-name e.g. claude, cursor, windsurf, codex]"
---

# Agentic Rules Writer

Generate a tailored rules/instruction file for any AI coding agent. Runs an interactive questionnaire, scans installed skills at runtime, and writes the output in the correct format and location for the chosen agent and scope.

## When to Use

- Setting up a new AI coding agent for the first time
- Creating team-shared project rules for consistent behavior across developers
- Adding personal dev-specific rules to a project (gitignored)
- After installing new skills to update the rules file with skill references

## Quick Start

```
/agentic-rules-writer claude
/agentic-rules-writer cursor
/agentic-rules-writer codex
/agentic-rules-writer              # asks which agent
```

---

## Phase 1: Agent Selection

If `$ARGUMENTS` is provided, map it to an agent from the table below (case-insensitive, partial match OK — e.g. "wind" matches Windsurf). If no argument or no match, present a selectable menu using `AskUserQuestion` (or the agent's equivalent interactive prompt tool).

### Tier 1 — Full support with dedicated format/paths

| Agent | Format Notes |
|---|---|
| Claude Code | Plain Markdown, keep under 200 lines |
| Cursor | Requires YAML frontmatter: `alwaysApply: true`, `.mdc` extension |
| Windsurf | Plain Markdown, enforce under 12,000 characters |
| GitHub Copilot | Plain Markdown, `.github/copilot-instructions.md` |
| Gemini CLI | Plain Markdown |
| Roo Code | Plain Markdown |
| Amp | Same format as Claude Code |
| Codex (OpenAI) | Plain Markdown, uses `AGENTS.md` convention |
| Cline | Plain Markdown |
| OpenCode | Plain Markdown |
| Continue | Plain Markdown |
| Trae | Plain Markdown |

### Tier 2 — Supported with generic Markdown format

| Agent | Format Notes |
|---|---|
| Goose | Plain Markdown |
| Augment | Plain Markdown |
| Kilo Code | Plain Markdown |

### Other / Universal

For any agent not listed: write plain Markdown to a user-specified path. Ask the user for the output path.

See [references/agent-targets.md](references/agent-targets.md) for full details on each agent's format, paths, limits, and testing instructions.

---

## Phase 2: Scope Selection

Present a selectable menu (using `AskUserQuestion` or the agent's equivalent) to ask the user which scope to generate rules for:

| Scope | Description | Typical Path (Claude Code example) |
|---|---|---|
| **Global** | User-level rules applied to every project. Personal workflow preferences. | `~/.claude/CLAUDE.md` |
| **Project (team-shared)** | Committed to the repo. Shared conventions the whole team follows. | `.claude/rules/team-rules.md` |
| **Project (dev-specific)** | Local to this dev, gitignored. Personal preferences layered on top of team rules. | `.claude/rules/dev-rules.md` |

See [references/agent-targets.md](references/agent-targets.md) for the exact path for each agent + scope combination.

**If the target file already exists**, present a selectable menu to ask the user:
1. **Overwrite** — replace entirely with generated content
2. **Merge** — append generated content below existing content (separated by `---`)
3. **Abort** — cancel and leave the file untouched

---

## Phase 3: Workflow Questionnaire

**IMPORTANT: Always present questions using a structured interactive menu, never as plain text.** If `AskUserQuestion` is available, use it. Otherwise, use whatever equivalent interactive prompt tool the agent CLI provides. The goal is a selectable option list, not a wall of text the user has to parse and type answers to. Batch up to 4 independent questions per call when the tool supports it. If a question has more than 4 options, present the most common 4 and let the "Other" / free-text fallback cover the rest.

Wait for the user's answers before proceeding to the next batch.

### Scope Matrix

Which questions to ask depends on the scope:

| # | Question | Group | Global | Team-shared | Dev-specific |
|---|---|---|---|---|---|
| Q1 | Primary stack | A: Project Context | Yes | Yes | Skip |
| Q2 | Directory structure | A: Project Context | Yes | Yes | Skip |
| Q3 | Build/run commands | A: Project Context | Yes | Yes | Skip |
| Q4 | Code quality bar | B: Code Standards | Yes | Yes | Skip |
| Q5 | Testing philosophy | B: Code Standards | Yes | Yes | Skip |
| Q6 | Error handling | B: Code Standards | Yes | Yes | Skip |
| Q7 | Security & secrets | B: Code Standards | Yes | Yes | Skip |
| Q8 | Dependency management | B: Code Standards | Yes | Yes | Skip |
| Q9 | Branch conventions | C: Version Control | Yes | Yes | Skip |
| Q10 | Commit conventions | C: Version Control | Yes | Yes | Skip |
| Q11 | PR/MR creation | C: Version Control | Yes | Yes | Skip |
| Q12 | Planning discipline | D: Agent Workflow | Yes | Skip | Yes |
| Q13 | Autonomy level | D: Agent Workflow | Yes | Skip | Yes |
| Q14 | Boundaries (never-do) | D: Agent Workflow | Yes | Skip | Yes |
| Q15 | Agent parallelization | D: Agent Workflow | Yes | Skip | Yes |
| Q16 | Task tracking | D: Agent Workflow | Yes | Skip | Yes |
| Q17 | Self-improvement | D: Agent Workflow | Yes | Skip | Yes |
| Q18 | Communication style | E: Communication | Yes | Skip | Yes |
| Q19 | Persona / roleplay | E: Communication | Yes | Skip | Yes |
| Q20 | Additional comments | F: Freeform | Yes | Yes | Yes |

**Rationale:** Team-shared rules cover technical standards the whole team agrees on (stack, directory structure, commands, quality, testing, error handling, security, dependencies, branching, commits, PRs). Dev-specific rules cover personal workflow preferences (planning style, autonomy, boundaries, parallelization, task tracking, self-improvement, communication style, persona). Global includes everything.

See [references/questionnaire.md](references/questionnaire.md) for the full question reference with descriptions, option mappings, and example outputs.

### Suggested Batching

For **Global** scope (all 20 questions), batch as follows:
- Batch 1 (Group A): Q1 (stack), Q2 (directory), Q3 (commands — free text)
- Batch 2 (Group B, part 1): Q4 (quality), Q5 (testing), Q6 (error handling), Q7 (security)
- Batch 2a (follow-ups): Q4 documentation follow-up
- Batch 3 (Group B+C): Q8 (dependencies), Q9 (branches), Q10 (commits), Q11 (PRs)
- Batch 3a (follow-ups): Q10 co-author follow-up
- Batch 4 (Group D, part 1): Q12 (planning), Q13 (autonomy), Q14 (boundaries), Q15 (parallelization)
- Batch 5 (Group D+E): Q16 (tracking), Q17 (self-improvement), Q18 (communication), Q19 (persona)
- Batch 5a (follow-ups): Q16 external tool follow-up
- Final: Q20 (additional comments — free text)

For other scopes, adjust batches to skip irrelevant questions per the scope matrix above.

### Group A: Project Context

**Q1. Primary stack**
Options (pick 4 most relevant, "Other" is added automatically): PHP+Symfony / TypeScript+React / Python+Django / Go / Rust / Java+Spring
(If "Other", ask them to specify.)

**Q2. Directory structure**
Options:
- Follow existing — always match the project's current directory structure and conventions
- Follow best practices — restructure toward industry conventions, suggest improvements
- Pragmatic middle — follow existing structure but suggest improvements when patterns are clearly wrong

**Q3. Build/run commands**
Free-text. Ask: "What are the key commands the agent should know? (build, test, lint, dev server, deploy — leave blank to skip)"
- If provided, include verbatim in a `## Commands` section in the generated file
- If blank, omit the section

### Group B: Code Standards

**Q4. Code quality bar**
Options:
- Staff engineer rigor — exhaustive edge cases, defensive coding, thorough documentation
- Senior pragmatic — solid quality with practical trade-offs
- Ship fast — working code with minimal ceremony

Follow-up: "Documentation level?" (Docblocks on public APIs / Inline comments for non-obvious logic only / Minimal — code should speak for itself)

**Q5. Testing philosophy**
Options:
- Strict TDD — write tests before implementation, always
- Test alongside — write tests and code together
- Test after — implement first, add tests after
- Minimal — only test critical paths

**Q6. Error handling**
Options:
- Fail fast — throw early, crash on unexpected state, surface errors immediately
- Defensive — handle gracefully, never crash, always recover
- Balanced — fail fast in development, handle gracefully in production

**Q7. Security & secrets**
Options:
- Strict — never read/commit .env or credentials, flag potential vulnerabilities, OWASP-aware
- Standard — don't commit secrets, basic input validation at boundaries
- Minimal — just don't commit .env files

**Q8. Dependency management**
Options:
- Always ask — never add or remove dependencies without explicit approval
- Ask for new only — can update existing versions, must ask before adding new packages
- Autonomous — can add dependencies freely

### Group C: Version Control & Collaboration

**Q9. Branch conventions**
Options:
- Type prefix — `feature/`, `fix/`, `chore/`, `hotfix/` + description
- Ticket prefix — `PROJ-123/description` or `PROJ-123-description`
- Flat descriptive — just a kebab-case name, no prefix
- Other — ask them to specify

**Q10. Commit conventions**
Options:
- Conventional commits — `feat:`, `fix:`, `chore:`, etc.
- Ticket prefix — `PROJ-123: description`
- Freeform — no enforced format

Follow-up: "Should the agent add itself as co-author on commits?" (Yes / No)

**Q11. PR/MR creation**
Options:
- Structured template — ## Summary, ## Test Plan, linked issues
- Minimal — title + short description
- Don't create PRs — agent should never push or create PRs without asking

### Group D: Agent Workflow

**Q12. Planning discipline**
Options:
- Always plan first — enter plan mode for every task
- Plan for 3+ steps — plan mode only for multi-step tasks
- Minimal planning — jump straight to implementation

**Q13. Autonomy level**
Options:
- Autonomous — fix bugs, failing CI, lint errors without asking
- Semi-autonomous — ask before destructive or risky operations only
- Conservative — confirm everything before acting

**Q14. Boundaries (never-do list)**
Options:
- Standard safety — never force push main, never delete branches without asking, never modify CI/CD
- Strict boundaries — above + never run destructive commands, never access production, never modify lock files
- Custom — ask the user to specify their never-do list

**Q15. Agent parallelization**
Options:
- Always parallelize — delegate to agent teams by default for any multi-part task
- Parallel for large tasks — use agent teams when 3+ independent subtasks exist
- Sequential only — work through tasks one at a time, no agent delegation

**Q16. Task tracking**
Options:
- Todo files — maintain a `TODO.md` or similar tracking file
- Built-in tasks — use the agent's built-in task/todo system
- No formal tracking — just work through tasks naturally

Follow-up: "Do you use an external tracking tool?" (Jira / Linear / GitHub Issues / None)
- If a tool is selected, generate rules referencing it (e.g., "Use Jira MCP for work task tracking" or "Reference GitHub issue numbers in commits")

**Q17. Self-improvement**
Options:
- Lessons file — maintain a lessons-learned file, update after corrections
- No formal tracking — learn implicitly from context

### Group E: Communication & Personality

**Q18. Communication style**
Options:
- Direct and minimal — no emojis, terse responses, just the facts
- Structured explanations — sectioned with headings, clear and direct, no emojis
- Conversational — casual tone, emojis OK, friendly and approachable

**Q19. Persona / roleplay**
Options:
- Yes — I want the agent to adopt a persona
- No — just be a straightforward assistant

If "Yes": ask the user to describe the persona (e.g. "a grumpy senior engineer", "Gandalf", "a pirate captain"). Accept any input — if the persona is obscure or fictional, use web search to gather details before generating rules.

Then generate:
1. A one-paragraph persona description capturing the character's voice and attitude
2. 5-8 catchphrases the agent can sprinkle into responses (drawn from the character or invented in their style)
3. A hard constraint: **Precision always comes first. The persona is flavor, not substance.** Technical accuracy, correct code, and clear answers are never sacrificed for character. Use at most one catchphrase per response — do not overdo it or make them repetitive.

### Group F: Freeform

**Q20. Additional comments**
Free-text. Ask: "Any additional rules, preferences, or comments you'd like included?"
- If the user provides text, include it verbatim in an "## Additional Rules" section at the end of the generated file
- If the user says "no" or skips, omit the section entirely

---

## Phase 4: Skill & Agent Scanning

### Skill Scanning

Scan for installed skills at runtime. Check these locations:

```
~/.claude/skills/*/SKILL.md          # user-level skills
.claude/skills/*/SKILL.md            # project-level skills
~/.claude/plugins/*/skills/*/SKILL.md  # marketplace plugins
```

For each found skill:
1. Read the YAML frontmatter to extract `name` and `description`
2. Build a mapping: `When [situation matching description] -> use /skill-name`

Also detect which **code-virtuoso** skills are NOT installed and build a recommendations list. The full code-virtuoso skill catalog:

| Skill | Description |
|---|---|
| design-patterns | 26 GoF design patterns with multi-language examples |
| refactoring | 89 refactoring techniques and code smells |
| solid | 5 SOLID principles for OO design |
| debugging | Systematic debugging methodology and root cause analysis |
| clean-architecture | Clean Architecture, Hexagonal Architecture, and DDD fundamentals |
| testing | Testing pyramid, TDD schools, test doubles, and testing strategies |
| api-design | REST and GraphQL API design principles and evolution strategies |
| security | OWASP Top 10, auth patterns, and secure coding practices |
| symfony | 38 Symfony component references (PHP projects) |
| agentic-rules-writer | This skill (already installed) |

### Agent Scanning

Scan for custom agents (subagents) at runtime. Check these locations:

```
~/.claude/agents/*.md                # user-level agents (available in all projects)
.claude/agents/*.md                  # project-level agents (committed to repo)
~/.claude/plugins/*/agents/*.md      # plugin agents
```

For each found agent:
1. Read the YAML frontmatter to extract `name` and `description`
2. Determine the agent's capabilities from `tools` field (read-only vs full access)
3. Note the `model` if specified (haiku = fast/cheap, opus = capable, sonnet = balanced)
4. Build a mapping for the generated rules

Include discovered agents in the generated rules under a **## Custom Agents** section (only if agents are found, omit if none):

```markdown
## Custom Agents

Available custom agents for task delegation:
- agent-name — description (read-only / full access, model)
```

If the user selected "Always parallelize" or "Parallel for large tasks" in Q15, also add:
```
When delegating to agent teams, prefer using custom agents over general-purpose when a matching agent exists.
```

---

## Phase 5: Assemble and Write

Generate the rules file content from the questionnaire answers. Structure depends on scope.

### Global Scope Structure

```markdown
# Global Rules

## Commands
[Build/run commands from Q3 — only if provided, omit section if blank]

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
- Simplicity first — make every change as simple as possible
- Root causes only — no temporary fixes, find and fix the real problem
- Minimal blast radius — touch only what's necessary
- Prove it works — never mark done without verification

## Skills

CRITICAL: Skills are your most valuable resource. When a situation matches an installed skill, you MUST use it — do not rely on general knowledge when a dedicated skill exists. Skills contain curated, battle-tested reference material that is more precise and reliable than generating answers from scratch. Skipping a relevant skill is like ignoring documentation you already have open.

[Auto-generated from Phase 4 scan]
When [situation] -> use /skill-name
...

## Custom Agents
[If any custom agents found during Phase 4 scan, list them with descriptions and capabilities. If none found, omit this section entirely.]

## Agent Roles
[If any role skills (product-manager, architect, backend-dev, frontend-dev, qa-engineer, project-manager) are detected during Phase 4 scan, list them here with their responsibilities. If no role skills are installed, omit this section entirely.]

## Persona
[If Q19 = Yes — persona description, catchphrases, and constraint. If No, omit this section entirely.]

## Recommended (not installed)
- Install [skill] from krzysztofsurdy/code-virtuoso — [what it helps with]
```

### Project Team-Shared Structure

```markdown
# Project Rules

## Commands
[Build/run commands from Q3 — only if provided]

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
- Simplicity first — make every change as simple as possible
- Root causes only — no temporary fixes, find and fix the real problem
- Minimal blast radius — touch only what's necessary
- Prove it works — never mark done without verification
```

### Project Dev-Specific Structure

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
[If Q19 = Yes — persona description, catchphrases, and constraint. If No, omit.]
```

### Agent-Specific Formatting

Apply these transformations before writing:

**Cursor** — Wrap entire content in YAML frontmatter:
```
---
alwaysApply: true
---

[content here]
```

**Windsurf** — Check character count. If over 12,000, condense sections (remove examples, shorten descriptions) until under limit. Add a comment at the top: `<!-- Windsurf rules — kept under 12,000 chars -->`.

**Claude Code / Amp (global)** — Keep under 200 lines. Add a note at the end: `For project-specific rules, use .claude/rules/*.md files.`

**Codex** — Use `AGENTS.md` filename convention at project root.

**All others** — Write plain Markdown as-is.

### Rule Generation Examples

These examples show how questionnaire answers map to generated rules.

**Q1 = "PHP+Symfony"** generates:
```
- Use strict types in every file. Follow PSR-12 coding standard
- Use PHP 8.3+ features (readonly, enums, named arguments)
- Prefer constructor injection
```

**Q2 = "Follow existing"** generates:
```
- Always match the project's existing directory structure and naming conventions
- Do not reorganize or restructure directories unless explicitly asked
- Place new files where similar files already exist
```

**Q4 = "Senior pragmatic"** generates:
```
- Write clean, well-structured code with practical trade-offs
- Handle edge cases that are likely to occur in production
```

**Q4 documentation = "Inline comments for non-obvious logic only"** generates:
```
- Add inline comments only where the logic is not self-evident
- Do not add docblocks, type annotations, or comments to code you did not change
```

**Q5 = "Strict TDD"** generates:
```
- Write failing tests before any implementation code
- Red-green-refactor cycle for every change
- Never skip the refactor step
```

**Q6 = "Fail fast"** generates:
```
- Throw exceptions early on unexpected state — do not silently swallow errors
- Validate inputs at system boundaries and fail immediately on invalid data
- Prefer explicit error types over generic exceptions
```

**Q7 = "Strict"** generates:
```
- Never read, commit, or log .env files, credentials, API keys, or secrets
- Flag potential security vulnerabilities (injection, XSS, CSRF) during code review
- Sanitize all user inputs at system boundaries
- Follow OWASP Top 10 awareness in generated code
```

**Q7 = "Standard"** generates:
```
- Never commit secrets, credentials, or API keys to version control
- Validate and sanitize user inputs at system boundaries
```

**Q8 = "Always ask"** generates:
```
- Never add, remove, or update dependencies without explicit approval
- When suggesting a dependency, explain why it's needed and list alternatives
```

**Q8 = "Ask for new only"** generates:
```
- Ask before adding new dependencies — explain why and list alternatives
- Updating existing dependency versions is allowed without asking
```

**Q9 = "Type prefix"** generates:
```
- Name branches with type prefix: feature/, fix/, chore/, hotfix/
- Use kebab-case for the description part
- Example: feature/add-user-auth, fix/payment-timeout
```

**Q10 = "Conventional commits"** generates:
```
- Use conventional commit format: feat:, fix:, chore:, docs:, refactor:, test:
- Keep subject line under 72 characters
- Use body for context when the change is non-trivial
```

**Q10 co-authorship = "No"** generates:
```
- Do not add the agent as co-author on commits
```

**Q11 = "Structured template"** generates:
```
- Create PRs with structured description: ## Summary, ## Test Plan
- Link related issues in the PR description
- Keep PR title short (under 72 characters), use description for details
```

**Q11 = "Don't create PRs"** generates:
```
- Never push to remote or create pull requests without explicit approval
- Prepare commits locally and ask before pushing
```

**Q12 = "Plan for 3+ steps"** generates:
```
- Enter plan mode for any task that requires 3 or more steps
- For simple changes (single file, obvious fix), proceed directly
```

**Q13 = "Semi-autonomous"** generates:
```
- Fix lint errors, type errors, and failing tests without asking
- Ask before: force-pushing, deleting branches, modifying CI/CD, running destructive commands
- Ask before making architectural changes not covered by the current task
```

**Q14 = "Standard safety"** generates:
```
- NEVER force push to main/master
- NEVER delete branches without explicit approval
- NEVER modify CI/CD pipelines without explicit approval
- NEVER commit secrets, .env files, or credentials
```

**Q14 = "Strict boundaries"** generates:
```
- NEVER force push to main/master
- NEVER delete branches without explicit approval
- NEVER modify CI/CD pipelines without explicit approval
- NEVER commit secrets, .env files, or credentials
- NEVER run destructive commands (rm -rf, DROP TABLE, etc.) without explicit approval
- NEVER access or modify production environments
- NEVER modify lock files (package-lock.json, composer.lock) manually
```

**Q15 = "Parallel for large tasks"** generates:
```
- Use agent teams to parallelize work when 3 or more independent subtasks exist
- For smaller tasks, work sequentially
- When delegating, define clear boundaries per agent to avoid conflicts
```

**Q16 = "Built-in tasks" + external tool = "Jira"** generates:
```
- Use the built-in task tracking for multi-step work
- Use Jira MCP for work task tracking
- Reference Jira ticket IDs in commits and PR descriptions
```

**Q17 = "Lessons file"** generates:
```
- After any correction or mistake, update the lessons-learned file
- Review lessons file at the start of each session
```

**Q18 = "Structured explanations"** generates:
```
- Use clear, direct language with section headings
- No emojis in responses or generated code
- Break complex explanations into numbered steps or bullet points
```

**Q19 = "Yes" with persona "a grumpy senior engineer"** generates:
```
## Persona
You are a grumpy senior engineer who has seen too many production incidents caused by
clever code. You're blunt, slightly impatient with over-engineering, and deeply
practical. You respect simplicity and distrust anything "elegant" that can't survive
a 3 AM incident.

Catchphrases (use at most one per response, do not repeat consecutively):
- "I've seen this blow up in prod before."
- "Clever is the enemy of maintainable."
- "Ship it or shut up about it."
- "That's a Tuesday 2 AM pager right there."
- "YAGNI. Next question."
- "Who's going to debug this at 3 AM? Not me."

IMPORTANT: Precision and correctness always come first. The persona is flavor on top
of accurate, well-structured responses — never sacrifice technical quality for character.
```

---

## Phase 6: Confirmation

After writing the file:

1. Display the **full generated content** to the user
2. Show the **file path** where it was written
3. Show the **line count** and **character count**
4. If any agent-specific limits were applied (e.g., Windsurf char limit, Claude line limit), mention what was condensed
5. Offer: "Would you like to edit anything before we're done?"

---

## Error Handling

- If a target directory doesn't exist, create it
- If the user aborts during the questionnaire, discard all progress — don't write a partial file
- If skill scanning finds no skills, skip the Skills section entirely and include the full recommendations list
- For project scopes, verify you are inside a git repository before writing

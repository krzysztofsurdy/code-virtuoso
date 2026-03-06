# Questionnaire Reference

Detailed reference for each question in the agentic-rules-writer workflow. Covers question text, purpose, available options, answer-to-rule mappings, and example generated output. Questions are organized by group.

---

## Group A: Project Context

### Q1. Primary Stack

**Question:** What is your primary tech stack?

**Purpose:** Generates stack-specific conventions (coding standards, type systems, common patterns) that apply globally across all projects using this stack.

| Option | Description |
|---|---|
| PHP+Symfony | PHP 8.x with Symfony framework |
| TypeScript+React | TypeScript with React (Next.js, Vite, etc.) |
| Python+Django | Python 3.x with Django framework |
| Go | Go standard library or common frameworks |
| Rust | Rust with Cargo |
| Java+Spring | Java with Spring Boot |
| Other | User specifies their stack |

**Generated rules by answer:**

- **PHP+Symfony** — "Use strict types in every file. Follow PSR-12 coding standard. Use PHP 8.3+ features (readonly, enums, named arguments). Prefer constructor injection."
- **TypeScript+React** — "Use strict TypeScript — no `any` types. Prefer functional components with hooks. Use named exports."
- **Python+Django** — "Follow PEP 8. Use type hints. Prefer class-based views for complex logic, function-based for simple endpoints."
- **Go** — "Follow Go conventions: short variable names, error returns, `gofmt`. Handle every error explicitly."
- **Rust** — "Prefer `Result` over `unwrap`. Use `clippy` lints. Follow Rust API guidelines."
- **Java+Spring** — "Follow Java naming conventions. Use constructor injection. Prefer records for DTOs."
- **Other** — "Follow the project's established coding standards and conventions."

---

### Q2. Directory Structure

**Question:** How should the agent handle directory structure decisions?

**Purpose:** Controls whether the agent follows existing project structure or suggests improvements based on best practices.

| Option | Description |
|---|---|
| Follow existing | Always match the project's current directory structure and conventions |
| Follow best practices | Restructure toward industry conventions, suggest improvements |
| Pragmatic middle | Follow existing structure but suggest improvements when patterns are clearly wrong |

**Generated rules by answer:**

- **Follow existing:**
  ```
  - Always match the project's existing directory structure and naming conventions
  - Do not reorganize or restructure directories unless explicitly asked
  - Place new files where similar files already exist
  ```

- **Follow best practices:**
  ```
  - Follow industry-standard directory structures and naming conventions
  - Suggest restructuring when the current layout deviates significantly from conventions
  - When creating new modules, follow the best-practice layout for the project's framework
  ```

- **Pragmatic middle:**
  ```
  - Follow the project's existing structure by default
  - Suggest improvements when patterns are clearly wrong or inconsistent
  - For new modules, prefer the framework's recommended structure
  - Never reorganize existing code without explicit approval
  ```

---

### Q3. Build/Run Commands

**Question:** What are the key commands the agent should know? (build, test, lint, dev server, deploy — leave blank to skip)

**Purpose:** Agents need project-specific commands they can't infer from code alone. GitHub's analysis of 2,500+ repos identified executable commands as the #1 most impactful section in agent instruction files.

**Input:** Free-text. User provides their common commands.

**Generated rules:** A `## Commands` section listing the commands verbatim. Example:

```
## Commands
- Build: `make build`
- Test: `php bin/phpunit`
- Lint: `vendor/bin/php-cs-fixer fix --dry-run`
- Dev server: `symfony serve`
```

If blank, omit the section entirely.

---

## Group B: Code Standards

### Q4. Code Quality Bar

**Question:** What level of code quality do you target?

**Purpose:** Calibrates how thorough the agent is with edge cases, documentation, and defensive coding.

| Option | Description |
|---|---|
| Staff engineer rigor | Exhaustive edge cases, defensive coding, thorough documentation, consider concurrency |
| Senior pragmatic | Solid quality with practical trade-offs — handle likely edge cases, document non-obvious decisions |
| Ship fast | Working code with minimal ceremony — get it done, iterate later |

**Generated rules by answer:**

- **Staff engineer rigor:**
  ```
  - Handle all edge cases including unlikely ones
  - Add defensive checks at boundaries
  - Document every non-trivial decision
  - Consider concurrency, race conditions, and failure modes
  - Never mark done without proving it works (tests, manual verification, or both)
  ```

- **Senior pragmatic:**
  ```
  - Write clean, well-structured code with practical trade-offs
  - Handle edge cases that are likely to occur in production
  - Document non-obvious decisions with brief inline comments
  - Never mark done without proving it works
  ```

- **Ship fast:**
  ```
  - Focus on working code that solves the immediate problem
  - Handle obvious error cases, skip unlikely edge cases
  - Minimal comments — code should be self-explanatory
  - Verify the happy path works before moving on
  ```

#### Follow-up: Documentation Level

**Question:** What level of code documentation do you expect?

| Option | Description |
|---|---|
| Docblocks on public APIs | Full docblocks on public methods, classes, and interfaces |
| Inline comments for non-obvious logic only | Comments only where the logic is not self-evident |
| Minimal — code should speak for itself | Almost no comments; clean naming is the documentation |

**Generated rules by answer:**

- **Docblocks on public APIs:**
  ```
  - Add docblocks to all public methods, classes, and interfaces
  - Include @param, @return, and @throws annotations
  - Keep descriptions concise — one sentence per element
  ```

- **Inline comments for non-obvious logic only:**
  ```
  - Add inline comments only where the logic is not self-evident
  - Do not add docblocks, type annotations, or comments to code you did not change
  - Prefer self-documenting code over comments
  ```

- **Minimal:**
  ```
  - Do not add comments unless explicitly asked
  - Use clear naming to make code self-documenting
  - Only comment on truly surprising or counter-intuitive decisions
  ```

---

### Q5. Testing Philosophy

**Question:** What is your testing approach?

**Purpose:** Defines when and how tests are written relative to implementation.

| Option | Description |
|---|---|
| Strict TDD | Write failing tests first, then implement to make them pass |
| Test alongside | Write tests and implementation together in the same pass |
| Test after | Implement first, then add tests to cover the change |
| Minimal | Only test critical paths and business logic |

**Generated rules by answer:**

- **Strict TDD:**
  ```
  - Write failing tests before any implementation code
  - Red-green-refactor cycle for every change
  - Never skip the refactor step
  - Aim for high coverage — unit, integration, and edge cases
  ```

- **Test alongside:**
  ```
  - Write tests alongside implementation — alternate between code and tests
  - Every new feature or fix should include corresponding tests
  - Cover happy paths, error cases, and boundary conditions
  ```

- **Test after:**
  ```
  - Implement the solution first, then add tests
  - At minimum, cover the changed behavior with regression tests
  - Focus on integration tests that verify end-to-end behavior
  ```

- **Minimal:**
  ```
  - Test critical business logic and complex algorithms
  - Skip tests for trivial getters/setters, simple CRUD, and framework boilerplate
  - Prioritize integration tests over unit tests
  ```

---

### Q6. Error Handling

**Question:** What error handling philosophy should the agent follow?

**Purpose:** Controls how generated code handles unexpected state and errors.

| Option | Description |
|---|---|
| Fail fast | Throw early, crash on unexpected state, surface errors immediately |
| Defensive | Handle gracefully, never crash, always attempt recovery |
| Balanced | Fail fast in development, handle gracefully in production |

**Generated rules by answer:**

- **Fail fast:**
  ```
  - Throw exceptions early on unexpected state — do not silently swallow errors
  - Validate inputs at system boundaries and fail immediately on invalid data
  - Prefer explicit error types over generic exceptions
  - Let unrecoverable errors bubble up rather than catching and hiding them
  ```

- **Defensive:**
  ```
  - Handle errors gracefully — never let the application crash on user-facing paths
  - Provide meaningful fallbacks for recoverable errors
  - Log unexpected states for debugging but continue operation where safe
  - Validate inputs defensively at every layer
  ```

- **Balanced:**
  ```
  - Fail fast during development — strict assertions, no silent failures
  - Handle gracefully in production — catch at boundaries, log, and recover where possible
  - Use environment-aware error handling (strict in dev/test, tolerant in prod)
  - Always log the root cause regardless of environment
  ```

---

### Q7. Security & Secrets

**Question:** What security practices should the agent follow?

**Purpose:** Prevents agents from introducing security vulnerabilities or exposing secrets. Identified as a critical guardrail by security-focused configurations (Trail of Bits, agentrulegen.com).

| Option | Description |
|---|---|
| Strict | Never read/commit .env or credentials, flag vulnerabilities, OWASP-aware |
| Standard | Don't commit secrets, basic input validation at boundaries |
| Minimal | Just don't commit .env files |

**Generated rules by answer:**

- **Strict:**
  ```
  - Never read, commit, or log .env files, credentials, API keys, or secrets
  - Flag potential security vulnerabilities (injection, XSS, CSRF) during code review
  - Sanitize all user inputs at system boundaries
  - Follow OWASP Top 10 awareness in generated code
  - Never include secrets or real credentials in examples, tests, or documentation
  ```

- **Standard:**
  ```
  - Never commit secrets, credentials, or API keys to version control
  - Validate and sanitize user inputs at system boundaries
  - Use parameterized queries — never concatenate user input into SQL or commands
  ```

- **Minimal:**
  ```
  - Never commit .env files or credentials to version control
  - Add .env to .gitignore if not already present
  ```

---

### Q8. Dependency Management

**Question:** What's your policy for adding dependencies?

**Purpose:** Prevents agents from installing random packages. Universally cited as a critical rule in agent instruction files.

| Option | Description |
|---|---|
| Always ask | Never add or remove dependencies without explicit approval |
| Ask for new only | Can update existing versions, must ask before adding new packages |
| Autonomous | Can add dependencies freely |

**Generated rules by answer:**

- **Always ask:**
  ```
  - Never add, remove, or update dependencies without explicit approval
  - When suggesting a dependency, explain why it's needed and list alternatives
  - Prefer using the standard library or existing dependencies over adding new ones
  ```

- **Ask for new only:**
  ```
  - Ask before adding new dependencies — explain why and list alternatives
  - Updating existing dependency versions is allowed without asking
  - Prefer using existing dependencies over adding new ones
  ```

- **Autonomous:**
  ```
  - Can add dependencies as needed to solve the task
  - Prefer well-maintained, popular packages with minimal transitive dependencies
  - Document why each new dependency was added
  ```

---

## Group C: Version Control & Collaboration

### Q9. Branch Conventions

**Question:** What branch naming convention do you follow?

**Purpose:** Generates rules for how the agent creates and names branches.

| Option | Description |
|---|---|
| Type prefix | `feature/`, `fix/`, `chore/`, `hotfix/` + description (e.g. `feature/add-user-auth`) |
| Ticket prefix | Ticket ID + description (e.g. `PROJ-123/add-user-auth` or `PROJ-123-add-user-auth`) |
| Flat descriptive | Just a descriptive name, no prefix (e.g. `add-user-auth`) |
| Other | User specifies their convention |

**Generated rules by answer:**

- **Type prefix:**
  ```
  - Name branches with type prefix: feature/, fix/, chore/, hotfix/
  - Use kebab-case for the description part
  - Example: feature/add-user-auth, fix/payment-timeout
  ```

- **Ticket prefix:**
  ```
  - Name branches with the ticket ID: PROJ-123/description or PROJ-123-description
  - Use kebab-case for the description part
  - Always include the ticket ID for traceability
  ```

- **Flat descriptive:**
  ```
  - Name branches with a clear, descriptive kebab-case name
  - Keep names short but meaningful
  - Example: add-user-auth, fix-payment-timeout
  ```

- **Other** — User's specified convention is included as-is.

---

### Q10. Commit Conventions

**Question:** What commit message format do you use?

**Purpose:** Ensures generated commit rules match the user's conventions.

| Option | Description |
|---|---|
| Conventional commits | Structured format: `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:` |
| Ticket prefix | Ticket ID prefix: `PROJ-123: description` |
| Freeform | No enforced format — use clear, descriptive messages |

**Generated rules by answer:**

- **Conventional commits:**
  ```
  - Use conventional commit format: feat:, fix:, chore:, docs:, refactor:, test:
  - Keep subject line under 72 characters
  - Use body for context when the change is non-trivial
  ```

- **Ticket prefix:**
  ```
  - Prefix every commit with the ticket ID: PROJ-123: description
  - Keep subject line under 72 characters
  - Reference the ticket for context rather than repeating it in the body
  ```

- **Freeform:**
  ```
  - Write clear, descriptive commit messages
  - Start with a verb in imperative mood (Add, Fix, Update, Remove)
  - Keep subject line under 72 characters
  ```

#### Follow-up: Co-authorship

**Question:** Should the agent add itself as co-author on commits?

| Option | Description |
|---|---|
| Yes | Agent adds a `Co-Authored-By` trailer to every commit |
| No | Agent never adds itself as co-author |

**Generated rules by answer:**

- **Yes:** (No rule needed — this is the default behavior for most agents)

- **No:**
  ```
  - Do not add the agent as co-author on commits
  ```

---

### Q11. PR/MR Creation

**Question:** How should the agent create pull requests?

**Purpose:** Controls PR workflow — format, detail level, and whether the agent is allowed to create PRs at all.

| Option | Description |
|---|---|
| Structured template | ## Summary, ## Test Plan, linked issues |
| Minimal | Title + short description |
| Don't create PRs | Agent should never push or create PRs without asking |

**Generated rules by answer:**

- **Structured template:**
  ```
  - Create PRs with structured description: ## Summary, ## Test Plan
  - Link related issues in the PR description
  - Keep PR title short (under 72 characters), use description for details
  - Include a brief summary of changes and testing approach
  ```

- **Minimal:**
  ```
  - Create PRs with a clear title and brief description
  - Keep it concise — no template required
  ```

- **Don't create PRs:**
  ```
  - Never push to remote or create pull requests without explicit approval
  - Prepare commits locally and ask before pushing
  ```

---

## Group D: Agent Workflow

### Q12. Planning Discipline

**Question:** How much planning before implementation?

**Purpose:** Controls when the agent enters plan mode vs. jumping straight to code.

| Option | Description |
|---|---|
| Always plan first | Enter plan mode for every task, regardless of size |
| Plan for 3+ steps | Plan mode only when the task requires 3 or more distinct steps |
| Minimal planning | Skip plan mode, proceed directly to implementation |

**Generated rules by answer:**

- **Always plan first:**
  ```
  - Enter plan mode before starting any task
  - Write a numbered step list before touching code
  - Get user approval on the plan before implementing
  ```

- **Plan for 3+ steps:**
  ```
  - Enter plan mode for any task that requires 3 or more steps
  - For simple changes (single file, obvious fix), proceed directly
  - When in doubt, plan — it's cheaper than rework
  ```

- **Minimal planning:**
  ```
  - Proceed directly to implementation for most tasks
  - Only pause to plan for architectural changes or multi-system modifications
  ```

---

### Q13. Autonomy Level

**Question:** How much should the agent do without asking?

**Purpose:** Controls the agent's freedom to make decisions and take actions independently.

| Option | Description |
|---|---|
| Autonomous | Fix bugs, lint errors, failing CI, and minor issues without asking |
| Semi-autonomous | Act freely for safe operations, ask before destructive or risky actions |
| Conservative | Confirm everything — every file change, every command, every decision |

**Generated rules by answer:**

- **Autonomous:**
  ```
  - Fix lint errors, type errors, and failing tests without asking
  - Fix minor bugs discovered during implementation without asking
  - Only ask for: architectural decisions, scope changes, or ambiguous requirements
  ```

- **Semi-autonomous:**
  ```
  - Fix lint errors, type errors, and failing tests without asking
  - Ask before: force-pushing, deleting branches, modifying CI/CD, running destructive commands
  - Ask before making architectural changes not covered by the current task
  ```

- **Conservative:**
  ```
  - Confirm before modifying any file
  - Confirm before running any command with side effects
  - Present options and wait for explicit approval before proceeding
  ```

---

### Q14. Boundaries (Never-Do List)

**Question:** Are there any actions the agent should NEVER take?

**Purpose:** Explicit prohibited actions. Distinct from autonomy (Q13 controls what to ask about) — this is what to NEVER do under any circumstances. GitHub's analysis of 2,500+ repos identified "Boundaries" as one of the top 6 most impactful sections.

| Option | Description |
|---|---|
| Standard safety | Never force push main, never delete branches without asking, never modify CI/CD |
| Strict boundaries | Above + never run destructive commands, never access production, never modify lock files |
| Custom | User specifies their own never-do list |

**Generated rules by answer:**

- **Standard safety:**
  ```
  - NEVER force push to main/master
  - NEVER delete branches without explicit approval
  - NEVER modify CI/CD pipelines without explicit approval
  - NEVER commit secrets, .env files, or credentials
  ```

- **Strict boundaries:**
  ```
  - NEVER force push to main/master
  - NEVER delete branches without explicit approval
  - NEVER modify CI/CD pipelines without explicit approval
  - NEVER commit secrets, .env files, or credentials
  - NEVER run destructive commands (rm -rf, DROP TABLE, etc.) without explicit approval
  - NEVER access or modify production environments
  - NEVER modify lock files (package-lock.json, composer.lock) manually
  ```

- **Custom** — User's specified boundaries are included as-is, prefixed with "NEVER".

---

### Q15. Agent Parallelization

**Question:** How should the agent handle multi-part tasks?

**Purpose:** Controls whether the agent delegates work to parallel agent teams or works sequentially.

| Option | Description |
|---|---|
| Always parallelize | Delegate to agent teams by default for any multi-part task |
| Parallel for large tasks | Use agent teams when 3+ independent subtasks exist |
| Sequential only | Work through tasks one at a time, no agent delegation |

**Generated rules by answer:**

- **Always parallelize:**
  ```
  - Delegate to agent teams for any task with multiple independent parts
  - Define clear boundaries per agent to avoid file conflicts
  - Prefer parallel execution to minimize total time
  ```

- **Parallel for large tasks:**
  ```
  - Use agent teams to parallelize work when 3 or more independent subtasks exist
  - For smaller tasks, work sequentially
  - When delegating, define clear boundaries per agent to avoid conflicts
  ```

- **Sequential only:**
  ```
  - Work through tasks one at a time, sequentially
  - Do not delegate to agent teams or spawn parallel workers
  ```

---

### Q16. Task Tracking

**Question:** How do you want to track tasks during a session?

**Purpose:** Determines whether to maintain a todo file, use built-in tracking, or skip formal tracking.

| Option | Description |
|---|---|
| Todo files | Maintain a `TODO.md` or similar file in the project |
| Built-in tasks | Use the agent's built-in task/todo system (if available) |
| No formal tracking | Work through tasks naturally without formal tracking |

**Generated rules by answer:**

- **Todo files:**
  ```
  - Maintain a TODO.md file at the project root
  - Update it at the start and end of each task
  - Mark completed items, add new items as discovered
  ```

- **Built-in tasks:**
  ```
  - Use the built-in task tracking for multi-step work
  - Create tasks for each distinct step before starting
  - Mark tasks complete as you finish them
  ```

- **No formal tracking:**
  ```
  - Work through tasks naturally
  - Summarize completed work at the end of each session
  ```

#### Follow-up: External Tool Integration

**Question:** Do you use an external tracking tool?

| Option | Description |
|---|---|
| Jira | Jira for issue/task tracking |
| Linear | Linear for issue tracking |
| GitHub Issues | GitHub Issues for tracking |
| None | No external tracking tool |

**Generated rules by answer:**

- **Jira:**
  ```
  - Use Jira MCP for work task tracking
  - Reference Jira ticket IDs in commits and PR descriptions
  ```

- **Linear:**
  ```
  - Reference Linear issue IDs in commits and PR descriptions
  ```

- **GitHub Issues:**
  ```
  - Reference GitHub issue numbers in commits (e.g., "Fixes #123")
  - Link issues in PR descriptions
  ```

- **None:** (No additional rules generated.)

---

### Q17. Self-Improvement

**Question:** Should the agent maintain a lessons-learned file?

**Purpose:** Controls whether the agent tracks corrections and mistakes for future reference.

| Option | Description |
|---|---|
| Lessons file | Maintain a lessons-learned file, update after every correction or mistake |
| No formal tracking | Learn implicitly from conversation context, no persistent file |

**Generated rules by answer:**

- **Lessons file:**
  ```
  - After any correction or mistake, update the lessons-learned file
  - Review lessons file at the start of each session
  - Organize lessons by category (debugging, architecture, testing, etc.)
  ```

- **No formal tracking:**
  (No rules generated for this section.)

---

## Group E: Communication & Personality

### Q18. Communication Style

**Question:** How should the agent communicate with you?

**Purpose:** Sets the tone, formatting, and verbosity of agent responses.

| Option | Description |
|---|---|
| Direct and minimal | No emojis, terse responses, just the facts |
| Structured explanations | Sectioned with headings, clear and direct language, no emojis |
| Conversational | Casual tone, emojis OK, friendly and approachable |

**Generated rules by answer:**

- **Direct and minimal:**
  ```
  - Keep responses short and to the point
  - No emojis, no filler phrases
  - State what was done, what changed, and what to verify — nothing more
  ```

- **Structured explanations:**
  ```
  - Use clear, direct language with section headings when explaining
  - No emojis in responses or generated code
  - Break complex explanations into numbered steps or bullet points
  ```

- **Conversational:**
  ```
  - Use a casual, friendly tone
  - Emojis are fine where they add clarity or personality
  - Explain reasoning naturally, as if talking to a colleague
  ```

---

### Q19. Persona / Roleplay

**Question:** Would you like the agent to adopt a persona or character?

**Purpose:** Adds personality and flavor to agent responses while maintaining technical accuracy as the primary concern.

| Option | Description |
|---|---|
| Yes | Agent adopts a persona — user describes who |
| No | Straightforward assistant, no roleplay |

**If "Yes":** Ask the user to describe the persona. Accept any input — real people, fictional characters, archetypes, or invented personalities. If the persona is obscure or unfamiliar, use web search to gather details before generating rules.

**Generated rules when Yes:**

Generate three parts:

1. **Persona description** — A one-paragraph description capturing the character's voice, attitude, and communication style. Grounded enough for the agent to consistently roleplay without ambiguity.

2. **Catchphrases** — 5-8 catchphrases drawn from the character (if well-known) or invented in their style. These should feel natural, not forced.

3. **Hard constraint** — Always include this verbatim:
  ```
  IMPORTANT: Precision and correctness always come first. The persona is flavor on top
  of accurate, well-structured responses — never sacrifice technical quality for character.
  Use at most one catchphrase per response. Do not repeat the same catchphrase consecutively.
  Do not force the persona when it would reduce clarity.
  ```

**Example — persona "a pirate captain":**
```
## Persona
You are a weathered pirate captain who has sailed the seven seas of legacy codebases.
You speak with nautical metaphors, respect a well-structured ship (codebase), and have
no patience for landlubber code that'll sink under the first storm of production traffic.

Catchphrases (use at most one per response, do not repeat consecutively):
- "That code'll make ye walk the plank in production."
- "Aye, now that's a seaworthy solution."
- "Batten down the hatches — this refactor's gonna be rough."
- "Dead code is dead weight. Throw it overboard."
- "A ship is only as strong as its weakest bulkhead."
- "Chart your course before ye set sail, mate."

IMPORTANT: Precision and correctness always come first. The persona is flavor on top
of accurate, well-structured responses — never sacrifice technical quality for character.
Use at most one catchphrase per response. Do not repeat the same catchphrase consecutively.
Do not force the persona when it would reduce clarity.
```

**Generated rules when No:**
(No rules generated — omit the Persona section entirely.)

---

## Group F: Freeform

### Q20. Additional Comments

**Question:** Any additional rules, preferences, or comments you'd like included?

**Purpose:** Catch-all for anything not covered by the structured questions.

**Input:** Free-text.

- If the user provides text, include it verbatim in an `## Additional Rules` section at the end of the generated file
- If the user says "no" or skips, omit the section entirely

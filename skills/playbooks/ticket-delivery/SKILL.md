---
name: ticket-delivery
description: End-to-end ticket workflow from ticket analysis through investigation, planning, TDD implementation, committing, and PR creation. Adapts to your environment via a supplement file created on first run. Use when starting work on a ticket, implementing a feature end-to-end, or following a structured development workflow from ticket to PR.
user-invocable: true
argument-hint: "<ticket-id>"
---

# Ticket Workflow

This workflow takes a ticket ID and drives it through analysis, codebase investigation, planning, TDD implementation, committing, and PR creation. An interactive supplement, created on first run, adapts it to your stack.

## Phase 0: Environment supplement

Before anything else, check for a supplement file stored alongside this skill (e.g., `.supplement.md` in the skill directory).

### If the supplement exists
Read the file and load all `$VARIABLE` values for use throughout the workflow.

### If the supplement is missing
Run an interactive setup. Present an interactive prompt (or the platform's equivalent) for each question, wait for the answer, then move to the next. Save all answers to a supplement file stored alongside this skill (e.g., `.supplement.md` in the skill directory).

**Questions to ask** (see [supplement reference](references/supplement-questions.md) for full details):

1. **Ticket system:** GitHub Issues / GitLab Issues / Jira / Linear / Other? Integration tool name for fetching tickets?
2. **Version control:** Bitbucket / GitHub / GitLab? CLI tool (`gh`, `glab`)? Main branch name?
3. **Error tracking:** Bugsnag / Datadog / Sentry / none? Integration tool name?
4. **Logging:** CloudWatch / Datadog / ELK / Grafana / none? Tool access or manual paste?
5. **Database:** ORM (ActiveRecord / Doctrine / Eloquent / Prisma / TypeORM / none)? Read-only query command?
6. **CI/CD hooks:** Pre-commit hooks to skip? (e.g., `SKIP=lint,test git commit`)
7. **Testing framework:** Go test / Jest / PHPUnit / pytest / RSpec / other? TDD style preference (London / Chicago)?
8. **Architecture:** Monolith / microservices? Admin panel? API layer (REST / GraphQL / both)?
9. **PR conventions:** Branch naming pattern? Commit message format?

After saving, confirm: "Supplement saved. You can edit it anytime at the supplement file path or delete it to re-run setup."

---

## Delegation strategy

When a multi-agent team is available, the coordinating agent can delegate parallel investigation to specialized sub-agents.

### Approach
| Strategy | Purpose |
|---|---|
| **Coordinating agent** | Runs the full workflow, delegates investigation, reviews results |
| **Investigation sub-agents (x1-3)** | Explore specific codebase layers in parallel during Phase 3 |
| **Implementation sub-agent** | Runs TDD cycles during Phase 6 (or the coordinating agent does this directly) |

Delegate only when the ticket scope justifies parallel investigation. For small bug fixes, a single agent can do everything.

---

## Phase 1: Ticket intelligence gathering

### Step 1.1: Fetch ticket details

**If `$TICKET_MCP_TOOL` is configured:**
```
Use $TICKET_MCP_TOOL to fetch ticket $TICKET_ID
```

**If no integration tool is configured:**
Ask the developer: "Please paste the ticket title, description, and acceptance criteria."

### Step 1.2: Parse ticket information
Extract and organize:
- **Title** and **description**
- **Acceptance criteria** (numbered list)
- **Ticket type** (bug / feature / improvement / refactor)
- **Priority** and **linked tickets**
- **Attachments or screenshots** (note them for later)

### Step 1.3: Fetch error context (bugs only)

**If `$ERROR_TRACKING_MCP_TOOL` is configured and the ticket is a bug:**
```
Use $ERROR_TRACKING_MCP_TOOL to fetch error details linked in the ticket
```
Extract: stack trace, affected file paths, frequency, first/last seen.

**If no integration tool is configured:** Ask the developer to paste relevant error details or stack traces.

### Step 1.4: Fetch log context (if applicable)

**If `$LOGGING_TOOL` is configured:**
Fetch relevant log entries around the error timeframe.

**If manual:** Ask the developer to paste relevant log snippets if available.

### Step 1.5: Summarize findings
Present a structured summary:
```
TICKET: $TICKET_ID
TYPE: [bug|feature|improvement|refactor]
SUMMARY: [one-line summary]
ACCEPTANCE CRITERIA: [numbered list]
ERROR CONTEXT: [if bug - stack trace summary, affected files]
INITIAL HYPOTHESES: [2-3 possible approaches]
```

Ask the developer: "Does this look correct? Any additional context before I investigate the codebase?"

---

## Phase 2: Branch setup

```bash
git fetch origin
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH
```

Do NOT create a feature branch yet. That happens in Phase 5, after planning.

---

## Phase 3: Codebase investigation

Investigate the codebase to understand the area the ticket affects. Adapt the investigation to your project's architecture (`$ARCHITECTURE`).

### Investigation areas

Run these in parallel when using sub-agents, or one after another as a single agent:

#### 3a: Entity / model layer
- Find domain models or entities related to the ticket
- Check properties, relationships, validation rules
- If using an ORM (`$ORM`): check mappings, migrations, schema

#### 3b: Service / business logic layer
- Find services, handlers, use cases related to the ticket
- Trace the execution flow from entry point to persistence
- Identify dependencies and collaborators

#### 3c: API layer (if applicable)
- **REST**: Find controllers, routes, request/response DTOs
- **GraphQL**: Find types, resolvers, mutations related to the feature
- Check authentication/authorization on relevant endpoints

#### 3d: Admin panel (if configured)
- If the ticket involves admin functionality, investigate admin controllers or configuration
- Check how admin interfaces relate to the underlying models

#### 3e: Repository / data access layer
- Find repositories, query builders, or data access objects
- Understand existing query patterns for the affected area
- If read-only queries are available (`$DB_QUERY_COMMAND`): verify current data state if relevant

#### 3f: Test layer
- Find existing tests for the affected area
- Identify test patterns used (unit, integration, functional)
- Note any test fixtures, factories, or helpers

### Investigation summary
After all areas are explored, compile:
```
AFFECTED FILES: [list of files that will likely need changes]
DEPENDENCIES: [services, classes, interfaces involved]
EXISTING TESTS: [test files covering the affected area]
DATABASE IMPACT: [schema changes needed, if any]
API IMPACT: [endpoint changes, if any]
RISK AREAS: [parts of the codebase that could break]
```

---

## Phase 4: Implementation planning

Create a detailed plan before writing any code.

### Step 4.1: Plan structure
```
## Implementation Plan for $TICKET_ID

### Changes Required
1. [File path] - [What changes and why]
2. [File path] - [What changes and why]
...

### New Files
1. [File path] - [Purpose]
...

### Test Plan
1. [Test file] - [What to test]
2. [Test file] - [What to test]
...

### Migration / Schema Changes
[If applicable]

### Order of Operations
1. [First step - typically write failing tests]
2. [Second step]
...
```

### Step 4.2: Design consultation
If the implementation involves design decisions, consider consulting specialized skills:

| Situation | Recommended Skill |
|---|---|
| Design patterns needed | `design-patterns` |
| Code smells / refactoring | `refactoring` |
| SOLID principles | `solid` |
| PR message writing | `pr-message-writer` |
| Work summary report | `report-writer` |

### Step 4.3: Plan approval
Present the plan to the developer and wait for approval before continuing.
"Here is my implementation plan. Shall I proceed, or would you like changes?"

---

## Phase 5: Branch creation

After plan approval, create the feature branch.

**Using `$BRANCH_PATTERN` from the supplement:**
```bash
git checkout -b $BRANCH_PATTERN
```

Example patterns:
- `feat/PROJ-123-short-description`
- `fix/PROJ-123-short-description`
- `PROJ-123/short-description`

---

## Phase 6: TDD implementation

Follow a strict TDD cycle. Use `$TEST_COMMAND` from the supplement.

### Step 6.1: Write failing tests first
For each item in the test plan:
1. Write the test
2. Run it to confirm it fails: `$TEST_COMMAND path/to/TestFile`
3. Confirm the failure is for the RIGHT reason (not a syntax error)

### Step 6.2: Implement to make tests pass
Write the minimum code that makes each test pass:
1. Implement the change
2. Run the specific test: `$TEST_COMMAND path/to/TestFile`
3. Confirm it passes

### Step 6.3: Refactor
After tests pass:
1. Look for duplication, unclear naming, or structural improvements
2. Refactor while keeping tests green
3. Re-run tests after each refactor step

### Step 6.4: Run the full test suite
Run the broader test suite to catch regressions:
```bash
$TEST_COMMAND [relevant test directory or suite]
```

Fix any failures before continuing.

### Step 6.5: Commit changes
Commit using the project's conventions (`$COMMIT_FORMAT`):

```bash
$SKIP_HOOKS git add [specific files]
git commit -m "$COMMIT_FORMAT"
```

For large changes, make several focused commits rather than one large commit.

---

## Phase 7: Implementation summary

After all changes are committed, generate a summary:

```
## Implementation Summary for $TICKET_ID

### Changes Made
- [File]: [What changed and why]
- [File]: [What changed and why]

### Tests Added/Modified
- [Test file]: [What is tested]

### Commits
- [hash]: [message]

### Verification
- All new tests pass: YES/NO
- Existing tests pass: YES/NO
- Schema changes applied: YES/NO/N/A

### Notes
- [Any caveats, follow-up work, or decisions made during implementation]
```

---

## Phase 8: PR creation

Use the `pr-message-writer` skill if available, or create the PR directly.

### Using the pr-message-writer skill
Invoke the skill with the implementation summary and ticket context to generate a structured PR description.

### Direct PR creation
Use `$VCS_CLI` (e.g., `gh`, `glab`) to create the PR:

```bash
git push -u origin HEAD
$VCS_CLI pr create --title "$TICKET_ID: [short description]" --body "[PR body]"
```

The PR body should include:
- Link to the ticket
- Summary of changes
- Test plan / how to verify
- Screenshots (if UI changes)
- Any deployment notes

---

## Phase 9: Report generation

If the `report-writer` skill is available, invoke it to create a work summary report covering:
- Ticket details and acceptance criteria
- Investigation findings
- Implementation decisions
- Test coverage
- PR link

This is optional but recommended for complex tickets.

---

## Critical rules

1. **Never skip Phase 0.** The supplement adapts the workflow to your stack. Without it, the skill cannot work correctly.

2. **Get plan approval before coding.** Phase 4 must end with explicit developer approval.

3. **TDD is not optional.** Write tests first. If the project has no test infrastructure, flag this to the developer and discuss it before continuing.

4. **Keep commits granular.** One logical change per commit. Do not bundle unrelated changes.

5. **Never force-push to the main branch.** Always work on feature branches.

6. **Ask when uncertain.** If the ticket is ambiguous, ask the developer rather than guessing. A wrong assumption costs more time than a quick question.

7. **Respect existing patterns.** Match the project's coding style, naming conventions, and architectural patterns, even if you would do it differently.

8. **Keep the developer informed.** At the end of each phase, give a brief status update. Do not move silently through several phases.

9. **Stop on failures.** If tests fail unexpectedly, the codebase does not match expectations, or the ticket requirements are unclear, stop and communicate instead of pushing through.

10. **Security first.** Never commit secrets, credentials, or sensitive data. If a ticket requires configuration changes, use environment variables or configuration files that are in `.gitignore`.

## Reference Files

| Reference | Contents |
|---|---|
| [supplement-questions](references/supplement-questions.md) | Full details on each supplement question, options, follow-ups, and example entries |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Design patterns needed during planning | `design-patterns` |
| Code smells discovered during investigation | `refactoring` |
| SOLID violations found during review | `solid` |
| Writing the PR description | `pr-message-writer` |
| Generating a work summary report | `report-writer` |

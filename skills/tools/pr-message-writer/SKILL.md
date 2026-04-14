---
name: pr-message-writer
description: Write comprehensive pull request messages with structured technical documentation, testing instructions, and verification queries. Framework-agnostic with customizable templates. Use when writing or generating a PR description, preparing a pull request for review, or documenting code changes for teammates.
user-invocable: true
argument-hint: "[optional: branch-name or ticket-id]"
---

# PR Message Writer

Write comprehensive, well-structured pull request descriptions by analyzing code changes and following established best practices for technical documentation.

## Workflow

### Step 1: Gather Context

1. Determine the main branch:
   ```bash
   git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
   ```
   Falls back to `main` or `master` if not set.

2. Find the merge base:
   ```bash
   MAIN_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
   MERGE_BASE=$(git merge-base HEAD origin/$MAIN_BRANCH)
   ```

3. Collect all changes since the branch diverged:
   ```bash
   git log --oneline $MERGE_BASE..HEAD
   git diff --stat $MERGE_BASE..HEAD
   git diff $MERGE_BASE..HEAD
   ```

4. If a ticket ID or branch name is provided as an argument, include it in the PR title.

5. **Gather ticket context.** The ticket content is essential for writing accurate testing instructions and understanding the business requirement. If the ticket content is available in context (e.g., from a previous conversation or your project tracker), use it. If it is NOT available or has fallen out of context, **ask the user to provide the ticket content** before proceeding. Do not guess or invent requirements.

### Step 2: Analyze Changes

Read every changed file and understand:
- **What** was changed (new files, modified logic, deleted code)
- **Why** the change was made (bug fix, new feature, refactoring, performance)
- **Impact** on existing functionality (breaking changes, migrations, cache invalidation)
- **Dependencies** introduced or removed

### Step 3: Follow the Template

Use the PR message template for structure: [template](references/template.md)

Review real-world examples for tone and detail level: [examples](references/examples.md)

### Step 4: Match Change Type to Categories

Apply the appropriate sections based on what the PR touches:

| Category | When to Include |
|----------|----------------|
| Database and Entity/Model Changes | New tables, columns, migrations, schema changes |
| API Changes (REST/GraphQL) | New or modified endpoints, query/mutation changes |
| Admin Interface Changes | New admin pages, filters, list views, form fields |
| Caching and Performance | Cache keys, invalidation, query optimization |
| Security and Permissions | Auth rules, role checks, access control changes |
| Event Handling | New events, handlers, message queue changes |
| Testing | New or modified test cases, fixtures, test utilities |

### Step 5: Write Testing Instructions (Optional)

**Before writing testing scenarios, ask the user whether they want testing scenarios included in this PR message.** Testing scenarios are optional. If the user declines, skip this step entirely and omit the "Test scenarios" section from the PR message. Still include the "Testing instructions" section with basic verification steps and database queries if applicable.

If the user wants testing scenarios included:

**Target audience: QA testers with ZERO codebase knowledge.** They do not know about internal code structure, classes, services, or any implementation details. Write every instruction as if explaining to someone who has never seen the code and never will.

Rules for testing instructions:
- **NEVER reference code** -- no file paths, class names, method names, variable names, or internal architecture
- **NEVER use technical implementation terms** -- no internal framework concepts, no code-level abstractions
- **If UI exists**, provide exact click-by-click navigation: which URL to open, which button to click, which field to fill, what value to enter, what to expect on screen
- **If no UI exists** (API-only or GraphQL-only), provide the exact request to execute -- full query/mutation with example variables, which tool to use (GraphQL playground, Postman, curl), and the exact URL/endpoint
- **Database queries are OK** -- QA knows how to run SQL. Include queries when there is no other way to verify something through UI or API
- **Every scenario is checkboxed** -- use `- [ ] **Scenario N: Name**` so QA can tick them off
- **Every scenario ends with "Expected results"** -- a bullet list of what should be visible/changed after the steps
- **Every scenario is step-by-step** -- numbered steps, one action per step
- **Use plain language** -- "Go to the admin panel", "Click the 'Users' menu item", "You should see a green success message"

#### Finding real URLs and UI paths

When a scenario involves navigating to a page, **search the codebase for the actual route/URL** rather than guessing or using placeholder URLs. Look in:
- Route configuration files (e.g., route definitions, annotations, attributes, decorators)
- Controller or handler definitions with route mappings
- Frontend router definitions (e.g., client-side router configs, page-based routing)

Always provide the **real relative URL path** (e.g., `/en/account/internal-store`) rather than generic placeholders like `https://your-staging.example.com/store`. If the route has dynamic segments, show the pattern and explain what to substitute (e.g., `/en/account/store/checkout/{packageId}` -- replace `{packageId}` with the ID from the previous step).

When a feature is reachable through the UI, **lead with the UI navigation** -- describe how to get there by clicking through menus and buttons. Only fall back to direct URL navigation when there is no UI path or the UI path is too many clicks deep.

#### Providing test data

Always provide **concrete, realistic test data** that QA can copy-paste directly. Never say "enter a valid credit card" or "use test credentials" without giving the actual values.

Common test data to include when relevant:
- **Credit cards (Stripe test mode)**: `4242 4242 4242 4242` (Visa, succeeds), `4000 0000 0000 3220` (3D Secure required), `4000 0000 0000 0002` (declined). Expiry: any future date (e.g., `12/34`). CVC: any 3 digits (e.g., `123`)
- **Credit cards (Adyen test mode)**: `4111 1111 1111 1111` (Visa), `5500 0000 0000 0004` (Mastercard). Expiry: `03/30`. CVC: `737`
- **PayPal sandbox**: provide sandbox buyer email/password if available, or note "use PayPal sandbox credentials from the team"
- **Email addresses**: use realistic but clearly fake addresses (e.g., `qa-tester+scenario1@example.com`)
- **Phone numbers**: use test numbers for the relevant country (e.g., `+1 555 0100` for US test)
- **Dates**: use specific dates, not "any date" (e.g., `2025-01-15`)
- **Amounts/quantities**: use specific numbers that test the scenario (e.g., quantity `3`, not "some items")

If the project uses a specific payment provider, search for its test mode configuration in the codebase (look for environment variable keys related to payment, payment config files) to determine which test card numbers apply.

When test data requires database setup (e.g., a specific user account, a product with certain stock), provide the exact SQL INSERT or describe the UI steps to create it.

For every PR, include:
- **Step-by-step verification** -- exact UI navigation or exact API requests to run
- **Copy-pasteable requests** -- full GraphQL queries/mutations or curl commands with example values, specifying where to run them
- **Database verification** -- SQL queries to confirm data integrity (QA can run these)
- **Edge cases** -- described as user actions and expected outcomes, not as code behavior

### Step 6: Maintain Consistency

- Use the same section ordering as the template
- Write in imperative mood for descriptions ("Add product review entity" not "Added" or "Adds")
- Include code blocks with language hints for syntax highlighting
- Keep line length reasonable for readability in PR tools

## Quality Checklist

Before finalizing the PR message, verify:

- [ ] Ticket content was referenced (or user was asked to provide it)
- [ ] Title is concise and includes ticket ID if available
- [ ] "What have I changed" covers every file group logically
- [ ] Testing instructions contain ZERO code references (no file names, class names, method names)
- [ ] Testing instructions are step-by-step with one action per step
- [ ] Every scenario specifies exact UI navigation OR exact API requests to run
- [ ] Every scenario has a checkbox (`- [ ]`) and an "Expected results" bullet list
- [ ] URLs in scenarios are real routes from the codebase (not placeholder URLs)
- [ ] Test data is concrete and copy-pasteable (card numbers, emails, dates -- not "use a valid card")
- [ ] Testing instructions are understandable by someone with zero codebase knowledge
- [ ] Database verification queries are included for any schema changes
- [ ] Product-facing changes are called out explicitly
- [ ] No sensitive data (secrets, tokens, internal URLs) is included
- [ ] Migration steps are documented if applicable
- [ ] Breaking changes are highlighted prominently

## Common Patterns by PR Type

### New Feature
- Describe the business requirement briefly
- List new entities/models, endpoints, and admin pages
- Provide full testing flow from setup to verification
- Include database queries showing new data

### Bug Fix
- State the bug clearly: what happened vs. what should happen
- Explain root cause
- Describe the fix and why this approach was chosen
- Include regression test instructions

### Refactoring
- Explain motivation (tech debt, performance, maintainability)
- Confirm no behavioral changes (or document any intentional ones)
- List before/after comparisons if helpful
- Note any config or dependency changes

### Database Migration
- List all schema changes (new tables, columns, indexes)
- Note if migration is reversible
- Flag any data migrations that touch existing rows
- Include rollback instructions if applicable

## Reference Files

| Reference | Contents |
|---|---|
| [PR message template](references/template.md) | Structured template for PR descriptions with all optional sections |
| [Example PR messages](references/examples.md) | Real-world examples for features, bug fixes, and admin changes |

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Starting work on a ticket end-to-end | `ticket-delivery` |
| Generating a summary report after completing work | `report-writer` |
| Reviewing code before writing the PR | `code-review-excellence` |
| Requesting a code review from teammates | `requesting-code-review` |

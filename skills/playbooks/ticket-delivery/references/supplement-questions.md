# Supplement Configuration Reference

## Overview

The ticket-delivery skill uses a supplement file stored alongside the skill (e.g., `.supplement.md` in the skill directory) to adapt to your specific development environment. This file is created automatically on first run through an interactive questionnaire.

The supplement uses simple `KEY: value` entries that the skill references as `$VARIABLE` placeholders throughout the workflow phases.

## File Location

Store the supplement file alongside this skill, for example as `.supplement.md` in the skill directory. The exact path depends on your platform and how skills are installed.

## Questions

### 1. Ticket System

**Question:** "What ticket/issue tracking system do you use?"
**Options:** GitHub Issues, GitLab Issues, Jira, Linear, Other
**Follow-up:** "Do you have an integration tool for fetching tickets? If so, what is the tool name? (e.g., an MCP tool like `mcp__jira__get_issue`, a CLI command, or an API integration)"
**How it is used:** Determines how tickets are fetched in Phase 1. If an integration tool is available, the skill fetches ticket details automatically. Otherwise, it asks you to paste the ticket title, description, and acceptance criteria.
**Example supplement entry:**
```
TICKET_SYSTEM: jira
TICKET_MCP_TOOL: mcp__jira__get_issue
TICKET_ID_PATTERN: PROJ-XXXXX
```

### 2. Version Control

**Question:** "What version control hosting platform do you use?"
**Options:** Bitbucket, GitHub, GitLab, Other
**Follow-up:** "What CLI tool do you use for PRs? (`gh`, `glab`, or none)" and "What is your main branch name?"
**How it is used:** Determines the CLI command for PR creation in Phase 8 and the base branch for checkout/rebase operations in Phases 2 and 5.
**Example supplement entry:**
```
VCS_PLATFORM: github
VCS_CLI: gh
MAIN_BRANCH: main
```

### 3. Error Tracking

**Question:** "What error tracking system do you use?"
**Options:** Bugsnag, Datadog, Sentry, None
**Follow-up:** "Do you have an integration tool for fetching error details? If so, what is the tool name?"
**How it is used:** For bug tickets, Phase 1 uses this to fetch stack traces, error frequency, and affected file paths. If no tool is configured, the skill asks you to paste relevant error information.
**Example supplement entry:**
```
ERROR_TRACKING: sentry
ERROR_TRACKING_MCP_TOOL: mcp__sentry__get_issue
```

### 4. Logging

**Question:** "What logging/observability platform do you use?"
**Options:** CloudWatch, Datadog, ELK Stack, Grafana, None
**Follow-up:** "Do you have tool access to logs, or will you paste log snippets manually?"
**How it is used:** For bug tickets, Phase 1 can fetch or request log entries around the error timeframe to provide additional context for investigation.
**Example supplement entry:**
```
LOGGING_PLATFORM: grafana
LOGGING_ACCESS: tool
LOGGING_MCP_TOOL: mcp__grafana__query_logs
```

### 5. Database

**Question:** "What ORM or database abstraction do you use?"
**Options:** ActiveRecord, Doctrine, Eloquent, Prisma, TypeORM, None / raw SQL
**Follow-up:** "Can you run read-only queries during development? If so, what command?" (e.g., `rails console`, `php bin/console doctrine:query:sql`, `npx prisma db execute`)
**How it is used:** During Phase 3 investigation, the skill may need to verify current data state or understand schema. The ORM choice also affects how entity/model files are located and interpreted.
**Example supplement entry:**
```
ORM: doctrine
DB_QUERY_COMMAND: php bin/console doctrine:query:sql
```

### 6. CI/CD Hooks

**Question:** "What pre-commit hooks does your project run, and which ones should be skipped during iterative development?"
**Options:** Free-form answer
**Follow-up:** "What is the skip command prefix?" (e.g., `SKIP=lint,test`, `--no-verify`)
**How it is used:** During Phase 6 TDD cycles, rapid commits may need to skip slow hooks (linting, full test suites) that will run in CI anyway. The final commit before PR should run all hooks.
**Example supplement entry:**
```
SKIP_HOOKS: SKIP=lint,schema-validate git
PRE_COMMIT_HOOKS: lint, test, schema-validate, migration-diff
```

### 7. Testing Framework

**Question:** "What testing framework does your project use?"
**Options:** Go test, Jest, PHPUnit, pytest, RSpec, Other
**Follow-up:** "What is the command to run a single test file?" and "Do you prefer London-style (mockist) or Chicago-style (classicist) TDD?"
**How it is used:** Drives the entire Phase 6 TDD cycle. The test command is used to run individual test files during red-green-refactor, and the TDD style preference guides how tests are structured (heavy mocking vs. integration-style).
**Example supplement entry:**
```
TEST_FRAMEWORK: phpunit
TEST_COMMAND: php bin/phpunit
TDD_STYLE: london
```

### 8. Architecture

**Question:** "What is your project's architecture?"
**Options:** Microservices, Modular monolith, Monolith
**Follow-up:** "Do you have an admin panel? If so, what framework?" (e.g., ActiveAdmin, Filament, Nova, Sonata Admin, custom) and "What API layer do you use?" (REST, GraphQL, both, none)
**How it is used:** Shapes Phase 3 investigation scope. For monoliths, all layers are explored in one codebase. For microservices, the skill asks which service the ticket targets. The admin panel and API layer settings determine which investigation sub-phases are relevant.
**Example supplement entry:**
```
ARCHITECTURE: monolith
ADMIN_PANEL: none
API_LAYER: rest
```

### 9. PR Conventions

**Question:** "What branch naming pattern does your team use?"
**Options:** Free-form, with examples shown
**Follow-up:** "What commit message format do you use?"
**How it is used:** Determines branch names in Phase 5 and commit message formatting in Phase 6. The skill fills in the ticket ID and description automatically.
**Example supplement entry:**
```
BRANCH_PATTERN: feat/$TICKET_ID-short-description
COMMIT_FORMAT: $TICKET_ID: description of change
```

## Supplement File Format

The complete supplement file looks like this:

```markdown
# Ticket Workflow Supplement
# Generated by ticket-delivery skill
# Edit manually or delete this file to re-run setup

## Ticket System
TICKET_SYSTEM: jira
TICKET_MCP_TOOL: mcp__jira__get_issue
TICKET_ID_PATTERN: PROJ-XXXXX

## Version Control
VCS_PLATFORM: github
VCS_CLI: gh
MAIN_BRANCH: main

## Error Tracking
ERROR_TRACKING: sentry
ERROR_TRACKING_MCP_TOOL: mcp__sentry__get_issue

## Logging
LOGGING_PLATFORM: none
LOGGING_ACCESS: manual

## Database
ORM: doctrine
DB_QUERY_COMMAND: php bin/console doctrine:query:sql

## CI/CD Hooks
SKIP_HOOKS: SKIP=lint,schema-validate git
PRE_COMMIT_HOOKS: lint, test, schema-validate

## Testing
TEST_FRAMEWORK: phpunit
TEST_COMMAND: php bin/phpunit
TDD_STYLE: london

## Architecture
ARCHITECTURE: monolith
ADMIN_PANEL: none
API_LAYER: rest

## PR Conventions
BRANCH_PATTERN: feat/$TICKET_ID-short-description
COMMIT_FORMAT: $TICKET_ID: description of change
```

## Updating Your Supplement

**To re-run the full setup:** Delete the supplement file and invoke the ticket-delivery skill again.

**To edit a single value:** Open the file directly and modify the relevant line. Changes take effect on the next skill invocation.

**To add custom variables:** You can add any `KEY: value` lines to the file. The skill will ignore keys it does not recognize, but they can be useful for your own reference or for custom workflow extensions.

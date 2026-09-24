# Ticket-Delivery Config Reference

## Contents

- [Overview](#overview)
- [Layers and paths](#layers-and-paths)
- [Reading the config](#reading-the-config)
- [Writing the config](#writing-the-config)
- [Questions](#questions)
- [Defaults](#defaults)
- [Example config](#example-config)
- [Migrating a legacy supplement](#migrating-a-legacy-supplement)
- [Updating your config](#updating-your-config)

## Overview

The ticket-delivery skill adapts to your environment through saved choices in the layered Code Virtuoso config, under the `ticket-delivery` namespace. An interactive setup (main session only) fills in what is missing and writes each answer to the right layer. The workflow phases refer to the keys by name, for example `mainBranch` or `commands.test`.

Choices are never saved next to the skill. That directory is replaced on plugin updates and deleted on reinstall, and it cannot be shared with a team. The full convention is in `spec/config-spec.md` of the Code Virtuoso repository. This file holds everything the skill needs on its own.

## Layers and paths

| Layer | Path | Git | Use for |
|---|---|---|---|
| User | `$CODE_VIRTUOSO_CONFIG_HOME/config.json`, else `${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso/config.json` (Windows: `%APPDATA%\code-virtuoso\config.json`) | Never | Personal choices (`scope: user`) |
| Project shared | `<project root>/.code-virtuoso/config.json` | Committed | Team decisions (`scope: project`) |
| Project local | `<project root>/.code-virtuoso/config.local.json` | Ignored | Personal overrides for one project |

- Project root is `git rev-parse --show-toplevel`, else the current directory.
- Precedence, highest first: explicit argument, project local, project shared, user, defaults. Objects deep-merge. Lists and single values replace.
- When you first create `.code-virtuoso/`, also write `.code-virtuoso/.gitignore` containing `*.local.json` and `loop/state/`.
- Never store secrets. Reject any key whose name matches token, secret, password, or apikey.

## Reading the config

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
home="${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}"
files=()
for f in "$home/config.json" "$root/.code-virtuoso/config.json" "$root/.code-virtuoso/config.local.json"; do
  [ -f "$f" ] && files+=("$f")
done
if [ ${#files[@]} -gt 0 ]; then
  jq -s 'reduce .[] as $x ({}; . * $x)' "${files[@]}" | jq '.["ticket-delivery"] // {}'
else
  echo '{}'
fi
```

Without a shell: open the three files in the order above and skip any that are missing. Start with an empty object and copy each file's `ticket-delivery` values on top of it. Nested objects (such as `commands`) merge key by key. For anything else the later file wins. Keys still unset use the defaults below.

## Writing the config

Change only the `ticket-delivery` keys you own. Read the file, set the keys, and write it back, so other namespaces and unknown keys stay intact.

```bash
f="$root/.code-virtuoso/config.json"   # or "$home/config.json" for scope: user
mkdir -p "$(dirname "$f")"
[ -f "$f" ] || echo '{"version":1}' > "$f"
jq --arg v "main" '.["ticket-delivery"].mainBranch = $v' "$f" > "$f.tmp" && mv "$f.tmp" "$f"
```

After each write, tell the user which file was written and which keys. When setup finishes, offer to add the line `Shared tool decisions: .code-virtuoso/config.json` to the project `AGENTS.md` (or `CLAUDE.md`).

## Questions

Each question has a scope. Ask one at a time, wait for the answer, and write the answers to the layer shown. Skip questions whose keys are already set.

### 1. Ticket system

**Question:** "What ticket/issue tracking system do you use?" (`scope: project`)
**Options:** GitHub Issues, GitLab Issues, Jira, Linear, Other
**Follow-ups:** "What does a ticket ID look like?" (`scope: project`, saved as a regular expression, for example `PROJ-\d+`). "Do you have an integration tool for fetching tickets? If so, what is the tool name?" (`scope: user`, for example an MCP tool like `mcp__jira__get_issue`, a CLI command, or an API integration)
**How it is used:** Sets how tickets are fetched in Phase 1. With an integration tool the skill fetches ticket details. Otherwise it asks you to paste the title, description, and acceptance criteria.
**Keys:** `tracker`, `ticketIdPattern`, `ticketTool`

### 2. Version control

**Question:** "What version control hosting platform do you use?" (`scope: project`)
**Options:** Bitbucket, GitHub, GitLab, Other
**Follow-ups:** "What is your main branch name?" (`scope: project`). "What CLI tool do you use for PRs (`gh`, `glab`, or none)?" (`scope: user`)
**How it is used:** Sets the CLI command for PR creation in Phase 8 and the base branch for checkout and rebase in Phases 2 and 5.
**Keys:** `vcsPlatform`, `mainBranch`, `vcsCli`

### 3. Error tracking

**Question:** "What error tracking system do you use?" (`scope: project`)
**Options:** Bugsnag, Datadog, Sentry, None
**Follow-up:** "Do you have an integration tool for fetching error details? If so, what is the tool name?" (`scope: user`)
**How it is used:** For bug tickets, Phase 1 fetches stack traces, error frequency, and affected file paths. Without a tool the skill asks you to paste the error details.
**Keys:** `errorTracking`, `errorTrackingTool`

### 4. Logging

**Question:** "What logging/observability platform do you use?" (`scope: project`)
**Options:** CloudWatch, Datadog, ELK Stack, Grafana, None
**Follow-up:** "Do you have tool access to logs, or will you paste log snippets manually? If you have a tool, what is its name?" (`scope: user`)
**How it is used:** For bug tickets, Phase 1 fetches or requests log entries around the error timeframe as extra context.
**Keys:** `loggingPlatform`, `loggingAccess` (`tool` or `manual`), `loggingTool`

### 5. Database

**Question:** "What ORM or database abstraction do you use?" (`scope: project`)
**Options:** ActiveRecord, Doctrine, Eloquent, Prisma, TypeORM, None / raw SQL
**Follow-up:** "Can you run read-only queries during development? If so, what command?" (`scope: project`, for example `rails console`, `php bin/console doctrine:query:sql`, `npx prisma db execute`)
**How it is used:** During Phase 3 the skill may verify current data state or read the schema. The ORM also affects how entity and model files are found.
**Keys:** `orm`, `dbQueryCommand`

### 6. CI/CD hooks

**Question:** "What pre-commit hooks does your project run, and which ones should be skipped during iterative development?" (`scope: project` for the hook list, `scope: user` for the skip prefix)
**Options:** Free-form answer
**Follow-up:** "What is the skip prefix or flag?" (for example `SKIP=lint,test` or `--no-verify`)
**How it is used:** During Phase 6, frequent commits may skip slow hooks that run in CI anyway. The final commit before the PR runs all hooks.
**Keys:** `preCommitHooks`, `skipHooks`

### 7. Testing framework

**Question:** "What testing framework does your project use?" (`scope: project`)
**Options:** Go test, Jest, PHPUnit, pytest, RSpec, Other
**Follow-ups:** "What is the command to run tests (and a single test file)?" Also ask for the lint command and the static analysis command, if any. "Do you prefer London-style (mockist) or Chicago-style (classicist) TDD?" (all `scope: project`)
**How it is used:** Drives the Phase 6 TDD cycle. The test command runs files during red-green-refactor, and the TDD style guides how tests are structured.
**Keys:** `testFramework`, `commands.test`, `commands.lint`, `commands.staticAnalysis`, `tddStyle`

### 8. Architecture

**Question:** "What is your project's architecture?" (`scope: project`)
**Options:** Microservices, Modular monolith, Monolith
**Follow-ups:** "Do you have an admin panel? If so, what framework?" (for example ActiveAdmin, Filament, Nova, Sonata Admin, custom). "What API layer do you use?" (REST, GraphQL, both, none) (all `scope: project`)
**How it is used:** Sets the scope of the Phase 3 investigation. For monoliths all layers are explored in one codebase. For microservices the skill asks which service the ticket targets. The admin panel and API layer decide which investigation steps apply.
**Keys:** `architecture`, `adminPanel`, `apiLayer`

### 9. PR conventions

**Question:** "What branch naming pattern does your team use?" (`scope: project`)
**Options:** Free-form, with examples shown
**Follow-up:** "What commit message format do you use?" (`scope: project`)
**How it is used:** Sets branch names in Phase 5 and commit messages in Phase 6. Patterns use the placeholders `{ticket}`, `{slug}` (short description for the branch), and `{summary}` (commit summary).
**Keys:** `branchPattern`, `commitFormat`

## Defaults

| Key | Default |
|---|---|
| `mainBranch` | `main` |
| `loggingAccess` | `manual` |
| `branchPattern` | `feat/{ticket}_{slug}` |
| `commitFormat` | `{ticket}: {summary}` |
| Every other key | Unset: the workflow asks you instead (paste a ticket, paste an error) or skips the step |

## Example config

A project file at `.code-virtuoso/config.json` with the team decisions:

```json
{
  "version": 1,
  "ticket-delivery": {
    "tracker": "jira",
    "ticketIdPattern": "PROJ-\\d+",
    "vcsPlatform": "github",
    "mainBranch": "main",
    "errorTracking": "sentry",
    "loggingPlatform": "none",
    "orm": "doctrine",
    "dbQueryCommand": "php bin/console doctrine:query:sql",
    "preCommitHooks": "lint, test, schema-validate",
    "testFramework": "phpunit",
    "commands": { "test": "php bin/phpunit", "lint": "composer lint", "staticAnalysis": "vendor/bin/phpstan" },
    "tddStyle": "london",
    "architecture": "monolith",
    "adminPanel": "none",
    "apiLayer": "rest",
    "branchPattern": "feat/{ticket}_{slug}",
    "commitFormat": "{ticket}: {summary}"
  }
}
```

A user file with the personal choices:

```json
{
  "version": 1,
  "ticket-delivery": {
    "ticketTool": "mcp__jira__get_issue",
    "vcsCli": "gh",
    "errorTrackingTool": "mcp__sentry__get_issue",
    "loggingAccess": "manual",
    "skipHooks": "SKIP=lint,schema-validate"
  }
}
```

## Migrating a legacy supplement

Earlier versions saved a `.supplement.md` file next to the skill. If the `ticket-delivery` namespace is empty in every layer, look for the file in these places and import it:

- `.supplement.md` next to this skill
- `~/.agents/skills/ticket-delivery/.supplement.md`
- `~/.agents/skills/ticket-workflow/.supplement.md`
- `~/.claude/skills/*/ticket-delivery/.supplement.md`

Parse both `KEY: value` lines and `- **Label**: value` bullets. For a bullet, uppercase the label and replace spaces with underscores to get the key. Map each key as follows.

| Legacy key | Config key | Scope | Notes |
|---|---|---|---|
| `TICKET_SYSTEM` | `tracker` | project | |
| `TICKET_MCP_TOOL` | `ticketTool` | user | |
| `TICKET_ID_PATTERN` | `ticketIdPattern` | project | Convert `PROJ-XXXXX` to the regular expression `PROJ-\d+` |
| `VCS_PLATFORM` | `vcsPlatform` | project | |
| `VCS_CLI` | `vcsCli` | user | |
| `MAIN_BRANCH` | `mainBranch` | project | |
| `ERROR_TRACKING` | `errorTracking` | project | |
| `ERROR_TRACKING_MCP_TOOL` | `errorTrackingTool` | user | |
| `LOGGING_PLATFORM` | `loggingPlatform` | project | |
| `LOGGING_ACCESS` | `loggingAccess` | user | |
| `LOGGING_MCP_TOOL` | `loggingTool` | user | |
| `ORM` | `orm` | project | |
| `DB_QUERY_COMMAND` | `dbQueryCommand` | project | |
| `SKIP_HOOKS` | `skipHooks` | user | Drop a trailing ` git` from old values such as `SKIP=lint git` |
| `PRE_COMMIT_HOOKS` | `preCommitHooks` | project | |
| `TEST_FRAMEWORK` | `testFramework` | project | |
| `TEST_COMMAND` | `commands.test` | project | |
| `TDD_STYLE` | `tddStyle` | project | |
| `ARCHITECTURE` | `architecture` | project | |
| `ADMIN_PANEL` | `adminPanel` | project | |
| `API_LAYER` | `apiLayer` | project | |
| `BRANCH_PATTERN` | `branchPattern` | project | Replace `$TICKET_ID` with `{ticket}` and the trailing description word with `{slug}` |
| `COMMIT_FORMAT` | `commitFormat` | project | Replace `$TICKET_ID` with `{ticket}` and the description text with `{summary}` |

Rules for the import:

- Imported values go to the user layer, which keeps the old global behavior. Show the user the path written.
- If the run is inside a git project with no `.code-virtuoso/config.json`, offer to move the project-scope keys there so the team shares them.
- Ignore keys not in the table. They were user notes.
- Leave the legacy file in place and tell the user it can be deleted. After migration the skill does not read it again.

## Updating your config

**To re-run setup:** Remove the `ticket-delivery` object from the layer you want to reset and invoke the skill again. Or ask for setup directly.

**To edit a value:** Open the layer file and change the key. Changes take effect on the next run.

**To override one project value for yourself:** Put it in `.code-virtuoso/config.local.json`. It wins over the shared file and is never committed.

**To add your own keys:** Add any key under `ticket-delivery`. The skill ignores keys it does not know, and every tool that writes the file keeps them.

# Agents

@CONTRIBUTING.md

Agents are sub-agents - standalone markdown files that define a specialized role, its allowed tools, and its system prompt. Each agent file contains YAML frontmatter for configuration and a markdown body that is the agent's system prompt.

Where **skills** provide reference knowledge (patterns, checklists, component docs), **agents** are the actors that use that knowledge to perform work. A skill is a book on the shelf; an agent is the specialist who reads the book and applies it. Delegate to an agent when a task is well-scoped enough that a focused sub-agent will do it better than the orchestrating model switching context mid-conversation.

## Contents

- [Architecture](#architecture)
- [Specialist agents](#specialist-agents)
- [Role agents](#role-agents)
- [Agent chaining patterns](#agent-chaining-patterns)
- [Running agents headless](#running-agents-headless)
- [Conventions](#conventions)
- [Plugins](#plugins)

## Architecture

Agents follow a two-tier model:

**Specialist agents** handle a single, repeatable task type. They are typically read-only, stateless, and operate on whatever the caller hands them. Think of them as focused tools: investigate this, review that, scan for smells.

**Role agents** embody a team position. They carry a broader mandate and some keep persistent project-level memory across sessions. They own a domain ("the what", "the how", "the when") rather than a single task. A role is an agent plus the files in `roles/<role>/` (templates, checklists, guides) that the agent reads by path when a task needs them. There is no role skill. See [roles/README.md](roles/README.md).

| Aspect | Specialist | Role |
|--------|-----------|------|
| Scope | Single task type | Entire domain of responsibility |
| Knowledge | 0-2 preloaded skills | Reads `roles/<role>/` files on demand, plus 0-2 preloaded skills |
| Memory | Stateless | Some use persistent memory for cross-session context |
| File modification | Read-only, except Implementer (source code) and Doc Writer (documentation) | Dev roles (Backend, Frontend) write code; the others are read-only |
| Isolation | Implementer uses a worktree; others run in place | Backend Dev and Frontend Dev use a worktree; others run in place |

## Specialist agents

| Agent | Tools | Isolation | Preloaded skills | Purpose |
|-------|-------|-----------|------------------|---------|
| [Investigator](agents/investigator.md) | File reading, code search, shell | - | debugging | Deep codebase exploration, dependency mapping |
| [Implementer](agents/implementer.md) | File reading, code search, shell, file editing | worktree | verification-before-completion | TDD red-green-refactor execution |
| [Reviewer](agents/reviewer.md) | File reading, code search, shell | - | security | Structured code review (SOLID, OWASP, smells) |
| [Refactor Scout](agents/refactor-scout.md) | File reading, code search, shell | - | - | Code smell scanning, complexity hotspots |
| [Dependency Auditor](agents/dependency-auditor.md) | Shell, file reading, code search | - | security | CVE checks, outdated packages, license audit |
| [Doc Writer](agents/doc-writer.md) | File reading, code search, shell, file editing | - | - | Changelogs, API docs, migration guides |
| [Migration Planner](agents/migration-planner.md) | File reading, code search, shell | - | - | Migration safety analysis, rollback paths |
| [Test Gap Analyzer](agents/test-gap-analyzer.md) | File reading, code search, shell | - | - | Missing test coverage, untested edge cases |
| [Cold Reviewer](agents/cold-reviewer.md) | File reading, code search, shell | - | security | Zero-context code review, fresh-eyes findings |
| [Acceptance Verifier](agents/acceptance-verifier.md) | File reading, code search, shell | - | verification-before-completion | Spec compliance checking, criteria coverage matrix |
| [Plan Auditor](agents/plan-auditor.md) | File reading, code search, shell | - | verification-before-completion | Pre-implementation readiness gate and mid-work change impact |
| [Instruction Auditor](agents/instruction-auditor.md) | File reading, code search, shell | - | context-engineering | Audit AGENTS.md, CLAUDE.md, rules files, and skill descriptions |
| [Researcher](agents/researcher.md) | File reading, code search, shell, web search and fetch | - | research, docs-lookup | Sourced answers from local files, official docs, and the web |

**Investigator** - Delegate when you need to understand how something works before changing it. It traces code paths, maps dependencies, and returns structured findings with file paths and line numbers.

**Implementer** - Delegate when you have a concrete plan and want strict TDD execution. It works in an isolated worktree, runs red-green-refactor cycles, and commits after each change. Hand it a plan, not a vague request.

**Reviewer** - Delegate after implementation to get a structured code review. It checks correctness, SOLID compliance, OWASP security concerns, performance patterns (N+1 queries), code smells, and test coverage. Returns prioritized findings with severity levels.

**Refactor Scout** - Delegate for codebase health assessments. It scans directories for bloaters, coupling issues, dispensables, and change preventers, then maps each smell to a named refactoring technique with effort estimates.

**Dependency Auditor** - Delegate for dependency health checks. It runs `composer audit`, `npm audit`, or equivalent commands, checks for outdated packages, and flags license incompatibilities.

**Doc Writer** - Delegate after completing features or changes that need documentation. It reads code changes and produces changelogs, API endpoint docs, or migration guides. Apart from the Implementer, it is the only specialist with file editing permissions, and it only touches documentation files.

**Migration Planner** - Delegate before running database migrations. It classifies operations by risk (safe, caution, dangerous), evaluates zero-downtime compatibility, verifies rollback paths, and produces a step-by-step execution plan with pre-checks.

**Test Gap Analyzer** - Delegate after implementation to find what the tests missed. It maps source files to their test files, inventories public interfaces, and identifies missing unit tests, edge cases, integration tests, and error path tests by priority.

**Cold Reviewer** - Delegate when you want a fresh-eyes pass on code changes. It reviews diffs with zero project context - no spec, no documentation, no domain knowledge. Catches issues that familiarity blinds you to. Best used as part of the Review Squad team or alongside the standard Reviewer for a two-perspective review.

**Acceptance Verifier** - Delegate when you need to verify that code changes satisfy their acceptance criteria. It maps every criterion to a PASS/FAIL/PARTIAL/UNTESTED status with file-level evidence. Also flags changes not required by any criterion (scope creep detection).

**Plan Auditor** - Delegate before starting implementation, or when the plan breaks mid-work. It has two modes. Gate mode inventories the planning artifacts (requirements, design, stories, test plans), traces every requirement to a design element and story, checks for contradictions, and returns a READY, NEEDS WORK, or NOT READY verdict. Change-impact mode traces a requirement change, blocker, or scope shift across the plan, classifies the blast radius (minor, moderate, major), and drafts change proposals with old-to-new diffs.

**Instruction Auditor** - Delegate when agent instructions are ignored, a rules file keeps growing, or before you publish instruction files. It reads `AGENTS.md`, `CLAUDE.md`, rules, Cursor and Copilot instructions, `GEMINI.md`, and skill descriptions, then reports size problems, contradictions, stale rules, secrets, and hidden Unicode. It never edits the files.

**Researcher** - Delegate when a question needs evidence rather than recall: "what is the best practice for X", "compare A and B", "is this still recommended", or any fact that may have changed since training. It checks local files first, then official docs and the web, and returns a report with confidence labels, disagreements between sources, and what it could not confirm. It never edits files.

## Role agents

| Agent | Tools | Memory | Preloaded skills | Reads from | Purpose |
|-------|-------|--------|------------------|------------|---------|
| [Product Manager](agents/product-manager.md) | File reading, code search, shell | project | - | [roles/product-manager/](roles/product-manager) | Requirements, PRDs, prioritization |
| [Architect](agents/architect.md) | File reading, code search, shell | project | - | [roles/architect/](roles/architect) | System design, ADRs, trade-offs |
| [Backend Dev](agents/backend-dev.md) | File reading, file editing, shell, code search | - | security, verification-before-completion | [roles/backend-dev/](roles/backend-dev) | API implementation, data models, TDD |
| [Frontend Dev](agents/frontend-dev.md) | File reading, file editing, shell, code search | - | accessibility, verification-before-completion | [roles/frontend-dev/](roles/frontend-dev) | UI components, accessibility, state |
| [QA Engineer](agents/qa-engineer.md) | File reading, code search, shell | project | debugging, security | [roles/qa-engineer/](roles/qa-engineer) | Test plans, bug reports, release sign-off |
| [Project Manager](agents/project-manager.md) | File reading, code search, shell | project | - | [roles/project-manager/](roles/project-manager) | PRINCE2 stages, risk, progress tracking |
| [Scrum Master](agents/scrum-master.md) | File reading, code search, shell | - | - | [roles/scrum-master/](roles/scrum-master) | Sprint planning, goals, retrospectives |

**Product Manager** - Owns the "what" and "why." Delegate when requirements are unclear, user stories need writing, or scope needs prioritizing. Uses MoSCoW/RICE frameworks, writes PRDs with Given/When/Then acceptance criteria, and classifies priorities as P0/P1/P2. Does not write code or make architecture decisions.

**Architect** - Owns the "how." Delegate for system design, component boundaries, API contracts, and technology choices. Writes ADRs (Context, Decision, Alternatives, Consequences) and evaluates trade-offs between quality attributes. Does not implement code.

**Backend Dev** - Owns backend production code. Delegate when you need API endpoints, data models, or services built with strict TDD. Works in a worktree. Follows red-green-refactor and commits after each logical change. Escalates to the Architect when API contracts cannot satisfy requirements.

**Frontend Dev** - Owns the user-facing interface. Delegate for UI component implementation, API integration, accessibility compliance, and responsive layouts. Works in a worktree. Builds leaf components first, composes upward, and tests rendering, interaction, and integration paths.

**QA Engineer** - Owns quality assurance. Delegate after feature completion for test plans, test case design, exploratory testing, and release sign-off. Classifies bugs by severity (P0-P3) and blocks releases when critical bugs are open. Does not fix bugs.

**Project Manager** - Owns the "when" and "how much." Delegate for stage plans, risk registers, highlight reports, and tolerance management. Operates on PRINCE2 principles: manage by stages, manage by exception, continued business justification. Escalates via exception reports when tolerances are forecast to breach.

**Scrum Master** - Facilitates Scrum events. Delegate for sprint planning, sprint goal crafting, retrospective facilitation, and impediment resolution. Coaches rather than directs. Uses the FOCUS criteria for sprint goals and tracks action items from retrospectives.

## Agent chaining patterns

Common multi-agent workflows where the output of one agent feeds the next:

### Investigation flow

```
Investigator -> Architect -> Implementer -> Reviewer
```

Start with the Investigator to map the relevant code area. Hand findings to the Architect for design decisions. Pass the design to the Implementer for TDD execution. Finish with the Reviewer for quality checks.

### Feature flow

```
Product Manager -> Architect -> Backend Dev / Frontend Dev -> QA Engineer
```

The Product Manager defines requirements and acceptance criteria. The Architect translates them into component designs and API contracts. Dev agents implement in worktrees. The QA Engineer writes test plans against the original acceptance criteria and signs off.

### Review flow

```
Refactor Scout -> Reviewer -> Implementer
```

The Refactor Scout scans for code smells and structural issues. The Reviewer validates the scout's findings against the actual code context. The Implementer applies the recommended refactorings with TDD.

### Pre-migration flow

```
Migration Planner -> Reviewer -> Implementer
```

The Migration Planner analyzes migration files and produces a risk-assessed execution plan. The Reviewer checks that application code is compatible with both old and new schemas. The Implementer applies any required code changes.

### Coverage improvement flow

```
Test Gap Analyzer -> Implementer -> Reviewer
```

The Test Gap Analyzer identifies missing test cases by priority. The Implementer writes the missing tests using TDD cycles. The Reviewer checks that the new tests assert real behavior and are structured correctly.

### Teams

Three recurring multi-agent patterns are packaged as teams. Each team is a Claude Code workflow script in [workflows/](workflows) plus a Markdown recipe in [teams.md](skills/knowledge/agent-orchestration/references/teams.md) that any harness can follow. See [spec/team-spec.md](spec/team-spec.md) for the format.

| Team | Claude Code command | Pattern |
|------|---------------------|---------|
| Review Squad | `/agents-virtuoso:review-squad` | Cold Reviewer, Acceptance Verifier, and optionally Refactor Scout run in parallel, then the Reviewer adds a full-context pass, deduplicates, and triages |
| Development Team | `/agents-virtuoso:development-team` | Product Manager, Architect, Plan Auditor gate, Backend Dev and Frontend Dev in separate worktrees, integration, QA sign-off. Stops at the first failed gate and reports what blocked it |
| War Room | `/agents-virtuoso:war-room` | Architect frames the question, four roles each argue for one option and attack one other position, the Architect synthesizes. The user makes the final call. It produces a decision, not code |

## Running agents headless

Seven read-only agents can run without a person at the keyboard, in CI or from a script. Seven wrapper skills in `skills/tools/` run an agent as a forked subagent and make it answer in JSON. They ship in the `agents-virtuoso` plugin, so a CI job installs one plugin to get both the agents and the wrappers. Ready-to-copy GitHub Actions workflows are in [examples/ci/](examples/ci/README.md).

| Skill | Agent | Argument | JSON schema |
|---|---|---|---|
| `review-pr` | `reviewer` | base ref or PR number | `skills/tools/review-pr/references/output.schema.json` |
| `review-pr-cold` | `cold-reviewer` | base ref or PR number | `skills/tools/review-pr-cold/references/output.schema.json` |
| `verify-acceptance` | `acceptance-verifier` | spec file or PR number, then base ref | `skills/tools/verify-acceptance/references/output.schema.json` |
| `find-test-gaps` | `test-gap-analyzer` | base ref or directory | `skills/tools/find-test-gaps/references/output.schema.json` |
| `plan-migration` | `migration-planner` | base ref or migration path | `skills/tools/plan-migration/references/output.schema.json` |
| `audit-dependencies` | `dependency-auditor` | project directory | `skills/tools/audit-dependencies/references/output.schema.json` |
| `scan-refactors` | `refactor-scout` | directory or base ref | `skills/tools/scan-refactors/references/output.schema.json` |

### Claude Code

Install the plugin once with `claude plugin marketplace add krzysztofsurdy/code-virtuoso` and `claude plugin install agents-virtuoso@code-virtuoso`. Installed agents and skills carry the plugin name as a prefix: `agents-virtuoso:reviewer`, `/agents-virtuoso:review-pr`.

Run a wrapper skill. The session result is the agent's final message, which is the JSON report:

```bash
claude -p "/agents-virtuoso:review-pr origin/main" \
  --allowedTools "Read,Grep,Glob,Bash(git diff:*),Bash(git log:*)" \
  --max-turns 30 --output-format json | jq -r .result
```

Run a session as an agent, with your own prompt:

```bash
claude -p --agent agents-virtuoso:reviewer \
  --allowedTools "Read,Grep,Glob,Bash(git diff:*)" \
  "Review git diff origin/main...HEAD"
```

Notes:

- Use the prefixed name. In a skill's `agent:` field a name without the prefix, or a misspelled one, does not fail: Claude Code falls back to `general-purpose` and the run loses the agent's instructions and tool limits. `--agent` does fail on an unknown name and lists the available ones.
- The wrapper skills start the agent as a forked subagent, and its preloaded skills load. In a `claude -p --agent` session they did not in a test, so prefer the wrapper skills when the agent depends on its preloads.
- A headless run cannot answer a permission prompt. Allow the commands the skill needs with `--allowedTools`, or the command is denied. A skill given a PR number also needs `Bash(gh pr diff:*)` and `Bash(gh pr view:*)`.
- In GitHub Actions, use [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) as in [claude-review.yml](examples/ci/claude-review.yml): `plugin_marketplaces`, `plugins`, `prompt: /agents-virtuoso:review-pr origin/main`, and `claude_args` for the flags above.

### Codex

Codex does not load Claude Code plugins or `agents/*.md`. Build the prompt from the agent file and pass the schema, then read the answer from the last message:

```bash
awk '/^---$/ && n < 2 { n++; next } n >= 2' agents/reviewer.md > prompt.md
echo 'Review `git diff origin/main...HEAD`. Answer with the JSON report only.' >> prompt.md
jq 'del(."$schema")' skills/tools/review-pr/references/output.schema.json > schema.json
codex exec --sandbox read-only --output-schema schema.json -o report.json - < prompt.md
```

`codex exec` runs in a read-only sandbox by default, so the agent cannot change files. Drop `$schema` from the schema to stay inside the subset of JSON Schema that strict structured output accepts. In GitHub Actions, use [openai/codex-action](https://github.com/openai/codex-action) as in [codex-review.yml](examples/ci/codex-review.yml).

## Conventions

### Tool permission philosophy

Agents follow least privilege. Read-only agents get only file reading, code search, and shell tools. File editing permissions are granted only to agents that must modify files: the Implementer, Doc Writer, Backend Dev, and Frontend Dev. Shell access is universally available for running tests, audit commands, and git operations. A read-only agent that is asked for a JSON report in CI returns it as its final message and writes no files.

### Worktree isolation

Agents that change source code operate in isolated git worktrees. This prevents half-finished changes from polluting the main working tree and lets the orchestrator review changes before merging. Three agents use worktree isolation: Implementer, Backend Dev, and Frontend Dev. The Doc Writer edits documentation only and runs in place.

### Memory usage

Role agents that need cross-session context (Product Manager, Architect, QA Engineer, Project Manager) use persistent project-level memory. This allows them to accumulate project knowledge - requirements decisions, architectural context, risk registers - across multiple conversations. Specialist agents are stateless by design.

### Handoff contracts

Agents declare what they expect as input (`expects`) and what they produce (`produces`) using artifact type names from [spec/artifacts.md](spec/artifacts.md). These declarations let orchestrators and teams verify that the output of one agent matches the input of the next. Contracts are documentation - not runtime enforcement. Agents handle missing artifacts gracefully.

### Skill preloading

Agents preload at most a few skills, by the `name` field in the skill's SKILL.md and not by path. Names resolve across every installed plugin, so `agents-virtuoso` agents pick up `security`, `debugging`, `accessibility`, and `context-engineering` from `knowledge-virtuoso` when it is installed. When that plugin is missing the agent still runs, without the preload and without a warning. Install `knowledge-virtuoso` next to `agents-virtuoso`. Details are in [spec/agent-spec.md](spec/agent-spec.md#skill-preloading).

### Role references

Role agents do not preload a role skill. Each reads the files in `roles/<role>/` by path when a task needs a template or checklist, so the files cost no context until they are opened. Codex installs copy `roles/` next to the agents. See [codex/README.md](codex/README.md).

### Punctuation Style

Do not use em dashes (`—`), en dashes (`–`), or the double-dash (`--`) as a pause in agent definitions, skills, specs, or any project documentation. Use a comma, colon, period, parentheses, or a single hyphen (`-`) with surrounding spaces instead. Number ranges use a plain hyphen (`1-5`). This rule applies to prose only: CLI flags (`--help`), argument separators (`git checkout -- .`, `cargo test -- --nocapture`), and SQL comments (`-- note`) keep their double dash.

## Plugins

Skills and agents in this repo are agent-agnostic markdown. The `plugins/` directory is the one deliberate exception: each entry is a self-contained Claude Code plugin with its own `.claude-plugin/plugin.json`, and it may ship hooks, scripts, commands, and skills that run inside Claude Code. `plugins/loop-virtuoso` is the first one. It is Claude Code only. Install it with `/plugin install loop-virtuoso@code-virtuoso`.

Plugins under `plugins/` are listed in `.claude-plugin/marketplace.json` with `name`, `source`, and `description` only. The plugin's own `plugin.json` is the source of truth for its version and components.

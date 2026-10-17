<p align="center">
  <img src="logo.png" alt="Code Virtuoso" width="220" />
</p>

<h1 align="center">Code Virtuoso</h1>

<p align="center">
  Skills, sub-agents, and playbooks for Claude Code, Cursor, and any Agent Skills-compatible AI coding assistant.
</p>

<p align="center">
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/releases"><img src="https://img.shields.io/github/v/tag/krzysztofsurdy/code-virtuoso?label=version&color=1f6feb" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/krzysztofsurdy/code-virtuoso?color=2ea44f" alt="License"></a>
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/stargazers"><img src="https://img.shields.io/github/stars/krzysztofsurdy/code-virtuoso?style=social" alt="Stars"></a>
  <a href="https://agentskills.io"><img src="https://img.shields.io/badge/standard-Agent%20Skills-black" alt="Agent Skills standard"></a>
</p>

<p align="center">
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-marketplace.yml"><img src="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-marketplace.yml/badge.svg" alt="Validate Marketplace"></a>
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-skills.yml"><img src="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-skills.yml/badge.svg" alt="Validate Skills"></a>
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-agents.yml"><img src="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-agents.yml/badge.svg" alt="Validate Agents"></a>
  <a href="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-markdown.yml"><img src="https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate-markdown.yml/badge.svg" alt="Validate Markdown"></a>
</p>

> **What you get:** 56 skills, 19 sub-agents, 3 team workflows, and a delivery-loop plugin - all installable individually or as bundles, based on the open [Agent Skills](https://agentskills.io) standard.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

<details>
<summary><strong>Table of Contents</strong></summary>

- [Quickstart](#quickstart)
- [Why use this](#why-use-this)
- [What's inside](#whats-inside)
- [Knowledge skills](#knowledge-skills)
- [Tool skills](#tool-skills)
- [Playbook skills](#playbook-skills)
- [Framework skills](#framework-skills)
- [AI engineering skills](#ai-engineering-skills)
- [Agents](#agents)
- [Teams](#teams)
- [Running agents in CI](#running-agents-in-ci)
- [Plugins](#plugins)
- [Installation](#installation)
- [Works well with](#works-well-with)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)
- [Repository structure](#repository-structure)

</details>

---

## Quickstart

```bash
# 1. Install (interactive - pick what you want)
npx skills add krzysztofsurdy/code-virtuoso

# 2. Try a skill immediately
/ticket-writer
# Follow the prompts - paste the output into Jira, Linear, or GitHub Issues.
```

That is the whole tour. For Claude Code plugins, Codex, per-skill installs, and auto-update see [Installation](#installation).

---

## Why use this

- **Researched, then hand-curated.** Every skill was checked against official docs and community best practices. No invented API references.
- **Skills that change behavior.** A skill earns its place by fixing something the model gets wrong without it: a procedure, a decision rule, a pitfall list. Textbook material the model already knows is kept short or runs only when you ask for it.
- **Progressive disclosure saves context.** Skills load a short `SKILL.md` first and pull in deeper references only when the task calls for them.
- **One installation, many tools.** Built on the open Agent Skills standard. Works with Claude Code, Cursor, Windsurf, Copilot, Codex, Gemini CLI, and more.
- **Shaped like a team.** 19 sub-agents delegate like a real team instead of one over-prompted assistant. Seven of them are role agents (Product Manager, Architect, Backend Dev, Frontend Dev, QA, Project Manager, Scrum Master) that read their templates and checklists from [roles/](roles/README.md).

---

## What's inside

| Category | Count | Summary |
|---|---|---|
| [Knowledge](#knowledge-skills) | 19 | Security, debugging, accessibility, agent workflow, and design references. 11 run only when you call them by name |
| [Tools](#tool-skills) | 18 | Interactive generators (rules files, tickets, agents, plugins, PR messages, reports, screenshots) and 7 headless agent wrappers |
| [Playbooks](#playbook-skills) | 8 | Step-by-step procedures for delivery, TDD, PR feedback, handoff, guardrails |
| [Frameworks](#framework-skills) | 7 | Symfony, Django, LangChain, PHP, and Vercel AI SDK guides |
| [AI engineering](#ai-engineering-skills) | 4 | Agent design, LLM evals, LLM observability, MCP servers |
| [Agents](#agents) | 19 | 12 specialist and 7 role sub-agents |
| [Teams](#teams) | 3 | Review squad, development team, war room as workflows plus Markdown recipes |
| [Plugins](#plugins) | 1 | Self-contained Claude Code plugin with hooks and scripts |

Skills marked **run by name** have `disable-model-invocation: true`. They never load on their own, so they cost no context until you type `/skill-name` (or the equivalent in your tool). The rest load automatically when their description matches the task.

---

## Knowledge skills

Each skill has a short `SKILL.md` and deep-dive files under `references/`. Bundle: `knowledge-virtuoso`, except the two agent workflow skills, which ship in `agents-virtuoso`.

### Loads automatically

| Skill | Summary |
|-------|---------|
| [Security](skills/knowledge/security/SKILL.md) | OWASP Top 10:2025, auth patterns, secrets, secure coding |
| [Agent Security](skills/knowledge/agent-security/SKILL.md) | Prompt injection, session design, sandboxing, and secrets for coding agents and LLM features |
| [Debugging](skills/knowledge/debugging/SKILL.md) | Root-cause debugging method and post-mortem templates |
| [Accessibility](skills/knowledge/accessibility/SKILL.md) | WCAG 2.1/2.2, ARIA patterns, keyboard navigation, a11y testing |
| [Context Engineering](skills/knowledge/context-engineering/SKILL.md) | Budget and structure what a coding agent sees: AGENTS.md, rules, skill descriptions |
| [Docs Lookup](skills/knowledge/docs-lookup/SKILL.md) | Fetch version-correct official docs instead of answering API questions from memory |

### Run by name

Reference material for design and craft. Call one when you want it, for example `/solid` or `/testing`.

| Skill | Summary |
|-------|---------|
| [Design Patterns](skills/knowledge/design-patterns/SKILL.md) | 26 patterns with trade-offs and anti-patterns |
| [SOLID](skills/knowledge/solid/SKILL.md) | The five principles with violation detection and fixes |
| [Clean Architecture](skills/knowledge/clean-architecture/SKILL.md) | Clean and Hexagonal Architecture with DDD tactical patterns |
| [Refactoring](skills/knowledge/refactoring/SKILL.md) | 89 refactoring techniques and 22 code smells |
| [Testing](skills/knowledge/testing/SKILL.md) | Test strategy, pyramid, test doubles, flaky tests, antipatterns |
| [API Design](skills/knowledge/api-design/SKILL.md) | REST and GraphQL design, error contracts, versioning |
| [Database Design](skills/knowledge/database-design/SKILL.md) | Schema modeling, indexing, constraints, migrations |
| [Performance](skills/knowledge/performance/SKILL.md) | Profiling-driven optimization, caching, N+1 fixes |
| [Microservices](skills/knowledge/microservices/SKILL.md) | Service boundaries, sagas, CQRS, resilience |
| [CI/CD](skills/knowledge/cicd/SKILL.md) | Pipeline design, deployment strategies, rollback |
| [Scrum](skills/knowledge/scrum/SKILL.md) | Roles, events, sprint goals, retrospectives |

### Agent workflow

| Skill | Summary |
|-------|---------|
| [Agent Orchestration](skills/knowledge/agent-orchestration/SKILL.md) | Decide how to split work across agents: delegation, fan-out, worktrees, review gates, team recipes |
| [Verification Before Completion](skills/knowledge/verification-before-completion/SKILL.md) | Evidence-based completion discipline and tiered definition of done |

---

## Tool skills

Interactive generators, invoked as `/skill-name`. Bundle: `tools-virtuoso`.

| Skill | Summary |
|-------|---------|
| [Agentic Rules Writer](skills/tools/agentic-rules-writer/SKILL.md) | Generate rules files for Claude Code, Cursor, Windsurf, Copilot, Gemini, Codex, and more |
| [Ticket Writer](skills/tools/ticket-writer/SKILL.md) | Write tickets of the right type - story, subtask, issue, bug, epic, or initiative |
| [Agent Creator](skills/tools/agent-creator/SKILL.md) | Design a sub-agent with proper frontmatter, tool permissions, isolation, and system prompt |
| [Plugin Creator](skills/tools/plugin-creator/SKILL.md) | Scaffold a complete Claude Code plugin - manifest, skills, agents, hooks, MCP/LSP servers |
| [Brainstorming](skills/tools/brainstorming/SKILL.md) | Pre-implementation design exploration - turn a vague idea into an approved spec |
| [Using Ecosystem](skills/tools/using-ecosystem/SKILL.md) | Discovery advisor: which skill, agent, or team fits the task |
| [PR Message Writer](skills/tools/pr-message-writer/SKILL.md) | Write structured pull request messages with testing instructions |
| [Report Writer](skills/tools/report-writer/SKILL.md) | Generate standalone HTML reports on changes, investigations, or decisions |
| [Stakeholder Update Writer](skills/tools/stakeholder-update-writer/SKILL.md) | Draft stakeholder Slack or email updates on status, blockers, and decisions |
| [Web Screenshot](skills/tools/web-screenshot/SKILL.md) | Capture web page screenshots with shot-scraper |
| [Image Annotate](skills/tools/image-annotate/SKILL.md) | Mark up images with arrows, boxes, text, numbered steps, blur, and redaction |

### Headless agent wrappers

Each wrapper runs one read-only agent as a forked subagent and answers in JSON. They are **run by name**, built for CI and scripts, and ship in `agents-virtuoso` so the agent and its wrapper install together. See [Running agents in CI](#running-agents-in-ci).

| Skill | Runs | Summary |
|-------|------|---------|
| [Review PR](skills/tools/review-pr/SKILL.md) | `reviewer` | Review a PR or branch diff |
| [Review PR Cold](skills/tools/review-pr-cold/SKILL.md) | `cold-reviewer` | Independent zero-context second opinion |
| [Verify Acceptance](skills/tools/verify-acceptance/SKILL.md) | `acceptance-verifier` | Map a diff against acceptance criteria |
| [Find Test Gaps](skills/tools/find-test-gaps/SKILL.md) | `test-gap-analyzer` | Missing test cases in changed files |
| [Plan Migration](skills/tools/plan-migration/SKILL.md) | `migration-planner` | Risk-rated plan for pending migrations |
| [Audit Dependencies](skills/tools/audit-dependencies/SKILL.md) | `dependency-auditor` | Vulnerabilities, outdated packages, licenses |
| [Scan Refactors](skills/tools/scan-refactors/SKILL.md) | `refactor-scout` | Code smells and refactoring techniques |

---

## Playbook skills

Step-by-step procedures for recurring work. Bundle: `playbooks-virtuoso`.

| Skill | Summary |
|-------|---------|
| [Ticket Delivery](skills/playbooks/ticket-delivery/SKILL.md) | Ticket to PR: analysis, investigation, planning, TDD, commit, and pull request |
| [Spec-Driven Development](skills/playbooks/spec-driven-development/SKILL.md) | Turn an approved idea into spec, plan, and tasks in the repo, then execute one task at a time |
| [TDD](skills/playbooks/tdd/SKILL.md) | Strict red-green-refactor for agents, including the excuses agents use to skip it |
| [Finishing Branch](skills/playbooks/finishing-branch/SKILL.md) | Pre-push checks, merge strategy, PR message, cleanup, recovery |
| [PR Feedback](skills/playbooks/pr-feedback/SKILL.md) | Triage review comments and failing CI, fix with tests, reply |
| [Handoff](skills/playbooks/handoff/SKILL.md) | Write and resume from a short handoff note when a session ends mid-task |
| [Hooks and Guardrails](skills/playbooks/hooks-and-guardrails/SKILL.md) | Deny rules, sandbox and permission choices, and hooks for an agent setup |
| [Worktree Ops](skills/playbooks/worktree-ops/SKILL.md) | Create, list, switch, and remove git worktrees with safety checks |

---

## Framework skills

Version facts, opinions, and pitfalls rather than copies of the official docs. Bundle: `frameworks-virtuoso`.

| Skill | Summary |
|-------|---------|
| [Symfony Components](skills/frameworks/symfony/symfony-components/SKILL.md) | Version matrix, opinionated defaults, and pitfalls for Symfony and its components |
| [Symfony Upgrade](skills/frameworks/symfony/symfony-upgrade/SKILL.md) | Deprecation-first upgrade guide for minor and major versions |
| [Django Components](skills/frameworks/django/django-components/SKILL.md) | Version matrix and the pitfalls that cause real Django bugs |
| [LangChain Components](skills/frameworks/langchain/langchain-components/SKILL.md) | Choose between create_agent, LangGraph, and Deep Agents; multi-agent patterns |
| [Vercel AI SDK](skills/frameworks/vercel/vercel-ai-sdk/SKILL.md) | Version matrix, core versus UI packages, the agent loop, and TypeScript pitfalls |
| [PHP Upgrade](skills/frameworks/php/php-upgrade/SKILL.md) | PHP 7.4 to 8.5 upgrade process with Rector and breaking changes per version |
| [Composer Dependencies](skills/frameworks/php/composer-dependencies/SKILL.md) | Safe dependency updates, security auditing, automated update tools |

---

## AI engineering skills

For teams building with LLMs and agents. Bundle: `ai-virtuoso`.

| Skill | Summary |
|-------|---------|
| [Agent Design](skills/ai/agent-design/SKILL.md) | Workflow versus agent, workflow patterns, harness anatomy, tool permissions |
| [LLM Evals](skills/ai/llm-evals/SKILL.md) | Error analysis of real traces, binary graders, judge validation, agent evals |
| [LLM Observability](skills/ai/llm-observability/SKILL.md) | OpenTelemetry GenAI traces, token and cost attribution, PII-safe capture |
| [MCP Server Development](skills/ai/mcp-server-development/SKILL.md) | Tool design, response formats, errors, and shipping MCP servers |

---

## Agents

Sub-agents follow the [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) standard. **Specialist** agents handle one focused task type. **Role** agents embody a team position, read their templates and checklists from [roles/](roles/README.md), and some carry persistent project memory. See [AGENTS.md](AGENTS.md) for full specifications, delegation patterns, and headless use. Bundle: `agents-virtuoso`.

| Kind | Agent | Tools | Isolation | Memory | Purpose |
|------|-------|-------|-----------|--------|---------|
| Specialist | [Investigator](agents/investigator.md) | Read, Grep, Glob, Bash | - | - | Deep codebase exploration, dependency mapping |
| Specialist | [Implementer](agents/implementer.md) | Read, Grep, Glob, Bash, Edit, Write | worktree | - | TDD red-green-refactor execution |
| Specialist | [Reviewer](agents/reviewer.md) | Read, Grep, Glob, Bash | - | - | Structured code review (SOLID, OWASP, smells) |
| Specialist | [Refactor Scout](agents/refactor-scout.md) | Read, Grep, Glob, Bash | - | - | Code smell scanning, complexity hotspots |
| Specialist | [Dependency Auditor](agents/dependency-auditor.md) | Bash, Read, Grep, Glob | - | - | CVE checks, outdated packages, license audit |
| Specialist | [Doc Writer](agents/doc-writer.md) | Read, Grep, Glob, Bash, Write, Edit | - | - | Changelogs, API docs, migration guides |
| Specialist | [Migration Planner](agents/migration-planner.md) | Read, Grep, Glob, Bash | - | - | Migration safety analysis, rollback paths |
| Specialist | [Test Gap Analyzer](agents/test-gap-analyzer.md) | Read, Grep, Glob, Bash | - | - | Missing test coverage, untested edge cases |
| Specialist | [Cold Reviewer](agents/cold-reviewer.md) | Read, Grep, Glob, Bash | - | - | Zero-context code review, fresh-eyes findings |
| Specialist | [Acceptance Verifier](agents/acceptance-verifier.md) | Read, Grep, Glob, Bash | - | - | Spec compliance checking, criteria coverage matrix |
| Specialist | [Plan Auditor](agents/plan-auditor.md) | Read, Grep, Glob, Bash | - | - | Pre-implementation readiness gate and mid-work change impact |
| Specialist | [Instruction Auditor](agents/instruction-auditor.md) | Read, Grep, Glob, Bash | - | - | Audit AGENTS.md, CLAUDE.md, rules files, and skill descriptions |
| Role | [Product Manager](agents/product-manager.md) | Read, Grep, Glob, Bash | - | project | Requirements, PRDs, prioritization |
| Role | [Architect](agents/architect.md) | Read, Grep, Glob, Bash | - | project | System design, ADRs, trade-offs |
| Role | [Backend Dev](agents/backend-dev.md) | Read, Edit, Write, Bash, Grep, Glob | worktree | - | API implementation, data models, TDD |
| Role | [Frontend Dev](agents/frontend-dev.md) | Read, Edit, Write, Bash, Grep, Glob | worktree | - | UI components, accessibility, state |
| Role | [QA Engineer](agents/qa-engineer.md) | Read, Grep, Glob, Bash | - | project | Test plans, bug reports, release sign-off |
| Role | [Project Manager](agents/project-manager.md) | Read, Grep, Glob, Bash | - | project | PRINCE2 stages, risk, progress tracking |
| Role | [Scrum Master](agents/scrum-master.md) | Read, Grep, Glob, Bash | - | - | Sprint planning, goals, retrospectives |

Role agents read reference files on demand from [roles/](roles/README.md): templates (ADR, PRD, test plan, risk register), checklists, and guides. These are plain files, not skills, so nothing loads them until the agent opens one.

On Codex, the same agents install from generated TOML files. See [codex/README.md](codex/README.md).

---

## Teams

A team is a fixed recipe: a roster, phases, and gates. Each ships twice: as a Claude Code workflow (`/agents-virtuoso:<name>`) that runs the recipe deterministically, and as a Markdown recipe in [teams.md](skills/knowledge/agent-orchestration/references/teams.md) that any harness can follow. See [spec/team-spec.md](spec/team-spec.md) for the format.

| Team | Workflow | Roster | Use case |
|------|----------|--------|----------|
| Development Team | [development-team.js](workflows/development-team.js) | Product Manager, Architect, Plan Auditor, Backend Dev, Frontend Dev, QA | Feature delivery from ticket to merge-ready branch, with a gate between phases |
| Review Squad | [review-squad.js](workflows/review-squad.js) | Cold Reviewer, Acceptance Verifier, Refactor Scout (optional), Reviewer | Multi-perspective code review with one triaged report |
| War Room | [war-room.js](workflows/war-room.js) | Architect, Product Manager, Backend Dev, QA | Structured debate for a technical decision. Returns a synthesis, you decide |

---

## Running agents in CI

The seven headless wrappers run read-only agents in GitHub Actions or any script and return JSON. [examples/ci/](examples/ci/README.md) holds ready-to-copy workflows for Claude Code and Codex: PR review, and a weekly dependency and refactor audit. They are examples, not active workflows. [AGENTS.md](AGENTS.md#running-agents-headless) has the commands.

---

## Plugins

Everything above is agent-agnostic markdown. The `plugins/` directory is the one deliberate exception: each entry is a self-contained Claude Code plugin with its own `.claude-plugin/plugin.json`, and it may ship hooks, scripts, commands, and skills. These plugins run code, so they work in Claude Code only.

| Plugin | Summary |
|--------|---------|
| [loop-virtuoso](plugins/loop-virtuoso/README.md) | Backlog-driven delivery loop. Feeds the agent one small item at a time and accepts it only when verify commands pass and a write-boundary guard approves |

---

## Installation

### Claude Code marketplace

Add the marketplace once, then install any bundle:

```
/plugin marketplace add krzysztofsurdy/code-virtuoso
/plugin install knowledge-virtuoso@code-virtuoso
/plugin install tools-virtuoso@code-virtuoso
/plugin install playbooks-virtuoso@code-virtuoso
/plugin install frameworks-virtuoso@code-virtuoso
/plugin install ai-virtuoso@code-virtuoso
/plugin install agents-virtuoso@code-virtuoso
/plugin install loop-virtuoso@code-virtuoso
```

| Bundle | Holds |
|--------|-------|
| `knowledge-virtuoso` | 17 knowledge skills |
| `tools-virtuoso` | 11 interactive tool skills |
| `playbooks-virtuoso` | 8 playbooks |
| `frameworks-virtuoso` | 7 framework skills |
| `ai-virtuoso` | 4 AI engineering skills |
| `agents-virtuoso` | 19 agents, 3 team workflows, agent-orchestration, verification-before-completion, 7 headless wrappers |
| `loop-virtuoso` | Delivery loop (Claude Code only) |

Install `knowledge-virtuoso` next to `agents-virtuoso`. Several agents preload knowledge skills such as `security`, `debugging`, and `accessibility`. When `knowledge-virtuoso` is missing, the agent still runs but without that preloaded guidance.

### Other agents with the skills CLI

```bash
# Interactive pick
npx skills add krzysztofsurdy/code-virtuoso

# Pick individual skills
npx skills add krzysztofsurdy/code-virtuoso --skill security --skill debugging

# Everything at once
npx skills add krzysztofsurdy/code-virtuoso --all

# Install globally (available in every project)
npx skills add krzysztofsurdy/code-virtuoso -g

# Preview what's available without installing
npx skills add krzysztofsurdy/code-virtuoso --list
```

### Codex

Codex reads the same marketplace for skills. Codex plugins cannot ship agents, so the agents install from a script:

```bash
codex plugin marketplace add krzysztofsurdy/code-virtuoso
git clone https://github.com/krzysztofsurdy/code-virtuoso && cd code-virtuoso
scripts/install-codex-agents.sh             # or --project for ./.codex/agents/
```

Details and limits are in [codex/README.md](codex/README.md).

### Updating

```bash
npx skills check    # see what can be updated
npx skills update   # update everything installed
```

In Claude Code, run `/plugin marketplace update code-virtuoso`. For Codex, run `codex plugin marketplace upgrade` and rerun the agent installer.

### Auto-update, once a day, in the background

<details>
<summary>macOS / Linux (zsh)</summary>

```bash
echo '_skills_marker="${TMPDIR:-/tmp}/.skills-updated-$(date +%Y%m%d)"
[ ! -f "$_skills_marker" ] && (npx skills update --yes >/dev/null 2>&1 && touch "$_skills_marker" &)' >> ~/.zshrc
```

</details>

<details>
<summary>Windows (PowerShell)</summary>

```powershell
Add-Content $PROFILE '$marker = "$env:TEMP\.skills-updated-$(Get-Date -Format yyyyMMdd)"; if (-not (Test-Path $marker)) { Start-Job { npx skills update --yes *> $null; New-Item $using:marker -Force } | Out-Null }'
```

</details>

<details>
<summary>Project-level (git post-merge hook)</summary>

```bash
printf '#!/bin/sh\nnpx skills update --yes >/dev/null 2>&1 &\n' > .git/hooks/post-merge
chmod +x .git/hooks/post-merge
```

</details>

---

## Works well with

Companion tools that fit alongside this library.

### Beads - task memory for AI agents

[github.com/steveyegge/beads](https://github.com/steveyegge/beads)

Distributed, git-backed graph issue tracker that gives AI agents persistent, structured memory for long-horizon tasks. Replaces ad-hoc markdown planning files with a dependency-aware task graph.

### GSD - spec-driven development

[github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)

Meta-prompting and context engineering system for Claude Code, OpenCode, Gemini CLI, and Codex. Targets context rot with spec-driven development, subagent orchestration, and state management.

### Grepika - token-efficient code search

[github.com/agentika-labs/grepika](https://github.com/agentika-labs/grepika)

MCP server that replaces built-in grep/file search with ranked, compact results using roughly 80% fewer tokens. Combines FTS5 full-text search, parallel grep, and trigram indexing with BM25 ranking.

---

## FAQ

**Which AI coding assistants does this support?**
Anything that follows the [Agent Skills](https://agentskills.io) open standard, including Claude Code, Cursor, Windsurf, GitHub Copilot, Codex, Gemini CLI, Cline, OpenCode, Continue, Trae, Roo Code, Amp, and more. Skills use portable frontmatter; platform-specific extensions (tool names, isolation, memory) are noted per-agent. The plugins under `plugins/` are the exception and need Claude Code. Agents install natively in Claude Code and, through generated TOML files, in Codex.

**Do I have to install everything?**
No. Install only the skills you need with `--skill <name>`, or one bundle such as `knowledge-virtuoso` or `playbooks-virtuoso`. Each bundle is listed in `.claude-plugin/marketplace.json`.

**Why do some skills say "run by name"?**
Textbook references such as SOLID or design patterns cover things the model already knows. They stay available, but they do not load on their own, so they add nothing to your context until you call them.

**How do I update?**
Run `npx skills update`, or `/plugin marketplace update code-virtuoso` in Claude Code. For hands-free upkeep, use one of the auto-update snippets above.

**Can I use skills across multiple projects?**
Yes - install with `-g` for global availability. Local installs live in the current project only.

**Can I contribute my own skills or agents?**
Yes. See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions, the research workflow, `marketplace.json` update rules, and version-bumping policy.

**Why not use one long CLAUDE.md file?**
One long rule file takes up context on every request. Skills use progressive disclosure: metadata sits in context, bodies load when triggered, and deep references load only when needed. Specialist knowledge costs nothing until it is relevant.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- How to add a new skill or agent
- Naming conventions and frontmatter rules
- Marketplace configuration and plugin tiers
- Version-bumping policy
- Quality standards and language/provider-agnosticism rules

Commit conventions are in [CLAUDE.md](CLAUDE.md). No AI co-author lines.

---

## License

MIT - see [LICENSE](LICENSE).

---

## Repository structure

<details>
<summary>Click to expand</summary>

```
code-virtuoso/
├── agents/                        # Sub-agent definitions (19)
│   ├── investigator.md            # Specialist: codebase exploration
│   ├── implementer.md             # Specialist: TDD execution
│   ├── reviewer.md                # Specialist: code review
│   ├── refactor-scout.md          # Specialist: code smell scanning
│   ├── dependency-auditor.md      # Specialist: CVE and license audit
│   ├── doc-writer.md              # Specialist: documentation generation
│   ├── migration-planner.md       # Specialist: migration safety
│   ├── test-gap-analyzer.md       # Specialist: coverage gaps
│   ├── cold-reviewer.md           # Specialist: zero-context review
│   ├── acceptance-verifier.md     # Specialist: criteria compliance
│   ├── plan-auditor.md            # Specialist: readiness gate and change impact
│   ├── instruction-auditor.md     # Specialist: instruction file audit
│   ├── product-manager.md         # Role: requirements, PRDs
│   ├── architect.md               # Role: system design, ADRs
│   ├── backend-dev.md             # Role: API implementation
│   ├── frontend-dev.md            # Role: UI components
│   ├── qa-engineer.md             # Role: test planning
│   ├── project-manager.md         # Role: delivery management
│   └── scrum-master.md            # Role: sprint facilitation
├── roles/                         # Templates and checklists the role agents read (not skills)
│   ├── architect/
│   ├── backend-dev/
│   ├── frontend-dev/
│   ├── product-manager/
│   ├── project-manager/
│   ├── qa-engineer/
│   └── scrum-master/
├── workflows/                     # Team workflows for Claude Code
│   ├── development-team.js
│   ├── review-squad.js
│   └── war-room.js
├── skills/
│   ├── knowledge/                 # accessibility, agent-orchestration, agent-security, api-design,
│   │                              # cicd, clean-architecture, context-engineering, database-design,
│   │                              # debugging, design-patterns, docs-lookup, microservices,
│   │                              # performance, refactoring, scrum, security, solid, testing,
│   │                              # verification-before-completion
│   ├── tools/                     # agent-creator, agentic-rules-writer, brainstorming, image-annotate,
│   │                              # plugin-creator, pr-message-writer, report-writer,
│   │                              # stakeholder-update-writer, ticket-writer, using-ecosystem,
│   │                              # web-screenshot, plus 7 headless wrappers: review-pr,
│   │                              # review-pr-cold, verify-acceptance, find-test-gaps,
│   │                              # plan-migration, audit-dependencies, scan-refactors
│   ├── playbooks/                 # finishing-branch, handoff, hooks-and-guardrails, pr-feedback,
│   │                              # spec-driven-development, tdd, ticket-delivery, worktree-ops
│   ├── frameworks/
│   │   ├── django/                # django-components
│   │   ├── langchain/             # langchain-components
│   │   ├── php/                   # php-upgrade, composer-dependencies
│   │   ├── symfony/               # symfony-components, symfony-upgrade
│   │   └── vercel/                # vercel-ai-sdk
│   └── ai/                        # agent-design, llm-evals, llm-observability, mcp-server-development
├── codex/                         # Codex support
│   ├── agents/                    # Generated custom agent TOML files
│   └── README.md
├── examples/
│   └── ci/                        # Example GitHub Actions workflows for headless agents
├── plugins/                       # Self-contained Claude Code plugins (hooks, scripts)
│   └── loop-virtuoso/             # Backlog-driven delivery loop (Claude Code only)
│       ├── .claude-plugin/        # plugin.json
│       ├── commands/
│       ├── hooks/
│       ├── scripts/
│       └── skills/
├── scripts/                       # Repository validators and the Codex agent builder
├── spec/                          # Format specifications
│   ├── skill-spec.md
│   ├── agent-spec.md
│   ├── plugin-spec.md
│   ├── team-spec.md
│   ├── config-spec.md
│   └── artifacts.md
├── template/                      # Starter templates
│   ├── skill-template.md
│   ├── agent-template.md
│   └── workflow-template.js
├── AGENTS.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

</details>

![Logo](logo.png)
# Code Virtuoso

[![Validate Skills and Agents](https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate.yml/badge.svg)](https://github.com/krzysztofsurdy/code-virtuoso/actions/workflows/validate.yml)

AI agent skill sets for software engineering — built on the [Agent Skills](https://agentskills.io) open standard. Knowledge, Tools, Frameworks, Playbooks, Roles, and Agents.

Six categories, installable independently or as bundles:

- **Knowledge** — Design Patterns, Refactoring, SOLID Principles, Debugging, Clean Architecture, Testing, API Design, Security, Scrum, Performance, Microservices, Git Workflow, CI/CD, Accessibility, Database Design. Reference material with progressive disclosure.
- **Tools** — Agentic Rules Writer. Agent configuration and bootstrapping tools.
- **Frameworks** — Symfony Components, Symfony Upgrade, Django Components, LangChain Components. Component-level reference and version upgrade guides for framework-specific development.
- **Playbooks** — PHP Upgrade, Composer Dependencies. Step-by-step operational procedures for recurring maintenance tasks.
- **Roles** — Product Manager, Architect, Backend Dev, Frontend Dev, QA Engineer, Project Manager. Reference skills defining responsibilities, workflows, and handoff checklists for each team role.
- **Agents** — 15 sub-agent definitions (8 specialist + 7 role agents) following the [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) standard. Specialist agents handle focused tasks (investigation, TDD, code review, refactoring, auditing, documentation, migration planning, test gap analysis). Role agents embody team positions with persistent memory and skill preloading.

---

## Installation

```bash
# Interactive — select skills and agents to install
npx skills add krzysztofsurdy/code-virtuoso

# Install specific skills
npx skills add krzysztofsurdy/code-virtuoso --skill design-patterns --skill refactoring

# Install all skills to all agents
npx skills add krzysztofsurdy/code-virtuoso --all

# Install globally (available in all projects)
npx skills add krzysztofsurdy/code-virtuoso -g

# List available skills without installing
npx skills add krzysztofsurdy/code-virtuoso --list
```

### Keeping Skills Updated

```bash
# Check for available updates
npx skills check

# Update all installed skills to latest versions
npx skills update
```

#### Auto-update (once daily, background)

**macOS / Linux** — runs silently on each new shell, at most once per day:

```bash
echo '_skills_marker="${TMPDIR:-/tmp}/.skills-updated-$(date +%Y%m%d)"
[ ! -f "$_skills_marker" ] && (npx skills update --yes >/dev/null 2>&1 && touch "$_skills_marker" &)' >> ~/.zshrc
```

**Windows (PowerShell)** — same behavior, once per day on shell startup:

```powershell
Add-Content $PROFILE '$marker = "$env:TEMP\.skills-updated-$(Get-Date -Format yyyyMMdd)"; if (-not (Test-Path $marker)) { Start-Job { npx skills update --yes *> $null; New-Item $using:marker -Force } | Out-Null }'
```

**Project-level** — auto-update after every `git pull` via post-merge hook:

```bash
printf '#!/bin/sh\nnpx skills update --yes >/dev/null 2>&1 &\n' > .git/hooks/post-merge && chmod +x .git/hooks/post-merge
```

---

## Knowledge Skills

| Skill | Summary |
|-------|---------|
| [Design Patterns](skills/knowledge/design-patterns/SKILL.md) | 26 Gang of Four patterns with PHP 8.3+ implementations |
| [Refactoring](skills/knowledge/refactoring/SKILL.md) | 67 refactoring techniques and 22 code smells |
| [SOLID](skills/knowledge/solid/SKILL.md) | All five SOLID principles with multi-language examples |
| [Debugging](skills/knowledge/debugging/SKILL.md) | Systematic debugging methodology and post-mortem templates |
| [Clean Architecture](skills/knowledge/clean-architecture/SKILL.md) | Clean/Hexagonal Architecture and DDD fundamentals |
| [Testing](skills/knowledge/testing/SKILL.md) | Testing pyramid, TDD schools, test doubles, strategies |
| [API Design](skills/knowledge/api-design/SKILL.md) | REST and GraphQL design principles and evolution strategies |
| [Security](skills/knowledge/security/SKILL.md) | OWASP Top 10, auth patterns, secure coding practices |
| [Scrum](skills/knowledge/scrum/SKILL.md) | Sprint goals, events, roles, and facilitation templates |
| [Performance](skills/knowledge/performance/SKILL.md) | Profiling, caching, database optimization, N+1 prevention |
| [Microservices](skills/knowledge/microservices/SKILL.md) | Saga, CQRS, event sourcing, circuit breakers, service mesh |
| [Git Workflow](skills/knowledge/git-workflow/SKILL.md) | Branching strategies, commit conventions, PR patterns, release management |
| [CI/CD](skills/knowledge/cicd/SKILL.md) | Pipeline design, deployment strategies, environment promotion |
| [Accessibility](skills/knowledge/accessibility/SKILL.md) | WCAG compliance, ARIA patterns, keyboard navigation, a11y testing |
| [Database Design](skills/knowledge/database-design/SKILL.md) | Schema modeling, indexing strategies, migration patterns, temporal data |

## Tool Skills

| Skill | Summary |
|-------|---------|
| [Agentic Rules Writer](skills/tools/agentic-rules-writer/SKILL.md) | Generate rules files for Claude Code, Cursor, Windsurf, Copilot, Gemini, Roo Code, or Amp |

## Framework Skills

| Skill | Summary |
|-------|---------|
| [Symfony Components](skills/frameworks/symfony/symfony-components/SKILL.md) | 38 Symfony components for PHP 8.3+ and Symfony 7.x |
| [Symfony Upgrade](skills/frameworks/symfony/symfony-upgrade/SKILL.md) | Deprecation-first upgrade guide for minor and major Symfony versions |
| [Django Components](skills/frameworks/django/django-components/SKILL.md) | 33 Django components for Python 3.10+ and Django 6.0 |
| [LangChain Components](skills/frameworks/langchain/langchain-components/SKILL.md) | 17 LangChain ecosystem references — models, agents, tools, retrieval, LangGraph, Deep Agents |

## Playbook Skills

| Skill | Summary |
|-------|---------|
| [PHP Upgrade](skills/playbooks/php-upgrade/SKILL.md) | PHP version upgrade process with Rector, PHPCompatibility, and per-version breaking changes |
| [Composer Dependencies](skills/playbooks/composer-dependencies/SKILL.md) | Safe dependency update strategies, security auditing, and automated update tools |

## Role Skills

| Skill | Summary |
|-------|---------|
| [Product Manager](skills/roles/product-manager/SKILL.md) | Requirements gathering, PRD writing, prioritization, acceptance criteria |
| [Architect](skills/roles/architect/SKILL.md) | System design, component boundaries, API contracts, ADRs |
| [Backend Dev](skills/roles/backend-dev/SKILL.md) | API implementation, data models, TDD workflows |
| [Frontend Dev](skills/roles/frontend-dev/SKILL.md) | UI components, accessibility, state management |
| [QA Engineer](skills/roles/qa-engineer/SKILL.md) | Test planning, test design, bug reporting, release sign-off |
| [Project Manager](skills/roles/project-manager/SKILL.md) | PRINCE2-based delivery, risk management, progress tracking |

## Agents

See [AGENTS.md](AGENTS.md) for detailed agent specifications, delegation patterns, and usage examples.

### Specialist Agents

| Agent | Model | Tools | Isolation | Purpose |
|-------|-------|-------|-----------|---------|
| [Investigator](agents/investigator.md) | haiku | Read, Grep, Glob, Bash | -- | Deep codebase exploration, dependency mapping |
| [Implementer](agents/implementer.md) | inherit | All | worktree | TDD red-green-refactor execution |
| [Reviewer](agents/reviewer.md) | inherit | Read, Grep, Glob, Bash | -- | Structured code review (SOLID, OWASP, smells) |
| [Refactor Scout](agents/refactor-scout.md) | sonnet | Read, Grep, Glob, Bash | -- | Code smell scanning, complexity hotspots |
| [Dependency Auditor](agents/dependency-auditor.md) | haiku | Bash, Read, Grep, Glob | -- | CVE checks, outdated packages, license audit |
| [Doc Writer](agents/doc-writer.md) | sonnet | Read, Grep, Glob, Bash, Write, Edit | -- | Changelogs, API docs, migration guides |
| [Migration Planner](agents/migration-planner.md) | inherit | Read, Grep, Glob, Bash | -- | Migration safety analysis, rollback paths |
| [Test Gap Analyzer](agents/test-gap-analyzer.md) | sonnet | Read, Grep, Glob, Bash | -- | Missing test coverage, untested edge cases |

### Role Agents

| Agent | Model | Tools | Isolation | Memory | Purpose |
|-------|-------|-------|-----------|--------|---------|
| [Product Manager](agents/product-manager.md) | sonnet | Read, Grep, Glob, Bash | -- | project | Requirements, PRDs, prioritization |
| [Architect](agents/architect.md) | inherit | Read, Grep, Glob, Bash | -- | project | System design, ADRs, trade-offs |
| [Backend Dev](agents/backend-dev.md) | inherit | Read, Edit, Write, Bash, Grep, Glob | worktree | -- | API implementation, data models, TDD |
| [Frontend Dev](agents/frontend-dev.md) | inherit | Read, Edit, Write, Bash, Grep, Glob | worktree | -- | UI components, accessibility, state |
| [QA Engineer](agents/qa-engineer.md) | sonnet | Read, Grep, Glob, Bash | -- | project | Test plans, bug reports, release sign-off |
| [Project Manager](agents/project-manager.md) | sonnet | Read, Grep, Glob, Bash | -- | project | PRINCE2 stages, risk, progress tracking |
| [Scrum Master](agents/scrum-master.md) | sonnet | Read, Grep, Glob, Bash | -- | -- | Sprint planning, goals, retrospectives |

---

## Repository Structure

```
code-virtuoso/
├── agents/                        # Sub-agent definitions (Anthropic standard)
│   ├── investigator.md            # Specialist: codebase exploration
│   ├── implementer.md             # Specialist: TDD execution
│   ├── reviewer.md                # Specialist: code review
│   ├── refactor-scout.md          # Specialist: code smell scanning
│   ├── dependency-auditor.md      # Specialist: CVE/license audit
│   ├── doc-writer.md              # Specialist: documentation generation
│   ├── migration-planner.md       # Specialist: migration safety
│   ├── test-gap-analyzer.md       # Specialist: coverage gaps
│   ├── product-manager.md         # Role: requirements, PRDs
│   ├── architect.md               # Role: system design, ADRs
│   ├── backend-dev.md             # Role: API implementation
│   ├── frontend-dev.md            # Role: UI components
│   ├── qa-engineer.md             # Role: test planning
│   ├── project-manager.md         # Role: delivery management
│   └── scrum-master.md            # Role: sprint facilitation
├── skills/
│   ├── knowledge/
│   │   ├── api-design/
│   │   ├── clean-architecture/
│   │   ├── debugging/
│   │   ├── design-patterns/
│   │   ├── refactoring/
│   │   ├── microservices/
│   │   ├── cicd/
│   │   ├── git-workflow/
│   │   ├── accessibility/
│   │   ├── database-design/
│   │   ├── performance/
│   │   ├── scrum/
│   │   ├── security/
│   │   ├── solid/
│   │   └── testing/
│   ├── roles/
│   │   ├── product-manager/
│   │   ├── architect/
│   │   ├── backend-dev/
│   │   ├── frontend-dev/
│   │   ├── qa-engineer/
│   │   └── project-manager/
│   ├── frameworks/
│   │   ├── django/
│   │   │   └── django-components/
│   │   ├── langchain/
│   │   │   └── langchain-components/
│   │   └── symfony/
│   │       ├── symfony-components/
│   │       └── symfony-upgrade/
│   ├── playbooks/
│   │   ├── php-upgrade/
│   │   └── composer-dependencies/
│   └── tools/
│       └── agentic-rules-writer/
├── spec/                          # Format specifications
│   ├── agent-skills-spec.md
│   ├── skill-spec.md
│   └── agent-spec.md
├── template/                      # Starter templates
│   ├── SKILL.md
│   └── agent.md
├── AGENTS.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Recommended Companion Tools

### Beads — Task Memory for AI Agents

[github.com/steveyegge/beads](https://github.com/steveyegge/beads)

A distributed, git-backed graph issue tracker that gives AI agents persistent, structured memory for long-horizon tasks. Replaces ad-hoc markdown planning files with a dependency-aware task graph stored in a version-controlled database.

### GSD — Spec-Driven Development

[github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)

A meta-prompting and context engineering system for Claude Code, OpenCode, Gemini CLI, and Codex. Solves context rot — the quality degradation that happens as Claude fills its context window. Spec-driven development with subagent orchestration and state management.

### Grepika — Token-Efficient Code Search

[github.com/agentika-labs/grepika](https://github.com/agentika-labs/grepika)

An MCP server that replaces built-in grep/file search with ranked, compact results using ~80% fewer tokens. Combines FTS5 full-text search, parallel grep, and trigram indexing with BM25 ranking.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding or improving skills.

## License

MIT

<p align="center">
  <img src="logo.png" alt="Code Virtuoso" width="220" />
</p>

<h1 align="center">Code Virtuoso</h1>

<p align="center">
  Skills, sub-agents, and playbooks for Claude Code, Cursor, and any Agent Skills–compatible AI coding assistant.
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

> **What you get:** 30+ curated skills, 15 sub-agents, 7 team role personas, and operational playbooks -- all installable individually or as bundles, based on the open [Agent Skills](https://agentskills.io) standard. Turn your AI coding assistant from a generalist into a domain specialist.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

<details>
<summary><strong>Table of Contents</strong></summary>

- [Quickstart](#quickstart)
- [Why Use This](#why-use-this)
- [What's Inside](#whats-inside)
- [Knowledge Skills](#knowledge-skills)
- [Tool Skills](#tool-skills)
- [Framework Skills](#framework-skills)
- [Playbook Skills](#playbook-skills)
- [Role Skills](#role-skills)
- [Agents](#agents)
- [Installation (detailed)](#installation-detailed)
- [Works Well With](#works-well-with)
- [FAQ](#faq)
- [Contributing](#contributing)
- [License](#license)
- [Repository Structure](#repository-structure)

</details>

---

## Quickstart

```bash
# 1. Install (interactive -- pick what you want)
npx skills add krzysztofsurdy/code-virtuoso

# 2. Try a skill immediately
/ticket-writer
# Follow the prompts -- paste the output into Jira, Linear, or GitHub Issues.
```

That is the whole tour. For fine-grained install modes (per-skill, global, offline, auto-update) see [Installation (detailed)](#installation-detailed).

---

## Why Use This

- **Battle-tested, not LLM-generated.** Every skill was researched against official docs and community best practices, then hand-curated. No hallucinated API references.
- **Progressive disclosure keeps your context clean.** Skills load a short `SKILL.md` first and only pull in deeper references when the task calls for them. Less context rot, sharper answers.
- **One installation, many tools.** Built on the open Agent Skills standard -- works with Claude Code, Cursor, Windsurf, Copilot, Codex, Gemini CLI, and more. No lock-in.
- **Team-shaped, not pattern-shaped.** The library ships 7 role personas (Product Manager, Architect, Backend Dev, Frontend Dev, QA, PM, Scrum Master) and 15 sub-agents that delegate like a real team rather than a single over-prompted assistant.

---

## What's Inside

| Category | Count | Summary |
|---|---|---|
| [Knowledge](#knowledge-skills) | 18 | Principles, craft, process, and agent workflow references |
| [Tools](#tool-skills) | 6 | Interactive generators -- rules files, tickets, agents, plugins |
| [Frameworks](#framework-skills) | 4 | Symfony, Django, LangChain component libraries and upgrade guides |
| [Playbooks](#playbook-skills) | 3 | Step-by-step procedures for recurring operational tasks |
| [Roles](#role-skills) | 6 | Team-role reference skills used by role agents |
| [Agents](#agents) | 15 | 8 specialist + 7 role sub-agents with tool, isolation, and memory metadata |

---

## Knowledge Skills

Grouped by theme. Each skill is a self-contained reference with a short `SKILL.md` and deep-dive files under `references/`.

### Principles & Design

| Skill | Summary |
|-------|---------|
| [Design Patterns](skills/knowledge/design-patterns/SKILL.md) | 26 Gang of Four patterns with idiomatic implementations |
| [SOLID](skills/knowledge/solid/SKILL.md) | All five SOLID principles with multi-language examples |
| [Clean Architecture](skills/knowledge/clean-architecture/SKILL.md) | Clean/Hexagonal Architecture and DDD fundamentals |
| [Refactoring](skills/knowledge/refactoring/SKILL.md) | 67 refactoring techniques and 22 code smells |

### Craft & Code

| Skill | Summary |
|-------|---------|
| [Testing](skills/knowledge/testing/SKILL.md) | Testing pyramid, TDD schools, test doubles, strategies |
| [Debugging](skills/knowledge/debugging/SKILL.md) | Systematic debugging methodology and post-mortem templates |
| [API Design](skills/knowledge/api-design/SKILL.md) | REST and GraphQL design principles and evolution strategies |
| [Database Design](skills/knowledge/database-design/SKILL.md) | Schema modeling, indexing strategies, migration patterns |
| [Performance](skills/knowledge/performance/SKILL.md) | Profiling, caching, database optimization, N+1 prevention |
| [Security](skills/knowledge/security/SKILL.md) | OWASP Top 10, auth patterns, secure coding practices |
| [Accessibility](skills/knowledge/accessibility/SKILL.md) | WCAG compliance, ARIA patterns, keyboard navigation, a11y testing |

### Process & Delivery

| Skill | Summary |
|-------|---------|
| [Scrum](skills/knowledge/scrum/SKILL.md) | Sprint goals, events, roles, and facilitation templates |
| [Git Workflow](skills/knowledge/git-workflow/SKILL.md) | Branching strategies, commit conventions, PR patterns |
| [CI/CD](skills/knowledge/cicd/SKILL.md) | Pipeline design, deployment strategies, environment promotion |
| [Microservices](skills/knowledge/microservices/SKILL.md) | Saga, CQRS, event sourcing, circuit breakers, service mesh |

### Agent Workflow

| Skill | Summary |
|-------|---------|
| [Verification Before Completion](skills/knowledge/verification-before-completion/SKILL.md) | Evidence-based completion discipline and tiered definition of done |
| [Dispatching Parallel Agents](skills/knowledge/dispatching-parallel-agents/SKILL.md) | Fan-out/fan-in patterns, subagent briefing, result synthesis |
| [Subagent-Driven Development](skills/knowledge/subagent-driven-development/SKILL.md) | One-fresh-agent-per-task execution with two-stage review gates |

---

## Tool Skills

Interactive generators. Each is user-invocable via `/skill-name`.

| Skill | Summary |
|-------|---------|
| [Agentic Rules Writer](skills/tools/agentic-rules-writer/SKILL.md) | Generate rules files for Claude Code, Cursor, Windsurf, Copilot, Gemini, Roo Code, or Amp |
| [Ticket Writer](skills/tools/ticket-writer/SKILL.md) | Write tickets of the right type -- story, subtask, issue, bug, epic, or initiative |
| [Agent Creator](skills/tools/agent-creator/SKILL.md) | Design a sub-agent with proper frontmatter, tool permissions, isolation, and system prompt |
| [Plugin Creator](skills/tools/plugin-creator/SKILL.md) | Scaffold a complete Claude Code plugin -- manifest, skills, agents, hooks, MCP/LSP servers |
| [Brainstorming](skills/tools/brainstorming/SKILL.md) | Pre-implementation design exploration -- turn a vague idea into an approved spec |
| [Using Virtuoso](skills/tools/using-virtuoso/SKILL.md) | Guided tour and discovery advisor for the ecosystem |

---

## Framework Skills

| Skill | Summary |
|-------|---------|
| [Symfony Components](skills/frameworks/symfony/symfony-components/SKILL.md) | 38 Symfony components for PHP 8.3+ and Symfony 7.x |
| [Symfony Upgrade](skills/frameworks/symfony/symfony-upgrade/SKILL.md) | Deprecation-first upgrade guide for minor and major versions |
| [Django Components](skills/frameworks/django/django-components/SKILL.md) | 33 Django components for Python 3.10+ and Django 6.0 |
| [LangChain Components](skills/frameworks/langchain/langchain-components/SKILL.md) | 17 LangChain references -- models, agents, tools, retrieval, LangGraph |

---

## Playbook Skills

| Skill | Summary |
|-------|---------|
| [PHP Upgrade](skills/playbooks/php-upgrade/SKILL.md) | PHP version upgrade process with Rector, PHPCompatibility, breaking changes |
| [Composer Dependencies](skills/playbooks/composer-dependencies/SKILL.md) | Safe dependency updates, security auditing, automated update tools |
| [Finishing Branch](skills/playbooks/finishing-branch/SKILL.md) | End-to-end branch finishing -- pre-push checks, PR messages, cleanup, recovery |

---

## Role Skills

| Skill | Summary |
|-------|---------|
| [Product Manager](skills/roles/product-manager/SKILL.md) | Requirements gathering, PRD writing, prioritization, acceptance criteria |
| [Architect](skills/roles/architect/SKILL.md) | System design, component boundaries, API contracts, ADRs |
| [Backend Dev](skills/roles/backend-dev/SKILL.md) | API implementation, data models, TDD workflows |
| [Frontend Dev](skills/roles/frontend-dev/SKILL.md) | UI components, accessibility, state management |
| [QA Engineer](skills/roles/qa-engineer/SKILL.md) | Test planning, test design, bug reporting, release sign-off |
| [Project Manager](skills/roles/project-manager/SKILL.md) | PRINCE2-based delivery, risk management, progress tracking |

---

## Agents

Sub-agents follow the [Claude Code sub-agents](https://code.claude.com/docs/en/sub-agents) standard. **Specialist** agents handle one focused task type. **Role** agents embody a team position and carry persistent project memory. See [AGENTS.md](AGENTS.md) for full specifications, delegation patterns, and chaining examples.

| Kind | Agent | Tools | Isolation | Memory | Purpose |
|------|-------|-------|-----------|--------|---------|
| Specialist | [Investigator](agents/investigator.md) | Read, Grep, Glob, Bash | -- | -- | Deep codebase exploration, dependency mapping |
| Specialist | [Implementer](agents/implementer.md) | All | worktree | -- | TDD red-green-refactor execution |
| Specialist | [Reviewer](agents/reviewer.md) | Read, Grep, Glob, Bash | -- | -- | Structured code review (SOLID, OWASP, smells) |
| Specialist | [Refactor Scout](agents/refactor-scout.md) | Read, Grep, Glob, Bash | -- | -- | Code smell scanning, complexity hotspots |
| Specialist | [Dependency Auditor](agents/dependency-auditor.md) | Bash, Read, Grep, Glob | -- | -- | CVE checks, outdated packages, license audit |
| Specialist | [Doc Writer](agents/doc-writer.md) | Read, Grep, Glob, Bash, Write, Edit | -- | -- | Changelogs, API docs, migration guides |
| Specialist | [Migration Planner](agents/migration-planner.md) | Read, Grep, Glob, Bash | -- | -- | Migration safety analysis, rollback paths |
| Specialist | [Test Gap Analyzer](agents/test-gap-analyzer.md) | Read, Grep, Glob, Bash | -- | -- | Missing test coverage, untested edge cases |
| Role | [Product Manager](agents/product-manager.md) | Read, Grep, Glob, Bash | -- | project | Requirements, PRDs, prioritization |
| Role | [Architect](agents/architect.md) | Read, Grep, Glob, Bash | -- | project | System design, ADRs, trade-offs |
| Role | [Backend Dev](agents/backend-dev.md) | Read, Edit, Write, Bash, Grep, Glob | worktree | -- | API implementation, data models, TDD |
| Role | [Frontend Dev](agents/frontend-dev.md) | Read, Edit, Write, Bash, Grep, Glob | worktree | -- | UI components, accessibility, state |
| Role | [QA Engineer](agents/qa-engineer.md) | Read, Grep, Glob, Bash | -- | project | Test plans, bug reports, release sign-off |
| Role | [Project Manager](agents/project-manager.md) | Read, Grep, Glob, Bash | -- | project | PRINCE2 stages, risk, progress tracking |
| Role | [Scrum Master](agents/scrum-master.md) | Read, Grep, Glob, Bash | -- | -- | Sprint planning, goals, retrospectives |

---

## Installation (detailed)

### Selective install

```bash
# Pick individual skills
npx skills add krzysztofsurdy/code-virtuoso --skill design-patterns --skill refactoring

# Everything at once
npx skills add krzysztofsurdy/code-virtuoso --all

# Install globally (available in every project)
npx skills add krzysztofsurdy/code-virtuoso -g

# Preview what's available without installing
npx skills add krzysztofsurdy/code-virtuoso --list
```

### Updating

```bash
npx skills check    # see what can be updated
npx skills update   # update everything installed
```

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

## Works Well With

Companion tools that pair naturally with this library.

### Beads -- Task Memory for AI Agents

[github.com/steveyegge/beads](https://github.com/steveyegge/beads)

Distributed, git-backed graph issue tracker that gives AI agents persistent, structured memory for long-horizon tasks. Replaces ad-hoc markdown planning files with a dependency-aware task graph.

### GSD -- Spec-Driven Development

[github.com/gsd-build/get-shit-done](https://github.com/gsd-build/get-shit-done)

Meta-prompting and context engineering system for Claude Code, OpenCode, Gemini CLI, and Codex. Targets context rot with spec-driven development, subagent orchestration, and state management.

### Grepika -- Token-Efficient Code Search

[github.com/agentika-labs/grepika](https://github.com/agentika-labs/grepika)

MCP server that replaces built-in grep/file search with ranked, compact results using roughly 80% fewer tokens. Combines FTS5 full-text search, parallel grep, and trigram indexing with BM25 ranking.

---

## FAQ

**Which AI coding assistants does this support?**
Anything that follows the [Agent Skills](https://agentskills.io) open standard, including Claude Code, Cursor, Windsurf, GitHub Copilot, Codex, Gemini CLI, Cline, OpenCode, Continue, Trae, Roo Code, Amp, and more. Skills use portable frontmatter; platform-specific extensions (tool names, isolation, memory) are noted per-agent.

**Do I have to install the full bundle?**
No. Install only the skills you need with `--skill <name>`, or install a single plugin (e.g., `role-backend-dev`, `knowledge-virtuoso`, `tool-ticket-writer`). Each plugin is documented in `.claude-plugin/marketplace.json`.

**How do I update?**
Run `npx skills update`. For hands-free upkeep, use one of the auto-update snippets above.

**Can I use skills across multiple projects?**
Yes -- install with `-g` for global availability. Local installs live in the current project only.

**Can I contribute my own skills or agents?**
Yes. See [CONTRIBUTING.md](CONTRIBUTING.md) for conventions, the research workflow, `marketplace.json` update rules, and version-bumping policy.

**Why not just prompt-engineer one long CLAUDE.md file?**
One long rule file consumes context on every request. Skills use progressive disclosure -- metadata sits in context, bodies load only when triggered, deep references load only when explicitly needed. You get specialist knowledge without paying for it until it's relevant.

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

MIT -- see [LICENSE](LICENSE).

---

## Repository Structure

<details>
<summary>Click to expand</summary>

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
│   │   ├── testing/
│   │   ├── verification-before-completion/
│   │   ├── dispatching-parallel-agents/
│   │   └── subagent-driven-development/
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
│   │   ├── composer-dependencies/
│   │   └── finishing-branch/
│   └── tools/
│       ├── agentic-rules-writer/
│       ├── ticket-writer/
│       ├── agent-creator/
│       ├── plugin-creator/
│       ├── brainstorming/
│       └── using-virtuoso/
├── spec/                          # Format specifications
│   ├── agent-skills-spec.md
│   ├── skill-spec.md
│   ├── agent-spec.md
│   └── plugin-spec.md
├── template/                      # Starter templates
│   ├── SKILL.md
│   └── agent.md
├── AGENTS.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

</details>

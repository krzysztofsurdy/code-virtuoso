# Changelog

All notable changes to Code Virtuoso are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- `skills/tools/brainstorming` -- interactive pre-implementation design exploration with hard approval gate
- `skills/tools/using-virtuoso` -- meta-skill ecosystem discovery advisor covering skill categories, agent tiers, chaining patterns, and plugin tiers
- `skills/tools/pr-message-writer` -- structured pull request message generation with testing instructions (migrated from dev-virtuoso, made CLI/language/tracker-agnostic)
- `skills/tools/report-writer` -- standalone HTML report generation with Tailwind styling, semantic color tokens, Bootstrap Icons, and print/PDF support (migrated from dev-virtuoso)
- `skills/tools/stakeholder-update-writer` -- stakeholder Slack/email update drafting (migrated from dev-virtuoso)
- `skills/playbooks/ticket-delivery` -- end-to-end ticket workflow from analysis through TDD to PR creation (migrated from dev-virtuoso, made CLI/language/tracker-agnostic)
- `skills/playbooks/worktree-ops` -- git worktree management (create, list, switch, remove) merged from 4 separate skills (migrated from dev-virtuoso)
- `skills/knowledge/verification-before-completion` -- evidence-based completion discipline with tiered definition of done
- `skills/knowledge/dispatching-parallel-agents` -- fan-out/fan-in patterns, briefing, context isolation, result synthesis
- `skills/knowledge/subagent-driven-development` -- one-fresh-agent-per-task with two-stage review gates and structured hand-offs
- `skills/playbooks/finishing-branch` -- end-to-end branch finishing workflow
- CHANGELOG.md covering full git history (25 versions, 167 commits)

### Changed
- Consolidated marketplace from 27 individual plugins down to 5 category bundles (knowledge-virtuoso, tools-virtuoso, frameworks-virtuoso, playbooks-virtuoso, agents-virtuoso)
- agentic-rules-writer: removed filesystem scanning for skills and agents, deferred ecosystem inventory to `using-virtuoso` as single source of truth
- `using-virtuoso` ecosystem map, decision matrix, and plugin tiers updated with all new skills and 5-bundle model
- `knowledge-virtuoso` plugin expanded from 15 to 18 skills
- `tools-virtuoso` plugin expanded from 6 to 9 skills
- `playbooks-virtuoso` plugin expanded from 3 to 5 skills
- README rewritten with centered hero, quickstart, grouped knowledge tables, merged agent table, FAQ, collapsible sections
- CONTRIBUTING.md updated to reflect simplified plugin distribution model

## [8.2.0] - 2026-04-13

### Added
- `skills/tools/agent-creator` -- tool skill for generating new agent definitions
- `skills/tools/plugin-creator` -- tool skill for generating new marketplace plugin entries
- `tool-agent-creator` and `tool-plugin-creator` plugins in marketplace

## [8.1.0] - 2026-04-13

### Added
- `skills/tools/ticket-writer` -- interactive tool to draft well-formed tickets for six types (story, subtask, issue, bug, epic, initiative), each with its own structure, required fields, questionnaire, output template, and quality checks
- `tool-ticket-writer` plugin in marketplace

## [8.0.0] - 2026-03-12

### Added
- Scrum Master role skill (`skills/roles/scrum-master`) with references
- Individual agent plugins: `agent-investigator`, `agent-implementer`, `agent-reviewer`, `agent-refactor-scout`, `agent-dependency-auditor`, `agent-doc-writer`, `agent-migration-planner`, `agent-test-gap-analyzer`
- Individual role plugins: `role-product-manager`, `role-architect`, `role-backend-dev`, `role-frontend-dev`, `role-qa-engineer`, `role-project-manager`, `role-scrum-master`
- CI validation workflow with 4 separate jobs (YAML lint, markdown lint, marketplace validation, broken-link check) and individual badges
- `.gitignore` entry for `__pycache__`

### Changed
- Consolidated marketplace from granular plugins into tiered distribution model (individual, category bundle, agents bundle)
- `agents-virtuoso` plugin now includes all 15 agents plus all 7 role skills
- README updated with CI badges and new logo

### Removed
- `__pycache__` directories from tracked files

## [7.14.0] - 2026-03-11 <!-- not tagged -->

### Added
- Role reference files for all 6 role skills (product-manager, architect, backend-dev, frontend-dev, qa-engineer, project-manager)
- `AGENTS.md` -- sub-agent architecture documentation, chaining patterns, and conventions
- `CONTRIBUTING.md` -- full contributor guide with skill creation, agent creation, and marketplace rules
- `CLAUDE.md` -- Claude Code tool mapping and project-specific instructions

### Changed
- Enriched agent descriptions with keyword-rich trigger conditions
- Removed `model` field from all agent definitions (provider-agnostic policy)
- Fixed `user-invocable` values across all skills
- Preloaded knowledge skills into agent definitions
- Restructured project documentation

## [7.13.0] - 2026-03-08 <!-- not tagged -->

### Added
- 15 sub-agent definitions: Investigator, Implementer, Reviewer, Refactor Scout, Dependency Auditor, Doc Writer, Migration Planner, Test Gap Analyzer, Product Manager, Architect, Backend Dev, Frontend Dev, QA Engineer, Project Manager, Scrum Master
- 6 role skills: `skills/roles/product-manager`, `skills/roles/architect`, `skills/roles/backend-dev`, `skills/roles/frontend-dev`, `skills/roles/qa-engineer`, `skills/roles/project-manager`

## [7.11.0] - 2026-03-07 <!-- not tagged -->

### Added
- Django 6.0 components skill (`skills/frameworks/django`) with 33 reference files covering models, views, templates, forms, admin, authentication, caching, testing, middleware, signals, deployment, async, and utility components
- `django-virtuoso` plugin in marketplace

## [7.10.1] - 2026-03-06 <!-- not tagged -->

### Changed
- agentic-rules-writer: added always-generated rules section to output templates

## [7.10.0] - 2026-03-06 <!-- not tagged -->

### Added
- `skills/playbooks/php-upgrade` -- PHP version upgrade guide (8.0 through 8.4+) with Rector, PHPCompatibility, and testing strategies
- `skills/playbooks/symfony-upgrade` -- Symfony version upgrade guide with deprecation-first approach and recipe updates
- `skills/playbooks/composer-dependencies` -- Composer dependency update playbook with security auditing and lock file management
- `playbooks-virtuoso` plugin in marketplace
- Updated README with playbooks section and new directory structure

## [7.9.0] - 2026-03-06 <!-- not tagged -->

### Changed
- agentic-rules-writer: added new questions, reordered questionnaire flow, improved agent support in generated output

## [7.8.0] - 2026-03-06 <!-- not tagged -->

### Changed
- agentic-rules-writer: switched questionnaire to interactive menu-based selection

## [7.7.0] - 2026-03-06 <!-- not tagged -->

### Added
- `skills/knowledge/database-design` -- normalization, indexing strategies, schema evolution, migration patterns, temporal data, audit trails, and partitioning

## [7.6.0] - 2026-03-05 <!-- not tagged -->

### Added
- `skills/knowledge/accessibility` -- WCAG compliance, semantic HTML, ARIA, keyboard navigation, color contrast, screen reader support, and accessible forms

## [7.5.0] - 2026-03-04 <!-- not tagged -->

### Added
- `skills/knowledge/cicd` -- CI/CD pipeline patterns, deployment models (blue-green, canary, rolling), environment promotion, and artifact management

## [7.4.0] - 2026-03-03 <!-- not tagged -->

### Added
- `skills/knowledge/git-workflow` -- branching strategies, commit conventions, PR workflows, release management, and monorepo patterns

## [7.2.0] - 2026-03-02 <!-- not tagged -->

### Added
- `skills/knowledge/microservices` -- service decomposition, saga orchestration, CQRS, event sourcing, circuit breakers, and API gateways

## [7.1.0] - 2026-03-01 <!-- not tagged -->

### Added
- `skills/knowledge/performance` -- profiling strategies, caching layers, database query optimization, memory management, lazy loading, and N+1 prevention

## [7.0.1] - 2026-03-05 <!-- not tagged -->

### Changed
- Restructured directory layout: added `spec/` (format specifications) and `template/` (starter templates) directories
- Updated README installation docs
- Hidden template directory from skill discovery
- Added GSD to recommended tools, added auto-update and installation documentation

## [6.5.0] - 2026-03-04 <!-- not tagged -->

### Added
- `skills/knowledge/scrum` -- sprint planning, sprint goals, daily scrums, sprint reviews, retrospectives, scrum roles, and artifacts
- Scrum Master agent definition
- `scrum-virtuoso` plugin in marketplace

## [6.4.0] - 2026-03-02 <!-- not tagged -->

### Changed
- Added `user-invocable: false` to all knowledge and framework skills

## [6.3.0] - 2026-03-02 <!-- not tagged -->

### Changed
- agentic-rules-writer: added custom agent scanning alongside skill scanning

## [6.2.0] - 2026-03-02 <!-- not tagged -->

### Changed
- agentic-rules-writer: added critical skill utilization rule to generated rules output

## [6.1.0] - 2026-03-02 <!-- not tagged -->

### Changed
- agentic-rules-writer: expanded questionnaire with parallelization, communication style, directory structure, error handling, persona, co-authorship, and documentation level questions

## [6.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- `skills/knowledge/clean-architecture` -- Clean Architecture, Hexagonal Architecture, and DDD fundamentals
- `skills/knowledge/testing` -- testing pyramid, test design, TDD, test doubles, and testing antipatterns
- `skills/knowledge/api-design` -- REST and GraphQL API design, resource modeling, versioning, and pagination
- `skills/knowledge/security` -- OWASP Top 10, injection prevention, authentication, authorization, and secrets management
- Project logo

### Changed
- Improved wording across all design patterns, refactoring, and SOLID reference files (two-pass improvement)

## [5.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- `skills/knowledge/debugging` -- systematic debugging workflow with root cause analysis, bug category strategies, and post-mortem documentation
- `skills/tools/agentic-rules-writer` (moved from `setup/` category)

### Changed
- Restructured plugins: merged `design-patterns-virtuoso`, `refactoring-virtuoso`, and `solid-virtuoso` into single `knowledge-virtuoso` plugin
- Made `CONTRIBUTING.md` fully stack-agnostic (removed PHP/Symfony-specific references)
- Removed private dev-virtuoso references from agentic-rules-writer

### Removed
- Workflow and role skills moved to separate `dev-virtuoso` repository

## [3.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- `skills/tools/agentic-rules-writer` -- interactive rules file generator for AI coding agents

### Changed
- Restructured skills directory from flat layout into `knowledge/`, `workflows/`, and `frameworks/` categories
- Symfony skills moved under `skills/frameworks/symfony/`

## [2.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- Multi-language examples (PHP, Java, Python, TypeScript, Go) to all 26 design pattern references
- Multi-language examples and guidance to all refactoring technique references
- `solid-virtuoso` plugin with 5 SOLID principle reference files (SRP, OCP, LSP, ISP, DIP)

### Changed
- Consolidated individual skill entries into 3 top-level plugin paths (one per skill category)

### Removed
- Symfony component skills removed from this repository (moved to `krzysztofsurdy/symfony-virtuoso`)

## [1.1.0] - 2026-02-25 <!-- not tagged -->

### Added
- `.claude-plugin/marketplace.json` with three plugins: `symfony-virtuoso`, `design-patterns-virtuoso`, `refactoring-virtuoso`

### Fixed
- Cleaned up stale `.gitkeep` files

## [1.0.0] - 2026-02-22 <!-- not tagged -->

Initial release. All content was added before the marketplace existed; version inferred from the first marketplace entry (1.1.0).

### Added
- Project structure, contributing guide, and skill template
- 38 Symfony component skills (Asset through Yaml)
- 26 design pattern skills: 6 creational (Abstract Factory, Builder, Factory Method, Prototype, Singleton, Object Pool), 8 structural (Adapter, Bridge, Composite, Decorator, Facade, Flyweight, Proxy, Private Class Data), 12 behavioral (Chain of Responsibility, Command, Interpreter, Iterator, Mediator, Memento, Null Object, Observer, State, Strategy, Template Method, Visitor)
- 67 refactoring technique skills across 7 categories: composing methods (9), moving features (8), organizing data (16), simplifying conditionals (8), simplifying method calls (12), dealing with generalization (12), plus 2 additional
- 22 code smell skills: bloaters (5), object-orientation abusers (4), change preventers (3), dispensables (6), couplers (4)

[Unreleased]: https://github.com/krzysztofsurdy/code-virtuoso/compare/v8.2.0...HEAD
[8.2.0]: https://github.com/krzysztofsurdy/code-virtuoso/releases/tag/v8.2.0
[8.1.0]: https://github.com/krzysztofsurdy/code-virtuoso/releases/tag/v8.1.0

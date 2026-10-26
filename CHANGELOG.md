# Changelog

All notable changes to Code Virtuoso are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [11.0.0] - 2026-10-26

### Removed
- 28 skills that a fair, fixture-backed A/B measurement (with-skill vs without-skill arms, blind judge) showed a strong current model already matches unaided, so they no longer earned their context cost. This is breaking: these skills no longer install.
  - AI: `agent-design`, `mcp-server-development`
  - Frameworks: `doctrine-orm`, `symfony-testing`, `symfony-components`, `django-components`, `langchain-components`, `php-quality`
  - Knowledge: `agent-orchestration`, `agent-security`, `api-design`, `cicd`, `clean-architecture`, `database-design`, `design-patterns`, `microservices`, `motion-design`, `refactoring`, `scrum`, `solid`, `testing`
  - Playbooks: `video-production`, `retro`, `ticket-delivery`, `worktree-ops`
  - Tools: `using-ecosystem`, `web-screenshot`, `image-annotate`
- The trigger, outcome, and demotion eval cases for the removed skills
- Agent preloads were unaffected: every skill still preloaded by an agent (`security`, `debugging`, `accessibility`, `context-engineering`, `docs-lookup`, `tdd`, `verification-before-completion`, `research`) was kept

### Added
- `skill-measure` tool skill (run by name): audits whether a skill or reference changes a strong model's output enough to earn its context cost, using a fair-fixture A/B ablation and a blind judge that also returns a worth-improving verdict. Two trigger evals

### Changed
- Renamed the `skill-writer` tool skill to `skill-creator`, with its references and eval cases. Anthropic's separate `skill-creator` is disambiguated by plugin prefix (`tools-virtuoso:skill-creator` vs `anthropic-skills:skill-creator`)
- Trimmed the auto-loaded bodies of `security`, `debugging`, `context-engineering`, `accessibility`, `docs-lookup`, and `llm-evals` to their load-bearing content (version facts, gates, decision tables, pitfalls), cutting slogan and restated-knowledge sections; reference files unchanged
- Fixed a WCAG citation in `accessibility` (`keyboard-and-focus.md`): 2.4.11 is Focus Not Obscured, Minimum (AA); the 2px and 3:1 contrast rule is 2.4.13 Focus Appearance (AAA)
- Moved the team recipe `teams.md` out of the removed `agent-orchestration` skill to `workflows/teams.md`; the review-squad, development-team, and war-room workflows and commands are unchanged
- Bundle sizes are now knowledge-virtuoso 6, ai-virtuoso 2, frameworks-virtuoso 6, playbooks-virtuoso 8, tools-virtuoso 13

## [10.5.0] - 2026-10-23

### Added
- `retro` playbook: review an agent coding session for friction (repeated mistakes, wasted tool calls, missing checks, ignored rules) and turn each finding into the cheapest durable fix, preferring a lint rule, hook, or CI check over another prose rule. A repeated mistake with no guardrail is itself a finding. Cross-links `hooks-and-guardrails`, `agentic-rules-writer`, `context-engineering`, and the `instruction-auditor` agent. Three trigger evals
- `context-engineering`: a `writing-levers` reference (leading words, positive phrasing over prohibitions, the no-op test) and a project glossary convention with banned synonyms
- `spec-driven-development`: a `slicing` reference (vertical tracer-bullet slices sized to one context window with declared blockers, and expand/migrate/contract for wide refactors) and a glossary step

### Changed
- `implementer` agent no longer carries the full coding-standards document; the `reviewer` agent now owns enforcing documented standards, so the implementer spends its context on the code
- `pr-message-writer`: every PR type now includes a Merge Danger section (reversibility as a one-way or two-way door, plus blast radius) and an Evidence tier order (screenshot, then execution output, then before/after); reversibility and rollback moved out of the migration-only path into Merge Danger
- `ticket-writer`: prefer a vertical slice that declares its blockers
- Ideas adopted from Matt Pocock's skills and Humanlayer's show-me (both MIT), re-authored, no text copied

## [10.4.0] - 2026-10-22

### Added
- `communication-style` tool skill: writes messages in the user's own voice instead of a generic AI tone. An always-on default voice, a per-person overlay that tunes delivery only when a recipient is named (never replacing the voice, never switching mid-stream), and channel tuning for chat, PR comments, email and tickets. Profiles are saved per user under the config home, never in a repo. A setup mode builds the default voice and person profiles from samples or a few questions; person profiles come only from conversations the user provides, with no web research
- Three trigger evals for the skill

## [10.3.0] - 2026-10-22

### Added
- `security-research` playbook: a gated loop for authorized vulnerability research and coordinated disclosure. Authorization gate first (in-scope bounty target, open-source code run in your own lab, or a system you own), a mandatory live-research step that pulls current CVEs, write-ups and tooling every run, then hunt, reproduce with a minimal non-weaponized PoC, classify with CWE and CVSS, report privately, and write up after the patch. It points to `trailofbits/skills` and `rea` rather than rebuilding them, and to the repo's own `security`, `agent-security`, `research`, `docs-lookup` and `verification-before-completion` skills. References cover techniques, lab setup, disclosure and the CVE path, feeds to monitor, and the authorization and legal boundary (general information, not legal advice)
- Research notes with a prior-art table and fact ledger, and three trigger evals for the skill

## [10.2.0] - 2026-10-22

### Added
- `motion-design` knowledge skill: timing and easing by role, holds by reading time, frame and safe-area rules, an accessibility gate, and the tells of generated-looking motion
- `video-production` playbook: brief, engine choice (Remotion, HyperFrames, Motion Canvas, Manim, Lottie and Rive, ffmpeg, generative), storyboard stills, numeric spec, frame-snapshot review, audio and loudness, render, delivery
- `game-feature-loop` playbook: one mechanic at a time on any engine, proven from live game state, then a separate game-feel pass
- `godot` and `godot-upgrade` framework skills: the verify loop, headless test-runner traps reproduced on Godot 4.6.1, `.tscn` text rules, and behavior changes per 4.x version
- `doctrine-orm` framework skill: fetch strategy and N+1, migration ordering, transactions and locking, batches, and Messenger workers, measured on ORM 3.7
- `symfony-testing` framework skill: which test type to write, PHPUnit 11 to 13, Foundry, DAMA, HTTP client, clock, Messenger and mailer test doubles
- `php-quality` framework skill: PHPStan levels and baselines, Psalm, PER Coding Style, Rector quality sets, and PHP 8.3 to 8.5 idioms
- `ui-review` tool skill: static and rendered review of UI code against 55 sourced rules, with file:line findings and severity
- Research notes with a prior-art table and fact ledger in each new skill
- Trigger evals for every new skill, and an outcome eval for `agentic-rules-writer`

### Changed
- `agentic-rules-writer` writes only what the model cannot guess, asks eight questions after reading the repo, turns hard limits into deny rules and hooks, adds a trim mode for existing files, and checks each tool's current docs before writing
- `symfony-components` points to `doctrine-orm` for Doctrine pitfalls
- `using-ecosystem` lists vendor and community skill sets to install instead of rebuilding them
- The `context-engineering` trim trigger case also passes when `agentic-rules-writer` trim mode handles the request

## [10.1.1] - 2026-10-22

### Changed
- `agentic-rules-writer` writes rules only: no skill routing tables or agent rosters, AGENTS.md as the single source with a thin `@AGENTS.md` CLAUDE.md, a 200-line size check, and an optional reminder hook
- `context-engineering` covers skill listing overflow, instruction drift, and one source of truth for instructions
- `instruction-auditor` checks that skill references resolve, flags routing tables, estimates listing overflow, and notes whether a reminder hook exists
- `hooks-and-guardrails` adds a tested `UserPromptSubmit` reminder hook against drift
- `web-screenshot` prefers a connected real-browser extension (for example Claude in Chrome) before headless tools
- `image-annotate` offers Snipaya for hand annotation alongside the annotate.py script

## [10.1.0] - 2026-10-22

### Added
- `research` skill: answer a question from local files, official docs, and the web, with sources, confidence labels, and a list of what could not be confirmed
- `researcher` agent (read-only, produces `research-report`) and the `research-question` and `research-report` artifact types
- `skill-writer` skill: write or update a skill after researching the topic and verifying every checkable fact
- Trigger evals for `research` and `skill-writer`

### Changed
- skill-writer and agent-creator search for similar skills and agents online (skills.sh, GitHub, vendor and community libraries) and compare their strengths and weaknesses before writing a new one
- `agent-creator` runs a research phase before the design questions
- `plugin-creator` points to `skill-writer` for skill content, and to Anthropic's `skill-creator` as the eval loop when installed
- `using-ecosystem` lists `research`, `skill-writer`, and `researcher` in its decision matrix and compass

## [10.0.1] - 2026-10-22

### Changed
- `symfony-upgrade` is now a `/` command (`user-invocable: true`), like the other upgrade playbooks
- CONTRIBUTING: framework skills are hidden from the `/` menu when they are reference material, shown when they are upgrade or update procedures

## [10.0.0] - 2026-10-21

### Added
- `ai` skill category and the `ai-virtuoso` plugin: `agent-design`, `llm-evals`, `llm-observability`, `mcp-server-development`
- Knowledge skills: `agent-security`, `context-engineering`, `docs-lookup` (version-correct documentation), `agent-orchestration` (replaces four orchestration skills)
- Playbooks: `spec-driven-development`, `tdd`, `pr-feedback`, `handoff`, `hooks-and-guardrails` (with tested hook scripts for Claude Code and Codex)
- Framework skill `vercel-ai-sdk`
- `instruction-auditor` agent and the `instruction-audit-report` artifact type
- Seven headless wrapper skills (`review-pr`, `review-pr-cold`, `verify-acceptance`, `find-test-gaps`, `plan-migration`, `audit-dependencies`, `scan-refactors`) that run read-only agents as forked subagents and answer in JSON, and `examples/ci` with least-privilege GitHub Actions workflows for Claude Code and Codex
- Team workflows in `workflows/` (`review-squad`, `development-team`, `war-room`) with Markdown recipes in `agent-orchestration/references/teams.md`
- `roles/<role>/` reference files read by the role agents on demand
- Codex support: `scripts/build-codex-agents.py` generates `codex/agents/*.toml` from the agent files, `scripts/install-codex-agents.sh` installs them (28 unit tests), and `codex/README.md`
- `plugins/loop-virtuoso`, the backlog-driven delivery loop, imported with its history as a self-contained Claude Code plugin (loop-virtuoso 2.0.0 stores state under `.code-virtuoso`, keeps pipelines in user and project files, and checkpoints commits in the project's format)
- Layered `.code-virtuoso` config (`spec/config-spec.md`): user, project shared, and project local files replace settings stored next to skills
- `spec/team-spec.md` rewritten for workflows, `template/workflow-template.js`, and a skill-preloading section in `spec/agent-spec.md`
- Carried from the earlier unreleased work: `brainstorming`, `using-ecosystem`, `pr-message-writer`, `report-writer`, `stakeholder-update-writer`, `ticket-delivery`, `worktree-ops`, `verification-before-completion`, `finishing-branch`

### Changed
- Marketplace is six bundles and one self-contained plugin: `knowledge-virtuoso`, `tools-virtuoso`, `playbooks-virtuoso`, `frameworks-virtuoso`, `ai-virtuoso`, `agents-virtuoso`, and `loop-virtuoso`. Skill-only bundles use `"source": "./skills"` so installing one no longer registers all agents under its own name. `agents-virtuoso` also ships the wrapper skills, `agent-orchestration`, and `verification-before-completion`
- Role skills folded into their agents: the process lives in the agent bodies and templates and checklists moved to `roles/<role>/`. The role skills were preloaded whole on every spawn and their broad descriptions fired on everyday work
- Eleven textbook knowledge skills (`solid`, `design-patterns`, `refactoring`, `testing`, `api-design`, and others) are run by name: `disable-model-invocation: true` keeps their descriptions out of the per-turn skill list. Agents use short inline checklists instead of preloading them
- `readiness-checker` and `course-corrector` merged into `plan-auditor` (gate and change-impact modes)
- `git-workflow` merged into `finishing-branch`. PHP playbooks moved under `frameworks/php/`
- `symfony-components`, `django-components`, and `langchain-components` slimmed to version facts, opinions, and pitfalls. About 37k lines of API reference were deleted, and exact details come from `docs-lookup`
- `security` follows OWASP Top 10:2025, NIST SP 800-63B-4, and RFC 9700. `api-design` uses RFC 9457, the IETF RateLimit fields draft, the Deprecation header, and OpenAPI 3.2
- Saved choices for `ticket-delivery` and the tuned agents moved to the layered config, and subagents no longer prompt
- Skills no longer need Core Principles or Integration sections, and skill descriptions were cut to under 300 characters each
- Specs and CONTRIBUTING describe the role pairing rule, the Edit and Write isolation rule, the `ai` category, run-by-name skills, and the skills-only marketplace source
- `scripts/validate-markdown.py` ignores the `#fragment` of a file link
- Earlier unreleased work: marketplace consolidated from 27 plugins to category bundles, README rewritten, prose normalized (no em or en dashes, sentence-case headings, plain voice), Contents lists added to reference files over 100 lines, SKILL.md descriptions tightened to third-person "what and when" form, reference file limit set to 700 lines

### Removed
- Role skills (`skills/roles/`), the `readiness-checker` and `course-corrector` agents, and the `git-workflow` skill
- `skills/tools/agent-teams`, `skills/tools/dispatching-agent-teams`, `dispatching-parallel-agents`, and `subagent-driven-development`, replaced by `agent-orchestration`
- `template/team-template.md` (replaced by `template/workflow-template.js`) and per-team config files
- API reference files for Symfony, Django, and LangChain components, and the stale PHP per-version reference

### Fixed
- loop-virtuoso: checkpoints no longer use `git add -A` or `--no-verify` and never commit secret-like files, the run refuses a dirty tree or the default branch, hooks find state from the git root, one violation no longer burns the budget, a stall verdict no longer masks a real pass, worktree-isolated agents and monorepo paths resolve correctly (92 tests)
- Agent definitions: `implementer` stays inside its worktree, `cold-reviewer` has no finding quota, `dependency-auditor` uses correct audit commands, agents that write documents or memory no longer claim to be read-only, and references point to skills that exist
- Validators reject marketplace entries that share a source containing `agents/`, `commands/`, `workflows/`, or `hooks/hooks.json`, and cover plugin skills
- Plugin spec facts and YAML-unsafe descriptions
- Earlier unreleased work: wrong APIs and imports in Django, Symfony, and LangChain references, invalid code in pattern, refactoring, and SOLID examples, broken CLI `--` separators, stale agent counts in the root docs

## [8.2.0] - 2026-04-13

### Added
- `skills/tools/agent-creator` - tool skill for generating new agent definitions
- `skills/tools/plugin-creator` - tool skill for generating new marketplace plugin entries
- `tool-agent-creator` and `tool-plugin-creator` plugins in marketplace

## [8.1.0] - 2026-04-13

### Added
- `skills/tools/ticket-writer` - interactive tool to draft well-formed tickets for six types (story, subtask, issue, bug, epic, initiative), each with its own structure, required fields, questionnaire, output template, and quality checks
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
- `AGENTS.md` - sub-agent architecture documentation, chaining patterns, and conventions
- `CONTRIBUTING.md` - full contributor guide with skill creation, agent creation, and marketplace rules
- `CLAUDE.md` - Claude Code tool mapping and project-specific instructions

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
- `skills/playbooks/php-upgrade` - PHP version upgrade guide (8.0 through 8.4+) with Rector, PHPCompatibility, and testing strategies
- `skills/playbooks/symfony-upgrade` - Symfony version upgrade guide with deprecation-first approach and recipe updates
- `skills/playbooks/composer-dependencies` - Composer dependency update playbook with security auditing and lock file management
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
- `skills/knowledge/database-design` - normalization, indexing strategies, schema evolution, migration patterns, temporal data, audit trails, and partitioning

## [7.6.0] - 2026-03-05 <!-- not tagged -->

### Added
- `skills/knowledge/accessibility` - WCAG compliance, semantic HTML, ARIA, keyboard navigation, color contrast, screen reader support, and accessible forms

## [7.5.0] - 2026-03-04 <!-- not tagged -->

### Added
- `skills/knowledge/cicd` - CI/CD pipeline patterns, deployment models (blue-green, canary, rolling), environment promotion, and artifact management

## [7.4.0] - 2026-03-03 <!-- not tagged -->

### Added
- `skills/knowledge/git-workflow` - branching strategies, commit conventions, PR workflows, release management, and monorepo patterns

## [7.2.0] - 2026-03-02 <!-- not tagged -->

### Added
- `skills/knowledge/microservices` - service decomposition, saga orchestration, CQRS, event sourcing, circuit breakers, and API gateways

## [7.1.0] - 2026-03-01 <!-- not tagged -->

### Added
- `skills/knowledge/performance` - profiling strategies, caching layers, database query optimization, memory management, lazy loading, and N+1 prevention

## [7.0.1] - 2026-03-05 <!-- not tagged -->

### Changed
- Restructured directory layout: added `spec/` (format specifications) and `template/` (starter templates) directories
- Updated README installation docs
- Hidden template directory from skill discovery
- Added GSD to recommended tools, added auto-update and installation documentation

## [6.5.0] - 2026-03-04 <!-- not tagged -->

### Added
- `skills/knowledge/scrum` - sprint planning, sprint goals, daily scrums, sprint reviews, retrospectives, scrum roles, and artifacts
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
- `skills/knowledge/clean-architecture` - Clean Architecture, Hexagonal Architecture, and DDD fundamentals
- `skills/knowledge/testing` - testing pyramid, test design, TDD, test doubles, and testing antipatterns
- `skills/knowledge/api-design` - REST and GraphQL API design, resource modeling, versioning, and pagination
- `skills/knowledge/security` - OWASP Top 10, injection prevention, authentication, authorization, and secrets management
- Project logo

### Changed
- Improved wording across all design patterns, refactoring, and SOLID reference files (two-pass improvement)

## [5.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- `skills/knowledge/debugging` - systematic debugging workflow with root cause analysis, bug category strategies, and post-mortem documentation
- `skills/tools/agentic-rules-writer` (moved from `setup/` category)

### Changed
- Restructured plugins: merged `design-patterns-virtuoso`, `refactoring-virtuoso`, and `solid-virtuoso` into single `knowledge-virtuoso` plugin
- Made `CONTRIBUTING.md` fully stack-agnostic (removed PHP/Symfony-specific references)
- Removed private dev-virtuoso references from agentic-rules-writer

### Removed
- Workflow and role skills moved to separate `dev-virtuoso` repository

## [3.0.0] - 2026-02-27 <!-- not tagged -->

### Added
- `skills/tools/agentic-rules-writer` - interactive rules file generator for AI coding agents

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

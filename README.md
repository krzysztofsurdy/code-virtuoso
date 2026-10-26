<p align="center">
  <img src="logo.png" alt="Code Virtuoso" width="220" />
</p>

# Code Virtuoso

[![Version](https://img.shields.io/github/v/tag/krzysztofsurdy/code-virtuoso?label=version&color=1f6feb)](https://github.com/krzysztofsurdy/code-virtuoso/releases)
[![License](https://img.shields.io/github/license/krzysztofsurdy/code-virtuoso?color=2ea44f)](LICENSE)

Agent-agnostic skills and sub-agents for software engineering, built on the open [Agent Skills](https://agentskills.io) standard. It installs as a Claude Code plugin marketplace and works in Codex and any other tool that reads `SKILL.md` files. Release notes are in [CHANGELOG.md](CHANGELOG.md).

## Install

Claude Code:

```
/plugin marketplace add krzysztofsurdy/code-virtuoso
/plugin install knowledge-virtuoso@code-virtuoso
/plugin install agents-virtuoso@code-virtuoso
```

The agents in `agents-virtuoso` preload skills from `knowledge-virtuoso`, so install both. Other bundles are listed below.

Any agent, with the skills CLI:

```bash
npx skills add krzysztofsurdy/code-virtuoso
```

Codex: skills come from the marketplace, agents from a script. Details are in [codex/README.md](codex/README.md).

```bash
codex plugin marketplace add krzysztofsurdy/code-virtuoso
scripts/install-codex-agents.sh
```

## What is inside

45 skills, 20 agents, and 3 team workflows, in seven bundles. Install any of them with `/plugin install <bundle>@code-virtuoso`.

| Bundle | Holds |
|---|---|
| `knowledge-virtuoso` | 6 knowledge skills |
| `tools-virtuoso` | 13 tool skills |
| `playbooks-virtuoso` | 8 step-by-step procedures |
| `frameworks-virtuoso` | 6 framework skills |
| `ai-virtuoso` | 2 skills for building with LLMs and agents |
| `agents-virtuoso` | 20 agents, 3 team workflows, 8 skills (see Agents and Teams) |
| `loop-virtuoso` | Delivery loop plugin with 2 skills, opt-in guard hooks, setup audit and setup evals, Claude Code only |

A skill marked "run by name" never loads on its own. It costs no context until you call it, for example `/performance`.

### Knowledge

| Skill | Purpose |
|---|---|
| `security` | OWASP Top 10:2025, auth, secrets, secure coding |
| `debugging` | Root-cause method and post-mortem templates |
| `accessibility` | WCAG 2.1 and 2.2, ARIA, keyboard use, a11y testing |
| `context-engineering` | What a coding agent should see: AGENTS.md, rules, skill descriptions |
| `docs-lookup` | Fetch version-correct official docs instead of answering from memory |

Run by name: `performance`.

### Tools

| Skill | Purpose |
|---|---|
| `agentic-rules-writer` | Write a short rules file, or trim an existing CLAUDE.md or AGENTS.md |
| `ticket-writer` | Write a story, bug, epic, or other ticket of the right type |
| `agent-creator` | Design a sub-agent |
| `skill-creator` | Write or update a skill, researching the topic first |
| `skill-measure` | Measure whether a skill earns its context cost, with a fair A/B ablation and blind judge |
| `plugin-creator` | Scaffold a Claude Code plugin |
| `research` | Answer a question from local files, official docs, and the web, with sources |
| `brainstorming` | Turn a vague idea into an approved spec |
| `communication-style` | Write in your own voice, with per-person profiles layered on top |
| `pr-message-writer` | Write a pull request message with testing steps |
| `report-writer` | Make a standalone HTML report |
| `stakeholder-update-writer` | Draft a status update for Slack or email |
| `ui-review` | Review UI code and the rendered page against a sourced rule set |

### Playbooks

| Skill | Purpose |
|---|---|
| `spec-driven-development` | Spec, plan, and tasks in the repo, then one task at a time |
| `tdd` | Strict red-green-refactor for agents |
| `finishing-branch` | Pre-push checks, merge strategy, PR message, cleanup |
| `pr-feedback` | Triage review comments and failing CI, fix, reply |
| `handoff` | Write and resume from a handoff note |
| `hooks-and-guardrails` | Deny rules, sandbox choices, and hooks for an agent setup |
| `game-feature-loop` | One game mechanic at a time, proven in the running game, then a feel pass |
| `security-research` | Authorized vuln research: scope gate, lab repro, minimal PoC, coordinated disclosure, CVE |

### Frameworks

| Skill | Purpose |
|---|---|
| `symfony-upgrade` | Deprecation-first Symfony upgrades |
| `vercel-ai-sdk` | Version matrix, packages, the agent loop, TypeScript pitfalls |
| `php-upgrade` | PHP 7.4 to 8.5 with Rector and breaking changes |
| `composer-dependencies` | Safe Composer updates and security audits |
| `godot` | Verify loop, headless test traps, and scene-file rules for Godot 4 |
| `godot-upgrade` | Godot 4.x upgrades with behavior changes per version |

### AI engineering

| Skill | Purpose |
|---|---|
| `llm-evals` | Error analysis, binary graders, judge validation |
| `llm-observability` | OpenTelemetry GenAI traces, token and cost attribution |

### Agents

Thirteen specialists and seven roles, all in `agents-virtuoso`. Role agents read templates and checklists from [roles/](roles/README.md). Full specs and headless use are in [AGENTS.md](AGENTS.md).

| Agent | Purpose |
|---|---|
| `investigator` | Explore a code area and map dependencies |
| `researcher` | Sourced answers from docs and the web, with confidence labels |
| `implementer` | TDD in a worktree |
| `reviewer` | Structured code review |
| `cold-reviewer` | Zero-context second review |
| `acceptance-verifier` | Check a diff against acceptance criteria |
| `refactor-scout` | Code smells and complexity hotspots |
| `test-gap-analyzer` | Missing tests and edge cases |
| `dependency-auditor` | CVEs, outdated packages, licenses |
| `migration-planner` | Risk-rated migration plan with rollback |
| `doc-writer` | Changelogs, API docs, migration guides |
| `plan-auditor` | Readiness gate and change-impact check |
| `instruction-auditor` | Audit AGENTS.md, CLAUDE.md, rules, skill descriptions |
| `product-manager` | Requirements, PRDs, prioritization |
| `architect` | System design and ADRs |
| `backend-dev` | API and data model work, TDD, worktree |
| `frontend-dev` | UI components and accessibility, worktree |
| `qa-engineer` | Test plans, bug reports, release sign-off |
| `project-manager` | Stage plans, risks, progress |
| `scrum-master` | Sprint planning and retrospectives |

### Teams

A team is a fixed recipe of agents, phases, and gates. In Claude Code, run it as a workflow. Other tools can follow the Markdown recipe in [teams.md](workflows/teams.md).

| Command | Does |
|---|---|
| `/agents-virtuoso:development-team` | Ticket to merge-ready branch, with a gate between phases |
| `/agents-virtuoso:review-squad` | Parallel reviews merged into one triaged report |
| `/agents-virtuoso:war-room` | Debate a technical decision and return a synthesis. You decide |

`agents-virtuoso` also holds `verification-before-completion` and seven headless wrappers (`review-pr`, `review-pr-cold`, `verify-acceptance`, `find-test-gaps`, `plan-migration`, `audit-dependencies`, `scan-refactors`).

### Delivery loop

`loop-virtuoso` works in Claude Code only, because it ships hooks and scripts. It feeds the agent one small backlog item at a time and accepts the item only when its verify command passes and a write-boundary guard approves. It also ships opt-in guard hooks for ordinary sessions (secret files, edits to committed tests, a lint and test gate before stopping), `/loop-virtuoso:harden` for a settings baseline, `/loop-virtuoso:doctor` to audit your setup, `/loop-virtuoso:eval-setup` to measure your setup against vanilla Claude Code, and `/loop-virtuoso:scaffold` for starter templates. Install it with `/plugin install loop-virtuoso@code-virtuoso`. See [plugins/loop-virtuoso/README.md](plugins/loop-virtuoso/README.md).

## More

- Run the read-only agents in GitHub Actions: [examples/ci/](examples/ci/README.md).
- Check that skills trigger and behave: [evals/README.md](evals/README.md).
- Saved choices such as ticket pattern and test command live in `.code-virtuoso` config files: [spec/config-spec.md](spec/config-spec.md).
- Add or change a skill or agent: [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT. See [LICENSE](LICENSE).

# Plugin Tiers

How to pick what to install. Plugins in `.claude-plugin/marketplace.json` are organized as five category bundles -- one per `skills/` subdirectory, plus one for agents.

## The Five Bundles

| Bundle | Contains | Count |
|---|---|---|
| `knowledge-virtuoso` | All knowledge reference skills (design patterns, refactoring, SOLID, debugging, clean architecture, testing, API design, security, scrum, performance, microservices, git workflow, CI/CD, accessibility, database design, verification-before-completion, dispatching-parallel-agents, subagent-driven-development) | 18 skills |
| `tools-virtuoso` | All interactive tool skills (agentic-rules-writer, ticket-writer, agent-creator, plugin-creator, brainstorming, using-virtuoso, pr-message-writer, report-writer, stakeholder-update-writer) | 9 skills |
| `frameworks-virtuoso` | All framework-specific skills (symfony-components, symfony-upgrade, django-components, langchain-components) | 4 skills |
| `playbooks-virtuoso` | All operational playbook skills (php-upgrade, composer-dependencies, finishing-branch, ticket-delivery, worktree-ops) | 5 skills |
| `agents-virtuoso` | All specialist and role agents plus all role skills | 15 agents + 7 role skills |

---

## Recommended Install Sets

### Starter (solo developer)

- `tools-virtuoso` -- interactive generators for daily work
- One framework bundle matching your stack (`frameworks-virtuoso` covers all three)

### Backend-focused team

- `knowledge-virtuoso` -- reference base
- `agents-virtuoso` -- full agent roster for delegation
- `playbooks-virtuoso` -- operational procedures including ticket delivery
- `frameworks-virtuoso` -- framework-specific references

### Frontend-focused team

- `knowledge-virtuoso` -- includes accessibility, performance, design patterns
- `tools-virtuoso` -- ticket writing, PR messages, brainstorming
- `agents-virtuoso` -- reviewer, test-gap-analyzer, frontend-dev role

### Platform / infrastructure team

- `knowledge-virtuoso` -- includes CI/CD, security, microservices
- `playbooks-virtuoso` -- dependency management, upgrades
- `agents-virtuoso` -- dependency-auditor, migration-planner

### Full install

```bash
npx skills add krzysztofsurdy/code-virtuoso --all
```

Installs all five bundles. Unused skills do not consume context until triggered.

---

## Versioning Policy

The top-level marketplace version in `metadata.version` follows semantic rules:

| Change | Bump |
|---|---|
| Content edits to existing skills | Patch |
| New skills or agents added | Minor |
| Renames, directory restructures, removals | Major |

---

## Install Commands

```bash
# Specific bundle
npx skills add krzysztofsurdy/code-virtuoso --plugin knowledge-virtuoso

# Everything
npx skills add krzysztofsurdy/code-virtuoso --all

# List available plugins without installing
npx skills add krzysztofsurdy/code-virtuoso --list
```

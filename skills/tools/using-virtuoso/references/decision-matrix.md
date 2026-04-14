# Decision Matrix

Situation-to-skill and situation-to-agent lookups. Use when you need to pick the right piece of the ecosystem for a specific moment.

## By Work Phase

| Phase | What you are doing | Use |
|---|---|---|
| Idea | The user has a vague request and no spec | `brainstorming` tool |
| Requirements | Need to write a PRD or acceptance criteria | `product-manager` role agent |
| Architecture | Choosing technology, drawing boundaries, writing ADRs | `architect` role agent + `clean-architecture` knowledge |
| Planning | Have requirements, need an ordered plan | `writing-plans` skill |
| Execution (independent tasks) | Tasks do not depend on each other | `dispatching-parallel-agents` |
| Execution (dependent tasks) | Tasks must run in order with review gates | `subagent-driven-development` + `executing-plans` |
| Implementation | Writing production code with tests | `implementer` agent or a `-dev` role agent |
| Review | Code ready for review | `reviewer` agent + `code-review-excellence` skill |
| Verification | About to claim done | `verification-before-completion` knowledge |
| Ticket delivery | Working through a ticket end-to-end | `ticket-delivery` playbook |
| Finishing | Ready to push and open PR | `finishing-branch` playbook |
| PR description | Writing the pull request message | `pr-message-writer` tool |
| Reporting | Generating a report for the work done | `report-writer` tool |
| Stakeholder comms | Updating stakeholders on progress | `stakeholder-update-writer` tool |
| Post-merge cleanup | Closing tickets, retrospective | `scrum-master` role + `scrum` knowledge |

## By Bug or Quality Task

| Task | Use |
|---|---|
| Debug a reproducible bug | `debugging` knowledge + `investigator` agent |
| Debug a flaky intermittent bug | `debugging` knowledge (flaky section) + `investigator` + observability |
| Find code smells | `refactor-scout` agent + `refactoring` knowledge |
| Apply a refactoring with TDD | `refactoring` + `solid` + `implementer` agent |
| Security review | `security` knowledge + `reviewer` agent |
| Accessibility audit | `accessibility` knowledge + manual audit |
| Performance investigation | `performance` knowledge + profiler data first |
| Test coverage audit | `test-gap-analyzer` agent |
| Dependency audit | `dependency-auditor` agent + `composer-dependencies` playbook |

## By Design Task

| Task | Use |
|---|---|
| Pick a design pattern | `design-patterns` knowledge |
| Pick an architecture style | `clean-architecture` + `microservices` knowledge |
| Design a REST endpoint | `api-design` knowledge + `architect` role |
| Design a GraphQL schema | `api-design` knowledge (GraphQL section) + `architect` role |
| Model a database schema | `database-design` knowledge |
| Plan a data migration | `database-migration` playbook + `migration-planner` agent |

## By Delivery / Process Task

| Task | Use |
|---|---|
| Sprint planning | `scrum` knowledge + `scrum-master` role |
| Write a sprint goal | `scrum` knowledge (sprint goal section) |
| Run a retrospective | `scrum-master` role |
| Write a ticket | `ticket-writer` tool |
| Write a PR message | `pr-message-writer` tool |
| Generate an HTML report | `report-writer` tool |
| Stakeholder update | `stakeholder-update-writer` tool + `project-manager` role |
| Work a ticket end-to-end | `ticket-delivery` playbook |
| Manage parallel worktrees | `worktree-ops` playbook |
| Risk register | `project-manager` role |

## By Framework or Upgrade Task

| Task | Use |
|---|---|
| Build something in Symfony | `symfony-components` |
| Upgrade a Symfony major | `symfony-upgrade` playbook |
| Build something in Django | `django-components` |
| Build a LangChain agent | `langchain-components` |
| Upgrade PHP itself | `php-upgrade` playbook |
| Update Composer dependencies | `composer-dependencies` playbook |

## By Ecosystem Authoring Task

| Task | Use |
|---|---|
| Create a new skill | `skill-creator` tool |
| Create a new agent definition | `agent-creator` tool |
| Package a plugin | `plugin-creator` tool |
| Write an agent rules file | `agentic-rules-writer` tool |
| Discover available skills | `find-skills` tool |
| Get oriented to the ecosystem | `using-virtuoso` (this skill) |

## Tie-Breaking

When two skills both look like they fit:

1. **Pick the narrower one.** `database-design` beats `api-design` for schema questions even if the schema is exposed via an API.
2. **Pick the one with matching triggers.** The frontmatter `description` contains trigger phrases — check which one matches the user's actual words.
3. **If one is a playbook and the other is knowledge, the playbook is for executing and the knowledge is for deciding.** Choose based on whether the user is deciding or doing.
4. **If still tied, pick the more recently updated skill** — newer content is usually more precise.

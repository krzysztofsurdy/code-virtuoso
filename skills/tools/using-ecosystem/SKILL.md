---
name: using-ecosystem
description: "Ecosystem discovery advisor. Use when the user asks 'what skill should I use', 'what agent should I delegate to', 'which team fits this task', or when onboarding to available skills, agents, and teams. Scans all installed skills at runtime, not limited to any single plugin or vendor. Triggers: 'which skill', 'which agent', 'what do I use for', 'orient me', 'what tools do I have'."
user-invocable: true
argument-hint: "[optional: situation or topic]"
---

# Using ecosystem

Discover the right skill, agent, or team for the situation at hand. This skill teaches a discovery process. It does not maintain a hardcoded inventory, and every recommendation comes from scanning what is installed.

## Core Principles

| Principle | Meaning |
|---|---|
| **Scan, don't guess** | Scan installed skills/agents/teams before every recommendation. Never assume something is available. |
| **Match situation, not topic** | Pick the skill whose description triggers match what the user is doing, not the skill whose title only loosely matches. |
| **Agents act, skills inform** | Skills are reference material. Agents are actors. Delegate work to an agent; consult a skill. |
| **Teams for multi-role work** | If the work needs 3+ agents coordinating, check for a pre-composed team before assembling ad-hoc. |
| **Narrower wins** | If two skills overlap, pick the one with the tighter trigger match. |
| **Chain when work crosses domains** | Multi-step tasks often need two or three agents in sequence. |

---

## Step 1: Scan what is installed

Run the discovery commands from [discovery-commands](references/discovery-commands.md) to build a live index of installed skills, agents, and teams. Read each frontmatter `name` and `description` field.

Do not skip this step and do not recommend from memory. The installed set varies per user and per project.

---

## Step 2: Classify the user's situation

Determine what the user needs:

| Signal | Category |
|---|---|
| Needs reference material, patterns, or principles | **Knowledge skill** |
| Needs to generate a specific output (ticket, PR message, report, rules file) | **Tool skill** |
| Needs to follow a step-by-step operational procedure | **Playbook skill** |
| Needs framework-specific component reference | **Framework skill** |
| Needs a single focused task done (investigate, review, implement) | **Specialist agent** |
| Needs ongoing domain ownership (requirements, architecture, QA) | **Role agent** |
| Needs coordinated multi-agent delivery (feature, release, review cycle) | **Team** |

---

## Step 3: Match and recommend

### Decision tree

```
User request
   |
   v
Does it need multiple agents coordinating?
   +-- Yes --> Scan bundled and project teams for a match
   |            +-- Found --> Recommend the team
   |            +-- None  --> Assemble ad-hoc from agents (see chaining below)
   |
   +-- No --> Is it a well-scoped actionable task?
               +-- Yes --> Scan agents/ for a matching specialist or role
               +-- No  --> Scan skills/ for a matching skill
                            Use the category signals from Step 2
```

### Matching rules

1. **Read the `description` field** of each candidate. Match on trigger phrases, not the name.
2. **Prefer the narrower skill.** `database-design` beats `clean-architecture` for a schema question.
3. **Check `user-invocable`.** If the user wants to run something interactively, only recommend user-invocable skills.
4. **Skills stack.** You can recommend multiple knowledge skills for one task (e.g., `security` + `solid` for a security review).
5. **Never recommend what is not installed.** If a skill would fit but is not present, suggest installing it with `npx skills add`.

---

## Step 4: Chain when needed

When a single skill or agent is not enough, chain them. Common patterns:

| Pattern | Shape |
|---|---|
| **Investigation flow** | Read-only agent --> Design agent --> Implementation agent --> Review agent |
| **Feature flow** | Requirements role --> Architecture role --> Dev roles (parallel) --> QA role |
| **Review flow** | Smell scanner --> Reviewer --> (optional) Implementer for fixes |
| **Coverage flow** | Test gap analyzer --> Implementer --> Reviewer |

These are guidelines. Skip steps that do not apply and add steps that do. If a pre-composed team matches the chain, use the team instead.

---

## Step 5: Compass (what next?)

When the user has just finished work with an agent, skill, or team and asks "what next?" or "where do I go from here?":

1. Ask what they just completed (which agent/skill/team, what output they have)
2. Consult [compass](references/compass.md) for the recommended next step
3. Verify the recommended agent/skill/team is installed (scan first, do not recommend from memory)
4. Present the recommendation with one-line reasoning
5. If multiple paths exist, present 2-3 options and let the user choose
6. If nothing chains naturally, say so. Not every task needs a follow-up

Compass mode is conversational. Ask the user, do not scan the filesystem to infer what happened.

---

## Ecosystem Structure

The ecosystem has five layers. The structure stays the same when skills are added.

| Layer | Location | Format | Purpose |
|---|---|---|---|
| **Skills** | `skills/{category}/{name}/SKILL.md` | Markdown + YAML frontmatter | Reference material, tools, playbooks, roles, frameworks |
| **Agents** | `agents/{name}.md` | Markdown + YAML frontmatter | Specialist and role sub-agents |
| **Teams** | Bundled inside dispatching skill or at project `teams/{name}.md` | Markdown + YAML frontmatter | Pre-composed agent teams with coordination protocols |
| **Specs** | `spec/*.md` | Markdown | Format specifications for skills, agents, teams, plugins |
| **Plugins** | `.claude-plugin/marketplace.json` | JSON | Distribution bundles grouping skills and agents |

### Skill categories

| Category | Path | Invocation |
|---|---|---|
| Knowledge | `skills/knowledge/` | Auto-loaded when relevant |
| Tools | `skills/tools/` | User-invocable slash commands |
| Playbooks | `skills/playbooks/` | User-invocable slash commands |
| Roles | `skills/roles/` | Auto-loaded by matching role agents |
| Frameworks | `skills/frameworks/{name}/` | Loaded when the framework is in play |

### Agent tiers

| Tier | Scope | Examples |
|---|---|---|
| Specialist | Single repeatable task (stateless) | investigator, reviewer, refactor-scout |
| Role | Domain of responsibility (some carry memory) | architect, backend-dev, qa-engineer |

### Team spawning modes

| Mode | When | How |
|---|---|---|
| Peer | Platform supports agent-to-agent messaging | Lead creates team, teammates claim tasks and message each other |
| Sequential | All other platforms | Lead dispatches one sub-agent per phase, passes outputs forward |

---

## Quality checklist

Before answering a "which skill/agent/team" question:

- [ ] Did I scan installed skills/agents/teams rather than recommending from memory?
- [ ] Did I match on the description's trigger phrases, not just the name?
- [ ] Did I consider whether a narrower, more specific skill exists?
- [ ] Did I recommend an agent when the work is actionable, not just reference material?
- [ ] Did I check for a pre-composed team when the work needs 3+ agents?
- [ ] Did I mention chaining when the work crosses domains?
- [ ] Did I avoid recommending something that is not installed?

---

## Critical rules

1. **Scan first.** Every recommendation starts with a live scan of what is installed. No hardcoded lists.
2. **Situation over title.** Match what the user is doing, not what the skill is called.
3. **Specialist for scoped tasks, role for domain work, team for multi-role delivery.**
4. **Chain over stretch.** If a single skill does not cover the work, combine two. Do not force one skill beyond its fit.
5. **Never recommend uninstalled skills as available.** Suggest installing with a hint, not as a next step.
6. **Respect agent boundaries.** Read-only agents do not edit files. Dev agents run in worktrees.
7. **Category is a signal.** Tools for interactive output, playbooks for procedures, knowledge for reference.

---

## Reference files

| Reference | Contents |
|---|---|
| [discovery-commands](references/discovery-commands.md) | Shell commands to scan installed skills, agents, and teams at runtime |
| [chaining-patterns](references/chaining-patterns.md) | Multi-agent chain templates with when-to-use guidance |
| [compass](references/compass.md) | "What next?" recommendation map for post-task navigation |

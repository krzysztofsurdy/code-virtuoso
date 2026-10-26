# Phase 2: Placement

**Progress: Phase 2 of 4**

## Purpose

Choose the name, location, invocation mode, and bundle before drafting.

## Steps

1. Name it: lowercase letters, digits, and single hyphens, 1-64 characters, matching the directory. Avoid names that collide with an installed skill (Anthropic's `skill-creator` is one).
2. Choose where it lives. In this library, pick the category:

   | Category | Use for |
   |---|---|
   | `knowledge` | Decision rules and pitfalls on concepts and practices |
   | `frameworks/<name>` | Version facts, opinions, and pitfalls for one framework |
   | `tools` | Interactive generators, setup utilities, headless wrappers |
   | `playbooks` | Step-by-step procedures for recurring work |
   | `ai` | Building with LLMs and agents |

   In another project, use that project's skills directory and skip library registration.
3. Choose the invocation mode. Never turn both off, or nothing can start the skill.

   | Mode | Frontmatter | Use when |
   |---|---|---|
   | Auto | `user-invocable: true` (or omit), no `disable-model-invocation` | The agent should pick it up from the description and the user can also run it |
   | Hidden background | `user-invocable: false` | Reference the agent should load itself and a person would never run |
   | Run by name | `disable-model-invocation: true` and `user-invocable: true` | Well-known material or side-effecting procedures that should start only on request |

   The description of a run-by-name skill still matters for the slash menu, but it stays out of the agent's context.
4. Choose the plugin bundle in `.claude-plugin/marketplace.json`: the `*-virtuoso` bundle that matches the category. Do not invent a new bundle for one skill.
5. Decide the structure: SKILL.md only, plus `references/`, or plus `phases/`. Use phases only when there are three or more steps that need user input and the agent tends to rush them.

## Gate

**Advances when:** name, location, invocation mode, bundle, and structure are confirmed.
**Returns to this phase when:** the name collides or the mode does not fit how people will use the skill.

Ask the user: "Proposed: `[name]` in `[path]`, mode `[mode]`, bundle `[bundle]`, structure `[structure]`. Confirm or change?"

Do not proceed to Phase 3 until the user confirms.

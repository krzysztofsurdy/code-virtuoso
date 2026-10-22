---
name: agentic-rules-writer
description: Writes or trims agent instruction files (AGENTS.md, CLAUDE.md, Cursor, Copilot, Codex and more). Use to set up agent rules, or when asked to trim my CLAUDE.md, shorten a rules file that is too long, or clean up AGENTS.md. Keeps only what the model cannot guess. Hard limits become hooks.
user-invocable: true
argument-hint: "[agent name e.g. claude, cursor, codex] or [trim <path>]"
---

# Agentic rules writer

A rules file is read on every turn. Filler such as "write clean code" costs tokens, buries the few lines that matter, and changes nothing, because the model already does it. Research on repository context files found that they did not generally raise task success and cost over 20% more to run, while specific instructions were followed well. This skill writes the short file: commands, conventions that differ from the defaults, the user's real preferences. It sends rules that must always hold to deny rules and hooks, where they are enforced instead of requested.

It has two modes. Pick one from the request, and ask only if it is unclear.

| Mode | Triggers | Does |
|---|---|---|
| Generate | "set up agent rules", "write CLAUDE.md", "create Cursor rules" | Infers from the repo, asks about eight things, writes a short file |
| Trim | "trim my CLAUDE.md", "my rules file is too long", "clean up AGENTS.md" | Audits an existing file, classifies each line, shows a diff, applies it after approval. See [trim-mode](references/trim-mode.md) |

Argument `trim <path>` starts trim mode on that file. Any other argument names the target tool.

## What a rules file may hold

Every line must prevent a mistake the agent would make without it.

| Keep | Example |
|---|---|
| Commands the agent cannot guess | `Test one file: pnpm test -- path/to/file.spec.ts` |
| Conventions that differ from defaults | `Money is integer cents, never floats`. `Do not edit generated/ (rebuilt by make gen)` |
| The user's real preferences | Commit and branch format, what to ask before doing, reply language |
| Environment quirks | `Tests need docker compose up db first` |
| Pointers, one line each | `Read docs/payments.md before touching src/payments/` |

## What not to write

Leave these out, and tell the user a line was dropped when they ask for one. The model follows them already, the repo shows them, or a tool enforces them.

| Do not write | Example lines |
|---|---|
| Generic engineering principles | `Write clean, maintainable code`. `Simplicity first`. `Root causes only`. `Minimal blast radius`. `Follow SOLID` |
| Habits the model already has | `Read before editing`. `Follow existing patterns`. `Prefer editing over creating files`. `Remove dead code`. `Minimal diffs` |
| Honesty and care slogans | `Don't guess`. `Prove it works`. `Ask when stuck`. `Handle edge cases`. `Validate inputs at boundaries` |
| Generic testing, security and quality lectures | `Write tests for everything`. `Follow OWASP`. `Sanitize all input`. `Maintain high code quality` |
| What the repo shows | Directory trees, stack lists, a README summary, dependency lists |
| What a formatter or linter enforces | Indentation, quote style, import order |
| Knowledge-source habits | `Prefer official docs over blog posts`. `Search the web when unsure` |
| Skill routing tables and agent rosters | `When X, use /skill`. A list of agents. Every description already reaches the model |
| Rules that must always hold, as prose | `Never force push to main`. `Never commit secrets`. `Never read .env`. These go to Phase 4 |

A persona or tone the user asks for is a preference, so it stays. Everything else in the table goes.

## Phase 1: target and scope

1. Resolve the target tool from the argument or ask. [agent-targets](references/agent-targets.md) lists paths per tool and the date each row was checked. The skill covers Claude Code, Codex, Cursor, Copilot, Windsurf (Devin Desktop), Antigravity, Gemini CLI, Cline, Roo Code, OpenCode, Continue, Trae, Amp, Goose, Augment and Kilo Code. For another tool ask for the path.
2. Run the runtime check in that file for the chosen tool before writing: confirm the paths, frontmatter and limits against the tool's current docs with `docs-lookup`, then `research` at quick depth for anything unclear. The table is a starting point. If a fact cannot be confirmed, say so and ask the user.
3. Ask the scope: global (all projects), project shared with the team, or personal in this project.

### One source of truth for project rules

Write project rules once, in `AGENTS.md` at the repository root. Never copy the rules into a second file.

| Situation | What to write |
|---|---|
| Only Claude Code is used | `AGENTS.md` and no `CLAUDE.md`. Claude Code 2.1.277 or later reads `AGENTS.md` when no `CLAUDE.md`, `.claude/CLAUDE.md` or `CLAUDE.local.md` exists in the working directory or above |
| Claude Code plus other tools | `AGENTS.md`, plus a thin `CLAUDE.md` whose first line is `@AGENTS.md`, with only Claude-specific lines below it |
| A `CLAUDE.md` with rules already exists | Move the shared rules into `AGENTS.md`, then cut `CLAUDE.md` to the import and Claude-only lines |
| Part of the repo needs its own rules | Keep `AGENTS.md` as the base. Add a path-scoped rule file or a nested file for that part only |

The `@AGENTS.md` import keeps one copy of the text, but the imported file still loads at launch, so it does not cut context cost. For global scope there is no shared file, so keep a short separate file per tool.

If the target file exists, ask: overwrite, merge (add new lines under the old ones, skipping duplicates), or abort. Offer trim mode when the existing file is long.

## Phase 2: infer from the repo

Read the repo before asking anything: lockfiles, manifests and scripts, CI config, formatter config, `git log` message style, branch names, the PR template, and existing rules files. The sources and what each one tells you are in [questionnaire](references/questionnaire.md). Never read `.env` files or credential stores.

Show every inferred value in one block and ask the user to confirm or correct it. Include only values that become output lines. Global scope has no repo, so skip this phase.

## Phase 3: interview

Ask the eight questions in [questionnaire](references/questionnaire.md), using the agent's interactive menu tool when it has one (up to four questions per call). Skip any question the confirmation block or the scope already settled. The questions cover: target and scope, commands the repo does not show, what differs from defaults, git format, ask-before rules, hard limits, and personal preferences.

If an answer is a line from the do-not-write table, say why it is left out. If it is a rule that must always hold, route it to Phase 4.

## Phase 4: guardrails

Rules that must hold every time are not prose. A rules file is a request the model may drop. A deny rule, sandbox setting or hook runs whether or not the model remembers.

1. Collect the "never" answers (Q7) and any ask-before rule the user wants enforced.
2. Map each one to a mechanism with the `hooks-and-guardrails` playbook when it is installed, or by its procedure inline:

   | Rule | Mechanism |
   |---|---|
   | Never read or edit secrets | Deny rules for `.env*`, key files and credential folders, plus a PreToolUse hook for shell access |
   | Never force-push, always ask before pushing | A deny rule on force-push forms and an `ask` rule on `git push` |
   | No `rm -rf` or other destructive commands | A deny rule on the command, with the sandbox for what a deny rule cannot see |
   | Do not finish while tests fail | A Stop hook that runs the project's test command |
   | Do not touch production, lockfiles or generated files | Deny rules on the paths or commands |

3. Show the proposed settings snippet and hook scripts, for the target tool, in one message. Say what each one blocks and what it cannot catch. Deny rules do not stop a script that opens a file itself.
4. Write them only after the user approves, into the project settings file, not a user-level file, unless the user asks for that. Install nothing silently. Test each one as the playbook describes.
5. In the rules file keep at most one line pointing at them, for example `Hard limits are enforced in .claude/settings.json (deny rules and hooks).` Write it only for guardrails that were installed. If the user declined them, write nothing, and do not move the rule back into prose.
6. If the target tool has no documented deny or hook mechanism, keep the rule as a single `Never:` line and tell the user it is a request, not enforcement. Run the runtime check to confirm the tool has none.

## Phase 5: skill names

The file must not copy skill or agent lists. At most it holds one generic line for global scope: `Before acting, check the available skills and invoke any whose description matches the task.` A rule about one named skill (for example "use /communication-style before writing PR comments") is written only when the user asks for it and the skill is installed.

Verify a name before writing it. Check the user-level and project-level skill directories for the chosen tool and the plugin cache. For Claude Code that means `~/.claude/skills/<name>/SKILL.md`, `.claude/skills/<name>/SKILL.md`, installed plugins under `~/.claude/plugins/cache`, and `~/.agents/skills` and `.agents/skills`. A name that resolves nowhere is left out, and the user is told. Do not write an agent roster. Add an agent rule only when the user states one.

Count the installed skills while scanning. If there are many (roughly over 50), tell the user that Claude Code caps the skill listing (1% of the context window, 1,536 characters per skill), drops descriptions of the least-used skills first, and that dropped skills show as bare names. Point to `/context`, `/skill-doctor`, and the "Skill listing overflow" section of the `context-engineering` skill for the fixes. Other tools cap differently.

## Phase 6: assemble and write

Use only the sections that have content. This is the whole shape of a file:

```markdown
# Project rules

## Commands
- [from the confirmed commands and Q3]

## Conventions
- [Q4, one line each, with a reason when it is not obvious]

## Git
- [Q5: commit, branch and PR format, attribution]

## Ask first
- [Q6: what the agent asks before doing]

## Preferences
- [Q8, global and personal files only]

Hard limits are enforced in [settings file] (deny rules and hooks).   <- only if installed
```

A section with nothing in it is omitted, so a small repo gets a file of ten or fifteen lines. There is no fixed template beyond this. Do not add principle blocks, a repository overview, or a knowledge-sources section.

Checks before writing:

1. Compare every line with the do-not-write table. Remove any that match.
2. Count lines. Keep the shared file under about 60 lines and any file under the tool's budget: Claude Code about 200 lines per file, Windsurf 6,000 characters global and 12,000 per rule file, Antigravity 24,000 bytes, Codex 32 KiB combined. If the content is over budget, cut, then move part-of-repo rules into path-scoped or nested files.
3. Apply tool formatting from [agent-targets](references/agent-targets.md): Cursor `.mdc` frontmatter, Windsurf and Antigravity `trigger` frontmatter, none for `AGENTS.md`.
4. For Claude Code with other tools in play, write `AGENTS.md` and the thin `CLAUDE.md`. Never duplicate the rules.
5. Create missing directories. For project scopes confirm the repo is a git repository. Tell the user to add personal files to `.gitignore`.

## Phase 7: confirm

1. Show the full content, the path, and the line and character count against the tool's budget. Say what was dropped from the request and why.
2. Show the guardrails still waiting for approval, if any.
3. Offer, without pressing, a `UserPromptSubmit` reminder hook, because rules loaded once at session start fade in long sessions. It re-injects two or three critical rules on every prompt. The `hooks-and-guardrails` playbook covers setup. Do not install it unless the user agrees.
4. Offer the `instruction-auditor` agent for a later audit, and ask whether to change anything.

## Error handling

- If the user aborts during the interview, write nothing.
- If a skill the user names is not installed, leave it out and say so.
- If a path or limit cannot be confirmed from current docs, say it is unverified and ask the user, instead of writing it.
- If a rule is unclear, ask. Do not invent wording.

## Reference files

| Reference | Contents |
|---|---|
| [agent-targets](references/agent-targets.md) | File paths, formats and limits per tool, each row dated, plus the runtime check to run before writing |
| [questionnaire](references/questionnaire.md) | What to infer from the repo, the confirmation block, the eight questions, the scope matrix, persona handling |
| [trim-mode](references/trim-mode.md) | Audit, line classes, proposal format and apply steps for trimming an existing file |

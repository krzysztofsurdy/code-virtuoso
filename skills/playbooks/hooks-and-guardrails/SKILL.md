---
name: hooks-and-guardrails
description: Adds guardrails to an AI coding agent setup, including deny rules for secrets, sandbox and permission choices, and hooks that block .env reads and gate 'done' on passing tests. Use when hardening an agent, adding hooks, or stopping secret reads.
user-invocable: true
argument-hint: "[claude-code | codex] [risk level: low | medium | high]"
---

# Hooks and guardrails

An instruction in a rules file is a request. A hook is code that runs whether or not the model remembers the request. Use rules to say what you want, deny rules and the sandbox to set hard limits, and hooks to catch what slips through and to give the agent fast feedback on its own work.

## Core principles

| Principle | Meaning |
|---|---|
| **Enforce, do not ask** | Anything that must never happen belongs in a deny rule or the sandbox, not in prose |
| **Layers fail differently** | Deny rules cover the agent's file tools, the sandbox covers shell processes, hooks cover custom logic. Use at least two for secrets |
| **Hooks are sensors** | A hook that returns the error to the agent turns a silent failure into a fix in the same turn |
| **Fast or off** | A hook that takes seconds on every edit gets disabled. Keep per-edit checks under a second or two |
| **Hooks run with your permissions** | A hook script is code the agent can trigger. Review it like any other script, and never let it run untrusted input through a shell |

## Procedure

1. **Pick a risk level.** Choose the row that matches the work, then set the permission mode and sandbox to match.

   | Risk | Typical work | Mode and isolation |
   |---|---|---|
   | Low | Own repo, no secrets nearby, no untrusted content | Accept-edits style mode plus deny rules |
   | Medium | Real project, credentials on the machine, reads issues or docs from the web | Default prompts or classifier mode, OS sandbox on, deny rules, hooks below |
   | High | Unknown repo, unattended runs, CI, or untrusted input plus network access | Container or VM with no secrets mounted, allowlisted network, pre-approved tools only, no bypass flags on the host |

   Bypass-everything flags belong only inside an isolated container or VM. See [deny-rules-and-modes](references/deny-rules-and-modes.md) for the settings per tool.

2. **Add deny rules** for secret files and risky commands. Deny rules win over allow rules and over a hook's allow. They do not stop a script that opens the file by itself, which is why step 3 and the sandbox exist.

3. **Pick hooks.** Add only the ones you need.

   | Goal | Event | Script | How it signals |
   |---|---|---|---|
   | Block reads and edits of secrets | PreToolUse | `scripts/block-secret-reads.sh` | exit 2 with reason on stderr |
   | Run a formatter, linter, or syntax check after edits | PostToolUse | `scripts/post-edit-check.sh` | exit 2 sends the error to the agent |
   | Do not finish while tests fail | Stop | `scripts/stop-gate.sh "<test cmd>"` | JSON `decision: block` |
   | Restore branch, status, and key rules after compaction | SessionStart, matcher `compact` | `scripts/reinject-context.sh` | JSON `additionalContext` |
   | Keep rules in view as a long session drifts from its start-of-session instructions | UserPromptSubmit | `scripts/prompt-reminder.sh` | JSON `additionalContext` |

   PreCompact can only block compaction or run side effects. It cannot add context, so re-inject through SessionStart.

   Use the prompt reminder when long sessions start ignoring rules the agent followed early on. It adds text to every message, so keep it to a sentence or two.

4. **Install.** Copy the scripts you chose to `.claude/hooks/` (Claude Code) or `.codex/hooks/` (Codex), make them executable, and register them. The exact config is in [claude-code-settings](references/claude-code-settings.md) and [codex-hooks](references/codex-hooks.md).

5. **Test before trusting.** Run `bash scripts/test-hooks.sh` to see the scripts pass on sample input. Then test your own config: ask the agent to read `.env`, to edit a file with a syntax error, and to finish with a failing test. Each should be blocked or corrected. A guardrail you never saw fire is a guess.

6. **Review changes to hooks and settings like code.** Hooks and `.claude/` or `.codex/` config live in the repo, so a pull request can change them. Require review on those paths, and turn hooks off with the tool's disable flag when you run an agent over a repo you did not write.

## Pitfalls

| Pitfall | Why it bites | Fix |
|---|---|---|
| Exit code 1 from a blocking hook | Only exit 2 blocks. Other non-zero codes are logged and the action continues | Use exit 2, or print the JSON decision with exit 0 |
| Stop hook that always blocks | The agent loops. Claude Code caps this at 8 continuations, but each costs a full turn | Gate on a real, repeatable check and skip when nothing changed |
| Matching secrets by tool name only | The agent can read a file through Bash, not just through Read | Check Bash commands too, and use the sandbox for real enforcement |
| Hook prints extra text before JSON | Stdout is parsed as JSON only if it is a single JSON object | Print only the JSON object, send logs to stderr |
| Relative script paths | The working directory can change during a session, and the docs advise absolute paths | Use `${CLAUDE_PROJECT_DIR}` or `git rev-parse --show-toplevel` |
| Imperative wording in injected context | Text that looks like a system command can trigger injection defenses | State facts: "This repo uses `make test`" |

## Checklist

- [ ] Risk level chosen and permission mode and sandbox set to match
- [ ] Deny rules cover `.env*`, key files, `~/.ssh`, `~/.aws`, and credential files
- [ ] Secret-read hook installed and seen to block `.env`
- [ ] Post-edit check installed and under two seconds on a typical file
- [ ] Stop gate installed with the project's real test command
- [ ] Context re-injection installed if sessions run long
- [ ] Prompt reminder installed if the agent forgets rules in long sessions, kept to a sentence or two
- [ ] `scripts/test-hooks.sh` passes
- [ ] Hook and settings paths require code review
- [ ] No hook or setting was installed into a user-level config without the owner agreeing

## Reference files

| Reference | Contents |
|---|---|
| [claude-code-settings](references/claude-code-settings.md) | Paste-ready `settings.json` with deny rules and four hooks, the prompt reminder entry, and event input and output details |
| [codex-hooks](references/codex-hooks.md) | The same guardrails in `hooks.json` and `config.toml` form, and where Codex differs |
| [deny-rules-and-modes](references/deny-rules-and-modes.md) | Permission modes, sandbox settings, and deny-rule limits for Claude Code and Codex |

Scripts live in `scripts/`: `block-secret-reads.sh`, `post-edit-check.sh`, `stop-gate.sh`, `reinject-context.sh`, `prompt-reminder.sh`, and `test-hooks.sh`. They need bash and jq.

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Defining what "done" evidence the Stop gate should demand | `verification-before-completion` |

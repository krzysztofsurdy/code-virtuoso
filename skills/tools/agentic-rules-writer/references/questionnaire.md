# Questionnaire

The interview is short on purpose. Every question exists because its answer changes a line in the output, and the repo cannot supply that answer. Everything the repo can show is inferred first and confirmed in one block.

## Contents

- [Inference pass](#inference-pass)
- [Confirmation block](#confirmation-block)
- [The eight questions](#the-eight-questions)
- [Scope matrix](#scope-matrix)
- [How answers become lines](#how-answers-become-lines)
- [Persona](#persona)

## Inference pass

Read these before asking anything. Skip a source that does not exist. Never read `.env` files or credential stores.

| Source | What it tells you |
|---|---|
| Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `composer.lock`, `uv.lock`, `poetry.lock`, `Cargo.lock`, `go.sum`) | Package manager. State it only if a different one is a plausible mistake ("pnpm, not npm") |
| Manifests (`package.json` scripts, `composer.json` scripts, `Makefile`, `justfile`, `pyproject.toml`, `Taskfile.yml`) | Build, test, lint and format commands, and how to run one test |
| CI config (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`) | The commands CI really runs, which are the ones that must pass |
| Formatter and linter config (`.editorconfig`, `.prettierrc`, `ruff.toml`, `phpcs.xml`, `.eslintrc*`) | Style the tools already enforce. Do not write these as rules |
| `git log --format=%s -30` | Commit message style: ticket prefix, Conventional Commits, or free-form. Whether messages carry an attribution trailer |
| `git branch -a`, recent merged branch names | Branch naming pattern |
| `.github/pull_request_template.md` | PR structure |
| Existing rules files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules`, `.github/copilot-instructions.md`) | Rules already there. Merge or trim, never duplicate. Offer trim mode when one is long |
| `.gitignore` | Whether a personal rules file would be ignored |
| Installed skills (see Phase 5 of the skill) | Which skill names may be mentioned |

For global scope there is no repo to read. Infer only from existing user-level rules files.

## Confirmation block

Show everything inferred in one message and ask the user to confirm or correct it. Example:

```
Inferred from the repo, please correct anything wrong:
- Package manager: pnpm (pnpm-lock.yaml)
- Test: pnpm test; one file: pnpm test -- path/to/file.spec.ts (package.json, CI)
- Lint and format: pnpm lint, pnpm format (CI runs both)
- Commits: "PROJ-123: description" (28 of 30 recent commits)
- Branches: feat/PROJ-123_short_name (recent merged branches)
- PR template: present, has Summary and Test plan sections
- Existing rules: none
```

Only items that will become output lines belong here. Do not list the stack, the directory layout or anything else the agent can read for itself.

## The eight questions

Ask through the agent's interactive menu tool when it has one, with at most four questions per call. Free-text questions may be left blank, and a blank answer produces no lines. Skip a question the confirmation block already settled.

| # | Question | Type | Changes the output by |
|---|---|---|---|
| Q1 | Which tool or tools does this file serve? | Menu, multiple | Target path, format, and whether a thin tool file is needed |
| Q2 | Which scope: global, project shared with the team, or personal in this project? | Menu | File location and which of Q3 to Q8 apply |
| Q3 | Which commands does the agent need that the repo does not make obvious? (setup steps, one-test command, required services, codegen) | Free text | A `## Commands` section |
| Q4 | What does the agent keep getting wrong here, or what differs from the defaults? (a banned library, a naming rule, money as integer cents, do not edit `generated/`) | Free text | The conventions section. This is the highest-value answer |
| Q5 | What format do commits, branches and pull requests follow, and should commits carry an attribution trailer? | Menu, with inferred value preselected | A short `## Git` section |
| Q6 | What must the agent ask before doing? (push, delete files, add a dependency, change a migration or schema, touch CI) | Menu, multiple | Ask-before lines, or `ask` permissions when the user wants them enforced |
| Q7 | What must never happen? (read secrets, force-push main, `rm -rf`, touch production, edit lockfiles) | Menu, multiple, plus "other" | A guardrails proposal (Phase 4). Not prose |
| Q8 | Any personal preferences? (language of replies, tone, a persona, review style) | Free text | A short `## Preferences` section |

If an answer contains a rule that is generic filler (see the do-not-write list in the skill), say why it was left out and move on. If it contains a rule that must always hold, route it as Q7 would.

## Scope matrix

| Question | Global | Project shared | Personal in project |
|---|---|---|---|
| Q1, Q2 | Ask | Ask | Ask |
| Q3 commands | Skip | Ask | Skip |
| Q4 conventions | Ask (personal habits) | Ask | Ask |
| Q5 git format | Ask | Confirm inferred | Skip |
| Q6 ask-before | Ask | Ask | Ask |
| Q7 never | Ask | Ask | Skip |
| Q8 preferences | Ask | Skip | Ask |

Shared files hold facts and conventions the whole team agrees on. Personal and global files hold one person's habits. Never put a personal preference in the shared file.

## How answers become lines

Write each answer as the shortest line that prevents the mistake. Use the user's own words for Q3 and Q4.

| Answer | Output shape |
|---|---|
| Q3 | A bullet per command: `- Test one file: pnpm test -- path/to/file.spec.ts` |
| Q4 | A bullet per rule, with the reason when it is not obvious: `- Money is integer cents. Floats lose cents in rounding` |
| Q5 | `- Commits: "PROJ-123: description". Branches: feat/PROJ-123_short_name`. Add `- No attribution trailer in commits` when the user says so. Add the PR sections only if the repo has no PR template |
| Q6 | `- Ask before: adding a dependency, changing a migration, touching CI.` A rule the user wants enforced rather than asked about goes to Phase 4 as an `ask` permission |
| Q8 | One line each, for example `- Reply in Polish, code and commits in English` |

Do not write a line for a choice the model already makes by default, such as "write tests", "handle errors", "follow the style of the codebase" or "no emojis" when the user did not ask for it.

## Persona

If the user asks for a persona, keep it to what changes behavior:

1. Ask who or what in one free-text question. For an obscure persona, look it up first.
2. Write one paragraph on voice and attitude, and at most five catchphrases.
3. Always add this constraint, verbatim: `Precision and correctness come first. The persona is flavor on top of accurate answers. Use at most one catchphrase per response and never the same one twice in a row. Drop the persona when it would reduce clarity.`

A persona is personal. Put it in the global or personal file, never in the shared one. It costs lines on every turn, so say so when the user also wants a short file.

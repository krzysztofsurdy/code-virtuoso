# Skill checklist

Run before calling the skill done. Items marked for this library apply only when the skill ships here.

## Facts

- [ ] Research notes exist, or "research skipped at user request" is recorded in the notes and the PR
- [ ] Every checkable claim in the skill has a ledger row, or was cut or marked (unverified)
- [ ] Every command and snippet was run and the output matches
- [ ] Every external link was opened and is the page the skill says it is
- [ ] Volatile facts are pointers to official pages, not copied numbers
- [ ] No dates, "latest", or "as of" wording in the skill text

## Purpose

- [ ] The baseline showed the agent getting something wrong without the skill
- [ ] No existing skill in this repo or installed set covers the same need
- [ ] Each section traces to a baseline gap or a ledger fact
- [ ] Nothing the model already knows

## Frontmatter and structure

- [ ] `name` matches the directory, lowercase with single hyphens
- [ ] `description` is third person, leads with what a person types, says what and when, and is under 1024 characters (aim for 300)
- [ ] `user-invocable` is set, and `user-invocable` and model invocation are not both off
- [ ] No `model` field
- [ ] SKILL.md is under 500 lines
- [ ] References are one level deep, linked from SKILL.md, one topic each
- [ ] Files over 100 lines start with a `## Contents` list
- [ ] Reference files have no frontmatter
- [ ] Content is agent-agnostic, with product specifics only in a sourced Platform Notes table

## Style

- [ ] No em or en dashes, and no double hyphen used as a pause
- [ ] Sentence-case headings
- [ ] No filler or hype wording
- [ ] No consecutive blank lines, one trailing newline

## Triggers

- [ ] Two fires cases and one near-miss case in `evals/cases/triggers/`
- [ ] Prompts never name the skill or quote its description
- [ ] `evals/run.sh check` passes
- [ ] Description tuning was handed to Anthropic's skill-creator when available

## Registration (this library)

- [ ] Path added to the right `*-virtuoso` plugin in `.claude-plugin/marketplace.json`, version bumped
- [ ] README tables and structure updated
- [ ] `python3 scripts/validate-skills.py` and `python3 scripts/validate-markdown.py` pass

# CI examples

Workflow files that run the read-only agents in GitHub Actions. They are examples, not active workflows: nothing here runs in this repository. Copy the ones you want into your own repository.

| File | Runs | Trigger | Output |
|---|---|---|---|
| [claude-review.yml](claude-review.yml) | `review-pr` and `review-pr-cold` with Claude Code | pull request | JSON reports as artifacts, check fails on a CRITICAL finding |
| [codex-review.yml](codex-review.yml) | The reviewer agent with Codex, answer shaped by `--output-schema` | pull request | JSON report, check fails on a CRITICAL finding |
| [scheduled-audit.yml](scheduled-audit.yml) | `audit-dependencies` and `scan-refactors` with Claude Code | weekly, or by hand | One issue with the top findings, full JSON as artifacts |
| [evals.yml](evals.yml) | The plugin eval suites from [evals/](../../evals/README.md) | pull request touching skills or the marketplace | Eval report as an artifact, fails below the score threshold |

## How to copy them

1. Copy the file into `.github/workflows/` of your repository.
2. Add the secret it names: `ANTHROPIC_API_KEY` for the Claude workflows, `OPENAI_API_KEY` for Codex. Install the [Claude GitHub App](https://github.com/apps/claude) for the Claude workflows.
3. Read the comments at the top of the file, then adjust the lines that depend on your project: the matrix of skills, `--allowedTools`, `--max-budget-usd`, and the toolchain setup in the scheduled audit.
4. The third-party actions are pinned to commit SHAs, with the release tag in a comment. Update them with your usual tooling (Dependabot, Renovate), and pin the `ref:` of the Code Virtuoso checkout in `codex-review.yml` to a release tag or commit SHA before relying on it.

## Security choices

- The review workflows use `pull_request`, never `pull_request_target`. Fork PRs run without secrets, so the examples skip them instead of failing.
- `actions/checkout` runs with `persist-credentials: false`, so the workflow token is not left in `.git/config` for the agent to read. No step pushes.
- Each job declares its own `permissions:` and the workflow default is none. The review jobs get read access only. The scheduled report job is the only one that can write, and it only writes issues.
- `--allowedTools` lists the exact commands each skill needs (`git diff`, `npm audit`, and so on). The agents cannot run anything else without a prompt, and a headless run has nobody to answer one.
- `--max-turns`, `--max-budget-usd`, and `timeout-minutes` cap cost and run time.
- The PR title, body, and code are untrusted input. The wrapper skills tell the agent to treat them as data, and the agents are read-only. The examples still print model output behind `::stop-commands::` so it cannot inject workflow commands into the log.

## Running agents headless

This section is written to be pasted into AGENTS.md.

Every read-only agent can run without a person at the keyboard, in CI or from a script. Seven wrapper skills in `skills/tools/` run an agent as a forked subagent and make it answer in JSON. They ship in the `agents-virtuoso` plugin, so a CI job installs one plugin to get both the agents and the wrappers.

| Skill | Agent | Argument | JSON schema |
|---|---|---|---|
| `review-pr` | `reviewer` | base ref or PR number | `skills/tools/review-pr/references/output.schema.json` |
| `review-pr-cold` | `cold-reviewer` | base ref or PR number | `skills/tools/review-pr-cold/references/output.schema.json` |
| `verify-acceptance` | `acceptance-verifier` | spec file or PR number, then base ref | `skills/tools/verify-acceptance/references/output.schema.json` |
| `find-test-gaps` | `test-gap-analyzer` | base ref or directory | `skills/tools/find-test-gaps/references/output.schema.json` |
| `plan-migration` | `migration-planner` | base ref or migration path | `skills/tools/plan-migration/references/output.schema.json` |
| `audit-dependencies` | `dependency-auditor` | project directory | `skills/tools/audit-dependencies/references/output.schema.json` |
| `scan-refactors` | `refactor-scout` | directory or base ref | `skills/tools/scan-refactors/references/output.schema.json` |

### Claude Code

Install the plugin once with `claude plugin marketplace add krzysztofsurdy/code-virtuoso` and `claude plugin install agents-virtuoso@code-virtuoso`. Installed agents and skills carry the plugin name as a prefix: `agents-virtuoso:reviewer`, `/agents-virtuoso:review-pr`.

Run a wrapper skill. The session result is the agent's final message, which is the JSON report:

```bash
claude -p "/agents-virtuoso:review-pr origin/main" \
  --allowedTools "Read,Grep,Glob,Bash(git diff:*),Bash(git log:*)" \
  --max-turns 30 --output-format json | jq -r .result
```

Run a session as an agent, with your own prompt:

```bash
claude -p --agent agents-virtuoso:reviewer \
  --allowedTools "Read,Grep,Glob,Bash(git diff:*)" \
  "Review git diff origin/main...HEAD"
```

Notes:

- Use the prefixed name. In a skill's `agent:` field a name without the prefix, or a misspelled one, does not fail: Claude Code falls back to `general-purpose` and the run loses the agent's instructions and tool limits. `--agent` does fail on an unknown name and lists the available ones.
- A headless run cannot answer a permission prompt. Allow the commands the skill needs with `--allowedTools`, or the command is denied. A skill given a PR number also needs `Bash(gh pr diff:*)` and `Bash(gh pr view:*)`.
- In GitHub Actions, use [anthropics/claude-code-action](https://github.com/anthropics/claude-code-action) as in [claude-review.yml](claude-review.yml): `plugin_marketplaces`, `plugins`, `prompt: /agents-virtuoso:review-pr origin/main`, and `claude_args` for the flags above.

### Codex

Codex does not load Claude Code plugins or `agents/*.md`. Build the prompt from the agent file and pass the schema, then read the answer from the last message:

```bash
awk '/^---$/ && n < 2 { n++; next } n >= 2' agents/reviewer.md > prompt.md
echo 'Review `git diff origin/main...HEAD`. Answer with the JSON report only.' >> prompt.md
jq 'del(."$schema")' skills/tools/review-pr/references/output.schema.json > schema.json
codex exec --sandbox read-only --output-schema schema.json -o report.json - < prompt.md
```

`codex exec` runs in a read-only sandbox by default, so the agent cannot change files. Drop `$schema` from the schema to stay inside the subset of JSON Schema that strict structured output accepts. In GitHub Actions, use [openai/codex-action](https://github.com/openai/codex-action) as in [codex-review.yml](codex-review.yml).

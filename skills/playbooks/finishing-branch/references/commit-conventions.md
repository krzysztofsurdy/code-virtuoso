# Commit conventions

Commit messages have three readers: the reviewer of the PR, the developer running `git log` next month, and tools that build changelogs and version bumps. Follow the project's existing convention first. Check `git log --oneline -20` and any commitlint or hook config before choosing a format.

## Contents

- [Pick the convention the project already uses](#pick-the-convention-the-project-already-uses)
- [Conventional Commits](#conventional-commits)
- [Ticket prefixes](#ticket-prefixes)
- [Breaking changes](#breaking-changes)
- [Version impact](#version-impact)
- [Message quality](#message-quality)
- [Enforcing the format](#enforcing-the-format)

## Pick the convention the project already uses

| History looks like | Use |
|---|---|
| `feat(auth): add 2FA` | Conventional Commits |
| `PROJ-123: add 2FA` | Ticket prefix |
| `PROJ-123 feat(auth): add 2FA` or `feat(auth): add 2FA (PROJ-123)` | Both, in the order the history shows |
| No pattern | Conventional Commits, plus the ticket ID in the footer or branch name |

Do not introduce a new format into a repo that has one. A mixed history is worse than a plain one.

## Conventional Commits

```
<type>(<scope>): <description>

[body]

[footer]
```

| Type | Use for |
|---|---|
| `feat` | New behavior visible to users |
| `fix` | Bug fix |
| `refactor` | Restructuring with no behavior change |
| `perf` | Performance improvement |
| `test` | Tests only |
| `docs` | Documentation only |
| `build`, `ci`, `chore` | Build system, pipelines, dependencies, tooling |
| `style` | Formatting only, no logic change |
| `revert` | Reverting an earlier commit |

Rules:

- The description is imperative ("add", not "added"), lowercase, no trailing period.
- The scope is optional. Pick one scheme per project (module, layer, or package) and keep to it.
- The body explains why. The diff already shows what.
- Footers carry `BREAKING CHANGE:`, issue references, and `Reviewed-by:` style metadata.

## Ticket prefixes

When the team ties commits to a tracker, put the ticket key first and keep the rest short:

```
PROJ-123: add email verification token expiry
```

- Take the key from the branch name (`feat/PROJ-123_email_verification`) so it is never guessed.
- If no ticket exists, ask for one or omit the prefix. Never invent a key.
- On squash merge, the PR title becomes the commit on the target branch, so give the PR title the same prefix.

## Breaking changes

Mark them with `!` after the type, a `BREAKING CHANGE:` footer, or both. Use the footer when readers need migration steps.

```
feat(api)!: remove /v1/users

BREAKING CHANGE: use /v2/users. Pagination is now cursor-based.
```

## Version impact

| Commit | Bump |
|---|---|
| `fix`, `perf` | Patch |
| `feat` | Minor |
| `!` or `BREAKING CHANGE` | Major |
| everything else | None |

This only matters when release tooling reads the history. Without it, the types are still useful labels, but do not argue over which one a commit is.

## Message quality

- Keep the subject under 72 characters (50 is better).
- Be specific: "fix null user in session serializer", not "fix bug".
- One logical change per commit, so each can be reverted alone.
- Clean up before opening the PR: squash fixups with `git rebase -i`, and reword vague messages. Do this only on commits you have not shared.
- No `WIP`, `fix stuff`, or `address review comments` in history that will be kept. If the PR will be squash merged, these are harmless but still clean them up in the squash message.

## Enforcing the format

A `commit-msg` hook rejects bad messages before they land. Track hooks in the repo so the team shares them:

```bash
git config core.hooksPath .githooks
```

```bash
#!/usr/bin/env bash
# .githooks/commit-msg
pattern='^(feat|fix|refactor|perf|test|docs|build|ci|chore|style|revert)(\([a-z0-9-]+\))?!?: .{1,72}$'
head -1 "$1" | grep -qE "$pattern" || {
  echo "Expected: <type>(<scope>): <description>" >&2
  exit 1
}
```

Adjust the pattern if the project uses ticket prefixes. Prefer the project's existing tool (commitlint, lefthook, pre-commit) over a hand-written hook.

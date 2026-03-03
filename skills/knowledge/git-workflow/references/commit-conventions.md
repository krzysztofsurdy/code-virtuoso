# Commit Conventions

## The Conventional Commits Format

Conventional commits follow a structured format that makes commit history readable by both humans and machines. The format enables automated version bumping, changelog generation, and semantic release pipelines.

### Full Format

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Rules

- **type** -- Required. Describes the category of change (see types below)
- **scope** -- Optional. A noun identifying the section of the codebase affected, wrapped in parentheses
- **description** -- Required. A short summary in imperative mood ("add" not "added"), lowercase, no period at the end
- **body** -- Optional. Provides additional context. Separated from the description by a blank line
- **footer** -- Optional. Contains metadata like `BREAKING CHANGE:`, `Reviewed-by:`, or issue references

---

## Commit Types

| Type | When to Use | Example |
|---|---|---|
| `feat` | A new feature visible to end users | `feat(cart): add quantity selector to cart items` |
| `fix` | A bug fix | `fix(auth): prevent session expiry on active users` |
| `refactor` | Code restructuring without behavior change | `refactor(order): extract pricing logic to dedicated service` |
| `perf` | A change that improves performance | `perf(search): add database index for full-text queries` |
| `test` | Adding or correcting tests | `test(payment): add edge cases for currency conversion` |
| `docs` | Documentation changes only | `docs(api): update authentication endpoint examples` |
| `chore` | Maintenance tasks, dependency updates | `chore(deps): update symfony/http-kernel to 7.2` |
| `ci` | Changes to CI configuration or scripts | `ci: add PHP 8.4 to test matrix` |
| `build` | Changes to build system or tooling | `build: switch from webpack to vite` |
| `style` | Formatting, whitespace, semicolons (no logic change) | `style: apply PSR-12 formatting to src/` |
| `revert` | Reverts a previous commit | `revert: feat(cart): add quantity selector` |

---

## Scope Naming Patterns

Scopes should be consistent across a project. Common approaches:

### By Module or Domain

```
feat(auth): add two-factor authentication
fix(billing): correct proration calculation
refactor(notification): consolidate email templates
```

### By Layer

```
feat(api): add pagination to /users endpoint
fix(db): handle connection timeout gracefully
perf(cache): reduce Redis round-trips for session data
```

### By Package (Monorepos)

```
feat(web-app): add dark mode toggle
fix(shared-utils): handle null in date formatter
chore(cli): bump minimum Node version to 20
```

Pick one approach and document it. Mixing scope strategies in a single project makes the history harder to read.

---

## Breaking Changes

Two equivalent ways to signal a breaking change:

### Exclamation Mark After Type

```
feat(api)!: rename /users/list to /users

The /users/list endpoint has been removed. Clients should use GET /users with
pagination parameters instead.
```

### BREAKING CHANGE Footer

```
refactor(config): switch from YAML to TOML configuration

BREAKING CHANGE: Configuration files must be migrated from config.yaml to
config.toml. Run `bin/migrate-config` to convert automatically.
```

Both approaches trigger a major version bump in automated release pipelines. Use the footer form when you want to include detailed migration instructions.

---

## Semantic Versioning Alignment

Conventional commits map directly to semantic version increments:

| Commit Pattern | Version Bump | Before -> After |
|---|---|---|
| `fix(scope): ...` | Patch | 2.3.1 -> 2.3.2 |
| `perf(scope): ...` | Patch | 2.3.1 -> 2.3.2 |
| `feat(scope): ...` | Minor | 2.3.1 -> 2.4.0 |
| `feat!:` or `BREAKING CHANGE` | Major | 2.3.1 -> 3.0.0 |
| `refactor`, `test`, `docs`, `chore`, `ci`, `build`, `style` | None (no release) | 2.3.1 -> 2.3.1 |

### Pre-release Versions

For pre-release builds, append identifiers to the version:

```
v2.0.0-alpha.1    # Early development, unstable
v2.0.0-beta.1     # Feature-complete, testing phase
v2.0.0-rc.1       # Release candidate, final validation
v2.0.0            # Stable release
```

---

## Automated Changelog Generation

When commits follow conventional format, changelogs can be generated automatically by parsing `git log` output.

### Typical Generated Changelog Structure

```markdown
## [2.4.0] - 2026-03-06

### Features
- **cart**: add quantity selector to cart items (a1b2c3d)
- **search**: add fuzzy matching for product names (d4e5f6g)

### Bug Fixes
- **auth**: prevent session expiry on active users (h7i8j9k)
- **billing**: correct proration calculation for annual plans (l0m1n2o)

### Performance
- **search**: add database index for full-text queries (p3q4r5s)
```

### Release Automation Pipeline

A typical automated release flow:

1. **Analyze** -- Scan commits since the last tag, categorize by type
2. **Determine version** -- Calculate the next version based on commit types present
3. **Generate changelog** -- Build release notes from commit messages
4. **Tag** -- Create an annotated git tag with the new version
5. **Publish** -- Build artifacts, push to registries, create platform release

```bash
# Example: manual changelog generation from conventional commits
git log v2.3.1..HEAD --pretty=format:"%s" | grep "^feat" | sed 's/^/- /'
```

---

## Git Hooks for Commit Validation

Git hooks can enforce commit message format at the point of creation, preventing non-conforming messages from entering the repository.

### commit-msg Hook

The `commit-msg` hook runs after the developer writes a commit message but before the commit is finalized. It receives the path to the temporary file containing the message.

```bash
#!/usr/bin/env bash
# .git/hooks/commit-msg
# Validates commit messages against conventional commits format

commit_msg=$(cat "$1")
pattern="^(feat|fix|refactor|perf|test|docs|chore|ci|build|style|revert)(\([a-z0-9-]+\))?(!)?: .{1,100}$"

# Check first line against pattern
first_line=$(head -1 "$1")
if ! echo "$first_line" | grep -qE "$pattern"; then
    echo "ERROR: Commit message does not follow conventional commits format."
    echo ""
    echo "Expected: <type>(<scope>): <description>"
    echo "Example:  feat(auth): add two-factor authentication"
    echo ""
    echo "Valid types: feat, fix, refactor, perf, test, docs, chore, ci, build, style, revert"
    exit 1
fi
```

```bash
# Make the hook executable
chmod +x .git/hooks/commit-msg
```

### Sharing Hooks Across the Team

Git hooks live in `.git/hooks/` by default, which is not tracked by version control. To share them, store hooks in a tracked directory (e.g., `.githooks/`) and configure git to use it:

```bash
git config core.hooksPath .githooks
```

---

## Writing Good Commit Messages

- Use imperative mood: "add feature" not "added feature"
- Keep the description under 72 characters (ideally under 50), no trailing period
- Be specific: "fix null pointer in user serializer" not "fix bug"
- In the body, explain **why** the change was made -- reviewers can see the "what" in the diff
- Avoid vague messages like `fix stuff` or `WIP` in the final history
- Use `git rebase -i main` to squash fixup commits and reword messages before merging

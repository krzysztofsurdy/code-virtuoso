# PR Message Template

A pull request message has three audiences: the reviewer who needs to understand the change now, the developer who will read `git log` in six months, and the automation that parses titles for changelogs and release notes. Write for all three.

## Contents

- [Template](#template)
- [Writing guidance](#writing-guidance)
- [Sizing the message to the change](#sizing-the-message-to-the-change)
- [Cross-reference: pr-message-writer skill](#cross-reference-pr-message-writer-skill)
- [Platform-specific notes](#platform-specific-notes)

## Template

```markdown
## Summary

[1-3 sentences: what changed and why. Link to the ticket if one exists.]

Closes #TICKET-ID

## Changes

- [Specific change 1]
- [Specific change 2]
- [Specific change 3]

## Test Plan

- [ ] [How to verify change 1]
- [ ] [How to verify change 2]
- [ ] [Automated tests added/updated: describe what they cover]

## Risks

- [What could go wrong]
- [Migration considerations]
- [Rollback plan if applicable]

## Rollout

- [Deployment steps if any]
- [Feature flag details if applicable]
- [Monitoring to watch after deploy]

## Screenshots / Recordings

[For UI changes: before/after screenshots or screen recordings]
```

---

## Writing guidance

### Title

- Keep it under 72 characters
- Use the conventional commit format when the project uses it: `type(scope): description`
- Use imperative mood: "Add email verification" not "Added email verification"
- Include the ticket number if the project convention requires it

**Good titles:**

```
feat(auth): add email verification flow
fix(api): prevent timeout on large file uploads
refactor(billing): extract payment gateway interface
chore(deps): update Symfony to 7.4
```

**Bad titles:**

```
Updates
Fix bug
WIP: stuff
JIRA-123
```

### Summary section

- State **what** changed and **why** in plain language
- Link to the ticket or issue so reviewers do not have to search for context
- If there is no ticket, explain the motivation directly
- One to three sentences at most

### Changes section

- List concrete, specific changes, not vague descriptions
- Group related changes together
- Call out anything surprising or non-obvious
- If the PR is part of a stack, explain where it sits in the sequence

**Good:**

```markdown
- Add `EmailVerificationService` with token generation and validation
- Add `/api/verify-email` endpoint accepting GET with token parameter
- Add database migration for `email_verification_tokens` table
- Update `UserRegistrationHandler` to send verification email on signup
```

**Bad:**

```markdown
- Made some changes
- Updated files
- Fixed things
```

### Test plan section

- Describe how a reviewer can verify the change works
- Include both manual verification steps and automated test descriptions
- Be specific enough that someone unfamiliar with the feature can follow the steps
- Mark items as checkboxes so reviewers can check them off

### Risks section

- Be honest about what could break
- Mention backward compatibility concerns
- Note if the change requires a specific deployment order
- Describe the rollback plan if the change causes issues in production
- If there are no meaningful risks, say "Low risk - backward-compatible change with no migration" rather than omitting the section

### Rollout section

- Include it only when the change requires deployment coordination
- Mention feature flags, environment variables, or configuration changes
- Note any monitoring dashboards or alerts to watch after deployment
- Omit it for simple changes that deploy normally

---

## Sizing the message to the change

Not every PR needs every section. Scale the message to the complexity of the change.

| PR complexity | Required sections | Optional sections |
|---|---|---|
| Trivial (typo, config tweak) | Summary only | - |
| Small (single concern, < 100 lines) | Summary, Changes | Test Plan |
| Medium (feature or fix, 100-400 lines) | Summary, Changes, Test Plan | Risks |
| Large (multi-component, 400+ lines) | All sections | Screenshots if UI |
| Breaking change or migration | All sections including Risks and Rollout | - |

---

## Cross-reference: pr-message-writer skill

For interactive PR message generation, use the `pr-message-writer` skill. It provides:

- Structured templates with dynamic sections based on change type
- Automated diff analysis to suggest content
- Verification queries to check completeness
- Customizable templates for different project conventions

This reference provides the template and guidelines. The `pr-message-writer` skill provides the interactive workflow for generating the actual message from your branch's diff and commit history.

---

## Platform-specific notes

### GitHub

GitHub uses the first line of the squash-merge message as the commit title. If your team uses squash-and-merge, make the PR title follow your commit conventions.

Keywords in the PR body close issues: `Closes #123`, `Fixes #456`, `Resolves #789`.

### GitLab

GitLab supports closing patterns: `Closes #123` or `Fixes #123` in the MR description.

GitLab MR templates can be stored in `.gitlab/merge_request_templates/` for team-wide consistency.

### Bitbucket

Bitbucket uses `Closes #123` or links to Jira tickets via smart commits: `PROJ-123 #close`.

PR templates are configured in repository settings or via `PULL_REQUEST_TEMPLATE.md` in the repository root.

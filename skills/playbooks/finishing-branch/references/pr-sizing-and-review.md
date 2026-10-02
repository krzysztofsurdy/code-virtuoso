# PR sizing and review etiquette

Review quality falls as the diff grows. A small PR gets read; a large one gets skimmed or approved on trust. Size the PR before you open it, because splitting afterwards is expensive.

## Contents

- [Size targets](#size-targets)
- [Keeping a PR small](#keeping-a-pr-small)
- [Author etiquette](#author-etiquette)
- [Reviewer etiquette](#reviewer-etiquette)
- [Review gates](#review-gates)

## Size targets

| Lines changed | What to expect | Action |
|---|---|---|
| Under 50 | Reviewer catches most issues | Ideal, especially for stack layers |
| 50 to 200 | Easy to review | Default target |
| 200 to 400 | Needs focused time | Upper bound for one PR |
| Over 400 | Fatigue, defects slip through | Split, or explain in the description why it cannot be |

Count meaningful lines. Generated files, lockfiles, and snapshots inflate the number without adding review load, so call them out in the description.

## Keeping a PR small

- One concern per PR: a feature, a fix, or a refactor, not a mix.
- Put mechanical changes (renames, formatting, import moves) in their own PR, merged first.
- Do the preparatory refactor in a separate PR before the feature that needs it.
- Merge partial work behind a feature flag instead of holding a long branch.
- When the work is layered (schema, service, API, UI) and each layer is reviewable alone, use a stack. See [integration strategies](integration-strategies.md#stacked-prs).

Skip stacking when the change is small, the team is not used to rebasing, or no part makes sense without the rest.

## Author etiquette

- Self-review the diff first (Phase 3). Leave comments on your own PR where the diff is surprising.
- Open as a draft until CI is green and the description is complete.
- Say what you want feedback on: "unsure about the retry policy in `Sender`".
- Link the ticket and any design discussion. Do not make reviewers search.
- Answer every comment: fix it, or explain why not. Resolve threads only for comments you addressed.
- Avoid force-pushing during active review without saying so, since it hides what changed since the last pass. Prefer new commits during review and squash at merge.
- Respond within a working day. A stale PR collects conflicts and blocks dependent work.
- Do not mix new work into a PR mid-review. Open a follow-up instead.

## Reviewer etiquette

- Review within a working day, or say you cannot and hand it off.
- Label severity so the author knows what blocks: `blocker:`, `suggestion:`, `nit:`, `question:`.
- Explain the problem, not only the fix. Comment on the code, not the person.
- Approve with minor comments when nothing blocks. Do not hold a PR for taste.
- Check behavior and tests, not only style. Linters cover style.
- If the PR is too large to review well, ask for a split instead of skimming.

## Review gates

| Risk | Approvals | CI required | Branch up to date |
|---|---|---|---|
| Low (docs, internal tools) | 1 | Yes | No |
| Medium (application code) | 1 | Yes | Yes |
| High (auth, payments, infrastructure, migrations) | 2, one from a code owner | Yes | Yes |

Use a CODEOWNERS file to route high-risk paths to the right reviewers. Enable branch protection on the default branch so these gates are enforced by the platform, not by habit.

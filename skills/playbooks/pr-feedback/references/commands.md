# PR feedback commands

Commands were checked against `gh` 2.67 and the GitLab CLI docs (docs.gitlab.com/cli). Run `gh <command> --help` or `glab <command> --help` if a flag is rejected, since flags change between releases.

## Contents

- [GitHub: status and threads](#github-status-and-threads)
- [GitHub: failed CI](#github-failed-ci)
- [GitHub: reply and resolve](#github-reply-and-resolve)
- [GitLab](#gitlab)
- [Other hosts](#other-hosts)

## GitHub: status and threads

Omit the PR number to use the PR for the current branch.

```bash
# Overall state: review decision, mergeability, checks
gh pr view --json number,url,headRefOid,reviewDecision,mergeStateStatus,statusCheckRollup

# Checks as a table, with a bucket of pass, fail, pending, skipping, cancel
gh pr checks --json name,bucket,state,link --jq '.[] | select(.bucket != "pass")'

# Block until checks finish (exit code 8 means still pending)
gh pr checks --watch --fail-fast
```

`gh pr view --json` does not return review threads or their resolved state. Use GraphQL. It returns each thread with `isResolved`, so you can filter to open ones.

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F number=123 -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          comments(first: 20) {
            nodes { databaseId author { login } body url }
          }
        }
      }
    }
  }
}' --jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false)'
```

- `{owner}` and `{repo}` placeholders are filled by `gh` from the current repository. Replace `123` with the PR number (`gh pr view --json number --jq .number`).
- If `hasNextPage` is true, pass `-f after=<endCursor>` and add `after: $after` to `reviewThreads(first: 100, after: $after)` with `$after: String` in the signature.
- `isOutdated: true` means the diff under the comment changed. The comment may already be fixed, but check before assuming.
- Top-level review bodies and general PR comments are not threads. Read them with `gh pr view --json reviews,comments`.

## GitHub: failed CI

```bash
# Find the failed run for the PR branch
gh run list --branch "$(git branch --show-current)" --limit 5

# Log of only the failed steps (run id from the check link or the list above)
gh run view <run-id> --log-failed

# One job only
gh run view --job <job-id> --log

# Re-run only failed jobs, for infrastructure failures with no code change
gh run rerun <run-id> --failed
```

Check links from `gh pr checks` end in `/runs/<run-id>/job/<job-id>`. Checks from other CI systems (CircleCI, Jenkins) are not GitHub Actions runs, so open the `link` field and read the log there.

## GitHub: reply and resolve

Reply inside a thread (keeps the conversation together). Use the thread `id` from the query above.

```bash
gh api graphql -f id='<thread-id>' -f body='Fixed in abc1234: moved the check into the validator.' -f query='
mutation($id: ID!, $body: String!) {
  addPullRequestReviewThreadReply(input: {pullRequestReviewThreadId: $id, body: $body}) {
    comment { url }
  }
}'
```

REST alternative using the `databaseId` of the first comment in the thread:

```bash
gh api repos/{owner}/{repo}/pulls/123/comments/<comment-id>/replies -f body='Fixed in abc1234.'
```

Resolve a thread only after you addressed it:

```bash
gh api graphql -f id='<thread-id>' -f query='
mutation($id: ID!) {
  resolveReviewThread(input: {threadId: $id}) { thread { isResolved } }
}'
```

A general PR comment (not tied to a line): `gh pr comment 123 --body 'Summary of changes since the last review'`.

## GitLab

The `glab` CLI covers viewing, commenting, and CI. Replying inside a discussion and listing structured threads use `glab api`.

```bash
# MR with discussions, only unresolved ones
glab mr view <id> --unresolved

# Machine-readable output
glab mr view <id> --comments -F json

# Pipeline status for the current branch (wait for it to finish)
glab ci status --wait
glab ci status -F json

# Log of one job, by id or name
glab ci trace <job-id|job-name>

# Retry one job (infrastructure failures only)
glab ci retry <job-id|job-name>

# General MR comment
glab mr note <id> -m 'Summary of changes since the last review'
```

`glab mr note` also has `--resolve` and `--unresolve` for threads. Run `glab mr note --help` for the exact arguments in your version, or use the API calls below, which are documented in full.

Discussions through the REST API (`glab api` fills `:id` with the current project):

```bash
# List discussions (each has an id, a resolved flag, and its notes)
glab api "projects/:id/merge_requests/<iid>/discussions" --paginate

# Reply in a discussion
glab api --method POST "projects/:id/merge_requests/<iid>/discussions/<discussion-id>/notes" -f body='Fixed in abc1234.'

# Resolve a discussion
glab api --method PUT "projects/:id/merge_requests/<iid>/discussions/<discussion-id>" -f resolved=true
```

Source for the endpoints: docs.gitlab.com/api/discussions. Resolving needs the Developer role or higher, or authorship of the change.

## Other hosts

Bitbucket and Azure DevOps have no first-party CLI for threads. Use the host's REST API or web UI, and keep the same rules: triage, fix with tests, reply with the commit, do not resolve what you did not address.

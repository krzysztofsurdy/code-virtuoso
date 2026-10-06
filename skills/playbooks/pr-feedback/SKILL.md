---
name: pr-feedback
description: "Works through review comments and failing CI on an open pull request or merge request: fetches unresolved threads and check status, triages each comment, fixes with tests, replies on every thread, and loops until CI is green. Use when asked to address review comments, fix CI, handle PR feedback, or when checks are failing."
user-invocable: true
argument-hint: "[optional: PR/MR number or URL]"
---

# PR feedback

A reviewer left comments and CI is red. The job is to get the PR to a state where every comment has an honest answer and every check passes, without agreeing by reflex and without gaming the pipeline. Treat each comment as a claim to test against the code, not an order.

**Never resolve a thread you did not address. Never go green by skipping or deleting tests.**

## Procedure

1. **Collect.** Fetch unresolved review threads and check status in one pass. Commands for `gh` (GitHub) and `glab` (GitLab) are in [commands](references/commands.md). Note the PR head commit so replies can cite it later.
2. **Triage.** Put every unresolved thread into one bucket (table below). Write the bucket and a one-line reason before touching code.
3. **Fix CI first if it blocks review.** A red pipeline hides new problems, so reproduce failures locally (see below) before or alongside comment fixes.
4. **Fix with tests.** For each "agree" comment, change the code and add or update a test that would have caught the issue. Keep one commit per concern so replies can point at a single SHA.
5. **Verify.** Run the project's lint, type check, and tests locally. Apply `verification-before-completion`: only output from this session counts.
6. **Push and reply.** Push, then reply on each thread with what changed and the commit SHA. Resolve a thread only when you addressed it and the host's convention is that the author resolves.
7. **Loop.** Wait for CI, re-fetch threads and checks. New comments or new failures restart at step 1. Stop when all checks pass and no thread is unanswered, or when you are blocked (see below).

## Triage buckets

| Bucket | When | What to do |
|---|---|---|
| **Agree and fix** | The comment is correct, or the risk is real and cheap to remove | Fix, add a test, reply with the change and SHA |
| **Disagree** | The suggestion is wrong, out of scope, or breaks a constraint the reviewer may not know | Reply with the technical reason and evidence (code path, test, doc). Offer an alternative or a follow-up ticket. Leave the thread open for the reviewer |
| **Needs clarification** | The intent is unclear, or two readings lead to different fixes | Ask one specific question. Do not guess and implement |
| **Already done** | The code already handles it or an earlier commit fixed it | Point to the line or SHA |

## Evaluate before you agree

Check each suggestion against the code before acting. "Make this a constant" is easy to accept. "Remove this null check" needs a look at the callers. Questions to ask:

- Is the claim true for the code as it is now, not as the reviewer remembers it?
- Does the fix break another caller, a public contract, or a test?
- Is it in scope for this PR, or a separate change?
- Does a project convention or an earlier decision already cover it?

Disagreeing politely with evidence helps the reviewer. Silent agreement that ships a regression does not. If the reviewer is a bot, apply the same checks: bots are often wrong about context.

## Replies

- One reply per thread, short and factual: what changed and the commit (`Fixed in abc1234: moved the check into the validator`).
- For a disagreement, give the reason first, then the offer.
- If a comment asks for something you will not do in this PR, say so and name where it will go.
- Use `communication-style` if the user wants replies in their own voice.
- Post replies only after the fix is pushed, so the SHA exists on the remote.

## Failing CI

1. **Read the failure.** Fetch the failed job log, not the whole run (commands in [commands](references/commands.md)). Find the first real error, not the last line.
2. **Reproduce locally.** Run the same command the job runs, with the same versions and env flags. If it passes locally, look for CI-only differences: cached dependencies, OS, timezone, parallelism, missing service containers, test order.
3. **Fix the root cause.** Use the `debugging` skill when the cause is not obvious. Flaky tests get a stability fix or an issue, not a blind re-run.
4. **Never go green by cheating.** Do not skip, delete, or loosen a test, lower a coverage gate, add `|| true`, or disable a lint rule to pass. If a check is wrong, fix the check in its own commit and tell the reviewer.
5. **Re-run only after a push** (or a re-run of failed jobs when the failure was infrastructure, such as a runner timeout or a network error). Say in the reply when you re-ran without a code change.

## When to stop

Stop and report instead of looping forever when:

- The same check fails after two different fixes. Report what you tried and what you observed.
- A required check needs access you lack (secrets, protected environments, a runner you cannot reach).
- Reviewers disagree with each other, or a comment conflicts with the ticket.
- A needs-clarification thread has had no answer. Summarise it for the user.

## Checklist

- [ ] All unresolved threads fetched, each in a bucket
- [ ] Failing checks reproduced locally before fixing
- [ ] Every agreed change has a test and a commit
- [ ] Lint, types, and tests pass locally this session
- [ ] Every thread has a reply with the SHA or the reasoning
- [ ] No thread resolved without being addressed
- [ ] CI re-run after the push and green, or the blocker reported

## Reference files

| Reference | Contents |
|---|---|
| [commands](references/commands.md) | `gh` and `glab` commands for threads, checks, failed logs, replies, resolving, and re-runs |

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| A CI failure has an unclear cause | `debugging` |
| Confirming the fix before pushing | `verification-before-completion` |
| Writing replies in the user's voice | `communication-style` |
| PR description needs updating after changes | `pr-message-writer` |
| Branch was ready to merge before feedback | `finishing-branch` |
| Session ends with feedback still open | `handoff` |

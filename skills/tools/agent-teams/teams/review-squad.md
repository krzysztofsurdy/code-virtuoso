---
name: review-squad
description: "Multi-perspective code review team. Three reviewers examine changes from independent angles - zero context, spec compliance, and full quality review - then the lead triages into one actionable report. Use when merging significant changes that warrant thorough review."
lead: reviewer
agents:
  - reviewer
  - cold-reviewer
  - acceptance-verifier
skills:
  - verification-before-completion
workflow: parallel
---

# Review Squad

## Purpose

Examine code changes from three independent angles simultaneously, then merge findings into a single triaged report. Each reviewer operates at a different context level: zero (cold reviewer), spec-only (acceptance verifier), and full project context (lead reviewer). Comparing the three perspectives catches issues that a single reviewer misses.

## Workflow

1. **Cold Reviewer**: receives only the diff. No spec, no docs, no history. Returns findings based purely on what the code shows. Runs in parallel with phase 2.
2. **Acceptance Verifier**: receives the diff plus acceptance criteria. Returns a per-criterion PASS/FAIL/PARTIAL/UNTESTED matrix. Runs in parallel with phase 1.
3. **Reviewer (lead)**: reads both reports, performs a full structured review (correctness, SOLID, security, performance, smells, testing), then produces the unified report. Deduplicates across all three sources.

## Entry Criteria

- A diff, branch, or commit range exists to review
- Tests pass before the review starts
- For Acceptance Verifier: acceptance criteria or requirements are available. If unavailable, run a two-reviewer variant instead.

## Exit Criteria

- Unified review report with all findings deduplicated and classified
- Each finding tagged: **fix** (must address), **discuss** (human judgment needed), **defer** (out of scope), or **dismiss** (false positive)

## Coordination Rules

- Cold Reviewer must not receive acceptance criteria, docs, or prior conversation. Only the diff.
- Acceptance Verifier must receive both the diff and the acceptance criteria. No project docs.
- Reviewer (lead) has full codebase access and reads all prior reports.
- Duplicate findings from multiple reviewers merge into one, noting which reviewers caught it.
- Conflicting severity assessments default to the higher severity.
- Skip Acceptance Verifier if no acceptance criteria exist.

## Spawning

**Peer mode** (platforms with agent-to-agent messaging):
1. Create the team with Reviewer as lead
2. Post two parallel tasks: "Cold review of [diff]" and "Verify [diff] against [criteria]"
3. Cold Reviewer and Acceptance Verifier post their reports
4. Reviewer reads both, runs its own review, posts the unified result

**Sequential mode** (all other platforms):
1. Spawn Cold Reviewer with the diff - collect report
2. Spawn Acceptance Verifier with the diff and criteria - collect report
3. Reviewer reads both reports, runs its own review, produces the unified result

## Variants

- **Two-reviewer**: drop Acceptance Verifier when no criteria exist. Cold Reviewer + Reviewer still provides zero-context vs full-context contrast.
- **Deep mode**: add Refactor Scout before the review to scan for structural smells. Its smell report feeds into the Reviewer's analysis alongside the other two reports.

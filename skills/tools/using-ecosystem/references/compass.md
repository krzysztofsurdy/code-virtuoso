# Compass Mode

When the user has just finished work with an agent, skill, or team and asks "what next?" or "where do I go from here?" - use compass mode to recommend the next step.

## How It Works

Compass mode is conversational. Ask the user what they just completed, then match against known workflows to recommend the logical next step. Do not scan the filesystem for artifacts - ask the user.

## Recommendation Map

| Just finished with | Likely next step | Why |
|---|---|---|
| **Brainstorming** (spec approved) | Architect or a planning skill | Spec needs a design before implementation |
| **Investigator** (report produced) | Architect or Implementer | Findings need design decisions or direct fixes |
| **Product Manager** (requirements/PRD) | Architect | Requirements need technical design |
| **Architect** (ADR/design produced) | Backend Dev, Frontend Dev, or Development Team | Design needs implementation |
| **Backend Dev / Frontend Dev** (code written) | Reviewer or Review Squad | Code needs review before merging |
| **Reviewer** (review report) | Implementer (if fixes needed) or finishing-branch | Apply fixes, or merge if approved |
| **Cold Reviewer** (cold review report) | Reviewer (for triage) or Implementer | Cold findings need context-aware triage, then fixes |
| **Refactor Scout** (smell report) | Reviewer (validate findings), then Implementer | Confirm findings are real, then apply refactorings |
| **Test Gap Analyzer** (gap report) | Implementer | Write the missing tests |
| **Migration Planner** (migration plan) | Reviewer, then Implementer | Validate plan, then execute |
| **QA Engineer** (test plan/sign-off) | Finishing-branch or Project Manager | Ship it, or update delivery tracking |
| **Review Squad** (triaged report) | Implementer (for fixes) or finishing-branch | Address fix items, then merge |
| **War Room** (decision made) | Architect (if design needed) or Dev agents (if ready to build) | Turn the decision into action |
| **Dependency Auditor** (audit report) | Implementer (for upgrades) or ticket-writer (for tracking) | Fix vulnerabilities or track them |
| **Doc Writer** (docs written) | Reviewer or finishing-branch | Review docs, then ship |

## Handling Ambiguity

When the next step is unclear (e.g., after an investigation, both Architect and Implementer could be appropriate):

1. Present 2-3 options with one-line reasoning for each
2. Let the user choose
3. If the user is unsure, recommend the safer path (more analysis before more action)

## Dead Ends

Not every interaction needs a next step. If the user has:
- Completed a standalone task (e.g., dependency audit with no issues found)
- Finished a full workflow (development team delivered, PR merged)
- Used a tool skill for a one-off output (ticket-writer, report-writer)

Say so: "That looks complete. Nothing chains naturally from here unless you have a new task."

## Teams Over Chains

If the compass would recommend 3+ agents in sequence, check whether a pre-composed team covers that workflow instead. Teams are easier to invoke and include coordination rules that ad-hoc chains lack.

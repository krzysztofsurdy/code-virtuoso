# When to exit

Criteria for determining whether brainstorming is complete or needs more rounds. Stop at the point of diminishing returns: thorough enough that the spec is reliable, not so thorough that the session becomes an end in itself.

## Contents

- [Brainstorming is done when](#brainstorming-is-done-when)
- [Brainstorming needs more rounds when](#brainstorming-needs-more-rounds-when)
- [Diminishing returns](#diminishing-returns)
- [Premature exit](#premature-exit)
- [Edge cases](#edge-cases)
- [Decision tree](#decision-tree)

---

## Brainstorming is done when

All of the following must be true:

1. **The spec is written.** All mandatory sections of the spec template are filled in. Empty sections are marked "N/A - [reason]" with a genuine reason.

2. **The user has explicitly approved.** "Looks good," "approve," "yes," or equivalent affirmative. Silence, "sure," or proceeding without comment does not count as approval - ask directly.

3. **No unresolved contradictions.** If the spec says both "real-time updates" and "works offline," those have been reconciled into a coherent design direction (e.g., "offline-first with sync-on-reconnect").

4. **All must-have acceptance criteria are present and testable.** Each criterion can be verified by a human test or automated test. Subjective criteria ("it should feel intuitive") have been rewritten into testable forms or moved to non-goals.

5. **The scope boundary is explicit.** Goals and non-goals together draw a clear line around what is in and what is out. A reader who was not in the session can tell what the project includes and excludes.

6. **The first-cut approach is coherent with the scope.** The described approach could plausibly satisfy the acceptance criteria. If the approach looks far too small or too large for the stated scope, something is misaligned.

---

## Brainstorming needs more rounds when

Any of the following indicate the session is not yet complete:

### Signals from the spec

| Signal | What it means | Action |
|---|---|---|
| A section says "TBD" or "to be determined" | Genuine unknowns remain | Move to open questions if non-blocking, or resolve if blocking |
| Acceptance criteria use vague language ("fast," "reliable," "user-friendly") | Criteria are not testable | Rewrite with specific, measurable thresholds |
| Non-goals section is empty | Scope boundaries are undefined | Ask: "What might someone expect to be in scope that is not?" |
| Risks section has only generic risks | Risk analysis was superficial | Ask about specific technical, operational, and adoption risks |
| First-cut approach contradicts constraints | Coherence failure | Revisit constraints and approach together |

### Signals from the conversation

| Signal | What it means | Action |
|---|---|---|
| User has not disagreed with or refined anything | Possible fake consensus | Probe engagement - see anti-patterns reference |
| User introduced new scope after convergence | Scope is not locked | Return to divergence for the new item, then re-converge |
| User expressed uncertainty about a key decision | A blocking question exists | Resolve before proceeding to approval |
| User deferred a decision ("let's figure that out later") | An open question may be blocking | Assess: is this genuinely non-blocking, or is it avoidance? |
| Two stated requirements contradict each other | Unresolved contradiction | Surface the conflict explicitly and ask the user to choose |

### Signals from question coverage

| Signal | What it means | Action |
|---|---|---|
| No constraint-surfacing questions were asked | Solution space may be unbounded | Ask at least two constraint questions before closing |
| No risk-surfacing questions were asked | Risks are hidden, not absent | Ask at least one risk question before closing |
| No assumption-challenging questions were asked | Unstated assumptions may be embedded | Challenge at least one stated "fact" |
| Only one approach was discussed | Anchoring on the first idea | Force at least one alternative before choosing |

---

## Diminishing returns

Brainstorming has reached diminishing returns when:

- New questions produce answers that repeat what is already in the spec
- The user starts giving shorter, more impatient answers
- The scope has been confirmed multiple times without change
- Acceptance criteria are stable across revisions
- The only remaining open questions are genuinely non-blocking

At this point, write the spec and move to the approval gate. Do not continue exploring for the sake of thoroughness.

---

## Premature exit

Brainstorming is being exited too early when:

- The spec has been written but the user has not approved it
- Critical sections are incomplete without explanation
- The user said "just build it" without reviewing the spec
- No closed questions were asked during convergence (scope was never locked)
- The acceptance criteria describe features, not testable outcomes

If the user pushes to skip ahead, acknowledge the pressure and show the value: "I understand you want to move fast. Let me ask one more question that will save us rework later."

---

## Edge cases

### The user approves too quickly

If the user approves the spec within seconds of seeing it, they probably did not read it. Ask a specific question about one acceptance criterion: "Just to confirm - criterion #3 says [specific detail]. Is that accurate?" This prompts engagement without confrontation.

### The user wants to iterate forever

If convergence has restarted more than twice, the user may be uncomfortable committing. Name it: "We have explored this at length. Is there a specific concern that is preventing you from approving, or are we ready?" Sometimes the blocker is not a spec issue but an organizational or political one.

### The scope changed dramatically

If Phase 2 (divergence) revealed that the project is fundamentally different from what the user initially described, do not try to fit the new understanding into the old spec. Start a fresh spec with the new problem statement. Patching a spec whose foundation has shifted produces an incoherent document.

### Multiple specs needed

If brainstorming reveals that the project naturally splits into independent workstreams, produce separate specs for each. A spec that covers two unrelated features is harder to approve, implement, and verify.

---

## Decision tree

```
Is the spec fully written?
  No  -> Continue writing (Phase 4)
  Yes -> Does the user approve?
           No, wants changes  -> Revise and re-present
           No, has not seen it -> Present for review (Phase 5)
           Yes -> Are there unresolved contradictions?
                    Yes -> Resolve, revise, re-present
                    No  -> Are all acceptance criteria testable?
                             No  -> Rewrite vague criteria
                             Yes -> EXIT: Brainstorming complete
```

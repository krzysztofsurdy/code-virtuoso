# Post-Mortem Template

Use this template for significant bugs: production incidents, bugs that affected multiple users, bugs that took more than a day to resolve, or bugs that reveal systemic issues. Post-mortems are blameless. Their purpose is institutional learning, not assigning fault.

---

## Contents

- [Template](#template)
- [Example post-mortem](#example-post-mortem)

## Template

```
# Post-Mortem: [Short title describing the incident]

## Incident Summary
[1-2 sentences: what happened, who was affected, how severe.]

## Timeline
- **[timestamp]**: Bug introduced (commit/deploy/config change)
- **[timestamp]**: First user impact or alert triggered
- **[timestamp]**: Issue reported / team became aware
- **[timestamp]**: Investigation started
- **[timestamp]**: Root cause identified
- **[timestamp]**: Fix implemented
- **[timestamp]**: Fix deployed and verified
- **[timestamp]**: Incident closed

## Root Cause
[Technical explanation of WHY the bug happened. Cover what was wrong and
why the system allowed it. Include the chain of events.]

## Impact
- **Users affected**: [number or percentage]
- **Duration**: [time from first impact to resolution]
- **Severity**: [critical / high / medium / low]
- **Data impact**: [any data loss or corruption? was it recoverable?]
- **Business impact**: [revenue, reputation, SLA violations, if applicable]

## Resolution
[What was done to fix the immediate issue. Include the specific change:
commit hash, config change, rollback, etc.]

## Prevention
What will prevent this class of bug from recurring:
- [ ] [Specific test added: describe what it covers]
- [ ] [Monitoring/alerting improvement: what threshold, what alert]
- [ ] [Validation added: where, what it checks]
- [ ] [Design change: if structural prevention is needed]
- [ ] [Documentation updated: runbook, onboarding, API docs]

## Lessons Learned
### What went well
- [Things that worked during detection and response]

### What went poorly
- [Things that slowed detection or resolution]

### Where we got lucky
- [Things that could have been worse but happened to work out]

## Action Items
| Action | Owner | Due Date | Status |
|---|---|---|---|
| [Specific task] | [Person/team] | [Date] | [Open/Done] |
| [Specific task] | [Person/team] | [Date] | [Open/Done] |
```

---

## Example post-mortem

```
# Post-Mortem: Order totals calculated incorrectly for discount codes

## Incident Summary
Orders using percentage-based discount codes were charged the wrong amount
when the cart contained items with different tax rates. Approximately 340
orders were affected over 3 days before detection.

## Timeline
- **Mon 09:14**: Deploy v2.31.0 with refactored discount calculation module
- **Mon 09:30**: First affected order placed (detected retroactively)
- **Wed 11:02**: Customer support receives third complaint about wrong total
- **Wed 11:45**: Support escalates to engineering, investigation begins
- **Wed 13:20**: Root cause identified: discount applied before tax grouping
- **Wed 14:10**: Fix implemented and tested
- **Wed 14:45**: Fix deployed to production (v2.31.1)
- **Wed 15:30**: Affected orders identified, refund process initiated
- **Thu 10:00**: All affected customers refunded, incident closed

## Root Cause
The discount calculation refactor in v2.31.0 changed the order of operations.
Previously, items were grouped by tax rate first, then the discount was applied
to each group. The refactored code applied the discount to the full subtotal
first, then split by tax rate. This caused rounding errors when tax rates
differed across items, resulting in totals that were off by small amounts
(typically under 1 currency unit, but noticeable to customers).

The root cause was not the rounding itself but the lack of a specification
for the calculation order. The original code was correct by accident:
there was no test or documentation specifying that tax grouping must happen
before discount application.

## Impact
- **Users affected**: 340 orders (approximately 2% of orders in the period)
- **Duration**: 3 days (Mon 09:30 to Wed 14:45)
- **Severity**: High (incorrect charges)
- **Data impact**: No data loss. Incorrect totals stored but correctable.
- **Business impact**: Refunds issued totaling approximately $890. Three
  customer complaints. No SLA violation.

## Resolution
Reverted the order of operations so tax grouping happens before discount
application. Added explicit rounding at each calculation step. Commit abc1234.

## Prevention
- [x] Added 12 test cases covering discount + mixed tax rate combinations
- [x] Added property-based test generating random carts with discounts
- [ ] Add monitoring alert when order total differs from cart total by > 0.01
- [ ] Document the calculation order specification in the architecture docs
- [ ] Add integration test that compares order flow output against a reference
      implementation for 1000 random carts

## Lessons Learned
### What went well
- Customer support escalated quickly after spotting the pattern
- Root cause was found within 2 hours of investigation starting
- Fix was low-risk and deployable same day

### What went poorly
- 3-day detection gap, with no automated check to catch the discrepancy
- The refactor had no specification to test against
- Code review did not catch the order-of-operations change

### Where we got lucky
- The amounts were small, so customer impact was limited
- No regulatory implications for this billing error

## Action Items
| Action | Owner | Due Date | Status |
|---|---|---|---|
| Add monitoring for total discrepancies | Platform team | Next sprint | Open |
| Document calculation order spec | Backend team | Next sprint | Open |
| Add property-based cart tests | QA | Done | Done |
| Review other financial calculations for similar issues | Backend team | 2 sprints | Open |
```

# Project Status Report Template

A structured template for regular progress reporting. Use this for highlight reports during stage execution and for stakeholder updates.

---

## Highlight Report Template

Produce this report at the agreed frequency (typically weekly). It gives the project board and stakeholders a clear picture of progress, issues, and forecast.

### [Project Name] - Status Report

**Report Date**: [YYYY-MM-DD]

**Report Period**: [Start date] to [End date]

**Author**: [Project Manager name]

**Distribution**: [List of recipients]

---

### Overall Status

| Dimension | Status | Trend | Comment |
|---|---|---|---|
| **Schedule** | Green / Amber / Red | Improving / Stable / Declining | [One sentence explanation] |
| **Scope** | Green / Amber / Red | Improving / Stable / Declining | [One sentence explanation] |
| **Quality** | Green / Amber / Red | Improving / Stable / Declining | [One sentence explanation] |
| **Risk** | Green / Amber / Red | Improving / Stable / Declining | [One sentence explanation] |
| **Budget** | Green / Amber / Red | Improving / Stable / Declining | [One sentence explanation] |

**RAG Definitions**:

| Color | Meaning |
|---|---|
| **Green** | On track. Within tolerances. No action needed from the project board. |
| **Amber** | At risk. Approaching tolerance boundaries. Corrective action in progress or planned. |
| **Red** | Off track. Tolerance breached or forecast to breach. Escalation or exception report required. |

### Executive Summary

[2-3 sentences summarizing the most important things the reader needs to know. Lead with the headline - do not bury bad news.]

### Achievements This Period

| # | Achievement | Impact |
|---|---|---|
| 1 | [What was completed or delivered] | [Why it matters] |
| 2 | [What was completed or delivered] | [Why it matters] |
| 3 | [What was completed or delivered] | [Why it matters] |

### Planned for Next Period

| # | Activity | Owner | Due Date |
|---|---|---|---|
| 1 | [What will be worked on] | [Name/role] | [Date] |
| 2 | [What will be worked on] | [Name/role] | [Date] |
| 3 | [What will be worked on] | [Name/role] | [Date] |

### Issues and Blockers

| # | Issue | Impact | Owner | Status | Resolution Target |
|---|---|---|---|---|---|
| 1 | [Description] | [How it affects delivery] | [Name] | Open / In Progress / Resolved | [Date] |
| 2 | [Description] | [How it affects delivery] | [Name] | Open / In Progress / Resolved | [Date] |

### Risk Summary

| # | Risk | Probability | Impact | Mitigation | Owner |
|---|---|---|---|---|---|
| 1 | [Risk description] | High / Medium / Low | High / Medium / Low | [Current mitigation action] | [Name] |
| 2 | [Risk description] | High / Medium / Low | High / Medium / Low | [Current mitigation action] | [Name] |

[Full risk register is maintained separately. Only top risks are included here.]

### Milestones

| Milestone | Planned Date | Forecast Date | Status |
|---|---|---|---|
| [Milestone 1] | [Original date] | [Current forecast] | Complete / On Track / At Risk / Late |
| [Milestone 2] | [Original date] | [Current forecast] | Complete / On Track / At Risk / Late |
| [Milestone 3] | [Original date] | [Current forecast] | Complete / On Track / At Risk / Late |

### Decisions Needed

| # | Decision Required | Context | Decision Maker | Due Date |
|---|---|---|---|---|
| 1 | [What needs to be decided] | [Brief context] | [Role/name] | [Date] |

---

## End Stage Report Template

Produce this report at each stage boundary. It summarizes the completed stage and recommends whether to proceed.

### [Project Name] - End Stage Report: [Stage Name]

**Date**: [YYYY-MM-DD]

**Author**: [Project Manager]

---

### Stage Summary

| Field | Value |
|---|---|
| **Stage** | [Stage name/number] |
| **Planned start** | [Date] |
| **Actual start** | [Date] |
| **Planned end** | [Date] |
| **Actual end** | [Date] |
| **Variance** | [+/- days] |

### Deliverables

| Deliverable | Status | Quality Check | Notes |
|---|---|---|---|
| [Deliverable 1] | Delivered / Partial / Deferred | Passed / Failed | [Any notes] |
| [Deliverable 2] | Delivered / Partial / Deferred | Passed / Failed | [Any notes] |

### Performance Against Plan

| Dimension | Planned | Actual | Variance | Within Tolerance |
|---|---|---|---|---|
| Schedule | [X weeks] | [Y weeks] | [+/- Z weeks] | Yes / No |
| Scope | [N deliverables] | [M deliverables] | [Deferred items] | Yes / No |
| Quality | [Target] | [Actual] | [Gap] | Yes / No |

### Lessons Learned

| # | Category | Lesson | Action for Next Stage |
|---|---|---|---|
| 1 | [Process / Technical / Communication] | [What we learned] | [What we will do differently] |
| 2 | [Category] | [Lesson] | [Action] |

### Recommendation

- [ ] **Proceed** to the next stage as planned
- [ ] **Proceed with adjustments** (specify adjustments below)
- [ ] **Pause** for re-planning
- [ ] **Close** the project (business case no longer valid)

**Adjustments** (if applicable):

[Describe changes to scope, timeline, resources, or approach for the next stage]

---

## Status Report Writing Guidelines

### Leading with Bad News

| Do | Do Not |
|---|---|
| "Sprint is 3 days behind due to API integration complexity" | "Things are going well overall" (when they are not) |
| "Risk X has materialized; mitigation plan below" | "There are some minor issues we are working through" |
| State the impact, then the mitigation | Minimize or defer bad news to a later report |

### RAG Status Guidelines

**Schedule**:
- Green: Forecast completion is within the planned date +/- tolerance
- Amber: Forecast completion is approaching tolerance boundary
- Red: Forecast completion exceeds tolerance; exception report required

**Scope**:
- Green: All planned deliverables are on track
- Amber: Some deliverables are at risk of being deferred
- Red: P0 deliverables are at risk or have been descoped without approval

**Quality**:
- Green: Test pass rate meets target; no open P0/P1 bugs
- Amber: Test pass rate below target or open P1 bugs pending
- Red: Open P0 bugs or quality metrics significantly below target

### Report Frequency Guide

| Project Size | Report Frequency | Report Depth |
|---|---|---|
| Small (1-2 weeks) | Daily standup summary | Bullet points |
| Medium (2-8 weeks) | Weekly highlight report | Full template |
| Large (2+ months) | Weekly highlights + monthly detailed report | Full template + trend analysis |

### Audience Adaptation

| Audience | Focus On | Avoid |
|---|---|---|
| **Project board / executives** | Status, risks, decisions needed, milestones | Technical details, implementation specifics |
| **Development team** | Blockers, priorities, scope clarification | Business justification, budget details |
| **Stakeholders** | Deliverable progress, timeline impact | Internal team issues, technical debt |

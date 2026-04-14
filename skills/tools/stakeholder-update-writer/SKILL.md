---
name: stakeholder-update-writer
description: Write a stakeholder Slack/email update message. Use when the user wants to communicate project status, blockers, decisions, or release readiness to stakeholders.
user-invocable: true
argument-hint: "[optional: topic or context]"
---

# Stakeholder Update Message

Write a concise, professional stakeholder update message for Slack or email.

## Process

### 1. Gather context

Understand what the user wants to communicate. The source can be anything:
- An epic or set of tickets from your ticket tracker or project management tool (fetch via your project tracker integration if available)
- A conversation summary or decision outcome
- A project milestone, blocker, or risk
- A release status or go/no-go decision
- Anything the user describes or provides

If the context is about tracked work (epic, sprint, tickets), fetch the relevant data to understand the full picture. If it's about a decision, event, or general update, work from what the user provides.

### 2. Understand the audience and purpose

Before drafting, identify:
- **Who** is receiving this (team, management, cross-functional stakeholders, external partners)
- **What** they need to know (status, decision, blocker, request for input, FYI)
- **What action** is expected from them (none, approval, input, awareness)

If unclear, ask the user briefly before drafting.

### 3. Draft the message

**Tone**: Professional, direct, confident. Not corporate fluff. Written as a real person talking to colleagues.

**Structure**: Flowing text with minimal formatting. Use bold for section headers only when they add clarity. Avoid:
- Bullet-point walls
- Listing every ticket or task individually
- Project management jargon (sprint velocity, story points, epics)
- Over-explaining what's obvious

**Content flow**:
1. One-line context -- what this is about
2. Background -- what led to this update (kept brief, only what the reader needs)
3. The substance -- grouped by theme, not by ticket or task. Summarize what matters in plain language. Keep it to 3-4 groups max.
4. Framing -- set expectations on effort, timeline, or impact
5. Dependencies or asks -- who needs to do what
6. Next steps -- where to find details, when to expect the next update, offer to discuss

**Key principles**:
- Lead with the conclusion, not the process
- Group by business theme, not by task or ticket
- Say what needs to happen, not what the task title says
- Name people/teams who own dependencies
- One link to a tracking board or document is enough -- don't link every item
- Keep it under 200 words if possible

### 4. Iterate with the user

Expect the user to refine. Common feedback patterns:
- "Too many details" -- consolidate, remove granularity
- "More professional" -- drop casual language, tighten sentences
- "Less bullet points" -- convert to flowing paragraphs
- "Add context about X" -- weave it in naturally, don't bolt on a section
- "Shorter" -- cut to the essentials, assume more shared context

When iterating, apply the feedback and present the full updated message. Don't ask clarifying questions unless the feedback is genuinely ambiguous.

## Example output style

> Hey -- update on [topic].
>
> We've [done what / looked into what / decided what], and here's where we are.
>
> **Theme A** -- what's happening, what needs to happen. Who's on it.
>
> **Theme B** -- what's happening. What we need from [person/team].
>
> **Theme C** -- what's happening.
>
> [Effort/timeline framing]. [Key dependency or ask].
>
> [Where to find details]. [Next checkpoint]. Happy to discuss.

## Anti-patterns to avoid

- Starting with "I hope this message finds you well" or similar filler
- Restating an entire document or epic description
- Including task/ticket IDs inline (a single link is enough)
- Writing a wall of bullet points that reads like a board export
- Over-qualifying statements ("we believe", "it seems like", "potentially")
- Adding a summary section at the end that repeats the message
- Using project management jargon the audience doesn't care about

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| When generating a full project report instead of a message | `report-writer` |
| When writing a PR description, not a stakeholder message | `pr-message-writer` |
| When planning sprint goals to reference in the update | `scrum` |

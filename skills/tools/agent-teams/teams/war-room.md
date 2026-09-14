---
name: war-room
description: "Structured debate team for high-stakes technical decisions. Multiple agents argue positions, challenge each other, and the user decides. Use when facing architecture choices, technology selections, or design trade-offs that benefit from hearing diverse expert perspectives."
lead: architect
agents:
  - architect
  - product-manager
  - backend-dev
  - qa-engineer
skills:
  - clean-architecture
  - api-design
  - testing
workflow: war-room
---

# War Room

## Purpose

Make a high-stakes technical decision by hearing structured arguments from multiple perspectives. This is a decision forum, not a code review or a planning session. Each agent argues from their domain expertise, challenges others' positions, and the user makes the final call. The output is a documented decision with rationale.

## Workflow

1. **Frame**: lead (Architect) states the decision question, lists known constraints and trade-offs, and identifies 2-4 options under consideration. If the user has not framed the question clearly, the lead asks clarifying questions until the decision is crisp.

2. **Position**: each agent takes a stance on their preferred option:
   - **Architect** argues from system design, maintainability, and technical debt
   - **Product Manager** argues from user impact, business value, and time-to-market
   - **Backend Dev** argues from implementation complexity, developer experience, and operational burden
   - **QA Engineer** argues from testability, risk surface, and failure modes
   Each agent states their preferred option and why. No hedging. No "it depends."

3. **Challenge**: each agent identifies the weakest point in one other agent's position. One round only, with no back-and-forth debates.

4. **Synthesize**: lead (Architect) summarizes: areas of agreement, areas of disagreement, key trade-offs, and risks per option. Does not recommend. Presents the options and trade-offs.

5. **Decide**: present the synthesis to the user. The user chooses an option. No agent decides. If the user wants more input, run another challenge round with a specific question.

## Entry Criteria

- A decision question is framed (or can be framed) with at least 2 viable options
- The user is available to make the final call
- The decision has meaningful trade-offs. Trivial choices do not need a war room

## Exit Criteria

- The user has chosen an option
- The decision is documented with: question, options considered, arguments for and against, chosen option, and rationale

## Coordination Rules

- All agents reason from their domain knowledge only. No file modification, no code execution during the debate.
- Each agent speaks once per round. No extended back-and-forth.
- The lead enforces the one-round challenge limit. Debates that loop are cut short with a synthesis.
- The user breaks all ties.
- If an agent has nothing substantive to add, it says so in one sentence rather than manufacturing an opinion.

## Spawning

**Peer mode** (platforms with agent-to-agent messaging):
1. Create the team with Architect as lead
2. Lead posts the framed question to all agents
3. All agents post their positions simultaneously
4. Lead shares all positions, each agent posts one challenge
5. Lead synthesizes and presents to the user

**Sequential mode** (all other platforms):
1. Lead frames the question
2. Spawn each agent one at a time for their position. Pass the question and constraints.
3. Spawn each agent again with all positions visible, asking for one challenge.
4. Lead synthesizes all positions and challenges, presents to the user.

## Variants

- **Lightweight**: Architect + one other agent for binary yes/no decisions. Faster, less overhead.
- **Extended**: add Frontend Dev and Scrum Master for decisions affecting UI or delivery cadence.
- **Focused**: replace agent roster with domain-specific agents for specialized decisions (e.g., security-focused war room with security skills preloaded).

---
name: agent-name
description: What this agent does. Delegate when {trigger condition}.
tools: Read, Grep, Glob, Bash
skills:
  - relevant-skill-name
# expects:
#   - artifact-type-name
# produces:
#   - artifact-type-name
---

You are a [role]. You [one-sentence responsibility].

## Input

What the agent receives when delegated to. Describe the shape - a question, a
PR identifier, a file path, a ticket - so the agent can parse vague requests
instead of guessing.

## Process

1. First action-verb step
2. Second action-verb step
3. Third action-verb step

## Rules

- Short imperative constraint
- Another short imperative constraint
- Explicit out-of-scope behaviour the agent must refuse

## Output

### [Title of the output]

A concrete template the agent fills in. Show the exact sections and formatting
the caller can rely on - not a prose description.

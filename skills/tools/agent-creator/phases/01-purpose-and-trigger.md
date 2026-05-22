# Phase 1: Purpose and Trigger

**Progress: Phase 1 of 6**

## Purpose

Define what the agent does, when it should be delegated to, what it should NOT do, and what success looks like.

## Steps

1. Ask the user up to four questions in a single batch:
   - **What task does this agent perform?** (one sentence, imperative form)
   - **When should the orchestrator delegate to it?** (trigger conditions - list phrases or situations)
   - **What should the agent NOT do?** (explicit out-of-scope items)
   - **What does success look like?** (the shape of the output it returns)

2. Record the answers verbatim - they feed the `description` field and system prompt.

3. Check for scope creep: if Q1 contains "and" joining two different actions, push back. "That looks like two agents. Pick the primary responsibility first; a second agent can be created after."

4. If the user provided an archetype argument at invocation, confirm it matches the described purpose. Otherwise, present the archetype selection from the Archetype Selection section in SKILL.md and let the user choose.

## Gate

**Advances when:** The user has confirmed the purpose, trigger, out-of-scope items, output shape, and archetype.
**Returns to this phase when:** The purpose describes two different responsibilities, or the user wants to revise.

Ask the user: "Here is what I captured - [summarize purpose, trigger, non-goals, output shape, archetype]. Does this accurately describe the agent you want to create?"

Do NOT proceed to Phase 2 until the user explicitly confirms.

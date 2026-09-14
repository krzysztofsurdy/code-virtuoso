# Phase 1: Purpose and trigger

**Progress: Phase 1 of 6**

## Purpose

Define what the agent does, when to delegate to it, what it must not do, and what success looks like.

## Steps

1. Ask the user up to four questions in a single batch:
   - **What task does this agent perform?** (one sentence, imperative form)
   - **When should the orchestrator delegate to it?** (trigger conditions - list phrases or situations)
   - **What should the agent NOT do?** (explicit out-of-scope items)
   - **What does success look like?** (the shape of the output it returns)

2. Record the answers verbatim. They feed the `description` field and the system prompt.

3. Check for scope creep. If the first answer joins two different actions with "and", push back: "That looks like two agents. Pick the primary responsibility first; a second agent can be created after."

4. If the user provided an archetype argument at invocation, confirm it matches the described purpose. Otherwise, present the archetype selection from the Archetype Selection section in SKILL.md and let the user choose.

## Gate

**Advances when:** the user has confirmed the purpose, trigger, out-of-scope items, output shape, and archetype.
**Returns to this phase when:** the purpose describes two different responsibilities, or the user wants to revise.

Ask the user: "Here is what I captured: [summarize purpose, trigger, non-goals, output shape, archetype]. Does this describe the agent you want to create?"

Do not proceed to Phase 2 until the user explicitly confirms.

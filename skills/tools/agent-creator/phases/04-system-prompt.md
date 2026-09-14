# Phase 4: System prompt

**Progress: Phase 4 of 6**

## Purpose

Draft the agent's system prompt following the five-section contract.

## Steps

1. Draft the system prompt using the answers from Phases 1-3. Structure it as:

   ```
   You are a [role]. You [one-sentence responsibility].

   ## Input
   What the agent receives when delegated to.

   ## Process
   Numbered steps the agent runs through (3-7 steps).

   ## Rules
   Constraints and guardrails. What the agent must never do.

   ## Output
   The exact shape of what the agent returns. Include a template.
   ```

2. Check for common mistakes (see [system-prompts.md](../references/system-prompts.md)):
   - No filler preamble ("You are a helpful AI assistant...")
   - No model-specific phrasing ("As Claude...")
   - No tool instructions contradicting the frontmatter
   - No second responsibility smuggled in
   - Output section has a concrete template, not prose

3. Present the draft to the user.

## Gate

**Advances when:** the user approves the system prompt or has incorporated all requested changes.
**Returns to this phase when:** the user wants revisions to the prompt.

Ask the user: "Here is the system prompt draft. Review it and confirm, or tell me what to change."

Do not proceed to Phase 5 until the user approves the system prompt.

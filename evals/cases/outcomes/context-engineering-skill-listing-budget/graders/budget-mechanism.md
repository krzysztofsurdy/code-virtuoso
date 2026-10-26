---
type: llm
focus: last_message
---

PASS if the reply explains that the skill listing has a fixed budget (about 1 percent of the context window, with a per-skill description cap of 1,536 characters) and that when it overflows the descriptions of the least-used skills are dropped first while the names stay, and recommends reducing the listing (disable unused plugins or skills, set low-value skills to name-only or off in skillOverrides, or mark them disable-model-invocation) and trimming descriptions with the key use case first, with raising the budget (skillListingBudgetFraction or SLASH_COMMAND_TOOL_CHAR_BUDGET) as a last step that costs context every turn.
FAIL if the reply attributes it to model quality or vague context limits, tells the user to just raise the budget first, or names no listing budget or setting.

---
type: llm
focus: last_message
---

PASS if the reply ends by asking the user exactly one focused question about the idea (such as what problem it solves, who imports, or from where), contains no code, and does not present a finished design, implementation plan or list of many questions.
FAIL if the reply contains code or pseudocode, says the importer has been built, asks several separate questions in one message, or proposes a full solution before asking anything.

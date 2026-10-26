---
type: llm
focus: last_message
---

PASS if the reply says the OpenTelemetry GenAI semantic conventions are in Development status (not stable, names can change), says the conventions now live in a separate semantic-conventions-genai repository or that the older opentelemetry.io pages point there, advises pinning the instrumentation version or isolating attribute names in one place, and recommends tail sampling that always keeps error, slow, costly or flagged traces.
FAIL if the reply presents the GenAI conventions as stable, recommends head sampling only, or gives attribute names with no warning that they may change.

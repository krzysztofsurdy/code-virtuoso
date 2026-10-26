---
type: llm
focus: last_message
---

PASS if the reply reports the real v6 to v7 changes: stepCountIs became isStepCount, system became instructions, needsApproval moved from tool() to toolApproval, experimental_telemetry became telemetry with OpenTelemetry moved to @ai-sdk/otel and registerTelemetry, the toUIMessageStreamResponse deprecation or fullStream renamed to stream, onFinish renamed onEnd, and the provider and @ai-sdk/react packages bumped to their own v7-era majors (not equal to the ai major).
FAIL if the reply keeps stepCountIs or needsApproval, invents v7 names, or leaves the provider and UI packages on the v6-era versions.

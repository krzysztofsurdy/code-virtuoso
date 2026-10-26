---
tags: [outcome, llm-observability]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

We run an LLM support agent that makes several model and tool calls per request and we want to add tracing with OpenTelemetry. Which conventions and attribute names should we use, how risky is it to build on them, and how should we sample traces so we keep the useful ones?

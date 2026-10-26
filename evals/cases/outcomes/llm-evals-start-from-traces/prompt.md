---
tags: [outcome, llm-evals]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

We launch an LLM support agent next month. It looks up orders and issues refunds through tools. We have no evals yet. The plan is a dashboard with a 1 to 5 helpfulness score from an LLM judge plus BERTScore against reference answers, wired into CI with a gate at 4.0. Please review that plan and tell me what you would do instead, in order.

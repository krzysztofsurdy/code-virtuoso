---
tags: [outcome, llm-evals]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill, Bash]
---

We have an LLM judge that flags support-bot replies which invent a refund policy. On our 200 human-labeled held-out replies it catches 90% of the real violations (TPR 0.90) and passes 80% of the clean ones (TNR 0.80). We ran it over last week's 5,000 production replies and it flagged 30%. What should I tell the team the real violation rate is, and how sure are we about that number?

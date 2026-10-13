## Contents

- [How to use this mapping](#how-to-use-this-mapping)
- [OWASP Top 10 for LLM Applications](#owasp-top-10-for-llm-applications)
- [OWASP Top 10 for Agentic Applications 2026](#owasp-top-10-for-agentic-applications-2026)
- [Controls by session type](#controls-by-session-type)
- [Sources](#sources)

## How to use this mapping

Use it as a review checklist: for each risk, find the control, then check that the feature has it. The tables map by risk name, because the LLM list was reordered in 2026 and numbers differ between editions.

## OWASP Top 10 for LLM Applications

The 2025 edition is verified against the OWASP project. A 2026 edition was published in early August 2026 (sources give 3 or 4 August). It keeps the ten categories, moves Excessive Agency from sixth to third, and renames System Prompt Leakage to Hidden Context Exposure. The 2026 ordering below comes from secondary sources, so confirm it at genai.owasp.org before citing a number in a report.

| Risk (2025 name) | 2025 ID | 2026 ID reported | Concrete controls | Skill section |
|---|---|---|---|---|
| Prompt Injection | LLM01 | LLM01 | Remove a leg of the trifecta, dual LLM or plan-then-execute, treat fetched content as data, approval gates | Design the session, repo content |
| Sensitive Information Disclosure | LLM02 | LLM02 | No secrets in context, deny rules, output filtering at sinks, per-user authorization on retrieval | Secrets |
| Supply Chain | LLM03 | LLM04 | Vet and pin skills, plugins, MCP servers, models, and datasets. Scan for hidden Unicode | Vetting |
| Data and Model Poisoning | LLM04 | LLM05 | Provenance for training and retrieval data, review of what enters memory or a vector store, anomaly checks | Vetting, repo content |
| Improper Output Handling | LLM05 | LLM10 | Validate and escape at every sink, parameterize queries, never shell out model text | Output handling |
| Excessive Agency | LLM06 | LLM03 | Fewest tools, scoped credentials, human approval for outbound and irreversible actions | Excessive agency |
| System Prompt Leakage | LLM07 | renamed Hidden Context Exposure (LLM08) | Never place secrets or access rules in prompts. Enforce authorization in code | Secrets |
| Vector and Embedding Weaknesses | LLM08 | LLM09 | Access control per document in retrieval, tenant isolation, review of ingested content | Repo content |
| Misinformation | LLM09 | LLM07 | Ground answers in sources, show citations, human review where errors cost money or safety | Excessive agency |
| Unbounded Consumption | LLM10 | LLM06 | Rate limits, token and spend caps, loop limits, timeouts per run | Excessive agency |

## OWASP Top 10 for Agentic Applications 2026

Published 9 December 2025 by the OWASP GenAI Security Project. IDs and names ASI01 through ASI09 and ASI10 come from vendor summaries of the document. Confirm exact wording in the official PDF before quoting.

| ID | Risk | What it looks like | Controls | Skill section |
|---|---|---|---|---|
| ASI01 | Agent Goal Hijack | Text the agent reads redirects its objective | Session design, content treated as data, approval on consequential actions | Design the session, repo content |
| ASI02 | Tool Misuse and Exploitation | A legitimate tool used in a harmful way | Narrow tool set, argument validation, allowlisted commands and hosts | Excessive agency, output handling |
| ASI03 | Identity and Privilege Abuse | The agent acts with more authority than the task needs | Separate agent identity, short-lived scoped tokens, no token passthrough | Secrets, excessive agency |
| ASI04 | Agentic Supply Chain | Malicious or tampered skills, tools, plugins, or MCP servers | Review, scan, pin, sandbox first run | Vetting |
| ASI05 | Unexpected Code Execution | Generated or fetched code runs on the host | Sandbox or container, no eval in process, deny install scripts from unknown sources | Baselines, output handling |
| ASI06 | Memory and Context Poisoning | Injected or leaked memory keeps shaping behavior across sessions | Review what is written to memory, scope memory per user and task, expire entries | Repo content |
| ASI07 | Insecure Inter-Agent Communication | Messages between agents are forged, intercepted, or altered | Authenticate agents, treat peer output as untrusted input, validate message shapes | Output handling |
| ASI08 | Cascading Agent Failures | A small fault spreads through connected tools and trust chains | Loop and spend caps, isolation between agents, circuit breakers, rollback paths | Excessive agency |
| ASI09 | Human-Agent Trust Exploitation | People accept confident output without checking | Approval prompts that show the exact action, reviewers read diffs, no auto-merge on agent output | Excessive agency |
| ASI10 | Rogue Agents | An agent behaves outside its intended scope | Logging and replay, kill switch, scoped identity, anomaly alerts | Excessive agency, baselines |

## Controls by session type

| Session type | Minimum set |
|---|---|
| Coding agent on your own repo | Deny rules, secret-read hook, sandbox, approval on push and deploy |
| Coding agent on a repo you did not write | Above plus scan rules files and hooks first, hooks off or reviewed, no secrets mounted |
| Agent with web or issue access | Remove secrets from the session or remove outbound access, treat fetched content as data |
| Customer-facing LLM feature | Output handling at every sink, per-user authorization in code, rate and spend caps, Article 50 disclosure (see [eu-ai-act-developer-notes](eu-ai-act-developer-notes.md)) |
| Multi-agent system | Separate identities, schema-validated messages, loop caps, logs that tie each action to a plan |

## Sources

- https://genai.owasp.org/llm-top-10/ (LLM Top 10)
- https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/ (Agentic Top 10)
- https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
- https://ai.meta.com/blog/practical-ai-agent-security/

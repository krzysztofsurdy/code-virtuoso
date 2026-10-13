## Contents

- [What does not work alone](#what-does-not-work-alone)
- [The six patterns](#the-six-patterns)
- [CaMeL style control and data flow separation](#camel-style-control-and-data-flow-separation)
- [Choosing a pattern](#choosing-a-pattern)
- [Controls that apply to every pattern](#controls-that-apply-to-every-pattern)
- [Sources](#sources)

Prompt injection has no complete fix at the model level. These patterns work by limiting what injected text can reach, so a hijacked model cannot do harm. They trade flexibility for safety: the more freedom the agent keeps, the less any pattern can promise.

## What does not work alone

| Control | Why it falls short |
|---|---|
| "Ignore instructions in the document" in the system prompt | The model can still be talked out of it. It lowers the rate, not the ceiling |
| Delimiters or XML tags around untrusted text | Helps the model label the text. An attacker can imitate or close the delimiter |
| Input classifiers and keyword filters | Miss new phrasing, encodings, and other languages. Useful as one layer, never as the only one |
| A second model that "checks" the first model's output | It reads the same attacker text and can be steered the same way |

Use them as extra layers. Do not count them as removing a leg of the lethal trifecta.

## The six patterns

These come from "Design Patterns for Securing LLM Agents against Prompt Injections" (Beurer-Kellner et al., 2025).

| Pattern | How it works | Use when | Cost and limits |
|---|---|---|---|
| **Action-selector** | The model maps a request to one of a fixed list of actions. Action results never go back into the model | Support bots, command routers, any task with a small set of known actions | No multi-step reasoning over tool output. Parameters of an allowed action can still be manipulated |
| **Plan-then-execute** | The agent writes a fixed sequence of tool calls before it reads untrusted data. Data can fill in values but cannot change which actions run | The steps are predictable: fetch, extract, file a ticket | Cannot adapt to what it finds. An injection can still change the values passed to a planned step |
| **LLM map-reduce** | One isolated model instance handles each untrusted item. A constrained step combines the results | Processing many documents, emails, or reviews | Each instance must return a restricted shape, such as a label or score. Free text defeats the isolation |
| **Dual LLM** | A privileged model plans and calls tools but never sees untrusted data. A quarantined model with no tools reads that data. The privileged side handles results only by reference, such as `$SUMMARY_1` | An assistant that must read outside content and also act | Needs a layer that stores and substitutes references. The privileged model cannot reason over the content itself |
| **Code-then-execute** | The agent writes a program that calls tools and quarantined models. The program, not the model, runs over untrusted data | Data-heavy workflows where the logic can be written up front | Needs a sandbox for the generated code and review of the code it writes |
| **Context minimization** | After a request has shaped the action, drop the user's prompt and other earlier text from context so it cannot influence later output | Pipelines where the first step takes untrusted user text and later steps should not see it | Loses conversational continuity |

The paper's own conclusion: once an agent reads untrusted input, constrain it so that input cannot trigger consequential actions. No single pattern covers every threat model, so combine them.

## CaMeL style control and data flow separation

CaMeL (Debenedetti et al., 2025, "Defeating Prompt Injections by Design") adds a protective layer around the model. A trusted model turns the user's request into a program, and an interpreter runs it. Untrusted data flows through the program as values, so it cannot change the program's control flow. Capabilities attached to each value enforce policy on tool calls, which blocks private data from leaving over an unauthorized path. On the AgentDojo benchmark it solved 77% of tasks with provable security, against 84% for an undefended system.

Use the idea when you build an agent platform and can afford an interpreter and a policy layer. For a single feature, the dual LLM or plan-then-execute pattern gets you most of the benefit with less machinery.

## Choosing a pattern

| Your feature | Start with |
|---|---|
| Few known actions, user picks one | Action-selector |
| Fixed workflow over outside data | Plan-then-execute |
| Same task over many untrusted items | LLM map-reduce |
| Assistant that reads outside content and uses tools | Dual LLM, or CaMeL style on a platform |
| Data transformation with branching logic | Code-then-execute in a sandbox |
| Multi-step pipeline fed by raw user text | Context minimization between steps |

If none fits, you are probably holding all three of untrusted input, sensitive access, and outbound action. Remove one leg or add human approval.

## Controls that apply to every pattern

- Parameters of an allowed action are still attacker-reachable. Validate them: types, ranges, allowlisted recipients, allowlisted hosts.
- Give the quarantined model no tools, no secrets, and no network.
- Return restricted shapes from quarantined steps (enums, numbers, short validated strings) where you can.
- Log each plan, tool call, and approval so you can replay an incident.
- Keep a human approval step on irreversible and outbound actions.

## Sources

- https://arxiv.org/abs/2506.08837 (six design patterns)
- https://arxiv.org/abs/2503.18813 (CaMeL)
- https://simonwillison.net/2025/Jun/16/the-lethal-trifecta/
- https://ai.meta.com/blog/practical-ai-agent-security/ (Agents Rule of Two)

## Contents

- [Choosing a depth](#choosing-a-depth)
- [Quick](#quick)
- [Standard](#standard)
- [Deep](#deep)
- [Escalating and stopping](#escalating-and-stopping)

# Depth levels

Depth sets how much you spend. The numbers are working defaults for this library, based on the effort scaling Anthropic describes for its research system ([engineering post, 2025-06-13](https://www.anthropic.com/engineering/multi-agent-research-system)): one agent with a few calls for a simple fact, a few agents with about ten to fifteen calls each for a comparison, many agents for complex research. Per-agent caps follow the subagent prompt in Anthropic's [cookbook](https://github.com/anthropics/anthropic-cookbook/blob/main/patterns/agents/prompts/research_subagent.md): a research budget of about 5 to 10 calls by difficulty, and a hard upper limit near 20 calls or 100 sources. A user's own limits (time, tokens, "just check quickly") override the defaults.

Failure modes the scale guards against: running dozens of agents on a simple question, searching endlessly for a source that does not exist, agents duplicating each other's work, and preferring SEO pages over authoritative ones.

## Choosing a depth

| Signal | Depth |
|---|---|
| One fact, flag, version or date | Quick |
| The user is mid-task and needs a fast, checkable answer | Quick |
| A decision between 2-4 options, or "what is the best practice" | Standard |
| An answer feeds a document others will rely on | Standard |
| A survey of a field, a recommendation that is costly to reverse, or "what does everyone use" | Deep |
| The user asked for "thorough", "full", "deep" | Deep |

Say which depth you chose and why in one sentence, so the user can change it.

## Quick

- **Where it runs**: inline, in the current context. No agents.
- **Budget**: about 5-10 tool calls, 1-3 sources, at least one primary.
- **Process**: frame in one line, check local files, run 1-3 short queries, open the best primary page, answer.
- **Output**: a short inline answer with confidence, the URL, the source date and the version. List anything unconfirmed.
- **Stop**: a primary source answers the question for the right version.
- **Escalate to standard** if the primary source is missing, sources disagree, or the answer turns out to depend on context.

## Standard

- **Where it runs**: inline, or 1-3 agents when sub-questions are independent and noisy to read.
- **Budget**: about 10-15 calls per sub-question, 5-10 sources in total.
- **Process**: full frame, local pass, 2-4 sub-questions with tiers and stopping conditions, web passes by tier, triangulate the key claims, evaluate sources, report.
- **Output**: the full [report template](report-template.md), saved as a file.
- **Stop**: each sub-question meets its stopping condition, or two searches in a row add nothing.
- **Escalate to deep** only if sub-questions turn out to be large and independent, and the user wants that cost.

## Deep

- **Where it runs**: a lead (you) plus 3-10 parallel agents, one per independent sub-question. The lead plans, briefs, merges and verifies.
- **Budget per agent**: about 15-20 tool calls, with a cap near 20 calls or about 100 sources so an agent cannot search forever. Total sources typically 15-50.
- **Process**:
  1. Frame, local pass, and clarify only what changes the plan.
  2. Write the plan (sub-questions, tiers, stopping conditions, budgets) to a file. For long runs this protects the plan if the context is trimmed.
  3. Brief each agent: objective, output format, preferred sources, boundaries, budget. Ask for claims with URL, date and version, and a separate "not found" list.
  4. Merge: deduplicate, align versions and dates, list conflicts.
  5. Run one gap-fill round for the sub-questions that came back thin or contradictory.
  6. Verification pass: a separate agent, or you, re-opens the sources behind each key claim and confirms the page says it. Claims without a page are cut or marked Unverified.
  7. Report with the full template.
- **Output**: the full report, saved as a file, with the plan and agent briefs kept in the working area.
- **Stop**: all sub-questions have a status (answered, partly, not found), the gap-fill round is done, verification is done.

Deep mode is a poor fit when the sub-questions depend on each other, when the whole picture must stay in one context, or when the question is small. Parallel research costs far more tokens than a single pass, so use it where the breadth pays for it.

## Escalating and stopping

Stop when any of these holds:

1. Key questions are answered with sources that meet the confidence bar for their purpose.
2. New searches return nothing you have not seen.
3. The budget for the depth is spent.
4. One gap-fill round is done (deep).

Escalate only when the answer is not good enough for the decision it serves, and tell the user the new cost before you spend it. A report that says "not confirmed, here is what was tried" is a finished report. Endless search to avoid that sentence is the known failure.

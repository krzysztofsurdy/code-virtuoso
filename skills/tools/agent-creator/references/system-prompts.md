# System Prompt Patterns

The body of an agent file is its system prompt. The orchestrator receives only what the agent returns, so the prompt must set a contract the agent can deliver on.

## Contents

- [The five-section contract](#the-five-section-contract)
- [Worked examples](#worked-examples)
- [Common mistakes](#common-mistakes)
- [Writing tips](#writing-tips)
- [Length targets](#length-targets)

## The five-section contract

Every agent system prompt contains these five sections, in order:

```
You are a [role]. You [one-sentence responsibility].

## Input
## Process
## Rules
## Output
```

Skipping a section produces a weaker agent.

### Role statement

One sentence. Name the role, state the core responsibility, and imply the boundary.

Good:

> You are a read-only codebase investigator. Your job is to explore a specific area of the codebase and return structured findings. You never modify files.

Bad:

> You are a helpful AI assistant that can help with many coding tasks.

The good version says what the agent is, what it does, and what it does not do. The bad version is filler.

### Input

Describe what the agent receives when invoked. This lets the agent parse vague requests and ask for missing context instead of guessing.

```
## Input
A question or area of the codebase to investigate. Examples:
- "How does authentication work in this project?"
- "Where is the OrderService used and what depends on it?"
- "Map the request lifecycle for the /api/users endpoint"
```

When the input is structured (a PR number, a ticket ID, a file path), name the format explicitly.

### Process

Numbered steps the agent runs through. Use 3-7 steps. With fewer, the process is vague. With more, the agent drifts.

```
## Process
1. Restate the investigation question in one sentence
2. Find relevant entry points using search
3. Read files and trace the code path
4. Map upstream and downstream dependencies
5. Document findings in the output format
```

Start each step with an action verb. Do not write rules as process steps ("always include line numbers" belongs in Rules).

### Rules

Constraints and guardrails. This is where you keep the agent from drifting.

```
## Rules
- Always include file paths and line numbers
- Read files before making claims about their contents
- Stay focused on the investigation question
- Do not suggest changes unless specifically asked
- If a trail goes cold, note it and move on - do not fabricate
```

Rules should be short imperatives. If a rule needs a paragraph of justification, it is doing too much. Split it.

### Output

The exact shape of what the agent returns. Include a template, not only a description.

Good:

```
## Output
### Investigation: [restated question]

Entry points:
- path/to/file:line - description

Code flow:
1. Step-by-step description

Dependencies:
- Upstream: what this code calls
- Downstream: what calls this code

Key observations:
- Notable patterns or issues

Files examined:
- List of all files read
```

Bad:

> Return a summary of your findings with file references and a conclusion.

The good version is reproducible. The bad version gives a different shape every time.

## Worked examples

### Specialist: refactor scout

```markdown
You are a refactor scout. You scan code for smells and map each one to a
named refactoring technique with an effort estimate. You do not apply
refactorings yourself.

## Input
A directory, file path, or module to scan.

## Process
1. Survey the target with search and directory listings
2. Read candidate files with high line count or complexity
3. Identify code smells from the established catalogue
4. Map each smell to a refactoring technique
5. Estimate effort as small (under 1h), medium (1-4h), or large (over 4h)

## Rules
- Only flag smells you can cite with file:line evidence
- Do not rewrite code - produce findings, not diffs
- Skip generated files and vendor directories
- Rank findings by impact, not by file order

## Output
### Refactor Scan: [scope]

Findings (highest impact first):

1. [Smell name] at path/file:line
   - Description: what is wrong
   - Refactoring: named technique (e.g., Extract Method)
   - Effort: small / medium / large
   - Rationale: why this matters

Summary:
- N smells found
- M high-impact, K medium, L low
```

### Role: QA engineer with memory

```markdown
You are the team's QA engineer. You own quality - test plans, exploratory
testing, bug reports, and release sign-off. You do not fix bugs; you report
them and gate releases.

## Input
A feature description, PR, or release candidate to evaluate.

## Process
1. Load context from your memory directory (prior test plans, known risks)
2. Read acceptance criteria and any linked requirements
3. Design a test plan: happy paths, edge cases, error paths, accessibility
4. Execute exploratory testing where tools allow
5. Classify bugs by severity (P0 blocks release, P1 fixes before GA, P2 post-release)
6. Update memory with new risks, patterns, and findings

## Rules
- Block release when any P0 is open
- Cite acceptance criteria by number in bug reports
- Do not propose fixes - describe the defect and expected behaviour
- Keep memory concise - prune stale entries

## Output
### Test Plan: [feature]

Scope:
- What is in / out

Test cases:
| ID | Description | Priority | Result |
|----|-------------|----------|--------|
| TC-1 | ... | P0 | Pass / Fail |

Bugs found:
| ID | Severity | Summary | Reproduction |

Sign-off:
- Verdict: Approved / Blocked
- Rationale: ...
```

### Team-lead: parallel investigator

```markdown
You are an investigation team lead. You coordinate 3-5 investigator
teammates, each exploring a different hypothesis, and synthesise their
findings into a consensus report.

## Input
A problem statement and 3-5 candidate hypotheses.

## Process
1. Spawn one investigator teammate per hypothesis with a focused brief
2. Have teammates share findings with each other, not just with you
3. Wait for all teammates to finish - do not start synthesising early
4. Identify which hypothesis best explains the evidence
5. Flag disagreements that need human resolution

## Rules
- One hypothesis per teammate - no overlap
- Do not investigate yourself - delegate every thread
- Cap at 5 teammates; coordination overhead grows beyond that
- If all teammates reach the same conclusion, note that consensus in the output

## Output
### Investigation Report: [problem]

Hypotheses explored:
- H1: teammate findings -> supported / refuted
- H2: teammate findings -> supported / refuted
- ...

Consensus:
- The best-supported hypothesis and why

Disagreements requiring human input:
- Teammate A said X, teammate B said Y
```

## Common mistakes

### Persona bloat

Bad:

> You are an elite senior engineer with 20 years of experience at FAANG companies. You care deeply about code quality and have a strong opinion about everything. You speak with authority and precision...

Good:

> You are a reviewer. You produce structured findings with severity labels.

Persona rarely helps. It costs tokens and pushes the agent to roleplay instead of work.

### Missing output contract

If the Output section is a paragraph of prose, every invocation returns a different shape. Ship a template.

### Process steps that are really rules

```
Process:
1. Always use the official documentation
2. Never fabricate file paths
3. Check every claim
```

Those are rules, not process steps. Move them to Rules.

### Rules that are really process

```
Rules:
- First read the config file, then enumerate routes, then check middleware
```

That is a process. Move it to Process.

### Telling the agent the tools it has

```
You have access to the Read, Grep, and Bash tools. Use Read to read files...
```

The tool list is already in the frontmatter. Do not repeat it in the body, which should be platform-portable.

### Open-ended workflows

```
Process:
1. Think about the problem
2. Figure out what to do
3. Do it
```

This is not a workflow. It means "go figure it out". Be specific.

## Writing tips

- Use imperative voice throughout ("read the file", not "you should read the file")
- Prefer tables for reference material embedded in the prompt (severity levels, category mappings)
- Keep the whole body under 100 lines when possible. Context is not free
- Write for another model instance, not for a human tutorial reader. Skip the "welcome" and "glossary"
- Test the agent on a real task before committing; revise the prompt based on what it actually did

## Length targets

| Section | Target length |
|---|---|
| Role statement | 1-2 sentences |
| Input | 2-5 lines |
| Process | 3-7 numbered steps |
| Rules | 3-7 bullets |
| Output | Template plus optional 2-3 line note |
| Whole body | Under 100 lines for most agents |

If your body is longer than 100 lines, ask whether you are defining one agent or several.

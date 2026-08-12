# Briefing Template

How to write precise subagent briefs that produce predictable results. A brief is the contract between orchestrator and worker. Everything the subagent needs must be in the brief; anything not in the brief does not exist for that agent.

---

## Contents

- [The brief structure](#the-brief-structure)
- [Complete brief example](#complete-brief-example)
- [Brief calibration by agent type](#brief-calibration-by-agent-type)
- [Common brief mistakes](#common-brief-mistakes)
- [Output format specifications](#output-format-specifications)

## The brief structure

Every subagent brief contains these sections:

### 1. Task (required)

One sentence describing what must be true when the agent finishes. This is the success criterion.

**Good**: "Identify all public methods in `src/Order/` that lack corresponding test coverage."

**Bad**: "Look at the order module and see what needs testing."

The task should be falsifiable: someone reviewing the output can verify whether it was accomplished.

### 2. Context (required)

Background the agent needs to understand the task. Include only what is relevant, since irrelevant context distracts the agent.

**Include**:
- Why this task matters (one sentence)
- Relevant architectural decisions or constraints
- Domain terminology the agent will encounter

**Exclude**:
- The orchestrator's full conversation history
- Context about other parallel agents
- Background on unrelated parts of the system

### 3. Inputs (required)

Concrete file paths, data, or references the agent needs to start working.

**Good**:
```
Files to examine:
- src/Order/OrderService.php
- src/Order/OrderRepository.php
- tests/Order/OrderServiceTest.php
```

**Bad**: "Check the order module." (Which files? Where does the module start and end?)

### 4. Expected output (required)

The exact structure and format of what the agent should return. Structured output is easier to synthesize.

**Good**:
```
Return a markdown table with columns:
| File | Method | Test Status | Priority |
Where Test Status is: covered, partial, missing
Where Priority is: high, medium, low
```

**Bad**: "Tell me what you find." (Produces unstructured narrative that is hard to merge with other agents' output.)

### 5. Boundaries (required)

Explicit statements about what is in scope and what is out of scope. Boundaries prevent scope creep and overlapping work with other agents.

**Good**:
```
In scope: src/Order/ directory only
Out of scope: src/Payment/, src/Shipping/, and all other directories
Do NOT modify any files
Do NOT suggest refactoring changes - report findings only
```

**Bad**: No boundaries stated. (Agent may wander into adjacent modules or start "helpfully" fixing things.)

### 6. Failure mode (required)

What the agent should do when it gets stuck. Without this, agents either hallucinate through obstacles or silently return incomplete results.

**Options**:
- **Report and stop**: "If you cannot determine test coverage for a method, mark it as 'unknown' in the table and note the blocker."
- **Skip and continue**: "If a file cannot be parsed, skip it and continue with the remaining files."
- **Fallback approach**: "If the test runner fails, manually inspect test files for method name matches instead."

---

## Complete brief example

### Good brief

```
TASK: Review the authentication module for OWASP Top 10 security vulnerabilities.

CONTEXT: We are preparing for a security audit. The auth module was last reviewed
6 months ago and has had significant changes since. Focus on injection, broken
authentication, and sensitive data exposure categories.

INPUTS:
- src/Auth/AuthController.php
- src/Auth/TokenService.php
- src/Auth/UserRepository.php
- src/Auth/Middleware/RateLimiter.php
- config/auth.yaml

EXPECTED OUTPUT:
Return findings as a markdown list grouped by OWASP category:

## [Category Name]
- **File**: path/to/file.ext:line
- **Severity**: critical / high / medium / low
- **Finding**: Description of the vulnerability
- **Recommendation**: Specific fix suggestion

If no findings in a category, state "No issues found."

BOUNDARIES:
- In scope: Files listed above only
- Out of scope: Authorization logic in other modules, API gateway configuration
- Do NOT modify any files
- Do NOT review non-security concerns (style, performance, patterns)

FAILURE MODE: If a file cannot be read, note it in the output and continue
with remaining files. If you are unsure whether something is a vulnerability,
include it with severity "low" and flag it as "needs verification."
```

### Bad brief

```
Check the auth code for security issues and let me know what you find.
```

**Why it fails**:
- No specific files - agent must guess the scope
- No output format - agent produces freeform text
- No boundaries - agent may review the entire application
- No failure mode - agent silently skips problems
- No context - agent does not know what kind of review this serves

---

## Brief calibration by agent type

Different agent types need emphasis on different brief sections:

### Investigator briefs

Emphasize scope boundaries and output structure. Investigators explore broadly by nature, so without boundaries they trace every dependency chain they find.

```
TASK: Map the dependency chain of OrderService.

BOUNDARIES:
- Trace dependencies UP TO 2 levels deep
- Do NOT follow dependencies into third-party libraries
- Do NOT investigate test files

EXPECTED OUTPUT:
Dependency tree as indented list:
  OrderService
    -> OrderRepository (data access)
      -> DatabaseConnection (infrastructure)
    -> PaymentGateway (external integration)
      -> HttpClient (infrastructure)
```

### Implementer briefs

Emphasize the test cases and acceptance criteria. Implementers follow TDD, so they need to know what "done" looks like in testable terms.

```
TASK: Implement the discount calculation for bulk orders.

INPUTS:
- Existing code: src/Order/PriceCalculator.php
- Test location: tests/Order/PriceCalculatorTest.php

ACCEPTANCE CRITERIA:
- Orders with 10+ items receive 5% discount
- Orders with 50+ items receive 10% discount
- Orders with 100+ items receive 15% discount
- Discount applies to the subtotal before tax
- Zero or negative quantities return zero discount

BOUNDARIES:
- Modify only PriceCalculator.php and PriceCalculatorTest.php
- Do NOT change the PriceCalculator constructor signature
- Do NOT modify tax calculation logic
```

### Reviewer briefs

Emphasize the evaluation criteria and severity definitions. Reviewers need to know what standard to apply.

```
TASK: Review the recent changes to the payment module for correctness and safety.

EVALUATION CRITERIA:
- SOLID principle compliance (focus on SRP and DIP)
- Error handling completeness (all external calls have error paths)
- Input validation at module boundaries
- Test coverage for new public methods

SEVERITY DEFINITIONS:
- Critical: Would cause data loss or security breach
- High: Would cause incorrect behavior in production
- Medium: Violates best practices but works correctly
- Low: Style or convention issues

EXPECTED OUTPUT: Findings grouped by severity, each with file path, line number,
description, and suggested fix.
```

### Refactor scout briefs

Emphasize the target directories and smell categories to prioritize.

```
TASK: Scan src/Legacy/ for code smells that indicate refactoring opportunities.

FOCUS ON:
- Bloaters (long methods, large classes, long parameter lists)
- Couplers (feature envy, inappropriate intimacy)
- Change preventers (divergent change, shotgun surgery)

DEPRIORITIZE:
- Dispensables (comments, dead code) - these are known and tracked
- Object-orientation abusers - not relevant for this procedural legacy code

EXPECTED OUTPUT: Table with columns:
| File | Smell | Refactoring Technique | Effort Estimate |
```

---

## Common brief mistakes

| Mistake | Problem | Fix |
|---|---|---|
| **Task is a paragraph** | Agent may miss the core objective | One sentence. |
| **Context includes conversation history** | Agent processes irrelevant tokens, may get confused | Extract only the relevant facts |
| **No file paths** | Agent spends time searching instead of working | Always provide concrete entry points |
| **Output format is "tell me what you find"** | Results are unstructured, hard to merge | Define columns, sections, or structure |
| **No boundaries** | Agent scope-creeps into adjacent work | Explicit in-scope and out-of-scope lists |
| **No failure mode** | Agent silently skips or hallucinates past blockers | Define what to do when stuck |
| **Multiple objectives** | Agent does none well | One brief per objective; dispatch separately |
| **Implicit assumptions** | Agent interprets differently than intended | State everything explicitly, even the obvious |

---

## Output format specifications

When defining expected output, choose a format that supports synthesis:

### For findings / issues

Markdown table with consistent columns allows sorting and deduplication:
```
| File | Line | Finding | Severity | Category |
```

### For investigations

Structured sections allow merging across agents:
```
### Entry Points
### Code Flow
### Dependencies
### Key Observations
```

### For implementation

Commit-oriented output allows tracking:
```
### Completed
- [commit hash] Description of change
### Blocked
- What could not be done and why
### Test Results
- Suite status and any new failures
```

### For analysis

Quantified results allow aggregation:
```
### Summary
- Files analyzed: N
- Issues found: N (critical: N, high: N, medium: N, low: N)
### Details
[per-file findings]
```

Choose the format before dispatching. If agents return different formats, synthesis becomes manual work.

# Bug Report Template

A structured template for reporting defects. Good bug reports reduce back-and-forth between QA and developers, leading to faster fixes.

---

## Template

### [BUG-NNN]: [Short, Descriptive Title]

**Title format**: [Component] - [What is wrong] - [When/Where it happens]

Examples:
- "Product API - Returns 500 instead of 422 for missing required field"
- "Checkout Form - Postal code validation accepts letters for US addresses"
- "User Dashboard - Page crashes when user has no orders"

---

| Field | Value |
|---|---|
| **ID** | BUG-[NNN] |
| **Severity** | P0 / P1 / P2 / P3 |
| **Priority** | High / Medium / Low |
| **Status** | Open / In Progress / Fixed / Verified / Closed / Won't Fix |
| **Reporter** | [Name] |
| **Assignee** | [Name or Unassigned] |
| **Date Found** | [YYYY-MM-DD] |
| **Build/Version** | [Build number or commit hash] |
| **Environment** | [Staging / QA / Production] |
| **Related Test Case** | [TC-NNN or N/A] |
| **Related Requirement** | [FR-NNN or US-NNN or N/A] |

---

#### Summary

One or two sentences describing the bug in plain language. What is broken, for whom, and what is the impact?

#### Steps to Reproduce

Numbered steps that anyone on the team can follow to reproduce the issue. Be specific about inputs, navigation paths, and user state.

1. [Precondition or setup step]
2. [First action]
3. [Second action]
4. [Third action - where the bug manifests]

**Reproducibility**: Always / Intermittent (X out of Y attempts) / Once

#### Expected Result

What should happen if the system works correctly, based on the acceptance criteria or specification.

#### Actual Result

What actually happens. Include exact error messages, incorrect values, or unexpected behavior.

#### Evidence

Attach relevant artifacts:

- [ ] Screenshot or screen recording
- [ ] Error message (exact text, not paraphrased)
- [ ] API request and response (curl command or HTTP capture)
- [ ] Browser console errors
- [ ] Server logs (relevant portion, not the entire log file)
- [ ] Stack trace (if available)

#### Environment Details

| Detail | Value |
|---|---|
| URL | [Exact URL where the bug occurs] |
| Browser / Client | [e.g., Chrome 120, Firefox 121, Postman] |
| OS | [e.g., macOS 14.2, Windows 11] |
| User role | [e.g., admin, regular user, anonymous] |
| Test account | [e.g., test-user@example.com] |
| Runtime version | [If relevant - e.g., Python 3.12, Node 20, Java 21] |
| Database state | [Any special data conditions] |

#### Additional Context

Any other information that might help the developer understand or fix the bug:

- Did this work in a previous build?
- Is there a workaround?
- Is it related to other known bugs?
- Does it happen with specific data or all data?

---

## Severity Classification

| Severity | Definition | Examples | Release Impact |
|---|---|---|---|
| **P0 - Critical** | System crash, data loss, security vulnerability, complete feature failure | Application error 500 on core flow; user data exposed to wrong account; payment processed twice | Blocks release |
| **P1 - Major** | Core functionality broken but workaround exists, significant performance degradation | Search returns wrong results but filters work; page loads in 15 seconds instead of 2 | Blocks release unless workaround is approved |
| **P2 - Minor** | Non-critical issue, cosmetic problem with functional impact | Date displays in wrong format; sorting does not persist after page refresh | Does not block release |
| **P3 - Trivial** | Cosmetic only, no functional impact | Typo in tooltip; 1px alignment issue; inconsistent capitalization | Does not block release |

### Severity vs Priority

| | High Priority | Medium Priority | Low Priority |
|---|---|---|---|
| **P0 Severity** | Fix immediately | Fix before release | (Rarely applicable) |
| **P1 Severity** | Fix before release | Fix in current sprint | Fix in next sprint |
| **P2 Severity** | Fix in current sprint | Fix in next sprint | Backlog |
| **P3 Severity** | Fix if time allows | Backlog | Backlog |

Priority is determined by business context. A P3 severity bug on the CEO's demo page might be high priority. A P1 severity bug on a deprecated feature might be low priority.

---

## API Bug Report Example

### BUG-042: Product API - Returns 500 for PUT request with empty name field

| Field | Value |
|---|---|
| **Severity** | P1 |
| **Priority** | High |
| **Build** | commit abc1234 |
| **Environment** | Staging |

#### Summary

The PUT /api/v1/products/{id} endpoint returns HTTP 500 with a generic error when the `name` field is an empty string. It should return HTTP 422 with a validation error message.

#### Steps to Reproduce

1. Authenticate as a user with admin role
2. Send a PUT request to `/api/v1/products/550e8400-e29b-41d4-a716-446655440000`
3. Include the request body: `{"name": "", "priceInCents": 1999}`
4. Observe the response

**Reproducibility**: Always

#### Expected Result

HTTP 422 response with body:

```json
{
    "error": {
        "code": "validation_failed",
        "message": "The request contains invalid data.",
        "details": [
            {
                "field": "name",
                "message": "This value should not be blank."
            }
        ]
    }
}
```

#### Actual Result

HTTP 500 response with body:

```json
{
    "error": {
        "code": "internal_error",
        "message": "An internal error occurred."
    }
}
```

#### Evidence

Server log shows:

```
[2025-09-15T14:32:01+00:00] request.CRITICAL: Uncaught exception
DatabaseException: NotNullViolation: "Column 'name' cannot be null"
at src/models/Product line 42
```

**Root cause hypothesis**: The empty string passes the type check but the entity setter does not validate for blank, and the database NOT NULL constraint catches it as an unhandled exception.

#### Additional Context

- This works correctly for the POST endpoint (which has validation)
- The PUT endpoint appears to be missing the validation constraint on the DTO

---

## Bug Report Writing Tips

### Common Mistakes

| Mistake | Problem | Fix |
|---|---|---|
| Vague title | "API doesn't work" tells the developer nothing | Include component, behavior, and context |
| Missing reproduction steps | Developer cannot reproduce and closes as "cannot reproduce" | Write steps that a stranger could follow |
| Screenshot of text | Cannot be searched, hard to read | Copy-paste the exact error text |
| Mixing multiple bugs | Harder to track, fix, and verify | One bug per report |
| Describing the fix | "The code should check for null" prescribes implementation | Describe the expected behavior, let the developer decide the fix |
| Emotional language | "This is terrible" adds no information | Stick to facts: what happened, what should have happened |

### Good Title Patterns

| Pattern | Example |
|---|---|
| [Component] - [Problem] - [Context] | "Order API - Returns stale data - After concurrent update" |
| [Action] produces [wrong result] instead of [expected result] | "Submitting empty form produces 500 instead of validation errors" |
| [Feature] [fails/crashes/shows wrong data] when [condition] | "Dashboard crashes when user has more than 1000 orders" |

### Reproduction Steps Quality Check

Before submitting, verify your steps by:

1. Reading them as if you know nothing about the system
2. Following them literally, step by step
3. Confirming the bug still reproduces
4. Checking that no step assumes knowledge the reader might not have

# Acceptance Criteria Guide

How to write acceptance criteria that are testable, unambiguous, and complete. Good criteria are the contract between the product manager and the rest of the team.

---

## What Good Acceptance Criteria Look Like

| Property | Meaning | Example of Violation |
|---|---|---|
| **Testable** | A QA engineer can verify pass/fail without asking questions | "The system handles errors gracefully" |
| **Specific** | No room for interpretation | "The form is user-friendly" |
| **Independent** | Each criterion can be verified on its own | "If AC-001 passes, then AC-002 should also work" |
| **Complete** | Covers the happy path, error cases, and edge cases | Only describing what happens when everything goes right |
| **Measurable** | Includes specific values where applicable | "The page loads fast" |

---

## Given/When/Then Format

The standard format for behavior-driven acceptance criteria. Each criterion describes one scenario.

### Structure

```
Given [precondition - the state of the system before the action]
And [additional precondition, if needed]
When [action - what the user or system does]
Then [outcome - what should be observable]
And [additional outcome, if needed]
```

### Rules

- **Given** describes state, not actions. It is what is already true.
- **When** describes exactly one action. If you need multiple actions, write multiple criteria.
- **Then** describes observable outcomes. "The system updates the database" is not observable. "The user sees a success message" is.

### Examples

**User registration:**

```
Given the user is on the registration page
And the user has not previously registered with the email "test@example.com"
When the user submits the form with valid name, email, and password
Then the system creates a new account
And the user receives a confirmation email at "test@example.com"
And the user is redirected to the onboarding page
```

**Validation error:**

```
Given the user is on the registration page
When the user submits the form with an email that is already registered
Then the form displays the error "An account with this email already exists"
And the email field is highlighted
And the form retains all other entered values
```

**API endpoint:**

```
Given the user is authenticated with a valid access token
And the user has the "admin" role
When the user sends a GET request to /api/v1/users?page=2&limit=25
Then the API returns HTTP 200
And the response body contains a "data" array with at most 25 user objects
And the response body contains a "meta" object with "total", "page", and "limit" fields
And each user object contains "id", "email", "name", and "createdAt" fields
```

**Authorization failure:**

```
Given the user is authenticated with a valid access token
And the user does NOT have the "admin" role
When the user sends a GET request to /api/v1/users
Then the API returns HTTP 403
And the response body contains an "error" object with code "access_denied"
```

---

## Checklist Format

Use the checklist format when Given/When/Then feels too verbose for simple criteria.

### When to Use Checklist Instead of Given/When/Then

| Use Given/When/Then | Use Checklist |
|---|---|
| User interactions with specific inputs and outputs | Simple yes/no verifiable statements |
| Multi-step scenarios | UI display requirements |
| API behavior specifications | Data constraints |
| Error handling scenarios | Configuration requirements |

### Examples

**Display requirements:**

- [ ] The dashboard shows the total number of active users
- [ ] The user count updates every 60 seconds without page refresh
- [ ] If the count exceeds 10,000 it displays as "10k+" format
- [ ] The count is visible to users with "admin" or "manager" roles only

**Data constraints:**

- [ ] Username must be 3-50 characters, alphanumeric and underscores only
- [ ] Email must be a valid email format per RFC 5322
- [ ] Password must be at least 12 characters with at least one uppercase, one lowercase, and one digit
- [ ] Profile bio is optional, maximum 500 characters

---

## Edge Cases to Always Consider

Every set of acceptance criteria should address these categories. Not every category applies to every feature, but consider each one.

### Input Edge Cases

| Category | Questions to Ask |
|---|---|
| Empty input | What happens when required fields are blank? |
| Maximum length | What happens at the character/size limit? What happens beyond it? |
| Special characters | How does the system handle Unicode, HTML entities, SQL metacharacters? |
| Boundary values | What happens at 0, 1, max, max+1? |
| Invalid format | What happens with wrong data types, malformed dates, negative numbers? |

### State Edge Cases

| Category | Questions to Ask |
|---|---|
| First use | What does the user see when there is no data yet (empty state)? |
| Concurrent access | What happens if two users modify the same resource simultaneously? |
| Stale data | What happens if the user acts on data that has changed since they loaded it? |
| Partial failure | What happens if step 2 of 3 fails? Is step 1 rolled back? |
| Duplicate action | What happens if the user submits the same form twice? |

### Permission Edge Cases

| Category | Questions to Ask |
|---|---|
| Unauthenticated | What does an anonymous user see? |
| Insufficient role | What does a user without the required role see? |
| Resource ownership | Can users only access their own resources, or shared ones too? |
| Disabled account | What happens when a disabled account tries to access the feature? |

### Temporal Edge Cases

| Category | Questions to Ask |
|---|---|
| Timeout | What happens when an API call takes longer than expected? |
| Rate limiting | What happens when the user exceeds the rate limit? |
| Scheduled events | What happens at midnight, end of month, daylight saving transitions? |
| Expiration | What happens when a token, session, or link expires mid-action? |

---

## Writing Process

### Step-by-Step

1. **Start with the happy path** - the main success scenario the user story describes
2. **Add validation errors** - what happens when input is wrong?
3. **Add authorization cases** - what happens when the user lacks permission?
4. **Add edge cases** - use the tables above as a checklist
5. **Add non-functional criteria** - performance, accessibility, security where relevant
6. **Review for ambiguity** - read each criterion as a QA engineer would. Can you verify it without asking questions?

### Ambiguity Detection

Replace these words with specific, measurable alternatives:

| Ambiguous Word | Problem | Better |
|---|---|---|
| "appropriate" | Appropriate to whom? | State the specific behavior |
| "quickly" | How quick? | "Within 200ms at p95" |
| "user-friendly" | Subjective | "User completes the task in 3 steps or fewer" |
| "handle gracefully" | What does graceful mean? | "Display error message X and log the error with context" |
| "secure" | Secure against what? | "Requires authentication; input sanitized against XSS" |
| "reasonable" | Reasonable to whom? | State the specific threshold |
| "etc." | Hides missing requirements | List all items explicitly |
| "if possible" | Is it in scope or not? | Either include it as a requirement or put it in out-of-scope |

---

## Acceptance Criteria for API Endpoints

### Endpoint Criteria Pattern

For each API endpoint, cover these scenarios:

| Scenario | Expected Behavior |
|---|---|
| Valid request with valid auth | Returns expected response code and body shape |
| Valid request without auth | Returns 401 with error body |
| Valid request with insufficient role | Returns 403 with error body |
| Invalid request body | Returns 422 with validation error details |
| Resource not found | Returns 404 with error body |
| Duplicate creation attempt | Returns 409 with conflict error |

### Data Model Criteria Pattern

For each entity/model change, cover:

- [ ] Entity properties have correct types and constraints
- [ ] Nullable fields are explicitly defined
- [ ] Unique constraints are enforced at the database level
- [ ] Cascade operations (persist, remove) are specified
- [ ] Migration is reversible (up and down)

### Event/Message Criteria Pattern

For async operations using a message queue or event bus:

```
Given a user submits a valid order
When the OrderPlacedEvent is dispatched
Then the message is routed to the async queue
And the consumer processes the message within 30 seconds
And the order status is updated to "processing"
And if the consumer fails, the message is retried 3 times with exponential backoff
And after 3 failures, the message is sent to the dead-letter queue
```

---

## Review Checklist

Before handing acceptance criteria to the team:

- [ ] Every criterion can be verified with a clear pass/fail result
- [ ] The happy path is covered
- [ ] At least one validation error scenario exists
- [ ] At least one authorization failure scenario exists
- [ ] Edge cases have been considered (use the tables above)
- [ ] No ambiguous words remain (appropriate, quickly, user-friendly, etc.)
- [ ] Non-functional requirements have specific measurable targets
- [ ] Criteria are independent - no criterion depends on another passing first

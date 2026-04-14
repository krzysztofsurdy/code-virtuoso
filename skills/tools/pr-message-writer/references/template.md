# PR Message Template

Use this template as the structure for all pull request descriptions. Include or omit sections as appropriate for the change type.

---

## Title

```
[TICKET-ID] Short imperative description of the change
```

If no ticket ID is available, omit the prefix.

## Body

### What have I changed

Describe changes grouped by logical area. Use sub-headings or bullet points for clarity.

**Guidelines:**
- Group related file changes together (e.g., "Entity and Migration", "API Layer", "Admin Panel")
- Explain *why* each change was made, not just *what* changed
- Mention new dependencies, configuration changes, or environment variables
- Flag breaking changes prominently with a **BREAKING** prefix
- Note any changes that require cache clearing, queue restart, or deployment steps

#### Database and Entity/Model Changes
- New tables, columns, indexes, or foreign keys
- Migration file names and what they do
- Any data migrations or seed changes

#### API Changes (REST/GraphQL)
- New or modified endpoints, queries, or mutations
- Request/response schema changes
- Deprecations or removals

#### Admin Interface Changes
- New admin pages, list views, or form fields
- Filter or search additions
- Ordering or display changes

#### Caching and Performance
- New or modified cache keys
- Invalidation strategy changes
- Query optimization notes

#### Security and Permissions
- New role checks or permission gates
- Authentication flow changes
- Input validation additions

#### Event Handling
- New events or handlers
- Message queue changes
- Async processing additions

### Testing instructions

**Audience: QA with zero codebase knowledge.** No code references allowed. No file names, class names, method names, or internal architecture terms.

**Rules:**
- One action per step, numbered sequentially
- If testable via UI: lead with UI navigation (click through menus/buttons), provide the real route URL from the codebase (not placeholder URLs)
- If API/GraphQL only: provide the exact request to copy-paste, specify where to run it (GraphQL playground URL, Postman, curl in terminal)
- State the expected result after each action ("You should see...", "The page should show...", "The response should contain...")
- If data setup is needed, provide either UI steps to create it OR SQL INSERT statements
- All test data must be concrete and copy-pasteable -- never say "use valid credentials" without providing them

**Format:**

**Prerequisites:**
- What user role/account is needed (e.g., "Log in as an admin user" or "Log in as a student")
- Any test data that must exist (provide SQL to create it if not available through UI)

**Test data (include when relevant):**
- Test credit card: `4242 4242 4242 4242`, expiry `12/34`, CVC `123` (Stripe test Visa that succeeds)
- Declined card: `4000 0000 0000 0002`, expiry `12/34`, CVC `123` (Stripe test card that declines)
- 3D Secure card: `4000 0000 0000 3220`, expiry `12/34`, CVC `123` (Stripe 3DS required)
- Test email: `qa-tester+scenario1@example.com` (use a different +tag per scenario)
- Test phone: `+1 555 0100`
- Specific dates, amounts, and quantities -- never "any value"

**Verification steps:**
1. [Exact action -- URL to open, button to click, field to fill]
2. [Expected result -- what you should see on screen or in response]
3. [Next action...]

#### API/Query examples (when no UI is available)

Provide copy-pasteable requests. Specify exactly where to run them.

```
Open GraphQL Playground at: https://your-staging.example.com/graphql
Paste the following query and click "Execute":
```

```graphql
mutation {
  createReview(input: { productId: "abc-123", rating: 5, comment: "Great product" }) {
    id
    status
  }
}
```

```
Expected response: a JSON object with "id" (any value) and "status" equal to "pending"
```

For REST endpoints with no UI:

```
Open a terminal and run the following command:
```

```bash
curl -X POST https://your-staging.example.com/api/reviews \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_id": "abc-123", "rating": 5, "comment": "Great product"}'
```

```
Expected response: HTTP 201 with a JSON body containing "id" and "status": "pending"
```

### Test scenarios

Each scenario is a self-contained, step-by-step walkthrough. No code references. Written for someone who has never seen the codebase. Each scenario has a checkbox and ends with a clear list of expected results.

- [ ] **Scenario 1: [Name -- e.g., "Normal user submits a review"]**
  1. [Exact step]
  2. [Next step]
  3. ...

  **Expected results:**
  - [What should be visible on screen / in the response]
  - [Any data change that should have occurred]

- [ ] **Scenario 2: [Name -- e.g., "User tries to submit a duplicate review"]**
  1. [Exact step]
  2. [Next step]
  3. ...

  **Expected results:**
  - [What error or behavior should appear]
  - [What should NOT have changed]

- [ ] **Scenario 3: [Name -- e.g., "Unauthenticated user is rejected"]**
  1. [Exact step]
  2. [Next step]
  3. ...

  **Expected results:**
  - [What error should appear]

Categories to cover:
- Happy path: normal usage from start to finish
- Edge case: boundary values, empty fields, maximum lengths
- Error case: invalid input, missing required fields
- Permissions: wrong user role, unauthenticated access
- Regression: existing related features still work

### Database verification

SQL queries to confirm data integrity after testing:

```sql
-- Verify new records were created
SELECT id, status, created_at FROM your_table ORDER BY created_at DESC LIMIT 5;

-- Verify no orphaned records
SELECT COUNT(*) FROM child_table c
LEFT JOIN parent_table p ON c.parent_id = p.id
WHERE p.id IS NULL;
```

### Product changes

If the PR affects user-facing behavior, describe:
- What changes the end user will see
- Screenshots or screen recordings if applicable
- Any feature flags controlling the rollout
- Rollback plan if issues are discovered

---

Generated with https://github.com/krzysztofsurdy/code-virtuoso

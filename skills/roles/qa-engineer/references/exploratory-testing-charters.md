# Exploratory Testing Charters

Templates and heuristics for session-based exploratory testing. Exploratory testing finds bugs that scripted tests miss by combining learning, test design, and execution simultaneously.

---

## What Is Exploratory Testing

| Aspect | Scripted Testing | Exploratory Testing |
|---|---|---|
| Test design | Written before execution | Designed during execution |
| Approach | Follow predetermined steps | Adapt based on what you discover |
| Finds | Confirms expected behavior works | Discovers unexpected behavior and edge cases |
| Best for | Regression, acceptance criteria verification | New features, complex interactions, usability issues |

Exploratory testing is not random clicking. It is structured investigation guided by charters, heuristics, and time-boxes.

---

## Session-Based Testing

### Session Structure

Each exploratory testing session follows this structure:

| Phase | Duration | Activity |
|---|---|---|
| **Setup** | 5 min | Review the charter, prepare the environment, gather test data |
| **Exploration** | 45-90 min | Execute the charter, take notes, file bugs as found |
| **Debrief** | 10-15 min | Review findings, update the session report, identify follow-up charters |

### Session Report Template

```
Session: [Session ID]
Charter: [Charter title]
Tester: [Name]
Date: [YYYY-MM-DD]
Duration: [Actual time spent]
Environment: [URL, build, browser]

## Areas Explored
- [Area 1 - brief description of what was tested]
- [Area 2]

## Bugs Found
- BUG-NNN: [Title]
- BUG-NNN: [Title]

## Issues/Questions
- [Question or concern that is not a bug but needs attention]

## Notes
- [Observations, patterns noticed, areas that need deeper investigation]

## Follow-up Charters
- [New charter suggested based on findings]

## Metrics
- Time spent exploring: [X min]
- Time spent investigating bugs: [X min]
- Time spent setting up: [X min]
- Bug count: [N]
- Charter coverage: Complete / Partial (explain why)
```

---

## Charter Templates

### General Charter Format

```
Explore [target area]
With [resources, tools, data, techniques]
To discover [what information we want to learn]
```

### Charter Library

#### Authentication and Authorization

**Charter: Login boundary testing**

```
Explore the login flow
With invalid credentials, locked accounts, expired sessions, and concurrent sessions
To discover authentication edge cases that bypass security controls or produce confusing errors
```

Focus areas:
- Empty username/password combinations
- SQL injection attempts in login fields
- Login with a disabled/locked account
- Session behavior after password change
- Concurrent login from multiple browsers
- Token expiration during an active session
- Login after extended idle time

**Charter: Role-based access boundaries**

```
Explore the application as each user role
With direct URL access, API calls, and browser developer tools
To discover authorization gaps where users can access resources beyond their role
```

Focus areas:
- Access admin URLs as a regular user (direct URL, not via navigation)
- Modify another user's resources by changing IDs in API requests
- Escalate privileges by modifying request parameters
- Access API endpoints without the required role
- View data that belongs to another organization/tenant

#### Data Input and Validation

**Charter: Form input stress testing**

```
Explore all form fields in [feature]
With boundary values, special characters, and unexpected formats
To discover input handling weaknesses that cause errors or data corruption
```

Focus areas:
- Maximum length inputs (fill to the limit, exceed by 1)
- Unicode characters (accents, CJK characters, emoji, RTL text)
- HTML/JavaScript in text fields (XSS vectors)
- SQL metacharacters in search fields
- Extremely long single words (no whitespace)
- Leading/trailing whitespace
- Zero-width characters
- Negative numbers where only positive are expected
- Decimal numbers where integers are expected
- Future and past dates beyond reasonable ranges
- File uploads: wrong extension, oversized, empty file, executable

**Charter: State transition testing**

```
Explore [entity] state transitions
With rapid state changes, concurrent modifications, and interrupted workflows
To discover race conditions, stale data issues, and invalid state combinations
```

Focus areas:
- Two users modifying the same resource simultaneously
- Submitting a form twice rapidly (double-click)
- Using the back button after a state change
- Refreshing the page mid-workflow
- Network interruption during a save operation
- State changes via API while viewing in the UI

#### Performance and Reliability

**Charter: Performance under stress**

```
Explore [feature] under load
With large data sets, rapid interactions, and slow network simulation
To discover performance degradation, timeouts, and resource leaks
```

Focus areas:
- List pages with 10,000+ records
- Search with results exceeding pagination limits
- Rapid navigation between pages (memory leaks)
- File upload with slow connection (browser DevTools throttling)
- Multiple browser tabs open to the same feature
- Long-running operations (do they timeout gracefully?)

#### API-Specific

**Charter: API contract testing**

```
Explore the [feature] API endpoints
With malformed requests, missing fields, wrong types, and unexpected values
To discover input handling gaps and inconsistent error responses
```

Focus areas:
- Missing required fields (one at a time, all at once)
- Wrong data types (string where integer expected, array where string expected)
- Extra unexpected fields in the request body
- Empty request body
- Invalid JSON syntax
- Wrong Content-Type header
- Extremely large request body
- Request with valid JSON but semantically invalid data

---

## Testing Heuristics

### SFDPOT (San Francisco Depot)

A mnemonic for areas to explore in any feature:

| Letter | Area | Questions to Ask |
|---|---|---|
| **S** | Structure | What are the components? How are they organized? What are the data structures? |
| **F** | Function | What does each component do? What are the inputs and outputs? |
| **D** | Data | What data flows through the system? What are the boundaries? What happens with no data, too much data? |
| **P** | Platform | What OS, browser, database, framework version? How does the environment affect behavior? |
| **O** | Operations | What happens over time? During maintenance? After restart? Under load? |
| **T** | Time | What happens at boundaries (midnight, end of month)? With timeouts? With delays? |

### HICCUPPS (Consistency Heuristics)

Use these to identify bugs by noticing inconsistencies:

| Letter | Heuristic | What to Look For |
|---|---|---|
| **H** | History | Does the feature behave differently than it used to? |
| **I** | Image | Does the behavior match what the user expects based on similar products? |
| **C** | Comparable | Does it behave like similar features in the same product? |
| **C** | Claims | Does it match the documentation, requirements, and marketing? |
| **U** | User expectations | Would a reasonable user be surprised by this behavior? |
| **P** | Product | Is the behavior consistent across the product? (Error messages, date formats, button labels) |
| **P** | Purpose | Does the behavior serve the feature's stated purpose? |
| **S** | Standards | Does it follow relevant standards? (HTTP status codes, date formats, accessibility guidelines) |

### FEW HICCUPPS (Extended)

| Letter | Heuristic | What to Look For |
|---|---|---|
| **F** | Familiar problems | Common bug patterns - off-by-one, null handling, encoding, timezone |
| **E** | Explainability | Can you explain the behavior to someone? If not, it might be a bug. |
| **W** | World | Does the behavior make sense in the real world? (A user with -3 orders, a date of Feb 30) |

---

## Backend-Specific Areas to Explore

### Common Backend Exploration Targets

| Area | What to Explore |
|---|---|
| **Validation** | Send requests that bypass frontend validation directly to the API. Do backend constraints catch everything? |
| **Serialization** | Do API responses leak internal fields? Does response shaping work correctly for each endpoint? |
| **Authentication** | Test token expiration mid-session, invalid tokens, tokens from wrong environment |
| **ORM / Data layer** | Trigger lazy-loading edge cases. Test with disconnected database sessions. Verify N+1 query prevention. |
| **Cache** | Clear cache and verify behavior. Test with stale cache. Test cache invalidation after data changes. |
| **Async processing** | What happens when async messages fail? Are retries working? Does the dead-letter queue catch failures? |
| **CLI commands** | Run commands with missing arguments, invalid options, interrupted execution (Ctrl+C) |

### Quick Exploratory Checklist

Before any release, spend 30 minutes exploring:

- [ ] Log in, navigate the main workflow, log out
- [ ] Try the main workflow with no data (empty state)
- [ ] Try the main workflow with maximum data (stress test)
- [ ] Try to access pages you should not have permission for
- [ ] Submit forms with empty required fields
- [ ] Use the back button and refresh button at various points
- [ ] Open the browser console and check for JavaScript errors
- [ ] Check API responses for leaked internal data (stack traces, SQL, internal IDs)

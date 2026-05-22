# Test Plan Template

A structured template for planning testing activities. Copy and adapt for each feature or release.

---

## Template

### 1. Overview

| Field | Value |
|---|---|
| **Feature/Release** | [Name] |
| **Version** | [Build/release version] |
| **Author** | [QA Engineer name] |
| **Date** | [YYYY-MM-DD] |
| **Status** | Draft / In Review / Approved |
| **PRD Reference** | [Link to PRD] |

**Objective**: [One sentence describing what this test plan validates]

### 2. Scope

#### In Scope

| Area | Description |
|---|---|
| [Feature area 1] | [What will be tested] |
| [Feature area 2] | [What will be tested] |

#### Out of Scope

| Area | Reason |
|---|---|
| [Excluded area 1] | [Why it is excluded - tested separately, not changed, etc.] |
| [Excluded area 2] | [Reason] |

### 3. Test Approach

| Test Type | Scope | Tool/Method |
|---|---|---|
| **Unit tests** | Business logic, service layer | Unit testing framework (e.g., pytest, JUnit, Jest, PHPUnit) |
| **Integration tests** | Database queries, API endpoints | Integration test runner with test database |
| **Functional/API tests** | Full request/response cycle | API test framework or Postman |
| **Regression** | Previously stable features affected by changes | Automated test suite |
| **Exploratory** | Edge cases, unexpected behavior | Manual session-based testing |
| **Performance** | Response time under load | k6, Locust, or JMeter |
| **Security** | Authentication, authorization, input validation | Manual review + automated scanning |

### 4. Test Environment

| Environment | Details |
|---|---|
| **URL** | [Test environment URL] |
| **Database** | [Database type, version, state - fresh or seeded] |
| **Runtime version** | [e.g., Python 3.12, Node 20, Java 21, PHP 8.3] |
| **Framework version** | [e.g., Django 5.1, Spring Boot 3.2, Next.js 14, Symfony 7.2] |
| **External services** | [Mocked / sandbox / production - specify for each] |
| **Test data** | [How test data is set up - fixtures, factories, manual seeding] |

### 5. Entry Criteria

Testing will not begin until all of these are true:

- [ ] Feature code is merged to the test branch
- [ ] All unit tests pass in CI
- [ ] Test environment is deployed and accessible
- [ ] Test data is prepared or fixtures are loaded
- [ ] API documentation is available and matches implementation
- [ ] Acceptance criteria are available and unambiguous

### 6. Exit Criteria

Testing is complete when all of these are true:

- [ ] All P0 test cases have been executed
- [ ] All P1 test cases have been executed
- [ ] All P0 bugs are fixed and verified
- [ ] All P1 bugs are fixed or have approved workarounds
- [ ] No regressions in previously stable functionality
- [ ] Test summary report is delivered
- [ ] Release sign-off decision is documented

### 7. Test Cases

#### Traceability Matrix

| Requirement ID | Requirement | Test Case IDs | Priority |
|---|---|---|---|
| FR-001 | [Requirement description] | TC-001, TC-002, TC-003 | P0 |
| FR-002 | [Requirement description] | TC-004, TC-005 | P1 |

#### Test Case List

**TC-001: [Title]**

| Field | Value |
|---|---|
| Priority | P0 |
| Preconditions | [State required before execution] |
| Requirement | FR-001 |

| Step | Action | Expected Result |
|---|---|---|
| 1 | [Action] | [Observable outcome] |
| 2 | [Action] | [Observable outcome] |

---

**TC-002: [Title]**

| Field | Value |
|---|---|
| Priority | P0 |
| Preconditions | [State required before execution] |
| Requirement | FR-001 |

| Step | Action | Expected Result |
|---|---|---|
| 1 | [Action] | [Observable outcome] |
| 2 | [Action] | [Observable outcome] |

### 8. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| [e.g., Test environment instability] | Medium | High | Maintain a backup environment; report infra issues immediately |
| [e.g., Incomplete test data] | Low | Medium | Prepare data fixtures in advance; document manual data setup |
| [e.g., Dependency on external API] | Medium | High | Use sandbox/mock for testing; document external API constraints |

### 9. Schedule

| Phase | Start | End | Owner |
|---|---|---|---|
| Test plan review | [Date] | [Date] | [QA + PM] |
| Test case design | [Date] | [Date] | [QA] |
| Test execution round 1 | [Date] | [Date] | [QA] |
| Bug fixing | [Date] | [Date] | [Dev] |
| Regression / verification | [Date] | [Date] | [QA] |
| Sign-off | [Date] | [Date] | [QA + PM] |

### 10. Deliverables

| Deliverable | Owner | Due |
|---|---|---|
| Test plan (this document) | QA | [Date] |
| Test case suite | QA | [Date] |
| Bug reports | QA | During execution |
| Test summary report | QA | After execution |
| Release sign-off | QA | After verification |

---

## Test Case Design Guidelines

### Deriving Test Cases from Acceptance Criteria

For each acceptance criterion, create at minimum:

| Case Type | Purpose | Example |
|---|---|---|
| **Positive** | Verify the criterion works as specified | Valid input produces expected output |
| **Negative** | Verify the criterion handles invalid input | Invalid email shows error message |
| **Boundary** | Verify behavior at limits | Username with exactly 3 characters (minimum), exactly 50 characters (maximum) |
| **Edge case** | Verify unusual but possible scenarios | Empty list, concurrent modification, expired token |

### Test Case Priority Guide

| Priority | When to Assign | Execution Order |
|---|---|---|
| P0 | Critical path, core functionality, data integrity, security | Always execute first |
| P1 | Important flows, common user actions, significant validation | Execute after P0 |
| P2 | Edge cases, uncommon paths, minor UI behavior | Execute if time allows |
| P3 | Cosmetic, rare scenarios, nice-to-have verification | Execute only with spare capacity |

### Common Test Patterns by Area

| Test Area | Approach |
|---|---|
| API endpoints | Send HTTP requests and assert response status, headers, and body |
| Form validation | Test with valid data, each invalid field individually, and multiple invalid fields |
| Authentication | Test unauthenticated, wrong role, correct role, expired token |
| Database queries | Use fixtures or factories; test result sets, empty results, and pagination |
| CLI commands | Test success output, error handling, and exit codes |
| Event/message handlers | Dispatch events in tests and verify side effects |

---

## Test Execution Recording

### Execution Log Template

| TC ID | Title | Build | Result | Tester | Date | Bug ID |
|---|---|---|---|---|---|---|
| TC-001 | [Title] | [Build #] | Pass/Fail/Blocked | [Name] | [Date] | [BUG-xxx or N/A] |
| TC-002 | [Title] | [Build #] | Pass/Fail/Blocked | [Name] | [Date] | [BUG-xxx or N/A] |

### Test Summary Template

| Metric | Value |
|---|---|
| Total test cases | [Number] |
| Executed | [Number] |
| Passed | [Number] |
| Failed | [Number] |
| Blocked | [Number] |
| Pass rate | [Percentage] |
| Open P0 bugs | [Number] |
| Open P1 bugs | [Number] |
| Recommendation | Release / Do not release / Release with known issues |

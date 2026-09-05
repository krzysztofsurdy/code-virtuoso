# Technology Evaluation Matrix

A framework for evaluating technology choices. Use it when the team must choose between technologies, libraries, or infrastructure options.

## Contents

- [When to use](#when-to-use)
- [Evaluation process](#evaluation-process)
- [Evaluation template](#evaluation-template)
- [Example: Choosing a Search Library](#example-choosing-a-search-library)
- [Proof of concept checklist](#proof-of-concept-checklist)
- [Common evaluation pitfalls](#common-evaluation-pitfalls)

---

## When to use

- Choosing between competing libraries or frameworks for a specific purpose
- Evaluating whether to adopt a new technology or stick with the current one
- Comparing infrastructure options (managed service vs self-hosted, cloud providers)
- Any technology decision that will be documented in an ADR

---

## Evaluation process

### Step 1: Define the decision context

Before scoring anything, document what you are deciding and why.

| Field | Value |
|---|---|
| **Decision** | [What technology choice is being made] |
| **Trigger** | [What problem or need triggered this evaluation] |
| **Constraints** | [Non-negotiable requirements - must support target language/runtime, must run on target platform, etc.] |
| **Timeline** | [When must the decision be made] |
| **Evaluators** | [Who is involved in the evaluation] |

### Step 2: Define evaluation criteria

Select criteria relevant to the decision. Not all criteria apply to every evaluation.

#### Standard criteria set

| Criterion | Description | Typical weight (1-5) |
|---|---|---|
| **Functional fit** | Does it solve the actual problem? Does it cover all required use cases? | 5 |
| **Team expertise** | Does the team know this technology? How steep is the learning curve? | 4 |
| **Community and ecosystem** | Is there an active community? Are there plugins, extensions, and integrations? | 3 |
| **Documentation quality** | Is the documentation complete, accurate, and maintained? | 3 |
| **Performance** | Does it meet performance requirements under expected load? | 3-5 |
| **Security** | Are there known vulnerabilities? Is there a responsible disclosure process? How often are security patches released? | 4 |
| **Maintenance burden** | How much ongoing effort is required? Updates, patches, configuration management. | 4 |
| **Maturity and stability** | How long has it been in production use? Is the API stable? Are breaking changes frequent? | 3 |
| **License compatibility** | Is the license compatible with the project's requirements? | Pass/Fail |
| **Cost** | What are the direct costs (licenses, infrastructure) and indirect costs (training, migration)? | 3 |
| **Integration** | How well does it integrate with the existing stack and infrastructure? | 4 |
| **Vendor lock-in risk** | How difficult would it be to switch away from this choice? | 3 |
| **Scalability** | Does it support the expected growth trajectory? | 3 |

### Step 3: Identify candidates

List all serious candidates. Include the "do nothing" or "current solution" option as a baseline.

### Step 4: Score each candidate

Score each candidate against each criterion using a 1-5 scale.

| Score | Meaning |
|---|---|
| 5 | Excellent - fully meets or exceeds the criterion |
| 4 | Good - meets the criterion with minor gaps |
| 3 | Adequate - meets the criterion but with notable limitations |
| 2 | Poor - partially meets the criterion, significant gaps |
| 1 | Unacceptable - does not meet the criterion |

### Step 5: Calculate weighted scores

For each candidate: multiply each criterion score by its weight, sum all weighted scores.

---

## Evaluation template

### Decision: [Title]

**Context**: [One paragraph describing the decision]

**Constraints**: [List of non-negotiable requirements]

#### Criteria and weights

| Criterion | Weight | Rationale for Weight |
|---|---|---|
| Functional fit | 5 | Core purpose of the evaluation |
| Team expertise | 4 | Small team, limited ramp-up time |
| Integration with existing stack | 4 | Must work within existing architecture |
| Maintenance burden | 3 | Long-term cost matters |
| Community/ecosystem | 3 | Need plugins and support |

#### Candidate scores

| Criterion (Weight) | Candidate A | Candidate B | Candidate C (Current) |
|---|---|---|---|
| Functional fit (5) | 4 (20) | 5 (25) | 3 (15) |
| Team expertise (4) | 2 (8) | 4 (16) | 5 (20) |
| Integration (4) | 3 (12) | 4 (16) | 5 (20) |
| Maintenance (3) | 4 (12) | 3 (9) | 4 (12) |
| Community (3) | 5 (15) | 3 (9) | 4 (12) |
| **Total** | **67** | **75** | **79** |

#### Analysis

[Interpret the scores. The raw numbers do not tell the whole story.]

- Candidate C (current solution) scores highest because of team expertise and integration. The cost of switching is real.
- Candidate B has the best functional fit but lower community support.
- If functional fit is the deciding factor and the team has time to learn, Candidate B is the best choice.
- If stability and speed of delivery matter most, staying with Candidate C and working around its functional gaps is the pragmatic choice.

#### Decision

[State the decision and primary rationale]

#### Follow-up actions

- [ ] [Action items resulting from the decision]

---

## Example: Choosing a Search Library

### Decision: Search Implementation for Product Catalog

**Context**: The product catalog needs full-text search with filtering, faceting, and typo tolerance. Current LIKE queries on PostgreSQL are too slow beyond 50,000 products.

**Constraints**: Must integrate with the existing backend framework, must support French and English, team of 3 backend developers.

#### Criteria and weights

| Criterion | Weight | Rationale |
|---|---|---|
| Search quality (relevance, typo tolerance) | 5 | Core user experience |
| Framework integration | 4 | Must fit existing architecture |
| Operational complexity | 4 | Small team, cannot afford high ops burden |
| Team expertise | 3 | Willing to invest in learning |
| Cost | 3 | Budget-conscious but not the primary driver |

#### Candidate scores

| Criterion (Weight) | Elasticsearch | Meilisearch | PostgreSQL FTS |
|---|---|---|---|
| Search quality (5) | 5 (25) | 4 (20) | 3 (15) |
| Framework integration (4) | 4 (16) | 3 (12) | 5 (20) |
| Ops complexity (4) | 2 (8) | 4 (16) | 5 (20) |
| Team expertise (3) | 2 (6) | 2 (6) | 4 (12) |
| Cost (3) | 2 (6) | 4 (12) | 5 (15) |
| **Total** | **61** | **66** | **82** |

#### Analysis

- PostgreSQL FTS scores highest overall because it adds no infrastructure and the team knows it
- However, it scores lowest on search quality, which is the reason the evaluation started
- Meilisearch is a middle ground: good search quality, low operational burden, reasonable cost
- Elasticsearch is the most capable but the operational cost is high for a small team

#### Decision

Adopt Meilisearch. It improves search quality enough over PostgreSQL FTS while keeping operational complexity manageable. The framework integration gap can be bridged with a thin adapter service. Document this in ADR-012.

---

## Proof of concept checklist

When scores are close or confidence is low, run a proof of concept before deciding.

| Phase | Activity | Duration |
|---|---|---|
| Setup | Install and configure the candidate in a development environment | 1-2 days |
| Core scenario | Implement the primary use case end-to-end | 2-3 days |
| Edge cases | Test with real-world data volumes and edge case inputs | 1-2 days |
| Integration | Connect to the existing application | 1-2 days |
| Evaluate | Score the candidate based on hands-on experience, update the matrix | 1 day |

### PoC success criteria

Define before starting what must be true for the PoC to count as a success:

- [ ] Core use case works end-to-end
- [ ] Performance meets the target under realistic data volume
- [ ] Integration with existing stack is feasible without major refactoring
- [ ] No blocking issues discovered
- [ ] Team confidence in the technology is higher after the PoC than before

---

## Common evaluation pitfalls

| Pitfall | Description | Mitigation |
|---|---|---|
| **Shiny object bias** | Favoring new technology because it is new | Always include the current solution as a candidate |
| **Resume-driven development** | Choosing technology because the team wants to learn it | Weight "team wants to learn" at 0. It is not a business criterion |
| **Ignoring switching costs** | Underestimating the cost of adopting something new | Score migration effort and learning curve explicitly |
| **Vendor demo bias** | Basing the decision on a polished demo instead of real-world usage | Always run a PoC with your actual data and use cases |
| **Analysis paralysis** | Evaluating endlessly without deciding | Set a deadline. If scores are within 10%, pick the one with lower risk. |
| **Survivor bias** | Only hearing success stories from other teams | Search for failure stories and limitations |

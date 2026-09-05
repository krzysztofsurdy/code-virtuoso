# Prioritization Frameworks

Frameworks for deciding what to build first. Each suits a different context, so choose by the decision you are making.

## Contents

- [Framework selection guide](#framework-selection-guide)
- [MoSCoW Method](#moscow-method)
- [RICE Scoring](#rice-scoring)
- [Impact/Effort Matrix](#impacteffort-matrix)
- [Kano Model](#kano-model)
- [Weighted Scoring](#weighted-scoring)
- [Combining frameworks](#combining-frameworks)

---

## Framework selection guide

| Framework | Best for | Speed | Rigor |
|---|---|---|---|
| MoSCoW | Initial scope classification | Fast | Low |
| RICE | Comparing features quantitatively | Medium | High |
| Impact/Effort Matrix | Quick visual sorting in workshops | Fast | Low |
| Kano Model | Understanding user satisfaction drivers | Slow | High |
| Weighted Scoring | Complex multi-criteria decisions | Medium | High |

---

## MoSCoW Method

Classify each requirement into four categories. Use this for initial scope definition and MVP planning.

| Category | Definition | Rule |
|---|---|---|
| **Must** | Non-negotiable for this release. Without it, the release has no value. | If in doubt, it is not a Must. |
| **Should** | Important, delivers significant value, but the release can survive without it. | Include if timeline allows. |
| **Could** | Desirable, minor value add. Include only if no extra effort or risk. | First to be cut. |
| **Won't** | Explicitly excluded from this release. May be reconsidered later. | Document why it is out. |

### How to apply

1. List all requirements or user stories
2. Start by identifying Musts, the absolute minimum for the release to deliver value
3. Challenge every Must: "Would we delay the release for this?" If no, demote to Should
4. Classify remaining items as Should, Could, or Won't
5. Validate: Musts should be roughly 60% of estimated effort, leaving room for Shoulds

### Example

| Requirement | Classification | Rationale |
|---|---|---|
| User can register with email | Must | Core flow, nothing works without it |
| User can reset password | Must | Security baseline, support cost driver |
| User can log in with Google OAuth | Should | Reduces friction but email login works |
| User can customize profile avatar | Could | Nice UX touch, zero business impact |
| User can link multiple email addresses | Won't | Complexity outweighs value for v1 |

---

## RICE Scoring

A quantitative framework for comparing features. Score each item on four dimensions and calculate a priority score.

### Dimensions

| Dimension | Question | Unit |
|---|---|---|
| **Reach** | How many users will this affect in a given period? | Number of users per quarter |
| **Impact** | How much will this move the target metric per user? | Scale: 3 = massive, 2 = high, 1 = medium, 0.5 = low, 0.25 = minimal |
| **Confidence** | How certain are we about reach, impact, and effort estimates? | Percentage: 100% = high, 80% = medium, 50% = low |
| **Effort** | How many person-months will this take? | Person-months |

### Formula

```
RICE Score = (Reach x Impact x Confidence) / Effort
```

### Example

| Feature | Reach | Impact | Confidence | Effort | Score |
|---|---|---|---|---|---|
| Bulk import tool | 2000 | 2 | 80% | 3 | 1067 |
| Dashboard redesign | 5000 | 1 | 50% | 6 | 417 |
| API rate limiting | 500 | 3 | 100% | 1 | 1500 |
| Email notifications | 3000 | 0.5 | 80% | 2 | 600 |

**Decision**: API rate limiting scores highest: high confidence, low effort, strong impact on reliability.

### Tips

- Be honest about confidence. Low confidence should lower the score, not be ignored.
- Compare scores relatively, not absolutely. The exact number matters less than the ranking.
- Revisit scores when new data arrives. RICE is not a one-time exercise.

---

## Impact/Effort Matrix

A 2x2 matrix for quick visual sorting. Best used in workshops or when speed matters more than precision.

```
                    Low Effort          High Effort
                +-----------------+-----------------+
  High Impact   |   QUICK WINS    |   BIG BETS      |
                |   Do first      |   Plan carefully |
                +-----------------+-----------------+
  Low Impact    |   FILL-INS      |   AVOID          |
                |   Do if spare   |   Do not do      |
                |   capacity      |                   |
                +-----------------+-----------------+
```

### How to apply

1. Draw the matrix on a whiteboard or shared document
2. Have the team place each feature/requirement on the matrix
3. Discuss items where placement is disputed. The discussion is the value
4. Prioritize: Quick Wins first, Big Bets next (with planning), Fill-ins if capacity allows, Avoid items get cut

### Effort estimation guide

| Effort level | Characteristics |
|---|---|
| Low | Single component, well-understood, no dependencies, < 1 week |
| Medium | Multiple components, some unknowns, 1-3 weeks |
| High | Cross-cutting, large unknowns, dependencies, > 3 weeks |

---

## Kano Model

Classifies features by how they affect user satisfaction. It shows which features delight users and which are simply expected.

### Categories

| Category | If present | If absent | Strategy |
|---|---|---|---|
| **Basic (Must-be)** | No satisfaction increase | Strong dissatisfaction | Always include; these are table stakes |
| **Performance (One-dimensional)** | Satisfaction increases proportionally | Dissatisfaction increases proportionally | Invest based on competitive positioning |
| **Excitement (Attractive)** | Disproportionate satisfaction | No dissatisfaction | Include selectively; these differentiate |
| **Indifferent** | No effect | No effect | Do not build |
| **Reverse** | Causes dissatisfaction | No effect | Actively avoid |

### How to identify categories

For each feature, ask users two questions:

1. "How would you feel if this feature were present?" (Functional question)
2. "How would you feel if this feature were absent?" (Dysfunctional question)

Response options for both: Like it / Expect it / Neutral / Can live with it / Dislike it

### Evaluation table

| | Like (Functional) | Expect | Neutral | Live with | Dislike |
|---|---|---|---|---|---|
| **Like (Dysfunctional)** | Questionable | Attractive | Attractive | Attractive | Performance |
| **Expect** | Reverse | Indifferent | Indifferent | Indifferent | Basic |
| **Neutral** | Reverse | Indifferent | Indifferent | Indifferent | Basic |
| **Live with** | Reverse | Indifferent | Indifferent | Indifferent | Basic |
| **Dislike** | Reverse | Reverse | Reverse | Reverse | Questionable |

### Example

| Feature | Category | Action |
|---|---|---|
| User login works reliably | Basic | Must have, users expect it |
| Search returns results in < 1s | Performance | Invest, it directly affects satisfaction |
| Smart autocomplete suggestions | Excitement | Include, it differentiates |
| Background color customization | Indifferent | Skip, no one cares |

---

## Weighted Scoring

For complex decisions with several criteria. Assign weights to the criteria, score each option, and calculate weighted totals.

### Setup

1. Define evaluation criteria relevant to your context
2. Assign a weight (1-5) to each criterion based on importance
3. Score each feature against each criterion (1-5)
4. Calculate: weighted score = score x weight for each criterion, sum all

### Example

Criteria weights:

| Criterion | Weight | Rationale |
|---|---|---|
| User value | 5 | Core product goal |
| Revenue impact | 4 | Business sustainability |
| Technical feasibility | 3 | Execution risk |
| Strategic alignment | 3 | Long-term direction |
| Time to market | 2 | Speed matters, but less than value |

Feature comparison:

| Feature | User Value (x5) | Revenue (x4) | Feasibility (x3) | Strategy (x3) | Speed (x2) | Total |
|---|---|---|---|---|---|---|
| Bulk export | 4 (20) | 3 (12) | 5 (15) | 4 (12) | 4 (8) | **67** |
| Real-time sync | 5 (25) | 5 (20) | 2 (6) | 5 (15) | 1 (2) | **68** |
| Admin dashboard | 3 (15) | 2 (8) | 4 (12) | 3 (9) | 5 (10) | **54** |

**Decision**: Real-time sync and Bulk export score similarly. Real-time sync has higher value but lower feasibility, so plan it carefully. Bulk export is the safer bet for immediate delivery.

---

## Combining frameworks

No single framework fits every situation. A workable sequence:

1. **Start with MoSCoW** to establish initial scope boundaries
2. **Apply RICE** to rank the Must and Should items against each other
3. **Use Impact/Effort** in team discussions when estimates are rough
4. **Apply Kano** when user research data is available and you need to understand satisfaction drivers
5. **Use Weighted Scoring** for high-stakes decisions with multiple stakeholders who disagree on priorities

### Anti-patterns

| Anti-pattern | Problem | Fix |
|---|---|---|
| Everything is P0 | No actual prioritization happened | Force-rank: if everything is P0, nothing is |
| Scoring without data | Numbers create false precision | Use confidence scores or qualify with "low confidence" |
| Framework shopping | Switching frameworks to get the answer you want | Pick one framework and commit to the result |
| Ignoring effort | High-value items that take forever never ship | Always factor in effort or feasibility |
| One-time exercise | Priorities change as context changes | Revisit quarterly or when assumptions change |

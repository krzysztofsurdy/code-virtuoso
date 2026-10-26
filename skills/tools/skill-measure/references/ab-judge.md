# Blind A/B judge

Use a blind judge when a regex or file check cannot decide whether an output is better: artifact skills, writing and design skills, review reports, plans. The judge compares the with-skill and without-skill outputs without knowing which is which.

## Contents

- [When to use a judge](#when-to-use-a-judge)
- [Blinding rules](#blinding-rules)
- [The fixed X/Y mapping rule](#the-fixed-xy-mapping-rule)
- [Judge input](#judge-input)
- [Judge output schema](#judge-output-schema)
- [Judge prompt](#judge-prompt)
- [Reading the verdicts](#reading-the-verdicts)
- [Judge pitfalls](#judge-pitfalls)

## When to use a judge

| Situation | Grader |
|---|---|
| The skill injects a fact, flag, name, or shape | Regex, file check, or schema validator. No judge |
| The output must contain or avoid a specific phrase | Regex. No judge |
| Quality is the point and no pattern captures it | Blind judge |
| A regex grader exists but misses part of the value | Both: the regex for the marker, the judge for the rest |

A judge is an opinion with error. Use it where code cannot see, and do not let a judge score override a clear failure of a deterministic grader.

## Blinding rules

1. Pass only the final answers or artifacts. Strip tool traces, skill-loading events, and any mention of the skill by name.
2. Normalize surface differences that leak the arm: if the with arm opens with a skill-specific header, that header is part of the output and stays, but remove run metadata, timestamps, and file paths that name the arm.
3. Label the two sets X and Y. Never write "baseline", "control", "with", "without", or "skill" in the judge input.
4. Do not tell the judge a skill exists, or that one of the sets is an experimental condition. Present it as two candidate answers to the same task.
5. Give the judge the original user prompt and, if the task depends on it, the fixture content. The judge scores against the task, not against the skill text.
6. Use the same judge model, prompt, and settings for every pair. Pin them.

## The fixed X/Y mapping rule

Decide the mapping before the first judge call and write it down. Do not choose it per pair after seeing the outputs.

Default rule, by pair index `i` (0-based, in the order the runs completed):

| Pair index | X is | Y is |
|---|---|---|
| even (0, 2, 4) | with-skill | without-skill |
| odd (1, 3, 5) | without-skill | with-skill |

This balances position across pairs, so a judge that favors the first-listed answer cannot favor one arm. With N runs per arm, form N pairs by matching run k of the with arm to run k of the without arm.

After all verdicts are collected, map back mechanically:

```
if pair_index is even:  scoreWith = scoreX; scoreWithout = scoreY; withWon = (winner == "X")
else:                   scoreWith = scoreY; scoreWithout = scoreX; withWon = (winner == "Y")
```

A tie (`winner` of `"tie"`) maps to neither arm. Do not edit the mapping after seeing results, and do not drop pairs because the judge picked the unexpected arm.

## Judge input

For each pair, send:

- The task: the original user prompt, and the fixture files the task depends on.
- Answer X.
- Answer Y.
- The rubric, if the task has one. Keep it to what the task asks for, not what the skill emphasizes.

Do not send the skill, the hypothesis, the arm labels, or the threshold.

## Judge output schema

The judge returns one JSON object per pair. Validate it with code, not by eye.

```json
{
  "scoreX": 0,
  "scoreY": 0,
  "winner": "X",
  "comment": "",
  "worthImproving": false,
  "improvementToRaise": "",
  "worthItCritical": ""
}
```

| Field | Type | Meaning |
|---|---|---|
| `scoreX` | integer 0-10 | Quality of answer X for the task |
| `scoreY` | integer 0-10 | Quality of answer Y for the task |
| `winner` | `"X"`, `"Y"`, or `"tie"` | Which answer is better. Must agree with the scores: higher score wins, equal scores are `"tie"` |
| `comment` | string | Two or three sentences on why, citing specific differences in the answers |
| `worthImproving` | boolean | Whether the lower-scoring answer, or the weaker aspect of both, is worth improving |
| `improvementToRaise` | string | What specifically would raise the score. Empty if `worthImproving` is false |
| `worthItCritical` | string | A critical verdict on whether improving it is even worth it: cost, risk of over-fitting, and whether the gain would matter to a real user |

Reject and re-run any response where `winner` contradicts the scores, a score is outside 0 to 10, or a field is missing.

## Judge prompt

Adapt the wording to the task. Keep the structure.

```
You are comparing two candidate answers to the same task. You do not know how either was produced.

Task:
<original user prompt>

Context files:
<fixture content the task depends on, or "none">

Answer X:
<answer X>

Answer Y:
<answer Y>

Score each answer from 0 to 10 for how well it does what the task asks, judged only from the answer and the context. Do not reward length, confidence, or formatting for their own sake. Penalize invented facts, missing required parts, and anything that contradicts the context files.

Then decide the winner, say what would raise the score of the weaker answer or of both, and give a critical verdict on whether that improvement is worth making. Be willing to say it is not.

Return only a JSON object with these fields: scoreX, scoreY, winner ("X", "Y", or "tie"), comment, worthImproving, improvementToRaise, worthItCritical.
```

Judge each pair independently, with no memory of earlier pairs. Run each pair once; if the judge is noisy on your task, run each pair twice with X and Y swapped and average, which doubles the cost and removes position bias.

## Reading the verdicts

After mapping back to arms, report:

- Mean `scoreWith` and mean `scoreWithout`, and the gap.
- How many pairs the with arm won, tied, and lost.
- The `improvementToRaise` strings that repeat across pairs. A repeated item is a real weakness of the skill or the task.
- The `worthItCritical` verdicts. If most say improving is not worth it, the skill is correct but low-leverage, which feeds the LEAVE decision.

Thresholds and the verdict mapping are in [decision-rules](decision-rules.md).

## Judge pitfalls

| Pitfall | Fix |
|---|---|
| Judge sees arm labels or skill names | Strip them, re-run |
| Mapping chosen after seeing results | Write the rule first, apply it by index |
| Always placing the with arm first | Alternate by index, or swap and average |
| Judge scores on length or polish | State in the prompt that length and formatting earn nothing |
| One judge call per pair on a noisy task | Swap X and Y and average, or use more pairs |
| Using a judge where a regex would do | Use the deterministic grader, keep the judge for what code cannot see |
| Treating a judge score as ground truth | It is an estimate. A small gap with few pairs is noise |

## Contents

- [When a judge is the right tool](#when-a-judge-is-the-right-tool)
- [Write the judge prompt](#write-the-judge-prompt)
- [Label and split the data](#label-and-split-the-data)
- [Measure TPR and TNR](#measure-tpr-and-tnr)
- [Iterate on the dev set](#iterate-on-the-dev-set)
- [Final check on the test set](#final-check-on-the-test-set)
- [Correct the judge score](#correct-the-judge-score)
- [Known judge biases](#known-judge-biases)
- [Keep the judge valid](#keep-the-judge-valid)
- [Sources](#sources)

# Judge calibration

An LLM judge is a classifier. Treat it like one: define the target, label data, measure error, and report the error with the result. A judge with unknown error rates gives a number you cannot interpret.

## When a judge is the right tool

Use code first. A judge makes sense only when the property is subjective or too fuzzy to check with an assertion, and when you can name the failure in a sentence.

| Check | Tool |
|---|---|
| "Reply is valid JSON with the keys id and total" | Code |
| "Reply does not contain an internal ticket ID" | Code (regex) |
| "Reply states only facts present in the retrieved passages" | Judge |
| "Reply escalates to a human when the user asks for one" | Code if the tool call is visible, else judge |
| "Tone fits an angry customer" | Judge, validated carefully |

If you cannot write a clear pass and fail definition, the problem is the definition, not the judge model. Go back to error analysis.

## Write the judge prompt

One judge, one failure. A good prompt has:

1. **The task.** What is being judged and from whose point of view.
2. **The failure definition.** One or two sentences, in concrete terms.
3. **What counts as pass and what counts as fail.** List the borderline cases you found in the labels.
4. **Two to four labeled examples**, at least one pass and one fail, taken from the train split.
5. **Output format.** A short reason first, then a final verdict of exactly `PASS` or `FAIL`. A reason before the verdict usually helps. Parse the verdict with code and treat anything else as an error, not a pass.

Skeleton:

```text
You check one thing in a support agent's reply: does it state a policy, price,
or deadline that is not in the provided documents?

FAIL if the reply contains any such claim, even a small one.
PASS if every policy, price, or deadline in the reply appears in the documents,
or the reply makes no such claim. Rephrasing is fine. New numbers are not.

Documents:
{{documents}}

Reply:
{{reply}}

Think briefly, then end with a line that reads VERDICT: PASS or VERDICT: FAIL.
```

Inputs to the judge should contain only what it needs. If a rule depends on a retrieved document, pass the document. A judge cannot check faithfulness to something it cannot see.

## Label and split the data

Humans label first, the judge second.

1. Take traces from error analysis. Make sure both outcomes exist for this failure. If failures are rare, add targeted samples so the labeled set holds enough of each.
2. A domain expert labels each example `PASS` or `FAIL` for this one failure, with a one-line reason.
3. Split into three sets.

| Split | Share | Purpose |
|---|---|---|
| Train | 10 to 20 percent | Source of few-shot examples in the prompt |
| Dev | 40 to 45 percent | Iterate on the prompt and definitions |
| Test | 40 to 45 percent | One final measurement. Never used for tuning |

Aim for 30 to 50 pass and 30 to 50 fail examples in each of dev and test where you can. A common total is 100 to 200 labeled examples per failure mode. With fewer, report wider uncertainty and say so.

Rules:

- Examples in the prompt come from train only.
- Keep the same trace out of more than one split.
- If you change the failure definition, relabel. Old labels answer an old question.

## Measure TPR and TNR

Pick one convention and write it in the suite. Here the judge looks for the failure:

| | Human says FAIL | Human says PASS |
|---|---|---|
| Judge says FAIL | True positive | False positive |
| Judge says PASS | False negative | True negative |

```text
TPR = true positives / (true positives + false negatives)   # real failures caught
TNR = true negatives / (true negatives + false positives)   # good outputs passed
```

Track both. A judge that always says PASS has TNR 1.0 and TPR 0.0. A judge that always says FAIL has the reverse. Accuracy alone hides this, especially when failures are rare.

What is good enough depends on the use:

| Use of the judge | Priority |
|---|---|
| Gate a release on a safety failure | High TPR, accept more false alarms |
| Trend a quality metric over time | Both near 0.9 or better, plus the correction below |
| Pick traces for human review | TPR matters most. Humans clear false alarms |

## Iterate on the dev set

1. Run the judge over dev. Compute TPR and TNR.
2. Read the disagreements one by one. Put them in two lists: false positives and false negatives.
3. For each, decide whether the judge or the label is wrong. Fix wrong labels first. This often exposes a vague definition.
4. Change the prompt: tighten the definition, add a borderline rule, swap a few-shot example from train. Change one thing at a time.
5. Re-run on dev. Repeat until the rates stop improving.

Inspect disagreements by hand before reaching for automated prompt optimization. Automated tuning can overfit dev and hide a bad definition. If errors are stuck, try a stronger judge model, a smaller input, or splitting the failure into two narrower judges.

## Final check on the test set

Run the judge once on test. If test rates are much worse than dev, the prompt overfit dev. Go back, simplify the prompt, and gather more labels. Do not start tuning on test, because then it is no longer a test.

Record the final prompt, the judge model and version, the split files, and the TPR and TNR. These make the metric reproducible.

## Correct the judge score

When you run the judge over many unlabeled traces, the raw flag rate is biased by the judge's errors. If the judge flags 20 percent of outputs, the true failure rate is not 20 percent unless the judge is perfect.

Let `q` be the observed flag rate. Let `phi` be the true failure rate. Then:

```text
q = phi * TPR + (1 - phi) * (1 - TNR)

phi = (q + TNR - 1) / (TPR + TNR - 1)        # needs TPR + TNR > 1
```

This is the Rogan-Gladen estimator from epidemiology. Clamp the result to the range 0 to 1. Use the TPR and TNR measured on the test set.

Example: TPR 0.85, TNR 0.95, observed flag rate 0.12. Corrected failure rate is (0.12 + 0.95 - 1) / (0.85 + 0.95 - 1) = 0.07 / 0.80 = 0.0875, about 8.8 percent.

Also give a confidence interval. The labeled set is small, so TPR and TNR are uncertain. A bootstrap works: resample the labeled test set with replacement, recompute TPR and TNR, recompute the corrected rate, repeat a few thousand times, and report the middle 95 percent. Resample the unlabeled traces too if the count is small. Libraries exist for this, but the method is a few lines in any language.

For regression gates, compare two versions with the same judge on the same cases. If the judge's error rates are stable across both versions, much of the bias cancels in the comparison, so the gate can use the raw rate. Use the corrected rate when you report an absolute number to others.

## Known judge biases

| Bias | Effect | Mitigation |
|---|---|---|
| Verbosity | Longer answers score higher | State "length does not matter" in the rubric. Check against labels |
| Position | In pairwise comparisons, the first or second answer wins too often | Prefer single-output pass or fail. If pairwise, swap order and keep only consistent verdicts |
| Self-preference | A model rates its own style higher | Use a different model family for the judge than for the app when you can |
| Leniency | Judge passes borderline cases | Add borderline fails as examples. Watch TNR and TPR together |
| Format sensitivity | Correct answer marked wrong because it is laid out differently | Say in the rubric that format does not decide the verdict |
| Context overload | Accuracy drops on long inputs | Pass only the needed excerpts. Use code to check long outputs |

Alignment with human labels matters more than any published bias list. Measure your judge on your data.

## Keep the judge valid

A validated judge stays valid only while its conditions hold.

- **Pin the judge model version.** A silent model update changes TPR and TNR.
- **Re-validate** when you change the judge prompt, the judge model, the app's output format, or the input mix.
- **Spot-check in production.** Pull a few judged traces each week, label them by hand, and compare. A falling agreement rate means drift.
- **Add new disagreements to the labeled set.** Hold some for a refreshed test split.
- **Retire a judge** when its failure is fixed for good and the cases have moved to a code assertion.

## Sources

- Hamel Husain and Shreya Shankar, AI Evals FAQ (updated 2026-09-18), sections on LLM-as-judge validation and bias: https://hamel.dev/blog/posts/evals-faq/
- Anthropic, Demystifying evals for AI agents (2026-01-09), on model graders and calibration against human graders: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents
- Rogan and Gladen, Estimating prevalence from the results of a screening test, American Journal of Epidemiology, 1978 (the correction formula)

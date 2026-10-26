# Decision rules

Turn the measurements into one verdict per skill. Fix the thresholds before reading any result.

## Contents

- [Inputs](#inputs)
- [Thresholds](#thresholds)
- [Verdicts](#verdicts)
- [Handling noise](#handling-noise)
- [The false no-op warning](#the-false-no-op-warning)
- [Before you REMOVE](#before-you-remove)
- [What to report](#what-to-report)

## Inputs

| Source | Measure | Scale |
|---|---|---|
| Outcome harness (`evals/run.sh outcomes`) | `scoreWith`, `scoreWithout`, `delta = scoreWith - scoreWithout` | 0 to 1, mean over runs |
| Blind judge | Mean judge score per arm after mapping back, and the with arm's win count | 0 to 10, per pair |
| Step 1 gate | UNMEASURABLE flag and reason | none |

When a skill has both a deterministic grader and a judge, decide on the deterministic grader and use the judge to explain it.

## Thresholds

Defaults. Change them only before the run, and write the change down.

| Method | KEEP when | Tie band |
|---|---|---|
| Harness | `delta >= 0.25` | `abs(delta) < 0.10` |
| Blind judge | Mean gap `>= 2.0` points and the with arm wins a majority of non-tied pairs | Mean gap `< 1.0` |
| Between | Gap between the tie band and the KEEP threshold | Run more trials before deciding |

Minimums: 2 runs per arm, 3 or more preferred. With fewer than 3 runs, treat anything short of a clear KEEP or an exact tie as undecided.

The harness scores are the mean pass rate over weighted graders, so a delta of 0.25 on three runs is roughly one extra pass in four graded checks. Raise the threshold when graders are few.

## Verdicts

| Verdict | Rule | Meaning |
|---|---|---|
| KEEP | The with arm beats the without arm by more than the KEEP threshold, on a fair fixture and a skill-specific grader | The skill changes the output and earns its context cost |
| REMOVE | A measured no-op: fair fixture, skill-specific grader, at least 3 runs per arm, gap inside the tie band, and the without arm already produces the skill's intended behavior or the behavior is not wanted | The skill adds cost and no measurable benefit. Recommend removal or demotion to run by name |
| LEAVE | A tie where both arms are correct, but the task tested is narrow, or the judge's `worthItCritical` says improvement is not worth it, or only one task was run | The skill is correct but not load-bearing on this task. Do not delete on this evidence |
| UNMEASURABLE | Failed the step 1 gate | The method cannot answer. Report separately and keep the skill pending another way to test it |
| Undecided | The gap falls between the tie band and the KEEP threshold, or runs are too few | Run more trials or a second task |

Demotion is a middle path for a measured no-op that someone may still want on request: mark it `user-invocable: true` and `disable-model-invocation: true` so it costs no context until called.

A skill that makes the without arm worse than with on one grader but better on another is a split result. Report both graders and decide on the one that matches the skill's stated purpose.

## Handling noise

- Variance between runs of the same arm is the floor of what you can detect. If two runs of the without arm differ by 0.3, a delta of 0.25 is not a result.
- Report per-run scores, not only the mean, so the reader can see spread.
- If the with arm wins on average but loses a run outright, say so. One loss in three is noise. Two in three is not.
- Re-run once if the result sits near a threshold. Do not re-run repeatedly until the answer changes.
- Pin the model, the judge model, the prompt, and the fixture for every run. A score change across sessions with different models is not a skill effect.

## The false no-op warning

A single-task tie is weak evidence to delete. One task exercises one slice of a skill, and a skill with several rules may carry its value in a rule the task did not touch.

A skill whose value is on-disk state or a post-cutoff fact, scored without the right fixture, reads as a false no-op. This was observed in this library: a voice skill scored REMOVE while the sandbox had no saved profile, because the with arm had nothing to load and both arms produced the same generic voice. After a real saved profile was seeded at the path the skill reads, the with arm used the profile's signature phrasing and avoided its banned words, and the verdict flipped to a strong KEEP. The skill had not changed. The fixture had.

The same applies to:

- Version skills scored on a question whose answer is the same across versions.
- Review skills scored on a defect the model always catches.
- Schema skills scored when the schema was also in the prompt.
- Lookup skills scored with the needed file missing from the sandbox.

If a skill scores REMOVE, re-check the fixture against [fair-fixtures](fair-fixtures.md) before acting.

## Before you REMOVE

Check each, in order. Any "no" blocks the verdict.

1. Was the fixture fair: every piece of state the skill reads was on disk where the skill says it lives?
2. Did a grader key on a skill-specific marker, and could the without arm have failed it?
3. Were there at least 3 runs per arm, on a clean fixture each time?
4. Did you try a second, different task, or can you state why one task covers the skill?
5. Is the without arm's output correct on the thing the skill claims to improve, not merely plausible?
6. Is the skill's value really inside the sandbox, with no live lookup or external tool in the loop?

If the answer to 4 is no, the verdict is LEAVE, not REMOVE.

## What to report

One row per skill:

| Skill | Class | Fixture | Arms and runs | Result | Verdict | Next action |
|---|---|---|---|---|---|---|
| name | Measurable or UNMEASURABLE | state seeded, defect planted, schema, or lockfile | model, runs per arm | `scoreWith` / `scoreWithout` / delta, or judge means and wins | KEEP, REMOVE, LEAVE, UNMEASURABLE, or Undecided | one concrete step |

Under the table, give three lines: what the grader keyed on, the most telling per-run difference, and the main reason this verdict could be wrong. State cost if the harness reported it. Do not edit the skill, change its invocation mode, or delete it unless the user asks.

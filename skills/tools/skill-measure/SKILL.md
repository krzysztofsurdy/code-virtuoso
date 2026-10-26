---
name: skill-measure
description: Measures whether a skill or reference resource changes a strong model's output enough to earn its context cost, using a fair-fixture A/B ablation and a blind judge. Run by name to audit a skill before keeping, trimming, or removing it.
user-invocable: true
disable-model-invocation: true
argument-hint: "[skill-name | path]"
---

# Skill measure

A skill costs context in every session that lists it, and most skills are never tested against the model that loads them. A strong model often already does the task right, so the skill is a no-op. The opposite error is as common: a skill that carries saved state or a post-cutoff fact is scored in an empty sandbox, the no-skill arm looks as good as the skill arm, and a valuable skill gets deleted. This skill measures one skill with a fair ablation: seed the state the skill needs, run with and without it, grade on the specific thing the skill injects, and judge subjective output blind.

Anthropic's `skill-creator` does basic skill benchmarking. This skill is the fair-ablation-plus-blind-judge method specifically, and the two combine well: use `skill-creator` for the run harness if you prefer it, and keep the fixture, grading, and decision rules from here.

## Procedure

Argument: a skill name or a path to a `SKILL.md` or reference file. Read the target in full before step 1. Write each gate result down; do not run a step until the previous gate passes.

### 1. Decide whether it is measurable

Read the skill and name the one behavior change it is supposed to cause. Classify it:

| Class | Test | Action |
|---|---|---|
| Measurable | A sandbox with files, a prompt, and a transcript can show the change | Continue |
| UNMEASURABLE | Its value needs the network, a browser, a binary that is not installed, a paid or private service, or facts fresher than the model's cutoff that a fixture cannot plant | Report UNMEASURABLE with the reason and stop |

Do not force a fake test. A skill that wraps a live API cannot be graded offline, and a check that passes both arms proves nothing. Criteria and borderline cases are in [fair-fixtures](references/fair-fixtures.md).

Gate: one sentence stating the behavior change, and a Measurable or UNMEASURABLE verdict.

### 2. Build a fair fixture

The no-skill baseline must be fair. Seed on disk whatever state the skill needs before the task runs: a saved profile, a planted defect in a file, an output schema, a lockfile with specific versions. If the skill's whole value is loading saved state or supplying a post-cutoff version fact, the fixture must put that state in place, or the measurement is rigged against the skill.

Write a realistic user prompt in the words a person would type. It must not name the skill and must not quote its text, or the without arm cannot be compared and the with arm is told the answer. Seeding patterns per skill type are in [fair-fixtures](references/fair-fixtures.md).

Gate: a fixture directory the task can run in, and a prompt that passes this check: remove the skill and the task is still well-posed and answerable in principle.

### 3. Pick what the grade keys on

Grade the specific thing the skill injects: the post-training fact, version, API name, flag, gate phrase, or output-schema shape. Do not grade generic correctness. A generic grader passes both arms and reads as a false no-op.

Write the pass condition as a regex or file check first. Use an LLM grader only for output a pattern cannot judge. For each condition, answer: would the without arm fail this if it lacked the skill's fact? If it would pass anyway, the grader is too generic. Rewrite it.

Gate: at least one grader that keys on a skill-specific marker, and a stated reason the without arm could fail it.

### 4. Run two arms

Run with-skill and without-skill, at least 2 runs per arm and 3 or more preferred, from a clean fixture each time. Keep model, prompt, tool grants, and fixture identical between arms. Only the skill differs.

| Skill type | Runner |
|---|---|
| Verifiable by regex, file, or tool-order check | The repo's outcome harness: add a case under `evals/cases/outcomes/`, then `evals/run.sh outcomes --case <name> --runs 3`. It runs both arms and reports `scoreWith`, `scoreWithout`, and the delta. See `evals/README.md` for the case layout |
| Subjective or artifact output a regex cannot judge | Collect the final outputs from each arm and go to step 5 |

Record the model, the number of runs, and the cost.

Gate: per-arm outputs saved, and for the harness path a delta reported.

### 5. Blind judge (subjective or artifact skills)

Give the judge both answer sets labeled only X and Y. Never say which arm is which, never pass transcripts that show a skill being loaded, and decide the X/Y mapping by a fixed rule before judging so it cannot bias the score. The judge scores each set 0 to 10 and returns `scoreX`, `scoreY`, `winner`, `comment`, `worthImproving`, `improvementToRaise`, and `worthItCritical`. Map X and Y back to with and without only after all verdicts are in. The exact prompt, schema, and mapping rule are in [ab-judge](references/ab-judge.md).

Gate: judge verdicts for every pair, mapped back to arms, with the mapping rule written before the first call.

### 6. Decide

Set the threshold before reading results. Defaults: a harness delta of 0.25 or more, or a mean judge gap of 2 points or more with the with arm winning most pairs.

| Verdict | When |
|---|---|
| KEEP | The with arm beats the without arm by more than the threshold |
| REMOVE | A measured no-op: a fair fixture, a skill-specific grader, enough runs, and no gap |
| LEAVE | A tie where both arms are correct. The skill is not load-bearing on the task tested, but one task does not prove it is dead |
| UNMEASURABLE | Failed the step 1 gate. Report separately and do not count it as a no-op |

Warnings that change the verdict:

- A single-task tie is weak evidence to delete. Try a second, different task before REMOVE.
- A skill that depends on on-disk state or a fresh fact, scored without the right fixture, reads as a false no-op. This was observed: a voice skill scored REMOVE until a real saved profile was seeded, then flipped to a strong KEEP. If a skill scores REMOVE, re-check the fixture before acting.

Thresholds, the tie policy, and what to report are in [decision-rules](references/decision-rules.md).

Output a short table: skill, class, fixture, arms and runs, scores or delta, verdict, and the one next action. Make no edits to the target skill unless the user asks.

## Pitfalls

- Naming the skill in the prompt. The with arm then loads it for the wrong reason and the without arm is not a baseline.
- A grader that checks the answer is right. Check that it contains the marker only the skill supplies.
- One run per arm. Variance alone can produce a delta of the size you are looking for.
- Letting the judge see which output came from which arm, or ordering every pair with the with arm first. Position and label bias are real.
- Judging an on-disk-state skill in an empty sandbox. Seed the state first.
- Treating UNMEASURABLE as REMOVE. It means the method cannot answer, not that the skill is useless.

## Reference Files

| Reference | Contents |
|---|---|
| [fair-fixtures](references/fair-fixtures.md) | UNMEASURABLE criteria, and how to seed saved state, planted defects, output schemas, and version lockfiles so the baseline is fair |
| [ab-judge](references/ab-judge.md) | The blind-judge protocol, exact judge output schema, judge prompt, and the fixed X/Y mapping rule |
| [decision-rules](references/decision-rules.md) | KEEP, REMOVE, LEAVE, UNMEASURABLE rules, thresholds, noise handling, and the false no-op warning |

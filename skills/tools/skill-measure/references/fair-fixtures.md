# Fair fixtures

A fixture is the set of files on disk when the task starts, plus the prompt. It is fair when the without arm has everything a competent model with no skill would have, and the with arm has the same files plus the skill. If the skill's value is the state or fact, the fixture supplies that state to both arms, and the only difference is whether the model knows to look for it and how to use it.

## Contents

- [The fairness test](#the-fairness-test)
- [UNMEASURABLE criteria](#unmeasurable-criteria)
- [Saved state](#saved-state)
- [Planted defect](#planted-defect)
- [Output schema](#output-schema)
- [Version lockfile](#version-lockfile)
- [Writing the prompt](#writing-the-prompt)
- [Common fixture mistakes](#common-fixture-mistakes)

## The fairness test

Before running, answer three questions:

1. Could a strong model with no skill do the task, given only the fixture and the prompt? If the task is impossible without the skill's text, the fixture is rigged for the skill.
2. Could a strong model with no skill still get it wrong in a way the grader detects? If not, the grader is too generic and both arms will pass.
3. Is every piece of state the skill reads present on disk, in the place the skill says it lives? If the skill reads a path the fixture does not create, the with arm has nothing to load and the measurement is rigged against the skill.

## UNMEASURABLE criteria

A skill is UNMEASURABLE in a sandbox when its value depends on something the sandbox cannot supply. Report it and stop.

| Cause | Examples | Why a fixture cannot fix it |
|---|---|---|
| Network | Live API lookups, package registry queries, fetching current docs or prices | The sandbox has no network, or the answer changes between runs |
| Browser | Screenshots, page interaction, visual review of a rendered page | No browser or display in the sandbox |
| Binary not installed | A game engine, a video renderer, a database server, a vendor CLI | The skill's commands fail in both arms for reasons unrelated to the skill |
| Facts fresher than the model's cutoff, not plantable | A release that happened last week, a changed price, a deprecation announced yesterday | You can plant a lockfile or a doc excerpt, but if the skill's point is that the model looks the fact up live, planting it measures reading a file, not the skill |
| Paid or private service | Tickets in a tracker, a company wiki, a paid generation API | No credentials, and cost or side effects are not acceptable in a test |
| Human judgment in the loop | A skill whose output is an interview or a negotiation | No automatic way to grade the exchange |

Borderline cases:

- A skill that needs a version fact the model lacks is measurable if the fact can live in a file the skill tells the model to read (a lockfile, a changelog excerpt, a pinned doc). It is unmeasurable if the skill's value is the live fetch.
- A skill that calls a binary is measurable if a stub binary on `PATH` can return deterministic output and the skill's value is in how the model sequences and reads it. It is unmeasurable if the value is in the binary's real behavior.
- A skill that produces a visual result is measurable if the grader reads a text artifact (a file, a config, a generated spec). It is unmeasurable if only a rendered image shows the difference.

When in doubt, state what you would need to measure it and mark it UNMEASURABLE.

## Saved state

Applies to skills whose value is loading a profile, config, memory, or prior output: a voice or style skill, a skill that reads saved preferences, a handoff skill that restores a session.

1. Find where the skill reads state from (a path, a naming convention, a config key). Quote it from the skill text.
2. Write a realistic state file at that path in the fixture. Use real content, not a placeholder: a voice profile with specific sentence length, vocabulary, and forbidden phrases, not "friendly and concise".
3. Make the state contain markers a generic answer would not produce: a signature phrase, a banned word, a specific ordering rule, a name.
4. Place the same file where a model without the skill would still see it (in the working directory). The without arm may or may not read it. That is the thing being measured.
5. Grade on the markers: the output uses the signature phrase and avoids the banned word. A generic "is the tone good" grader passes both arms.

If you leave the state out, the with arm has nothing to load, the two arms produce the same generic output, and the skill reads as a no-op. This is the most common false REMOVE.

## Planted defect

Applies to review, audit, lint, and debugging skills, where the skill's value is catching something the model overlooks.

1. Write a small realistic file with one specific defect the skill is meant to catch: a missing authorization check, a swallowed exception, an off-by-one in a boundary, a hook matcher that never fires.
2. Keep the file plausible. Surround the defect with correct code so the model has to find it, not be told.
3. Make the defect the kind a model without the skill misses some of the time. If a strong model catches it every time, the skill cannot show a gain on it. Try a subtler defect, or one that depends on a convention the skill supplies.
4. Grade on the defect: the output names the file and line, or the exact fault, and proposes the fix. Also grade that a clean line is not flagged if false positives matter to the skill.
5. Plant a second, unrelated defect the skill does not cover if you want to see scope discipline.

## Output schema

Applies to skills that fix the shape of an output: a report format, a ticket template, a JSON contract, a commit message convention.

1. Put the schema where the skill says it lives, or in the skill's text only if the schema ships with the skill (then the without arm gets no schema, which is the point).
2. Decide whether you are measuring "knows the format" or "follows a format it is handed". These are different. If the format is handed in the prompt for both arms, the skill adds nothing about the format and you should be measuring something else, such as sequencing or completeness.
3. Grade on shape: required fields present, ordering, section names, forbidden sections, length bounds. A validator script run on the output is the strongest check.
4. Do not grade content quality with the shape grader. Use a second grader or the blind judge for that.

## Version lockfile

Applies to skills that supply version-specific facts: a framework upgrade guide, a docs lookup skill, a migration playbook, a deprecation list.

1. Write a lockfile or manifest that pins the exact version the skill covers (`composer.lock`, `package-lock.json`, a `go.mod`). Use a version after the model's likely cutoff if the skill covers one, or a specific old version if the skill covers a version the model confuses with newer ones.
2. Ask a question whose correct answer differs by version: an argument order, a renamed option, a removed method.
3. Grade on the version-specific answer: the exact signature, flag, or class name for that version, plus whether the lockfile was read. A grader that accepts the answer from any version passes both arms.
4. Make sure the fact is true. Check the skill's claim against the vendor documentation or the installed source before using it as a grader, or you will reward the wrong answer.

## Writing the prompt

- Write it the way a person types: short, with context from the fixture, no skill vocabulary.
- Do not name the skill, quote its description, or use its headings.
- Make it specific enough that a correct answer exists and generic enough that the skill is relevant. "Fix this" fails the first test. "Apply the skill's 7-step review" fails the second.
- Do not mention the fixture file paths if the skill's job is to find them. Mention them if finding them is not what you are measuring.
- Run it once by hand with no skill. If the answer already passes the grader, the grader or the task is wrong.

## Common fixture mistakes

| Mistake | Effect | Fix |
|---|---|---|
| State missing from the fixture | With arm has nothing to load, false REMOVE | Seed the state at the path the skill reads |
| Skill text pasted into the prompt | Without arm becomes with arm, delta collapses | Prompt in the user's words only |
| Defect too obvious | Both arms catch it, false tie | Plant a subtler defect or a convention-dependent one |
| Grader on correctness only | Both arms pass, false no-op | Grade on the skill-specific marker |
| Fixture reused with leftover state from a prior run | Runs correlate, variance understated | Rebuild the fixture before each run |
| Fixture differs between arms | The delta measures the fixture | Same scaffold script for both arms |

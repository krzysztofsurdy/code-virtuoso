## Contents

- [Why start here](#why-start-here)
- [Get traces](#get-traces)
- [Open coding](#open-coding)
- [Failure taxonomy](#failure-taxonomy)
- [When to stop](#when-to-stop)
- [Fix before you measure](#fix-before-you-measure)
- [Turn findings into evals](#turn-findings-into-evals)
- [Refresh cadence](#refresh-cadence)
- [Sampling production traces](#sampling-production-traces)
- [Sources](#sources)

# Error analysis

Error analysis is how you find out what to measure. You read real outputs, write down what went wrong in plain words, and group the notes into categories. The categories become your graders. Skipping this step is the most common reason an eval suite measures things nobody cares about.

## Why start here

| Without error analysis | With error analysis |
|---|---|
| Metrics come from a catalog ("hallucination", "toxicity", "helpfulness") | Metrics come from failures your users actually hit |
| Scores move and nobody knows what to fix | Each score maps to a named failure with a known fix |
| Judges are written before anyone knows the failure | Judges are written for failures that are already understood |
| False confidence from a green dashboard | Honest picture of where the system breaks |

Your failure modes are specific to your product. A support bot may fail by promising refunds it cannot give. A coding agent may fail by editing a file it never read. No generic metric names these.

## Get traces

You need full transcripts: the user input, the system prompt version, every model call, every tool call and result, and the final output. Without tracing you cannot do this work. See `llm-observability`.

| Situation | Source of traces |
|---|---|
| App is live | Sample production traces, see [Sampling production traces](#sampling-production-traces) |
| App is not live | Write realistic inputs by hand, or generate varied ones from a list of dimensions, then run them through the real system |
| Few users so far | Mix both. Real inputs are better, so replace synthetic ones as they arrive |

For synthetic inputs, list the dimensions that change behavior (user intent, persona, input length, language, ambiguity, missing information, adversarial phrasing). Generate combinations of those dimensions rather than asking a model for "50 test questions", which returns 50 near-duplicates. Run them through the real application, not a mock.

## Open coding

Open coding means reading each trace and writing a short note about what went wrong, without a fixed list of categories.

1. Read one trace end to end.
2. Decide whether it succeeded for the user.
3. If not, write one note about the **first** failure in the trace. Later failures are often downstream of it. Use plain words: "quoted a price that is not in the retrieved docs", "asked the user for information already given", "called the search tool with an empty query".
4. Move on. Do not stop to fix or debate.

Rules that keep the notes useful:

- Annotate at least 30 traces yourself before looking at any model-generated suggestions. A model-written summary anchors you on its categories.
- Use a domain expert as the annotator, or one person who owns the product. Too many annotators early on produces inconsistent notes.
- Record what is wrong, not what you would prefer. "Too long" is a preference. "Ignored the user's request for three bullets" is a failure.
- Keep a "no failure" note too. Knowing the pass rate of your sample is useful.
- A simple spreadsheet or the annotation view of any tracing tool is enough.

## Failure taxonomy

Grouping the notes is sometimes called axial coding. It is the most valuable step.

1. Read all notes together and cluster similar ones.
2. Name each cluster as a specific failure, not a theme. "Invents policy details not in the knowledge base" beats "hallucination".
3. Write a one-line definition and one real example for each.
4. Go back through the traces and tag each one with its category.
5. Count traces per category.

A small taxonomy for a support agent might look like this:

| Failure | Definition | Count of 100 |
|---|---|---|
| Invented policy | States a rule or number absent from retrieved documents | 14 |
| Ignored context | Asks for data already given earlier in the conversation | 9 |
| Wrong tool arguments | Tool call has an empty or malformed argument | 7 |
| Missed escalation | Does not hand off when the user asks for a human | 5 |
| Tone mismatch | Cheerful reply to an angry complaint | 3 |

The counts tell you what to fix first. They also tell you which failures deserve a dedicated judge and which are rare enough to skip.

Merge categories that overlap and split categories that hide two different fixes. Expect two or three passes before the names feel right.

## When to stop

Stop reading when new traces stop showing new failure modes. This is called theoretical saturation. In practice, plan on about 100 diverse traces for a first pass. If trace 80 to 100 still reveal new categories, keep going. If the last 30 reveal none, you are done for this round.

Diverse matters more than many. 100 near-identical traces reveal fewer failures than 40 that cover different intents, user types, and edge cases.

## Fix before you measure

Not every failure needs an eval. Sort the taxonomy first:

| Kind | Action |
|---|---|
| Obvious gap in the prompt (the instruction was never given) | Fix the prompt, then check again |
| Broken tool, bad schema, missing data | Fix the code. This is a bug |
| Model cannot do it reliably even with clear instructions | Candidate for an eval, and for a guardrail or a better design |
| Subjective and rare | Spot-check by hand. Skip automation |

Many first-round failures disappear with a prompt or tool fix. Automate only the ones that remain and that you care about.

## Turn findings into evals

For each failure you will track:

1. Collect the traces tagged with it. Keep both failing and passing examples.
2. Choose the grader. If code can check it (a schema, a string, a tool argument, an end state), write the assertion. If not, build one judge for that failure and validate it, see [judge-calibration](judge-calibration.md).
3. Add the failing traces to the regression suite as cases. After you fix the failure they should pass, and they should keep passing.
4. Record the failure name, definition, and owner next to the suite so the next person understands why the case exists.

A small suite of 20 to 50 cases built from real failures protects more than a large synthetic set. Early in a project changes have large effects, so small samples are enough. Do not wait for a perfect dataset.

## Refresh cadence

The failure list goes stale. Users change, features ship, models are swapped. Re-run the analysis:

- On roughly 100 fresh traces every few weeks while the product is changing quickly
- After a major prompt, model, tool, or retrieval change
- After an incident or a user-visible quality complaint
- When a metric moves and you cannot explain why

If every case in the regression suite passes for months, the suite is no longer challenging the system. Add cases from new failures, or run the suite less often.

## Sampling production traces

| Method | What it finds | Use |
|---|---|---|
| Random | Unknown unknowns, a fair view of the real distribution | Always include some in every batch |
| Clustering | Groups of similar traces, so you read one per cluster | Large volumes, find common patterns |
| Outliers | Unusual length, step count, latency, cost, or tool sequence | Weekly review |
| Classifier flagged | Traces that a validated judge or rule marked as suspect | Targeted checks on known failures |
| User feedback | Thumbs down, rephrased questions, abandoned sessions, escalations | Most direct signal of real harm |

Outside of a major review, 10 to 20 traces per week is enough to keep the taxonomy current. Rare failures need targeted sampling on signals such as retries, repeated tool calls, or very long traces, because random sampling will almost never surface them. Always apply your privacy rules before humans read production data, see `llm-observability`.

## Sources

- Hamel Husain and Shreya Shankar, AI Evals FAQ (updated 2026-09-18): https://hamel.dev/blog/posts/evals-faq/
- Anthropic, Demystifying evals for AI agents (2026-01-09): https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents

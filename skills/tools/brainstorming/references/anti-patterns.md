# Anti-patterns

Failure modes that derail brainstorming sessions. Each anti-pattern includes what goes wrong, how to detect it, why it happens, and how to recover.

## Contents

- [Solution jumping](#solution-jumping)
- [Compound questions](#compound-questions)
- [Leading questions](#leading-questions)
- [Premature implementation](#premature-implementation)
- [Fake consensus](#fake-consensus)
- [Scope creep during convergence](#scope-creep-during-convergence)
- [Skipping for "simple" projects](#skipping-for-simple-projects)
- [Anchoring on the first idea](#anchoring-on-the-first-idea)
- [Consensus without conflict](#consensus-without-conflict)

---

## Solution jumping

**What happens**: The agent (or user) leaps to "how to build it" before defining "what to build and why." Architecture, technology choices, and implementation details appear before goals and constraints are established.

**Detection signals**:
- Technology names appear in the first few messages ("We should use Kafka for this")
- Architecture terms before problem definition ("Let's design a microservice that...")
- The user describes a solution and the agent starts refining it instead of asking why
- File scaffolding or code snippets appear before a spec exists

**Why it happens**: Building feels productive. Exploring feels slow. Both agents and users default to "doing" because it shows visible progress, even when the direction is wrong.

**Recovery**:
1. Pause and acknowledge: "That is an interesting approach. Before we go there, I want to make sure we have defined the problem."
2. Return to goal-seeking questions: "What problem does [proposed solution] solve?"
3. Park the solution idea for later: "I have noted [solution idea] - we will evaluate it once the spec is written."

**Prevention**: No code, no architecture, and no technology choices until the spec is approved. Treat this as a hard gate, not a suggestion.

---

## Compound questions

**What happens**: Multiple questions are bundled into a single message. The user answers whichever part is easiest or most interesting, and the rest are lost.

**Detection signals**:
- A message contains two or more question marks
- The user's answer only addresses part of what was asked
- Topics get conflated because they were raised simultaneously

**Why it happens**: Asking three questions feels faster than asking one. It is not. It produces shallower answers and more follow-ups.

**Recovery**:
1. Notice which parts went unanswered
2. Isolate the unanswered part and ask it as a standalone question
3. Do not reference the original compound question - just ask the new focused one

**Prevention**: Ask one question per message, every time. If you catch yourself writing "and also...", stop, send the first question, and wait for the answer.

---

## Leading questions

**What happens**: The question contains the desired answer, steering the user toward a conclusion chosen in advance instead of exploring the problem space.

**Detection signals**:
- Questions start with "Don't you think..." or "Wouldn't it be better to..."
- The phrasing makes one option sound obviously correct
- The user agrees quickly without adding new information
- Technology or architecture preferences are embedded in the question

**Examples**:

| Leading (bad) | Neutral (good) |
|---|---|
| "Don't you think we should use a message queue here?" | "How does the data need to flow between these components?" |
| "Wouldn't it be faster to cache this?" | "What performance characteristics does this need?" |
| "Since we're already using PostgreSQL, shouldn't we keep the data there?" | "Where should this data live, and what are the access patterns?" |
| "This is basically a CRUD app, right?" | "What operations do users need to perform on this data?" |

**Why it happens**: The agent (or a senior participant) has already formed an opinion and seeks confirmation instead of exploring.

**Recovery**: Rephrase as a neutral, open question. Remove all technology names, value judgments, and implied answers.

**Prevention**: Before sending a question, check: "Could someone answer this in a way I do not expect?" If not, the question is leading.

---

## Premature implementation

**What happens**: Code, scaffolding, file creation, or detailed technical design appears before the spec is written and approved. This differs from solution jumping: premature implementation is taking action, not just talking about solutions.

**Detection signals**:
- Files are created in the project directory
- Code snippets are presented as "just to illustrate"
- The agent starts "setting things up" before the spec exists
- Technical spikes happen without a defined question they are answering

**Why it happens**: Agents want to help, and writing code feels like helping. Users may also push for immediate results ("just build it, we can figure out the spec later").

**Recovery**:
1. Stop all implementation activity
2. Acknowledge the user's desire for speed: "I understand you want to move fast. The spec will actually get us there faster by avoiding rework."
3. Return to the current brainstorming phase

**Prevention**: The approval gate enforces this. Take no implementation action of any kind until the user says "approve."

---

## Fake consensus

**What happens**: The user agrees to things without truly engaging. The spec looks complete but contains gaps masked by shallow agreement.

**Detection signals**:
- Answers are consistently short: "sure," "sounds good," "yeah"
- The user agrees to contradictory things without noticing
- Acceptance criteria are suspiciously uncontroversial
- The user has not pushed back on anything or asked any counter-questions

**Why it happens**: The user may be disengaged, distracted, trusting the agent too much, or unsure how to push back. Some users agree to everything because they assume the agent "knows best."

**Recovery**:
1. Test engagement with a concrete scenario: "Can you walk me through how you would use [feature] on a typical day?"
2. Introduce a deliberate contradiction and see if the user catches it
3. Ask for prioritization: "If you had to cut one of these acceptance criteria, which would it be?"
4. Probe specifics: "When you say 'fast,' what does that mean in numbers?"

**Prevention**: Periodically check for real engagement. If the user has not disagreed with or refined anything after 5+ questions, probe deeper. Consensus without friction is probably fake.

---

## Scope creep during convergence

**What happens**: New ideas keep appearing after the scope was supposedly locked. The brainstorming session spirals because every discussion about boundaries introduces new features.

**Detection signals**:
- The user says "oh, and we also need..." after scope was confirmed
- Non-goals keep getting promoted to goals
- The spec grows every revision instead of stabilizing
- Phase 3 (convergence) restarts more than twice

**Why it happens**: Brainstorming prompts new ideas. Once the user starts thinking about what is possible, more keep coming. That helps during divergence and hurts during convergence.

**Recovery**:
1. Acknowledge the idea: "That is a good idea."
2. Park it explicitly: "I am adding it to future considerations, outside the scope of this spec."
3. Re-confirm the locked scope: "Our current scope is [X]. Does this new idea change that, or can it wait?"
4. If the user insists it must be in scope, loop back to divergence for that specific item only, then re-converge

**Prevention**: Create a visible "parking lot" or "future considerations" list. Every new idea during convergence goes there by default. The user can promote items, but must explicitly choose to expand scope.

---

## Skipping for "simple" projects

**What happens**: The brainstorming process is bypassed because the project "is too simple to need a spec." The agent or user jumps straight to implementation.

**Detection signals**:
- "It's just a small script"
- "This is straightforward, we don't need to brainstorm"
- "I already know what I want, just build it"
- "It's a simple CRUD app"

**Why it happens**: Small projects feel like they do not need a formal process, and sometimes they do not. But a short spec costs little, and building the wrong thing costs a lot, even for a small project.

**Recovery**: Do not argue about process. Instead, demonstrate value by asking one sharp question that reveals hidden complexity: "Before we start - what happens when [edge case]?" or "What does 'done' look like for this?"

**Prevention**: Scale the process, do not skip it. A simple project gets a 5-minute brainstorming session and a half-page spec. The phases are the same and the depth differs.

---

## Anchoring on the first idea

**What happens**: The first solution or approach mentioned becomes the default, and all subsequent discussion revolves around refining it rather than exploring alternatives.

**Detection signals**:
- Only one approach has been discussed
- Questions are about implementation details of the first idea, not about alternative approaches
- The user or agent says "so we are going with [first idea]" without evaluating alternatives
- No trade-offs have been discussed

**Why it happens**: The first idea fills the gap left by uncertainty. Once a plausible solution exists, it becomes the anchor and later thinking drifts toward it.

**Recovery**:
1. Explicitly name the anchor: "We have been discussing [approach A]. Before we commit, what would [approach B] look like?"
2. Force at least one alternative: "What is a completely different way to solve this?"
3. Evaluate trade-offs between approaches before choosing

**Prevention**: During divergence, when the first approach surfaces, note it and explicitly ask: "That is one direction. What are other ways this could work?" Do not evaluate until at least two approaches exist.

---

## Consensus without conflict

**What happens**: The brainstorming session proceeds smoothly with no disagreements, no trade-offs, and no difficult decisions. The resulting spec looks complete but has not been stress-tested.

**Detection signals**:
- No trade-offs were discussed
- No hard choices were made
- Every stakeholder need was accommodated
- The scope only grew, never shrank
- The first-cut approach sounds like it solves everything with no downsides

**Why it happens**: Avoiding conflict feels collaborative. But real design involves trade-offs, and a trade-off means choosing what to give up.

**Recovery**: Introduce deliberate tension:
- "What would you sacrifice to ship two weeks earlier?"
- "If we can only optimize for [A] or [B], which matters more?"
- "What is the hardest trade-off in this spec?"

**Prevention**: Build trade-off questions into every convergence phase. A spec without trade-offs has not been examined closely enough.

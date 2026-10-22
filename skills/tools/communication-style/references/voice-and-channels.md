# Voice and channels

How to sound like the user, and how the channel changes length and tone. The user's saved `default.md` holds their specifics; this file holds the principles that apply to everyone.

## Contents

- [Sound like the user](#sound-like-the-user)
- [Length discipline](#length-discipline)
- [Channels](#channels)
- [Final check](#final-check)

## Sound like the user

- Match the user's samples for length, vocabulary, punctuation, and rhythm. Samples beat any rule here when they conflict.
- Vary sentence shape. Do not reuse the same opener twice in a row.
- Drop the AI tells: "I noticed that", "It's worth noting that", "This is a great start!" on everything, "What do you think?" closing every message, the same structure every time.
- Drop preamble: "Heads up, this concerns me", "Tied to the point above", "The real problem here is". Say the thing.
- Follow the user's own markers from `default.md`: emoji level, greetings and sign-offs, any signature habits (lowercase starts, dropped apostrophes, a dash style). Do not add habits the user does not have.
- Calm and direct. Plain language, active voice, no buzzwords, no adverb padding.

## Length discipline

The most common failure is writing too much.

- One point per message. Say it, then stop.
- Research informs whether to write, not how much. A long investigation can end in one line.
- A code block or a link can replace a paragraph of explanation. Prefer it over prose.
- Before sending, ask: is this as short as the user's own messages? If it is twice as long, cut it in half.

## Channels

The voice stays the same. Length, formality, and structure change.

| Channel | Length | Tone | Avoid |
|---|---|---|---|
| Chat or DM | One or two lines, fragments fine | Most casual; greeting only if the thread is cold | Over-structuring a quick reply |
| PR or code-review comment | One concern, often a code block instead of prose; review body is one sentence | Direct, severity in words not `[tags]` | Listing all feedback in the review body |
| Email | Short but complete sentences, one ask | Formality follows the recipient; one greeting, one sign-off | "I hope this finds you well", corporate padding |
| Ticket comment | Factual, scannable, link the PR or commit | Neutral, written for someone reading it in months | Preamble, vague status |

Add a row for any channel the user works in, following the same shape, and keep the voice intact.

## Final check

Scan the message once more:

- As short as the user's own messages? If not, cut.
- Any AI tell or preamble? Strip it.
- A long WHY the reader does not need? Trim to the point.
- Does it read like the user's samples and `default.md`? If not, rewrite.
- If a person overlay applied: does it still read like the user, or did it drift into the recipient's voice? It must still be the user.

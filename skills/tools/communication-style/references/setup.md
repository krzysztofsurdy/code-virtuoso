# Setup: create or update profiles

Two things to build or refine: the default voice, and a person profile. Either can come from samples the user pastes or points to, or from a few questions. Always show the draft and let the user correct it before saving.

Resolve the config home once:
`${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/comm-profiles/`
Create it if missing (`mkdir -p`), with a `people/` subdirectory.

## Contents

- [Default voice](#default-voice)
- [A person profile](#a-person-profile)
- [Updating later](#updating-later)

## Default voice

Target file: `comm-profiles/default.md`.

Ask the user which input they want.

**From samples.** The user pastes or points to messages they wrote (PR comments, chats, emails). Save the raw ones under `comm-profiles/samples/` so rhythm can be matched later. Read them and distill: typical length, formality, language(s), emoji use, greetings and sign-offs, signature habits, and the openers or phrases they never use. Write these into `default.md`.

**From questions.** If the user has no samples handy, ask a few, one at a time:

1. Languages you write in, and when you switch.
2. How short do you like to be? Terse, medium, or spelled-out.
3. Formality by default: casual, neutral, or formal.
4. Emoji: none, light, or expressive.
5. Greetings and sign-offs you use, or skip.
6. Any signature habits (lowercase starts, dropped apostrophes, a word you overuse).
7. Three things that make a message read as not-you (the AI tells and preambles to ban).

Turn the answers into `default.md`. Keep it short. The default is a base, not an essay.

## A person profile

Target file: `comm-profiles/people/<slug>.md`.

1. Ask who the person is and the relationship (teammate, manager, reviewer, client, friend).
2. Ask for the input: a conversation export or pasted messages between the user and that person. Only what the user provides. Do not research the person online.
3. Follow [person-profiles.md](person-profiles.md) "Building a profile from conversations" to fill: how they write, what lands, what to avoid, shared context, and a short practical read.
4. Show the draft, take corrections, then save.

## Updating later

- The user can refresh any profile at any time: "update my default voice" or "update <person>'s profile".
- When refreshing a person profile, read the old file and the new samples, then merge rather than overwrite, so earlier corrections survive. Note the new date and source.
- If the default voice and a person profile conflict, the default wins on voice; the person profile wins on delivery (language, length, formality). Keep the user's voice.

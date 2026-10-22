# Person profiles

A person profile is an overlay. It tunes how the default voice is delivered to one specific person. It never replaces the voice. The reader should still hear the user, just pitched the way that person prefers.

## Contents

- [When a profile applies](#when-a-profile-applies)
- [What an overlay may change](#what-an-overlay-may-change)
- [What an overlay must not do](#what-an-overlay-must-not-do)
- [Building a profile from conversations](#building-a-profile-from-conversations)
- [Privacy](#privacy)

## When a profile applies

- Only when the recipient is known: the user named them, or the thread clearly identifies one person.
- Resolve the name to a slug and read `comm-profiles/people/<slug>.md`. No file: use the default alone, say so, and offer to build one.
- One recipient per message. Never blend two overlays. Never carry an overlay into a message for someone else. A group message with no single recipient uses the default alone.

## What an overlay may change

- Language (for example, reply in the language the person writes in).
- Length and density: terser or more spelled-out than the baseline.
- Formality: more casual with a close colleague, more neutral with a client.
- Emoji and playfulness tolerance.
- Shared context to lean on: projects, prior decisions, running jokes.
- Delivery of asks: bottom-line-first for one person, reasoning-first for another; direct for one, softened for another.

## What an overlay must not do

- Do not adopt the recipient's voice, vocabulary, or quirks. The user is not imitating them.
- Do not drop the user's core style from `default.md`.
- Do not change the user's position or values to please the recipient. Tune tone, not substance.

If applying an overlay would make the message stop sounding like the user, it went too far. Pull back.

## Building a profile from conversations

Input: a conversation history or messages the user had with that person, pasted or pointed to as a file. Only material the user provides.

1. Read the exchange. Note how the person writes (language, length, formality, emoji, habits) and how they react (what gets a fast reply, what gets ignored or pushback).
2. Draft `people/<slug>.md`: how they write, what lands, what to avoid, shared context, and a short practical read (direct vs diplomatic, detail-first vs bottom-line-first).
3. Keep the read practical, not a clinical personality label. The goal is how to talk to them well.
4. Record what it was built from and the date, so it can be refreshed.
5. Show the user the draft and let them correct it before saving.

## Privacy

- Build only from conversations the user provides. No web research or lookups on the person.
- The profile models communication preferences, not a dossier.
- These files hold notes about real people. They stay in the user config home, never in a repo and never shared.

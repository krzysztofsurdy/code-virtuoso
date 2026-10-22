---
name: communication-style
description: "Writes messages in the user's own voice, not a generic AI tone. Apply before writing ANY message meant to sound like the user: a GitHub PR or review comment, an issue or thread reply, a Slack or chat DM, an email, or a ticket comment. Loads the user's saved default voice, and when a recipient is named, layers that person's profile on top without losing the user's voice. Has a setup mode to build the default voice and per-person profiles from samples or a few questions."
user-invocable: true
argument-hint: "[setup | to:<person> | nothing, just write]"
---

# Communication style

An AI writing on someone's behalf drifts to a flat, hedged, preamble-heavy tone that does not sound like them, and it reads the same to everyone. This skill fixes both: it holds the user's own voice as an always-on base, and it tunes delivery for the channel and the named recipient without letting the message stop sounding like the user.

Profiles are saved per user, outside any repo, under the config home:
`${CODE_VIRTUOSO_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}/code-virtuoso}/comm-profiles/`

```
comm-profiles/
  default.md          the user's own voice. Always applied.
  people/<slug>.md    per-person overlays. Applied only when the recipient is known.
  samples/            optional: the user's real messages, used to match rhythm.
```

If `default.md` does not exist yet, run [setup](references/setup.md) first, or build it inline from samples the user gives in the conversation. Never invent a voice.

## Before writing (runtime)

1. **Load the default voice.** Read `comm-profiles/default.md` and skim any `comm-profiles/samples/`. This always applies.
2. **Pick the channel.** Chat or DM, PR or code-review comment, email, or ticket. Each sets length and formality. See [voice-and-channels.md](references/voice-and-channels.md).
3. **Layer the person, only if a recipient is known.** If the user named who the message is for, or the thread identifies one person, and `comm-profiles/people/<slug>.md` exists, read it and apply it on top. See [person-profiles.md](references/person-profiles.md). No recipient, or no profile: default only.
4. **Write**, following [voice-and-channels.md](references/voice-and-channels.md).
5. **Final check** (end of that file). Verbosity and AI tells are the common failures.

## The layering contract

The heart of the skill. Keep it exact.

- **Default is always on.** Every message must read like the user, in every channel, to everyone.
- **A person overlay tunes delivery only:** length, formality, language, emoji tolerance, shared context, and what lands with that person. It never replaces the user's core voice, vocabulary, or values. The reader should still hear the user, not an impression of themselves.
- **Never switch profiles mid-stream.** One message uses the default plus at most one person overlay. Do not carry one person's overlay into a message for someone else. Unsure who the recipient is: use the default alone and say so.

## Setup mode

Run when the user says "set up my style", "update my voice", "make a profile for <person>", or passes `setup`. Create or update the default voice or a person profile, from samples the user pastes or points to, or from a few questions. Steps: [setup.md](references/setup.md).

- **Default voice:** build or refine `comm-profiles/default.md`.
- **Person profile:** build `comm-profiles/people/<slug>.md` from conversations the user provides. No web research on the person. It models how to talk to them, not a dossier.

## Reference files

| Reference | Open when |
|---|---|
| [voice-and-channels.md](references/voice-and-channels.md) | Writing anything: sounding like the user, length, per-channel tone, the final check |
| [person-profiles.md](references/person-profiles.md) | A recipient is named, or building a person profile |
| [setup.md](references/setup.md) | Creating or updating the default voice or a person profile |

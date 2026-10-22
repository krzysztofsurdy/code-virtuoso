---
name: video-production
description: "Makes a video from a brief: picks an engine, storyboards stills for approval, writes a numeric spec, builds, reviews frame snapshots, adds audio, renders and delivers. Use for make a video, product teaser, explainer video, promo, motion graphics video, render a clip, video from a script."
user-invocable: true
argument-hint: "[brief: subject, audience, length, platform, assets]"
---

# Video production

Asked for a video, an agent usually starts coding in the engine it knows best, renders the whole film to find out whether it looks right, bolts audio on at the end, and delivers a file nobody checked. Each of those costs a full render cycle or a rework. This playbook puts the cheap decisions first (engine, storyboard, numbers), checks work with single frames before any full render, and treats sound as part of the film.

It is the workflow. The craft rules for timing, easing, type, safe areas, flashing and caption layout live in the `motion-design` skill: load it before the spec step and do not restate its numbers here.

## Principles

| Principle | Why |
|---|---|
| Approve stills before code | A drawn frame is cheap to change. A built scene is not |
| Every adjective becomes a number | "Snappy" and "calm" cannot be checked. Seconds, frames, pixels and percentages can |
| Look before you render | A frame capture takes seconds. A full render takes minutes and hides which frame is wrong |
| Time belongs to the engine | Anything driven by a wall clock, a CSS transition or a network call renders differently each run |
| Audio sets the clock | Narration or music length decides shot length. Shots stretched to fit a voice later never feel right |
| Show real things | Use the real product screens, logo and data. Draw or generate only what has no source |
| Say what you could not check | An agent cannot hear or watch the film. Measure what can be measured and list the rest |

## Workflow

Eight steps. Each ends with a gate. Do not start the next step before the gate passes.

### 1. Brief

Read the request and the project (existing video code, brand files, assets folder) first. Ask only for what is missing, in one batch. Details and the brief template are in [storyboard-and-spec](references/storyboard-and-spec.md).

Needed: the one thing the viewer should do or remember, audience, platform and aspect ratio, length, narration or music or silence, source assets, brand tokens, languages, and whether the result is for commercial use.

When the platform is not stated, state the assumption (16:9, 1920 x 1080, 30 fps unless footage or the platform says otherwise) and carry on.

**Gate:** the brief is written down, with assumptions marked.

### 2. Choose the engine

Pick the engine by the job, not by habit. The matrix, licence notes and install commands are in [engine-choice](references/engine-choice.md). The short rule:

1. An engine already in the project wins.
2. Cutting or joining real footage, or adding sound: ffmpeg.
3. Brand or product motion with text, data and screens: a frame-driven web engine (Remotion or HyperFrames).
4. Maths, diagrams, step-by-step visual proofs: Manim or Motion Canvas.
5. Looping UI animation assets: Lottie or Rive. They are not film engines.
6. Scenes that cannot be filmed or drawn: generative video, as B-roll only.

Check what is installed (`node -v`, `ffmpeg -version`). Never install an engine, a skill or a package without asking. If the engine has an official agent skill and it is installed, use it for engine code. If it is not, recommend installing it and give the command from the table below.

For company or commercial use, read the engine's licence file before committing to it, tell the user the terms, and link the file. Terms change, and one major engine says so in its own licence.

**Gate:** engine chosen, reason stated, licence fit confirmed with the user when use is commercial.

### 3. Storyboard stills

Write a beat sheet (one line per beat: what the viewer learns, seconds, voice line), then draw one still per beat at its most informative moment. Stills can be static layouts captured as images, real screenshots (see `web-screenshot`), or generated images if the user agrees (ask before paid generation). Show them in order.

**Gate:** the user approves order, copy and look. After approval, a change is a change request, not a tweak.

### 4. Numeric spec

Turn the approved stills into a spec file: canvas, fps, a table of shots with start and end in seconds and frames, text sizes as percent of frame height, easing and duration per role, colour and type tokens, audio levels. The template is in [storyboard-and-spec](references/storyboard-and-spec.md). Take timing and size values from `motion-design`, and write any adjective that remains as a number.

**Gate:** no adjective is left unquantified, and shot lengths add up to the total.

### 5. Build

- Open the engine's preview as soon as the project runs, and keep it open.
- Build shot by shot in order. After each shot capture its first, hold and last frames and compare them with the spec.
- Drive everything from the engine's frame or timeline clock. No wall-clock time, no CSS transitions in a frame-driven engine, no unseeded randomness, no network fetches at render time.
- Keep copy, colours and swappable media in variables so a wording change needs no code change.
- Use local fonts and assets, with paths relative to the project.

**Gate:** every shot exists and matches its spec frames. Do not render the final file yet.

### 6. Review loop

Capture frames, look at each, write notes with severity P0, P1 or P2, fix, and capture again. P0 and P1 must be zero before render. At most three rounds, then report what remains. Capture commands, the frame list, the severity definitions and the note format are in [review-loop](references/review-loop.md). Use `image-annotate` to mark a problem on a frame when the user needs to see it.

**Gate:** zero open P0 and P1, and a note listing any P2.

### 7. Audio

Decide the clock first (narration or music), then voice, then music under it, then sound effects that each have a visible cause, then captions. Measure loudness on the final mix and compare it with the target for the platform. Targets, sources and commands are in [audio](references/audio.md).

**Gate:** measured integrated loudness and true peak are on target, and captions exist where the platform or the audience needs them.

### 8. Render and deliver

Render once. Then verify the file, not the render log: probe its streams, capture frames from the actual file, re-measure loudness. Write the delivery note. Encoding settings, verification commands and the note template are in [delivery](references/delivery.md).

**Gate:** the file passes the probe and the loudness check, and the delivery note lists what was and was not verified.

## Pitfalls

- A frame-driven engine ignores CSS transitions and animations, so they snap or vanish in the render. Rewrite them as functions of the current frame.
- A contact sheet shows layout, not motion. Pops, jitter and late text need frame pairs or a frame range around each cut.
- Checking a font or a position by rendering the whole film wastes a cycle. Capture one frame.
- A render that exits cleanly is not a verified video. Probe the file and look at frames taken from it.
- Loudness measured on the voice track alone says nothing about the mix.
- Burned-in captions cannot be turned off or translated. Ship a sidecar caption file when the platform accepts one.
- Generative video model names and availability change within months. Never hard-code a model name into a pipeline or a spec.
- An engine licence can change between versions. Link the licence file in the delivery note.

## Platform notes

Official commands for each engine. Check the linked page before relying on a flag.

| Engine | Official agent skill | Preview | Frames | Render | Source |
|---|---|---|---|---|---|
| Remotion | `npx skills add remotion-dev/skills` | `npx remotion studio` | `npx remotion still`, or `npx remotion render <id> out/frames --frames=0,30,90 --image-format=png` | `npx remotion render <entry> <id> <output>` | https://github.com/remotion-dev/skills, https://www.remotion.dev/docs/cli/render |
| HyperFrames | `npx skills add heygen-com/hyperframes`, or its Claude Code plugin | `npx hyperframes preview` | `npx hyperframes snapshot --review` | `npx hyperframes render` | https://github.com/heygen-com/hyperframes |
| Manim | none found | none | none | `manim -pql <file>.py <Scene>` | https://docs.manim.community/en/stable/tutorials/quickstart.html |
| Motion Canvas | none found | editor | editor Render tab writes an image sequence | convert the frames with ffmpeg | https://motioncanvas.io/docs/rendering |
| ffmpeg | none found | none | `ffmpeg -ss <t> -i in.mp4 -frames:v 1 out.png` | see [delivery](references/delivery.md) | https://ffmpeg.org/ffmpeg.html |
| ElevenLabs audio (voice, music, sound effects, transcription) | `npx skills add elevenlabs/skills` | none | none | none | https://github.com/elevenlabs/skills |

## Reference files

| Reference | Contents |
|---|---|
| [engine-choice](references/engine-choice.md) | Engine matrix, licence terms to re-check, determinism, install commands, generative video rules |
| [storyboard-and-spec](references/storyboard-and-spec.md) | Brief template, beat sheet, storyboard stills, numeric spec template, frame math |
| [review-loop](references/review-loop.md) | Frame capture commands, which frames to capture, P0 P1 P2 notes, motion checks, round limit |
| [audio](references/audio.md) | Clock order, narration, music, sound effects, loudness targets and commands, captions |
| [delivery](references/delivery.md) | Encoding settings, file verification, deliverables list, delivery note template |
| [research-notes](references/research-notes.md) | Research: prior-art table, fact ledger with sources and dates, unconfirmed items |

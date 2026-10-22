---
name: motion-design
description: "Craft rules for anything that moves on a timeline, in video or UI: animate this, motion graphics, title card, intro or outro, transition, explainer that feels like slides, easing, timing, how long to hold text. Gives numeric defaults, an accessibility gate and the tells of generated-looking motion."
user-invocable: false
---

# Motion design

Left alone, an agent animates by reflex: every element fades and rises, one easing curve covers everything, a slow drift runs under every scene, and nobody counts how long a viewer needs to read a headline. The result looks generated and reads like slides. This skill replaces the reflexes with decisions: what the motion is for, how long each part takes, when it must be still, and what makes it unsafe for some viewers.

It is tool-agnostic. It covers the craft of timing, sequence, text, framing and accessibility for video and UI. It holds no engine code, and the build steps live elsewhere (see the `video-production` playbook for the end-to-end workflow).

## Using the numbers

Every number here is a default, tagged by how well it is backed:

| Tag | Meaning |
|---|---|
| **std** | A standard or specification (WCAG, EBU). Treat as a floor or a hard limit |
| **src** | Published guidance from one named source. Good starting point, check it fits the medium |
| **heur** | Practitioner heuristic with no source, or derived from sourced figures. Replace it when the brief, the brand or a reference video says otherwise |

The research notes list each source: [research-notes](references/research-notes.md). A reference video or a brand guide from the user beats every default below.

## 1. Decide what the motion is for

Pick the job before picking a curve. If none fits, hold still.

| Job | Motion serves it by |
|---|---|
| Direct the eye | Moving the thing to look at first, or the next thing |
| Show cause and effect | Starting a reaction on the frame of its cause |
| Show change | Moving or morphing the same object so the viewer tracks identity |
| Set mood | Speed, ease and amplitude as one consistent voice |
| Pace | Contrast between fast and still passages |

Write one line per scene: what the viewer sees first, second, third. Motion starts in that order. A scene with no such line is decoration, and decoration is the first thing to cut.

## 2. Turn adjectives into numbers

"Snappy", "smooth" and "premium" are not specs. Agree a number before building (heur, anchored on 0.1 s to 0.5 s UI ranges from NN/g).

| Tempo | Main move | Use for |
|---|---|---|
| Quick | 0.15 s to 0.3 s | UI feedback, data ticks, energetic cuts |
| Standard | 0.3 s to 0.5 s | Most arrivals and repositioning |
| Calm | 0.5 s to 0.9 s | Hero titles, full-frame changes, premium or slow brands |

Pick one tempo per piece and vary only with a reason.

## 3. Timing by role

Duration and curve follow the role of the move, not one global setting.

| Role | Default | Curve shape | Source |
|---|---|---|---|
| Feedback to a user action | 0.1 s to 0.2 s | Decelerate | src: under 0.1 s feels instant (NN/g) |
| Element arrives | 0.25 s to 0.5 s | Decelerate (starts fast, settles) | src: NN/g names ease-out as the usual choice |
| Reposition on screen | 0.3 s to 0.6 s | Accelerate then decelerate | heur, from the slow-in, slow-out principle |
| Large or full-frame change | 0.4 s to 0.9 s in video, 0.5 s cap in UI | Accelerate then decelerate | src: 500 ms starts to feel like a drag in UI (NN/g) |
| Exit | 70% to 85% of its entrance | Accelerate, or a clean cut | src: leaving elements need less attention (Material 1, NN/g) |
| Constant speed (spin, progress, credits) | As needed | Linear | src: linear UI moves look unnatural (NN/g), so use it only when constant speed is the point |

- A move shorter than about 4 frames reads as a cut, not a move (heur). Check it with the fps rule in section 8.
- Overshoot and bounce suit playful or emphasis beats on position and scale. Opacity and colour have no direction to overshoot. Serious or data-heavy content gets none.
- Exits shorter than entrances is the one rule most often missed. The derived range comes from entering 300 ms and leaving 200 ms to 250 ms (NN/g) and 225 ms and 195 ms (Material 1).

More roles, curve vocabulary and a worked sequence: [timing-and-sequencing](references/timing-and-sequencing.md).

## 4. Sequence: overlap, stagger, one hero

- **Overlap.** Start the next element before the previous one settles (the overlapping action principle). All sequential looks robotic. All at once looks like one block. Start with the next move beginning at about half of the previous one (heur).
- **Stagger.** Elements of one group start 30 ms to 100 ms apart, in reading or priority order, and the whole cascade stays near 0.5 s in UI and 1 s in video (heur, consistent with secondary practitioner ranges). Past 8 to 10 items, group them instead of staggering each one.
- **One hero per beat.** One element moves most. Everything else supports or waits.
- **Cause.** Each move starts because of something visible: a click, an impact, the end of the previous move. An uncaused move reads as an error.

## 5. Holds and reading time

Motion that ends too early leaves nothing to read, and text that moves while being read is hard to read. Land the text, then keep it still.

| Rule | Default | Source |
|---|---|---|
| Hold (fully visible, still) for read-only text | `max(1.0 s, 0.35 s x words)` | heur, derived: silent reading averages about 238 words per minute (0.25 s per word), subtitle norms run 17 to 20 characters per second |
| Entrance time | Not part of the hold | heur |
| Narrated text | Appears with the spoken word and holds until the sentence ends | heur |
| Captions | 42 characters per line, 2 lines, up to 20 characters per second for adults (17 for children), 5/6 s to 7 s on screen | src: Netflix English timed text style guide |

A 9-word headline at 24 fps holds 3.15 s, which is 76 frames. Cut the words before you extend the hold: 6 words or fewer per beat reads faster than 9 words held longer.

## 6. Rhythm

- Contrast makes pace. A fast montage needs a still beat before it, and a payoff needs a short stillness before it lands.
- Scenes of equal length feel like slides. Let content, narration or the beat set the length.
- Nothing changes for several seconds and the viewer thinks the file froze. Give a long hold something small that is happening for a reason (data updating, a cursor acting), not a breathing loop.
- End on a rest frame with the last element still for at least 1 s (heur).

## 7. Transitions with a cause

Choose the transition from the relation between two scenes, not from a menu.

| Relation | Transition |
|---|---|
| Same thought continues | Carry an object across the cut, matching direction and speed on both sides |
| Contrast or surprise | Hard cut |
| Time passes | Dissolve or dip, used sparingly |
| New chapter | One bigger move, reserved for chapters |

Use three or four kinds per piece. A cut lands best mid-motion, with the outgoing and incoming movement on the same axis and direction. A crossfade has nothing to carry the eye, so it is the "slides" signature. Diagnosis and fixes for "feels like slides": [transitions-and-rhythm](references/transitions-and-rhythm.md).

## 8. Frames, type and safe areas

- **fps rule.** Author in seconds. Frames = `round(seconds x fps)`. At 24 fps one frame is 41.7 ms, at 30 fps 33.3 ms, at 60 fps 16.7 ms. Choose fps from the delivery target, then convert. Changing fps late retimes everything.
- **Beat grid.** Frame of beat n = `round(n x fps x 60 / BPM)`, computed from n each time. Adding a rounded beat repeatedly drifts: at 140 BPM and 24 fps a beat is 10.29 frames, and ten frames added 28 times lands 8 frames early.
- **Safe areas.** Keep action inside 3.5% margins and all graphics and text inside 5% margins (std: EBU R95). At 1920 x 1080 that is 67 x 38 px and 96 x 54 px. Web video has no standard, so use the same boxes.
- **Vertical video.** Platform interface covers parts of the frame and the layout changes by platform. Keep text in the middle band and read the platform's current spec before fixing margins.
- **Type size.** Set text as a percent of frame height so it scales. No standard exists. Treat 2% (22 px at 1080p) as an absolute floor for small text and size titles well above it, then check a phone-sized preview (heur).

Details and worked examples: [frames-type-safe-areas](references/frames-type-safe-areas.md).

## 9. Brand motion tokens

Fix a small set once and reuse it: three durations (quick, standard, slow), two curves (arrive, leave), one entrance pattern and one exit pattern. Use a different entrance for a different job, never for variety alone. If the user has a brand, derive the tokens from its voice and write them down before building.

## 10. Accessibility gate

Run this before delivery. Full rules and the reduced-motion approach: [accessibility](references/accessibility.md).

- No more than three flashes in any one second (std: WCAG 2.3.1, Level A). Avoid full-screen light and dark alternation entirely. Check finished video with a photosensitivity analyser.
- Auto-playing motion that lasts over 5 s beside other content needs a pause, stop or hide control (std: WCAG 2.2.2, Level A).
- For web and app UI, honour `prefers-reduced-motion`: replace large movement, zoom and parallax with a fade, do not blank everything.
- Captions for spoken audio (std: WCAG 1.2.2, Level A) and audio description where the picture carries information the audio does not (std: WCAG 1.2.5, Level AA).

## 11. Pitfalls: the look of generated motion

The short list. Each item with its fix is in [looks-generated](references/looks-generated.md).

1. Every element fades in and rises by the same amount.
2. One easing and one duration for everything.
3. A slow drift, float, pulse or push running under every scene.
4. Titles that keep moving after they land.
5. Bounce on serious content.
6. A different transition for every cut, or a crossfade between every scene.
7. Sound effects on every move, or none with no decision.
8. All elements starting on frame 0, with no entrance order and no end rest.
9. Text held for a fixed 2 s whatever its length.
10. Scenes of identical length.

## Reference files

| Reference | Contents |
|---|---|
| [timing-and-sequencing](references/timing-and-sequencing.md) | Role table in full, curve vocabulary by shape, tempo, overlap and stagger, a worked title card, UI versus video |
| [transitions-and-rhythm](references/transitions-and-rhythm.md) | Transition catalogue with causes, the "feels like slides" diagnosis, pacing and scene length |
| [frames-type-safe-areas](references/frames-type-safe-areas.md) | fps and beat math, safe areas in pixels, type sizing, contrast over footage, captions, aspect ratios |
| [looks-generated](references/looks-generated.md) | The tells of generated motion, why each reads as machine-made, and the fix |
| [accessibility](references/accessibility.md) | Flash thresholds, pause rule, reduced motion, captions, motion-triggered discomfort |
| [research-notes](references/research-notes.md) | Prior-art table, fact ledger with sources, unconfirmed items |

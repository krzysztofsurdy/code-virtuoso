# Review loop

## Contents

- [Why frames first](#why-frames-first)
- [Capture frames](#capture-frames)
- [Which frames](#which-frames)
- [What to check in a frame](#what-to-check-in-a-frame)
- [Checks a still cannot make](#checks-a-still-cannot-make)
- [Severity and notes](#severity-and-notes)
- [Rounds and exit](#rounds-and-exit)
- [Show the user](#show-the-user)

## Why frames first

A full render hides which frame is wrong and costs minutes. A frame capture costs seconds and answers one question. The loop is: capture, look, write notes, fix, capture again. The agent must actually look at each captured image (open the file with an image-reading tool) and say what it sees. A review that never opens the images is a guess.

## Capture frames

Use the cheapest route the engine offers.

| Route | Command or action | Notes |
|---|---|---|
| Engine-native still | Remotion: `npx remotion still <entry> <id> --frame=<n>` (see the CLI page). HyperFrames: `npx hyperframes snapshot --review` | Renders the real scene at that frame, no encode |
| Several frames in one call | Remotion: `npx remotion render <id> out/frames --frames=0,30,90 --image-format=png` | The still command takes one frame. `--frames` takes lists and ranges |
| Browser preview | Open the preview URL and capture it with the `web-screenshot` skill, seeking to a frame first when the preview allows | Only for engines whose preview shows an exact frame |
| From a draft render | `ffmpeg -ss <seconds> -i draft.mp4 -frames:v 1 frame.png` | Works for any engine. Costs one low-quality render for the whole set |

Draft renders can be small and fast: render at half size and a cheap encode setting, since layout problems show at any size.

Contact sheet of a whole draft, one frame per second, six columns, scaled to 360 px per tile:

```bash
ffmpeg -i draft.mp4 -vf "fps=1,scale=360:-1,tile=6x2" -frames:v 1 sheet.png
```

Raise the second number in `tile` when the film is longer than twelve seconds, or capture several sheets with `-ss` and `-t`. The `fps=1` value samples one frame per second. A phone-sized tile is also the quickest legibility check for text.

Three consecutive frames around a cut, frames 44 to 46, written as `pair_044.png` and so on:

```bash
ffmpeg -i draft.mp4 -vf "select='between(n,44,46)'" -fps_mode vfr -start_number 44 pair_%03d.png
```

Older ffmpeg guides use `-vsync vfr` for this. Recent builds reject that option and need `-fps_mode vfr`.

## Which frames

| Frame | Why |
|---|---|
| First frame of the film | A blank or half-built first frame is the most common P0 |
| Each shot: first frame, the hold frame, last frame | Entrance, steady state and exit are three different failure sets |
| One frame before and after every cut or transition | Pops and overlaps hide here |
| The frame with the most text | Worst case for the safe boxes and for reading time |
| The frame with text over footage or a busy image | Worst case for contrast |
| The longest translation of each text, when there are several languages | Text overflow is invisible in the source language |
| Last frame of the film | The viewer action must be on screen and held |

## What to check in a frame

Check each captured frame against the spec, not against taste.

1. Does it match the approved still for this beat?
2. Is all text inside the graphics-safe box, and all essential action inside the action-safe box (values in the spec)?
3. Is each text at its spec size, and legible on a phone-sized tile?
4. Is there one hero element, with clear hierarchy?
5. Do colours, fonts and radii match the tokens?
6. Is every number, name and screen real, and copied from the source of truth?
7. Is contrast enough over the actual background in this frame?

The values for safe boxes, type size and contrast come from `motion-design`.

## Checks a still cannot make

A still shows layout. It cannot show a pop, a late arrival or a flash.

| Problem | How to check |
|---|---|
| A single-frame jump or pop at a cut | Capture the frame pair around the cut and compare. To find unplanned hard cuts, list the scene changes in the draft |
| Late or early text | Capture frames at the spec's start frame and the frame before it. Text must be absent before and present at start |
| Flashing | Compare consecutive frames for large luminance swings, and count alternations per second against the three-flash rule in `motion-design` |
| Stuck or frozen frames | Capture one frame every half second through a shot that should move |
| Audio and picture drift | Compare the cue time in the spec with the frame where the visible action lands |

Listing scene changes in a draft, which prints the time of each detected cut:

```bash
ffmpeg -i draft.mp4 -vf "select='gt(scene,0.4)',showinfo" -an -f null - 2>&1 | grep -o "pts_time:[0-9.]*"
```

The threshold 0.4 is a starting point. Lower it to catch softer changes and raise it when a busy scene reports false cuts. Every reported time must match a cut in the spec.

## Severity and notes

| Level | Meaning | Examples |
|---|---|---|
| P0 | The film is wrong or unsafe | Blank or broken frame, text outside the safe box or unreadable, wrong or invented content, flashing past the rule, clipping audio |
| P1 | A spec miss the viewer can notice | Wrong timing, easing, colour or size, text that arrives late, inconsistent tokens, a transition without a cause |
| P2 | Polish | A small spacing nudge, a slightly long hold, a smoother ease |

Write each finding as a row in the review file kept next to the spec:

```markdown
| ID | Time or frame | Level | What is wrong | Fix | Status |
|---|---|---|---|---|---|
| R1-03 | shot 2, frame 78 | P1 | Headline starts 6 frames after its spec start | Move the start to frame 72 | fixed in R2 |
```

Number findings by round (`R1-01`) so a later round can show what was fixed and what came back.

## Rounds and exit

- Fix every P0 and P1, then capture the same frames again and re-check them. A fix often moves something else.
- P2 findings are fixed only when cheap. List the rest in the delivery note.
- At most three rounds. If P0 or P1 findings remain after round three, stop and report them with the frames. A fourth guess usually means the spec or the approved still is wrong, and that needs the user.
- The preview is not the file. After the final render, capture five frames from the actual file (first, last, three that carry the most text) and re-check them, since fonts and codecs differ from the preview.

## Show the user

When a problem needs the user's eye, mark the frame instead of describing it. Use the `image-annotate` skill to box the problem and number it, save the result next to the original, and refer to it by finding ID. Never overwrite the captured frame.

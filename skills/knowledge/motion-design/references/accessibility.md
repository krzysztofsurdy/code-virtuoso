## Contents

- [Flashing](#flashing)
- [Auto-playing motion](#auto-playing-motion)
- [Reduced motion](#reduced-motion)
- [Motion that causes discomfort](#motion-that-causes-discomfort)
- [Captions, audio description and transcripts](#captions-audio-description-and-transcripts)
- [Delivery checklist](#delivery-checklist)

# Accessibility for motion

Flashing can trigger seizures, large movement can cause dizziness and nausea, and moving content competes with reading. These are the rules to check before a piece ships.

## Flashing

WCAG 2.3.1 Three Flashes or Below Threshold (Level A, std): content must not flash more than three times in any one second, or the flash must be below the general flash and red flash thresholds.

| Term | Definition (WCAG 2.2) |
|---|---|
| General flash | A pair of opposing changes in relative luminance of 10% or more of the maximum, where the darker image has relative luminance below 0.80 |
| Red flash | Any pair of opposing transitions involving a saturated red |
| Area limit | A flash passes if the combined flashing area stays within 0.006 steradians, taken as about 341 x 256 px at 1024 x 768 on screen (25% of a 10 degree field) |
| Video | The ITU-R BT.1702 definition applies: a luminance change of 20 cd/m2 or more where the darker image is below 160 cd/m2 |

What this means for motion graphics:

- Fast alternation between a light and a dark full frame counts. A strobe, a rapid hard-cut sequence of bright and dark frames, and a flickering light sweep are all risks.
- A pair means one step up and one step down. Three pairs in a second is the limit, so stay well under it. Use at most two per second as a working margin (heur).
- Large flashing areas matter more than small ones. Flash on a small icon is within the area limit, but do not rely on it without checking.
- Saturated red flashes are held to a stricter test.
- For finished video, run a photosensitivity analyser rather than judging by eye. It measures luminance change per frame against the BT.1702 thresholds. ITU-R BT.1702-3 (2023) is the version listed as current.

## Auto-playing motion

WCAG 2.2.2 Pause, Stop, Hide (Level A, std): for moving, blinking or scrolling information that starts automatically, lasts more than five seconds and sits beside other content, the user needs a way to pause, stop or hide it, unless the movement is essential. W3C notes five seconds was chosen because it is long enough to get a user's attention.

- Looping background motion on a web page needs a control or a stop after 5 s.
- A short intro under 5 s that plays once is outside the rule.
- Auto-updating content (tickers, live data) has no five-second exception.
- For an embedded video, the player's pause control meets the need.

## Reduced motion

`prefers-reduced-motion: reduce` means the user has asked their device to remove, reduce or replace motion animations. MDN's own example swaps a scaling animation for an opacity-only one. WCAG 2.3.3 Animation from Interactions (Level AAA) asks that motion animation triggered by interaction can be disabled unless it is essential.

How to honour it in UI:

1. **Replace, do not blank.** Swap large movement, zoom, spin and parallax for a fade or a small change. Do not apply `animation: none` to everything, because code that waits on `animationend` can break.
2. **Keep information.** A reveal that carries meaning (a step appearing) still needs to appear. It can fade rather than fly in.
3. **Drop decorative loops.** Background drift, pulses and floats are the first to go.
4. **Gate autoplay.** Do not autoplay video for these users, and show a still image first.
5. **Test it.** Turn on the system setting and walk the flow.

For a video file there is no media query. Where the viewer may be sensitive:

- Do not autoplay with sound or motion on a page.
- Offer a reduced-motion cut (no zooms, no parallax, no fast whips, slower pace) or a static summary with the transcript.
- Prefer cuts and fades over large camera moves for the default version when the audience is unknown.

## Motion that causes discomfort

W3C and web.dev name the triggers: parallax (backgrounds moving at a different rate to foregrounds), zooming, and non-scrolling elements that move a lot when the page scrolls. Reactions include dizziness, nausea and headaches (vestibular disorders).

Practical limits for video and UI (heur):

- Avoid sustained zoom or push across the whole frame. If used, keep it slow and short.
- Avoid shaking cameras and whip pans in long sequences.
- Keep parallax to one beat, never the whole piece.
- Spinning full-frame backgrounds are a risk for the same reason.
- Do not combine several large movements at once (camera push, parallax and a spinning background).

## Captions, audio description and transcripts

| Need | Rule |
|---|---|
| Captions for spoken audio in prerecorded video | WCAG 1.2.2, Level A (std) |
| Audio description for prerecorded video where the picture carries information the audio does not | WCAG 1.2.5, Level AA (std) |
| Text inside motion graphics | Provide the same content in a transcript or description, since an image of text has no text alternative |
| Caption format | See [frames-type-safe-areas](frames-type-safe-areas.md): 42 characters per line, 2 lines, reading speed limits |

Write the narration so the audio carries the meaning. Then the picture adds, and audio description is needed less.

## Delivery checklist

1. Flash analysis on finished video, or a written check that nothing flashes more than twice a second.
2. No looping motion beside other content longer than 5 s without a control.
3. A reduced-motion path for UI, or a reduced cut for video where needed.
4. Captions on all spoken audio, and a transcript when text lives in the picture.
5. No sustained full-frame zoom, shake or parallax unless a reduced version exists.
6. Text contrast checked on the worst frame behind it.

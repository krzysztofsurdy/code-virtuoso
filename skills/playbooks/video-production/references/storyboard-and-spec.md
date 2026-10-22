# Brief, storyboard and numeric spec

## Contents

- [Brief](#brief)
- [Beat sheet](#beat-sheet)
- [Storyboard stills](#storyboard-stills)
- [Approval](#approval)
- [Frame math](#frame-math)
- [Numeric spec](#numeric-spec)
- [Turning adjectives into numbers](#turning-adjectives-into-numbers)

## Brief

Fill what the request and the project already answer. Ask for the rest in one message. Mark every assumption.

```markdown
# Brief: <working title>

Viewer action: <the one thing the viewer should do or remember>
Audience: <who, what they already know>
Platform and ratio: <where it plays, 16:9 | 9:16 | 1:1 | 4:5>
Length: <seconds, and whether it is a hard limit>
Sound: <narration | music | both | silent> and language(s)
Source of truth: <product screens, data, script, logo files, with paths>
Brand: <colour and type tokens, motion personality, existing guidelines>
Use: <internal | public | paid ads>, commercial or not
Engine: <chosen in step 2, and why>
Assumptions: <each one, so the user can correct it>
Out of scope: <what this video will not do>
```

Why each field matters: the viewer action fixes what the last frame shows. The platform fixes ratio, length and loudness target. The source of truth stops invented screens. The use field decides whether a licence check is needed.

## Beat sheet

A beat is one idea the viewer takes in. One line each, in order:

| Beat | Viewer learns | Seconds | Voice line | On screen |
|---|---|---|---|---|
| 1 | One sentence | n | Words, or none | The real thing shown |

Rules:

- One idea per beat. Two ideas means two beats.
- The seconds column is a draft. With narration it is replaced by the measured voice length (see [audio](audio.md)).
- The last beat holds the viewer action: a name, a URL or a button, held long enough to read twice.
- Cut any beat whose line the viewer could skip without losing the thread.

## Storyboard stills

One still per beat, drawn at the moment a viewer would pause: the end of the entrance, when everything has landed. Use the cheapest route that shows the real layout.

| Route | Use when | Note |
|---|---|---|
| Real screenshots of the product or page | A beat shows a UI or a site | Capture with the `web-screenshot` skill. Redact secrets with `image-annotate` before showing |
| Static layout (HTML or SVG) captured as an image | Titles, data, diagrams, brand frames | Same fonts and colour tokens as the final, so the approved look is the built look |
| Generated images | The beat is a mood or a scene with no source | Ask before paid generation. Mark the stills as concept only, since the build will not match them |
| Text boards | No image route is available | One line per frame: position, size, colour, content. Weakest option, say so |

Show the stills in a row with the beat number and the voice line under each. Check them against the safe areas and type sizes in `motion-design` now, since moving text after approval is a change request.

## Approval

Ask: "Here are the stills for N beats. Approve the order, the copy and the look, or tell me what to change." Do not build before the answer.

What approval covers: beat order, on-screen words, voice lines, look (colour, type, imagery). It does not cover timing, which comes from the spec.

After approval, record changes in the spec with a line of reason. A request that adds a beat changes length and audio, so say so.

## Frame math

All shot boundaries sit on whole frames. Compute frames from seconds once, in the spec, and use frames in code.

| Quantity | Rule |
|---|---|
| Frames in a shot | `round(seconds x fps)` |
| Seconds of a frame count | `frames / fps` |
| Timeline end | The sum of shot frames, minus overlaps counted once |
| A change of fps | Recompute every shot from the seconds column, never scale frame numbers |

Example at 30 fps: 1.5 s is 45 frames, and a shot from 4.0 s to 7.5 s runs frames 120 to 225.

## Numeric spec

One file per video, kept next to the project. Every cell is a number, a token name or a path.

```markdown
# Spec: <title>

## Canvas
Width x height: 1920 x 1080     fps: 30     Total: <s> = <frames>
Safe boxes: action <px>, graphics <px> (from motion-design)

## Shots
| # | Beat | Start s | End s | Start f | End f | Hero element | Transition in |
|---|---|---|---|---|---|---|---|

## Text
| Role | Size % of height | Weight | Colour token | Max chars | Hold s |
|---|---|---|---|---|---|

## Motion
| Role | Duration s | Easing name | Delay s | Notes |
|---|---|---|---|---|
| Entrance | | | | |
| Exit | | | | |

## Tokens
Colours: <name: hex>     Type: <family, files, licence>     Radius, spacing: <px>

## Audio
Clock: <narration | music>     Voice: <source, file>     Music: <source, licence>
Mix: voice <LUFS> alone, music under voice <dB below>, target integrated <LUFS>, true peak <dBTP>
Effects: <cue, visible cause, file>

## Delivery
Container, codec, ratio, captions file, filename pattern

## Banned by name
<defaults this film will not use, for example the ones listed in motion-design>
```

The "banned by name" list works because it is checkable. Fill it from the pitfalls in `motion-design`.

## Turning adjectives into numbers

Take each adjective from the brief or the feedback and replace it, using `motion-design` for the values.

| Adjective | Becomes |
|---|---|
| Fast, snappy | An entrance duration in seconds, an easing name, a stagger in frames |
| Calm | Longer holds in seconds, fewer simultaneous movers, a count |
| Premium | A restricted palette (token list), one hero per shot, a motion-personality name |
| Readable | A text size as percent of frame height, a hold in seconds, a contrast ratio |
| Big | A percent of frame width or height |
| Lots of energy | A cut rate (cuts per ten seconds), not a mood |

If a value has no source, mark it `(default)` in the spec so a later reader knows it was a choice, not a rule.

## Contents

- [Seconds, frames and the fps rule](#seconds-frames-and-the-fps-rule)
- [Beat grid](#beat-grid)
- [Safe areas](#safe-areas)
- [Aspect ratios and vertical video](#aspect-ratios-and-vertical-video)
- [Type size and hierarchy](#type-size-and-hierarchy)
- [Text over footage](#text-over-footage)
- [Captions and on-screen text timing](#captions-and-on-screen-text-timing)

# Frames, type and safe areas

## Seconds, frames and the fps rule

Write every duration in seconds in the spec. Convert once, at build time:

```
frames = round(seconds x fps)
```

| fps | One frame | 0.1 s | 0.3 s | 1 s |
|---|---|---|---|---|
| 24 | 41.7 ms | 2.4 frames | 7.2 frames | 24 |
| 25 | 40 ms | 2.5 frames | 7.5 frames | 25 |
| 30 | 33.3 ms | 3 frames | 9 frames | 30 |
| 60 | 16.7 ms | 6 frames | 18 frames | 60 |

Rules:

- **Choose fps from the delivery target, then convert.** If the target is not given, ask. Do not pick the rate an animation tool defaults to.
- **Spec in seconds, not frames.** A spec in frames silently changes length when fps changes.
- **Round at the end.** Keep exact seconds through the plan and round only when placing on the frame grid.
- **Smallest move.** A move under about 4 frames reads as a cut (heur). That is 0.17 s at 24 fps and 0.07 s at 60 fps, so a "quick" 0.1 s move needs 60 fps to look like motion.
- **Netflix minimum duration for a subtitle event** is 5/6 s, which is 20 frames at 24 fps (src). Compute other rates as `round(5/6 x fps)`.
- **Do not change fps late.** Retiming every move changes how it feels. Decide early, or rebuild the timing from the seconds spec.
- **Low fps and fast moves.** At 24 fps a fast move jumps a long way between frames. Keep fast moves short and give them a decelerate tail so the last frames land softly.

## Beat grid

For music-driven cuts:

```
frame of beat n = round(n x fps x 60 / BPM)
```

Compute each beat from its index. Adding a rounded beat length repeatedly drifts. Example: 140 BPM at 24 fps gives 10.29 frames per beat. Beats 1 to 4 fall on frames 10, 21, 31 and 41. Adding 10 frames 28 times gives frame 280, while beat 28 belongs on frame 288, so the cuts end 8 frames early.

Cut on the beat. Change the layout on the bar (every fourth beat in 4/4). Use half-beat and quarter-beat divisions for stagger so motion sits on the music.

## Safe areas

EBU Recommendation R95 (version 1.1, 2017) defines two areas for 16:9 television:

| Area | Margin at each edge | Keep inside it |
|---|---|---|
| Action safe | 3.5% | All essential action (std) |
| Graphics safe | 5% | All graphics and text (std) |

At 1920 x 1080:

| Area | Horizontal margin | Vertical margin | Inner box |
|---|---|---|---|
| Action safe | 67 px | 38 px | 1786 x 1004 |
| Graphics safe | 96 px | 54 px | 1728 x 972 |

Why it still matters for web video: displays, players and platform interfaces crop or cover edges unpredictably. Treat the graphics-safe box as the working area for text even when the target is a browser. A background or photo may bleed to the edge. Text and logos may not.

Motion that starts or ends off frame is allowed to cross the margin. The rule applies to where things rest.

## Aspect ratios and vertical video

| Format | Notes |
|---|---|
| 16:9 | Television, most web video. R95 applies |
| 9:16 | Phone full screen. The platform draws interface over the frame |
| 1:1 and 4:5 | Feeds. Text near edges gets cropped in previews |

For 9:16, platform buttons, captions and account names cover parts of the frame, mainly the lower part and the right edge. The exact margins differ by platform and change. One third-party source quotes margins from a platform ad guide, but no first-party figure was confirmed, so no number is given here. Keep important text in the middle band, leave generous space at the bottom, and read the platform's current published spec before fixing margins (see the ledger in [research-notes](research-notes.md)).

When a piece ships in several ratios, design the safe zone for the narrowest one first, then widen.

## Type size and hierarchy

No broadcast standard sets title size as a fraction of the frame. Working defaults (heur):

| Use | Height as share of frame |
|---|---|
| Absolute floor for small text | 2% (22 px at 1080p) |
| Supporting lines, labels | 3% or more |
| Lower-third name | About 4% (44 px to 48 px at 1080p) |
| Headline | Above 5%, one or two lines |

The floor and lower-third values come from vendor style guides (one states 22 px as the minimum body size at 1080p, and two give 44 px to 48 px for a lower-third name). They are single-vendor guidance, so treat them as a check, not a standard.

Rules:

- Size text as a percent of frame height so it scales with resolution.
- Check a phone-sized preview. If a line cannot be read at about a third of full size, enlarge it or cut it.
- Limit to two or three sizes and one or two weights in a piece. The hierarchy is the scale step between them, which should be clear at a glance.
- One accent colour on the one word that carries the meaning.
- Prefer short lines. A headline of 6 words or fewer reads in one look.

## Text over footage

- Put a scrim or a card behind text on busy footage, rather than relying on a drop shadow. A dark gradient from the edge works for lower thirds.
- Check contrast on the worst frame, not the first frame. Moving footage changes the background under static text.
- Keep text away from the faces and focal points of footage.
- Do not animate text across high-detail areas while it must be read.

## Captions and on-screen text timing

| Item | Default | Source |
|---|---|---|
| Characters per line | 42 or fewer | src: Netflix English guide |
| Lines | 2 | src: Netflix |
| Reading speed, adult programs | Up to 20 characters per second | src: Netflix |
| Reading speed, children's programs | Up to 17 characters per second | src: Netflix |
| Minimum event length | 5/6 s | src: Netflix |
| Maximum event length | 7 s | src: Netflix |
| Silent reading speed, English | About 238 words per minute | src: Brysbaert 2019 |
| Hold for read-only text | `max(1.0 s, 0.35 s x words)` | heur, derived |

Derivation of the hold: 238 words per minute is 0.25 s per word, and subtitle norms of 17 to 20 characters per second run at roughly 0.3 s to 0.4 s per word. 0.35 s per word covers slower readers and the glance back at the picture. For fast readers or short phrases, the 1.0 s floor still applies.

When text accompanies narration, appear with the spoken word and hold until the sentence ends. Do not run text ahead of the voice, because viewers read ahead and stop listening.

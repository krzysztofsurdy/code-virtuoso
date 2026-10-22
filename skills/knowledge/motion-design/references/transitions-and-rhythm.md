## Contents

- [What makes motion feel like slides](#what-makes-motion-feel-like-slides)
- [The fix, in order](#the-fix-in-order)
- [Transition catalogue](#transition-catalogue)
- [Continuity at a cut](#continuity-at-a-cut)
- [Rhythm and scene length](#rhythm-and-scene-length)
- [Stillness and the payoff](#stillness-and-the-payoff)
- [Beginnings and endings](#beginnings-and-endings)

# Transitions and rhythm

## What makes motion feel like slides

A slide deck is a set of separate pictures. A video feels like one piece when the eye is handed from one thing to the next. Motion feels like slides when:

| Cause | What the viewer sees |
|---|---|
| Every scene starts from an empty frame | Each scene is a new page |
| Scenes join with a dissolve or a hard cut that matches nothing | No object or direction carries across |
| Every scene enters the same way | The pattern becomes a template |
| Scenes have the same length | The beat is a metronome |
| Elements land and then nothing happens | Dead time between events |
| Text blocks fill the frame | The viewer reads instead of watching |

## The fix, in order

Apply these top to bottom and stop when the piece feels continuous. The first two usually do most of the work.

1. **Carry something across each seam.** Pick an object that is in the outgoing scene and make it part of the incoming one: a shape that grows into the next layout, a line that becomes a chart axis, a card that docks into the next screen. Match its position and speed at the cut.
2. **Cut mid-motion.** End the outgoing scene while its last move is still travelling, and start the incoming move already in travel, in the same direction. Settling to rest before a cut and starting from rest after it is a dead beat.
3. **Vary the entrance.** Give different jobs different entrances (a label slides in from its target, a number counts up, a shape draws). Keep one family of curves so the variety still reads as one voice.
4. **Vary scene length.** Let narration, content or the beat decide each length.
5. **Put the idea in motion, not the text.** Draw the connection, move the object along the process, grow the bar. Cut on-screen words to what the picture cannot say.
6. **Keep something happening for a reason.** Content that is itself moving (a product UI at work, footage, a chart updating) fills a long beat. A decorative loop does not (see [looks-generated](looks-generated.md)).

Do not "fix" slides with a camera drift on every scene. It adds motion without a cause and reads as a template.

## Transition catalogue

Use three or four kinds in one piece. Each must have a cause on screen.

| Transition | Cause | How it works | Cost if misused |
|---|---|---|---|
| Hard cut | Contrast, surprise, a new place | No overlap, optionally a short dip beforehand | None. Overusing it is fine inside a scene, tiring between every scene |
| Match cut | Two things share a shape or position | Cut where the shapes align | Looks accidental if alignment is off by a few pixels |
| Carry across | Same thought continues | One object moves from scene A into scene B | Needs a real object in both scenes |
| Push or slide | Next step in a sequence | Both scenes move on one axis in one direction | Ping-pong directions read as an error |
| Zoom through | Going deeper into the same subject | Scale up through an element into the next | Overused, it becomes a gimmick |
| Dissolve | Time passes, soft mood | Cross-fade for a short time | A dissolve between unrelated scenes is the slides signature |
| Dip to colour | A clean break, a chapter end | Fade to a flat colour, then up | Slow and heavy if long |
| Wipe or mask reveal | A reveal tied to a shape on screen | A mask opens from an element | Decorative wipes with no source are noise |

Rules:

- Pick one dominant direction per piece for ordinary next-step moves. Reserve other directions (up for a conclusion, toward the camera for arrival) so they carry meaning.
- Never run two consecutive seams in opposite directions without a visible cause.
- A direction change needs a cause (an impact, a click, a chapter boundary).
- Spinning cubes, page curls and random built-in wipes cause nothing, so leave them out.

## Continuity at a cut

Continuity of movement across a cut is the film-editing idea of cutting on action. It gives three things to match:

1. **Axis.** Horizontal stays horizontal.
2. **Direction.** Do not mirror. A shrinking exit answered by a grow-from-small entry has opposite direction on the depth axis.
3. **Speed.** The incoming move starts at about the speed the outgoing move had. Pair an accelerate curve on the exit with a decelerate curve on the entry, with the same distance and duration.

Check by taking stills a few frames before and after the cut. The object should be in nearly the same place, with the same blur or lean, and heading the same way.

## Rhythm and scene length

- **Contrast speeds.** A piece of one speed feels flat. Alternate fast cuts with a slow, held shot, or quick small moves with one large one.
- **Scene length follows content.** Short for a simple statement, long for a demo that needs to be followed. Equal lengths only when the equal beat is the style.
- **Let audio set the clock.** A narration or music track fixes the timing. Retime scenes to the real word or beat positions, never rush a spoken line to fit a slot.
- **Beat grid.** For music, compute every beat from its index: frame = `round(n x fps x 60 / BPM)`. Cut on the beat and change the layout on the bar (every four beats in 4/4).
- **A pause is a beat.** A short hold before a key reveal makes the reveal register.

No standard sets an ideal shot length. Cutting and colleagues (2011, *i-Perception*) measured 160 English-language films from 1935 to 2010 and found shots getting shorter over time, which supports varying length rather than prescribing one number. Use the content to choose.

## Stillness and the payoff

- A heavy beat (a result, a price, a claim) works after a short stillness. Give the viewer a still moment of roughly 0.3 s to 0.7 s before the payoff (heur) and then let the payoff play at normal speed.
- Do not stack accents. One emphasis per beat, because two cancel each other.
- When something lands, let it be still. Motion moves on to the next element, the camera or the background.

## Beginnings and endings

- **Open** with the subject or the first image within about a second or two, not a long logo sting (heur, platform dependent).
- **End** on a rest frame with the last element still for at least 1 s, then cut or fade out. A piece that cuts in mid-motion at its last frame looks cropped.
- **Loops** (for a looping asset such as a GIF or an ambient screen) must match their first and last frames, otherwise the jump shows each cycle.

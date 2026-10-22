## Contents

- [Why timing is a role decision](#why-timing-is-a-role-decision)
- [Curve vocabulary by shape](#curve-vocabulary-by-shape)
- [Role table in full](#role-table-in-full)
- [Tempo and personality](#tempo-and-personality)
- [Overlap, stagger and order](#overlap-stagger-and-order)
- [UI versus video](#ui-versus-video)
- [Worked example: a title card](#worked-example-a-title-card)
- [Checks before you call the timing done](#checks-before-you-call-the-timing-done)

# Timing and sequencing

## Why timing is a role decision

Real objects need time to speed up and slow down, and lighter objects react faster than heavy ones. These are the slow in and slow out and timing principles from Thomas and Johnston, *The Illusion of Life* (1981). They give one working rule: the duration and curve of a move say what the thing is and why it moves. A single global setting says nothing, so everything feels the same.

Two limits frame the numbers:

- Under about 0.1 s a response feels instant, so a reaction to a user action needs no more than that to feel direct (NN/g, citing Miller 1968 and Card et al. 1991).
- In UI, most animations sit between 100 ms and 500 ms, and 500 ms starts to feel like a drag (NN/g). Video has no user waiting, so calm moves can run longer, but the same drag shows up when a simple move takes more than about a second.

## Curve vocabulary by shape

Curves are named here by shape, so they map to any tool (a cubic-bezier, a named ease, a spring).

| Shape | Behaviour | Use for |
|---|---|---|
| Decelerate | Fast start, long soft landing | Arrivals, anything entering the frame |
| Accelerate | Slow start, fast finish | Exits, objects leaving or pushed away |
| Accelerate then decelerate | Gentle both ends | Moving something already on screen, camera moves, colour changes of a whole background |
| Linear | Constant speed | Rotation, progress bars, crawling text, continuous loops |
| Spring, light | One small overshoot, settles | Friendly UI, a single emphasis |
| Spring, strong | Visible bounce | Playful or cartoon content only |

How to choose when unsure: decelerate for arrival, accelerate for exit, both ends gentle for anything that stays in frame. Steep curves (a long, thin tail on the landing) read as confident and premium. Gentle curves read as soft and neutral. This is judgment, not a measured fact (heur).

## Role table in full

| Role | Duration | Shape | Notes |
|---|---|---|---|
| Press or toggle feedback | 0.1 s | Decelerate | Anything slower feels laggy (NN/g: about 100 ms for simple feedback) |
| Small UI change (tooltip, chip, menu) | 0.15 s to 0.3 s | Decelerate | |
| Panel, modal or card entering | 0.2 s to 0.4 s | Decelerate | NN/g gives 200 ms to 300 ms for substantial screen changes |
| Same panel leaving | 70% to 85% of the entrance | Accelerate | Entering 300 ms and leaving 200 ms to 250 ms (NN/g), 225 ms and 195 ms (Material 1) |
| Text arriving in video | 0.3 s to 0.6 s per unit (line or word group) | Decelerate | heur |
| Hero object or logo arriving | 0.5 s to 0.9 s | Decelerate, steep | heur |
| Camera move, pan or push | 0.7 s to 1.5 s | Accelerate then decelerate | heur. Slow it down if viewers say "too fast" |
| Full-frame change (colour flood, layout swap) | 0.4 s to 0.9 s | Accelerate then decelerate | |
| Ambient loop (only when it carries meaning) | One cycle at least 2 s | Linear or gentle both ends | Section "Looks generated" explains why most should be cut |
| Data update (number tick, bar growth) | 0.3 s to 0.8 s | Decelerate | Tie length to the size of the change |

Scale duration with distance and size. A long travel across a large frame needs more time than a short nudge, or it will look like a snap (NN/g and Material 1 both say duration grows with travel and surface change).

## Tempo and personality

One tempo per piece, then variation only with a cause.

| Voice | Main move | Curve lean | Overshoot |
|---|---|---|---|
| Direct, technical | 0.2 s to 0.35 s | Decelerate | None |
| Warm, friendly | 0.3 s to 0.5 s | Decelerate, light spring on one emphasis | Small |
| Premium, calm | 0.5 s to 0.9 s | Steep decelerate, gentle both ends | None |
| Energetic, youth | 0.15 s to 0.3 s | Decelerate, strong spring on hits | Visible |

These rows are a starting grid (heur). The idea of mapping a brand personality to a duration and curve family comes from the motion-personality approach in LottieFiles' motion-design skill, rewritten here with independently sourced ranges. Write the chosen row into the spec so every later decision can be checked against it.

## Overlap, stagger and order

- **Overlap.** The overlapping action and follow-through principles say parts of a thing do not all start and stop together. Start the next element when the previous one is about half done. Fully sequential motion looks robotic, and everything at once reads as a block (heur on the half-way figure).
- **Stagger.** A group of similar items starts 30 ms to 100 ms apart. Practitioner references for UI put list items at roughly 20 ms to 100 ms and cap the whole cascade near 400 ms to 600 ms. No standard or official source gives a number, so treat these as secondary figures (heur). In video the cascade can reach about 1 s because the viewer is watching, not waiting.
- **Order.** Stagger in reading order (left to right, top to bottom) or in order of importance. Never random.
- **Count limit.** Past 8 to 10 items, bring the remainder in together, otherwise the last item starts too late.
- **Group, then detail.** Bring the container first, then its contents, so the eye knows where to look before it reads.
- **Cause.** Chain motion so each move starts on the frame of the thing that causes it. A reaction that begins "shortly after" its cause feels disconnected. Reactions scale with implied weight: heavy things settle slowly, light things snap.

## UI versus video

| Concern | UI | Video |
|---|---|---|
| Viewer waits on the motion | Yes, so keep it short | No, so calm moves are fine |
| Interrupts | Must be interruptible | Not applicable, but must survive a pause on any frame |
| Length of a main move | 0.1 s to 0.5 s | 0.3 s to 0.9 s |
| Text | Appears with the screen | Needs a hold long enough to read |
| Frame rate | Display rate, 60 fps typical | Delivery rate, often 24, 25 or 30 fps |
| Reduced motion | A user setting to honour | No setting, so deliver an alternative if needed |

Motion that is smooth at 60 fps can look choppy at 24 fps because a fast move covers a large distance per frame. At low fps keep fast moves short and add a decelerate tail so the last frames land gently.

## Worked example: a title card

Brief: a 7 s intro with a logo, a 9-word headline and a tagline, 24 fps, calm voice.

| Time | Event | Duration | Shape |
|---|---|---|---|
| 0.0 s to 0.5 s | Hold on the starting frame (background only) | 0.5 s | none |
| 0.5 s to 1.2 s | Logo arrives | 0.7 s | Decelerate, steep |
| 1.4 s to 2.1 s | Logo moves up and shrinks to make room | 0.7 s | Accelerate then decelerate |
| 1.6 s to 2.25 s | Headline arrives as two word groups, 0.15 s apart | 0.5 s each | Decelerate |
| 2.25 s to 5.4 s | Headline fully visible and still (9 words x 0.35 s = 3.15 s) | 3.15 s | none |
| 3.2 s to 3.7 s | Tagline arrives while the headline is still held | 0.5 s | Decelerate |
| 3.7 s to 5.4 s | Tagline holds, well over the 1.0 s minimum | 1.7 s | none |
| 5.4 s to 5.8 s | Tagline, headline and logo leave together | 0.4 s (70% of a 0.6 s entrance) | Accelerate |
| 5.8 s to 7.0 s | Rest frame | 1.2 s | none |

In frames at 24 fps: the logo arrival is 17 frames (0.7 s x 24 = 16.8), the 3.15 s headline hold is 76 frames, and the exit is 10 frames. Nothing drifts under the hold, because the viewer is reading. If 7 s is too long for the use, cut the tagline first and shorten the hold last.

## Checks before you call the timing done

1. Every duration traces to a role row or a stated reason.
2. Exits are shorter than their entrances.
3. Every text block has a hold computed from its word count.
4. No move shorter than 4 frames at the delivery fps.
5. Nothing moves under a block the viewer must read.
6. The last element is still for at least 1 s.

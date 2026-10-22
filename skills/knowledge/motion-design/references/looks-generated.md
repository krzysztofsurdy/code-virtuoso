## Contents

- [Why these read as machine-made](#why-these-read-as-machine-made)
- [Timing and curves](#timing-and-curves)
- [Sequence and structure](#sequence-and-structure)
- [Decoration](#decoration)
- [Text](#text)
- [Sound](#sound)
- [Self-check before delivery](#self-check-before-delivery)

# Looks generated: the tells

A piece reads as generated when its choices were made once and applied everywhere. A person making motion varies things for reasons: this move is heavy, that one is a reaction, this scene is short because the point is small. Every tell below is a uniform default standing in for a decision. The fix is always the same: make the decision for this element, and write the reason in the spec.

These tells come from the baseline gaps seen when an agent was asked to plan a title card and to fix an explainer that "feels like slides" with no guidance, and from craft practice. Ideas about uniform defaults as a tell are shared with practitioner skills named in [research-notes](research-notes.md). The wording and numbers here are original.

## Timing and curves

| Tell | Why it reads as generated | Fix |
|---|---|---|
| One ease and one duration for every move | Nothing has weight or role, so everything feels alike | Choose curve and duration per role (see [timing-and-sequencing](timing-and-sequencing.md)) |
| Exits as long as entrances | Leaving elements need less attention, so equal time feels sluggish | Make exits 70% to 85% of the entrance, or cut |
| Everything eases out | Exits and repositioning need other shapes | Accelerate on exit, both ends gentle on repositioning |
| Linear on moves that should settle | Linear UI moves look unnatural | Reserve linear for constant speed |
| Every move 0.5 s because it is "standard" | The rhythm is flat | Vary with size, distance and role |
| Moves under 4 frames | They read as cuts and flicker | Lengthen or use a cut on purpose |

## Sequence and structure

| Tell | Why | Fix |
|---|---|---|
| Every element fades in and rises by the same distance | A template pattern, no hierarchy | Vary entrance by job. Let the hero enter differently from support elements |
| All elements start on frame 0 | The viewer cannot tell what to look at first | Order the starts. One hero per beat |
| Nothing overlaps | Robotic, each step waits for the last | Start the next move at about half of the previous one |
| Everything overlaps | One mushy block | Let one move lead, the rest follow |
| Every scene is the same length | A metronome | Set lengths from content or audio |
| Every scene starts from an empty frame | Slides | Carry an object across the seam |
| A crossfade between each scene | No carrier for the eye | Use a transition with a cause |
| A different fancy transition at each cut | A menu, not a voice | Three or four kinds, each with a cause |
| No rest at the end | Cropped feel | Hold the last element still for 1 s or more |

## Decoration

| Tell | Why | Fix |
|---|---|---|
| A slow drift, push, float or pulse under every scene | Motion without a cause, so it reads as "the video is waiting" | Remove it, or replace it with content that moves for a reason |
| Titles that keep scaling or sliding after they land | The viewer cannot read moving text | Land the title, then keep it still |
| Bounce on serious content | Wrong tone | Use no overshoot on data, legal and clinical content |
| Parallax or push on every layer | Adds vestibular risk for nothing | Use it on at most one deliberate beat, with a reduced alternative |
| Gradient blobs, glows and light sweeps as filler | Stock-template look | Make the background quiet and put the effort into the subject |
| Icons from a pack with mixed styles | Visual noise | Use one style, or the product's real imagery |
| A particle or shimmer on every hit | Dilutes impact | Spend effects on the one moment that matters |

## Text

| Tell | Why | Fix |
|---|---|---|
| Fixed 2 s hold whatever the length | A long line is unreadable, a short line drags | Hold `max(1.0 s, 0.35 s x words)` |
| Text that animates letter by letter for long lines | The reading speed is set by the animation | Reveal by word group, or all at once |
| Five bullets all at once | The viewer reads instead of watching | One idea per beat, drawn as a picture where possible |
| Centred text on everything | Safe default, no hierarchy | Align to the layout and use scale to rank |
| Text outside the safe box | Cropped on some players | Keep it in the 5% margin box |

## Sound

| Tell | Why | Fix |
|---|---|---|
| A whoosh on every move | The sound loses meaning | Add sound only where an on-screen action causes it |
| No decision about audio | Silent by accident | State whether the piece is silent, scored or narrated, and why |
| Music that ignores the cuts | The edit feels unplanned | Cut on beats, change layout on the bar |

## Self-check before delivery

1. Pick three random frames. Does each have one clear thing to look at?
2. Count distinct entrance styles and distinct transitions. Is it more than one but fewer than five?
3. Is any motion running with no cause?
4. Are exits shorter than entrances?
5. Does any text move while it must be read?
6. Does each text block hold for its computed time?
7. Do the first and last seconds show the subject?

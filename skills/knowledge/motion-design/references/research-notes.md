## Contents

- [Scope](#scope)
- [Sources](#sources)
- [Prior art](#prior-art)
- [Fact ledger](#fact-ledger)
- [Baseline](#baseline)
- [Not confirmed](#not-confirmed)
- [Left out](#left-out)

# Research notes: motion design

Date: 2026-10-22
Depth: deep (many tools and standards, numbers that must be sourced independently)
Research skill used: yes, followed inline by one agent with web search and page fetches. Parallel agents were not used because the sub-questions fed each other.
Prior-art search: done

## Scope

Covers tool-agnostic craft for any timed visual (video and UI): purpose, timing and easing by role, overlap and stagger, holds against reading speed, transitions with a cause, frame math, safe areas, type size, accessibility, and the tells of generated motion. It does not cover engines, rendering, audio mastering or delivery, which belong to the `video-production` playbook.

Questions the research answered:

1. Which numeric defaults have a source other than a single vendor's launch films?
2. What do WCAG, ITU and the EBU require for flashing and safe areas?
3. What reading speeds and subtitle limits apply to on-screen text?
4. Which skills already cover this, and what do they miss?

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://www.w3.org/WAI/WCAG22/Understanding/captions-prerecorded.html | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://www.w3.org/WAI/WCAG22/Understanding/audio-description-prerecorded.html | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://www.w3.org/TR/WCAG22/ (levels of 2.3.1, 2.2.2, 2.3.3) | standard | W3C | WCAG 2.2 | 2026-10-22 |
| https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion | vendor docs | MDN | unknown | 2026-10-22 |
| https://web.dev/articles/prefers-reduced-motion | vendor docs | Google | unknown | 2026-10-22 |
| https://tech.ebu.ch/docs/r/r095.pdf (EBU R95 v1.1) | standard | EBU | 2017-06 | 2026-10-22 |
| https://tech.ebu.ch/docs/r/r128.pdf (EBU R128) | standard | EBU | 2023-11 | 2026-10-22 |
| https://www.itu.int/rec/R-REC-BT.1702/en (listing only) | standard | ITU | BT.1702-3, 2023-11 | 2026-10-22 |
| https://www.nngroup.com/articles/animation-duration/ | practitioner research | Nielsen Norman Group | unknown | 2026-10-22 |
| https://www.nngroup.com/articles/response-times-3-important-limits/ | practitioner research | Nielsen Norman Group | unknown | 2026-10-22 |
| https://m1.material.io/motion/duration-easing.html | vendor design system | Google (Material 1) | unknown | 2026-10-22 |
| https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977-English-Timed-Text-Style-Guide | vendor spec | Netflix | unknown | 2026-10-22 |
| https://partnerhelp.netflixstudios.com/hc/en-us/articles/215758617-Timed-Text-Style-Guide-General-Requirements | vendor spec | Netflix | unknown | 2026-10-22 |
| https://www.bps.org.uk/research-digest/most-comprehensive-review-date-finds-average-persons-reading-speed-slower | summary of a paper | British Psychological Society | 2019 | 2026-10-22 |
| Brysbaert (2019), "How many words do we read per minute?", Journal of Memory and Language (found by search, summary only) | peer-reviewed paper | Elsevier | 2019 | 2026-10-22 |
| https://support.spotify.com/artists/article/loudness-normalization/ | vendor docs | Spotify | unknown | 2026-10-22 |
| https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation | secondary | Wikipedia | n/a | 2026-10-22 |
| Cutting et al. (2011), i-Perception, shot length in 160 films (found by search, abstract summary only) | peer-reviewed paper | SAGE | 2011 | 2026-10-22 |
| Candidate skills listed below | community and vendor | various | see table | 2026-10-22 |

## Prior art

Queries run: `gh search repos "motion design skill" --sort stars --limit 8 --json ...`; `gh api repos/<owner>/<repo>/git/trees/main?recursive=1` for each candidate; `gh api repos/<owner>/<repo>/contents/<path>` to read each SKILL.md; web search for "motion design skill" patterns. `npx skills find "motion design"` could not run in this environment (the `timeout` wrapper used was missing), so the registry tier was not checked. Local check: no existing skill in `skills/`, nor installed skills other than Remotion and ElevenLabs, covers tool-agnostic motion craft.

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| heygen-com/hyperframes (`motion-doctrine`, `skills/hyperframes/references/motion.md`) | https://github.com/heygen-com/hyperframes | vendor of the HyperFrames engine | 69.6k stars, 2026-10-22 | Motion and video craft inside HyperFrames: easing by role, exits shorter than entrances, overlap, stagger, holds, transitions with a cause, "defaults that look generated", continuity at seams | The deepest craft guidance found. A seam law (match axis, direction and speed across a cut), carriers, no idle wobble | Welded to its CLI, registry and GSAP. Numbers are measured from the vendor's own launch films, so they are one source | Apache-2.0 |
| LottieFiles/motion-design-skill | https://github.com/LottieFiles/motion-design-skill | vendor (Lottie) | 2.4k stars, 2026-05-18 | UI motion: personality archetypes, Disney principles, timing and easing tables, checklist | Maps brand personality to duration and curve. Brand motion identity as three constants | UI micro-interactions only: no video, no holds against reading, no accessibility numbers | MIT |
| iart-ai/motion-design-skills (`animation-principles`, `motion-art-direction`, `shot-composition`, `beat-sync-editing`) | https://github.com/iart-ai/motion-design-skills | community | 152 stars, 2026-06-22 | Tech-agnostic motion fundamentals plus engines (After Effects, Remotion), composition with safe areas, BPM to frames | Closest in scope. Covers beat math, restraint, "what earns motion", cross-shot consistency | Numbers track other skills and carry no sources. No flash or reduced-motion gate. Tied in part to After Effects and Remotion | MIT |
| emilkowalski/skills (`animate`, `review-animations`, others) | https://github.com/emilkowalski/skills | community, well known author | 48.6k stars, 2026-10-11 | Web UI animation: a gate on whether to animate at all, build, audit | Clear "should it animate" decision first. Separate build and review roles | Web UI only. No video, no timeline craft | MIT |
| kylezantos/design-motion-principles | https://github.com/kylezantos/design-motion-principles | community | 1.4k stars, 2026-05-30 | UI motion build and audit, drawing on three designers, catches "AI slop" patterns | Audit mode that names generated-looking patterns | UI and React-centred. No video | MIT |
| remotion-dev/skills | https://github.com/remotion-dev/skills | vendor (Remotion) | 5.5k stars, 2026-10-19 | Remotion engine usage and its verification loop | Official and current for its engine | Engine specific. No licence file in the repo, so ideas only | none stated |
| affaan-m/ecc (video-editing) and adithya-s-k/manim_skill | https://github.com/affaan-m/ecc, https://github.com/adithya-s-k/manim_skill | community | 286k and 1.2k stars | Thin editing guidance tied to that stack, and Manim usage | Narrow and usable for its engine | Not general craft | MIT, MIT |

Decision: write a new skill. No candidate combines independently sourced numbers, the accessibility gate (WCAG 2.3.1, 2.2.2, reduced motion), reading-time arithmetic for on-screen text, an fps rule and EBU safe areas in a tool-agnostic form. `iart-ai/motion-design-skills` is the nearest alternative and may be worth recommending alongside. Recommend installing the official Remotion and ElevenLabs skills for those engines rather than rebuilding them.

Strengths adopted as ideas (no text copied):

- HyperFrames: continuity of axis, direction and speed across a cut. Exits shorter than entrances. Overlap and stagger. Transitions need a cause. A list of generated-looking defaults. Hold time tied to reading. (Numbers were not used. Each was re-sourced or re-derived, see the ledger.)
- LottieFiles: map a personality to a duration and curve family. Fix a small set of motion tokens (three durations, one signature curve, one entrance pattern).
- iart-ai: hold discipline and "what earns motion". Beat-to-frame conversion, written here with an original example.
- Emil Kowalski: ask whether to animate at all before choosing a curve.
- kylezantos: a named audit for generated-looking patterns.

Weaknesses avoided: single-vendor numbers, engine-specific code, no accessibility gate, unsourced durations, UI-only scope.

## Fact ledger

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | WCAG 2.3.1 (Level A): no more than three flashes in any one second, or below the general and red flash thresholds | https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html and https://www.w3.org/TR/WCAG22/ | 2026-10-22 | WCAG 2.2 | confirmed | read both W3C pages (text and level) |
| 2 | General flash: pair of opposing changes of 10% or more of max relative luminance where the darker image is below 0.80. Area limit 0.006 steradians, about 341 x 256 px at 1024 x 768 | same | 2026-10-22 | WCAG 2.2 | confirmed (primary, one publisher) | read page |
| 3 | Red flash: saturated red pair, R/(R+G+B) at least 0.8 and a chromaticity change above 0.2 | same | 2026-10-22 | WCAG 2.2 | likely | read page, single publisher |
| 4 | For video the ITU-R BT.1702 definition applies (20 cd/m2 change, darker image below 160 cd/m2). BT.1702-3 (2023-11) is listed as in force | W3C page and https://www.itu.int/rec/R-REC-BT.1702/en | 2026-10-22 | BT.1702-3 | likely | W3C quotes it, ITU listing seen in search results, not opened in full |
| 5 | WCAG 2.2.2 (Level A): auto-starting moving content over 5 s beside other content needs pause, stop or hide. Five seconds chosen because it is long enough to get attention | https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html | 2026-10-22 | WCAG 2.2 | confirmed | read page and level |
| 6 | WCAG 2.3.3 (Level AAA): motion animation triggered by interaction can be disabled unless essential | https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html | 2026-10-22 | WCAG 2.2 | confirmed | read page |
| 7 | WCAG 1.2.2 captions for prerecorded audio is Level A. 1.2.5 audio description for prerecorded video is Level AA | W3C Understanding pages for each | 2026-10-22 | WCAG 2.2 | confirmed | read both pages |
| 8 | `prefers-reduced-motion: reduce` means the user asks to remove, reduce or replace motion. MDN example swaps scaling for opacity | https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-reduced-motion | 2026-10-22 | n/a | confirmed | MDN plus web.dev agree |
| 9 | `animation: none !important` can break code that depends on `animationend`. Parallax, scrolling effects and zooming can trigger vestibular reactions (dizziness, nausea, migraine) | https://web.dev/articles/prefers-reduced-motion | 2026-10-22 | n/a | confirmed | web.dev and W3C (2.3.3 page names parallax, dizziness, nausea, headaches) |
| 10 | EBU R95 v1.1 (2017): action safe area is 3.5% and graphics safe area is 5% at the top, bottom and sides of a 16:9 picture | https://tech.ebu.ch/docs/r/r095.pdf | 2026-10-22 | v1.1 | likely | read the PDF text (Note 5). One primary source. HyperFrames' own docs state a different pair (90% and 80%), which is not independent confirmation |
| 11 | NN/g: most animations 100 ms to 500 ms. Simple feedback about 100 ms. Substantial screen changes 200 ms to 300 ms. 400 ms is slow. 500 ms feels like a drag. Entering needs a slightly longer duration than exiting (example 300 ms and 200 ms to 250 ms). Linear looks unnatural. Ease-out is the common choice | https://www.nngroup.com/articles/animation-duration/ | 2026-10-22 | n/a | confirmed | read NN/g, Material 1 agrees (row 12) |
| 12 | Material 1: mobile transitions about 300 ms. Entering 225 ms. Leaving 195 ms. Large transitions 375 ms. Over 400 ms may feel too slow. Leaving elements may be shorter because they need less attention | https://m1.material.io/motion/duration-easing.html | 2026-10-22 | Material 1 | confirmed | read page. Material 2 and 3 pages are script rendered and could not be read |
| 13 | NN/g: under 0.1 s feels instant, 1 s keeps the train of thought, 10 s loses attention (Miller 1968, Card et al. 1991) | https://www.nngroup.com/articles/response-times-3-important-limits/ | 2026-10-22 | n/a | confirmed | read page |
| 14 | Derived: exit is about 70% to 85% of its entrance (225 to 195 is 87%, 300 to 250 is 83%, 300 to 200 is 67%) | rows 11 and 12 | 2026-10-22 | n/a | derived, likely | computed |
| 15 | Silent reading of English averages about 238 words per minute (all studies 238 across 190 studies, English only 236 across 144) | BPS digest and Brysbaert 2019 | 2026-10-22 | n/a | likely | BPS digest read. The paper itself was not opened. The digest says 17,887 participants and search summaries say 18,573, so no participant count is used |
| 16 | Netflix English: 42 characters per line, 2 lines, up to 20 characters per second for adult programs and 17 for children's, minimum event 5/6 s (20 frames at 24 fps), maximum 7 s | Netflix English and general timed text pages | 2026-10-22 | n/a | confirmed | read both pages |
| 17 | Hold = `max(1.0 s, 0.35 s x words)`, from rows 15 and 16 (0.25 s per word silent reading, 0.3 s to 0.4 s per word subtitle norms) | rows 15 and 16 | 2026-10-22 | n/a | derived heuristic | computed |
| 18 | Twelve principles of animation including slow in and slow out, timing, follow-through and overlapping action, from Thomas and Johnston, *The Illusion of Life* (1981) | https://en.wikipedia.org/wiki/Twelve_basic_principles_of_animation | 2026-10-22 | n/a | likely | secondary page only, book not opened |
| 19 | frames = round(seconds x fps). Frame durations at 24, 25, 30, 60 fps. Beat example: 140 BPM at 24 fps is 10.2857 frames per beat, ten frames x 28 beats lands on 280 while beat 28 is at 288 | arithmetic | 2026-10-22 | n/a | confirmed | ran in python3 |
| 20 | Safe-area pixels at 1920 x 1080: action 67 x 38, graphics 96 x 54, inner boxes 1786 x 1004 and 1728 x 972 | arithmetic from row 10 | 2026-10-22 | n/a | confirmed | ran in python3 |
| 21 | Stagger of 20 ms to 100 ms per item, cascade cap about 400 ms to 600 ms in UI | secondary practitioner pages seen in search results, no first-party number | 2026-10-22 | n/a | single-source, heuristic | search results only. Marked heur in the skill |
| 22 | Text size floor near 22 px at 1080p and lower-third names at 44 px to 48 px | vendor style guides (Towbook, Square) and an ARPP legal rule, via search results | 2026-10-22 | n/a | single-source, heuristic | search summary only. Marked heur in the skill |
| 23 | Cutting et al. (2011) measured 160 English-language films from 1935 to 2010 and found shots getting shorter | SAGE i-Perception, via search summary | 2026-10-22 | n/a | likely | abstract summarised by search, paper page returned 403 |

## Baseline

Prompt without the skill, run by a separate agent, two requests: a 12 s title card plan, and fixing a 30 s five-scene explainer that "feels like slides". What it got wrong or left out:

- Planned a slow linear scale drift under the whole 12 s title card and a light sweep across the logo: motion with no cause.
- Used the same decelerate curve on nearly every arrival, and exits that were as long as the entrances.
- Did not question a 12 s intro for a 9-word headline, and computed no hold from the word count.
- Proposed a camera push and parallax on every scene, and whooshes on every key move, in answer to "feels like slides".
- Gave no accessibility check (flashing, reduced motion, captions), no safe-area rule beyond a margin guess, and no review step.
- Gave durations in frames tied to 30 fps without a conversion rule.

What it got right, so the skill does not repeat it: carry an object across scene boundaries, stagger in reading order, vary scene length, cut text. Those are in the skill as short lines, not sections.

Invocation mode: auto (`user-invocable: false`, model invocation on). People type "animate", "title card", "feels like slides", and the model undertriggers background skills it thinks it can do alone (see `evals/README.md`), so the description leads with those phrases. It is not a run-by-name skill because a person would not choose to run a craft reference by hand.

## Not confirmed

| Item | Reason | What was done |
|---|---|---|
| BBC subtitle guideline of 160 to 180 words per minute and 0.3 s per word minimum | The BBC page could not be fetched. Only third-party summaries, which disagree on gaps and line length | Not used as a source. Cited norms are Netflix's, which were read |
| Vertical safe zone margins (a third-party figure of 14% top, 35% bottom, 6% sides attributed to a Meta ads guide) | No first-party page found. Sources disagree (20% versus 35% for bottom) | Cut the numbers. The skill says to read the platform's current spec |
| YouTube loudness target | No official YouTube page states a target. -14 LUFS rests on secondary sources | Not in the skill. Spotify's -14 LUFS (confirmed) is noted under Left out |
| Average shot length figures (about 2.5 s today, 12 s in 1930) | A spoken figure reported by a data site, not in the paper | Cut. Only the direction of the trend is cited |
| Stagger milliseconds and title sizes | Single or secondary sources only (rows 21, 22) | Kept, marked `heur` in the skill text |
| Material 2 and 3 motion tokens | Pages are script rendered and could not be read | Used Material 1, which was read |
| Brysbaert paper first-hand | Only the BPS digest and search summaries were read | 238 words per minute kept as likely. Participant count dropped |

## Left out

| Item | Why |
|---|---|
| Loudness: EBU R128 target -23.0 LUFS, tolerance 1.0 LU for live, true peak -1 dBTP (read from the 2023 PDF text, where the minus signs were stripped by extraction, so the signs rest on the known standard). Spotify -14 LUFS with true peak -1 dB TP, or -2 dB TP for louder masters (confirmed) | Audio mastering belongs to the `video-production` playbook, not to motion craft |
| Remotion licence terms and engine rules | Engine choice, belongs to the playbook. Remotion skills are recommended as installs |
| Easing curve numbers (cubic-bezier values) | Engine and design-system specific. Shapes are named instead |
| Motion blur amounts, spring damping tables | Single-vendor numbers or engine specific |
| Twelve principles in full | The model knows them. Only the ones that change timing decisions are named |

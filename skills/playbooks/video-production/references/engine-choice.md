# Engine choice

## Contents

- [Choose by job](#choose-by-job)
- [Matrix](#matrix)
- [Licence terms to re-check](#licence-terms-to-re-check)
- [How each engine treats time](#how-each-engine-treats-time)
- [Install and official skills](#install-and-official-skills)
- [Mixed pipelines](#mixed-pipelines)
- [Generative video](#generative-video)

## Choose by job

| The job | First choice | Why | Do not pick it when |
|---|---|---|---|
| Cut, join, speed up, add sound or captions to existing footage | ffmpeg | Exact, scriptable, no project to maintain | The film needs animated text, data or layout beyond simple overlays |
| Product teaser, launch film, explainer with text, UI screens, data and brand motion | Remotion or HyperFrames | Layout and timing are code, so a wording change is an edit and a re-render | The team cannot accept the licence, or Node is not available |
| Maths, equations, algorithm walk-throughs, diagram proofs | Manim | Built for exact geometric animation from a script | The film is brand or UI motion, or mixes photos and footage |
| Code-like precise explainer animation in TypeScript with an editor | Motion Canvas | Generator-based animation with a visual editor | You need unattended batch rendering (see the note below) |
| Small looping animation for an app or page | Lottie or Rive | Compact vector animation that plays in a runtime | You need a whole film, narration or a timeline of scenes |
| Realistic scenes nobody can film or draw | Generative video | The only route to that footage | You need exact text, logos, product UI or repeatable output |

An engine already used in the project beats every row. A second engine means a second toolchain, a second licence and a second set of pitfalls.

## Matrix

The columns are the facts that change a decision. The licence column is a summary, not legal advice: open the linked file before a commercial decision.

| Engine | Model of time | Licence | Strengths | Do not use when |
|---|---|---|---|---|
| Remotion | React components driven by the current frame number. Every frame is a function of that number | Source-available company licence with free tiers. See [Licence terms](#licence-terms-to-re-check) | Studio preview, React ecosystem, official agent skills, captions and cloud rendering packages | Company use above the free tiers is not budgeted, or the project is not Node |
| HyperFrames | HTML with a paused, seekable timeline. The renderer seeks frame by frame, so the render repeats exactly | Apache-2.0 for the project. Some third-party parts keep their own terms, for example GSAP | Plain HTML and CSS that any agent writes well, CLI with `check` and `snapshot`, registry of ready blocks | You want the React component ecosystem. Some media features can call HeyGen services, so check cost before using them |
| Motion Canvas | TypeScript generator functions, played in a browser editor | MIT | Precise explainer animation, editor with timeline | Unattended or CI renders: its rendering page describes the editor Render button and an image sequence, with no command-line renderer |
| Manim | Python scenes rendered frame by frame | MIT, for both Manim Community and the original 3Blue1Brown project | Equations, graphs, geometry, step-by-step maths | UI or brand motion, photo and footage compositing. Manim Community and the original project are separate repositories, so check which one is installed before writing code |
| Lottie, Rive | A JSON or binary animation file played by a runtime | Lottie players and Rive runtimes are MIT. Rive's editor is a hosted product with plans | Small vector animation that ships in apps and sites | Whole films. To get video, play the animation inside a frame-driven engine, or export from the editor if the plan allows |
| ffmpeg | Streams and filters over existing media. No scene model | LGPL 2.1 or later for the core. GPL if built with GPL parts such as libx264. See the legal page | Cuts, concatenation, scaling, audio, loudness, still frames, contact sheets | Anything with animated layout |
| Generative video | A model samples new footage from a prompt | Per provider and plan. Read the provider's terms | Footage that does not exist | Exact product UI, text, logos, repeatable renders |

## Licence terms to re-check

Open the file before the user commits. Tell the user what you read, and link it in the delivery note.

| Engine | What the source says | Where |
|---|---|---|
| Remotion | Free for an individual, a for-profit organisation with up to 3 employees, a non-profit, or evaluation without commercial use. A company licence is required for larger for-profit organisations. The file warns that the licence changes in Remotion 5.0 | https://github.com/remotion-dev/remotion/blob/main/LICENSE.md |
| HyperFrames | Apache-2.0. The credits file lists GSAP under the GSAP Standard License and says it is not an OSI open-source licence. GSAP is vendored or loaded by some registry blocks | https://github.com/heygen-com/hyperframes/blob/main/LICENSE and https://github.com/heygen-com/hyperframes/blob/main/CREDITS.md |
| ffmpeg | LGPL 2.1 or later. Parts under the GPL apply to all of ffmpeg when used. The legal page lists libx264 as a GPL library and advises building without `--enable-gpl` and `--enable-nonfree` for LGPL compliance. On patents it says it cannot say, and that commercial products may face fees | https://ffmpeg.org/legal.html |
| Rive | The pricing page lists a free plan whose exports carry a Rive splash screen, and describes the runtimes as MIT | https://rive.app/pricing |
| Motion Canvas, Manim, Lottie players | MIT, per each repository's licence file | https://github.com/motion-canvas/motion-canvas, https://github.com/ManimCommunity/manim, https://github.com/3b1b/manim, https://github.com/airbnb/lottie-web |

Fonts, music, voices, stock footage and generated media each carry their own terms. Record the source and licence of every asset in the delivery note.

## How each engine treats time

A repeatable render needs a clock the engine controls.

| Class | Engines | Rule for the agent |
|---|---|---|
| Frame-driven or seekable | Remotion, HyperFrames, Manim, Motion Canvas | Compute everything from the frame or timeline time. No wall clock, no timers, no unseeded randomness, no fetches during render |
| Recorded | Screen capture, camera footage | Cannot be re-rendered with new copy. Plan retakes, and cut with ffmpeg |
| Sampled | Generative video | Two runs differ. Keep the chosen clip file, not just the prompt |

Remotion's own skill states that CSS `transition` and `animation` and Tailwind animation classes do not render correctly there and must be rewritten as functions of the current frame (https://github.com/remotion-dev/skills/blob/main/skills/remotion-markup/SKILL.md). The same applies to any frame-driven engine.

## Install and official skills

Never install without asking. Detect first, then recommend.

| Need | Command | Source |
|---|---|---|
| Remotion agent skills | `npx skills add remotion-dev/skills` | https://github.com/remotion-dev/skills |
| HyperFrames agent skills | `npx skills add heygen-com/hyperframes`, or `npx hyperframes skills update` for the core set | https://github.com/heygen-com/hyperframes |
| HyperFrames as a Claude Code plugin | `claude plugin marketplace add heygen-com/hyperframes` then `claude plugin install hyperframes@hyperframes` | https://github.com/heygen-com/hyperframes |
| ElevenLabs audio skills (speech, music, sound effects, transcription) | `npx skills add elevenlabs/skills`, with an API key in `ELEVENLABS_API_KEY` | https://github.com/elevenlabs/skills |
| Remotion project scaffold | `npx create-video@latest` | https://github.com/remotion-dev/skills/blob/main/skills/remotion-create/SKILL.md |
| HyperFrames project scaffold | `npx hyperframes init <dir>`. Needs Node 22 or later and FFmpeg on the path | https://github.com/heygen-com/hyperframes |

The vendors' skills know their own API better than this playbook can. Use them for engine code, and use this playbook for the workflow around them. Their licences differ: the ElevenLabs skills are MIT, and the Remotion skills repository states no licence in its metadata, so read it before copying anything from it.

## Mixed pipelines

- Manim or Motion Canvas clips as scenes, joined and scored with ffmpeg.
- A Lottie animation played inside Remotion through its `@remotion/lottie` package (https://www.remotion.dev/docs/lottie/lottie).
- HyperFrames publishes a skill for moving existing Remotion code into HyperFrames, which is the route when a licence change forces a switch.

Keep one fps and one canvas size across all parts, or the join will need a rescale and a retime.

## Generative video

- Treat the output as unpredictable. Keep the delivered clip file and record provider, model name as shown in the console, prompt and date.
- Use it for B-roll and atmosphere. Never for text, logos, product screens or anything the viewer must read.
- Ask before spending money on generation, and state the cost per clip first.
- Model lineups change fast. Google's Gemini API video page, for example, announces the shutdown of a Veo preview model and points to a replacement, so a pipeline pinned to a model name breaks (https://ai.google.dev/gemini-api/docs/video).
- Commercial rights, watermarks and permitted subjects differ per provider and per plan. Read the provider's current terms and link them in the delivery note.

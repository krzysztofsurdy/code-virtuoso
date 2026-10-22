# Research notes: video-production playbook

Date: 2026-10-22
Depth: deep (run inline; see Method)
Research skill used: no (procedure of `skills/tools/research` followed inline: local first, primary sources, two sources or one primary for key claims)
Prior-art search: done

## Method and process notes

- Three background research agents (engines, standards, prior art) were spawned but never returned a report in this run. All research below was redone inline by the main agent with WebFetch, WebSearch, `gh api`, `npx skills find` and local ffmpeg runs. Nothing from those agents is used.
Confirmation gates: approved by the maintainer in the build brief.
- Phase 1 baseline run (agent without the skill on realistic prompts) was skipped at the maintainer's request. The skill's reason to exist rests on the prior-art gaps below and on documented failure modes in the official skills, not on a measured baseline.
- Not done: the with-and-without eval run and description tuning through Anthropic's skill-creator, and a real trigger run (`evals/run.sh triggers`). Only `evals/run.sh check` was run.
- Fetched text was treated as data. No install, plugin or script from a fetched page was run. `npx skills find` only searches.

## Scope

An engine-agnostic playbook for making a video from a brief: brief, engine choice, storyboard stills, numeric spec, build, frame-snapshot review loop, audio, render, delivery. Craft numbers (timing, easing, type, safe areas, flashing, caption layout) are left to the sibling `motion-design` skill. Out of scope: video editing of real footage beyond ffmpeg basics, avatar and dubbing products, platform strategy.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://github.com/remotion-dev/remotion/blob/main/LICENSE.md | official | Remotion | file copyright 2026 | 2026-10-22 |
| https://www.remotion.dev/docs/cli/render | official | Remotion | unknown | 2026-10-22 |
| https://www.remotion.dev/docs/cli/still | official | Remotion | unknown | 2026-10-22 |
| https://www.remotion.dev/docs/lottie/lottie | official | Remotion | unknown | 2026-10-22 |
| https://github.com/remotion-dev/skills (README, skills/remotion-markup, remotion-render, remotion-studio, remotion-create) | official | Remotion | skills version 4.0.537, pushed 2026-10-19 | 2026-10-22 |
| https://github.com/heygen-com/hyperframes (README.md, CREDITS.md, skills/hyperframes/SKILL.md) | official | HeyGen | pushed 2026-10-22 | 2026-10-22 |
| https://github.com/elevenlabs/skills (README.md) | official | ElevenLabs | pushed 2026-10-19 | 2026-10-22 |
| https://motioncanvas.io/docs/rendering and /docs/quickstart | official | Motion Canvas | unknown | 2026-10-22 |
| https://docs.manim.community/en/stable/tutorials/quickstart.html | official | Manim Community | unknown | 2026-10-22 |
| https://rive.app/pricing | vendor | Rive | unknown | 2026-10-22 |
| GitHub repo metadata via `gh api` for 10 repos (licence, stars, last push) | vendor | GitHub | n/a | 2026-10-22 |
| https://ffmpeg.org/legal.html | official | FFmpeg | unknown | 2026-10-22 |
| https://ffmpeg.org/ffmpeg-filters.html (loudnorm) and local `ffmpeg -h filter=loudnorm` | official | FFmpeg | 9.0.2 locally | 2026-10-22 |
| https://ffmpeg.org/ffmpeg-formats.html (faststart) | official | FFmpeg | unknown | 2026-10-22 |
| https://tech.ebu.ch/docs/r/r128.pdf (v5, November 2023), r128s1.pdf (v3, 2020), r128s2.pdf (2023) | standard | EBU | see rows | 2026-10-22 |
| https://tech.ebu.ch/docs/r/r095.pdf (v1.1, June 2017) | standard | EBU | 2017-06 | 2026-10-22 |
| https://support.spotify.com/us/artists/article/loudness-normalization/ | official | Spotify | unknown | 2026-10-22 |
| https://support.google.com/youtube/answer/1722171 | official | YouTube | unknown | 2026-10-22 |
| https://www.w3.org/TR/WCAG22/ | standard | W3C | 2024-12-12 | 2026-10-22 |
| https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977 and /215758617 | vendor | Netflix | unknown | 2026-10-22 |
| https://ai.google.dev/gemini-api/docs/video | official | Google | unknown | 2026-10-22 |
| https://skills.sh/101-skills/superpowers/storyboard-creation | community | skills.sh | unknown | 2026-10-22 |
| Local: skills/knowledge/motion-design, skills/tools/web-screenshot, image-annotate, research, skill-writer | local | this repo | n/a | 2026-10-22 |

## Prior art

Queries run: `npx skills find "video production"`; `gh api repos/<owner>/<repo> --jq '[.stargazers_count,.pushed_at,.license.spdx_id]'` for each candidate; `gh api repos/.../contents/...` to read each SKILL.md; read of the repo's own `skills/` tree and installed skills. A `gh search repos` query was not run.

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| heygen-com/hyperframes@hyperframes | https://github.com/heygen-com/hyperframes/blob/main/skills/hyperframes/SKILL.md | official (HyperFrames, HeyGen) | 69.6k stars, pushed 2026-10-22 | Make, edit, render video in HyperFrames: contract, work loop, per-type references | Spec step where every adjective becomes a number and defaults are banned by name; story options approved before the file; automated `check`; snapshot-based review that ends in a written review file; render only after approval; safe-box rule | Welded to its CLI, registry, GSAP and HeyGen media services; its guidance does not help on any other engine; its safe boxes (90% and 80%) differ from EBU R 95 (93% and 90%) | Apache-2.0 (project); GSAP and some blocks carry their own terms |
| remotion-dev/skills (remotion-create, remotion-studio, remotion-markup, remotion-render) | https://github.com/remotion-dev/skills | official (Remotion) | 5.5k stars, pushed 2026-10-19 | Create, preview, write markup for and render Remotion videos; many sub-skills | Open the Studio preview early and keep it open; drive animation from the frame, not CSS; render several frames with `render --frames`; keep timing in fps-aware expressions; keep user edits | Remotion only; no storyboard step, no audio loudness or delivery checks; the repository has no licence file, so ideas only | none stated |
| coreyhaines31/marketingskills@video | https://github.com/coreyhaines31/marketingskills/blob/main/skills/video/SKILL.md | community | 55.9k stars, pushed 2026-10-19; 83.9k installs on skills.sh | Marketing video overview: programmatic, generative, avatar and editing tools, workflows | Broad tool map, clear "when to pick which" tables, product demo and explainer workflows | Per-model price and duration tables go stale; no storyboard approval, no frame review loop, no audio or loudness step, no licence checks beyond a one-line note | MIT |
| lottiefiles/motion-design-skill@motion-design | https://github.com/lottiefiles/motion-design-skill/blob/main/skills/motion-design/SKILL.md | community (LottieFiles) | 2.4k stars, last commit 2026-05-18 | Tool-agnostic UI motion principles: personality, duration and easing tables, choreography, checklist | Tool-agnostic craft, quick checklist, troubleshooting table | UI micro-interactions only: no video, audio, render or delivery. (Craft is covered here by `motion-design`.) | MIT |
| affaan-m/ecc@video-editing | https://github.com/affaan-m/ecc/blob/main/skills/video-editing/SKILL.md | community | 286k stars, last change to the skill 2026-09-10 | AI-assisted editing of real footage with ffmpeg, Remotion and other tools | Layered pipeline, deterministic cuts with ffmpeg | Editing of real footage, tied to that author's tool stack, no review loop or loudness | MIT |
| elevenlabs/skills (text-to-speech, music, sound-effects, speech-to-text) | https://github.com/elevenlabs/skills | official (ElevenLabs) | 501 stars, pushed 2026-10-19 | API skills for speech, music, effects, transcription | Official, MIT, covers the whole audio asset side | Vendor-bound and paid, no video workflow | MIT |
| 101-skills/superpowers@storyboard-creation (fork of inference-sh/skills) | https://skills.sh/101-skills/superpowers/storyboard-creation | community | 53.1k installs on skills.sh, 8 stars on source repo | One storyboard panel through an external image CLI | n/a | One example, needs an external CLI and login, no sequence or approval guidance | none shown |

Decision: write a new skill. No official or better skill covers the engine-agnostic workflow (engine choice, storyboard approval, spec, frame review, audio targets, delivery). The official engine skills (Remotion, HyperFrames) and the ElevenLabs skills are recommended for install, not rebuilt. `motion-design` (this repo) holds craft rules.

Strengths adopted as ideas, credited: numeric spec and banned defaults, approve concept before build, review frames with severity and a written review file (HyperFrames); open the preview early, frame-driven timing, `render --frames` for several stills (Remotion); a "when to pick which" decision table (marketingskills). Weaknesses avoided: engine lock-in, per-model price tables, copied numbers from a single vendor, no audio step. No text was copied. HyperFrames' safe-box and timing numbers were not used.

Gap this skill fills: an engine-agnostic workflow with gates, a verified engine matrix with licence pointers, a measured audio and delivery step, and explicit unverified-item reporting.

## Fact ledger

Confidence: confirmed = primary source plus reproduction or a second source. likely = one primary source. All rows retrieved 2026-10-22.

| # | Claim | Source URL | Version | Confidence | Verified by |
|---|---|---|---|---|---|
| 1 | Remotion is free for an individual, a for-profit organisation with up to 3 employees, a non-profit, or evaluation without commercial use; larger for-profit organisations need a company licence | https://github.com/remotion-dev/remotion/blob/main/LICENSE.md | file in main | likely | read file via WebFetch. Note: the fetch said the file does not state the threshold directly for larger firms, only implies it |
| 2 | LICENSE.md says the licence changes slightly in Remotion 5.0 | same | same | likely | read file |
| 3 | `npx skills add remotion-dev/skills` installs the Remotion agent skills | https://github.com/remotion-dev/skills README | main | confirmed | read README via gh api, same install form in elevenlabs and hyperframes READMEs |
| 4 | Remotion skills repo has no LICENSE file | `gh api repos/remotion-dev/skills/contents` listing (README.md, package.json, scripts, skills, tsconfig.json) and `.license.spdx_id` empty | main | confirmed | gh api |
| 5 | `npx remotion render <entry-point|serve-url>? <composition-id> <output-location>`; `--frames=0,30,60` renders listed frames as an image sequence | https://www.remotion.dev/docs/cli/render | docs | confirmed | read page, matches remotion-render skill |
| 6 | `npx remotion still <serve-url|entry-point>? [<composition-id>] [<output-location>]`; the `--frame` flag is listed, its options are not described; docs recommend `render --frames` for several frames | https://www.remotion.dev/docs/cli/still | docs | confirmed | read page. The `--frame=<n>` form in review-loop.md is the flag listed on that page, not exercised here |
| 7 | CSS `transition`, `animation` and Tailwind animation classes do not render correctly in Remotion; drive with `useCurrentFrame()` and `interpolate()` | https://github.com/remotion-dev/skills/blob/main/skills/remotion-markup/SKILL.md | 4.0.537 | confirmed | read skill |
| 8 | Remotion skills: start Studio and open the preview early, `npx remotion studio`; scaffold `npx create-video@latest` | remotion-studio and remotion-create SKILL.md | 4.0.537 | confirmed | read skills |
| 9 | `<Lottie>` from `@remotion/lottie` plays Lottie JSON through `animationData` | https://www.remotion.dev/docs/lottie/lottie | docs | confirmed | read page |
| 10 | HyperFrames is Apache-2.0, needs Node.js 22+ and FFmpeg, commands `npx hyperframes init|preview|render`, `check --json`, `snapshot --review` | https://github.com/heygen-com/hyperframes README and skills/hyperframes/SKILL.md; `gh api` licence field | main | confirmed | read README and skill, licence via API |
| 11 | HyperFrames renders HTML by seeking a paused timeline frame by frame so every render is identical | hyperframes SKILL.md | main | likely | vendor statement, not independently tested here |
| 12 | HyperFrames install: `npx skills add heygen-com/hyperframes`, `npx hyperframes skills update` (core set), Claude Code `claude plugin marketplace add heygen-com/hyperframes` then `claude plugin install hyperframes@hyperframes` | README | main | confirmed | read README. Commands not executed |
| 13 | CREDITS.md lists GSAP 3.14.2 under the GSAP Standard License, "not an OSI open-source licence", vendored or loaded by some registry blocks | https://github.com/heygen-com/hyperframes/blob/main/CREDITS.md | main | confirmed | read file |
| 14 | `/media-use` obtains media with HeyGen or free local tools | README skills table | main | likely | read README |
| 15 | ElevenLabs skills (MIT): text-to-speech, speech-to-text, sound-effects, music and others; install `npx skills add elevenlabs/skills`; API key in `ELEVENLABS_API_KEY` | https://github.com/elevenlabs/skills | main | confirmed | README, licence via API |
| 16 | Motion Canvas: MIT, TypeScript scenes declared with generator functions, editor served locally; rendering page describes the editor Render button writing an image sequence (PNG, JPEG, WebP), suggests converting frames with ffmpeg, no headless or CLI renderer described | https://motioncanvas.io/docs/rendering and /docs/quickstart; `gh api` licence | docs | likely | read two pages. The absence of a headless option is "not described on that page", not proof none exists |
| 17 | Motion Canvas repo last push 2026-07-02 | `gh api` | n/a | confirmed | gh api |
| 18 | Manim Community and 3b1b/manim are both MIT; render with `manim -pql <file>.py <Scene>` | https://docs.manim.community/en/stable/tutorials/quickstart.html; `gh api` licence | stable docs | confirmed | read page, API |
| 19 | The two Manim projects have different APIs | not read from a source | n/a | unverified | cut from certainty: SKILL text says "check which one is installed" |
| 20 | Rive: Free, Cadet, Voyager, Enterprise plans; free exports include a Rive splash; MP4 and GIF appear under Export in the comparison (plan not readable); runtimes MIT | https://rive.app/pricing | page | likely | read page. Plan for MP4 export not confirmed |
| 21 | lottie-web (airbnb) MIT, last push 2025-09-01; dotlottie-web MIT; rive-wasm MIT | `gh api` | n/a | confirmed | gh api |
| 22 | ffmpeg is LGPL 2.1 or later; GPL parts apply to all of ffmpeg when used; libx264 named as GPL; compile without `--enable-gpl` and `--enable-nonfree` for LGPL compliance; on patents the page says it is not qualified to answer and warns of fees for commercial products | https://ffmpeg.org/legal.html | page | confirmed | read page |
| 23 | loudnorm: defaults I=-24, LRA=7, TP=-2; linear needs all measured_* and falls back to dynamic if conditions fail; dynamic mode upsamples to 192 kHz so set `-ar`; `print_format=json`; `dual_mono` for mono on stereo | https://ffmpeg.org/ffmpeg-filters.html#loudnorm and `ffmpeg -h filter=loudnorm` | ffmpeg 9.0.2 | confirmed | read docs, ran help |
| 24 | Two-pass loudnorm, linear, I=-16 on a 20 s test signal measured -16.0 LUFS and -3.4 dBTP afterwards; on a muxed film with I=-14 TP=-1 it measured -14.1 LUFS and -1.2 dBTP after AAC encode | local runs (scripts in a local sandbox (not committed)) | ffmpeg 9.0.2 | confirmed | reproduced |
| 25 | `ebur128=peak=true` prints Summary with `I:`, `LRA:` and `Peak:` | local run | ffmpeg 9.0.2 | confirmed | reproduced |
| 26 | `+faststart` moves MP4 metadata from the end to the start for better playback | https://ffmpeg.org/ffmpeg-formats.html | docs | confirmed | read docs; local file had moov before mdat |
| 27 | libx264 default preset is medium; `-crf` default -1 (encoder default) | `ffmpeg -h encoder=libx264` | 9.0.2 | confirmed | ran help. No CRF number is stated in the skill |
| 28 | Frame at time: `ffmpeg -ss <t> -i in.mp4 -frames:v 1 out.png`; contact sheet `fps=1,scale=360:-1,tile=6x2 -frames:v 1`; frame range `select='between(n,44,46)'` needs `-fps_mode vfr` (`-vsync` is rejected on 9.0.2); scene list `select='gt(scene,0.4)',showinfo` printed `pts_time:2` for a cut at 2 s | local runs | ffmpeg 9.0.2 | confirmed | reproduced |
| 29 | `ffprobe -show_entries stream=...,nb_frames,duration` returns width, height, pix_fmt, fps, nb_frames, durations, sample rate | local run | 9.0.2 | confirmed | reproduced |
| 30 | `mov_text` soft subtitle mux into MP4 works; the `subtitles` burn filter failed on this build, which lacks libass | local runs, `ffmpeg -version` | 9.0.2 | confirmed | reproduced |
| 31 | EBU R 128 v5 (November 2023): programme loudness target -23.0 LUFS; true peak not above -1 dBTP (measurement tolerance 0.3 dB); QC tolerance 0.2 LU; live tolerance 1.0 LU; loudness range not recommended for programmes under 1 minute; short-form in R 128 s1, streaming in R 128 s2 | https://tech.ebu.ch/docs/r/r128.pdf | v5 | confirmed | extracted text of the PDF. Minus signs were dropped by the extraction, signs confirmed from the sibling documents and common knowledge (-23 LUFS) |
| 32 | EBU R 128 s1 (v3, 2020): short-form programme loudness -23.0 LUFS, max short-term loudness 5 LU above target (+5.0 LU relative scale), no LRA limit, true peak not above -1 dBTP | https://tech.ebu.ch/docs/r/r128s1.pdf | v3 | confirmed | extracted text. The absolute -18 LUFS is inferred (-23 + 5) and not written in the skill |
| 33 | EBU R 128 s2 (2023): streaming services typically use a higher target than broadcast standards; EBU recommends streaming programmes unchanged | https://tech.ebu.ch/docs/r/r128s2.pdf | 2023 | likely | extracted text, numbers lost by extraction so none stated in skill |
| 34 | Spotify normalises to -14 dB LUFS; masters should stay below -1 dB TP, and below -2 dB TP if louder than -14 LUFS; it both lowers loud and raises quiet tracks | https://support.spotify.com/us/artists/article/loudness-normalization/ | page | confirmed | read page |
| 35 | YouTube upload help recommends MP4, H.264, AAC-LC or Opus or Eclipsa Audio, 4:2:0, 48 kHz, moov atom at front, upload at the recorded frame rate, 16:9 standard on computers, vertical and square accepted | https://support.google.com/youtube/answer/1722171 | page | confirmed | read page |
| 36 | EBU R 95 v1.1 (June 2017): action safe area 3.5% and graphics safe area 5% at top, bottom and sides | https://tech.ebu.ch/docs/r/r095.pdf | 1.1 | confirmed | extracted text. Not written in this skill (lives in motion-design), cross-checked consistent with it |
| 37 | WCAG 2.2 (W3C Recommendation 2024-12-12): 1.2.2 Captions (Prerecorded) Level A; 1.2.5 Audio Description (Prerecorded) Level AA; 2.3.1 Three Flashes or Below Threshold Level A; 2.2.2 Pause, Stop, Hide Level A | https://www.w3.org/TR/WCAG22/ | 2.2 | confirmed | read page |
| 38 | Netflix English (USA) style guide: 42 characters per line, up to 20 characters per second for adult programmes; general requirements: 2 lines maximum, minimum 5/6 second and maximum 7 seconds per subtitle event | https://partnerhelp.netflixstudios.com/hc/en-us/articles/217350977 and /215758617 | pages | confirmed | read both pages. Applies to Netflix deliverables, used only as one reference |
| 39 | A Google Gemini API video page announces the shutdown of a Veo 3.1 preview model with a migration to another model | https://ai.google.dev/gemini-api/docs/video | page | confirmed | read page. Model names and date intentionally not written in the skill |

## Not confirmed

| Item | What was done |
|---|---|
| Official YouTube, Instagram, TikTok, LinkedIn loudness targets | No official number found. Search returned only third-party pages. Skill says "read the platform's page" and marks the common -14 LUFS creator convention unverified |
| Vertical (9:16) platform safe-zone pixel values | Third-party tools disagree (for example 160 to 240 px top, 480 to 660 px bottom). TikTok distributes overlay templates instead. Skill gives no numbers and points to the platform templates through the generic "read the platform page" |
| EBU R 128 absolute tolerance wording for non-live (+/- 0.5 LU) | Version history of R 128 mentions the change; the body text shows 1.0 LU for live and 0.2 LU QC. Skill states only the -23 LUFS target and -1 dBTP |
| Rive plan that includes MP4 export | Page text did not carry the plan marks. Skill says exports exist in the comparison and to check the plan |
| Whether Motion Canvas has a headless renderer | Not described on the pages read. Skill says "its rendering page describes the editor Render button and an image sequence, with no command-line renderer" |
| Generative video: determinism, clip length limits, commercial terms per provider | Not verified. Skill states only that output varies (design inference, stated as a rule of thumb), points to provider terms, and cites the model-churn evidence |
| Remotion `--frame` flag semantics on `still` | Page lists the flag without describing it |
| HyperFrames determinism claim and registry size | Vendor statement only. Not tested |
| Whether HyperFrames and Remotion commands run as written | Not executed (no install, per the rule against installing without asking) |
| Two Manim projects have incompatible APIs | Not sourced. Phrased in the skill as "check which one is installed" |
| Description trigger accuracy | No eval run executed beyond `evals/run.sh check` (loading) |

## Left out

- Per-model generative video price and length tables (stale within months, a weakness of the marketingskills video skill).
- Easing, duration, type size and stagger numbers: belong to `motion-design`.
- Avatar and dubbing products (HeyGen, Synthesia, ElevenLabs dubbing): out of scope.
- Platform loudness numbers from blogs.
- SMPTE safe-area documents (not freely available).

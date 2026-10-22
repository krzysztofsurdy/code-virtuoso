# Research notes: game-feature-loop

Date: 2026-10-22
Depth: standard
Research skill used: no (inline)
Prior-art search: done
Confirmation gates: approved by the maintainer in the build brief.

## Scope

An engine-agnostic playbook: detect the engine, plan one mechanic, build small, run, prove behavior from live state before and after a simulated input, commit, then a separate game-feel pass. Out of scope: engine API detail (pointers only), GDD writing, genre design, asset production, publishing.

Baseline (phase 1): not run with a live model, no user available. The reason to exist comes from the user's own rules ("green tests with an unplayable game is the classic failure", "do not trust the screenshot alone") and the gaps in the prior-art table. Report this as untested against a baseline.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| ~/.claude/CLAUDE.md, section "When game developing" | local | user | n/a | 2026-10-22 |
| The maintainer's personal Godot skill (game-feel notes) | local | user | n/a | 2026-10-22 |
| ~/.claude/plugins/cache/awesome-gamedev-agent-skills/gamedev/0a70cfc64672/ (router, prototype-fast, game-feel, NOTICE, LICENSE) | community | gamedev-skills | 2026 | 2026-10-22 |
| https://github.com/obra/superpowers (verification-before-completion, test-driven-development SKILL.md) | community | obra | live | 2026-10-22 |
| skills/knowledge/verification-before-completion, skills/playbooks/tdd (this repo) | local | this repo | live | 2026-10-22 |
| https://github.com/Unity-Technologies/skills (README, LICENSE.md, skills list) | official | Unity | live | 2026-10-22 |
| https://github.com/Unity-Technologies/unity-agent-plugin (plugin.json, marketplace.json) | official | Unity | live | 2026-10-22 |
| https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin (README, skills/unreal-mcp/SKILL.md) | official | Epic Games | pushed 2026-09-17 | 2026-10-22 |
| GDC 2016 Eiserloh slides PDF (downloaded, text extracted from the PDF streams) | primary | Eiserloh | 2016 | 2026-10-22 |
| https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ | practitioner (translation of Sakurai column) | Source Gaming | 2015 | 2026-10-22 |
| https://shane-sicienski.com/blog/blog-post-title-one-55pmn | practitioner | Shane Sicienski | unknown | 2026-10-22 |
| https://sonichurricane.com/?p=1043 | practitioner | Sonic Hurricane | unknown | 2026-10-22 |
| https://gamineai.com/blog/pixel-art-combat-fx-hitstop-smear-frames-impact-timing-2026 | practitioner | GamineAI | 2026 | 2026-10-22 |
| https://docs.unity3d.com/ScriptReference/Time-timeScale.html | official | Unity | live | 2026-10-22 |
| https://docs.godotengine.org/en/stable/classes/class_engine.html | official | Godot | live | 2026-10-22 |
| https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html | official | Godot | live | 2026-10-22 |
| Epic API reference for FProjectDescriptor::EngineAssociation (via search summary, not opened) | official | Epic | n/a | 2026-10-22 |
| Unity ProjectVersion.txt: raw file from Unity-Technologies/com.unity.multiplayer.samples.bitesize via gh api | official sample | Unity | live | 2026-10-22 |
| npm registry (npm view phaser, pixi.js, three) and crates.io (bevy) | official | registries | live | 2026-10-22 |

## Prior art

Queries: `npx skills find "game feel"`, `npx skills find "gamedev"`, `gh api repos/<owner>/<repo>` for stars, push date, license, plus reading the SKILL.md files listed. Local repo: no game skill exists (`skills/frameworks/godot` is being written by another agent).

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| gamedev-skills/awesome-gamedev-agent-skills@router | https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/router/SKILL.md | community | 2751 stars, 5.4K installs, pushed 2026-10-22 | Engine fingerprint table, task classification, dispatch to 74 skills | Exclusive engine detection, version sources per engine, ambiguity rules, "ask when unknown" | Dispatches only. No build-run-prove order, no stop gates. Its detection table is wider than what a procedure needs | Apache-2.0 |
| ...@prototype-fast | https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/workflows/prototype-fast/SKILL.md | community | same repo | Timeboxed throwaway prototype, keep or kill criteria | One question per prototype, observable keep or kill signals, "rewrite, do not promote the spike" | Aimed at a judgement of fun, not at proving a mechanic works. No live-state check | Apache-2.0 |
| ...@game-feel | https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/main/skills/disciplines/game-feel/SKILL.md | community | same repo | Juice techniques, engine code samples | Importance tiers, feedback bundles, real-time wait pitfall for hit-stop, accessibility option | Does not say when in the workflow to run (after the mechanic is proven). Code samples are engine-specific. Numbers stated without sources | Apache-2.0 |
| obra/superpowers@verification-before-completion | https://github.com/obra/superpowers/blob/main/skills/verification-before-completion/SKILL.md | community | 303K stars, pushed 2026-10-21 | Evidence before completion claims | Gate function, table of claim versus required evidence | Generic. Nothing about running a game, simulated input, or live state. Textbook length | MIT |
| Unity-Technologies/skills | https://github.com/Unity-Technologies/skills | official | 1128 stars, pushed 2026-10-21 | 30+ Unity task skills (physics, UI, build, CLI) | Official, drives the editor via Unity CLI | Unity only, task-specific, no feature loop. License NOASSERTION (Unity Companion License text) | Unity Companion License |
| EpicGames/unreal-engine-skills-for-claude-code-plugin | https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin | official | 1567 stars, pushed 2026-09-17 | Drive a live Unreal Editor over MCP | Safety rules (save first, wait for compile, check results), live-editor read and write | Unreal only. Needs a running editor and extra plugins | MIT |
| Local: skills/knowledge/verification-before-completion, skills/playbooks/tdd | this repo | this repo | live | Generic completion evidence, test-first loop | Linked from the new skill instead of repeated | No game specifics, so they do not cover the live-state proof | repo |

Also seen in `npx skills find` and not read: jarrodmedrano/jarrod-claude-skills@game-feel (51 installs), abagames/agentic-gamedev-skills@maximizing-game-feel (37), lvtd-llc/skills@game-smooth-curves-and-motion (58), saschb2b/skills@game-design (69). Low adoption, not evaluated.

Decision: write a new skill. Not install-and-stop, because no official or community skill joins the loop (detect, plan one mechanic, build, run, prove with live state, commit, separate feel pass) with stop gates. The engine skills are complementary and are linked.

Adopted as ideas (no text copied): router's exclusive detection and version-source rule and the "ask when unknown" fallback; prototype-fast's one-question framing and rewrite-not-promote; game-feel's importance tiers and real-time wait pitfall; superpowers' evidence-before-claims principle (we link our own `verification-before-completion`). Avoided: dispatch-only scope, engine-specific code, unsourced numbers, textbook length, and a long engine table.

Gap filled: a single ordered procedure with a measurable proof step (read state before and after a simulated player input), a rule that a screenshot alone or green tests alone is not done, a two-failure stop, and a separate feel pass.

Licenses: Apache-2.0 (gamedev-skills) allows reuse with notice, MIT (superpowers, Epic) likewise. Nothing was copied, so no notice is needed. Credit lives here.

## Fact ledger

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | Godot: `project.godot`; version tag in `config/features` | local template ~/godot-templates/starter/project.godot (`config/features=PackedStringArray("4.6", ...)`); router engine-detection.md | 2026-10-22 | Godot 4.x | likely | read local file and router reference. Godot docs page on the file format not opened |
| 2 | Unity: `Assets/` plus `ProjectSettings/ProjectVersion.txt`; `m_EditorVersion`; two lines incl. `m_EditorVersionWithRevision` | https://github.com/Unity-Technologies/com.unity.multiplayer.samples.bitesize (ProjectVersion.txt) | 2026-10-22 | Unity 6000.0.28f1 sample | confirmed | read raw file, plus router reference. No official manual page found |
| 3 | Unity: package versions in `Packages/manifest.json` | router engine-detection.md | 2026-10-22 | n/a | single-source | read router reference only. Not opened in a project |
| 4 | Unreal: `*.uproject`, `EngineAssociation` is a version for launcher builds, a GUID for source builds, can be empty | https://docs.unrealengine.com/4.26/en-US/API/Runtime/Projects/FProjectDescriptor/EngineAssociation/ | 2026-10-22 | UE 4.26 docs and later docs | likely | web search summary of Epic docs, page not opened |
| 5 | Web engines: `package.json` deps `phaser`, `pixi.js`, `three`; resolve from lockfile | npm registry | 2026-10-22 | phaser 4.2.1, pixi.js 8.22.0, three 0.186.1 | confirmed | `npm view` returned each package |
| 6 | Bevy: `Cargo.toml` dep `bevy`, resolve from `Cargo.lock` | crates.io API | 2026-10-22 | bevy 0.20.0 | confirmed | curl crates.io returned crate |
| 7 | `npx skills add Unity-Technologies/skills` | https://github.com/Unity-Technologies/skills README | 2026-10-22 | n/a | confirmed | README read. `npx skills add --help` shows the `add <package>` form |
| 8 | Official Unity plugin repo `Unity-Technologies/unity-agent-plugin`, ships the same skills | README of Unity-Technologies/skills, plugin.json (name unity, 0.1.8-beta) | 2026-10-22 | 0.1.8-beta | confirmed | gh api. Its own README holds no install commands, so none are given |
| 9 | Unity skills drive the open Editor through the Unity CLI | Unity-Technologies/skills README | 2026-10-22 | n/a | confirmed | read README |
| 10 | Unreal: `/plugin install unreal-engine-skills-for-claude-code@claude-plugins-official`; repo EpicGames/unreal-engine-skills-for-claude-code-plugin; needs editor running with ModelContextProtocol and AllToolsets plugins; warning about broad access | repo README | 2026-10-22 | pushed 2026-09-17, MIT | confirmed | read README, including its Security section (line 86: broad, live access, treat like running arbitrary code from an assistant) |
| 11 | `npx skills add gamedev-skills/awesome-gamedev-agent-skills`; repo URL; Apache-2.0 | repo README and gh api | 2026-10-22 | 74 skills | confirmed | read README, `npx skills add --help` |
| 12 | `router/references/engine-detection.md` exists in that repo | local plugin cache copy | 2026-10-22 | commit 0a70cfc64672 | confirmed | read local copy |
| 13 | Trauma model: damage adds trauma (+= 0.2 or 0.5), linear decrease, shake = trauma^2 or ^3, 0.30/0.60/0.90 = 3%/22%/73%, 3D rotational only | Eiserloh GDC 2016 slides PDF | 2026-10-22 | n/a | confirmed | extracted text from the PDF |
| 14 | Sakurai: both fighters freeze the same time, more damage gives longer hitstop, a cap exists | sourcegaming.info translation | 2026-10-22 | n/a | single-source | page read (a translation) |
| 15 | Final Fight hitstop 6 frames | shane-sicienski.com | 2026-10-22 | n/a | single-source | page read |
| 16 | SF2 hit freeze about 14 frames | sonichurricane.com | 2026-10-22 | n/a | single-source | page read |
| 17 | Pixel-art guide: 2-4 frames light, 6-10 heavy at 60 fps | gamineai.com | 2026-10-22 | n/a | single-source | page read. Labeled a rough guideline |
| 18 | Unity: `WaitForSeconds` coroutines do not run while `timeScale` is 0 | Unity Time.timeScale docs | 2026-10-22 | n/a | confirmed | page read |
| 19 | Godot `Engine.time_scale` affects Timer, SceneTreeTimer, delta | Godot Engine class docs | 2026-10-22 | stable | confirmed | page read |
| 20 | Godot: do not commit `.godot/` | Godot VCS page | 2026-10-22 | stable | confirmed | page read |
| 21 | Squash and stretch under about 0.15 s; shake per event light 0.2 heavy 0.5 | user's game-feel.md; slides for the 0.2 and 0.5 | 2026-10-22 | n/a | squash time: unverified starting default, shake amounts: confirmed by slides | labeled starting defaults in the skill |
| 22 | "About 300 lines" script limit | user's CLAUDE.md | 2026-10-22 | n/a | unverified (a user rule) | labeled a starting limit |
| 23 | Godot supports C# alongside a `.csproj` | router disambiguation rules | 2026-10-22 | n/a | single-source | router text |

## Not confirmed

- Claims 1, 3, 4, 23: single or secondary source, kept because they are low-risk fingerprints and the skill tells the agent to verify each fingerprint in the project.
- Unity manual page for `ProjectVersion.txt`: none found. Confirmed from a sample file instead.
- Engine version for Unity plugin install commands: the plugin README has none, so none are given.
- Hit-stop numbers: all labeled starting defaults, no standard exists.
- No live-model baseline and no run of the trigger evals (they cost money, and the skill is not yet registered in marketplace.json, so the staged eval plugin does not include it).

## Left out

- Full engine fingerprint tables for LÖVE, pygame, Roblox: pointer to the router reference instead.
- Engine code samples for shake and hit-stop: engine skills own them.
- Per-engine tool names for run, input, and state: tool sets change. The skill names capabilities and gives a fallback.
- Prototype timeboxing detail: pointer to prototype-fast.

# Research notes: godot and godot-upgrade skills

Date: 2026-10-22
Depth: standard
Research skill used: no (inline, per brief)
Prior-art search: done
Confirmation gates: approved by the maintainer in the build brief.

## Scope
godot: verify loop, headless runner traps, .tscn hand editing, VCS files, doctool, typed GDScript pitfalls, visual baseline.
godot-upgrade: procedure plus per-version fact table 4.0 to 4.7.
Not covered: node catalogue, patterns, game feel (see prior art for breadth).

## Sources
| Source | Tier | Retrieved |
|---|---|---|
| docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.x.html (4.0 to 4.7, all 8 pages) | official | 2026-10-22 |
| godotengine.org/releases/4.3, 4.4, 4.5, 4.6, 4.7 | official | 2026-10-22 |
| godotengine.org/article/uid-changes-coming-to-godot-4-4 | official | 2026-10-22 |
| docs: command_line_tutorial, version_control_systems, tscn file format, static_typing, gdscript_basics, class_environment, multiple_resolutions | official | 2026-10-22 |
| Context7 /websites/godotengine_en_4_7 (typed override return, SceneTree.quit) | official via Context7 | 2026-10-22 |
| Local binary Godot 4.6.1.stable.official.14d19694e, scratch projects | reproduced | 2026-10-22 |

## Prior art
Queries: `npx skills find godot`; `gh api` tree listing and SKILL.md reads for each candidate below; `gh search repos "godot skill claude"` (empty).

| Name | Source URL | Maintainer | Adoption, updated | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| gamedev-skills/awesome-gamedev-agent-skills (skills/godot/*) | https://github.com/gamedev-skills/awesome-gamedev-agent-skills/tree/HEAD/skills/godot | community | 2751 stars, 2026-10-22 | 75 skills, 17 Godot (gdscript, nodes, physics, ui, export, csharp, headless-testing) | Tight "when not to use" lines, Godot 4.7 targeted, one reference per topic | No upgrade or version-delta skill, no end-to-end verify loop (run, screenshot, live state), headless-testing overlaps our runner trap section | Apache-2.0 |
| gamedev-skills ... godot-gdscript-headless-testing | https://github.com/gamedev-skills/awesome-gamedev-agent-skills/blob/HEAD/skills/godot/godot-gdscript-headless-testing/SKILL.md | community | same | SceneTree runner, exit codes, clean-checkout import | Covers assert hang, quit(code), import first | Does not cover --check-only exit 0, --quit-after masking a hung assert as exit 0, .uid, doctool | Apache-2.0 |
| jame581/GodotPrompter | https://github.com/jame581/GodotPrompter/tree/HEAD/skills | community | 861 stars, 2026-10-22 | ~70 skills (testing with GUT/gdUnit4, debugging, patterns, review) | Evals per skill, 4.7 delta notes and callouts inside skills, framework choice table | Per-skill 4.x callouts instead of one upgrade procedure, no verify loop with headless parse check | MIT |
| wshobson/agents godot-gdscript-patterns | https://github.com/wshobson/agents/blob/HEAD/plugins/game-development/skills/godot-gdscript-patterns/SKILL.md | community | 41533 stars (repo), 2026-10-19 | GDScript patterns, signals, state machines | Very high adoption | Textbook patterns the model knows, no version pins, no verification | MIT |

Decision: write new skills. Our gap is the verify loop (what Godot returns as exit codes, what each check catches) and a per-hop upgrade procedure with a dated fact table. Ideas adopted: a "when not to use" line and one-topic references (gamedev-skills), per-version callouts (GodotPrompter). Weaknesses avoided: textbook pattern lists, unpinned versions. No text copied. Breadth (nodes, physics, UI, testing frameworks GUT and gdUnit4) is left to those repositories and linked.

## Fact ledger
| # | Claim | Source | Version | Confidence | Verified by |
|---|---|---|---|---|---|
| 1 | `--import` exits 0 and prints no error for a project with broken .gd scripts | local | 4.6.1 | confirmed | ran bad project, exit 0, no error lines |
| 2 | `--check-only --script` exits 0 even with parse errors; errors only in output | local | 4.6.1 | confirmed | ran, exit 0 |
| 3 | Without a prior import, check-only reports false `Identifier "Player" not declared` for class_name | local; headless-testing prior art agrees | 4.6.1 | confirmed | rm -rf .godot, ran |
| 4 | failed assert() in SceneTree `_initialize` hangs the process | local | 4.6.1 | confirmed | 15 s timeout |
| 5 | push_error does not change exit code (0) | local | 4.6.1 | confirmed | ran |
| 6 | quit(3) exits 3; code after quit() in the same call still runs | local, docs say "at the end of the current iteration" | 4.6.1 | confirmed | ran |
| 7 | `--quit-after N` ends the hung assert case with exit 0 | local | 4.6.1 | confirmed | ran, exit 0 in <20 s |
| 8 | `:=` on Dictionary value or untyped Array element: "Cannot infer the type"; on JSON.parse_string / str_to_var result: warning treated as error; load() and get_node() infer fine; typed Array and Dictionary[String,int] infer fine | local | 4.6.1 | confirmed | check-only run |
| 9 | str2var is gone (parse error), str_to_var exists | local | 4.6.1 | confirmed | ran; doctool lists str_to_var |
| 10 | `--doctool <path>` dumps class XML with signatures, empty descriptions outside the source tree; erases `<path>/doc/classes` first (message "Erasing old docs at") | local | 4.6.1 | confirmed | ran, 6.6 MB |
| 11 | Dangling `ExtResource("id")` makes scene load fail with "Parse error ... :N"; import reports it; missing path reports "[ext_resource] referenced non-existent resource" | local | 4.6.1 | confirmed | ran |
| 12 | `--write-movie out.png --fixed-fps 30 --quit-after N` writes numbered PNG frames and needs a window (not headless); exit prints leak ERROR lines at quit | local; CLI docs | 4.6.1 | confirmed | ran |
| 13 | CLI docs: --headless, --import (implies --editor and --quit), --check-only, --script must inherit SceneTree or MainLoop, unknown args have no effect | https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html | 4.7 docs | confirmed | read |
| 14 | SceneTree.quit(exit_code=0), keep 0-125 | Context7 docs 4.7 | 4.7 | confirmed | read |
| 15 | assert ignored in non-debug builds, pauses editor-run project | gdscript_basics | stable | confirmed | read |
| 16 | .uid sidecars for scripts and shaders from 4.4, commit them, do not ignore, move with file; re-save scenes after upgrading from 4.3 | https://godotengine.org/article/uid-changes-coming-to-godot-4-4/ | 4.4 | confirmed | read plus local run created .gd.uid files |
| 17 | .godot/ not committed; VCS ignore list applies to 4.1+ | version_control_systems, 4.4 release page | 4.1+ | confirmed | read |
| 18 | TSCN: format=3; load_steps deprecated and ignorable in 4.6+; unique_id only in 4.6+ saves; ext_resource has path, type, uid, id; sub_resource no uid; referring resource must come after the referenced one; comments and default-valued props dropped on save | tscn doc | 4.7 docs | confirmed | read |
| 19 | 4.6 glow: default blend Soft Light to Screen, glow_intensity 0.8 to 0.3, glow before tonemapping; Environment doc lists order DoF, auto exposure, glow, tonemap, adjustments; SOFTLIGHT described as applied to tonemapped image (docs conflict) | 4.6 migration page, 4.6 release page, class_environment | 4.6 | confirmed (conflict noted) | read |
| 20 | Tonemap modes LINEAR (default), REINHARDT, FILMIC, ACES, AGX; AgX contrast default 1.25, white 16.29 | class_environment; local doctool | 4.6.1 | confirmed | read plus grep |
| 21 | AgX tonemapper arrived in 4.4; 4.6 made its parameters configurable | 4.4 and 4.6 release pages | 4.4, 4.6 | likely (4.4 page lists it under Rendering; does not say "new" in so many words) | read |
| 22 | Pixel art: stretch mode viewport, aspect keep, scale mode integer (since 4.2) | multiple_resolutions | stable | confirmed | read |
| 23 | Project setting names default_texture_filter (default 1 = Linear), snap_2d_transforms_to_pixel (false), snap_2d_vertices_to_pixel, stretch/mode, stretch/scale_mode exist | local doctool | 4.6.1 | confirmed | grep |
| 24 | 4.7 new projects: stretch mode canvas_items, aspect expand | 4.7 migration page | 4.7 | confirmed | read |
| 25 | 4.0 to 4.7 per-hop deltas | each migration page | see table in godot-upgrade | confirmed unless marked | read |
| 26 | `@export` plus `@onready` on one variable does not work as expected | gdscript_basics | stable | confirmed | read |
| 27 | Nested typed collections (Array[Array[int]]) not supported | static_typing | stable | confirmed | read |
| 28 | 4.7 override of method with typed return needs explicit return (add return null) | 4.7 migration, Context7 | 4.7 | confirmed | read |

## Not confirmed
- Whether the 4.7 page calls 4.7 "stable": the docs "stable" URL serves 4.7 pages, the release page says "feature release". Skill says "4.7" without the word stable.
- Exact first version of AgX (ledger 21): skill says "4.4 or later" nowhere without a source; table row cites the 4.4 release page.
- Not reproduced locally: everything marked 4.7 (only 4.6.1 binary available).
- Exported-build behaviour of assert, exit codes on non-macOS, Godot builds other than the official 4.6.1 standard build.

## Left out
Godot 3 to 4 rename table (textbook; official page linked), game feel, node and physics patterns (prior art), godot-mcp-runtime tool names (user specific), gdformat/gdlint hook (user tooling, not Godot fact), asset source links.

## Addendum (written during drafting)
- Ledger 29: `--import` loads only the project's main scene. A dangling ExtResource in another scene is silent at import (ran with and without run/main_scene). Confirmed on 4.6.1.
- Ledger 30: `Resource.DEEP_DUPLICATE_ALL` and `duplicate_deep` exist in the 4.6.1 class dump. Confirmed.
- Not confirmed: `config/features` in project.godot records the editor version. Skill says "hint, unverified".
- Corrections to the source skill: str2var is gone (parse error) and str_to_var exists, so the str2var row was dropped; `load()` and `get_node()` infer fine with `:=` (the source skill said they do not); AgX arrived in 4.4, only its parameters became configurable in 4.6.

---
name: godot-upgrade
description: Godot 4 minor-version upgrade playbook for hops from 4.0 to 4.7, with behavior changes per version and a verify step. Use to upgrade a Godot project, open it in a newer editor, check changed defaults, or fix glow, physics, .uid or scene-diff surprises after an upgrade.
user-invocable: true
---

# Godot version upgrade

A Godot minor release changes defaults and file formats without a compile error: glow looks different, physics behaves differently, scenes rewrite themselves on save. Upgrade one minor version at a time, read the official page for each hop, and prove the result in the running game.

## Core principles

| Principle | Meaning |
|---|---|
| Read the page for every hop | The official `Upgrading from Godot 4.x to Godot 4.y` page is the source. The table below is a starting list, not a replacement |
| One minor at a time | 4.3 to 4.4 to 4.5. Skipping hides which release caused a change |
| Back up first | Commit everything, and tag it. Some upgrades cannot be undone (the 4.2 mesh format, saved scenes) |
| Re-save in its own commit | Opening and saving scenes rewrites them. Keep that diff apart from your changes |
| Prove it in the game | An upgrade is done when the verify loop passes on the target version, with a screenshot compared to one from before |

## Procedure

1. Find the current version: the README or CI config, or the `config/features` line in `project.godot` when it has one (unverified, treat it as a hint). The target is `godot --version`. Ask when they disagree.
2. Read the migration page for each hop between them: `https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.<minor>.html`. For the 3.x to 4 jump read `upgrading_to_godot_4.html` and use its `--convert-3to4` tool after a full backup. Note what applies: grep the project for each renamed or changed API, and list changed defaults you rely on.
3. Back up. On the old version, run the verify loop from the `godot` skill and take reference screenshots of the main scenes.
4. Open the project in the new editor once. Accept the project-file upgrade prompts, or run Project > Tools > Upgrade Project Files (4.6 and later). Re-save every scene and resource, then commit that alone.
5. Walk the changed defaults for the hop (table below). Settings that changed only for new projects need no action. Settings that changed for existing ones are in the "Changed defaults" part of the page.
6. Fix API changes: the migration page lists signature, return type, and rename changes, with a column for GDScript compatibility. GDScript is affected only where that column says so.
7. Run the verify loop on the new version (`scripts/check.sh` from the `godot` skill, run the game, compare screenshots, check live state). Commit the new `.uid` files.
8. Pin the Godot version in CI and in the project README so the next person opens it with the same editor.

## Version facts

Verified against the official migration pages and release pages on 2026-10-22. Each row is what changes behavior in the hop, not every API change. Open the page for the full list.

| Hop | Behavior-changing deltas |
|---|---|
| 3.x to 4.0 | Many renames (`Sprite` to `Sprite2D`, `KinematicBody2D` to `CharacterBody2D`). `--convert-3to4` handles scripts partly. Lifecycle functions no longer call the parent version implicitly (use `super()`). `call_group()` is immediate by default. Shader texture settings moved to uniforms. Environment quality settings moved to project settings. Re-import `ArrayMesh` resources |
| 4.0 to 4.1 | `SubViewportContainer.mouse_filter` must be Stop or Pass for input to reach its viewports. Viewports with physics picking mark input events as handled. `NavigationAgent` and `NavigationServer` avoidance API reshaped (`set_velocity` became the `velocity` property, `time_horizon` split in two) |
| 4.1 to 4.2 | New Mesh format. The upgrade dialog offers Restart and Upgrade (no downgrade below 4.2) or Upgrade Only (slower loading). Commit first. `AnimationPlayer` and `AnimationTree` members moved to `AnimationMixer`, with renames (`playback_active` to `active`, `method_call_mode` to `callback_mode_method`). `TileMap.cell_quadrant_size` became `rendering_quadrant_size`. Stretch scale mode `integer` added |
| 4.2 to 4.3 | `TileMapLayer` node replaces layers inside `TileMap`, and the editor converts in one click. `TileMap` still works but is deprecated. Reverse Z depth buffer can break custom shaders. Default font outline color white to black. `auto_translate` deprecated for `auto_translate_mode`. `PackedByteArray` saves in a compact base64 form that older editors cannot open. Android permissions no longer requested automatically. Binary serialization changed |
| 4.3 to 4.4 | Scripts and shaders get `.uid` files. Commit them, never ignore them, and re-save scenes once. `@export_file` stores `uid://` values (`@export_file_path` for raw paths arrives in 4.5). `Curve` values are range checked. CSG uses Manifold, so non-manifold meshes no longer work. `FileAccess.store_*` return `bool`. Android sensors off by default. Jolt is available as an experimental 3D engine. AgX tonemapper added. Typed dictionaries added |
| 4.4 to 4.5 | `Resource.duplicate(true)` copies only internal resources. `duplicate_deep(DEEP_DUPLICATE_ALL)` restores the 4.4 result. `TileMapLayer` physics chunking is on (`physics_quadrant_size = 1` turns it off). Navigation regions update on threads by default. With Jolt, `Area3D` always reports static-body overlaps and the `areas_detect_static_bodies` setting is gone. New glTF, FBX and Blender imports use a corrected skeleton naming version, existing files keep the old one. GDScript gains abstract classes and variadic arguments |
| 4.5 to 4.6 | Scenes no longer write `load_steps` and save node unique ids, so run Upgrade Project Files once. Glow: default blend Soft Light to Screen, intensity 0.8 to 0.3, other glow defaults changed, glow blended before tonemapping. Volumetric fog looks brighter. New 3D projects default to Jolt and new Windows projects to Direct3D 12 (existing projects keep their settings). `AStar` path queries from a disabled or solid start return an empty path. `MeshInstance3D.skeleton` default changed. `AnimationPlayer` animation names are `StringName`. AgX parameters are configurable |
| 4.6 to 4.7 | An override of a method with a typed return needs an explicit `return` (add `return null`). Mouse and keyboard `InputEvent.device` is `DEVICE_ID_MOUSE` and `DEVICE_ID_KEYBOARD`, not 0. `AudioStreamPlayer` default `area_mask` 1 to 0, so `audio_bus_override` areas stop working until the mask is set to layer 1. Jolt: `WorldBoundaryShape3D.plane.d` sign flipped, `SoftBody3D` default mass 1 kg and stiffness applied differently. `CanvasItem` lines lose their antialiasing feather and look thinner. `LinearToSRGB` no longer clamps. Assigning one packed-array element no longer calls the whole-array setter. `sky_reflections/roughness_layers` back to 8. New projects: stretch mode `canvas_items`, aspect `expand` |

Sources: the eight pages linked from [the migration index](https://docs.godotengine.org/en/stable/tutorials/migrating/index.html), the [.uid article](https://godotengine.org/article/uid-changes-coming-to-godot-4-4/), and the release pages for [4.3](https://godotengine.org/releases/4.3/), [4.4](https://godotengine.org/releases/4.4/), [4.5](https://godotengine.org/releases/4.5/), [4.6](https://godotengine.org/releases/4.6/), and [4.7](https://godotengine.org/releases/4.7/).

## Pitfalls

| Pitfall | Why it hurts | Prevention |
|---|---|---|
| Opening the project in the new editor and saving casually | Scenes rewrite, `.uid` files appear, and node ids change, which buries real changes in the diff | Do the re-save as its own commit before any code change |
| Judging glow or fog from the old values | 4.6 changed the defaults and the blend order, so the same numbers look different | Compare screenshots and retune, as the 4.6 page says |
| Ignoring "new projects only" notes | Jolt, D3D12 and 4.7 stretch defaults apply to new projects, not to yours | Set them on purpose if you want them. Do not assume the project switched |
| Skipping a minor | A change from the skipped hop shows up with no way to tell where it came from | Upgrade and verify each minor |
| Trusting the test run | Import and parse checks exit 0 on broken scripts | Use the verify loop in the `godot` skill |

## Reference files

| Reference | Contents |
|---|---|
| `godot` skill | Verify loop, `check.sh`, headless test traps, `.tscn` editing rules |
| [Migration index](https://docs.godotengine.org/en/stable/tutorials/migrating/index.html) | The official page for every hop |

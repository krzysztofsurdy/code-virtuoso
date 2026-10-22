---
name: godot
description: Godot 4 work in a project with project.godot, .gd or .tscn files. Use to verify a change in the running game, fix a headless GDScript test run that hangs or exits 0, hand-edit a .tscn, commit .uid files, or catch an invented API.
user-invocable: false
---

# Godot

Godot reports success when the project is broken. A headless import and a parse check both exit 0 with broken scripts, a failed `assert()` can hang a script run, and `push_error` does not change the exit code. An agent that trusts exit codes or "it compiles" reports done on a game that does not run. This skill gives the loop that proves a change, and the traps that make the usual checks lie.

Facts here are for Godot 4.x and name the version where behavior differs. Run `godot --version` first, and use the `godot-upgrade` skill when the project crosses versions.

## Verify loop

Run it after every change. Done means seen working in the running game.

| Step | How | Pass when |
|---|---|---|
| 1. Import | `godot --headless --path <dir> --import` | Run it on a clean checkout too: `.godot/` is not committed, and without an import `class_name` types do not resolve |
| 2. Parse | `godot --headless --path <dir> --check-only --script res://file.gd` per script | The output has no `SCRIPT ERROR` or `Parse Error`. The exit code is 0 either way |
| 3. Run and read the log | Run the game and read its output | No `ERROR` or `WARNING` from your code |
| 4. Screenshot | Capture a frame of the running game and look at it | The change is visible |
| 5. Input | Simulate an input action, not a raw key | The action fires |
| 6. Live state | Read a value from the running scene tree (position, health, scene name) before and after the input | The value changed as intended. A screenshot alone is not proof |
| 7. Stop, commit | Stop the game, then commit | |

[scripts/check.sh](scripts/check.sh) runs steps 1 and 2 for a whole project and exits 1 on errors, because it reads the output instead of the exit code. Set `GODOT` to the binary. Its self-test is `scripts/test-check.sh`.

Steps 3 to 6 need a way to run the game and drive it. An MCP server for Godot or the CLI can provide this (see Platform notes). Without an MCP server: `godot --path <dir> --write-movie out.png --fixed-fps 30 --quit-after 60` writes numbered PNG frames from a windowed run (it cannot run headless), and read the last one. A `--script` run can print live state and call `quit(code)` itself.

Import only loads the main scene (`run/main_scene`). A broken `.tscn` elsewhere shows up when something loads it, so open it with `godot --headless --path <dir> --quit-after 2 res://x.tscn` and read the output.

The `game-feature-loop` playbook wraps this loop in a plan, build, verify, commit cycle for one mechanic at a time.

## Exit-code traps

Reproduced on 4.6.1. Details and a safe runner in [headless-testing](references/headless-testing.md).

| You do | What happens |
|---|---|
| `assert(false)` in a SceneTree script's `_initialize` | Prints `Assertion failed`, then the process hangs. With `--quit-after N` it ends with exit 0 |
| `push_error()` or `printerr()` | Exit code stays 0 |
| `--check-only` or `--import` on a broken script | Exit code 0, and import prints nothing about the script |
| `quit(1)` | Exits 1, but code after it in the same function still runs |

Count failures yourself and end with `quit(1 if failures > 0 else 0)`. Put a timeout on the process from outside (CI step timeout, or `timeout` where it exists).

## Files to commit

- Commit `.uid` files next to every `.gd` and shader (4.4 and later) and the `.import` files. Never edit them by hand. Move them with their file.
- Do not commit `.godot/`. It is a cache rebuilt by the import.
- After moving or renaming a script outside the editor, move its `.uid` file too, then run the import.

## Editing .tscn text

Prefer the editor or an MCP scene tool. When you edit text, follow [scene-text-editing](references/scene-text-editing.md): ids must match, a resource is declared before it is used, and a 4.6 or later editor rewrites the file on save, so expect a large diff once.

## Do not invent APIs

When a class, method, signal, or property is not certain, dump the signatures from the installed binary and grep:

```bash
godot --headless --path <project> --doctool <outdir>
grep -n 'method name="move_and_slide"' <outdir>/doc/classes/CharacterBody2D.xml
```

The dump has full signatures but empty descriptions, because descriptions live in the engine source tree. For behavior, read the official class page for the version. `--doctool` erases `<outdir>/doc/classes` first, so give it an empty scratch directory. Do not commit the dump (several MB).

## GDScript

Static typing is the main source of silent bugs. `:=` fails on values that are `Variant`, a typed override must return in 4.7, and `@export` with `@onready` on one variable does not do what it looks like. See [gdscript-pitfalls](references/gdscript-pitfalls.md).

For a new project or flat-looking visuals, set the render baseline first: [visual-baseline](references/visual-baseline.md).

## Stop rule

After 2 failed fix attempts on the same problem, stop. Report what was tried and what was observed (log lines, live state values). A third guess without new evidence makes the state worse.

## Reference files

| Reference | Open when |
|---|---|
| [headless-testing](references/headless-testing.md) | Writing or debugging a `--script` test runner, CI that exits 0 on failure, or a hung process |
| [scene-text-editing](references/scene-text-editing.md) | Changing a `.tscn` or `.tres` as text |
| [gdscript-pitfalls](references/gdscript-pitfalls.md) | Writing typed GDScript, or a script that parses but misbehaves |
| [visual-baseline](references/visual-baseline.md) | Day one of a project, or visuals look flat |
| [research-notes](references/research-notes.md) | Godot and godot-upgrade research: prior-art table, fact ledger with sources and dates, unconfirmed items |
| `godot-upgrade` skill | Moving a project between 4.x versions |

For breadth (node and pattern catalogues, GUT or gdUnit4 testing, shaders, multiplayer, export) use [gamedev-skills/awesome-gamedev-agent-skills](https://github.com/gamedev-skills/awesome-gamedev-agent-skills) (Apache-2.0) and [jame581/GodotPrompter](https://github.com/jame581/GodotPrompter) (MIT). This skill covers the verify loop and the version facts those do not.

## Platform notes

| Capability | Where to get it |
|---|---|
| Run the game, read its log, screenshot, simulate input, read live state | A Godot MCP server that does this (for example [godot-mcp-runtime](https://github.com/Erodenn/godot-mcp-runtime)), or the CLI as above |
| Headless import, parse check, doctool, `--script` runs | The `godot` binary alone: [command line docs](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) |
| Formatting and lint of `.gd` files | `gdformat` and `gdlint` from [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit) |

# Headless testing

Running GDScript from the command line without the editor, and getting an exit code a script or CI job can trust. Reproduced on Godot 4.6.1 (official standard build). Re-check on another version before relying on a row.

## Contents

- [What the CLI guarantees](#what-the-cli-guarantees)
- [Traps](#traps)
- [A runner that fails correctly](#a-runner-that-fails-correctly)
- [CI](#ci)
- [Test frameworks](#test-frameworks)

## What the CLI guarantees

From the [command line docs](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html):

- `--headless` runs with the headless display driver and a dummy audio driver. It is required where there is no GPU, such as CI.
- `--import` starts the editor, waits for imports, and quits. It implies `--editor` and `--quit`.
- `--script <file>` runs a script that must inherit `SceneTree` or `MainLoop`. `--check-only` with it parses and quits.
- Unknown arguments have no effect, so a flag the build lacks fails silently.
- `SceneTree.quit(exit_code)` ends the run at the end of the current iteration. Keep the code between 0 and 125.

The docs state no exit-code contract beyond that. Everything in the next table was observed, not documented.

## Traps

| Situation | Observed on 4.6.1 | Do instead |
|---|---|---|
| `assert(false)` in `_initialize` of a SceneTree script | Prints `SCRIPT ERROR: Assertion failed`, the rest of the function is skipped, and the process never exits | Use a helper that records the failure and continues. `assert` is also ignored in non-debug builds, so it cannot be the test mechanism |
| Same hang with `--quit-after N` | The process ends, with exit 0 | Never treat `--quit-after` as a timeout for tests |
| `push_error("...")`, `printerr(...)` | Output on stderr, exit 0 | Count failures and call `quit(1)` |
| `quit(1)` followed by more code | The code after `quit()` still runs | Put `quit()` last, or `return` right after it |
| `--check-only --script bad.gd` | Errors printed, exit 0 | Read the output for `SCRIPT ERROR` or `Parse Error` |
| `--import` with a broken script | No error printed, exit 0 | Parse each script as above |
| `--check-only` on a clean checkout | False `Identifier "X" not declared` for every `class_name` type | Run `--import` first, because it registers global classes |
| Scene with a dangling `ExtResource("id")` | The import reports it only for the main scene. Any other scene fails when loaded | Load the scene: `godot --headless --path . --quit-after 2 res://x.tscn` |
| `--write-movie` run | Needs a window. Quit prints leak `ERROR` lines | Do not grep this run for `ERROR` to decide pass or fail |

## A runner that fails correctly

```gdscript
extends SceneTree

var failures: int = 0


func check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", label)


func _initialize() -> void:
	check(1 + 1 == 2, "addition")
	check(2 * 3 == 7, "multiplication")
	quit(1 if failures > 0 else 0)
```

Run it with `godot --headless --path <dir> --script res://tests/runner.gd`, then read `$?`. Each test file that touches `class_name` types needs the import to have run. A test that awaits a signal that never fires hangs, so give every `await` a timer fallback and still wrap the process in an outside timeout.

## CI

- Run `--import` before the tests. The cache is not committed.
- Set a step timeout. macOS has no `timeout` command, so use the CI system's step timeout or a small wrapper in another language.
- Read the process exit code in the step, not only stdout.
- Pin the Godot version in the job. Behavior in this file can differ between versions.

## Test frameworks

For assertions, mocks, scene runners, and a CLI runner, use GUT or gdUnit4 instead of growing the runner above. jame581/GodotPrompter's `godot-testing` skill compares them, and gamedev-skills' `godot-gdscript-headless-testing` covers the same SceneTree runner pattern in more depth.

#!/usr/bin/env bash
set -euo pipefail
mkdir -p tests
cat > project.godot <<'CFG'
; Engine configuration file.
config_version=5

[application]
config/name="Arena"
config/features=PackedStringArray("4.6")
CFG
cat > tests/run.gd <<'GD'
extends SceneTree


func add(a: int, b: int) -> int:
	return a - b


func _initialize() -> void:
	assert(add(2, 2) == 4)
	assert(add(1, 1) == 2)
	print("tests finished")
	quit()
GD
cat > ci.sh <<'SH'
#!/usr/bin/env bash
set -e
godot --headless --path . --check-only --script res://tests/run.gd
godot --headless --path . --script res://tests/run.gd --quit-after 60
echo "CI green"
SH
chmod +x ci.sh

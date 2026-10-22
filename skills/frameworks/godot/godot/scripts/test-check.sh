#!/usr/bin/env bash
# Self-test for check.sh. Builds one good and two bad projects in a temp dir.
# Needs a Godot 4 binary: GODOT=/path/to/godot bash scripts/test-check.sh
set -u

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
PASS=0
FAIL=0

expect_exit() {
  local name="$1" want="$2" project="$3" got
  OUT="$("$DIR/check.sh" "$project" 2>&1)"
  got=$?
  if [ "$got" -eq "$want" ]; then
    PASS=$((PASS + 1)); printf 'ok   %s\n' "$name"
  else
    FAIL=$((FAIL + 1)); printf 'FAIL %s (exit %s, wanted %s)\n%s\n' "$name" "$got" "$want" "$OUT"
  fi
}

expect_out() {
  if printf '%s' "$OUT" | grep -qF -- "$2"; then
    PASS=$((PASS + 1)); printf 'ok   %s\n' "$1"
  else
    FAIL=$((FAIL + 1)); printf 'FAIL %s (output lacks %s)\n%s\n' "$1" "$2" "$OUT"
  fi
}

mkdir -p "$WORK/good" "$WORK/typed" "$WORK/syntax" "$WORK/scene" "$WORK/empty"
for p in good typed syntax scene; do
  printf 'config_version=5\n\n[application]\nconfig/name="%s"\n' "$p" > "$WORK/$p/project.godot"
done

cat > "$WORK/good/player.gd" <<'GD'
class_name Player
extends Node2D

@export var speed: float = 200.0
GD
cat > "$WORK/good/main.gd" <<'GD'
extends Node

func _ready() -> void:
	var p: Player = Player.new()
	print(p.speed)
GD
cat > "$WORK/typed/a.gd" <<'GD'
extends Node

func _ready() -> void:
	var n: int = "text"
	print(n)
GD
cat > "$WORK/syntax/b.gd" <<'GD'
extends Node
func _ready( -> void
	pass
GD

cat > "$WORK/scene/main.tscn" <<'TSCN'
[gd_scene format=3]

[ext_resource type="Script" path="res://main.gd" id="1_abc"]

[node name="Main" type="Node"]
script = ExtResource("9_missing")
TSCN

printf 'extends Node\n' > "$WORK/scene/main.gd"
printf 'run/main_scene="res://main.tscn"\n' >> "$WORK/scene/project.godot"

expect_exit "good project passes, class_name resolved after import" 0 "$WORK/good"
expect_out "good project prints OK" "check.sh: OK"
expect_exit "type error fails" 1 "$WORK/typed"
expect_out "type error names the file" "a.gd"
expect_exit "syntax error fails" 1 "$WORK/syntax"
expect_exit "dangling ExtResource id in the main scene fails at import" 1 "$WORK/scene"
expect_out "scene error names the file" "main.tscn"
expect_exit "directory without project.godot fails" 1 "$WORK/empty"

printf '\n%s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]

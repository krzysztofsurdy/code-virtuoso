#!/usr/bin/env bash
set -euo pipefail
cat > project.godot <<'GD'
; Engine configuration file.
config_version=5

[application]
config/name="Tiny Platformer"
config/features=PackedStringArray("4.4", "Forward Plus")

[input]
move_left={
"deadzone": 0.5,
"events": []
}
move_right={
"deadzone": 0.5,
"events": []
}
jump={
"deadzone": 0.5,
"events": []
}
GD
cat > player.gd <<'GD'
extends CharacterBody2D

const SPEED: float = 220.0
const JUMP_VELOCITY: float = -420.0
const GRAVITY: float = 980.0


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * SPEED
	move_and_slide()
GD

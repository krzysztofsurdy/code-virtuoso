---
tags: [outcome, godot-upgrade]
max_turns: 6
timeout_seconds: 240
allowed_tools: [Read, Glob, Grep, Skill]
---

We are moving our Godot project from the 4.6 editor to 4.7. A few things we rely on: cave zones are Area3D nodes using audio_bus_override for reverb, our input code tells the mouse from gamepad 0 with event.device == 0, and several of our Node subclasses override typed-return virtuals with early exits. Walk me through what could silently change or break on this hop and what I should set or edit.

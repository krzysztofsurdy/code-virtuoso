---
name: game-feature-loop
description: "Add a mechanic, implement a game feature, build a level, make the jump feel better, or prototype a game, one verified step at a time on any engine (Godot, Unity, Unreal, web, others). Detect the engine, plan one mechanic, build, run, prove it from live state, commit, then a separate game-feel pass."
user-invocable: true
argument-hint: "[mechanic or feature to add]"
---

# Game feature loop

A game can pass every test and still be unplayable: the input is never mapped, the node is not in the scene, the animation fights the movement code. An agent that stacks three features before running the game then cannot tell which one broke it. A screenshot does not settle it either, because a still frame shows layout, not behavior. This playbook builds one mechanic at a time and treats "done" as behavior observed in the running game.

## Gates that apply to every step

| Gate | Rule |
|---|---|
| One mechanic at a time | Do not start the next mechanic until this one is proven and committed |
| Done means observed | Tests passing, a clean compile, or a good screenshot is not done. Behavior read from the running game is |
| Two failed fixes | After two failed attempts at the same problem, stop. Report what was tried and what was observed. Do not guess a third time |
| Ask before spending | Paid asset generation (images, 3D, audio, sprites) needs explicit approval and a cost first |
| Ask before scope jumps | A new subsystem, an engine change, or a rewrite of existing architecture needs a yes before any code |
| Art bible first | If the project has an art bible or style guide, follow it. Do not add a new art source or mix styles and resolutions without asking |
| Tests for pure logic only | Test-first applies to damage math, inventory rules, state machine transitions. Gameplay and visuals are checked by running the game |

## Step 1: detect the engine and version

Do not assume. Look for the project fingerprint, open the file, and confirm it is a real project root and not a vendored sample or a dependency. Read the version from the project's own version source before choosing any API, because engine APIs differ between major versions and tutorials mix them.

The fingerprints, version sources, and ambiguity rules are in [engine-fingerprints](references/engine-fingerprints.md). If two engines match (a monorepo), pick by the directory the request is about. If none match and the user named no engine, ask. Never load engine knowledge on a guess.

Then find out how to run the game and drive it. See [step 4](#step-4-run-the-game) for the capabilities to look for. Do this now, not after the code is written.

## Step 2: plan one mechanic

Write the plan before the code. Keep it to a few lines:

```text
Mechanic:    one verb the player does (double jump, dash, pick up key)
Pass check:  the observable change that proves it, with numbers
             (example: vertical velocity goes from 0 to a negative value within 3 frames of the jump input)
Input:       the action a player would trigger, by its input-map name
State read:  the exact values to read before and after
Out of scope: what this step will not touch
```

Rules that keep the plan small:

- If the request holds several verbs, split it and do the first. List the rest as later steps.
- Pick a pass check that a script can read: a position, a velocity, a health value, a state name, a count of spawned objects. If you cannot name one, the mechanic is not specified enough. Ask.
- Check the art bible and existing assets. Placeholder shapes are fine for a mechanic. Paid generation is a separate ask.
- For a prototype whose only question is "is this fun", keep the same loop but allow hard-coded values and one file. The proof step still applies. For timeboxing and keep or kill criteria, see `prototype-fast` in the community gamedev skills.

## Step 3: build

- Keep scripts small and single-purpose. About 300 lines is a starting limit. Split before a file passes it, not after.
- Give players, enemies, and anything with modes a state machine from the start (idle, move, jump, attack, hurt). Add behavior as states or components, not as flags inside one big update function. Retrofitting states later costs more than starting with them.
- Read input through the engine's named actions or bindings, never raw key codes. A missing binding is the most common reason a built mechanic does nothing.
- Put tunable numbers (speed, jump height, cooldown) in exported fields or data, not in the middle of code. The feel pass edits them.
- Split pure logic from engine calls so the logic can be tested without launching the game. Use the `tdd` playbook for that part only.
- Use the engine's own editing path for scenes and assets when one exists (editor API, CLI, bridge). Hand-editing scene text is a last resort. If you must, keep ids consistent and run the engine's import or validate step afterwards.
- Run the engine's static check (compile, script parse, lint) after each change and fix errors before running the game.

## Step 4: run the game

Launch the real game or scene, not only a unit test runner. Look for these capabilities, and use whatever the project and your tools offer:

| Capability | Why you need it |
|---|---|
| Launch and stop the game | Start from a clean state each time |
| Read logs and errors | Script errors and warnings often appear only at run time |
| Send input the way a player would | Proves the input wiring, not only the function |
| Read live state (a property, a variable, a query) | The only way to measure behavior |
| Capture a frame | Confirms layout, visibility, and art, after behavior is proved |

If a capability is missing, add the cheapest substitute: a log line or on-screen text that prints the value you need, a test scene that plays a scripted input sequence, or an automated play-mode test. [Engine notes](#engine-notes) lists where to find each in the main engines.

## Step 5: prove the behavior

Reading state before and after a simulated input is the proof. Do it in this order:

1. Read the plan's state values and record them (before).
2. Send the plan's input through the player path (an input action or key event), not by calling the function or setting the value yourself. Hold it long enough for several frames or ticks.
3. Wait a fixed number of frames or a fixed time, then read the same values (after). Reading in the same frame as the input reads the old state.
4. Compare with the plan's pass check, with a tolerance. Quote both readings in your report.
5. Run the negative case: no input gives no change, and releasing the input stops the effect.
6. Read the logs for errors and warnings from the run. A new warning is a finding.
7. Capture a frame only for visual claims (sprite visible, UI placed), and only after the state checks pass.

If the numbers do not match, that is a failed attempt, so count it against the two-attempt limit. Fix one thing, run the whole proof again, and compare.

If the game cannot be run here (no display, no editor, no engine installed), say so, list what is therefore unproven, and do not call the feature done. A passing unit test does not replace this step.

## Step 6: commit

Commit one mechanic per commit, after the proof passes. Commit the engine's sidecar files that the project tracks, and do not commit its cache folder (for Godot that is `.godot/`, see the [Godot version control page](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html)). Follow the project's commit conventions. Put the pass check and the before and after readings in the message or the pull request, because they are the evidence.

For the general rule on completion claims, see `verification-before-completion`.

## Step 7: game-feel pass

Do this as a separate pass, only after the mechanic is proven and committed. Never add feedback to a mechanic that is broken or unproven, because the effects hide the bug and the numbers you tuned against will move when it is fixed.

Weight feedback by how much the event matters. Hits, deaths, and big pickups get the most. Routine actions such as walking or a common pickup get little or none, because constant effects become noise and tire the player. Layer small effects (sound, particles, camera shake, a short freeze on impact, a flash, a tween on the target) for heavy events and use one or two for light ones. Do not cover information the player needs, and give players a way to reduce shake and flashing.

Every effect is its own small change: add it, run the game, check that it fires, returns to rest, and does not block input, then move on. The tier table, the starting values (all of them defaults to tune by playing, not rules), and the pitfalls are in [game-feel-pass](references/game-feel-pass.md).

## Engine notes

| Engine | Where engine-specific help lives |
|---|---|
| Godot | The `godot` skill in this library (`skills/frameworks/godot`) |
| Unity | Unity's official skills, `npx skills add Unity-Technologies/skills`, also shipped as the Unity plugin from https://github.com/Unity-Technologies/unity-agent-plugin. Many of its skills drive the open editor through the Unity CLI |
| Unreal | Epic's plugin for Claude Code, `/plugin install unreal-engine-skills-for-claude-code@claude-plugins-official`. It drives a live editor over MCP and needs the editor running. Source: https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin |
| Any engine, plus genres and disciplines | Community gamedev skills (Apache-2.0): `npx skills add gamedev-skills/awesome-gamedev-agent-skills`, source https://github.com/gamedev-skills/awesome-gamedev-agent-skills |

These are installed by the user, not by this skill. Read an unfamiliar package before installing it. Unreal's plugin gives the agent broad control of a running editor, so its README asks you to treat it like running code from an assistant.

## Pitfalls

- Reading "after" state in the same frame as the input, then deciding the mechanic is broken (or fine).
- Setting the value directly or calling the handler, which skips the input binding that was the real bug.
- Judging a mechanic from a screenshot. A frame can look right while the object does not move.
- Adding shake, particles, and sound while the mechanic is still being debugged.
- Building the second mechanic on top of an unproven first one, then debugging both at once.
- Hand-writing engine API calls from memory of an older major version. Check the version from step 1 and the engine docs.

## Reference files

| Reference | Contents |
|---|---|
| [engine-fingerprints](references/engine-fingerprints.md) | Project files that identify each engine, where each version lives, how to verify a match, ambiguity rules |
| [game-feel-pass](references/game-feel-pass.md) | Feedback tiers, effect menu, starting values with sources, when not to add feedback, pitfalls |
| [research-notes](references/research-notes.md) | Research: prior-art table, fact ledger with sources and dates, unconfirmed items |

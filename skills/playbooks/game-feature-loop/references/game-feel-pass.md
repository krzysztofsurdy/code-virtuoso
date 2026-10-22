# Game-feel pass

Step 7 of the loop. Feedback makes a working mechanic satisfying. It cannot rescue a broken one.

## Contents

- [Order of work](#order-of-work)
- [Weight by impact](#weight-by-impact)
- [Effect menu](#effect-menu)
- [Starting values to tune](#starting-values-to-tune)
- [When not to add feedback](#when-not-to-add-feedback)
- [Pitfalls](#pitfalls)
- [Sources](#sources)

## Order of work

1. Confirm the mechanic emits events the feedback can attach to (on hit, on land, on pickup, on death). If not, add the events first and prove them with the proof step.
2. Assign each event a tier (below).
3. Add the effects of one tier at a time. After each effect, run the game, trigger the event many times, and check three things: it fires, it returns to rest, and input still works during it.
4. Stop when the event reads clearly. More effects past that point reduce clarity.
5. Commit the pass separately from the mechanic.

## Weight by impact

| Tier | Events | Feedback |
|---|---|---|
| Routine | Walking, common pickups, menu moves | None or one quiet cue (a soft sound, a small tween) |
| Light | A jump or landing, a weak hit, a UI click | One or two effects, kept short |
| Medium | A solid hit, a dash, a rare pickup | Three or four effects layered |
| Heavy | A big hit, a death, a boss event, an explosion | Five or more effects layered, each brief |

Define the tiers once as presets and give each event a tier, so intensity stays proportional across the whole game and tuning one preset retunes every event in it.

## Effect menu

| Effect | What it does | Note |
|---|---|---|
| Sound | Confirms the event | Vary pitch a little so repeats do not grate |
| Particles | Show where the impact was | Short-lived, small burst |
| Camera shake | Conveys force | Move the camera or a visual pivot, never the simulated body, or collision and aim drift apart |
| Hit-stop | A brief freeze that sells a hit | Strongest tool, easiest to abuse. Trigger once per impact, not every frame of a held attack |
| Flash | Marks the target as struck | One or two frames |
| Squash and stretch | Gives the target weight | Keep volume roughly constant, scale the sprite or mesh, not the collision shape |
| Tweens with easing | Make appearing, reacting, and settling feel alive | Ease out for reactions, avoid linear motion, kill the previous tween on the same property before starting a new one |
| Knockback or recoil | Shows force on the target | Check it does not push the target through walls |

## Starting values to tune

These are defaults to start from and then tune by playing. They are not rules, and no source gives one correct number. Games choose values per attack.

| Effect | Starting default | Basis |
|---|---|---|
| Camera shake model | Keep a `trauma` value from 0 to 1. Damage adds to it, it decreases linearly over time, and shake strength is trauma squared or cubed | Eiserloh, GDC 2016 slides: "Camera shake is trauma^2 or trauma^3", trauma 0.30, 0.60, 0.90 gives 3%, 22%, 73% shake. In 3D use rotational shake only, and drive shake with smooth noise |
| Shake per event | Add about 0.2 for a light event and about 0.5 for a heavy one, and more only for rare big events | The slides give "+= 0.2 or 0.5" as the example amounts. Tune by play |
| Hit-stop length | About 2 to 4 frames for light hits and 6 to 10 frames for heavy ones at 60 frames per second (roughly 30 to 70 ms light, 100 to 170 ms heavy) | A pixel-art combat guide gives these ranges. Fighting games report 6 frames (Final Fight) and about 14 frames (original Street Fighter II), so a fixed value per game is normal. Treat all of it as a starting range |
| Hit-stop cap | Set a maximum and never exceed it, and make longer freezes follow higher damage | Sakurai's column on hitstop: both sides freeze for the same time, more damage gives longer freeze, and a cap applies |
| Squash and stretch time | Under about 0.15 seconds | Practitioner default, no source |

Hit-stop is usually done by lowering the engine's time scale (or pausing) and restoring it on a timer that ignores time scale. A timer that follows the time scale never fires when the scale is zero. Unity's documentation states that coroutines using `WaitForSeconds` do not run while `timeScale` is zero, so use the real-time variant. Godot's `Engine.time_scale` affects timers and `delta` by default, so check its timer API for the option that ignores it. Guard against overlapping freezes by cancelling or counting the previous one.

## When not to add feedback

- On a placeholder or unproven mechanic.
- On actions the player repeats many times a second. Scale feedback down or rate-limit it.
- When the effects hide what the player needs to see (shake plus flash plus particles over an enemy).
- In precision or puzzle games where readability matters more than punch.

## Pitfalls

- Shaking the body instead of the camera, which desynchronises collision and aim.
- A fresh random offset every frame, which buzzes. Drive shake from smooth noise and a decaying value.
- Exaggeration that never returns to rest (scale or shake that does not settle), so it stops reading as feedback.
- Long freezes or uncancelable animations that block input. Keep them short and let input buffer through.
- No option to reduce shake and flashing for motion-sensitive players.

## Sources

| Source | Used for |
|---|---|
| Eiserloh, "Math for Game Programmers: Juicing Your Cameras With Math", GDC 2016. Slides: http://www.mathforgameprogrammers.com/gdc2016/GDC2016_Eiserloh_Squirrel_JuicingYourCameras.pdf, talk: https://gdcvault.com/play/1023146/Math-for-Game-Programmers-Juicing | The trauma model for shake |
| Sakurai column on hitstop: https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/ | Same freeze for both sides, longer for more damage, capped |
| Hitstop frame figures: https://shane-sicienski.com/blog/blog-post-title-one-55pmn (Final Fight, 6 frames), https://sonichurricane.com/?p=1043 (Street Fighter II, about 14 frames), https://gamineai.com/blog/pixel-art-combat-fx-hitstop-smear-frames-impact-timing-2026 (2 to 4 and 6 to 10 frames at 60 fps) | Rough frame ranges |
| Unity `Time.timeScale`: https://docs.unity3d.com/ScriptReference/Time-timeScale.html | Scaled waits stop at zero |
| Godot `Engine.time_scale`: https://docs.godotengine.org/en/stable/classes/class_engine.html | Time scale affects timers and delta |

# Coordinate Cheatsheet

Quick reference for picking pixel coordinates when annotating screenshots. All values are in image pixels with the origin at the top-left.

## Resolution Multipliers (Retina / High-DPI)

Most browsers and screenshot tools report positions in CSS pixels. The image saved to disk is usually larger by the device-pixel-ratio (DPR). Multiply the CSS value by DPR before passing to the annotator.

| Display | DPR | Apply to CSS coordinates |
|---|---|---|
| Standard 1x display | 1 | x |
| MacBook retina, iPhone | 2 | * 2 |
| iPhone Plus / Pro Max | 3 | * 3 |
| Some Android flagships | 2.5 - 3 | * DPR |

Quick check from the image itself: take the image width in pixels, divide by the expected CSS viewport width (1280 for desktop, 393 for iPhone 14 Pro). The result is the DPR you need to apply.

## Common Viewport-Width Anchors

| Viewport CSS width | Image pixel width (DPR=1) | Image pixel width (DPR=2) |
|---|---|---|
| 360 (mobile small) | 360 | 720 |
| 393 (iPhone 14 Pro) | 393 | 786 |
| 768 (tablet portrait) | 768 | 1536 |
| 1024 (tablet landscape) | 1024 | 2048 |
| 1280 (laptop default) | 1280 | 2560 |
| 1920 (full HD) | 1920 | 3840 |

## Typical Element Heights (Desktop)

A useful sanity check when guessing where a UI element falls vertically on a desktop screenshot:

| Element | Approximate height (px) |
|---|---|
| Browser top bar (chrome) | 80 |
| Cookie banner overlay | 80 - 140 |
| Marketing site hero | 480 - 720 |
| First content section | 300 - 500 |
| Standard button | 36 - 48 |
| Standard text input | 36 - 44 |
| Footer | 220 - 380 |

## Offset Patterns for Arrows and Labels

When marking a target, leave breathing room - putting a label directly on top of the target obscures the thing the reader is supposed to see.

| Mark | Offset from target |
|---|---|
| Arrow tip | 8 - 16 pixels outside the target edge, pointing toward the target |
| Arrow tail | 80 - 150 pixels away from the target, on the side where the label lives |
| Text label | 12 - 24 pixels outside the target edge, on the opposite side from the page edge |
| Numbered step circle | Centered on the target, or 30 - 50 pixels above and to the left |
| Rectangle outline | 8 - 16 pixels of padding outside the target's bounding box |

## Picking Coordinates Without Guessing

Three ways to get coordinates that work the first time:

1. **Browser DevTools - Elements panel**: hover the target in the elements tree. The overlay shows `top` and `left` in CSS pixels. Multiply by DPR for image-pixel coordinates.
2. **macOS Preview**: open the screenshot, hover over the target, watch the bottom status bar for the cursor position in pixels.
3. **Linux + ImageMagick `display`** or **GIMP**: same idea - hover and read the status bar.
4. **Windows + Paint**: hover and read the bottom-left status bar.
5. **A throwaway dry-run mark**: drop a `--rect 0,0,100,100 --rect-color magenta` and binary-search outward until the box lands where you want. Works always, useful when no DevTools is at hand.

## Aligning a Series of Step Markers

For a numbered tutorial with multiple steps on the same screenshot:

- Pick a baseline (a horizontal or vertical line) along which all markers will sit.
- Place each marker the same distance from the target's centre - usually 30 px above and to the left of the click target.
- Increase numbers in reading order (English: left-to-right, top-to-bottom).
- Place the text describing each step near the marker, on the side that does not occlude other targets.

## Coordinate Pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Forgetting the DPR multiplier | Marks land at half their intended position | Multiply CSS pixels by image-pixel-ratio |
| Using float coordinates | Pillow rounds silently; marks drift by 1 px between similar ops | Pass integers |
| Passing negative coordinates | Pillow clips silently | Verify bounds before the call |
| Confusing `(x, y)` with `(y, x)` | Marks land in the wrong axis | First number is horizontal, second is vertical |
| Coordinates referring to the cropped region after `crop` | All subsequent marks shift | If the spec includes `crop`, all later coordinates are relative to the cropped image |

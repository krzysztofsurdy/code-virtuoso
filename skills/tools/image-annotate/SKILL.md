---
name: image-annotate
description: Mark up an existing image with shapes, arrows, text, numbered steps, highlights, blur, or solid redaction. Use this skill whenever the user wants to annotate a screenshot, add arrows or boxes to a picture, write labels on an image, draw numbered callouts for a tutorial, highlight a region, blur faces or backgrounds, redact passwords or API keys before sharing, or compose multiple marks into a single image. Outputs a new PNG/JPEG with the marks burned in. Pairs naturally with the web-screenshot skill - capture first, then annotate.
user-invocable: true
argument-hint: "<input-image> <output-image> [--rect ...] [--arrow ...] [--text ...] [--step ...] [--blur ...] [--redact ...] [--spec FILE.json]"
---

# Image Annotate

Mark up an existing image with shapes, text, numbered steps, blur, or solid-color redaction. Single CLI, one-off flags for simple marks, JSON spec file for compositions. Output is a flat raster image with every mark burned in - the original is never modified in place.

## Core Principles

| Principle | Meaning |
|---|---|
| **Never modify in place** | Always write to a new output file. Annotation is destructive - the user must keep the original to redo or refine later. |
| **Blur is not redaction** | Pixelation and blur can be reversed for text content. For passwords, API keys, SSNs, payment numbers, and other security-critical strings, use solid-color redaction. Blur is acceptable only for casual privacy (faces in marketing shots, peripheral background detail). See `references/redaction-safety.md`. |
| **Marks should read on any background** | Use stroke + fill colors that contrast with the surrounding pixels, or add a contrasting outline to text. Yellow on a yellow page is invisible. The default style stacks a thick coloured stroke over the underlying pixels, never relies on transparency alone. |
| **Coordinate origin is top-left** | All `(x, y)` coordinates start from the top-left corner of the image. Y increases downward. Match the convention to whatever the source tool reports - browser DevTools and most screenshot tools agree on this. |
| **One operation, one purpose** | A single annotation does one thing. To layer marks, repeat flags or use a JSON spec - do not try to overload one operation. |
| **Burn into a flat image** | The output is a single-layer PNG or JPEG. No editable layers, no SVG re-edit path. If the user needs to iterate, they re-run the script with a new spec. |

---

## Quick Start

### Install (one-time, ask user first)

```bash
pip install --user Pillow
```

Pillow is the imaging library. Cross-platform, pure-Python install. Check first:

```bash
python -c "import PIL; print(PIL.__version__)"
```

### Simple one-off: rectangle + arrow + label

```bash
python scripts/annotate.py input.png output.png \
  --rect 100,100,500,300 --rect-color red --rect-width 5 \
  --arrow 600,250,520,200 --arrow-color yellow \
  --text 600,260 "Click this button" --text-color white --text-bg black
```

That produces `output.png` with a red box around the region, a yellow arrow pointing into it, and a labelled callout next to the arrow.

### Composition via JSON spec

For three or more marks, prefer a spec file:

```json
[
  {"op": "rect",   "xy": [100, 100, 500, 300], "color": "red", "width": 5},
  {"op": "arrow",  "from": [600, 250], "to": [520, 200], "color": "yellow"},
  {"op": "text",   "xy": [600, 260], "value": "Click this button", "color": "white", "bg": "black"},
  {"op": "step",   "n": 1, "xy": [150, 150]},
  {"op": "step",   "n": 2, "xy": [350, 250]},
  {"op": "redact", "xy": [50, 600, 400, 640]}
]
```

```bash
python scripts/annotate.py input.png output.png --spec marks.json
```

Operations apply in order - later marks overlay earlier ones.

---

## Operations Reference

### Rectangle - `rect`

Bounding box around an area. Outline only by default (no fill).

| CLI flag | JSON key | Default |
|---|---|---|
| `--rect x1,y1,x2,y2` | `{"op": "rect", "xy": [...]}` | required |
| `--rect-color NAME` | `"color": "red"` | red |
| `--rect-width N` | `"width": 5` | 4 |
| `--rect-fill NAME` | `"fill": null` | none (outline only) |

### Arrow - `arrow`

Line with a triangular arrowhead at the end point. Points from `(x1,y1)` to `(x2,y2)` - the head is at `(x2,y2)`.

| CLI flag | JSON key | Default |
|---|---|---|
| `--arrow x1,y1,x2,y2` | `{"op": "arrow", "from": [...], "to": [...]}` | required |
| `--arrow-color NAME` | `"color": "yellow"` | yellow |
| `--arrow-width N` | `"width": 6` | 6 |
| `--arrow-head N` | `"head": 20` | 20 (pixels, half-width of the head triangle) |

### Text label - `text`

Text with an optional filled background box for legibility on any underlying image. The position is the top-left of the text.

| CLI flag | JSON key | Default |
|---|---|---|
| `--text x,y "STRING"` | `{"op": "text", "xy": [...], "value": "..."}` | required |
| `--text-color NAME` | `"color": "white"` | white |
| `--text-bg NAME` | `"bg": "black"` | black (set `null` for no background box) |
| `--text-size N` | `"size": 24` | 24 |
| `--text-padding N` | `"padding": 8` | 8 |

### Circle / ellipse - `circle`

Outline around a centre point. Useful for highlighting a single UI element.

| CLI flag | JSON key | Default |
|---|---|---|
| `--circle cx,cy,r` | `{"op": "circle", "center": [...], "radius": N}` | required |
| `--circle-color NAME` | `"color": "red"` | red |
| `--circle-width N` | `"width": 4` | 4 |

### Numbered step marker - `step`

A filled coloured circle with a number inside, drawn in the order the user reads the image. Use for sequential tutorials ("first click here, then here, then here").

| CLI flag | JSON key | Default |
|---|---|---|
| `--step N x,y` | `{"op": "step", "n": N, "xy": [...]}` | required |
| `--step-color NAME` | `"color": "red"` | red |
| `--step-radius N` | `"radius": 22` | 22 |
| `--step-text-color NAME` | `"text_color": "white"` | white |

Stack multiple `--step` flags or list multiple `step` ops to enumerate a workflow.

### Highlight - `highlight`

Semi-transparent coloured overlay over a rectangular region. Use to call attention to an area without obscuring its content. Defaults to a translucent yellow, like a marker pen.

| CLI flag | JSON key | Default |
|---|---|---|
| `--highlight x1,y1,x2,y2` | `{"op": "highlight", "xy": [...]}` | required |
| `--highlight-color NAME` | `"color": "yellow"` | yellow |
| `--highlight-alpha N` | `"alpha": 80` | 80 (0-255, lower is more transparent) |

### Blur - `blur`

Gaussian blur over a rectangular region. **Not safe for security-critical content.** Use only for casual privacy (faces, peripheral background detail, non-secret personal info).

| CLI flag | JSON key | Default |
|---|---|---|
| `--blur x1,y1,x2,y2` | `{"op": "blur", "xy": [...]}` | required |
| `--blur-radius N` | `"radius": 16` | 16 |

### Redact - `redact`

Solid-color block over a rectangular region. Use this - not blur - for passwords, API keys, tokens, SSNs, payment numbers, or anything an attacker would reuse.

| CLI flag | JSON key | Default |
|---|---|---|
| `--redact x1,y1,x2,y2` | `{"op": "redact", "xy": [...]}` | required |
| `--redact-color NAME` | `"color": "black"` | black |

### Crop - `crop`

Cut the image to a rectangular region. Applied first if present in the spec.

| CLI flag | JSON key | Default |
|---|---|---|
| `--crop x1,y1,x2,y2` | `{"op": "crop", "xy": [...]}` | required |

---

## Common Recipes

### Bug-report screenshot: box the broken part, label it

```bash
python scripts/annotate.py bug.png bug-annotated.png \
  --rect 320,180,640,260 --rect-color red --rect-width 6 \
  --text 320,140 "Button stays disabled after valid input" --text-bg red
```

### Tutorial: three numbered steps with descriptions

```bash
python scripts/annotate.py tutorial.png tutorial-annotated.png \
  --step 1 180,210 \
  --step 2 420,280 \
  --step 3 660,210 \
  --text 220,210 "Open the file menu" \
  --text 460,280 "Pick Export -> PDF" \
  --text 700,210 "Confirm the location"
```

### Pre-share redaction: hide an API key and a session cookie

```bash
python scripts/annotate.py dashboard.png dashboard-shareable.png \
  --redact 80,420,580,452 \
  --redact 80,490,580,522
```

### Privacy-light: blur a face in a marketing-shot

```bash
python scripts/annotate.py team.png team-anon.png \
  --blur 120,80,260,240 --blur-radius 24
```

(Use redact instead if the face must be unrecognisable in any forensic recovery.)

### Highlight a paragraph in a documentation shot

```bash
python scripts/annotate.py docs.png docs-highlight.png \
  --highlight 60,300,720,420 --highlight-color yellow --highlight-alpha 90
```

---

## Picking Coordinates

The three reliable ways to find an `(x, y)` for a mark:

1. **Browser DevTools elements panel** - hover the element; the highlight shows pixel offsets in the page. Multiply by device-pixel-ratio if the screenshot was retina.
2. **macOS Preview / Linux image-viewer / Windows Paint** - open the screenshot, hover the target; most viewers show coordinates in the status bar.
3. **A first dry run with a colour mark** - drop a `--rect 0,0,100,100` and binary-search outward until the box lands where you want. Wasteful but always works.

The coordinate origin is the **top-left** corner: `x` increases right, `y` increases down. Pillow, browsers, and OS screen-capture tools all agree on this.

See `references/coordinate-cheatsheet.md` for common picks and offsets.

---

## Quick Reference: Checklist

- [ ] Pillow is installed (`python -c "import PIL"`)
- [ ] Input image exists and is readable
- [ ] Output path is **different** from the input - never overwrite the source
- [ ] Coordinates are within the image bounds (Pillow will silently clip otherwise)
- [ ] Colours are CSS-style names (`red`, `yellow`, `#ff8800`) - Pillow accepts both
- [ ] For sensitive data: `redact` not `blur`
- [ ] Final output viewed at full resolution to confirm marks land where intended

---

## Reference Files

| Reference | Contents |
|---|---|
| [redaction-safety](references/redaction-safety.md) | What is safe to blur vs requires solid redaction; recoverability research; common mistakes |
| [coordinate-cheatsheet](references/coordinate-cheatsheet.md) | Coordinate-picking tactics for typical screenshot dimensions; retina/DPR multipliers; offset patterns for arrows and labels |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Need to capture the source image first | `web-screenshot` - capture, copy to host, then run this skill on the host file |
| Generating a step-by-step tutorial | This skill's `step` operation plus the web-screenshot multi-viewport script for paired shots |
| Producing a PR or status report with annotated screenshots | `report-writer` - embed the annotated PNGs into the HTML report |

## Critical Rules

1. **Never overwrite the source image.** The output path must differ from the input path. Re-runs need the original.
2. **Use `redact` for secrets, not `blur`.** Blur is reversible for text content. Passwords, API keys, payment numbers, SSNs, JWT tokens, and anything an attacker could replay must be covered with a solid block.
3. **Coordinates are top-left origin and pixel-based.** Match the resolution of the image, not CSS pixels - if the screenshot is retina (2x), the coordinates are 2x what DevTools shows.
4. **Operations apply in order.** Later marks paint over earlier marks. Put redactions LAST in the spec so nothing in the source leaks through a partially-transparent overlay.
5. **Output format follows the file extension.** `.png` for lossless, `.jpg` for size-constrained. Annotations on a JPEG re-saved as JPEG will accumulate compression artifacts - prefer PNG when iterating.

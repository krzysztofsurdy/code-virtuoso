---
name: image-annotate
description: Mark up an existing image with shapes, arrows, text, numbered steps, highlights, blur, or solid redaction. Use this skill whenever the user wants to annotate a screenshot, add arrows or boxes to a picture, write labels on an image, draw numbered callouts for a tutorial, highlight a region, blur faces or backgrounds, redact passwords or API keys before sharing, or compose multiple marks into a single image. Outputs a new PNG/JPEG with the marks burned in. Pairs naturally with the web-screenshot skill - capture first, then annotate.
user-invocable: true
argument-hint: "<input-image> [<output-image>] [--name PURPOSE] [--rect ...] [--arrow ...] [--text ...] [--step ...] [--blur ...] [--redact ...] [--spec FILE.json]"
---

# Image Annotate

Mark up an existing image with shapes, text, numbered steps, blur, or solid-color redaction. It is a single CLI: one-off flags for simple marks, a JSON spec file for compositions. The output is a flat raster image with every mark burned in, and the original is never modified in place. The output filename always reflects what was done. Pass `--name PURPOSE` to label the artifact by intent, or omit the output path and let the script derive a descriptive name from the operations applied.

## Core Principles

| Principle | Meaning |
|---|---|
| **Never modify in place** | Always write to a new output file. Annotation is destructive, so the user must keep the original to redo or refine later. |
| **Output names describe intent** | Either pass `--name some-purpose` to label the artifact, or omit the output argument and the script derives a name from the ops applied (e.g. `screenshot-rect-arrow-text.png`). Collisions get a `-2`, `-3` suffix, so a repeated run never overwrites an earlier result. |
| **Blur is not redaction** | Pixelation and blur can be reversed for text. For passwords, API keys, SSNs, payment numbers, and other security-critical strings, use solid-color redaction. Blur is acceptable only for casual privacy (faces in marketing shots, peripheral background detail). See `references/redaction-safety.md`. |
| **Marks must read on any background** | Use stroke and fill colors that contrast with the surrounding pixels, or add a contrasting outline to text. Yellow on a yellow page is invisible. The default style stacks a thick colored stroke over the underlying pixels and does not rely on transparency alone. |
| **Coordinate origin is top-left** | All `(x, y)` coordinates start from the top-left corner of the image. Y increases downward. Browser DevTools and most screenshot tools use the same convention. |
| **One operation, one purpose** | A single annotation does one thing. To layer marks, repeat flags or use a JSON spec. Do not overload one operation. |
| **Burn into a flat image** | The output is a single-layer PNG or JPEG. There are no editable layers and no SVG path for re-editing. To iterate, re-run the script with a new spec. |

---

## Quick start

### Install (one-time, ask user first)

```bash
pip install --user Pillow
```

Pillow is the imaging library, installed with pip on any platform. Check first:

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

This produces `output.png` with a red box around the region, a yellow arrow pointing into it, and a labeled callout next to the arrow.

### Composition via JSON spec

For three or more marks, use a spec file:

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

## Operations reference

### Rectangle: `rect`

Bounding box around an area. Outline only by default (no fill).

| CLI flag | JSON key | Default |
|---|---|---|
| `--rect x1,y1,x2,y2` | `{"op": "rect", "xy": [...]}` | required |
| `--rect-color NAME` | `"color": "red"` | red |
| `--rect-width N` | `"width": 5` | 4 |
| `--rect-fill NAME` | `"fill": null` | none (outline only) |

### Arrow: `arrow`

Line with a triangular arrowhead at the end point. It points from `(x1,y1)` to `(x2,y2)`, and the head is at `(x2,y2)`.

| CLI flag | JSON key | Default |
|---|---|---|
| `--arrow x1,y1,x2,y2` | `{"op": "arrow", "from": [...], "to": [...]}` | required |
| `--arrow-color NAME` | `"color": "yellow"` | yellow |
| `--arrow-width N` | `"width": 6` | 6 |
| `--arrow-head N` | `"head": 20` | 20 (pixels, half-width of the head triangle) |

### Text label: `text`

Text with an optional filled background box so it stays legible on any image. The position is the top-left of the text.

| CLI flag | JSON key | Default |
|---|---|---|
| `--text x,y "STRING"` | `{"op": "text", "xy": [...], "value": "..."}` | required |
| `--text-color NAME` | `"color": "white"` | white |
| `--text-bg NAME` | `"bg": "black"` | black (set `null` for no background box) |
| `--text-size N` | `"size": 24` | 24 |
| `--text-padding N` | `"padding": 8` | 8 |

### Circle / ellipse: `circle`

Outline around a center point. Use it to highlight a single UI element.

| CLI flag | JSON key | Default |
|---|---|---|
| `--circle cx,cy,r` | `{"op": "circle", "center": [...], "radius": N}` | required |
| `--circle-color NAME` | `"color": "red"` | red |
| `--circle-width N` | `"width": 4` | 4 |

### Numbered step marker: `step`

A filled colored circle with a number inside, drawn in the order the reader follows. Use it for sequential tutorials ("first click here, then here, then here").

| CLI flag | JSON key | Default |
|---|---|---|
| `--step N x,y` | `{"op": "step", "n": N, "xy": [...]}` | required |
| `--step-color NAME` | `"color": "red"` | red |
| `--step-radius N` | `"radius": 22` | 22 |
| `--step-text-color NAME` | `"text_color": "white"` | white |

Stack multiple `--step` flags or list multiple `step` ops to enumerate a workflow.

### Highlight: `highlight`

Semi-transparent colored overlay over a rectangular region. Use it to draw attention to an area without hiding its content. It defaults to a translucent yellow, like a marker pen.

| CLI flag | JSON key | Default |
|---|---|---|
| `--highlight x1,y1,x2,y2` | `{"op": "highlight", "xy": [...]}` | required |
| `--highlight-color NAME` | `"color": "yellow"` | yellow |
| `--highlight-alpha N` | `"alpha": 80` | 80 (0-255, lower is more transparent) |

### Blur: `blur`

Gaussian blur over a rectangular region. **Not safe for security-critical content.** Use it only for casual privacy (faces, peripheral background detail, non-secret personal info).

| CLI flag | JSON key | Default |
|---|---|---|
| `--blur x1,y1,x2,y2` | `{"op": "blur", "xy": [...]}` | required |
| `--blur-radius N` | `"radius": 16` | 16 |

### Redact: `redact`

Solid-color block over a rectangular region. Use this, not blur, for passwords, API keys, tokens, SSNs, payment numbers, or anything an attacker would reuse.

| CLI flag | JSON key | Default |
|---|---|---|
| `--redact x1,y1,x2,y2` | `{"op": "redact", "xy": [...]}` | required |
| `--redact-color NAME` | `"color": "black"` | black |

### Crop: `crop`

Cut the image to a rectangular region. Applied first if present in the spec.

| CLI flag | JSON key | Default |
|---|---|---|
| `--crop x1,y1,x2,y2` | `{"op": "crop", "xy": [...]}` | required |

---

## Common recipes

### Bug-report screenshot: box the broken part, label it

```bash
python scripts/annotate.py bug.png --name button-stays-disabled \
  --rect 320,180,640,260 --rect-color red --rect-width 6 \
  --text 320,140 "Button stays disabled after valid input" --text-bg red
```

Output: `bug-button-stays-disabled.png`.

### Tutorial: three numbered steps with descriptions

```bash
python scripts/annotate.py tutorial.png --name export-pdf-walkthrough \
  --step 1 180,210 \
  --step 2 420,280 \
  --step 3 660,210 \
  --text 220,210 "Open the file menu" \
  --text 460,280 "Pick Export -> PDF" \
  --text 700,210 "Confirm the location"
```

Output: `tutorial-export-pdf-walkthrough.png`.

### Pre-share redaction: hide an API key and a session cookie

```bash
python scripts/annotate.py dashboard.png --name shareable \
  --redact 80,420,580,452 \
  --redact 80,490,580,522
```

Output: `dashboard-shareable.png`.

### Light privacy: blur a face in a marketing shot

```bash
python scripts/annotate.py team.png --name anon-face \
  --blur 120,80,260,240 --blur-radius 24
```

Output: `team-anon-face.png`. (Use redact instead if the face must stay unrecognizable under forensic recovery.)

### Highlight a paragraph in a documentation shot

```bash
python scripts/annotate.py docs.png --name section-callout \
  --highlight 60,300,720,420 --highlight-color yellow --highlight-alpha 90
```

Output: `docs-section-callout.png`.

---

## Picking coordinates

Three reliable ways to find an `(x, y)` for a mark:

1. **Browser DevTools elements panel**: hover the element. The highlight shows pixel offsets in the page. Multiply by the device-pixel ratio if the screenshot was retina.
2. **macOS Preview, a Linux image viewer, or Windows Paint**: open the screenshot and hover the target. Most viewers show coordinates in the status bar.
3. **A first dry run with a color mark**: draw `--rect 0,0,100,100` and binary-search outward until the box lands where you want. It is slow but always works.

The coordinate origin is the top-left corner: `x` increases right and `y` increases down. Pillow, browsers, and OS screen-capture tools all use this.

See `references/coordinate-cheatsheet.md` for common picks and offsets.

---

## Quick reference: checklist

- [ ] Pillow is installed (`python -c "import PIL"`)
- [ ] Input image exists and is readable
- [ ] Output path is different from the input (never overwrite the source)
- [ ] Coordinates are within the image bounds (Pillow clips silently otherwise)
- [ ] Colors are CSS-style names (`red`, `yellow`, `#ff8800`); Pillow accepts both
- [ ] For sensitive data: `redact` not `blur`
- [ ] Final output viewed at full resolution to confirm the marks land where intended

---

## Reference files

| Reference | Contents |
|---|---|
| [redaction-safety](references/redaction-safety.md) | What is safe to blur and what needs solid redaction; why blur is recoverable; common mistakes |
| [coordinate-cheatsheet](references/coordinate-cheatsheet.md) | Coordinate-picking tactics for typical screenshot dimensions; retina and DPR multipliers; offset patterns for arrows and labels |

---

## Integration with other skills

| Situation | Recommended skill |
|---|---|
| Need to capture the source image first | `web-screenshot`: capture, copy to host, then run this skill on the host file |
| Generating a step-by-step tutorial | This skill's `step` operation plus the web-screenshot multi-viewport script for paired shots |
| Producing a PR or status report with annotated screenshots | `report-writer`: embed the annotated PNGs into the HTML report |

## Critical rules

1. **Never overwrite the source image.** The output path must differ from the input path. Re-runs need the original. The script refuses to write to the input path, and auto-derived names always land in a separate file next to the source.
2. **Always produce a file with a meaningful name.** Either pass `--name PURPOSE` to label the artifact by intent or omit the output positional so the script derives a suffix from the ops applied. Do not deliver an opaque `out.png` when the file could be named for what it shows.
3. **Use `redact` for secrets, not `blur`.** Blur is reversible for text. Cover passwords, API keys, payment numbers, SSNs, JWT tokens, and anything an attacker could replay with a solid block.
4. **Coordinates are top-left origin and pixel-based.** Match the resolution of the image, not CSS pixels. If the screenshot is retina (2x), the coordinates are 2x what DevTools shows.
5. **Operations apply in order.** Later marks paint over earlier marks. Put redactions last in the spec so nothing in the source leaks through a partially transparent overlay.
6. **Output format follows the file extension.** `.png` for lossless, `.jpg` for size-constrained. Annotations on a JPEG re-saved as JPEG accumulate compression artifacts, so prefer PNG when iterating.

#!/usr/bin/env python3
"""Annotate an image with shapes, arrows, text, numbered steps, blur, or redaction.

Two ways to drive it:

    1. CLI flags (best for one or two marks):
        python annotate.py in.png out.png \\
            --rect 100,100,500,300 \\
            --arrow 600,250,520,200 \\
            --text 600,260 "Click here"

    2. JSON spec file (best for three or more marks):
        python annotate.py in.png out.png --spec marks.json

Operations apply in the order they appear (CLI flags first by category, then
spec entries in array order). For overlapping marks, later operations win.

Requires Pillow. Install with `pip install --user Pillow`.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

try:
    from PIL import Image, ImageDraw, ImageFilter, ImageFont
except ImportError:
    sys.stderr.write(
        "Pillow is required. Install with: pip install --user Pillow\n"
    )
    sys.exit(2)


# ---------- Drawing primitives ----------


def _resolve_font(size: int) -> ImageFont.ImageFont:
    """Pick a TrueType font when possible, fall back to the bitmap default."""
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/dejavu/DejaVuSans-Bold.ttf",
        "C:\\Windows\\Fonts\\arial.ttf",
        "C:\\Windows\\Fonts\\segoeui.ttf",
    ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def op_crop(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    x1, y1, x2, y2 = params["xy"]
    return image.crop((x1, y1, x2, y2))


def op_rect(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    draw = ImageDraw.Draw(image)
    draw.rectangle(
        tuple(params["xy"]),
        outline=params.get("color", "red"),
        width=int(params.get("width", 4)),
        fill=params.get("fill"),
    )
    return image


def op_circle(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    cx, cy = params["center"]
    r = int(params["radius"])
    draw = ImageDraw.Draw(image)
    draw.ellipse(
        (cx - r, cy - r, cx + r, cy + r),
        outline=params.get("color", "red"),
        width=int(params.get("width", 4)),
    )
    return image


def op_arrow(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    from math import atan2, cos, sin

    x1, y1 = params["from"]
    x2, y2 = params["to"]
    color = params.get("color", "yellow")
    width = int(params.get("width", 6))
    head = int(params.get("head", 20))

    draw = ImageDraw.Draw(image)

    # Shorten the line so it does not overshoot the arrowhead triangle.
    angle = atan2(y2 - y1, x2 - x1)
    line_end = (x2 - head * 0.6 * cos(angle), y2 - head * 0.6 * sin(angle))
    draw.line([(x1, y1), line_end], fill=color, width=width)

    # Arrowhead triangle perpendicular to the line direction.
    left = (
        x2 - head * cos(angle - 0.5),
        y2 - head * sin(angle - 0.5),
    )
    right = (
        x2 - head * cos(angle + 0.5),
        y2 - head * sin(angle + 0.5),
    )
    draw.polygon([(x2, y2), left, right], fill=color)
    return image


def op_text(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    x, y = params["xy"]
    value = str(params["value"])
    color = params.get("color", "white")
    bg = params.get("bg", "black")
    size = int(params.get("size", 24))
    padding = int(params.get("padding", 8))
    font = _resolve_font(size)

    # Measure the text so the background box wraps tightly.
    draw = ImageDraw.Draw(image)
    bbox = draw.textbbox((x, y), value, font=font)
    if bg:
        draw.rectangle(
            (bbox[0] - padding, bbox[1] - padding, bbox[2] + padding, bbox[3] + padding),
            fill=bg,
        )
    draw.text((x, y), value, fill=color, font=font)
    return image


def op_step(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    cx, cy = params["xy"]
    n = int(params["n"])
    color = params.get("color", "red")
    text_color = params.get("text_color", "white")
    radius = int(params.get("radius", 22))
    size = max(int(radius * 1.1), 18)
    font = _resolve_font(size)

    draw = ImageDraw.Draw(image)
    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        fill=color,
        outline="white",
        width=3,
    )
    label = str(n)
    bbox = draw.textbbox((0, 0), label, font=font)
    text_w = bbox[2] - bbox[0]
    text_h = bbox[3] - bbox[1]
    draw.text(
        (cx - text_w / 2 - bbox[0], cy - text_h / 2 - bbox[1]),
        label,
        fill=text_color,
        font=font,
    )
    return image


def op_highlight(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    x1, y1, x2, y2 = params["xy"]
    color = params.get("color", "yellow")
    alpha = int(params.get("alpha", 80))

    overlay = Image.new("RGBA", image.size, (0, 0, 0, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    rgba = _color_to_rgba(color, alpha)
    overlay_draw.rectangle((x1, y1, x2, y2), fill=rgba)

    base = image.convert("RGBA")
    blended = Image.alpha_composite(base, overlay)
    return blended.convert(image.mode if image.mode != "RGBA" else "RGBA")


def _color_to_rgba(name_or_hex: str, alpha: int) -> tuple[int, int, int, int]:
    from PIL import ImageColor
    rgb = ImageColor.getrgb(name_or_hex)
    if len(rgb) == 4:
        return (rgb[0], rgb[1], rgb[2], alpha)
    return (rgb[0], rgb[1], rgb[2], alpha)


def op_blur(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    x1, y1, x2, y2 = params["xy"]
    radius = int(params.get("radius", 16))
    region = image.crop((x1, y1, x2, y2)).filter(ImageFilter.GaussianBlur(radius))
    image.paste(region, (x1, y1))
    return image


def op_redact(image: Image.Image, params: dict[str, Any]) -> Image.Image:
    draw = ImageDraw.Draw(image)
    draw.rectangle(tuple(params["xy"]), fill=params.get("color", "black"))
    return image


OPS = {
    "crop": op_crop,
    "rect": op_rect,
    "circle": op_circle,
    "arrow": op_arrow,
    "text": op_text,
    "step": op_step,
    "highlight": op_highlight,
    "blur": op_blur,
    "redact": op_redact,
}


# ---------- CLI plumbing ----------


def _parse_tuple(s: str, length: int) -> list[int]:
    parts = [int(p.strip()) for p in s.split(",")]
    if len(parts) != length:
        raise argparse.ArgumentTypeError(
            f"expected {length} comma-separated integers, got {len(parts)}: {s!r}"
        )
    return parts


def _build_operations_from_args(args: argparse.Namespace) -> list[dict[str, Any]]:
    ops: list[dict[str, Any]] = []

    if args.crop:
        ops.append({"op": "crop", "xy": _parse_tuple(args.crop, 4)})

    for raw in args.rect or []:
        ops.append(
            {
                "op": "rect",
                "xy": _parse_tuple(raw, 4),
                "color": args.rect_color,
                "width": args.rect_width,
                "fill": args.rect_fill,
            }
        )

    for raw in args.circle or []:
        cx, cy, r = _parse_tuple(raw, 3)
        ops.append(
            {
                "op": "circle",
                "center": [cx, cy],
                "radius": r,
                "color": args.circle_color,
                "width": args.circle_width,
            }
        )

    for raw in args.arrow or []:
        x1, y1, x2, y2 = _parse_tuple(raw, 4)
        ops.append(
            {
                "op": "arrow",
                "from": [x1, y1],
                "to": [x2, y2],
                "color": args.arrow_color,
                "width": args.arrow_width,
                "head": args.arrow_head,
            }
        )

    for raw_xy, raw_value in args.text or []:
        ops.append(
            {
                "op": "text",
                "xy": _parse_tuple(raw_xy, 2),
                "value": raw_value,
                "color": args.text_color,
                "bg": args.text_bg if args.text_bg.lower() != "none" else None,
                "size": args.text_size,
                "padding": args.text_padding,
            }
        )

    for raw_n, raw_xy in args.step or []:
        ops.append(
            {
                "op": "step",
                "n": int(raw_n),
                "xy": _parse_tuple(raw_xy, 2),
                "color": args.step_color,
                "text_color": args.step_text_color,
                "radius": args.step_radius,
            }
        )

    for raw in args.highlight or []:
        ops.append(
            {
                "op": "highlight",
                "xy": _parse_tuple(raw, 4),
                "color": args.highlight_color,
                "alpha": args.highlight_alpha,
            }
        )

    for raw in args.blur or []:
        ops.append(
            {
                "op": "blur",
                "xy": _parse_tuple(raw, 4),
                "radius": args.blur_radius,
            }
        )

    for raw in args.redact or []:
        ops.append(
            {
                "op": "redact",
                "xy": _parse_tuple(raw, 4),
                "color": args.redact_color,
            }
        )

    return ops


def _load_spec(path: Path) -> list[dict[str, Any]]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        raise ValueError(f"Spec file {path} must contain a JSON array")
    return data


def _slugify(text: str, max_length: int = 48) -> str:
    """Reduce free text to a filesystem-safe kebab-case slug."""
    slug = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    return slug[:max_length].rstrip("-") or "annotated"


def _derive_output_path(
    input_path: Path,
    ops: list[dict[str, Any]],
    name_hint: str | None,
) -> Path:
    """Build a meaningful output path that describes the annotation request.

    Priority:
      1. If --name was given, use it as the descriptive slug.
      2. Otherwise, summarise the distinct operations applied.

    A "-N" counter is appended when the derived path already exists, so a
    second run of the same request produces a new file rather than silently
    overwriting the first.
    """
    stem = input_path.stem
    ext = input_path.suffix or ".png"

    if name_hint:
        suffix = _slugify(name_hint)
    else:
        seen: list[str] = []
        for entry in ops:
            op_name = entry.get("op")
            if op_name and op_name not in seen:
                seen.append(op_name)
        if not seen:
            suffix = "annotated"
        elif len(seen) > 4:
            suffix = "-".join(seen[:3] + [f"plus{len(seen) - 3}more"])
        else:
            suffix = "-".join(seen)

    base = input_path.parent / f"{stem}-{suffix}{ext}"
    if not base.exists():
        return base

    counter = 2
    while True:
        candidate = input_path.parent / f"{stem}-{suffix}-{counter}{ext}"
        if not candidate.exists():
            return candidate
        counter += 1


def apply_operations(image: Image.Image, ops: list[dict[str, Any]]) -> Image.Image:
    for entry in ops:
        op_name = entry.get("op")
        if op_name not in OPS:
            raise ValueError(f"Unknown operation: {op_name!r}")
        image = OPS[op_name](image, entry)
    return image


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="Source image path")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        default=None,
        help=(
            "Output image path. Optional - when omitted, the script derives a "
            "descriptive filename next to the input from --name or from the "
            "operations applied. Must differ from input when explicit."
        ),
    )
    parser.add_argument(
        "--name",
        help=(
            "Short description of the annotation's purpose, used as the slug in "
            "the auto-derived output filename (e.g. 'button-disabled-bug'). "
            "Ignored when an explicit output path is given."
        ),
    )
    parser.add_argument("--spec", type=Path, help="JSON array of operations to apply after CLI ops")

    parser.add_argument("--crop", help="x1,y1,x2,y2")

    parser.add_argument("--rect", action="append", help="x1,y1,x2,y2 (repeatable)")
    parser.add_argument("--rect-color", default="red")
    parser.add_argument("--rect-width", type=int, default=4)
    parser.add_argument("--rect-fill", default=None)

    parser.add_argument("--circle", action="append", help="cx,cy,r (repeatable)")
    parser.add_argument("--circle-color", default="red")
    parser.add_argument("--circle-width", type=int, default=4)

    parser.add_argument("--arrow", action="append", help="x1,y1,x2,y2 from->to (repeatable)")
    parser.add_argument("--arrow-color", default="yellow")
    parser.add_argument("--arrow-width", type=int, default=6)
    parser.add_argument("--arrow-head", type=int, default=20)

    parser.add_argument("--text", action="append", nargs=2, metavar=("XY", "TEXT"))
    parser.add_argument("--text-color", default="white")
    parser.add_argument("--text-bg", default="black", help="background colour or 'none'")
    parser.add_argument("--text-size", type=int, default=24)
    parser.add_argument("--text-padding", type=int, default=8)

    parser.add_argument("--step", action="append", nargs=2, metavar=("N", "XY"))
    parser.add_argument("--step-color", default="red")
    parser.add_argument("--step-text-color", default="white")
    parser.add_argument("--step-radius", type=int, default=22)

    parser.add_argument("--highlight", action="append", help="x1,y1,x2,y2 (repeatable)")
    parser.add_argument("--highlight-color", default="yellow")
    parser.add_argument("--highlight-alpha", type=int, default=80)

    parser.add_argument("--blur", action="append", help="x1,y1,x2,y2 (repeatable)")
    parser.add_argument("--blur-radius", type=int, default=16)

    parser.add_argument("--redact", action="append", help="x1,y1,x2,y2 (repeatable)")
    parser.add_argument("--redact-color", default="black")

    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not args.input.exists():
        sys.stderr.write(f"Input image not found: {args.input}\n")
        return 4

    image = Image.open(args.input)
    if image.mode not in ("RGB", "RGBA"):
        image = image.convert("RGBA")
    else:
        image = image.copy()

    ops = _build_operations_from_args(args)
    if args.spec:
        ops.extend(_load_spec(args.spec))

    if not ops:
        sys.stderr.write("No operations provided. Pass --rect/--arrow/--text/--spec etc.\n")
        return 5

    if args.output is None:
        args.output = _derive_output_path(args.input, ops, args.name)
        sys.stderr.write(f"No output path given - using {args.output}\n")

    if args.input.resolve() == args.output.resolve():
        sys.stderr.write(
            "Refusing to overwrite the source image. Pick a different output path "
            "or let the script auto-derive one (omit the second positional arg).\n"
        )
        return 3

    image = apply_operations(image, ops)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.output)
    print(str(args.output.resolve()))
    return 0


if __name__ == "__main__":
    sys.exit(main())

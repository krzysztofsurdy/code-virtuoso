# shot-scraper options reference

The shot-scraper options that matter when an agent drives the tool, grouped by purpose.

## Contents

- [Viewport and device emulation](#viewport-and-device-emulation)
- [Capture targets](#capture-targets)
- [Output format](#output-format)
- [Page interaction before capture](#page-interaction-before-capture)
- [Browser behaviour](#browser-behaviour)
- [Batch mode](#batch-mode)
- [Color scheme](#color-scheme)
- [Common mistakes](#common-mistakes)

## Viewport and device emulation

| Option | Purpose | Example |
|---|---|---|
| `--width N` | Viewport width in CSS pixels (default 1280) | `--width 1280` |
| `--height N` | Viewport and shot height. Omit it to capture the full page (the default) | `--height 800` |
| `--retina` | Device scale factor of 2. Cannot be combined with `--scale-factor` | `--retina` |
| `--scale-factor N` | Device scale factor, for example `3` for a 3x image. Cannot be combined with `--retina` | `--scale-factor 3` |
| `--user-agent STR` | Override User-Agent string | `--user-agent "Mozilla/5.0 (iPhone...)"` |
| `--reduced-motion` | Sets `prefers-reduced-motion: reduce` | (no value) |

### Standard viewport sizes

| Device class | Width | Height | Notes |
|---|---|---|---|
| Desktop (1080p) | 1920 | 1080 | Common QA size |
| Desktop (laptop) | 1280 | 800 | 1280 is the shot-scraper default width |
| Tablet portrait | 768 | 1024 | iPad mini |
| Tablet landscape | 1024 | 768 | - |
| Mobile (modern) | 393 | 852 | iPhone 14 Pro CSS pixels |
| Mobile (small) | 375 | 667 | iPhone SE CSS pixels |

## Capture targets

| Option | Purpose | Example |
|---|---|---|
| `--selector CSS` | Capture the first element matching the CSS selector. Repeat the option to cover several elements in one shot | `--selector ".hero-section"` |
| `--selector-all CSS` | Capture a rectangle around every element matching the selector | `--selector-all ".card"` |
| `--padding N` | Pixels of padding around an element capture | `--padding 16` |
| (full page) | Omit `--height` to capture from the top of the document to the bottom | (no option) |

## Output format

| Option | Purpose | Example |
|---|---|---|
| `-o PATH` | Output file path. Extension determines format. | `-o out.png` |
| `--format png\|jpeg\|webp` | Image format, overriding the file extension | `--format webp` |
| `--quality N` | JPEG or WebP quality (WebP is lossless without it). Not valid with PNG | `--quality 80` |
| `--omit-background` | Transparent background (PNG only) | (no value) |

PNG vs JPEG quick rule: PNG for UI (sharp text, transparency). JPEG for photographic content or when file size matters.

## Page interaction before capture

| Option | Purpose | Example |
|---|---|---|
| `--javascript "JS"` | Execute JS in the page before capture | `--javascript "document.querySelector('.banner').remove();"` |
| `--js-file FILE` | Execute JS loaded from a file (`-` for stdin) | `--js-file remove-clutter.js` |
| `--wait MS` | Wait fixed milliseconds before capture | `--wait 1500` |
| `--wait-for "JS"` | Wait until the JS expression returns truthy | `--wait-for "document.fonts.ready"` |
| `--auth-username STR` | HTTP Basic Auth username | `--auth-username admin` |
| `--auth-password STR` | HTTP Basic Auth password | `--auth-password secret` |
| `--auth FILE` | JSON authentication context (cookies and storage) saved by `shot-scraper auth` | `--auth auth.json` |

## Browser behaviour

| Option | Purpose | Example |
|---|---|---|
| `--browser NAME` | Pick browser: `chromium`, `firefox`, `webkit`, `chrome`, `chrome-beta` | `--browser firefox` |
| `--timeout MS` | Milliseconds to wait before failing | `--timeout 60000` |
| `--bypass-csp` | Bypass Content-Security-Policy (lets injected JS run anywhere) | (no value) |
| `--silent` | Do not output any messages | (no value) |

## Batch mode

`shot-scraper multi FILE.yaml` reads a YAML array where each entry mirrors the single-shot CLI options:

```yaml
- url: https://example.com
  output: example.png
  width: 1280
  height: 800
  wait_for: "document.fonts.ready"

- url: https://example.com/pricing
  output: pricing-hero.png
  selector: ".pricing-hero"
  padding: 16

- url: https://example.com/docs
  output: docs-full.png
  javascript: |
    document.querySelector('.cookie-banner')?.remove();
```

Snake_case in YAML maps to the hyphen-flag in the CLI (`wait_for` -> `--wait-for`, `js_file` -> `--js-file`). Omit `height` for a full-page shot. Settings that apply to the whole run, such as `--retina`, `--scale-factor`, `--reduced-motion`, `--timeout`, and `--browser`, are flags on the `multi` command, not YAML keys: `shot-scraper multi shots.yaml --retina --reduced-motion`.

## Color scheme

shot-scraper has no top-level `--dark` flag. Two workarounds:

### 1. Force `color-scheme` via JS

```bash
--javascript "document.documentElement.style.colorScheme = 'dark';"
```

Works on sites that read `color-scheme` and adjust their styles.

### 2. Emulate the media query (Playwright API)

For sites that use `@media (prefers-color-scheme: dark)`, escalate to raw Playwright:

```python
context = browser.new_context(color_scheme="dark")
```

## Common mistakes

| Mistake | Symptom | Fix |
|---|---|---|
| Forgot `shot-scraper install` | "Browser executable not found" | Run `shot-scraper install` once |
| Using `networkidle` wait | Hangs forever on pages with analytics | Wait on a selector or document.fonts.ready |
| Full-page on a sticky-header site | Header repeats down the page | Capture viewport-only or remove the sticky header via `--javascript` |
| No `--reduced-motion` on a comparison shot | Pixel diffs flake on every run | Add `--reduced-motion` and wait on `document.fonts.ready` |
| JPEG without `--quality` | File is huge or weirdly compressed | Add `--quality 80` for documentation-grade JPEG |
| Selector matches multiple elements | `--selector` captures only the first, with no warning | Make the selector specific (`#id`, not `.class`) or use `--selector-all` |

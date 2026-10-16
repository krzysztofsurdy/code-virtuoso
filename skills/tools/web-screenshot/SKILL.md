---
name: web-screenshot
description: Captures web page screenshots with shot-scraper (a Playwright-backed CLI), including full-page, element, mobile, dark mode, and batched captures. Use when asked to screenshot a URL or element, or to produce PNG or JPEG output from a web page.
user-invocable: true
argument-hint: "<url-or-batch-yaml> [--full-page] [--selector CSS] [--output PATH] [--width N] [--height N] [--retina] [--dark]"
---

# Web Screenshot

Take reliable screenshots of web pages. Pick the lightest tool that does the job, and never install dependencies the environment did not ask for.

## Tool selection cascade

Two cascades apply: one for picking the **capture tool**, one for **escalating around a bot wall**. They are separate decisions.

### Cascade A: picking the capture tool (no bot wall in sight)

Before any capture, check what is available in the environment and pick the lightest viable tool:

| # | Tool | Detect with | Best for | Limits |
|---|---|---|---|---|
| 1 | **Browser MCP** (e.g. `mcp__*__browser_take_screenshot`) | Already loaded in this session - check the MCP tool list | Single ad-hoc shot, no install, full-page and element shots, navigation flows | Runs in docker with datacenter IP - bot walls block this; output path is inside the MCP container |
| 2 | **shot-scraper** (CLI) | `which shot-scraper` | Repeated captures, batch YAML, scripted automation, CI jobs | Headless by default - some bot walls fire only on headless; requires `pip install shot-scraper && shot-scraper install` once |
| 3 | **Playwright** (Python or Node) | `python -c "import playwright" 2>/dev/null` | Multi-step flows, headed mode with stealth, anti-bot escalation (see Cascade B Tier 1) | Library-level; more code per shot |
| 4 | **Ask user before installing** | None of the above present | Long-term tooling decisions | Never install silently |

### Cascade B: escalating around a bot wall

When Cascade A's pick gets blocked (status 403/429/503 or a CAPTCHA/block page), do not retry the same tool with new flags. Escalate through the tiers in order. **Every tier aims at live content.** Archived snapshots are not an acceptable fallback: they show stale content with a third-party frame around it.

| # | Tier | What it does | When to pick it |
|---|---|---|---|
| 1 | **Playwright headed + stealth** | Local headed Chromium, stealth-patched, user's home IP | First escalation; user can install Playwright |
| 2 | **CDP attach to user's Chrome** | Use the user's actual running Chrome via `--remote-debugging-port` | User can relaunch Chrome with a debug flag; reuses their real session |
| 3 | **System-native browser + OS screen capture** | Open URL in the user's default browser, capture via the OS's built-in screenshot command | Last resort - no extra install, but brittle, steals focus, depends on OS permissions |

**Critical rule: never `pip install` or `brew install` without asking first.** Same rule for installing browser binaries (`playwright install chromium`, `shot-scraper install`). If a tool is missing, surface what is missing and which install fixes it; let the user decide.

[shot-scraper](https://github.com/simonw/shot-scraper) is the preferred install when long-term capture tooling is needed. It is a Playwright-backed CLI with sensible defaults for the common cases. Playwright itself is the preferred install when bot-wall escalation is likely.

## Core Principles

| Principle | Meaning |
|---|---|
| **Default to shot-scraper** | One install, one command per shot. Move to Playwright only when shot-scraper hits a wall. |
| **Wait on something real** | Wait for an element, a function, or a fixed delay. Never `networkidle`; Playwright's own docs discourage it. |
| **Element beats full page** | A selector shot is smaller, more stable, and faster to diff than a stitched full-page capture. Use full-page only when layout is the subject. |
| **Disable animations** | CSS animations are the top source of flaky shots. Pass options that freeze them for any shot that will be compared or reused. |
| **Match the device** | Mobile and desktop layouts differ a lot. Set viewport width and height explicitly when the user cares about a specific form factor. |
| **Output is a file path** | Every shot lands at a known absolute path the caller can hand to the next step (framing, OCR, diffing). |

---

## Quick start

### Path A: Browser MCP is in-session (zero install)

Use the MCP browser tools directly, with no pip install or Chromium download. Tool names vary by MCP host: look for `*browser_navigate` and `*browser_take_screenshot`.

```
1. Call browser_navigate with url=https://example.com
2. (Optional) browser_resize for a specific viewport
3. (Optional) browser_wait_for to gate on a visible text
4. Call browser_take_screenshot with type=png, fullPage=true|false
5. Always copy the resulting file out of the MCP container to the host.
```

The MCP host returns the image inline and saves it to a path like `../tmp/playwright-output/page-<timestamp>.png`, but that path is inside the docker container, not on the host filesystem. Without the copy step, the user has no file to open, attach, edit, or version-control. The inline image alone is not the deliverable.

Use the bundled helper:

```bash
./scripts/copy_mcp_capture_to_host.sh \
  /tmp/playwright-output/page-<timestamp>.png \
  ~/Desktop/screenshots/<descriptive-name>.png
```

The script finds the running MCP browser container by the `docker-mcp-name=playwright` label, normalises the `../tmp/...` paths the MCP returns, and runs `docker cp` to land the file on the host. On success it prints the final absolute host path, which is the deliverable the user opens.

### Path B: shot-scraper is installed

```bash
shot-scraper https://example.com -o example.png
```

Defaults: viewport-only (1280x780), waits for `load`, saves PNG.

### Path C: Nothing is installed

Ask first, install second:

```bash
# After explicit user OK:
pip install shot-scraper
shot-scraper install         # downloads Chromium (~150 MB)
shot-scraper --version       # verify
```

Without the `shot-scraper install` step, every capture fails with a browser-missing error.

### Path D: anti-bot blocks the shot

Bot-detection vendors (Cloudflare, Akamai, PerimeterX, DataDome, and many in-house systems) serve a block page instead of the real content when they detect automation. The block usually rests on three signals:

1. **UA string** containing `HeadlessChrome` or `Playwright`
2. **`navigator.webdriver === true`** (most modern MCP browsers patch this to `false`)
3. **Datacenter IP reputation** - cloud-VM IP ranges are pre-flagged

#### Detecting a block (any URL)

After loading any URL, check for these markers before treating the screenshot as the real page:

| Signal | Indicates block |
|---|---|
| HTTP status 403, 429, 503 | Server-side refusal |
| `<title>` contains `Access Denied`, `Blocked`, `Forbidden`, `Just a moment`, `Attention Required`, `Robot Check` | Bot wall |
| Page body contains `you have been blocked`, `cloudflare`, `please verify you are human`, `unusual traffic` | Bot wall |
| Page renders an iframe with `challenges.cloudflare.com` or `geo.captcha-delivery.com` | Active challenge |
| Body word count under ~50 on what should be a content-rich page | Likely block page |

If any of these is true, treat the page as blocked and walk the escalation tiers before declaring success.

#### Escalation tiers (in order)

Every tier aims at the live content. If one tier is not viable, move to the next. Never settle for an archive.

#### Tier 1: Playwright headed + stealth (recommended)

The most reproducible real-user path. Works on macOS, Linux, and Windows. Needs a one-time install with user approval.

```bash
# One-time install (ask user first):
pipx install playwright          # or: pip install --user playwright
playwright install chromium       # download the browser binary

# Stealth plugin to mask remaining automation signals:
pipx inject playwright tf-playwright-stealth
```

Then use the bundled `scripts/capture_with_stealth.py` helper. It launches Chromium **headed** (not headless), applies stealth patches that hide `navigator.webdriver`, browser plugins, language list, and `chrome.runtime`, and saves the screenshot. The browser uses the user's home IP, which passes the datacenter-IP check behind most refusals.

Why this is Tier 1: it is portable, scripted, needs no user interaction during capture, and uses the user's normal network.

#### Tier 2: connect to the user's running Chrome via CDP

When the user already has Chrome open with their real profile (cookies, extensions, logged-in sessions), a CDP attach reuses that browser. The bot wall sees the user's actual Chrome, with the same fingerprint, cookies, and IP, and there is no second browser process or profile.

Setup (one-time, user relaunches Chrome with the flag):

```
macOS:    /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
Linux:    google-chrome --remote-debugging-port=9222
Windows:  "C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```

Pick one of two attach paths:

**Path 2a: dedicated CLI (preferred when `npm` is available):**

The `agent-browser` package wraps the CDP attach pattern. It auto-discovers any Chrome running with a debug port, gives named element refs from the accessibility tree, and offers many commands (snapshot, click, fill, screenshot, eval, get-box). Install once:

```bash
npm install -g agent-browser
```

Then any command works against the user's live Chrome:

```bash
agent-browser --auto-connect open https://example.com
agent-browser --auto-connect screenshot out.png
agent-browser --auto-connect screenshot --selector "article" cropped.png
```

`--auto-connect` finds the running Chrome without a hard-coded port. Use it when one tool needs to navigate, locate elements, and capture in a single workflow.

**Path 2b: bundled Python script (fallback when `npm` is not available):**

```bash
python scripts/connect_to_running_chrome.py https://example.com out.png
```

Same CDP attach, fewer commands. Use it when `npm` cannot be installed in the environment.

Why Tier 2 and not Tier 1: it needs the user to relaunch Chrome with a debug flag, and a Chrome running with `--remote-debugging-port` open is a mild local security risk if untrusted processes share the machine.

#### Tier 3: system-native browser plus OS screen capture

When neither Playwright nor a CDP-debug Chrome is an option, fall back to the OS's own tools. This tier needs nothing the system does not ship with, but it is brittle, steals focus, and the shot includes whatever the user's screen shows (browser chrome, bookmarks bar, possibly other windows).

The bundled `scripts/capture_via_system_browser.sh` dispatches by platform:

| Platform | Open URL | Capture |
|---|---|---|
| macOS | `osascript` -> Google Chrome new tab; reads window bounds | `screencapture -R<x,y,w,h> out.png` |
| Linux (X11) | `xdg-open <URL>` or `google-chrome <URL>` | `import -window root out.png` (ImageMagick) / `scrot` / `gnome-screenshot -f out.png` |
| Linux (Wayland) | `xdg-open <URL>` | `grim out.png` |
| Windows | PowerShell `Start-Process chrome <URL>` | PowerShell `Add-Type System.Drawing` screen-capture |

Permissions:

- **macOS** prompts for "Allow Terminal to control Google Chrome" (Automation) the first time, and refuses `screencapture` until the calling terminal has Screen Recording permission. The script reports the missing permission instead of failing silently.
- **Linux** needs a capture tool installed (`grim`, ImageMagick, `scrot`, or `gnome-screenshot`); the script picks the first one it finds.
- **Windows** uses only PowerShell built-ins, so no extra install is needed, but the calling user must allow the script to invoke `Start-Process`.

Why Tier 3 is the last resort: it depends on the user's current screen state, needs OS-level permissions that may require a one-time grant, and the capture may include UI chrome the user has to crop manually. Use it only when Tiers 1 and 2 cannot run.

**Out of scope. Do not apply these automatically; surface them to the user:**

| Strategy | Why not to apply it automatically |
|---|---|
| **Residential proxy** | Costs money and routes traffic through someone else's IP, so it needs explicit approval and a legitimate use case |
| **CAPTCHA-solving service** | Defeats a security control the site put there on purpose. Report back; do not work around it silently |
| **Stealth + scraping protected content** | A wall that can be bypassed is not permission to bypass it. Check the site's terms before pushing past explicit refusals |

#### Report what was captured

A captured block page is a real result, not a tool failure. After any escalation, tell the user:

1. Which tier produced the final screenshot
2. Which URL was actually loaded (in case it was a deep-link rather than the root)
3. Whether the frame contains incidental chrome (browser toolbars in Tier 3, cookie banners that were not stripped, and so on)

---

## Capture modes

| Mode | Command | When to use |
|---|---|---|
| **Viewport** | `shot-scraper URL -o out.png --width 1280 --height 800` | Hero shots, above-the-fold, social cards |
| **Full page** | `shot-scraper URL -o out.png` (omit `--height`; a full-page shot is the default) | Long landing pages, articles, full-doc captures |
| **Element** | `shot-scraper URL -o out.png --selector "main .hero"` | Specific component, isolated UI, design-system docs |
| **Multiple selectors** | `--selector "header" --selector "footer"` (one shot covering the smallest area that contains every match) | Multi-region capture in one run |
| **Every matching element** | `--selector-all ".card"` | Rectangle around all elements that match a selector |
| **JPEG (smaller)** | `-o out.jpg --quality 80` | Documentation, social previews, anywhere PNG is overkill |
| **Retina (2x)** | `--retina` | High-DPI displays, marketing assets |

**Full-page caveat**: pages with `position: sticky` headers may render duplicate bands in WebKit/Firefox full-page mode. Test before committing to a full-page shot. If sticky headers misbehave, prefer viewport shots with scroll-and-stitch via custom JS.

---

## Wait strategies

Playwright and shot-scraper wait for the `load` event by default, which is enough for static pages. For dynamic content, add further waits.

| Strategy | Flag | When |
|---|---|---|
| **Wait for selector** | `--wait-for "document.querySelector('.loaded')"` | Wait until a DOM marker appears |
| **Wait fixed time** | `--wait 2000` (ms) | Last resort for "just give it 2 seconds" cases |
| **Custom JS readiness** | `--wait-for "window.__myAppReady === true"` | App sets a global when ready |
| **Run custom JavaScript** | `--javascript "JS"` or `--js-file FILE` | Remove banners or scroll before the shot (runs after `load`) |

**Do not use `networkidle`.** The Playwright team [discourages it](https://playwright.dev/docs/api/class-page#page-wait-for-load-state): pages with analytics pings or long-poll connections never settle. Wait for something deterministic instead.

See `references/wait-strategies.md` for SPA route changes, image-decode waits, and font-load waits.

---

## Stability tips

For any shot you want to compare across runs or reuse in docs:

```bash
shot-scraper https://example.com -o out.png \
  --reduced-motion \
  --wait-for "document.fonts.ready"
```

| Option | What it does |
|---|---|
| `--reduced-motion` | Sets `prefers-reduced-motion: reduce`, freezes most CSS animations |
| `document.fonts.ready` | Waits for web fonts to finish loading, which prevents text-shift artifacts |
| `--javascript "JS"` | Run custom JS that removes cookie banners or chat widgets before the shot |

Hide a cookie banner before capturing:

```bash
shot-scraper https://example.com -o out.png \
  --javascript "document.querySelector('#cookie-banner')?.remove();"
```

---

## Common recipes

### Mobile shot (iPhone 14 Pro viewport)

```bash
shot-scraper https://example.com -o mobile.png \
  --width 393 --height 852 \
  --user-agent "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)"
```

### Dark mode

```bash
shot-scraper https://example.com -o dark.png \
  --javascript "document.documentElement.style.colorScheme = 'dark';"
```

For sites that respect `prefers-color-scheme`, shot-scraper has no color-scheme option. Emulate the media query with Playwright's `color_scheme="dark"` context option. See `references/options.md`.

### Mobile + desktop pair (for a comparison page)

```bash
shot-scraper https://example.com -o desktop.png --width 1280 --height 800
shot-scraper https://example.com -o mobile.png --width 393 --height 852
```

### Batch capture from YAML

Create `shots.yaml`:

```yaml
- url: https://example.com
  output: example.png
  width: 1280
  height: 800
- url: https://news.ycombinator.com
  output: hn.png
  selector: ".athing:first-child"
```

Run:

```bash
shot-scraper multi shots.yaml
```

Use batch mode for nightly captures, doc-site galleries, or capturing many components at once.

### Element shot with scroll

```bash
shot-scraper https://example.com -o feature.png \
  --selector "#features" \
  --javascript "document.querySelector('#features').scrollIntoView({block:'start'});"
```

---

## When to move to raw Playwright

shot-scraper covers about 90% of cases. Use raw Playwright when the flow needs:

| Need | Why shot-scraper falls short |
|---|---|
| **Multi-step navigation** (login -> dashboard -> screenshot) | shot-scraper is single-page-shot oriented |
| **Form interaction before shot** | Cannot fill complex multi-step forms |
| **Multiple shots from one session** | Each shot-scraper call boots a fresh browser |
| **Visual regression suite** | Use `@playwright/test` with built-in `toHaveScreenshot()` matcher |
| **Auth via OAuth flows** | Multi-redirect auth is awkward in single-command CLI |

Minimal Playwright Python fallback:

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page(viewport={"width": 1280, "height": 800})
    page.goto("https://example.com")
    page.fill("#email", "user@example.com")
    page.click("button[type=submit]")
    page.wait_for_selector(".dashboard")
    page.screenshot(path="dashboard.png", animations="disabled")
    browser.close()
```

Install: `pip install playwright && playwright install chromium`.

---

## Helper scripts

Five bundled helpers, in cascade order.

| Script | Role in cascade | Install needed | Platforms |
|---|---|---|---|
| `scripts/copy_mcp_capture_to_host.sh` | **Post-step for Path A**: copies MCP container files to the host. Required on every MCP capture. | `docker` CLI | All (where Docker runs) |
| `scripts/capture_with_stealth.py` | **Tier 1** anti-bot fallback: Playwright headed + stealth | Playwright | macOS, Linux, Windows |
| `scripts/connect_to_running_chrome.py` | **Tier 2** anti-bot fallback: attach to user's running Chrome via CDP | Playwright (no browser download) | macOS, Linux, Windows |
| `scripts/capture_via_system_browser.sh` | **Tier 3** anti-bot fallback: system-native browser + OS screen capture | None (OS built-ins) | macOS, Linux, Windows |
| `scripts/multi_viewport.py` | Multi-device convenience wrapper | shot-scraper | All |

### Choosing a helper

```
Was the headless capture blocked or refused?
   |
   No -> done. Save the shot. Copy to host if it lives inside a container.
   |
   Yes -> escalate to Tier 1 (capture_with_stealth.py).
       Playwright installable (with user OK)?
          Yes -> install, run Tier 1.
          No  -> escalate to Tier 2 (connect_to_running_chrome.py or agent-browser).
              User can relaunch Chrome with --remote-debugging-port?
                 Yes -> Tier 2.
                 No  -> escalate to Tier 3 (capture_via_system_browser.sh).
                     OS permissions in place (Screen Recording on macOS,
                     a capture tool installed on Linux, etc.)?
                        Yes -> Tier 3.
                        No  -> stop and report. Do not silently work around explicit refusals.
```

### Examples

Capture a live page that requires a real-user fingerprint (Tier 1):

```bash
python scripts/capture_with_stealth.py https://example.com out.png \
  --width 1280 --height 800 --wait-for "document.fonts.ready"
```

Capture using the user's existing Chrome session (Tier 2):

```bash
# Once, in another terminal:
google-chrome --remote-debugging-port=9222

# Then:
python scripts/connect_to_running_chrome.py https://example.com out.png
```

Last-resort system-native capture (Tier 3, no extra install):

```bash
./scripts/capture_via_system_browser.sh https://example.com out.png --wait 8
```

Multi-device capture (no anti-bot needs):

```bash
python scripts/multi_viewport.py https://example.com --out screenshots/
```

---

## Quick Reference: Checklist

- [ ] **Preflight the URL with a text fetch first.** A quick `WebFetch` or `curl` confirms the URL returns real content (status 200, expected title, body word count). Opening a browser only to land on a 404 or a wrong redirect wastes a session and steals user focus.
- [ ] `shot-scraper install` has been run on this machine (if using shot-scraper)
- [ ] URL is reachable (no auth wall, no geoblock)
- [ ] Viewport size matches the target device or use case
- [ ] Output path is absolute and the directory exists
- [ ] Wait strategy targets a real DOM marker, not `networkidle`
- [ ] Animations are reduced for stable shots (`--reduced-motion`)
- [ ] Cookie banners and chat widgets removed via `--javascript`
- [ ] Full-page sticky-header issue checked when capturing full page
- [ ] Final file size acceptable (use JPEG + `--quality` for big captures)
- [ ] If capturing a specific region, the selector survived the verification routine in `references/platform-selectors.md`
- [ ] **Final file is on the host filesystem and the absolute path is reported.** A screenshot is not done while it exists only inside a docker container or remote sandbox.

---

## Reference Files

| Reference | Contents |
|---|---|
| [options](references/options.md) | Full shot-scraper option reference: viewport, device emulation, headers, auth, media queries, JS injection, output formats |
| [wait-strategies](references/wait-strategies.md) | Waiting patterns: SPA route changes, font readiness, image decode, custom readiness signals, debugging slow-loading pages |
| [platform-selectors](references/platform-selectors.md) | CSS selectors by content type and platform (articles, social posts, comments, code, video, products); verification routine; shadow-DOM tactics |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Apply frames, annotations, or compositing to the captured image | `image-annotate` |
| Diff screenshots across runs for visual regression | `testing` knowledge skill (component vs page strategy) |
| Capture as part of an end-to-end test suite | Use `@playwright/test` directly; this skill is for ad-hoc captures |
| Accessibility audit of the captured page | `accessibility` knowledge skill |

## Critical rules

1. **Every capture must land on the host filesystem, not inside a container.** Browser MCP servers run in docker and save inside the container, so the inline image alone is not a deliverable. Always end an MCP-based capture with `scripts/copy_mcp_capture_to_host.sh` (or an equivalent `docker cp`) so the user has a real file they can open, attach, edit, or commit. Local tools (shot-scraper, Playwright) already write to the host; the rule applies to any tool that writes inside a container or remote sandbox.
2. **Two cascades, not one.** Cascade A picks the capture tool. Cascade B escalates around bot walls.
3. **Never install dependencies silently.** That includes `pip install`, `brew install`, `playwright install chromium`, and `shot-scraper install`. Each needs explicit user approval. Surface what is missing and let the user decide.
4. **`shot-scraper install` runs once per machine** before any shot-scraper capture - the browser is not bundled with the pip package. The same applies to `playwright install chromium`.
5. **Never wait on `networkidle`.** It never finishes on pages with persistent connections. Wait on a selector, function, or fixed delay.
6. **Output paths must be absolute and on the host.** Report the final host path with every capture. When the path is inside a container, copy out before reporting (see Rule 1).
7. **Strip dynamic UI** (cookie banners, chat bubbles, ad slots) before any shot that will be reused or compared.
8. **For visual regression, escalate to Playwright's test runner** - shot-scraper is for ad-hoc captures, not pixel-diff suites.
9. **An anti-bot block page is a valid result.** Capture it, name it for what it is, and let the user decide whether to escalate. Do not silently retry with evasion tactics on sites that explicitly refuse automation, and never substitute archived content to make a capture succeed.
10. **No archive substitutions.** Wayback Machine, archive.today, and similar mirrors serve stale content with someone else's UI wrapped around it. They are not a fallback for live content. If the live site refuses, escalate through Tiers 1-3; do not switch to an archive.

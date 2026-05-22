# Wait Strategies for Reliable Screenshots

The wrong wait strategy is the single biggest cause of flaky screenshots. This file collects the patterns that work and the ones that look right but fail.

## The Hierarchy

Pick the most specific wait you can. From best to worst:

1. **Wait for an explicit readiness signal** the app provides (`window.__ready = true`)
2. **Wait for a DOM marker** that only appears when content is rendered
3. **Wait for browser primitives** like `document.fonts.ready` or `document.images`
4. **Wait a fixed time** as a last resort
5. ~~**Wait for network idle**~~ - never, see below

## Why `networkidle` Is a Trap

Playwright's own documentation discourages `waitForLoadState('networkidle')` because:

- Analytics pings (GA, Mixpanel, Segment) trickle out indefinitely
- WebSocket connections never idle
- Long-poll endpoints never idle
- Service workers keep the network busy in background

The result is either a 30-second hang or, worse, a flaky timeout that succeeds 80% of the time.

shot-scraper does not expose a `--networkidle` flag for this reason. Do not try to emulate it.

## Wait Patterns That Work

### Pattern 1: App Sets a Readiness Global

Best when you control the app. Add this at the end of bootstrap:

```javascript
window.__appReady = true;
```

Then capture with:

```bash
shot-scraper https://app.example.com -o app.png \
  --wait-for "window.__appReady === true"
```

### Pattern 2: Wait for a Specific DOM Marker

Best when you don't control the app but know what "loaded" looks like:

```bash
shot-scraper https://example.com/dashboard -o dash.png \
  --wait-for "document.querySelector('[data-loaded=\"true\"]') !== null"
```

Or wait for content count to stabilise:

```bash
--wait-for "document.querySelectorAll('.item').length >= 10"
```

### Pattern 3: Wait for Fonts to Load

Fonts loading late causes text reflow that ruins comparisons:

```bash
--wait-for "document.fonts.ready"
```

The `document.fonts.ready` promise resolves once all CSS fonts have loaded or failed.

### Pattern 4: Wait for Images to Decode

For pages with above-the-fold imagery:

```bash
--wait-for "Promise.all(Array.from(document.images).map(img => img.complete ? Promise.resolve() : new Promise(r => img.addEventListener('load', r, { once: true }))))"
```

This is verbose; consider wrapping in a script file:

```bash
--javascript-file scripts/wait-for-images.js
```

### Pattern 5: SPA Route Change

Single-page apps don't fire `load` on route changes. Wait for the route-specific marker:

```bash
shot-scraper "https://spa.example.com/#/pricing" -o pricing.png \
  --wait-for "location.hash === '#/pricing' && document.querySelector('.pricing-hero')"
```

### Pattern 6: Fixed Delay (Last Resort)

Sometimes you need to give a page X seconds to "settle" because nothing else works:

```bash
--wait 2000
```

Use this only for one-off captures. For anything reused, replace with a deterministic wait.

## Combining Waits

shot-scraper applies waits in order: first `--wait` (fixed), then `--wait-for` (JS expression). Use both when you need to give the app time to mount AND wait for a marker:

```bash
shot-scraper https://example.com -o out.png \
  --wait 500 \
  --wait-for "document.fonts.ready && document.querySelector('.hero')"
```

## Debugging a Slow or Hanging Capture

If a capture times out:

1. **Run with `--silent false`** to see all log output
2. **Open the URL in a real browser** with DevTools - what loads when?
3. **Check for analytics or chat widgets** that might create persistent connections (kill them with `--javascript "document.querySelector('#intercom').remove();"`)
4. **Try `--javascript-disable`** to see if JS is the problem - if the static HTML captures fine, the issue is JS-driven
5. **Reduce the wait condition** to something simpler. Start with `document.fonts.ready` and add specificity from there.

## Timeout Handling

shot-scraper's default timeout is generous but not infinite. To bump it:

```bash
--timeout 60000     # 60 seconds
```

If you find yourself raising the timeout, the real fix is usually a better wait condition.

## Anti-Patterns

| Anti-pattern | Why it's bad |
|---|---|
| `--wait 10000` "to be safe" | Wastes 10 seconds on every shot, still flakes on slow days |
| Polling with `setInterval` inside `--wait-for` | shot-scraper re-evaluates the expression; the polling does nothing |
| Combining `--javascript-disable` with `--wait-for` JS expressions | The JS expression never evaluates - JS is disabled |
| Capturing right after `page.goto` with no wait | First paint is rarely the final paint |

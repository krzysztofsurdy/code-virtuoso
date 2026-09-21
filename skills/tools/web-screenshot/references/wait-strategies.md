# Wait strategies for reliable screenshots

The wrong wait strategy is the biggest cause of flaky screenshots. This file lists the patterns that work and the ones that look right but fail.

## Contents

- [The hierarchy](#the-hierarchy)
- [Why networkidle is a trap](#why-networkidle-is-a-trap)
- [Wait patterns that work](#wait-patterns-that-work)
- [Combining waits](#combining-waits)
- [Debugging a slow or hanging capture](#debugging-a-slow-or-hanging-capture)
- [Timeout handling](#timeout-handling)
- [Anti-patterns](#anti-patterns)

## The hierarchy

Pick the most specific wait you can. From best to worst:

1. **Wait for an explicit readiness signal** from the app (`window.__ready = true`)
2. **Wait for a DOM marker** that only appears when content is rendered
3. **Wait for browser primitives** like `document.fonts.ready` or `document.images`
4. **Wait a fixed time** as a last resort
5. ~~**Wait for network idle**~~: never, see below

## Why networkidle is a trap

Playwright's documentation discourages `waitForLoadState('networkidle')` because:

- Analytics pings (GA, Mixpanel, Segment) trickle out indefinitely
- WebSocket connections never idle
- Long-poll endpoints never idle
- Service workers keep the network busy in the background

The result is either a 30-second hang or a flaky timeout that succeeds 80% of the time.

shot-scraper has no `--networkidle` flag for this reason. Do not emulate it.

## Wait patterns that work

### Pattern 1: app sets a readiness global

Best when you control the app. Add this at the end of bootstrap:

```javascript
window.__appReady = true;
```

Then capture with:

```bash
shot-scraper https://app.example.com -o app.png \
  --wait-for "window.__appReady === true"
```

### Pattern 2: wait for a specific DOM marker

Best when you do not control the app but know what "loaded" looks like:

```bash
shot-scraper https://example.com/dashboard -o dash.png \
  --wait-for "document.querySelector('[data-loaded=\"true\"]') !== null"
```

Or wait for content count to stabilise:

```bash
--wait-for "document.querySelectorAll('.item').length >= 10"
```

### Pattern 3: wait for fonts to load

Fonts loading late causes text reflow that ruins comparisons:

```bash
--wait-for "document.fonts.ready"
```

The `document.fonts.ready` promise resolves once all CSS fonts have loaded or failed.

### Pattern 4: wait for images to decode

For pages with above-the-fold imagery:

```bash
--wait-for "Promise.all(Array.from(document.images).map(img => img.complete ? Promise.resolve() : new Promise(r => img.addEventListener('load', r, { once: true }))))"
```

This is verbose. Consider wrapping it in a script file:

```bash
--js-file scripts/wait-for-images.js
```

### Pattern 5: SPA route change

Single-page apps do not fire `load` on route changes. Wait for a route-specific marker:

```bash
shot-scraper "https://spa.example.com/#/pricing" -o pricing.png \
  --wait-for "location.hash === '#/pricing' && document.querySelector('.pricing-hero')"
```

### Pattern 6: fixed delay (last resort)

If nothing else works, give the page a fixed time to settle:

```bash
--wait 2000
```

Use this only for one-off captures. For anything reused, replace with a deterministic wait.

## Combining waits

shot-scraper applies waits in order: first `--wait` (fixed), then `--wait-for` (JS expression). Use both when the app needs time to mount and you also need to wait for a marker:

```bash
shot-scraper https://example.com -o out.png \
  --wait 500 \
  --wait-for "document.fonts.ready && document.querySelector('.hero')"
```

## Debugging a slow or hanging capture

If a capture times out:

1. **Run without `--silent`** and add `--log-console` to see the page's console output
2. **Open the URL in a real browser** with DevTools and check what loads when
3. **Check for analytics or chat widgets** that may hold persistent connections (remove them with `--javascript "document.querySelector('#intercom').remove();"`)
4. **Log requests** with `--log-requests requests.log` to see which requests are slow or never finish
5. **Reduce the wait condition** to something simpler. Start with `document.fonts.ready` and add specificity from there.

## Timeout handling

shot-scraper's default timeout is finite. To raise it:

```bash
--timeout 60000     # 60 seconds
```

If you find yourself raising the timeout, the real fix is usually a better wait condition.

## Anti-patterns

| Anti-pattern | Why it is bad |
|---|---|
| `--wait 10000` "to be safe" | Wastes 10 seconds on every shot, still flakes on slow days |
| Polling with `setInterval` inside `--wait-for` | shot-scraper re-evaluates the expression; the polling does nothing |
| A `--wait-for` expression that never becomes true | The shot fails after the 30-second timeout. Test the expression in DevTools first |
| Capturing right after `page.goto` with no wait | First paint is rarely the final paint |

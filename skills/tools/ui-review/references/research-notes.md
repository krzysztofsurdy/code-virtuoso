# Research notes: ui-review skill

Date: 2026-10-22
Depth: standard
Research skill used: no (inline, WebSearch, WebFetch, gh api, Context7 resolve for React)
Prior-art search: done
Confirmation gates: approved by the maintainer in the build brief.

## Scope

A user-invocable skill that reviews UI code and the rendered page against a local, pinned, sourced rule set in eleven areas (focus and keyboard, forms, motion, typography, images, contrast and dark mode, touch targets, i18n and RTL, states, layout shift, hydration). Procedure: static pass, rendered pass (screenshot capture and image annotation named as capabilities), findings with file:line, rule id, P0 to P2 severity, fix.

Out of scope: designing UI (frontend-design), ARIA widget depth and screen reader testing (accessibility), motion timing, performance profiling.

Questions answered: which existing skills already give a pinned, sourced review; which rules have a normative source; exact thresholds and levels for each rule; what is stale or discontinued.

## Sources

| Source | Tier | Publisher | Published | Retrieved |
|---|---|---|---|---|
| https://github.com/vercel-labs/web-interface-guidelines (command.md, 191 lines) | community, vendor-run | Vercel Labs | pushed 2026-10-05 | 2026-10-22 |
| ~/.agents/skills/web-design-guidelines/SKILL.md | local | Vercel (installed copy) | unknown | 2026-10-22 |
| https://github.com/pbakaus/impeccable (SKILL.src.md, reference/audit.md) | community | Paul Bakaus | pushed 2026-10-22 | 2026-10-22 |
| ~/.agents/skills/frontend-design/SKILL.md | local | unknown | unknown | 2026-10-22 |
| ~/.agents/skills/ui-ux-pro-max/SKILL.md, design-taste-frontend/SKILL.md | local | community | unknown | 2026-10-22 |
| https://github.com/addyosmani/web-quality-skills (accessibility SKILL.md) | community | Addy Osmani | pushed 2026-08-24 | 2026-10-22 |
| https://github.com/maxritter/open-claude-design (open-claude-ui-review) | community | maxritter | pushed 2026-10-20 | 2026-10-22 |
| 29 W3C WCAG 2.2 Understanding pages (listed in rules.md) | standard | W3C WAI | various | 2026-10-22 |
| W3C APG: read-me-first, dialog-modal, alert, button | standard | W3C WAI | 2026 | 2026-10-22 |
| W3C: Using ARIA (discontinued draft), WAI images decision tree, WAI forms notifications, i18n qa-html-dir, i18n article-text-size | standard | W3C | various | 2026-10-22 |
| MDN pages: focus-visible, prefers-reduced-motion, color-scheme, forced-colors, autocomplete, inputmode, input, input/number, dir, translate, tabindex, aria-busy, viewport meta, aspect-ratio, CSS logical properties, Intl | vendor docs | Mozilla | various | 2026-10-22 |
| web.dev: optimize-cls, cls, optimize-lcp, fetch-priority, browser-level-image-lazy-loading, prefers-reduced-motion, color-scheme, font-best-practices, accessible-tap-targets | vendor docs | Google | various | 2026-10-22 |
| React hydrateRoot, Next.js react-hydration-error, Vue SSR guide | official docs | Meta, Vercel, Vue | various | 2026-10-22 |
| skills/knowledge/accessibility (this repo) | local | this repo | n/a | 2026-10-22 |

All 67 URLs in rules.md returned HTTP 200 on 2026-10-22 (curl).

## Prior art

Queries run: `gh api repos/<r>` for stars, push date, license; `gh search code "wcag review" --filename SKILL.md`; `gh search repos "web accessibility audit skill"` (empty); WebSearch "agent skill UI review accessibility WCAG 2.2 audit SKILL.md"; `npx skills find "ui review"` (rerun without `timeout`): top hits vercel-labs/agent-skills@web-design-guidelines (769.1K installs), uizze.sh@ui-taste, ui-ux-pro-max (408.4K), pbakaus/impeccable (351.5K), emilkowalski skills (apple-design, find-animation-opportunities, break-ui). The first, third and fifth are in the table. uizze.sh@ui-taste and the emilkowalski skills were not read (taste and animation leads, not a sourced review). Local scan of ~/.agents/skills and skills/.

| Name | Source URL | Maintainer | Adoption and last update | Scope | Does well | Gets wrong or misses | License |
|---|---|---|---|---|---|---|---|
| web-design-guidelines (Vercel) | https://github.com/vercel-labs/web-interface-guidelines/blob/main/command.md | community (vendor-run) | 1,027 stars, 2026-10-05 | 16 rule groups for UI code, terse file:line output | Good category list, terse output format, anti-pattern list | Installed skill fetches rules from a mutable `main` URL at run time. No spec citations. No severity. No rendered pass. Mixes spec rules with house style (Title Case, curly quotes, ellipsis, tabular-nums). Advises `autocomplete="off"` on non-auth fields, which conflicts with WCAG 1.3.5 and MDN. React and Tailwind flavored | MIT (repo) |
| impeccable | https://github.com/pbakaus/impeccable/blob/main/skill/SKILL.src.md | community | 84.7k stars, 2026-10-22 | 24 commands, design-led, 61 detector rules via CLI, audit scores 0-4 in 5 dimensions | Verification by looking at rendered output, mode concept, evidence-first reports | Heavy: CLI binary, PRODUCT.md and DESIGN.md setup, hooks. Audit rules are not cited to specs (3 WCAG mentions in audit.md). Scores are 0-4, not per-finding severity. Design taste mixed with standards | Apache-2.0 |
| frontend-design | ~/.agents/skills/frontend-design/SKILL.md | unknown | n/a | Generating distinctive UI | Strong on aesthetic direction | It is a build skill, not a review. Names a quality floor in one sentence only | LICENSE.txt in folder |
| ui-ux-pro-max | ~/.agents/skills/ui-ux-pro-max/SKILL.md | community | n/a | 99 UX guidelines, styles, palettes, 658 lines plus data and scripts | Priority-ordered rule categories, pre-delivery checklist | Rules tagged "(WCAG, MD)" with no URLs or levels. Large, mixes design generation with review | not checked |
| accessibility (addyosmani/web-quality-skills) | https://github.com/addyosmani/web-quality-skills/blob/main/skills/accessibility/SKILL.md | community | 2,978 stars, 2026-08-24 | WCAG 2.2 audit workflow, 464 lines | Evidence-led workflow, says automated score is not conformance | Accessibility only: no motion, i18n, hydration, layout shift review; no severity scheme read | MIT |
| open-claude-ui-review | https://github.com/maxritter/open-claude-design/blob/main/skills/open-claude-ui-review/SKILL.md | community | 37 stars, 2026-10-20 | Rendered UI review, lanes, blocker/quality/advisory classes | Report-only boundary, evidence per finding, three-way classification | Tied to its own design workflow, license NOASSERTION (source-available), rules live in references not read | NOASSERTION |

Decision: write a new skill. No candidate gives a pinned local rule set with a spec URL and date on each rule, plus a rendered pass and per-finding severity. Nothing here is clearly better on those points, so no "recommend installing" stop. Local overlap: `accessibility` (this repo) is a background reference for building accessible UI, not a review procedure, so ui-review links to it for depth.

Strengths adopted (ideas only, no text copied): rule groups by area and terse file:line output (Vercel); verify on the rendered page at the shipped sizes and keep tool evidence separate from judgment (impeccable); report-only by default and a three-way split between standards failure and taste (open-claude-ui-review); the note that an automated score is not conformance (addyosmani).
Weaknesses avoided: runtime fetch of a mutable rules URL; uncited rules; house style presented as spec; setup burden.
Gap filled: pinned, sourced, severity-ranked review that covers code and rendered page across eleven areas.

## Fact ledger

Confidence: confirmed = a primary source plus an independent second, or reproduced. likely = one primary source.

| # | Claim | Source URL | Retrieved | Version | Confidence | Verified by |
|---|---|---|---|---|---|---|
| 1 | SC 2.5.8 Target Size (Minimum) is AA, 24 by 24 CSS px, exceptions spacing, equivalent, inline, user agent, essential | https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html | 2026-10-22 | WCAG 2.2 | likely | read page; repo accessibility skill agrees (24px AA) |
| 2 | SC 2.5.5 is AAA, 44 by 44 | .../target-size-enhanced.html | 2026-10-22 | 2.2 | likely | read page |
| 3 | web.dev: about 48 device-independent px target, about 8px spacing | https://web.dev/articles/accessible-tap-targets | 2026-10-22 | n/a | likely | read page (page does not mention WCAG) |
| 4 | SC 2.4.11 Focus Not Obscured (Minimum) is AA, technique C43 scroll-padding | .../focus-not-obscured-minimum.html | 2026-10-22 | 2.2 | likely | read page. Page does not mention scroll-margin, so the rule names scroll-padding only |
| 5 | SC 2.4.7 AA, says nothing about outlines; 2.4.13 is AAA | .../focus-visible.html | 2026-10-22 | 2.2 | confirmed | read page; MDN :focus-visible confirms the 3:1 via 1.4.11 |
| 6 | SC 1.4.3 AA 4.5:1 and 3:1 large (18pt, 14pt bold), no rounding | .../contrast-minimum.html | 2026-10-22 | 2.2 | confirmed | read page; arithmetic checked (18pt = 24px, 14pt = 18.67px) and sample ratios run in python3 (#6b7280 on #111827 = 3.669) |
| 7 | SC 1.4.11 AA 3:1 for UI components, graphics, focus and state indicators | .../non-text-contrast.html | 2026-10-22 | 2.2 | confirmed | read page; MDN focus-visible cites it |
| 8 | SC 1.3.5 AA, autocomplete tokens from HTML spec | .../identify-input-purpose.html | 2026-10-22 | 2.2 | confirmed | read page; MDN autocomplete cites it |
| 9 | SC 3.3.8 AA: do not block paste or autofill, split code fields fail | .../accessible-authentication-minimum.html | 2026-10-22 | 2.2 | likely | read page |
| 10 | MDN: autocomplete="off" does not stop password managers; use sparingly | https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete | 2026-10-22 | n/a | likely | read page |
| 11 | SC 4.1.3 AA status messages, role=status, role=alert, aria-live | .../status-messages.html | 2026-10-22 | 2.2 | likely | read page |
| 12 | APG alert: must not move focus; alerts present at load are not announced | https://www.w3.org/WAI/ARIA/apg/patterns/alert/ | 2026-10-22 | n/a | likely | read page |
| 13 | APG modal dialog: Tab cycles inside, Escape closes, focus returns, aria-modal, accessible name | https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/ | 2026-10-22 | n/a | likely | read page |
| 14 | SC 2.1.1 A (failure F54, F55); 2.1.2 A | .../keyboard.html, .../no-keyboard-trap.html | 2026-10-22 | 2.2 | likely | read pages |
| 15 | SC 2.4.3 A, failure F44; SC 2.4.1 A | .../focus-order.html, .../bypass-blocks.html | 2026-10-22 | 2.2 | likely | read pages |
| 16 | MDN tabindex: avoid positive values, 0 and -1 only | https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/tabindex | 2026-10-22 | n/a | confirmed | read page; WCAG F44 consistent |
| 17 | SC 2.5.7 Dragging Movements AA | .../dragging-movements.html | 2026-10-22 | 2.2 | likely | read page |
| 18 | SC 3.3.1 A, 3.3.3 AA, 3.3.2 A, 1.3.1 A, 4.1.2 A, 1.4.1 A, 1.1.1 A | various Understanding pages | 2026-10-22 | 2.2 | likely | read pages. 3.3.3 level checked on its own page after the 3.3.1 page left it unstated |
| 19 | W3C WAI forms notifications: aria-describedby link, focus first error, role=alert, aria-live polite or assertive | https://www.w3.org/WAI/tutorials/forms/notifications/ | 2026-10-22 | n/a | likely | read page. Note the WCAG 3.3.1 page does not mention aria-describedby, so the rule cites the WAI tutorial for it |
| 20 | MDN input: placeholder not a label; MDN input number: not for postal or card numbers; use text, inputmode numeric, pattern | MDN input, MDN input/number | 2026-10-22 | n/a | likely | read both pages |
| 21 | MDN inputmode is a keyboard hint, type enforces | https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inputmode | 2026-10-22 | n/a | likely | read page |
| 22 | prefers-reduced-motion: reduce means remove, reduce or replace; JS should use matchMedia and listen to change; Baseline widely available | MDN + https://web.dev/articles/prefers-reduced-motion | 2026-10-22 | n/a | confirmed | two independent pages |
| 23 | SC 2.3.3 AAA, technique C39; 2.2.2 A (5 seconds, auto-start, parallel); 2.3.1 A (3 flashes per second) | Understanding pages | 2026-10-22 | 2.2 | likely | read pages |
| 24 | web.dev: animate transform rather than top, left, box-shadow; composited translate does not count toward CLS | https://web.dev/articles/optimize-cls | 2026-10-22 | n/a | likely | read page |
| 25 | SC 1.4.4 AA 200 percent, failures F69, F80, F94; MDN viewport warns against user-scalable=no | Understanding page + MDN viewport | 2026-10-22 | 2.2 | confirmed | two sources. The Understanding page does not name user-scalable, MDN does |
| 26 | SC 1.4.10 AA 320 CSS px, 1280 at 400 percent; exceptions list | .../reflow.html | 2026-10-22 | 2.2 | likely | read page |
| 27 | SC 1.4.12 AA: 1.5, 2, 0.12, 0.16 | .../text-spacing.html | 2026-10-22 | 2.2 | likely | read page |
| 28 | SC 1.4.8 AAA: 80 characters (40 CJK), no justification, 1.5 line spacing | .../visual-presentation.html | 2026-10-22 | 2.2 | likely | read page |
| 29 | web.dev font-display swap vs optional; size-adjust | https://web.dev/articles/font-best-practices, optimize-cls | 2026-10-22 | n/a | confirmed | two web.dev pages |
| 30 | CLS good 0.1 or less at p75, poor above 0.25, 500 ms input exclusion | https://web.dev/articles/cls, optimize-cls | 2026-10-22 | n/a | confirmed | two web.dev pages |
| 31 | web.dev: width and height on images, ads and embeds reserve space, injected content, fonts | https://web.dev/articles/optimize-cls | 2026-10-22 | n/a | likely | read page; MDN aspect-ratio consistent |
| 32 | LCP: do not lazy-load the LCP image, make it discoverable, fetchpriority high on one or two images | optimize-lcp, fetch-priority, browser-level-image-lazy-loading | 2026-10-22 | n/a | confirmed | three web.dev pages |
| 33 | WAI image decision tree and SC 1.1.1: alt="" for decoration (H67), non-empty alt is failure F39 | decision tree + Understanding page | 2026-10-22 | n/a | confirmed | two sources |
| 34 | MDN color-scheme and web.dev color-scheme: meta before CSS avoids wrong first paint; check contrast on defaults | two pages | 2026-10-22 | n/a | confirmed | two independent pages |
| 35 | MDN forced-colors: box-shadow and most backgrounds removed; use system color border; Baseline since 2022-09 | MDN | 2026-10-22 | n/a | likely | read page |
| 36 | SC 3.1.1 A, 3.1.2 AA; MDN dir: set dir on html, lang does not set direction; W3C i18n says use dir not CSS | MDN dir, W3C qa-html-dir, Understanding pages | 2026-10-22 | n/a | confirmed | MDN and W3C agree |
| 37 | MDN logical properties; W3C i18n mirroring | MDN + W3C | 2026-10-22 | n/a | confirmed | two sources |
| 38 | Intl constructors DateTimeFormat, NumberFormat, PluralRules, ListFormat, RelativeTimeFormat | MDN Intl | 2026-10-22 | n/a | likely | read page (one-line descriptions) |
| 39 | W3C i18n text size: short strings expand most, 1-10 chars about 200-300 percent (IBM guideline in the article) | https://www.w3.org/International/articles/article-text-size | 2026-10-22 | n/a | likely | read page. Rule words it as "two to three times" |
| 40 | MDN translate="no" is a hint | MDN | 2026-10-22 | n/a | likely | read page |
| 41 | aria-busy: set true during multi-part update, reset on every exit | MDN | 2026-10-22 | n/a | likely | read page |
| 42 | Hydration: output must match; causes (typeof window, browser APIs, Date, different data, nesting); suppressHydrationWarning one level deep and does not patch text; Vue 3.5 data-allow-mismatch; Vue timezone cause | React, Next.js, Vue docs | 2026-10-22 | React 19 docs, Next.js current docs, Vue 3 | confirmed | three independent docs agree on core causes. The React page does not list Date.now or Math.random, so the rule cites Next and Vue for Date and random |
| 43 | W3C Using ARIA is a Discontinued Draft (2026-02-24) | https://www.w3.org/TR/using-aria/ | 2026-10-22 | DISC-using-aria-20260224 | confirmed | read page. Used only for rule 4 text (no aria-hidden or presentation on focusable), flagged as such in FK-02 |
| 44 | APG read-me-first says "No ARIA is better than Bad ARIA" and "a role is a promise"; it does not use the phrase "first rule of ARIA" | https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/ | 2026-10-22 | n/a | likely | read page |

## Not confirmed

| Item | Reason | Action |
|---|---|---|
| uizze.sh@ui-taste, emilkowalski skills from the registry | Listed by the registry, SKILL.md not read | Titles point to taste and animation, not a sourced review. Check before release if overlap worries you |
| Baseline run (agent without the skill) | No user or spare agent available; spawning was barred | Baseline gaps were derived from the prior-art table instead of observed. Treat Phase 1 baseline as reasoned, not measured |
| Trigger evals run | Costs real model calls | Only `evals/run.sh check` and `bash evals/tests/test-stage.sh` ran (both pass). Run `evals/run.sh triggers --case 'ui-review-*'` before release |
| Impeccable detector rules | Read README, SKILL.src.md and audit.md only, not the 61 detector rules | Left as an adopt-ideas comparison, no text reused |
| Lighthouse touch-target thresholds | Not found on the sources read | Not stated in the skill |
| A rendered pass on a real site | No browser run during authoring | Procedure is written from the capture and annotation steps as designed. Run once on a real page and adjust |
| Practice rules: ST-03 empty state content, ST-04 pending state, IR-03 icon mirroring, IR-04 fragment concatenation, FM-04 reasoning for codes | No normative source | Marked "practice" in rules.md and capped at P2 |

## Left out

| Item | Why |
|---|---|
| Vercel rules on copy and typography style (Title Case, curly quotes, non-breaking spaces, ellipsis, active voice, numerals) | House style with no spec behind it |
| `touch-action: manipulation`, tap highlight, overscroll-behavior, safe-area insets, `tabular-nums`, `text-wrap: balance` | Browser-specific or taste, no normative source read. Candidates for a later rule if sourced |
| Virtualizing long lists, layout reads in render, preconnect, URL state for filters, destructive-action confirmation | Performance or product patterns outside the eleven areas, or no source read |
| Focus Appearance 2.4.13, hover and focus content 1.4.13, consistent navigation | Not requested or AAA and not fetched |
| WCAG levels A/AA/AAA overview, POUR | Model knows it, and `accessibility` covers it |
| Dates in the skill text | The brief asks for the pin date on each rule. It sits only in rules.md, not in SKILL.md prose. This deliberately overrides the checklist line "no dates in the skill text" |

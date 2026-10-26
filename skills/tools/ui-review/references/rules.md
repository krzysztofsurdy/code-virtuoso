# UI review rules

The pinned rule set for the `ui-review` skill. Each rule has a stable id. Ids are never reused: a retired rule keeps its id and is marked retired.

## Contents

- [How to read a rule](#how-to-read-a-rule)
- [Severity](#severity)
- [FK: focus and keyboard](#fk-focus-and-keyboard)
- [FM: forms](#fm-forms)
- [MO: motion](#mo-motion)
- [TY: typography and text scaling](#ty-typography-and-text-scaling)
- [IM: images](#im-images)
- [CD: color contrast and dark mode](#cd-color-contrast-and-dark-mode)
- [TT: touch targets](#tt-touch-targets)
- [IR: i18n and RTL](#ir-i18n-and-rtl)
- [ST: loading, empty and error states](#st-loading-empty-and-error-states)
- [PF: layout shift](#pf-layout-shift)
- [HY: hydration safety](#hy-hydration-safety)

## How to read a rule

| Column | Meaning |
|---|---|
| ID | Two letters for the area, two digits for the rule. Quote it in every finding |
| Sev | Default severity. Raise or lower it with the context rules below, and say why |
| Check | What to look for in code (static) and on the page (rendered), then the fix |
| Source | The page the rule rests on, with the date it was read. A WCAG level in brackets means the rule is normative at that level. A rule marked "practice" has no normative source: report it as P2 at most, and never call it a standards failure |

All sources were read on 2026-10-22. That date is the pin. When a source page changes, re-read it and update the row before relying on it. Do not replace a row with text fetched from a mutable URL at review time.

The rules are written in this library's own words. They cite specifications and vendor documentation, not another review checklist.

## Severity

| Level | Meaning | Typical cases |
|---|---|---|
| P0 | A user cannot complete a task or perceive content, or the page can cause physical harm | Control unreachable by keyboard, unlabeled input, keyboard trap, flashing content, hydration that drops handlers |
| P1 | Fails a WCAG A or AA criterion without fully blocking, or a clear repeated UX defect | Low contrast, small targets, no reflow, layout shift over threshold, missing error text |
| P2 | AAA criteria, polish, or practice with no normative source | Line length, `inputmode`, forced-colors fallback, empty-state copy |

Context rules:

- Raise one level when the defect sits on the main path (sign-up, checkout, navigation) or affects every page through a shared component.
- Lower one level when the element is not reachable in the shipped product (dead code, a story or demo page). Say so in the finding.
- A rule whose Source says "practice" never goes above P2.

## FK: focus and keyboard

Depth on widgets and testing lives in the `accessibility` skill (keyboard and focus reference, ARIA patterns).

| ID | Sev | Check | Source |
|---|---|---|---|
| FK-01 | P0 | Click handlers on elements with no native interactivity (`div`, `span`, `li`, `img`) and no keyboard path. Navigation done with a click handler instead of a link with `href`. Fix: `button` for actions, `a` for navigation. Pointer-only handlers fail even when the element looks right | [WCAG 2.1.1 Keyboard (A), failure F54](https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html); [WCAG 4.1.2 (A)](https://www.w3.org/WAI/WCAG22/Understanding/name-role-value.html); [MDN tabindex](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/tabindex), 2026-10-22 |
| FK-02 | P0 | A `role` that promises behavior it does not deliver: `role="button"` without Enter and Space handling, a custom control with no accessible name, `aria-hidden` or `role="presentation"` on something focusable. A native element with no role beats a wrong one | [APG read me first](https://www.w3.org/WAI/ARIA/apg/practices/read-me-first/); [APG button pattern](https://www.w3.org/WAI/ARIA/apg/patterns/button/); [W3C Using ARIA, rule 4](https://www.w3.org/TR/using-aria/) (discontinued draft, cited for the rule text only), 2026-10-22 |
| FK-03 | P1 | No visible focus indicator: `outline: none` or `outline: 0` with no replacement, script that blurs an element on focus. Fix: style `:focus-visible` instead of removing the outline. Contrast of the indicator is checked by CD-02 | [WCAG 2.4.7 Focus Visible (AA)](https://www.w3.org/WAI/WCAG22/Understanding/focus-visible.html); [MDN :focus-visible](https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible), 2026-10-22 |
| FK-04 | P1 | Sticky or fixed headers, footers, cookie bars or chat widgets that cover the focused element while tabbing. Rendered pass: tab through the page and watch the focused item. Fix: `scroll-padding` on the scroll container that matches the overlay height | [WCAG 2.4.11 Focus Not Obscured (AA), technique C43](https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html), 2026-10-22 |
| FK-05 | P1 | Tab order that differs from reading order: positive `tabindex`, visual reordering (CSS `order`, row-reverse, absolute positioning) of focusable elements. Fix: reorder the DOM, use `tabindex` only as 0 or -1 | [WCAG 2.4.3 Focus Order (A), failure F44](https://www.w3.org/WAI/WCAG22/Understanding/focus-order.html); [MDN tabindex](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/tabindex), 2026-10-22 |
| FK-06 | P0 | Modal dialog that does not move focus in on open, lets Tab reach the page behind, ignores Escape, has no close control, has no accessible name, or does not return focus to the opener. A custom widget that Tab enters and cannot leave | [APG dialog (modal) pattern](https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/); [WCAG 2.1.2 No Keyboard Trap (A)](https://www.w3.org/WAI/WCAG22/Understanding/no-keyboard-trap.html), 2026-10-22 |
| FK-07 | P1 | Repeated navigation before the main content with none of: a skip link, landmark regions (`main`, `nav`), or headings that mark the sections | [WCAG 2.4.1 Bypass Blocks (A)](https://www.w3.org/WAI/WCAG22/Understanding/bypass-blocks.html), 2026-10-22 |
| FK-08 | P1 | Drag, swipe or reorder interactions with no single-pointer or keyboard alternative (buttons that move the item, a click to place) | [WCAG 2.5.7 Dragging Movements (AA)](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html); [WCAG 2.1.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/keyboard.html), 2026-10-22 |

## FM: forms

| ID | Sev | Check | Source |
|---|---|---|---|
| FM-01 | P0 | An input, select or textarea with no programmatic label: no `label` tied by `for` and `id` (`htmlFor` in JSX) or by wrapping, and no `aria-labelledby` or `aria-label`. Icon-only buttons need a name too. Group related radios and checkboxes with `fieldset` and `legend` | [WCAG 1.3.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/info-and-relationships.html); [WCAG 3.3.2 (A)](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html); [WCAG 4.1.2 (A)](https://www.w3.org/WAI/WCAG22/Understanding/name-role-value.html), 2026-10-22 |
| FM-02 | P1 | The placeholder is the only label, or a floating label hides the real one once the field has a value. Placeholders vanish on typing, are not reliably announced, and may skip auto-translation. Use them for format hints only | [MDN input element, placeholders](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input); [WCAG 3.3.2 (A)](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html), 2026-10-22 |
| FM-03 | P1 | Fields that collect the user's own data (name, email, phone, address, card, username, passwords, one-time codes) without a valid `autocomplete` token such as `email`, `current-password`, `new-password`, `one-time-code`, `cc-number`. Made-up tokens count as missing | [WCAG 1.3.5 Identify Input Purpose (AA)](https://www.w3.org/WAI/WCAG22/Understanding/identify-input-purpose.html); [MDN autocomplete](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete), 2026-10-22 |
| FM-04 | P2 | `type` states what the value is, `inputmode` only picks the keyboard. Use `email`, `tel`, `url` when the value must be one. Do not use `type="number"` for values that are digits but not quantities (postal codes, card numbers, codes): use text with `inputmode="numeric"` and a `pattern` | [MDN inputmode](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/inputmode); [MDN input type number](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/input/number), 2026-10-22 |
| FM-05 | P1 | Validation errors that are color-only, say only "invalid", or do not name the field. An error needs text that identifies the field and, when the fix is known, says how to correct it | [WCAG 3.3.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html); [WCAG 3.3.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/error-suggestion.html); [WCAG 1.4.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html), 2026-10-22 |
| FM-06 | P1 | Error text not linked to its field (`aria-describedby`, `aria-invalid`), no focus or summary after a failed submit, or messages shown without `role="alert"` or a live region. An alert must be inserted after load to be announced and must not move focus | [W3C WAI forms: notifications](https://www.w3.org/WAI/tutorials/forms/notifications/); [APG alert pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alert/); [WCAG 4.1.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), 2026-10-22 |
| FM-07 | P1 | Login or verification fields that block paste (a paste handler that cancels the event), block password-manager autofill, or split a code into single-digit boxes with no full-paste path | [WCAG 3.3.8 Accessible Authentication, Minimum (AA)](https://www.w3.org/WAI/WCAG22/Understanding/accessible-authentication-minimum.html), 2026-10-22 |
| FM-08 | P2 | `autocomplete="off"` applied to whole forms or ordinary fields. It does not stop password managers in current browsers and removes autofill help. Keep it for the few cases that need it, such as a CAPTCHA or a one-time token field | [MDN autocomplete](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/autocomplete), 2026-10-22 |
| FM-09 | P1 | Required state, format or other instructions that appear only as color, an icon, or a tooltip. Instructions must be visible text. This holds for optional fields as well | [WCAG 3.3.2 (A)](https://www.w3.org/WAI/WCAG22/Understanding/labels-or-instructions.html), 2026-10-22 |

## MO: motion

This area only gates safety and user preference. Timing, easing and choreography are out of scope.

| ID | Sev | Check | Source |
|---|---|---|---|
| MO-01 | P1 | Large or looping motion (parallax, scaling or panning of big areas, auto-scroll, autoplay video, page transitions) with no `prefers-reduced-motion` handling. "Reduce" means remove, shorten or replace with a fade, not always switch off, so keep state-change feedback. JavaScript-driven animation must read `matchMedia` and react to its `change` event. Small fades are P2 | [MDN prefers-reduced-motion](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-reduced-motion); [web.dev prefers-reduced-motion](https://web.dev/articles/prefers-reduced-motion); [WCAG 2.3.3 (AAA), technique C39](https://www.w3.org/WAI/WCAG22/Understanding/animation-from-interactions.html), 2026-10-22 |
| MO-02 | P1 | Moving, blinking or scrolling content that starts by itself, runs over five seconds, and sits next to other content (carousel, marquee, background video, looping animation) with no pause, stop or hide control | [WCAG 2.2.2 Pause, Stop, Hide (A)](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide.html), 2026-10-22 |
| MO-03 | P0 | Anything that flashes more than three times in any one second, unless below the flash thresholds | [WCAG 2.3.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html), 2026-10-22 |
| MO-04 | P2 | Animations on layout properties (`top`, `left`, `width`, `height`, `box-shadow`) instead of `transform` and `opacity`. Layout-triggering animation costs frames and can add layout shift. Raise to P1 when the rendered pass shows shifts | [web.dev optimize CLS, animations](https://web.dev/articles/optimize-cls), 2026-10-22 |

## TY: typography and text scaling

| ID | Sev | Check | Source |
|---|---|---|---|
| TY-01 | P1 | Viewport meta with `user-scalable=no` or a low `maximum-scale`. Fix: `width=device-width` only. Zoom must work | [MDN viewport meta](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Elements/meta/name/viewport); [WCAG 1.4.4 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html), 2026-10-22 |
| TY-02 | P1 | Text that clips or breaks at 200 percent: fixed-height text boxes, font sizes tied only to viewport units, controls that do not grow with their text. Rendered pass: zoom to 200 percent | [WCAG 1.4.4 Resize Text (AA), failures F69, F80, F94](https://www.w3.org/WAI/WCAG22/Understanding/resize-text.html), 2026-10-22 |
| TY-03 | P1 | Vertical-scrolling content that needs horizontal scroll at 320 CSS pixels wide (1280 wide at 400 percent zoom): fixed widths, `min-width`, `white-space: nowrap`, overflowing grids. Data tables, maps, diagrams and similar two-dimensional content are exempt | [WCAG 1.4.10 Reflow (AA)](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html), 2026-10-22 |
| TY-04 | P1 | Layout that loses content when users apply their own spacing: line height 1.5, paragraph spacing 2, letter spacing 0.12, word spacing 0.16 (all times font size). Look for `overflow: hidden` on fixed-height text containers. Content must tolerate these values, it need not use them | [WCAG 1.4.12 Text Spacing (AA)](https://www.w3.org/WAI/WCAG22/Understanding/text-spacing.html), 2026-10-22 |
| TY-05 | P2 | Body text lines longer than 80 characters (40 for CJK), fully justified body text, or body line spacing under 1.5. Cap prose containers with a `ch` based `max-width`. Many designs aim well under 80, so follow the design system when it sets a narrower measure | [WCAG 1.4.8 Visual Presentation (AAA)](https://www.w3.org/WAI/WCAG22/Understanding/visual-presentation.html), 2026-10-22 |
| TY-06 | P2 | Web font loading left at the default: no deliberate `font-display` (`swap` shows text early and may shift, `optional` avoids the shift), no fallback metrics matched with `size-adjust` | [web.dev font best practices](https://web.dev/articles/font-best-practices); [web.dev optimize CLS, web fonts](https://web.dev/articles/optimize-cls), 2026-10-22 |

## IM: images

| ID | Sev | Check | Source |
|---|---|---|---|
| IM-01 | P0 | An `img` with no `alt` attribute, or an image that carries meaning through CSS background, icon font or inline SVG with no text alternative. Informative images get a short description of what they convey, functional ones (inside links or buttons) describe the action or destination, text images repeat their text | [WCAG 1.1.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/non-text-content.html); [W3C WAI image decision tree](https://www.w3.org/WAI/tutorials/images/decision-tree/), 2026-10-22 |
| IM-02 | P1 | Decorative images with a non-empty `alt` ("image", "spacer", a filename). Use `alt=""` so assistive technology skips them | [WCAG 1.1.1, technique H67 and failure F39](https://www.w3.org/WAI/WCAG22/Understanding/non-text-content.html), 2026-10-22 |
| IM-03 | P1 | `img`, `video` and `iframe` with no `width` and `height` (or CSS `aspect-ratio`), so the browser cannot reserve space. In `picture`, add the dimensions to each `source`. Keep one aspect ratio across `srcset` candidates | [web.dev optimize CLS, images without dimensions](https://web.dev/articles/optimize-cls); [MDN aspect-ratio](https://developer.mozilla.org/en-US/docs/Web/CSS/aspect-ratio), 2026-10-22 |
| IM-04 | P1 | Lazy loading on the wrong images. Below-the-fold images should use `loading="lazy"`. The image likely to be the largest paint, and anything visible on load, must load eagerly, discoverable in the initial HTML, with `fetchpriority="high"` on only one or two images | [web.dev browser-level lazy loading](https://web.dev/articles/browser-level-image-lazy-loading); [web.dev optimize LCP](https://web.dev/articles/optimize-lcp); [web.dev fetch priority](https://web.dev/articles/fetch-priority), 2026-10-22 |

## CD: color contrast and dark mode

Contrast is computed from the colors the browser resolves. Measure them on the rendered page, or resolve tokens by hand in the static pass. Do not estimate by eye.

| ID | Sev | Check | Source |
|---|---|---|---|
| CD-01 | P1 | Text under 4.5:1 against its background, or large text (24px, or about 18.5px bold) under 3:1. The ratio is not rounded: 4.499 fails. Check placeholder, helper, disabled-looking but active, hover and dark-theme text. Inactive controls and logotypes are exempt | [WCAG 1.4.3 Contrast Minimum (AA)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), 2026-10-22 |
| CD-02 | P1 | Input borders, icon-only controls, chart marks, and state indicators (focus ring, checked, selected, expanded) under 3:1 against adjacent colors. Hover and visited colors are exempt | [WCAG 1.4.11 Non-text Contrast (AA)](https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html); [MDN :focus-visible](https://developer.mozilla.org/en-US/docs/Web/CSS/:focus-visible), 2026-10-22 |
| CD-03 | P1 | Meaning carried by color alone: red-only errors, links in body text with no underline or other cue, status dots, chart series told apart only by hue. Add text, an icon, a pattern or an underline | [WCAG 1.4.1 Use of Color (A)](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html), 2026-10-22 |
| CD-04 | P2 | A page with dark styling that does not declare `color-scheme` (a `meta` tag placed before the CSS, or `:root`), so form controls, scrollbars and the first paint stay light. Raise to P1 when the rendered pass shows light controls on a dark page or a flash | [MDN color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/color-scheme); [web.dev color-scheme](https://web.dev/articles/color-scheme), 2026-10-22 |
| CD-05 | P1 | Dark theme gaps: tokens with no dark value, hard-coded colors that bypass the tokens, default link colors on dark backgrounds, images or logos that vanish. Rerun CD-01 to CD-03 in both schemes | [web.dev color-scheme, contrast note](https://web.dev/articles/color-scheme); [WCAG 1.4.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html), 2026-10-22 |
| CD-06 | P2 | A control whose edge or state exists only as `box-shadow` or a background image. Forced-colors mode removes both. Add a border in a system color inside `@media (forced-colors: active)`. Do not build a second design for that mode | [MDN forced-colors](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/forced-colors), 2026-10-22 |

## TT: touch targets

| ID | Sev | Check | Source |
|---|---|---|---|
| TT-01 | P1 | Pointer targets smaller than 24 by 24 CSS pixels. Measure the hit area, which includes padding, not the icon. Exceptions: spacing (TT-02), an equivalent control elsewhere, inline links in text, browser-drawn controls, essential presentation | [WCAG 2.5.8 Target Size, Minimum (AA)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), 2026-10-22 |
| TT-02 | P1 | Undersized targets packed together. A 24px circle centered on each undersized target must not overlap another target or another circle | [WCAG 2.5.8 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html), 2026-10-22 |
| TT-03 | P2 | Touch-first screens (mobile layouts, toolbars, list rows) with targets under 44 by 44 CSS pixels, or under about 48 device-independent pixels with about 8px between them | [WCAG 2.5.5 (AAA)](https://www.w3.org/WAI/WCAG22/Understanding/target-size-enhanced.html); [web.dev accessible tap targets](https://web.dev/articles/accessible-tap-targets), 2026-10-22 |

## IR: i18n and RTL

| ID | Sev | Check | Source |
|---|---|---|---|
| IR-01 | P1 | No `lang` on `html`, or a `lang` that does not match the content. Passages in another language carry their own `lang` (P2) | [WCAG 3.1.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/language-of-page.html); [WCAG 3.1.2 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/language-of-parts.html), 2026-10-22 |
| IR-02 | P1 | RTL locales that set direction in CSS only, or not at all. Set `dir` on `html` (`lang` does not set direction). Use `dir="auto"` or `bdi` for user-generated text of unknown direction | [MDN dir](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/dir); [W3C i18n: html dir](https://www.w3.org/International/questions/qa-html-dir), 2026-10-22 |
| IR-03 | P1 | Physical CSS (`margin-left`, `padding-right`, `left`, `text-align: left`, `float: left`, `border-left`) on parts that must mirror. Use logical properties (`margin-inline-start`, `padding-inline`, `inset-inline-start`, `text-align: start`). Direction-implying icons such as arrows and chevrons need a mirroring decision (practice) | [MDN CSS logical properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values); [W3C i18n: html dir, mirroring](https://www.w3.org/International/questions/qa-html-dir), 2026-10-22 |
| IR-04 | P1 | Hard-coded date, number, currency, list or relative-time formats, and hand-rolled plurals (`count === 1 ? ... : ...`). Use `Intl.DateTimeFormat`, `NumberFormat`, `PluralRules`, `ListFormat`, `RelativeTimeFormat`. Building sentences by joining translated fragments is a related defect (practice) | [MDN Intl](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl), 2026-10-22 |
| IR-05 | P1 | Fixed-width buttons, tabs, table headers and labels that cannot grow. Translated UI strings expand, short ones the most (a 1 to 10 character string can grow two to three times). Rendered pass: swap in long pseudo-text and look for clipping | [W3C i18n: text size in translation](https://www.w3.org/International/articles/article-text-size), 2026-10-22 |
| IR-06 | P2 | Brand names, product names and code tokens that auto-translation may mangle: add `translate="no"`. It is a strong hint, not a guarantee | [MDN translate](https://developer.mozilla.org/en-US/docs/Web/HTML/Reference/Global_attributes/translate), 2026-10-22 |

## ST: loading, empty and error states

| ID | Sev | Check | Source |
|---|---|---|---|
| ST-01 | P1 | Async regions with no loading state, or a loading state that screen readers never hear. Announce progress through `role="status"` or a polite live region, and set `aria-busy="true"` while several parts update, then reset it on every exit path including errors. Reserve the final size so the swap does not shift the page (PF-01) | [WCAG 4.1.3 Status Messages (AA)](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html); [MDN aria-busy](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Reference/Attributes/aria-busy), 2026-10-22 |
| ST-02 | P1 | A failed request that leaves a spinner, a blank region, or a console error only. The error state names what failed and offers a next step (retry, edit, contact), is exposed with `role="alert"` without moving focus, and the page is not stuck in loading | [WCAG 3.3.1 (A)](https://www.w3.org/WAI/WCAG22/Understanding/error-identification.html); [WCAG 3.3.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/error-suggestion.html); [APG alert pattern](https://www.w3.org/WAI/ARIA/apg/patterns/alert/), 2026-10-22 |
| ST-03 | P2 | An empty list, search result or table that renders a bare container or orphan headings. Show what is missing and one next action. When a filter or search changes the result count, announce the count through a status region | Practice for the empty-state content. [WCAG 4.1.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html) for the announcement, 2026-10-22 |
| ST-04 | P2 | Actions with no pending state: a submit that can fire twice, a button that gives no sign it was pressed, a failure that discards what the user typed | Practice. Announcement of the result follows [WCAG 4.1.3 (AA)](https://www.w3.org/WAI/WCAG22/Understanding/status-messages.html), 2026-10-22 |

## PF: layout shift

Depth on measurement and profiling lives in the `performance` skill. These rules cover the shifts a user sees.

| ID | Sev | Check | Source |
|---|---|---|---|
| PF-01 | P1 | Embeds, iframes, ads, maps, skeleton swaps and late widgets with no reserved space. Use `min-height` or `aspect-ratio`, and keep the placeholder when nothing loads | [web.dev optimize CLS, ads, embeds and iframes](https://web.dev/articles/optimize-cls), 2026-10-22 |
| PF-02 | P1 | Content inserted above what the user is reading after load: banners, consent bars, "new items" strips, feed prepends. Overlay it, place it below the fold, or reserve its space. Shifts within 500 ms of a click or key press are excluded from the metric | [web.dev optimize CLS, dynamically injected content](https://web.dev/articles/optimize-cls); [web.dev CLS](https://web.dev/articles/cls), 2026-10-22 |
| PF-03 | P1 | A measured CLS above 0.1 at the 75th percentile (above 0.25 is poor). A lab run on one page load is a hint, not the metric: say which it was | [web.dev CLS](https://web.dev/articles/cls), 2026-10-22 |

## HY: hydration safety

The causes are the same in React, Next.js and Vue: the first client render must produce the markup the server sent.

| ID | Sev | Check | Source |
|---|---|---|---|
| HY-01 | P0 | Render logic that differs between server and client: `typeof window` branches, `window`, `localStorage` or `matchMedia` read during render (including a theme chosen from storage), `Date`, random values. Fix: render the server-safe value first and switch in an effect, or serialize the value from the server | [React hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot); [Next.js hydration error](https://nextjs.org/docs/messages/react-hydration-error); [Vue SSR, hydration mismatch](https://vuejs.org/guide/scaling-up/ssr.html), 2026-10-22 |
| HY-02 | P1 | Invalid HTML nesting that the browser repairs before hydration: `div` or `ul` inside `p`, `p` inside `p`, `a` inside `a`, `button` inside `button` | [Next.js hydration error](https://nextjs.org/docs/messages/react-hydration-error); [Vue SSR, hydration mismatch](https://vuejs.org/guide/scaling-up/ssr.html), 2026-10-22 |
| HY-03 | P1 | Dates and times formatted with the runtime's own locale or time zone during render. Server and browser can differ. Pass an explicit locale and `timeZone`, or render the value client-only | [Vue SSR, timezone differences](https://vuejs.org/guide/scaling-up/ssr.html); [Next.js hydration error](https://nextjs.org/docs/messages/react-hydration-error), 2026-10-22 |
| HY-04 | P2 | `suppressHydrationWarning` (React) or `data-allow-mismatch` (Vue 3.5+) used broadly. It works one level deep, React does not patch the mismatched text, and it hides real bugs. Allow it on a single leaf that must differ, such as a timestamp | [React hydrateRoot](https://react.dev/reference/react-dom/client/hydrateRoot); [Vue SSR](https://vuejs.org/guide/scaling-up/ssr.html), 2026-10-22 |
| HY-05 | P2 | A mismatch with clean code is often not in the code: browser extensions that edit the DOM, a CDN that minifies or rewrites HTML, mobile browsers that turn numbers into links (fixable with a `format-detection` meta tag). Rule these out before rewriting components | [Next.js hydration error](https://nextjs.org/docs/messages/react-hydration-error), 2026-10-22 |

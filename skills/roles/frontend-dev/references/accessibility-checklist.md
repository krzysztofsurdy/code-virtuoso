# Accessibility Checklist for Frontend Developers

A practical WCAG-aligned checklist for building accessible user interfaces. Organized by implementation area, not WCAG success criteria numbers, so you can use it during development.

---

## Semantic HTML

| # | Check | WCAG |
|---|---|---|
| 1 | Page has exactly one `<h1>` and headings follow a logical hierarchy (h1 > h2 > h3, no skipping) | 1.3.1 |
| 2 | Navigation uses `<nav>` element | 1.3.1 |
| 3 | Main content is wrapped in `<main>` | 1.3.1 |
| 4 | Lists use `<ul>`, `<ol>`, or `<dl>` - not divs with visual bullets | 1.3.1 |
| 5 | Tables use `<table>`, `<thead>`, `<th>` with `scope` attribute | 1.3.1 |
| 6 | Buttons that perform actions use `<button>`, not `<div>` or `<a>` | 4.1.2 |
| 7 | Links that navigate use `<a>` with `href`, not `<button>` or `<span>` | 4.1.2 |
| 8 | Sections have visible or aria-labeled headings | 2.4.6 |

---

## Keyboard Navigation

| # | Check | WCAG |
|---|---|---|
| 1 | All interactive elements are reachable via Tab key | 2.1.1 |
| 2 | Tab order follows the visual order of the page (no unexpected jumps) | 2.4.3 |
| 3 | Focus is visible on all interactive elements (outline or equivalent indicator) | 2.4.7 |
| 4 | Buttons and links activate with Enter; buttons also activate with Space | 2.1.1 |
| 5 | Modals trap focus inside when open (Tab does not escape to background) | 2.4.3 |
| 6 | Modals return focus to the trigger element when closed | 2.4.3 |
| 7 | Dropdown menus support arrow key navigation | 2.1.1 |
| 8 | Escape key closes modals, dropdowns, and popovers | 2.1.1 |
| 9 | Skip-to-content link is the first focusable element on the page | 2.4.1 |
| 10 | No keyboard traps - the user can always Tab away from any element | 2.1.2 |
| 11 | Custom components (tabs, accordions, sliders) follow WAI-ARIA authoring practices for keyboard interaction | 2.1.1 |

---

## Images and Media

| # | Check | WCAG |
|---|---|---|
| 1 | Informative images have descriptive `alt` text | 1.1.1 |
| 2 | Decorative images have `alt=""` (empty alt) or are CSS background images | 1.1.1 |
| 3 | Complex images (charts, infographics) have a text alternative nearby or via `aria-describedby` | 1.1.1 |
| 4 | Icons used as buttons have accessible labels (`aria-label` or visually hidden text) | 1.1.1 |
| 5 | Videos have captions | 1.2.2 |
| 6 | Audio content has a text transcript | 1.2.1 |
| 7 | No content relies solely on color to convey meaning (error states use icons or text too) | 1.4.1 |

---

## Forms

| # | Check | WCAG |
|---|---|---|
| 1 | Every input has a visible `<label>` associated via `for`/`id` | 1.3.1 |
| 2 | Required fields are indicated in the label (not just by color) | 3.3.2 |
| 3 | Error messages identify the field and describe the problem | 3.3.1 |
| 4 | Error messages are programmatically associated with the field (`aria-describedby` or `aria-errormessage`) | 3.3.1 |
| 5 | Form submission errors are announced to screen readers (via `role="alert"` or live region) | 4.1.3 |
| 6 | Autocomplete attributes are set for common fields (name, email, address, credit card) | 1.3.5 |
| 7 | Placeholder text does not replace labels | 1.3.1 |
| 8 | Field groups use `<fieldset>` and `<legend>` (e.g., radio button groups, address sections) | 1.3.1 |
| 9 | Form validation does not rely solely on color changes | 1.4.1 |
| 10 | Users can review and correct input before final submission for important transactions | 3.3.4 |

---

## Color and Contrast

| # | Check | WCAG |
|---|---|---|
| 1 | Normal text (< 18px) has at least 4.5:1 contrast ratio against background | 1.4.3 |
| 2 | Large text (>= 18px or >= 14px bold) has at least 3:1 contrast ratio | 1.4.3 |
| 3 | UI components (buttons, inputs, icons) have at least 3:1 contrast against adjacent colors | 1.4.11 |
| 4 | Focus indicators have at least 3:1 contrast against the surrounding background | 1.4.11 |
| 5 | Information is not conveyed by color alone (use text, icons, or patterns in addition) | 1.4.1 |
| 6 | Links are distinguishable from surrounding text (underline, or 3:1 contrast + non-color indicator on hover/focus) | 1.4.1 |

### Contrast Checking Tools

| Tool | How to Use |
|---|---|
| Chrome DevTools | Inspect element > Color picker shows contrast ratio |
| Firefox Accessibility Inspector | Accessibility tab > Check for contrast issues |
| WebAIM Contrast Checker | https://webaim.org/resources/contrastchecker/ |
| axe DevTools extension | Run scan > Review color contrast violations |

---

## ARIA Usage

### Rules of ARIA

| Rule | Explanation |
|---|---|
| 1. Do not use ARIA if native HTML works | `<button>` beats `<div role="button">` |
| 2. Do not change native semantics | Do not put `role="heading"` on a `<button>` |
| 3. All interactive ARIA controls must be keyboard operable | If you add `role="tab"`, it must work with arrow keys |
| 4. Do not use `role="presentation"` or `aria-hidden="true"` on focusable elements | This hides them from assistive tech while leaving them in the tab order |
| 5. All interactive elements must have an accessible name | Via label, `aria-label`, or `aria-labelledby` |

### Common ARIA Patterns

| Pattern | When to Use | Key Attributes |
|---|---|---|
| Live region | Dynamic content updates (notifications, search results count) | `aria-live="polite"` or `aria-live="assertive"` |
| Expanded/collapsed | Accordions, dropdown menus | `aria-expanded="true/false"` |
| Modal dialog | Modal overlays | `role="dialog"`, `aria-modal="true"`, `aria-labelledby` |
| Tab interface | Tabbed content panels | `role="tablist"`, `role="tab"`, `role="tabpanel"`, `aria-selected` |
| Combobox | Autocomplete/typeahead inputs | `role="combobox"`, `aria-expanded`, `aria-activedescendant` |
| Progress | Loading indicators, progress bars | `role="progressbar"`, `aria-valuenow`, `aria-valuemin`, `aria-valuemax` |

---

## Dynamic Content

| # | Check | WCAG |
|---|---|---|
| 1 | Content loaded dynamically (AJAX, SPA navigation) updates the page title | 2.4.2 |
| 2 | Focus is managed after dynamic content changes (move focus to new content or announce it) | 4.1.3 |
| 3 | Loading states are announced to screen readers | 4.1.3 |
| 4 | Toast/notification messages use `aria-live` regions | 4.1.3 |
| 5 | Infinite scroll has a mechanism to reach content after the scrolling area (footer, nav) | 2.1.1 |
| 6 | Single-page app route changes announce the new page title | 2.4.2 |
| 7 | Animations can be paused or respect `prefers-reduced-motion` | 2.3.3 |

---

## Responsive and Touch

| # | Check | WCAG |
|---|---|---|
| 1 | Content is usable at 200% zoom without horizontal scrolling | 1.4.4 |
| 2 | Touch targets are at least 44x44 CSS pixels | 2.5.5 |
| 3 | Functionality is not dependent on device-specific interaction (hover-only tooltips, drag-only reordering) | 2.5.1 |
| 4 | Content does not disappear or overlap at any supported viewport size | 1.4.10 |

---

## Testing Process

### Automated Testing

Run these tools as part of CI or development workflow:

| Tool | What It Catches |
|---|---|
| axe-core | ~40% of WCAG violations (contrast, missing labels, ARIA errors) |
| Lighthouse accessibility audit | Similar coverage, integrated in Chrome DevTools |
| eslint-plugin-jsx-a11y | Catches common JSX accessibility mistakes at lint time |
| pa11y | CLI-based automated testing for CI pipelines |

### Manual Testing

Automated tools catch less than half of accessibility issues. Always do manual checks:

| Test | How |
|---|---|
| Keyboard-only navigation | Unplug mouse, Tab through the entire page, verify all actions are possible |
| Screen reader testing | Test with VoiceOver (macOS), NVDA (Windows), or Orca (Linux) |
| Zoom testing | Set browser zoom to 200%, verify layout does not break |
| Color blindness simulation | Use browser DevTools rendering emulation for color vision deficiencies |
| Reduced motion | Enable "prefers-reduced-motion" in OS settings, verify animations respect it |

### Testing Priority

| Priority | What to Test First |
|---|---|
| 1 | Forms and interactive workflows (highest user impact) |
| 2 | Navigation and page structure |
| 3 | Dynamic content updates (modals, notifications, live regions) |
| 4 | Images, media, and decorative content |
| 5 | Edge cases (zoom, reduced motion, high contrast mode) |

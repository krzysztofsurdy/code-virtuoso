---
name: accessibility
description: Web accessibility patterns and WCAG compliance — semantic HTML, ARIA attributes, keyboard navigation, color contrast, screen reader support, accessible forms, and testing strategies. Use when building accessible interfaces, auditing existing UIs, or establishing a11y standards.
user-invocable: false
---

# Web Accessibility

Accessibility is not a feature you bolt on at the end -- it is a quality attribute that must be considered from the first line of markup. Building accessible interfaces means that people with visual, motor, auditory, or cognitive disabilities can perceive, navigate, and interact with your application. It also means better usability for everyone: keyboard power users, people on slow connections, users with temporary injuries, and those in constrained environments.

## Why Accessibility Matters

| Dimension | Impact |
|---|---|
| **Legal** | Legislation in most jurisdictions (ADA, EAA, Section 508, EN 301 549) requires digital products to be accessible. Non-compliance carries litigation risk and financial penalties. |
| **Ethical** | Roughly 16% of the global population lives with some form of disability. Excluding them from digital services is a choice, not an inevitability. |
| **Business** | Accessible products reach a wider audience, improve SEO (structured content helps crawlers), reduce support costs, and correlate with higher overall usability scores. |
| **Technical quality** | Accessibility constraints force clean markup, proper semantics, and separation of concerns -- all of which improve maintainability. |

---

## WCAG Principles: POUR

The Web Content Accessibility Guidelines organize all success criteria under four principles. Every accessibility requirement maps to at least one.

| Principle | Question It Answers | Examples |
|---|---|---|
| **Perceivable** | Can users sense the content? | Text alternatives for images, captions for video, sufficient color contrast, resizable text |
| **Operable** | Can users interact with every control? | Keyboard operability, enough time to complete tasks, no seizure-triggering animations, clear navigation |
| **Understandable** | Can users comprehend the content and UI behavior? | Readable language, predictable navigation, input assistance and error messages |
| **Robust** | Does it work across assistive technologies? | Valid markup, proper use of ARIA, compatibility with screen readers and other tools |

---

## Conformance Levels

WCAG defines three levels. Each higher level includes all criteria from the levels below it.

| Level | Target Audience | Typical Requirement |
|---|---|---|
| **A** | Bare minimum -- removes the most severe barriers | Most legal and procurement requirements start here |
| **AA** | Industry standard -- addresses the majority of barriers for most users | Required by ADA, EAA, Section 508, and most organizational policies |
| **AAA** | Highest standard -- not always achievable for all content types | Aspirational goal; apply selectively where feasible |

For most projects, **target Level AA**. It covers the vast majority of real-world accessibility needs without imposing requirements that conflict with certain content types.

---

## Semantic HTML Fundamentals

Native HTML elements carry built-in semantics, keyboard behavior, and screen reader announcements. Using the right element is the single most effective accessibility technique.

| Instead Of | Use | Why |
|---|---|---|
| `<div onclick="...">` | `<button>` | Buttons are focusable, announce their role, and respond to Enter and Space |
| `<span class="link">` | `<a href="...">` | Links announce as "link," support middle-click, and appear in link lists |
| `<div class="header">` | `<header>`, `<nav>`, `<main>`, `<footer>` | Landmark elements let screen reader users jump between page regions |
| `<div class="list">` | `<ul>` / `<ol>` with `<li>` | Lists announce item count and position ("item 3 of 7") |
| `<div class="table">` | `<table>` with `<th>` | Table headers associate data cells with their labels for screen readers |
| Styled `<div>` for input | `<input>`, `<select>`, `<textarea>` | Native form controls have label association, validation, and assistive tech support built in |

### Heading Hierarchy

Headings create an outline that screen reader users navigate like a table of contents. Follow these rules:

- One `<h1>` per page that describes the page purpose
- Never skip levels (do not jump from `<h2>` to `<h4>`)
- Use headings for structure, not for visual styling -- CSS handles appearance

---

## Common Accessibility Issues

| Issue | Impact | Fix |
|---|---|---|
| Missing alt text on images | Screen readers announce the filename or nothing | Add descriptive `alt`; use `alt=""` for purely decorative images |
| Insufficient color contrast | Users with low vision cannot read text | Meet 4.5:1 ratio for normal text, 3:1 for large text (AA) |
| No keyboard access to interactive elements | Keyboard and switch users are completely blocked | Use native interactive elements or add `tabindex="0"` and key handlers |
| Missing form labels | Screen readers cannot announce what an input is for | Associate every input with a `<label>` using `for`/`id` or wrapping |
| Auto-playing media | Disorienting for screen reader users, harmful for those with cognitive disabilities | Never auto-play; if unavoidable, provide a visible pause/stop control |
| Missing skip link | Keyboard users must tab through the entire nav on every page | Add a skip-to-main-content link as the first focusable element |
| No focus indicator | Keyboard users lose track of their position on the page | Never remove `outline` without providing a visible custom alternative |
| Missing page language | Screen readers may mispronounce content | Set `lang` attribute on `<html>` (e.g., `lang="en"`) |
| Inaccessible dynamic content | Screen readers do not announce changes that happen after page load | Use ARIA live regions to announce dynamic updates |
| Missing document title | Screen reader users cannot identify the page when switching tabs | Set a unique, descriptive `<title>` for every page |
| Touch targets too small | Motor-impaired users cannot reliably tap small controls | Minimum 24x24 CSS pixels (AA), prefer 44x44 for comfortable interaction |
| Motion and animation | Can cause vestigo, nausea, or seizures | Respect `prefers-reduced-motion` media query; never flash more than 3 times per second |

---

## Accessible Forms

Forms are where accessibility failures cause the most real-world harm -- users cannot complete purchases, registrations, or critical workflows.

### Label Association

Every form control needs a programmatically associated label:

```html
<!-- Explicit association -->
<label for="email">Email address</label>
<input type="email" id="email" name="email" required>

<!-- Implicit association (wrapping) -->
<label>
  Email address
  <input type="email" name="email" required>
</label>
```

### Error Handling

- Display errors inline next to the relevant field, not only at the top of the form
- Use `aria-describedby` to associate error messages with their input
- Use `aria-invalid="true"` on fields that fail validation
- Provide clear, specific error text ("Enter an email in the format name@example.com" not "Invalid input")

### Required Fields

- Mark required fields with `required` attribute (for native validation) or `aria-required="true"` (for custom validation)
- Do not rely solely on color or an asterisk to indicate required status -- add text like "(required)"

---

## Color and Contrast

Color must never be the only means of conveying information. Pair it with text, icons, patterns, or other visual cues.

**Contrast ratios (WCAG AA):**

| Element | Minimum Ratio |
|---|---|
| Normal text (under 18pt / 14pt bold) | 4.5:1 |
| Large text (18pt+ / 14pt+ bold) | 3:1 |
| UI components and graphical objects | 3:1 |

**Quick wins:**
- Test with browser developer tools (Chrome DevTools shows contrast ratios on hover)
- Respect `prefers-color-scheme` for dark mode support
- Test designs with simulated color blindness (protanopia, deuteranopia, tritanopia)

---

## Reference Files

| Reference | Contents |
|---|---|
| [ARIA Patterns](references/aria-patterns.md) | When to use ARIA, roles and properties, widget patterns (tabs, modals, accordions, dropdowns), live regions, landmark roles |
| [Keyboard and Focus](references/keyboard-and-focus.md) | Tab order, arrow key navigation, focus trapping, skip links, focus restoration, visible focus indicators, touch targets |
| [Testing Strategies](references/testing-strategies.md) | Automated tools, manual testing checklist, screen reader testing, contrast verification, accessibility tree, CI integration |

---

## Integration with Other Skills

| Situation | Recommended Skill |
|---|---|
| Building REST or GraphQL APIs with accessible error responses | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for API design guidance |
| Security headers that affect accessibility (CSP, iframe restrictions) | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for security patterns |
| Testing accessible components with unit and integration tests | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for testing strategies |
| Performance optimization that does not sacrifice accessibility | Install `knowledge-virtuoso` from `krzysztofsurdy/code-virtuoso` for performance guidance |

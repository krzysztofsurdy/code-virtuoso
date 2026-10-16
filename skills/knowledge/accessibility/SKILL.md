---
name: accessibility
description: Web accessibility patterns and WCAG 2.1/2.2 compliance. Use to build accessible components, audit a UI for a11y issues, fix screen reader or keyboard problems, check contrast, or add ARIA.
allowed-tools: Read Grep Glob Bash
user-invocable: false
---

# Web Accessibility

Accessibility is a quality attribute, not a feature to bolt on at the end. Consider it from the first line of markup. Accessible interfaces let people with visual, motor, auditory, or cognitive disabilities perceive, navigate, and use your application. They also help keyboard power users, people on slow connections, users with temporary injuries, and anyone in a constrained environment.

## Why accessibility matters

| Dimension | Impact |
|---|---|
| **Legal** | Legislation in most jurisdictions (ADA, EAA, Section 508, EN 301 549) requires digital products to be accessible. Non-compliance carries litigation risk and financial penalties. |
| **Ethical** | Roughly 16% of the global population lives with some form of disability. Excluding them from digital services is a choice, not an inevitability. |
| **Business** | Accessible products reach a wider audience, improve SEO (structured content helps crawlers), reduce support costs, and correlate with higher overall usability scores. |
| **Technical quality** | Accessibility constraints force clean markup, proper semantics, and separation of concerns, which improves maintainability. |

---

## WCAG principles: POUR

The Web Content Accessibility Guidelines organize all success criteria under four principles. Every accessibility requirement maps to at least one.

| Principle | Question it answers | Examples |
|---|---|---|
| **Perceivable** | Can users sense the content? | Text alternatives for images, captions for video, sufficient color contrast, resizable text |
| **Operable** | Can users interact with every control? | Keyboard operability, enough time to complete tasks, no seizure-triggering animations, clear navigation |
| **Understandable** | Can users comprehend the content and UI behavior? | Readable language, predictable navigation, input assistance and error messages |
| **Robust** | Does it work across assistive technologies? | Valid markup, proper use of ARIA, compatibility with screen readers and other tools |

---

## Conformance levels

WCAG defines three levels. Each higher level includes all criteria from the levels below it.

| Level | Target audience | Typical requirement |
|---|---|---|
| **A** | Bare minimum, removes the most severe barriers | Most legal and procurement requirements start here |
| **AA** | Industry standard, addresses the majority of barriers for most users | Required by ADA, EAA, Section 508, and most organizational policies |
| **AAA** | Highest standard, not achievable for all content types | Aspirational; apply selectively where feasible |

For most projects, **target Level AA**. It meets most real-world needs and avoids requirements that conflict with some content types.

---

## Semantic HTML fundamentals

Native HTML elements carry built-in semantics, keyboard behavior, and screen reader announcements. Using the right element is the single most effective accessibility technique.

| Instead of | Use | Why |
|---|---|---|
| `<div onclick="...">` | `<button>` | Buttons are focusable, announce their role, and respond to Enter and Space |
| `<span class="link">` | `<a href="...">` | Links announce as "link," support middle-click, and appear in link lists |
| `<div class="header">` | `<header>`, `<nav>`, `<main>`, `<footer>` | Landmark elements let screen reader users jump between page regions |
| `<div class="list">` | `<ul>` / `<ol>` with `<li>` | Lists announce item count and position ("item 3 of 7") |
| `<div class="table">` | `<table>` with `<th>` | Table headers associate data cells with their labels for screen readers |
| Styled `<div>` for input | `<input>`, `<select>`, `<textarea>` | Native form controls have label association, validation, and assistive tech support built in |

### Heading hierarchy

Headings create an outline that screen reader users navigate like a table of contents.

- One `<h1>` per page that describes the page purpose
- Never skip levels (do not jump from `<h2>` to `<h4>`)
- Use headings for structure, not visual styling. CSS handles appearance

---

## Common accessibility issues

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
| Motion and animation | Can cause vertigo, nausea, or seizures | Respect `prefers-reduced-motion` media query; never flash more than 3 times per second |

---

## Accessible forms

Forms are where accessibility failures do the most damage: users cannot complete purchases, registrations, or other critical workflows.

### Label association

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

### Error handling

- Display errors inline next to the relevant field, not only at the top of the form
- Use `aria-describedby` to associate error messages with their input
- Use `aria-invalid="true"` on fields that fail validation
- Write clear, specific error text ("Enter an email in the format name@example.com", not "Invalid input")

### Required fields

- Mark required fields with the `required` attribute (native validation) or `aria-required="true"` (custom validation)
- Do not rely on color or an asterisk alone to indicate required status. Add text like "(required)"

---

## Color and contrast

Color must never be the only way to convey information. Pair it with text, icons, patterns, or other visual cues.

**Contrast ratios (WCAG AA):**

| Element | Minimum ratio |
|---|---|
| Normal text (under 18pt / 14pt bold) | 4.5:1 |
| Large text (18pt+ / 14pt+ bold) | 3:1 |
| UI components and graphical objects | 3:1 |

**Quick wins:**
- Check contrast with browser developer tools (Chrome DevTools shows ratios on hover)
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
| Building REST or GraphQL APIs with accessible error responses | `api-design` |
| Security headers that affect accessibility (CSP, iframe restrictions) | `security` |
| Testing accessible components with unit and integration tests | `testing` |
| Performance optimization that does not sacrifice accessibility | `performance` |

# Accessibility Testing Strategies

## The Testing Reality

Automated tools catch roughly 30-40% of accessibility issues. They excel at detecting missing alt text, contrast failures, missing labels, and invalid ARIA. But they cannot judge whether alt text is meaningful, whether navigation flows logically, or whether a custom widget is truly operable. A robust strategy combines automation, manual testing, and assistive technology validation.

---

## Automated Testing Tools

| Tool | Type | Strengths |
|---|---|---|
| **axe-core** | JS library | Most comprehensive (~80+ rules), integrates with all major test frameworks |
| **Lighthouse** | Browser/CLI | Built into Chrome DevTools, scores alongside performance and SEO |
| **pa11y** | CLI/CI tool | Simple command-line interface, good for pipeline smoke tests |
| **WAVE** | Browser extension | Visual overlay showing issues in context |
| **eslint-plugin-jsx-a11y** | React linter | Catches static JSX issues at write time |
| **eslint-plugin-vuejs-accessibility** | Vue linter | Catches template-level issues in Vue SFCs |

**What they catch:** missing alt, low contrast, missing labels, invalid ARIA, duplicate IDs, heading violations, empty buttons/links.

**What they miss:** alt text quality, keyboard flow logic, custom widget operability, reading order, error message helpfulness, context-dependent issues.

---

## Manual Testing Checklist

### Keyboard
- [ ] Tab reaches every interactive element
- [ ] Tab order matches visual layout
- [ ] Controls work with Enter, Space, arrow keys as appropriate
- [ ] Escape dismisses overlays and menus
- [ ] Visible focus indicator on every focused element
- [ ] Focus returns to trigger when overlays close
- [ ] Skip link bypasses repeated navigation

### Visual and Content
- [ ] Page readable at 200% zoom
- [ ] Content reflows at 320px width without horizontal scroll
- [ ] Color is never the sole information carrier
- [ ] All images have appropriate alt text
- [ ] Form errors are clear, specific, and associated with fields
- [ ] Heading hierarchy is logical (one h1, no skipped levels)

### Dynamic Content
- [ ] Status messages use live regions or `role="status"`
- [ ] Error alerts use `role="alert"` or `aria-live="assertive"`
- [ ] Loading states communicate progress to assistive tech
- [ ] Newly revealed content receives appropriate focus

### Media
- [ ] Videos have captions; audio has transcripts
- [ ] Auto-playing media can be paused
- [ ] Animations respect `prefers-reduced-motion`

---

## Screen Reader Testing

### Quick Reference

| Reader | Platform | Cost | Activation |
|---|---|---|---|
| **VoiceOver** | macOS/iOS | Free | Cmd+F5 (macOS) |
| **NVDA** | Windows | Free | Ctrl+Alt+N |
| **JAWS** | Windows | Commercial | Licensed install |
| **TalkBack** | Android | Free | Settings > Accessibility |

### VoiceOver Basics (macOS + Safari)
1. Cmd+F5 to enable. VO keys = Ctrl+Option.
2. VO+Right Arrow to move through content.
3. VO+U opens the rotor (headings, links, landmarks).
4. Interact with forms and widgets. Cmd+F5 to disable.

### NVDA Basics (Windows)
1. Ctrl+Alt+N to start. H = headings, D = landmarks, K = links, F = form fields.
2. Arrow keys to read through content. Tab for interactive elements.
3. Insert+Q to quit.

### What to Listen For
- Images: meaningful descriptions (or silence for decorative)
- Forms: label, required state, error messages announced
- Buttons/links: purpose clearly described
- Headings: navigable page outline
- Dynamic content: updates announced
- Custom widgets: role and state announced

---

## Color Contrast Verification

| Tool | Usage |
|---|---|
| **Chrome DevTools** | Inspect element > color picker shows ratio |
| **Firefox Accessibility Inspector** | Accessibility tab > contrast check |
| **Colour Contrast Analyser** | Desktop app with eyedropper |
| **WebAIM Contrast Checker** | Web tool -- enter hex values |

```js
// axe-core contrast check in tests
const results = await axe.run(document, { runOnly: ["color-contrast"] });
expect(results.violations).toHaveLength(0);
```

---

## Accessibility Tree Inspection

The accessibility tree is what assistive tech actually receives. Inspect it to verify:
- Every interactive element has an accessible name
- Roles match purpose (button is "button," not "generic")
- States are correct (expanded, selected, checked)
- Hidden decorations do not appear in the tree

**Chrome:** DevTools > Elements > Accessibility pane. **Firefox:** DevTools > Accessibility tab. **Safari:** Web Inspector > Elements > Accessibility.

---

## CI Integration

### axe-core with Playwright
```js
const { test, expect } = require("@playwright/test");
const AxeBuilder = require("@axe-core/playwright").default;

test("homepage a11y", async ({ page }) => {
  await page.goto("/");
  const results = await new AxeBuilder({ page }).analyze();
  expect(results.violations).toEqual([]);
});
```

### axe-core with Cypress
```js
describe("A11y", () => {
  it("home page passes", () => {
    cy.visit("/");
    cy.injectAxe();
    cy.checkA11y();
  });
});
```

### pa11y-ci (GitHub Actions)
```yaml
name: Accessibility
on: [pull_request]
jobs:
  a11y:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: npm ci && npm run build && npm run start &
      - run: npx wait-on http://localhost:3000
      - run: npx pa11y-ci --config .pa11yci.json
```

```json
{
  "defaults": { "timeout": 10000, "standard": "WCAG2AA", "runners": ["axe"] },
  "urls": ["http://localhost:3000/", "http://localhost:3000/login"]
}
```

### PHPUnit with Panther (Symfony)
```php
use Symfony\Component\Panther\PantherTestCase;

final class AccessibilityTest extends PantherTestCase
{
    public function testHomepageAccessibility(): void
    {
        $client = static::createPantherClient();
        $client->request('GET', '/');
        $violations = $client->executeScript(<<<'JS'
            return new Promise((resolve) => {
                const s = document.createElement('script');
                s.src = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js';
                s.onload = () => axe.run().then(r => resolve(r.violations));
                document.head.appendChild(s);
            });
        JS);
        self::assertEmpty($violations, sprintf('%d a11y violations found', count($violations)));
    }
}
```

---

## Testing Strategy Summary

| Layer | Catches | When |
|---|---|---|
| **Linter plugins** | Static markup issues | Every save / pre-commit |
| **Unit tests** (axe-core) | Component-level violations | Every CI build |
| **E2E tests** (Playwright/Cypress + axe) | Full-page violations with dynamic state | Every CI build |
| **Lighthouse CI** | Score regressions | Pull requests |
| **Manual keyboard testing** | Tab order, focus, interaction logic | Before every release |
| **Screen reader testing** | Reading order, announcements, widget operability | Before major releases |
| **User testing with disabled users** | Real-world usability gaps | Periodically |

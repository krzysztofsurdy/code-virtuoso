# Keyboard and Focus Management

## Why Keyboard Access Matters

Keyboard operability is a Level A requirement (WCAG 2.1.1). Users who depend on it include people with motor disabilities, power users, switch device users, and voice control users. If an interaction cannot be completed with a keyboard, those users are locked out.

---

## Tab Order

Default tab order follows DOM order of focusable elements (links, buttons, form controls, `tabindex="0"`).

| Rule | Explanation |
|---|---|
| DOM order should match visual order | CSS reordering (flexbox `order`, grid) can break logical tab sequence |
| `tabindex="0"` | Adds custom elements to tab order -- use only for interactive widgets |
| `tabindex="-1"` | Focusable via `.focus()` only, not reachable by Tab |
| Never use `tabindex` > 0 | Positive values override natural order and create maintenance problems |

---

## Arrow Key Navigation (Roving Tabindex)

Within composite widgets (tab lists, menus, tree views), only the active item has `tabindex="0"`. Others have `tabindex="-1"`. Arrow keys swap values and call `.focus()`.

**Vanilla JS:**
```js
function handleArrowNav(items, current, event) {
  let next = current;
  if (event.key === "ArrowDown" || event.key === "ArrowRight") next = (current + 1) % items.length;
  else if (event.key === "ArrowUp" || event.key === "ArrowLeft") next = (current - 1 + items.length) % items.length;
  else if (event.key === "Home") next = 0;
  else if (event.key === "End") next = items.length - 1;
  else return current;
  event.preventDefault();
  items[current].setAttribute("tabindex", "-1");
  items[next].setAttribute("tabindex", "0");
  items[next].focus();
  return next;
}
```

**React/TypeScript hook:**
```tsx
function useRovingTabIndex(count: number) {
  const [active, setActive] = useState(0);
  const refs = useRef<(HTMLElement | null)[]>([]);

  function onKeyDown(e: React.KeyboardEvent) {
    let next = active;
    if (e.key === "ArrowRight" || e.key === "ArrowDown") next = (active + 1) % count;
    else if (e.key === "ArrowLeft" || e.key === "ArrowUp") next = (active - 1 + count) % count;
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = count - 1;
    else return;
    e.preventDefault();
    setActive(next);
    refs.current[next]?.focus();
  }

  return { active, refs, onKeyDown, tabIndex: (i: number) => i === active ? 0 : -1 };
}
```

**Vue 3 composable:**
```ts
function useRovingTabIndex(count: Ref<number>) {
  const active = ref(0);
  const itemRefs = ref<HTMLElement[]>([]);

  function onKeyDown(e: KeyboardEvent) {
    let next = active.value;
    if (e.key === "ArrowRight" || e.key === "ArrowDown") next = (next + 1) % count.value;
    else if (e.key === "ArrowLeft" || e.key === "ArrowUp") next = (next - 1 + count.value) % count.value;
    else if (e.key === "Home") next = 0;
    else if (e.key === "End") next = count.value - 1;
    else return;
    e.preventDefault();
    active.value = next;
    itemRefs.value[next]?.focus();
  }
  return { active, itemRefs, onKeyDown };
}
```

---

## Skip Links

The first focusable element on the page, letting keyboard users bypass navigation.

```html
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  <header><!-- navigation --></header>
  <main id="main-content" tabindex="-1"><!-- content --></main>
</body>
```

```css
.skip-link {
  position: absolute;
  left: -9999px;
  top: auto;
  width: 1px;
  height: 1px;
  overflow: hidden;
}
.skip-link:focus {
  position: fixed;
  top: 0; left: 0;
  width: auto; height: auto;
  padding: 0.75rem 1.5rem;
  background: #1a1a2e;
  color: #fff;
  z-index: 10000;
}
```

**PHP/Twig base layout:**
```twig
<body>
  <a href="#main-content" class="skip-link">Skip to main content</a>
  {% block header %}{% include 'partials/header.html.twig' %}{% endblock %}
  <main id="main-content" tabindex="-1">{% block body %}{% endblock %}</main>
</body>
```

---

## Focus Trapping

When a modal is open, Tab/Shift+Tab must cycle within it. The native `<dialog>` with `.showModal()` handles this automatically -- prefer it over custom solutions.

**Vanilla JS trap (for custom dialogs):**
```js
function trapFocus(container) {
  const sel = 'a[href],button:not([disabled]),input:not([disabled]),select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';
  const focusable = Array.from(container.querySelectorAll(sel));
  const first = focusable[0], last = focusable[focusable.length - 1];

  function handle(e) {
    if (e.key !== "Tab") return;
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  }
  container.addEventListener("keydown", handle);
  first?.focus();
  return () => container.removeEventListener("keydown", handle);
}
```

**React component:**
```tsx
function FocusTrap({ children, active }: { children: React.ReactNode; active: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!active || !ref.current) return;
    const sel = 'a[href],button:not([disabled]),input:not([disabled]),[tabindex]:not([tabindex="-1"])';
    const prev = document.activeElement as HTMLElement;
    const items = Array.from(ref.current.querySelectorAll<HTMLElement>(sel));
    items[0]?.focus();

    function handle(e: KeyboardEvent) {
      if (e.key !== "Tab") return;
      const els = Array.from(ref.current!.querySelectorAll<HTMLElement>(sel));
      if (e.shiftKey && document.activeElement === els[0]) { e.preventDefault(); els[els.length-1].focus(); }
      else if (!e.shiftKey && document.activeElement === els[els.length-1]) { e.preventDefault(); els[0].focus(); }
    }
    ref.current.addEventListener("keydown", handle);
    return () => { ref.current?.removeEventListener("keydown", handle); prev?.focus(); };
  }, [active]);
  return <div ref={ref}>{children}</div>;
}
```

---

## Focus Restoration

When an overlay closes, return focus to the element that opened it. Store `document.activeElement` before opening, call `.focus()` on it after closing.

---

## Visible Focus Indicators

Never remove focus outlines without a visible alternative. WCAG 2.4.7 (AA) requires visible focus indicators. WCAG 2.4.11 (2.2) requires 2px minimum outline with 3:1 contrast.

```css
:focus-visible {
  outline: 3px solid #4a90d9;
  outline-offset: 2px;
}
:focus:not(:focus-visible) {
  outline: none;
}
@media (prefers-color-scheme: dark) {
  :focus-visible { outline-color: #7bb8f5; }
}
```

---

## Touch Target Sizes

| Level | Minimum | Notes |
|---|---|---|
| AA (WCAG 2.5.8) | 24x24 CSS px | Spacing can compensate for smaller targets |
| Best practice | 44x44 CSS px | Apple HIG and Material Design recommendation |

```css
button, a, [role="button"] {
  min-height: 44px;
  min-width: 44px;
}
```

---

## Keyboard Shortcuts

- Use shortcuts only when the relevant widget is focused (not global)
- Single-character shortcuts must be remappable or disableable (WCAG 2.1.4, Level A)
- Never override: Tab, Escape, Enter, Space, Ctrl+C/V/Z, or screen reader keys

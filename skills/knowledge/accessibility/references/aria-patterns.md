# ARIA Patterns

## The First Rule of ARIA

Before reaching for ARIA, ask: can a native HTML element do this? Native elements carry built-in semantics, keyboard behavior, and screen reader support. ARIA only changes announcements -- it does not add behavior. You must still implement keyboard handling and state changes yourself.

**Use ARIA when:** no native element fits (tabs, tree views, comboboxes), you need to describe relationships markup cannot convey, or dynamic content changes need announcing.

**Avoid ARIA when:** `<button>`, `<a>`, `<input>`, `<select>`, `<dialog>`, or `<details>` does the job.

---

## Roles, States, and Properties

| Category | Purpose | Examples |
|---|---|---|
| **Roles** | Define what an element is | `role="tab"`, `role="dialog"`, `role="alert"` |
| **States** | Current condition (can change) | `aria-expanded`, `aria-selected`, `aria-checked`, `aria-disabled` |
| **Properties** | Relationships or characteristics (typically static) | `aria-labelledby`, `aria-describedby`, `aria-controls`, `aria-haspopup` |

### Naming Priority

The browser resolves accessible names in this order: `aria-labelledby` > `aria-label` > native label (`<label>`, `alt`) > text content. Use `aria-labelledby` when visible text exists. Use `aria-label` only when no visible text is available.

---

## Landmark Roles

| HTML Element | Implicit Role | Purpose |
|---|---|---|
| `<header>` (top-level) | `banner` | Site header, logo, global nav |
| `<nav>` | `navigation` | Major navigation blocks |
| `<main>` | `main` | Primary content (one per page) |
| `<aside>` | `complementary` | Supporting content |
| `<footer>` (top-level) | `contentinfo` | Site footer, legal links |
| `<section>` with name | `region` | Named content section |
| None (use `role="search"`) | `search` | Search functionality |

Every visible content block should live inside a landmark so screen reader navigation does not miss it.

---

## Tabs

**HTML structure:**
```html
<div role="tablist" aria-label="Project settings">
  <button role="tab" id="tab-1" aria-selected="true" aria-controls="panel-1" tabindex="0">General</button>
  <button role="tab" id="tab-2" aria-selected="false" aria-controls="panel-2" tabindex="-1">Members</button>
</div>
<div role="tabpanel" id="panel-1" aria-labelledby="tab-1" tabindex="0"><!-- content --></div>
<div role="tabpanel" id="panel-2" aria-labelledby="tab-2" tabindex="0" hidden><!-- content --></div>
```

**Keyboard:** Arrow Left/Right move between tabs. Home/End jump to first/last. Tab moves into the active panel.

**React/TypeScript sketch:**
```tsx
function Tabs({ items }: { items: { label: string; content: React.ReactNode }[] }) {
  const [active, setActive] = useState(0);
  const refs = useRef<(HTMLButtonElement | null)[]>([]);

  function onKeyDown(e: React.KeyboardEvent, i: number) {
    let next = i;
    if (e.key === "ArrowRight") next = (i + 1) % items.length;
    else if (e.key === "ArrowLeft") next = (i - 1 + items.length) % items.length;
    else return;
    e.preventDefault();
    setActive(next);
    refs.current[next]?.focus();
  }

  return (
    <div>
      <div role="tablist">
        {items.map((item, i) => (
          <button key={i} ref={el => { refs.current[i] = el; }} role="tab"
            aria-selected={i === active} tabIndex={i === active ? 0 : -1}
            onKeyDown={e => onKeyDown(e, i)} onClick={() => setActive(i)}>
            {item.label}
          </button>
        ))}
      </div>
      <div role="tabpanel" tabIndex={0}>{items[active].content}</div>
    </div>
  );
}
```

---

## Modal Dialog

Modals must trap focus, dismiss with Escape, and return focus to the trigger on close. Prefer native `<dialog>` with `.showModal()` -- it provides focus trapping, Escape handling, and backdrop for free.

**HTML (native dialog):**
```html
<button id="open-btn" aria-haspopup="dialog">Delete account</button>
<dialog id="confirm" aria-labelledby="dlg-title">
  <h2 id="dlg-title">Confirm deletion</h2>
  <p>This cannot be undone.</p>
  <button id="cancel">Cancel</button>
  <button id="confirm-btn">Delete</button>
</dialog>
```

**Vue 3 sketch:**
```vue
<template>
  <button ref="trigger" @click="open = true" aria-haspopup="dialog">Delete</button>
  <Teleport to="body">
    <div v-if="open" role="dialog" aria-modal="true" aria-labelledby="t" @keydown.esc="close">
      <h2 id="t">Confirm deletion</h2>
      <button @click="close">Cancel</button>
      <button @click="confirm">Delete</button>
    </div>
  </Teleport>
</template>
<script setup lang="ts">
import { ref, nextTick } from "vue";
const open = ref(false);
const trigger = ref<HTMLButtonElement | null>(null);
function close() { open.value = false; nextTick(() => trigger.value?.focus()); }
function confirm() { /* action */ close(); }
</script>
```

---

## Dropdown Menu

**Key ARIA:** Trigger gets `aria-haspopup="true"` and `aria-expanded`. Container gets `role="menu"`. Items get `role="menuitem"` with roving tabindex.

**Keyboard:** Enter/Space/ArrowDown on trigger opens menu and focuses first item. ArrowUp/Down navigates items. Escape closes and returns focus. Type-ahead focuses matching items.

---

## Accordion

**HTML structure:**
```html
<div class="accordion">
  <h3>
    <button aria-expanded="true" aria-controls="s1" id="h1">Shipping</button>
  </h3>
  <div id="s1" role="region" aria-labelledby="h1">
    <p>We ship to 50+ countries. Standard delivery: 5-7 days.</p>
  </div>
  <h3>
    <button aria-expanded="false" aria-controls="s2" id="h2">Returns</button>
  </h3>
  <div id="s2" role="region" aria-labelledby="h2" hidden>
    <p>Returns accepted within 30 days.</p>
  </div>
</div>
```

**PHP/Twig rendering:**
```twig
{% for section in sections %}
  <h3>
    <button aria-expanded="{{ loop.first ? 'true' : 'false' }}"
            aria-controls="sec-{{ loop.index }}" id="hdr-{{ loop.index }}">
      {{ section.title }}
    </button>
  </h3>
  <div id="sec-{{ loop.index }}" role="region" aria-labelledby="hdr-{{ loop.index }}"
       {{ loop.first ? '' : 'hidden' }}>
    {{ section.body|raw }}
  </div>
{% endfor %}
```

---

## Live Regions

Live regions announce dynamic content changes to screen readers. The element must exist in the DOM before content is injected.

| Attribute | Behavior |
|---|---|
| `aria-live="polite"` | Announces after current speech finishes. Use for status updates. |
| `aria-live="assertive"` | Interrupts immediately. Reserve for errors and urgent messages. |
| `role="alert"` | Shorthand for assertive + atomic. Use for error messages. |
| `role="status"` | Shorthand for polite + atomic. Use for status updates. |

```html
<div aria-live="polite" id="search-status"></div>
<script>
  document.getElementById("search-status").textContent = "24 results found";
</script>
```

---

## Common ARIA Mistakes

| Mistake | Problem | Fix |
|---|---|---|
| `role="button"` on `<div>` without key handlers | Announced as button but Enter/Space does nothing | Use `<button>` or add tabindex and keydown |
| `aria-label` overriding visible text | Sighted and SR users get different info | Use `aria-labelledby` pointing to visible text |
| `aria-hidden="true"` on focusable elements | SR skips it but keyboard can still reach it | Remove from tab order too |
| Redundant ARIA on native elements | `<nav role="navigation">` double-announces | Omit the role -- native semantics suffice |
| Live region on a large container | Every change triggers announcements | Apply to the smallest possible element |

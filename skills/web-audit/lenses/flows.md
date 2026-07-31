# Lens: interactive states

The only lens that touches the page. **Requires `playwright`** — probe for it exactly as
`contrast.md` describes. Not found: report that this lens could not run, and stop. Never
install it.

## Hard limits

- **Only interactions the user named, plus the generic list below.** Never explore.
- **Never submit a form, never log in, never follow a destructive link** — `/logout`,
  anything under `/admin`, delete or purchase buttons. Reading a modal is fine; confirming
  one is not.
- The profile is fresh and has no session. A protected page shows the login screen; that
  is correct, not a defect. Do not try to get past it.
- Interacting changes the page. **Screenshot before and after** every interaction, and
  report which frame each finding came from.

## What to exercise

| Interaction | What is a defect |
|---|---|
| **Burger / mobile menu** | Does not open; opens behind other content; does not close; closes on the wrong thing; the page behind still scrolls. |
| **Modal, popup, dialog** | Renders behind its own overlay; cannot be closed; Escape does nothing; **scroll lock survives closing**; navigating away leaves the overlay or the lock behind. |
| **Lightbox / gallery** | Wrong item opens; arrows run past the end; closing loses the scroll position or the focus. |
| **Dropdown, accordion, tabs** | Clipped by `overflow: hidden`; opens off-screen at a narrow width; two panels open when one should be. |
| **Focus ring** | Invisible on keyboard focus; covered by a sticky header; disappears on the element that actually has focus. Press Tab — `:focus-visible` only paints for keyboard input. |
| **Hover state** | Nothing changes on an element that is clearly clickable, or the change moves neighbouring content. |
| **Filters, pagination, load-more** | State does not reset when it should; the control stays visible with nothing left to load; the list and the overlay disagree about what is in it. |

## Method

1. Capture the resting state first.
2. One interaction, one screenshot, one comparison. Never chain three actions and then
   look.
3. After each, check the things that break silently: page scroll still works, focus is on
   something sensible, nothing was left behind in the DOM.
4. Return to the resting state before the next interaction, or capture fresh.

## The trap this lens exists for

A defect that only exists **after** an interaction is invisible to every other lens and to
every static test. Route change with an overlay still open is the classic: the page under
it is correct, the overlay is orphaned, and no screenshot of a fresh load will ever show
it.

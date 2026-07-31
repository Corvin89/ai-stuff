# Lens: responsive

Needs **at least two widths**. Everything here is about what changes, or fails to change,
between them.

| Defect | How it shows |
|---|---|
| **Page scrolls sideways** | Content wider than the viewport at a narrow width. The single most common mobile bug. Confirm numerically — `scrollWidth > clientWidth` also names the offending node. |
| **Breakpoint discontinuity** | Correct at the narrowest and widest, broken in the middle: no longer mobile, not yet desktop. Always look at 768. |
| **Layout did not migrate** | A desktop multi-column grid still in columns at 360, each column a few characters wide. |
| **Navigation vanished** | The desktop nav is hidden below a breakpoint and no burger, menu button or alternative appeared. The links became unreachable — that is a blocker, not a nitpick. |
| **Fixed-width element** | One card, table, code block, image or embed keeps its desktop width while everything else reflows. |
| **Text did not reflow** | Headline set in viewport units overflowing its line, or body copy at desktop size on a phone. |
| **Media not constrained** | An image or iframe without `max-width: 100%` pushing the page wide. |
| **Sticky element eats the screen** | A header, banner or cookie bar taking a large share of a short viewport, leaving little content visible. |
| **Touch density collapse** | Controls that were comfortably apart on desktop stacked into a strip of adjacent tap targets. Sizes are measured by the `contrast` lens; here report only the visible crowding. |
| **Content reordered wrongly** | Flex or grid order putting the call to action above the thing it refers to, or an image before its caption. |

## Method

1. Open the frames for **each** width, narrowest first.
2. Describe what changed between adjacent widths before judging anything. A defect is a
   change that loses something — naming the change first stops you inventing one.
3. A layout that is identical at every width is itself worth a line: either the page is
   genuinely fluid, or media queries are not being applied at all.

## Traps specific to this lens

- **`--hide-scrollbars` changes the content width**, so a phantom ~15px overflow is a
  measurement artefact, not a defect. Confirm overflow numerically before reporting it.
- **A tall window lies about `100vh`.** Never judge a hero's height or a sticky header
  from a tall capture.
- The PNG is scaled: a 360px viewport at device scale 2 is a 720px file. **Report the
  viewport, never the file dimension.**

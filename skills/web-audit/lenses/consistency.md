# Lens: consistency across pages

Needs frames from **at least two routes** at the same width. If the run only covers one
route, say so and stop — this lens has nothing to compare.

| Defect | Detected by |
|---|---|
| **Spacing desync** | The same section type — hero, page header, footer — with different vertical rhythm on different pages. |
| **Unequal heights of equivalent cards** | The same component at different heights or paddings across pages, leaving ragged bottom edges. |
| **Typographic drift** | One semantic level — page title, card title, caption — rendered at different size or weight depending on the page. |
| **Inconsistent component states** | The primary button filled on one page and outlined on another; the same nav item active in two different styles. |
| **Navigation instability** | Header or footer height, logo size, or item order changing between pages — the page jumps when you navigate. |
| **Density outlier** | One page far denser or emptier than the rest, reading as a different product. |
| **Palette or elevation drift** | Shadows, surfaces or accent colours on one page outside what the rest of the set uses. |
| **Duplicate components** | Two visually different implementations of the same thing — two card styles, two breadcrumb styles. |

## Method

1. Put the frames for one width side by side, in navigation order.
2. Name the **shared** elements first — header, footer, page title, card grid. Those are
   the only things a comparison is valid for.
3. Compare shared elements only. Two different pages *should* look different; that is not
   drift.

## The rule that keeps this lens honest

**Every finding must cite both places.** "Card padding is inconsistent" is not a finding.
"Card padding on `/pricing@1440` is visibly larger than the same card on `/features@1440`"
is. No citation, no finding — this is the same test that separates `major` from `minor` in
`SKILL.md`, and here it applies to everything.

If a treatment appears consistently three times or more, it is the house style, even when
you would have chosen otherwise.

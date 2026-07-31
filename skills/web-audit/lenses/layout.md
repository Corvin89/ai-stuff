# Lens: layout

What a single rendered frame can prove on its own. Every row below is decidable from
pixels — that is why it is here and other things are not.

| Defect | Why it matters |
|---|---|
| **Overlap / collision** | Two elements on the same pixels. Information destroyed. Highest value — and the most common false positive, so zoom first. |
| **Clipped or cut text** | Glyphs sliced by a container edge, or truncation with no ellipsis. Reads as broken code, not as a choice. |
| **Horizontal overflow** | Content wider than the viewport. Usually an unconstrained image, table or `min-width`. |
| **Unreadable text** | Report only when you genuinely cannot read it. Merely "lowish" belongs to the contrast lens, which measures. |
| **Broken / missing image** | Alt box, broken-file icon, empty grey rectangle. Ships as obvious failure. |
| **Distorted image** | Logo or avatar squashed or stretched — wrong aspect ratio. |
| **Placeholder leakage** | Lorem ipsum, `TODO`, `{{name}}`, `undefined`, `NaN`, `Invalid Date`, raw ISO timestamps. Never intentional. |
| **Unstyled render** | Default serif, blue underlined links, native buttons. The stylesheet failed — **one** finding, not fifty. |
| **Stacking fault** | Sticky header over body text, modal behind its own overlay, dropdown clipped by `overflow: hidden`. |
| **Text on image with no scrim** | Legible over one image, illegible over the next. The image changes, the text does not. |
| **Collapsed or empty region** | A zero-height section, or a blank band far larger than any other gap. A data or conditional-render failure, not a spacing preference. |
| **Duplicated element** | The same heading, card or nav rendered twice. |
| **Local misalignment** | Elements that clearly share an intended edge or baseline and do not: icon vs label inside a button, card titles in one row, form label vs input. |
| **Inconsistency inside one frame** | Two cards side by side with different radius, shadow, padding or border; two icon families in one toolbar. Visible without comparison, so it belongs here. |
| **Stuck state** | Skeleton, spinner or "loading…" left in a finished render. |

## Out of this lens

- Anything needing a second frame → `consistency`.
- Anything needing a number → `contrast`.
- Anything needing a click, hover or keypress → `flows`.
- Wording, tone, typos → `copy`.

## Region argument

If the run named a region (`header`, `footer`, `hero`), audit that region and say
explicitly in the report header that the rest of the frame was not reviewed. Do not
quietly widen the scope, and do not quietly narrow it either.

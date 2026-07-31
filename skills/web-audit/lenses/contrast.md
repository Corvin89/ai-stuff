# Lens: contrast and measurable accessibility

**This lens produces numbers or it produces nothing.** Guessing a contrast ratio from a
screenshot is the single easiest way to make this whole tool untrustworthy: the value is
plausible, wrong, and impossible for the reader to tell apart from a real one.

## Step 1 — can you measure at all?

```bash
node -e "require.resolve('playwright')" 2>/dev/null && echo yes
NODE_PATH=$(npm root -g) node -e "require.resolve('playwright')" 2>/dev/null && echo yes-global
```

Also probe any local checkout: `playwright` may exist in another project's
`node_modules`. If found, run the probe with `NODE_PATH` pointing at that directory.

**Found:** run `scripts/probe.mjs` and report measured values, saying where each came from.

**Not found:** say so in the report header, in one line, and switch to the qualitative
pass below. **Never install it** — that is the user's decision, not yours.

Qualitative pass: report only text you genuinely cannot read, as
`unreadable, not measured — playwright unavailable`. No ratios, no "approximately".

## Step 2 — thresholds

In `SKILL.md`. They cover most verdicts without touching the network.

## Step 3 — what the probe checks

`scripts/probe.mjs <url>` returns JSON:

- **contrast** of every text node against its *effective* background, with the resolved
  colours it used, split into two lists:
  - `contrastFailures` — a real background colour was found and the text fails against it.
    These are findings.
  - `contrastUnmeasurable` — no opaque colour sits behind the text: gradient-filled
    buttons, text over a photo, glyphs painted by `background-clip: text`. **The probe
    refuses to invent a number here.** Do not report these as failures — and do not ignore
    them either: open the frame and look. Report only the ones you genuinely cannot read,
    as `unreadable on inspection, not measurable`. A long unmeasurable list on a
    gradient-heavy design is expected, not a problem;
- **tap targets** below the minimum, with their measured box;
- **`scrollWidth` vs `clientWidth`**, plus the widest offending element;
- **images** that failed to load (`naturalWidth === 0`);
- **console errors** and failed requests.

## Step 4 — reading the output honestly

- **A ratio of exactly 1.00 with identical foreground and background is not a defect — it
  is gradient text.** `background-clip: text` paints the glyphs from a gradient and sets
  `color` to the backdrop colour, so the computed values are identical and every measuring
  tool reports total failure. Measured on a real site: all four "failures" in the first run
  were this. Check for `background-clip` before reporting, and fall back to looking at the
  frame — if you can read it, it passes.
- **A gradient, image or semi-transparent layer behind text has no single background
  colour.** The probe reports the sampled value; say that it was sampled, and do not
  report a hard fail on a borderline number over a photograph.
- **Inline links inside a paragraph are exempt from the tap-target minimum** (WCAG 2.5.8
  inline exception). Nav links set as inline text routinely measure ~20px tall and are not
  findings on that basis alone.
- **Disabled controls, pure decoration and logotypes are exempt** from 1.4.3. Check the
  element's role before reporting it.
- **Text rendered inside an image** cannot be measured at all. Report it as visual only.
- A tap target under the minimum may still pass **via the spacing exception** — measure
  the gap before calling it a failure.

If an exception or a definition decides the verdict, `references/sources.md` has the
one link that settles it. One per finding, two per run.

## Out of this lens

ARIA, roles, labels, alt text, heading order, keyboard traps and screen-reader behaviour.
They are real accessibility work, but nothing here can see them, and half-measuring them
produces exactly the invented numbers this lens exists to prevent.

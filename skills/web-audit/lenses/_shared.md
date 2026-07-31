# Rules every lens obeys

Read this alongside your own lens file, and nothing else from `lenses/`.

## Evidence

**No PNG, no audit.** Never conclude anything about rendering from CSS, HTML or JS. If
capture failed, report the failure and stop — a report "from the code" is a lie about work
done. (`copy` is the exception: it reads text, and captures nothing.)

**Look at every frame.** List the files, then open each with the Read tool, one call per
file. State `reviewed N of N`. Different numbers mean you are not finished.

**Never state a number you did not read from a tool's output.** The eye cannot compute a
contrast ratio from a downscaled screenshot, and the model will invent a plausible one.
Either measure it and say where the value came from, or write "verify the contrast". There
is no middle option.

**"No defects found" is a complete result.** Do not top the list up to a round number.

## Four tests before a finding exists

All four, or the finding is dropped silently. Never report one "with low confidence" — a
caveat still costs someone a manual check, so it buys nothing.

1. **Zoom before claiming geometry.** Overlap, misalignment and blur are manufactured by
   downscaling and compression. Re-crop the region at full resolution and look again. Most
   overlap reports die here.
2. **Name the evidence**: screenshot file, viewport width, visible element. Missing any of
   the three means it is not a finding.
3. **Rule out state**: empty dataset, logged-out view, mid-load capture, a deliberately
   long test string. Half the "defects" in an early frame are an unfinished page load.
4. **Rule out intent.** A treatment repeated consistently three or more times is a design
   decision. Report it only if something is actually lost.

Never evidence: font antialiasing, scrollbars, cursor, compression noise, cards of
different height holding different content, missing hover states, the far edge of a
stitched capture. Taste is out of scope — "I'd add whitespace", "looks dated" are not
defects.

## Severity — a procedure, so two agents agree

First "yes" wins.

| | Test |
|---|---|
| **blocker** | Is a **function** lost or unreachable — a control that cannot be pressed, text that cannot be read, a page that cannot be scrolled to? |
| **major** | Is **legibility** lost while the function still works? Two glyphs overlapping into an unreadable mark, a label obscured but still clickable. Measured case: a modal's close button drawn exactly over a menu button — the close button worked and the menu was correctly inert under the overlay, so nothing was unreachable, but the two symbols merged into one unreadable shape. |
| **major** | Nothing lost at all, but **can you cite another place in this same build that does it differently?** No citation, no `major`. |
| **minor** | Consistent with the build; you are comparing it to an ideal. |

**Before calling an overlap a blocker, find out what actually receives the click.**
`document.elementFromPoint(x, y)` answers it; looking at the frame does not. An element
painted over another is often covered by a modal overlay that is doing its job — the
picture shows a collision, the DOM shows correct behaviour.

All blockers individually. Majors grouped by root cause. Minors as one closing list, five
lines maximum. Forty equal-weight remarks is a failed audit.

## Thresholds — no network needed

| | | |
|---|---|---|
| Text contrast | **4.5:1** | WCAG 1.4.3 AA |
| Large text (≥24px, or ≥18.66px bold) | **3:1** | WCAG 1.4.3 AA |
| Non-text (borders, icons, state indicators) | **3:1** | WCAG 1.4.11 AA |
| Tap target minimum | **24×24 CSS px** | WCAG 2.5.8 AA |
| Tap target comfortable | **44×44 CSS px** | WCAG 2.5.5 AAA |
| No scrolling in two directions | **320 × 256 CSS px** | WCAG 1.4.10 AA |

**Opening no external source is the normal outcome of a run.** Only when a finding turns on
an *exception or a definition* — is this large text, is this icon a UI component, are these
targets spaced far enough apart — open `references/sources.md`. One link per finding, two
per run, then stop.

## Report

One finding per line, JSONL, one file per lens — they merge with `cat`.

```json
{"id":"pricing/360/overflow/plan-card-3","lens":"layout","route":"pricing","viewport":360,
 "severity":"blocker","what":"third pricing card runs past the right edge; page scrolls sideways",
 "where":"third pricing card, right edge","shot":"shots/pricing@360.png"}
```

`id` is `<route>/<viewport>/<code>/<region>`, so the same breakage found by two lenses
deduplicates itself. `where` is a visible landmark, not a CSS selector: you looked at a
picture, not at the DOM. First line of your file is a header — lens, routes, frames,
`reviewed N of N`, whether `playwright` was found, sources opened.

## Traps that produce false findings

- **Dev server down → a valid PNG of Chrome's error page.** Every check passes and you
  audit an error screen. Look at frame one before trusting the rest.
- **Lazy images.** A virtual time budget fast-forwards timers, not IntersectionObserver.
  Below-fold images stay unloaded — judge the fold only, or scroll via playwright.
- **Fonts not swapped.** With `font-display: swap` the first paint is deliberately the
  fallback. A typography complaint from a too-early frame describes nothing real.
- **Animations mid-flight** make elements look missing or displaced.
- **`--hide-scrollbars` changes content width.** Without it macOS headless draws a ~15px
  scrollbar and a 360px window yields 345px of content — a phantom overflow. With it you
  lose the visual cue. Confirm overflow numerically instead.
- **A tall window lies about `100vh`**: hero sections become window-tall, sticky headers
  never stick. Such frames are not layout evidence.
- **A fresh profile has no session**, so protected pages shoot the login screen. That is
  correct isolation, not a defect.
- The PNG is scaled: a 360px viewport at device scale 2 is a 720px file. **Report the
  viewport, never the file dimension.**

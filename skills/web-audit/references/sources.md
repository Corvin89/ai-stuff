# Source catalogue

Opened only when a finding turns on an **exception or a definition** that the built-in
thresholds in `SKILL.md` cannot settle. If the thresholds give a clear verdict, this file
is not needed either.

**One link per finding. Hard cap: two per run.** Not "related" links, not "while I'm
here". Fetch the named section, not the whole page — several of these run past 12,000
words.

| Read when you need to decide | URL | Read only |
|---|---|---|
| General first pass, no specific finding yet — **this row excludes all others** | `https://www.w3.org/WAI/tips/designing/` | whole page, ~2500 words |
| Is this large text? a logo? an inactive control? | `https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html` | Exceptions + Key Terms |
| Is this icon or field border a "UI component" or a "graphical object"? | `https://www.w3.org/WAI/WCAG22/Understanding/non-text-contrast.html` | the two definitions |
| Are these small targets spaced far enough to be exempt? | `https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html` | the five exceptions |
| Does this table or carousel overflow actually violate reflow? | `https://www.w3.org/WAI/WCAG22/Understanding/reflow.html` | two-dimensional exception |
| Is a focus ring covered by a sticky header a failure here? | `https://www.w3.org/WAI/WCAG22/Understanding/focus-not-obscured-minimum.html` | whole page, it is short |
| Line length or leading, where WCAG has no answer — **advisory, not a criterion** | `https://practicaltypography.com/typography-in-ten-minutes.html` | ~600 words |

The last row is one author's opinion, not a standard. Never report a deviation from it as
a violation.

## When a link fails

Do not search for a replacement, and do not open a neighbouring row instead. Fall back to
the built-in thresholds, rule on those, and tag the finding
`source unverified, ruled by built-in WCAG <number>`.

The **criterion numbers are the stable identifier**; only the URL paths rot. Every
`/WCAG22/` path will move when a new version ships — that is a mechanical find-and-replace,
not a research task. If two links fail in one run, note it in the report header in one
line and carry on.

## Deliberately excluded

Checked and left out, so nobody re-adds them:

- **Material Design 3** and **Apple HIG layout** — both render through JavaScript and
  return an empty document to a fetch. Their numbers (48×48 dp, 44×44 pt) are constants in
  `SKILL.md` instead.
- **The WCAG specification itself** and **quickref** — one giant document and a JS filter
  app. The success-criterion wording is already inlined.
- **WCAG at a Glance** — a live page, but a paraphrase with no numbers in it.
- **MDN Responsive Design** — a teaching module that deliberately refuses to name
  breakpoints. Reflow covers what an audit actually needs.
- **WAI tutorials on forms and images** — about markup (`<label for>`, `alt`), which a
  screenshot cannot show. A broken `<img>` needs no source: you can see it.
- Aggregator sites paraphrasing W3C — they get the details wrong.

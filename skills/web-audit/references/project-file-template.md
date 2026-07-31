# Project file template

Offer this **after** the first run, never before it. Nothing in the skill needs configuring
to start, and a setup step in front of the first screenshot is a reason not to use the
skill at all.

Write it to `.claude/web-audit.md` in the project.

```markdown
# Web audit contract — <project>

Read by the `web-audit` skill. Mechanics live in the skill; only what is specific to
this project lives here.

## Serving
- Start: `<command>`              # blank if the server is expected to be running already
- URL: `http://localhost:<port>`
- Ready when: `<path that returns 200>`

## Routes
| Slug | Path | State needed |
|---|---|---|
| home | `/` | — |
| ... | ... | logged in as <fixture> / empty state / list with 20 items |

## Viewports
`<width>` … — this project's real breakpoints, narrowest first.
Only override the default 360 / 768 / 1440 if the project actually breaks elsewhere.
Every extra width multiplies frames, reviews and false positives.

## Intentional — not defects

**The section this file exists for.** Grows only from findings the user waved off. Each
line names what was flagged and why it stays. Without it, every future run returns the
same false positives and the reports stop being read.

- <e.g. The hero headline is clipped at 360px by design; the second line is decorative.>
- <e.g. Caption contrast is 3.2:1 — approved by the designer, do not report again.>

## Acceptance criteria
- Palette: `<hex list>` — anything outside it is a finding
- Content max-width: `<px>`
- Type scale: `<sizes>`
- Minimum tap target: `<px>`

## Known defects
| ID | Status | Note |
|---|---|---|
| ... | accepted / deferred to <ticket> | ... |

## Output
- Screenshots: `.claude/audit/shots/`
- Reports: `.claude/audit/<run-id>/`
```

Add `.claude/audit/` to `.gitignore` — screenshots are build artefacts, and a page captured
with real data does not belong in a repository.

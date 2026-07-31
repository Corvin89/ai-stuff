# web-audit

Audits a running site by **looking at it** — screenshots at several viewports, reviewed as
images — instead of reading its CSS.

Finds overlapping and clipped text, horizontal overflow, broken images, layout that fails
between breakpoints, unreadable contrast, states that only break after you click something.

## Install

```bash
bash scripts/install.sh          # symlink: updates arrive with git pull
bash scripts/install.sh --copy   # copy: edit freely, no upstream changes
```

The installer reports what this machine can do and installs nothing on its own. If a
browser binary is missing it prints the command and stops — downloading hundreds of
megabytes is your decision, not the tool's.

## Requirements

| | Needed for | If missing |
|---|---|---|
| `chrome-headless-shell` | everything | the skill cannot run: `npx playwright install chromium-headless-shell` |
| `playwright` | measured numbers, interactive states | `contrast` reports without numbers, `flows` is skipped |

Your everyday browser is **never launched and never killed**. Captures use a separate
binary with a throwaway profile, so your tabs, sessions and cookies are untouched — and
never appear in a screenshot.

## Use

```
/web-audit <parameter> [route|region]
```

| Parameter | Lenses | Widths |
|---|---|---|
| `all` | all six | 360 · 768 · 1440 |
| `mobile` | layout, responsive, contrast, flows | 360 · 768 |
| `desktop` | layout, consistency, contrast | 1440 |
| `view` | layout | 360 · 768 · 1440 |
| `mobile-view` | layout | 360 |
| `desktop-view` | layout | 1440 |
| `layout` `responsive` `contrast` `consistency` `flows` `copy` | the one named | all three |

Running with no parameter starts nothing — it prints this table and asks. A full run is
six lenses across three widths.

```
/web-audit mobile              everything mobile-relevant, both narrow widths
/web-audit view /pricing       layout only, one page, three widths
/web-audit layout header       layout only, header only
/web-audit flows               interactive states: menus, modals, focus
/web-audit copy /about         text of one page, no screenshots taken
```

**Routes** start with `/` or are a full URL. **Regions** are bare words (`header`,
`footer`, `hero`). A file path is never turned into a route silently — you get the guessed
address to confirm.

## Lenses

| | |
|---|---|
| `layout` | What one frame proves: overlap, clipping, overflow, broken images, placeholder text. In every group. |
| `responsive` | What changes, or fails to change, between widths. Needs two or more. |
| `contrast` | Measured: contrast ratios, tap-target sizes, overflow, broken images, console errors. Produces numbers or nothing. |
| `consistency` | Drift between pages: spacing, card heights, type scale, component states. Needs two or more routes. |
| `flows` | The only lens that clicks. Menus, modals, lightboxes, focus rings, filters. |
| `copy` | The only lens that judges words. Placeholder text, broken interpolation, terminology drift. |

## What it will not do

Fix anything. Read your source to explain a defect. Audit performance, SEO or bundle size.
Report taste. Invent a contrast ratio it did not measure. Touch a URL you did not name.

## Project file

Optional, and offered only **after** a run — never as setup before one. It records your
routes, your real breakpoints, and above all the findings you waved off, so the next run
does not report them again.

## The rules that make the output trustworthy

- **No screenshot, no audit.** Never a conclusion about rendering drawn from source code.
- **Every frame is opened**, and the report says `reviewed N of N`.
- **No invented numbers.** Measured and attributed, or described in words.
- **Every finding names a file, a viewport and a visible element**, or it is dropped.
- **"No defects found" is a complete result.** The list is never padded.

## Licence

[MIT](LICENSE) — copyright (c) 2026 Alexander Kutiy.

The licence file sits in this folder, not only at the repository root, so it travels with
the skill when you copy the folder out. MIT asks for the notice to be included in copies,
and a link back to a repository is not an inclusion.

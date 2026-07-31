# Lens: copy

The only lens that judges words. It **captures nothing** — read the text from the rendered
frames if they exist, otherwise fetch the pages and read the visible text. Never run it
implicitly: it belongs to `all` and to an explicit `copy` request, and to nothing else.

Mixing wording notes into a layout report buries the defects that break the page. Keep the
output separate.

| Defect | Why it matters |
|---|---|
| **Placeholder text shipped** | Lorem ipsum, `TODO`, "Your headline here", sample names, `example@example.com`. Never intentional. |
| **Broken interpolation** | `{{name}}`, `%s`, `undefined`, `NaN`, `Invalid Date`, a raw ISO timestamp where a date should be. |
| **Untranslated or mixed language** | One string in the wrong language, or a language switch mid-page. |
| **Spelling and grammar** | Only genuine errors. Regional spelling is not an error — pick the variant the rest of the site uses and check consistency, not preference. |
| **Terminology drift** | The same thing called three names — "workspace", "project", "board". The most common real find, and invisible until you list the terms. |
| **Inconsistent capitalisation** | Title Case here, sentence case there, in the same class of element — headings, buttons, nav items. |
| **Label does not match destination** | A button saying "Book a call" that opens a contact form. |
| **Truncated meaning** | Text cut by its container so the sentence changes meaning. Report the wording; the clipping itself belongs to `layout`. |
| **Unsupported claim** | Numbers, awards, client names or guarantees on a site with nothing behind them. Flag; do not rewrite. |
| **Empty-state silence** | A list, search or error view with no explanatory text at all. |

## Rules

- **Report, do not rewrite.** Suggest a replacement only when asked. A defect report the
  user can act on beats a rewrite they must review.
- **Style is not a defect.** Tone, voice, sentence length and word choice are decisions.
  Report them only when the same page contradicts itself.
- **Judge the rendered text, not the source.** A string in the codebase may be unused, and
  a visible string may come from data.
- If a claim is legally or factually risky — a guarantee, a certification, a named client —
  say so plainly and once. That is worth interrupting for; wording preferences are not.

---
name: web-audit
description: Audits a running site by looking at rendered screenshots. Invoked manually with one parameter - /web-audit all | mobile | desktop | view | mobile-view | desktop-view | layout | responsive | contrast | consistency | flows | copy - optionally followed by a route (/pricing) or a region (header). Reports defects; never fixes them, never audits source code, never touches a URL the user did not name.
argument-hint: [all|mobile|desktop|view|mobile-view|desktop-view|layout|responsive|contrast|consistency|flows|copy] [url|/route|region]
---

# Web audit

A router. It picks lenses, captures frames once, dispatches one subagent per lens, and
merges their findings. **The defect knowledge lives in `lenses/`** — nothing in this file
describes a defect.

**Scope.** Reports what is wrong. Does not fix anything, does not open source files to
explain a defect, does not cover performance, SEO, bundle size, or accessibility a
screenshot cannot show (ARIA, screen readers). Hand back the report and stop.

## Invocation

Invoked as `/web-audit <parameter> [url|route|region]`. The user typed: `$ARGUMENTS`

| Parameter | Lenses | Widths |
|---|---|---|
| `all` | all six | 360 · 768 · 1440 |
| `mobile` | layout, responsive, contrast, flows | 360 · 768 |
| `desktop` | layout, consistency, contrast | 1440 |
| `view` | layout | 360 · 768 · 1440 |
| `mobile-view` | layout | 360 |
| `desktop-view` | layout | 1440 |
| `layout` `responsive` `contrast` `consistency` `flows` `copy` | the one named | all three; `copy` captures nothing |

`layout` is in every group — without it there is no audit.

**No parameter: run nothing.** Print the table and ask. A full run is six lenses across
three widths; it should not start by accident.

### Second argument — route or region

Parsed by shape, never by guessing:

| Written | Meaning |
|---|---|
| `http://localhost:8080/` | full address — this sets the base for the run; other routes are discovered from it and confirmed |
| `http://localhost:8080/pricing` | full address of one page; audit that page only |
| `/pricing`, `/docs/intro` | a path, appended to the base URL |
| `header`, `footer`, `hero` | a region of the page, not a route |
| anything that looks like a file | **do not derive a route from it** |

A bare word is always a region; a route starts with `/` or is a full URL.

A file does not identify a URL: file-based routers each have their own convention,
config-based routing has none, and a dynamic segment needs a parameter value. Show the
address you would guess and wait for the user to confirm it.

**Which routes exist** comes from the project file if there is one; otherwise collect
same-origin links from the base page, show the list, and get confirmation before shooting.
Never hardcode routes.

## Rule 0 — never shoot an address nobody confirmed

Finding candidates is fine. **Acting on one the user has not agreed to is not.** A wrong
port means auditing someone else's project and reporting defects they will hunt for in
their own code; a wrong host means real requests to a live site.

When no address was given, work down this list and stop at the first that answers:

1. **The project file** `.claude/web-audit.md` — if it records a URL, use it and say which
   file it came from. No question needed: the user already answered it once.
2. **What is actually listening now**, which beats any config:
   ```bash
   lsof -iTCP -sTCP:LISTEN -P -n | grep -E 'node|bun|deno|python|ruby|php'
   ```
   `curl -s` each candidate and read its `<title>`. Present them as `port → title` — the
   title is what identifies the project; the port proves nothing.
3. **The project's own config** — dev script in `package.json`, `server.port` in the
   bundler config. A declared port, not a running one: offer it, and say it is unverified.

Then **show what you found and let the user pick**. One candidate is still a candidate:
present it and wait. Nothing found — say so and ask; do not start a dev server unless asked.

Once confirmed, offer to record it in the project file so the question is asked once per
project, never again.

- No confirmation needed beyond the above: `localhost`, `127.0.0.1`, `[::1]`, `*.local`.
- Any other host: stop and get explicit confirmation in this same turn.
- A host containing `stage`, `prod`, `www`, or a public IP: stop even when the user named
  it, and confirm they know it is a live site.
- `curl -sI` first; show the status and `<title>`. A title that does not match their
  project means another app owns that port — stop.
- **GET only.** No forms, no logins, no destructive links. Only `flows` interacts, and only
  with what the user named.

Do not start a dev server unless asked; check the port is already listening.

## Never touch the user's browser

They are working in it right now.

- **Never launch Chrome, Chromium, Edge or Brave from `/Applications`.** Only the
  standalone `chrome-headless-shell`. Missing? Stop and tell the user what to install —
  never install it yourself.
- **Always `--user-data-dir` on a fresh temp directory.** Without it the binary finds the
  default profile's singleton lock, hands your URL to the *running* browser over a socket
  and exits 0: no PNG, a success exit code, and a stray tab in the user's window. It also
  keeps their cookies out of your screenshots.
- **Never attach to a live browser**: no `connectOverCDP`, no `--remote-debugging-port`
  against a running instance, no browser MCP whose `executablePath` is the system Chrome.
  Such a config existing in the project is not permission to use it.
- **Kill only the PID you launched.** `killall`, `pkill -f chrome`, `pkill -f node` are
  forbidden, including "just in case" before starting. Sweep strays by matching your own
  temp profile path.
- Resolve the binary by glob, never by a pinned revision — the number differs per machine.

## Run

```bash
bash scripts/capture.sh <url> <out-dir> [width ...]
```

Capture **once** for the whole run; the script is idempotent, so overlapping lenses cost
nothing. It refuses to start if the server does not answer, checks the PNG signature and
warns on tiny files.

**Look at the first frame before dispatching anything.** A dead dev server yields a
perfectly valid PNG of Chrome's own error page, and every lens would then audit an error
screen.

Then dispatch **one subagent per selected lens**. Each is told to read `lenses/_shared.md`
and its own lens file — and nothing else from `lenses/`. Give it the frame paths, the
route list, and the region if one was named. Findings come back as JSONL, one file per
lens; merge with `cat` and sort by severity.

## Project file

Nothing needs configuring to start. **After** a run, once the routes are known and the user
has waved some findings off, offer to write `.claude/web-audit.md` from
`references/project-file-template.md`. Its one indispensable section is *"intentional — not
defects"*: without it every future run returns the same false positives and the reports
stop being read.

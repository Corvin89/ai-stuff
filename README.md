# ai-stuff

Reusable skills for Claude Code.

A skill is a folder with a `SKILL.md` inside. Claude Code picks it up and applies it when
the task matches — no dependencies to install, no configuration, just instructions and,
where useful, a helper script alongside.

## Install

Skills live in `~/.claude/skills/`. Clone this repository wherever you keep your
checkouts, then, from its root, pick one of two ways.

**Symlink — to receive updates with `git pull`:**

```bash
ln -s "$PWD/skills/<skill>" ~/.claude/skills/<skill>
```

`$PWD` is not decoration: a symlink target is resolved relative to the link, not to the
shell, so a relative path here produces a link that points at nothing.

**Copy — to edit freely without pulling anyone else's changes:**

```bash
cp -R skills/<skill> ~/.claude/skills/
```

A skill becomes available in the next Claude Code session. Some skills ship their own
installer — see their README.

## Skills

### `ai-image-set`

Generates a coherent **set** of images — for a gallery, portfolio, catalogue or
placeholder content — through a free service with no key and no account.

The generating is easy; the culling is the work. What the skill carries is the measured
experience of where this breaks:

- the service allows **one concurrent request per IP**, and answers a second one with an
  error that gets saved under your `.jpg` name and passes every naive check;
- output is capped at 686×858 whatever size you ask for;
- the defect rate is 30–40%, so candidates are generated with a surplus and **every one is
  reviewed by eye**;
- a table of the failures that actually recur: pseudo-text on labels, fused fingers,
  broken object geometry, frames that read as a 3D render;
- the prompt wording that prevents each of them in advance.

**How it is built:** mechanics live in the skill, style lives in the project. On startup it
reads `.claude/image-style.md` in the current project — palette, categories, subjects,
prohibitions — and creates that file by asking questions if it is missing. So the mechanics
are fixed once for every project, and style never leaks between them.

Full documentation: [`skills/ai-image-set/README.md`](skills/ai-image-set/README.md).

### `web-audit`

Audits a running site by **looking at it**: screenshots at several viewports, reviewed as
images, instead of reading CSS. Finds overlapping and clipped text, horizontal overflow,
broken images, breakpoint failures, unreadable contrast, and states that only break after
an interaction.

Invoked manually with a parameter, so it runs exactly the lenses you asked for:

```
/web-audit mobile              everything mobile-relevant
/web-audit view /pricing       layout only, one page
/web-audit flows               menus, modals, focus rings
```

The value is in the safeguards, without which this kind of audit does harm or produces
noise:

- **your browser is never launched and never killed** — captures use a separate binary
  with a throwaway profile, so your tabs and sessions stay untouched and never end up in a
  screenshot;
- **the address is an input, never a guess** — a wrong port means auditing someone else's
  project, and a live host means real requests to real endpoints;
- **no screenshot, no audit** — a conclusion about rendering is never drawn from source
  code, however much faster that would be;
- **no invented numbers** — contrast and sizes are measured and attributed, or described
  in words;
- **a finding needs a frame, a viewport and a visible element**, and "no defects found" is
  a complete result.

Full documentation: [`skills/web-audit/README.md`](skills/web-audit/README.md).

## Licence

[MIT](LICENSE) — use it, change it, ship it; keep the notice, expect no warranty.

# Working on this repository

Instructions for developing the skills here. User-facing documentation lives in
`README.md` and in each skill's own `README.md` — keep development notes out of both.

## Language

**Everything in this repository is written in English.** Skill instructions, helper
scripts, comments, READMEs, commit messages. `SKILL.md` is read by a model, and English
instructions are followed more precisely; the rest follows for consistency.

## Layout

```
skills/<name>/
  SKILL.md          required — frontmatter + the instructions themselves
  README.md         optional — for humans: what it does, install, usage
  lenses/           optional — bodies of knowledge read only when selected
  references/       optional — read on demand, not at activation
  scripts/          optional — helper scripts
```

## The one rule that keeps skills reusable

**Mechanics live in the skill. Anything project-specific lives in the project.**

A skill reads a contract file from the project it is working in — `.claude/image-style.md`,
`.claude/web-audit.md` — and creates it when missing. Never bake a palette, a route, a port
or a breakpoint into a skill, and never copy a skill into a project. One source of truth
for mechanics, one for specifics.

## Writing `SKILL.md`

**The `description` decides whether the skill is ever used.** It is matched against how the
user phrased their request, so it must name the *situation*, not the machinery. "Takes
screenshots with a headless browser" describes how; "check the layout", "why does it break
on mobile" describes when. A skill that never triggers fails silently — the model just does
the work worse, by hand, and nobody finds out.

For a manually invoked skill, name the command and its parameters in the description
instead.

**Keep the body short, and put depth behind a door.** `SKILL.md` loads into context in full
on activation; files in `lenses/` and `references/` load only when read. Anything needed in
one run out of twenty belongs behind the door. When a skill grows past its neighbours,
something that should have been a reference has leaked into the body.

**Write what to do, not why the alternative is worse.** One exception, and it matters:
a rule derived from a measured failure keeps its number. "6 of 9 portraits came back with
fused fingers despite that instruction" is what stops the rule being dismissed as
over-cautious. Generic justification is padding; evidence is not.

**Tables over prose.** Defect classes, thresholds and routing tables reproduce across
agents. Paragraphs do not.

## Writing helper scripts

- `#!/bin/bash`, invoked as `bash script.sh`. On macOS the default shell is zsh, which
  **does not word-split unquoted variables** — a loop over `$WIDTHS` silently collapses
  into one argument.
- **Idempotent.** Skip work whose output already exists and is valid; delete invalid output
  so a rerun repairs it. An interrupted run is then resumed by running it again.
- **Validate by content, not by exit code.** A downloaded file that is 4 KB of JSON error
  passes "exists and is non-empty" and ends up in a gallery. Check magic bytes.
- **Resolve paths by glob, never by a pinned version.** A hardcoded cache revision works on
  the author's machine and nowhere else.
- **Never kill processes by name.** `killall`, `pkill -f chrome` hit the user's own
  applications. Kill the PID you launched, and sweep strays by a path unique to your run.
- **Install nothing.** If a dependency is missing, print the command and stop. Downloading
  hundreds of megabytes onto someone else's machine is their decision.

## Before committing

- Would this work on a machine that is not yours? Check every absolute path, version
  number and assumed binary.
- `bash -n script.sh` on every script.
- Run the skill once against something real. An unproven skill is worse than none, because
  it will be trusted.

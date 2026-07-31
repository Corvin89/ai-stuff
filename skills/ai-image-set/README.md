# ai-image-set

Generates a coherent **set** of images — for a gallery, portfolio, catalogue or placeholder
content — through a free service with no key and no account.

The generating is easy. The culling is the work: expect a 30–40% defect rate, plan for it,
and look at every candidate before it ships.

## Install

No installer. Symlink or copy the folder:

```bash
ln -s ~/www/ai-stuff/skills/ai-image-set ~/.claude/skills/ai-image-set   # updates with git pull
cp -R ~/www/ai-stuff/skills/ai-image-set ~/.claude/skills/               # edit freely
```

Available in the next Claude Code session. Nothing to install, no API key, no account.

## Use

Not a slash command — it activates on the task. "Fill the gallery with images", "we need
placeholder photos for the catalogue", "generate a set of product shots".

On first run in a project it has no style to work from, so it asks: what the images are
for, what groupings, what palette and mood, what aspect ratio, how many per group. Those
answers become `.claude/image-style.md` and it never asks again.

## The project file

`.claude/image-style.md`, in the project being worked on — **not** in this skill.

The skill holds the mechanics; the project holds the palette, categories, subjects, target
counts, naming, and the prohibitions learned from previous culls. So a fix to the mechanics
reaches every project at once, and no project's style leaks into another. The skill creates
the file if it is missing.

## What is worth knowing before you rely on it

| | |
|---|---|
| **One request at a time** | The service allows a single in-flight request per IP. A second one returns `HTTP 429` with a JSON body that gets saved under your `.jpg` name — non-empty, `curl` exits 0, name ends in `.jpg`. Every naive check passes it. You find out when something tries to display it. |
| **686×858, always** | Whatever size you request. Fine for grid tiles up to ~400 CSS px; a full-screen lightbox will look soft. |
| **15–60s per image** | `model=flux` is much better and much slower than the default. A batch of thirty outlives any synchronous tool call, so it runs in the background. |
| **Seeds are reproducible** | Vary per image; reuse to regenerate the same frame after a prompt tweak. |

## The script

```bash
bash scripts/generate.sh <output-dir> <jobs-file> "<shared prompt tail>"
bash scripts/test-generate.sh          # 33 checks, stubbed curl, no network, ~1s
```

Strictly sequential, idempotent, validates every download by its magic bytes rather than
its size, retries 429 with exponential backoff, percent-encodes the whole prompt. Exits 1
when a job exhausted its retries — that is the signal to run it again, which regenerates
only what is missing.

Prefer it over an ad-hoc `curl` loop. Ad-hoc loops are where the 429-saved-as-JPEG failure
keeps coming from.

## What it will not do

Ship an image it has not looked at. Delete your rejects. Sample a batch instead of
reviewing all of it. Write alt text from the prompt rather than from the result. Bake your
palette into the skill. Renumber files already referenced by code.

## The rules that make the output trustworthy

- **Every candidate is opened and looked at.** Not sampled, not trusted because the
  filename says so. This is the step that decides quality.
- **Generate a surplus** — roughly 1.4 × the target — and cull down, rather than generating
  exactly N and hoping.
- **Rejects are kept, never deleted**, so you can overrule a call.
- **Alt text describes the result, not the intention.** The prompt is what was asked for;
  the image is what arrived.
- **The set is judged as a whole**, not just frame by frame — repeated archetypes, a
  reused lighting trick and brightness outliers are invisible one image at a time.

## Licence

[MIT](../../LICENSE) — copyright (c) 2026 Alexander Kutiy.

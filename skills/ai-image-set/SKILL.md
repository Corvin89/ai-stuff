---
name: ai-image-set
description: Use when a project needs a set of generated images for a gallery, portfolio, catalogue or placeholder content - generates candidates via a free no-key service, audits them visually, culls the defective ones and writes an alt-text manifest. Reads per-project style from .claude/image-style.md and creates that file if missing.
---

# Generating a coherent image set

Produces a **set** of images that look like they belong together, not a pile of
one-offs. The hard part is not generation — it is culling. Expect a 30–40% defect
rate and plan for it.

## Rule 0 — the style contract lives in the project, not here

This skill holds the mechanics. Everything project-specific — palette, categories,
subjects, target counts, prohibitions — lives in **`.claude/image-style.md`** in the
project you are working in.

1. Look for `.claude/image-style.md`.
2. If it exists, read it and follow it exactly.
3. If it does not exist, **create it before generating anything**. Ask the user, one
   question at a time: what the images are for; what categories or groupings; what
   palette and mood; what aspect ratio; roughly how many per group. Then write the
   file using the template at the end of this document and confirm it with them.

Never bake style into this skill, and never copy this skill into a project. One
source of truth for mechanics, one for style.

## The service

Free, no key, no account:

```
https://image.pollinations.ai/prompt/<url-encoded-prompt>?width=1024&height=1280&nologo=true&model=flux&seed=<n>
```

Verified behaviour — do not relearn this the hard way:

- **Output is capped at 686×858 regardless of the size you request.** Asking for
  1080×1350 or 1440×1800 returns exactly the same 686×858. Design around it: this is
  enough for grid tiles up to ~400 CSS px, but a full-screen lightbox will look soft.
  Cap displayed width at ~640px.
- `model=flux` gives noticeably better commercial-looking results than the default,
  but is **much slower** — 15–60s per image versus under a second.
- `seed` makes a result reproducible. Vary it per image; reuse it to regenerate the
  same frame after a prompt tweak.
- Aspect ratio is honoured (the 4:5 request comes back as 686×858), so ask for the
  ratio you actually want and you will not need to crop.

## Generation discipline

**One request at a time. This is the constraint that matters most.**

The service permits a single in-flight request per IP. A second concurrent request
gets `HTTP 429` with a JSON body — `Queue full for IP …: 1 requests already queued
(max: 1)`. That body is **saved as a ~4 KB file under your `.jpg` name**, and every
naive success check passes it: `curl` exits 0, the file is non-empty, the name ends
in `.jpg`. You only find out when something tries to display it.

Consequences to respect:

- Never parallelise generation. No background fan-out, no two scripts at once.
- Never generate while a subagent is generating. Coordinate, or wait.
- **Validate every download by its magic bytes** (a JPEG starts `FF D8`), not by
  file size. Check the HTTP status too, and delete anything that fails so a rerun
  repairs it.
- Retry 429 with exponential backoff — the queue clears in seconds.

`scripts/generate.sh` in this skill does all of the above. Prefer it over ad-hoc
`curl` loops, which is exactly where this failure keeps coming from.

**Never run a large batch synchronously.** Thirty images at 30–60s each will blow
past any tool timeout and you will lose the whole run. Instead:

- Write a shell script, run it with `run_in_background: true`, and let the completion
  notification tell you when it is done. See `scripts/generate.sh` in this skill.
- Make the script **idempotent**: skip files that already exist and are non-empty.
  Then a timed-out or partial run is resumed by simply running it again.
- On a failed download, delete the truncated file so the retry regenerates it.

**Shell gotchas that have actually bitten:**

- On macOS the default shell is **zsh, which does not word-split unquoted variables**.
  `for pair in "1080 1350"; set -- $pair` silently gives you one argument, not two.
  Write scripts as `#!/bin/bash` and invoke them with `bash script.sh`.
- URL-encode the prompt: spaces → `%20`, commas → `%2C`. A raw `sed 's/ /%20/g; s/,/%2C/g'`
  is enough for ordinary prose prompts.

## Generate a surplus, then cull

**Target N usable images → generate roughly 1.4 × N candidates.** Measured defect
rate on this service is 30–40%. Generating exactly N and hoping is how you end up
shipping a gallery with broken hands in it.

Put candidates in a **staging directory** (`images/candidates/`), not in the final
directory. Only culled survivors get moved and renamed into place. Keep rejects —
never delete them — so the user can overrule a call.

## Audit: look at every single one

**View every candidate with the Read tool.** It renders images. Do not sample, do not
trust the prompt, do not assume a file is fine because its name says so. This is the
step that determines quality, and it cannot be skipped or delegated to a filename.

Reject on any of these — all observed repeatedly in practice:

| Defect | Why it matters |
|---|---|
| **Pseudo-text on the subject** | The single most common failure. Any label, logo, engraving or printed word comes out as garbled letterforms. Fatal on packaging, where the label is the subject. |
| **Hands, fingers, faces** | Fused fingers, extra digits, anatomically impossible arm positions. |
| **Broken geometry** | An object that does not meet itself: a strap fused into a watch case, a glass stem not joining its bowl. |
| **Blob hardware** | Clasps, buckles, chains and jewellery melt into featureless lumps. |
| **Reads as a 3D render** | Over-saturated plastic, perfect specular highlights, no lens character. Kills the "real photograph" illusion. |
| **Collapses into darkness** | No discernible background or subject separation; in a grid it reads as a hole. |
| **Watermarks and signatures** | Some outputs carry a faux artist signature in a corner. |
| **Out of palette** | One cold frame in a warm set destroys the "one studio" effect. |

Then judge the set as a whole, which individual review will not catch:

- **Repeated subject archetype.** Four separate "transparent vessel holding amber
  liquid, centred, dark background" frames read as one image shown four times.
- **Repeated lighting trick.** Four of six interiors built on a hidden LED strip is a
  tell. Vary the light source: window, lamp, fire, overcast.
- **Cross-category collision.** A close-up of jewellery filed under Fashion and
  another under Product confuses the taxonomy.
- **Brightness outliers.** One frame far darker than the rest leaves a hole in a grid.

## Prompt rules that prevent defects

Fold these into the prompts rather than culling afterwards — cheaper, and it raises
the yield:

- **Anything with a label → demand blankness.** `completely blank and unbranded, no
  text, no lettering, no label`. Do not ask for "a coffee bag with elegant branding".
- **People → resolve the hands.** Either `hands out of frame` or `hands clearly
  visible and relaxed`. Add `no jewellery` unless jewellery is the subject.
- **People → demand a background.** `visible textured studio backdrop` or a named
  location, otherwise the model dissolves everything into black.
- **Anti-CGI.** `real photograph not a render`, `natural key light`, `matte materials`.
- **Name the forbidden trick** when the set already overuses one, e.g.
  `no hidden led strip lighting`.
- Keep a **shared tail** on every prompt in the set — this is what makes the frames
  look like one studio shot them. Example: `warm amber lighting, cinematic commercial
  photography, dark moody background, shallow depth of field, photorealistic`.

## Deliverables

1. Survivors moved into the project's image directory with **sequential, predictable
   names** (`product-01.jpg` … `product-15.jpg`). Continue existing numbering when
   extending a set; never renumber files already referenced by code.
2. **An alt-text line for every image**, written from actually looking at it, not from
   the prompt. The prompt describes an intention; alt text must describe the result.
3. A short report: what was kept, what was rejected and why, final counts per group.

**Uneven counts read as real.** Exactly N per category is arithmetic, not a portfolio.
Weight the groups by what the fictional owner would plausibly do most of.

## Template for `.claude/image-style.md`

```markdown
# Image style contract

Read by the `ai-image-set` skill. Mechanics live in the skill; only style lives here.

## Output
- Directory: `<path>`
- Staging: `<path>/candidates/`
- Naming: `<group>-NN.jpg`, sequential per group
- Aspect: `width=1024&height=1280` (4:5) — returns 686×858
- Model: `flux`

## Palette and mood
<colours, lighting, what the set should feel like>

## Shared prompt tail
`<the tail appended to every prompt in the set>`

## Groups and targets
| Group | Target | Subjects already used |
|---|---|---|
| ... | ... | ... |

## Prohibitions
- <per-group rules learned from previous culls>

## Consumers
<files that reference these images, e.g. src/data/gallery.ts — update after adding>
```

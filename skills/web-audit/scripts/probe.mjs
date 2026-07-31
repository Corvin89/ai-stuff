// Measured values for the contrast lens. Everything this prints came from the
// live DOM — nothing here is estimated, and nothing in a report should be.
//
//   node probe.mjs <url> [width] [height]
//   NODE_PATH=/path/to/some/node_modules node probe.mjs <url>
//
// Prints one JSON object to stdout. Exits 2 if playwright is not installed —
// that is a normal outcome, not an error to fix by installing it.

const [, , url, wArg, hArg] = process.argv;
if (!url) {
  console.error('usage: node probe.mjs <url> [width] [height]');
  process.exit(1);
}
const width = Number(wArg) || 1440;
const height = Number(hArg) || 900;

// NODE_PATH does not apply to ESM imports — it is a CommonJS mechanism. Resolve
// through createRequire, which does honour an explicit search path, then import
// the resolved file by URL. Plain `import('playwright')` only finds a copy
// installed next to this script or globally linked.
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';

const searchPaths = [
  process.env.PLAYWRIGHT_DIR,
  ...(process.env.NODE_PATH || '').split(':').filter(Boolean),
  process.cwd(),
].filter(Boolean);

let chromium;
try {
  ({ chromium } = await import('playwright'));
} catch {
  try {
    const require = createRequire(import.meta.url);
    const entry = require.resolve('playwright', { paths: searchPaths });
    // playwright's entry point is CommonJS, so importing it by URL puts the
    // exports under `default` rather than at the top level.
    const mod = await import(pathToFileURL(entry).href);
    chromium = mod.chromium ?? mod.default?.chromium;
    if (!chromium) throw new Error('resolved playwright but found no chromium export');
  } catch {
    console.error('playwright not resolvable — report the contrast lens as not measured.');
    console.error('Searched: ' + (searchPaths.join(', ') || '(nothing given)'));
    console.error('Point PLAYWRIGHT_DIR at a node_modules that has it, or leave it unmeasured.');
    console.error("Do NOT install it. That is the user's decision.");
    process.exit(2);
  }
}

// Its own bundled browser, its own throwaway profile. Never the user's Chrome.
const browser = await chromium.launch({ headless: true });
const context = await browser.newContext({
  viewport: { width, height },
  deviceScaleFactor: 1,
  reducedMotion: 'reduce',
});
const page = await context.newPage();

const consoleErrors = [];
const failedRequests = [];
page.on('console', (m) => m.type() === 'error' && consoleErrors.push(m.text().slice(0, 300)));
page.on('requestfailed', (r) => failedRequests.push({ url: r.url().slice(0, 200), why: r.failure()?.errorText }));
page.on('response', (r) => r.status() >= 400 && failedRequests.push({ url: r.url().slice(0, 200), status: r.status() }));

await page.goto(url, { waitUntil: 'networkidle', timeout: 45000 });
await page.evaluate(() => document.fonts?.ready);
// Let IntersectionObserver-driven images actually load before measuring.
await page.evaluate(async () => {
  await new Promise((r) => { window.scrollTo(0, document.body.scrollHeight); setTimeout(r, 600); });
  await new Promise((r) => { window.scrollTo(0, 0); setTimeout(r, 300); });
});

const result = await page.evaluate((MIN_TARGET) => {
  const lum = ([r, g, b]) => {
    const f = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
  };
  const ratio = (a, b) => {
    const [x, y] = [lum(a), lum(b)].sort((p, q) => q - p);
    return Math.round(((x + 0.05) / (y + 0.05)) * 100) / 100;
  };
  const parse = (s) => {
    const m = String(s).match(/rgba?\(([^)]+)\)/);
    if (!m) return null;
    const p = m[1].split(/[,\s/]+/).filter(Boolean).map(Number);
    return { rgb: p.slice(0, 3), a: p.length > 3 ? p[3] : 1 };
  };
  const over = (fg, bg, a) => fg.map((c, i) => Math.round(c * a + bg[i] * (1 - a)));

  // The effective background: walk up until something is actually opaque.
  // If an image or gradient is involved, the number is a sample, not a fact.
  // Walking past a gradient-filled surface is how this returns a number for a
  // background the text never sits on: a pill with `background-image` and no
  // `background-color` is transparent to this walk, so the page background wins
  // and the ratio is nonsense. Stop at the paint and say it is unmeasurable —
  // a missing number is honest, a wrong one is not.
  const backdrop = (el) => {
    let node = el;
    while (node && node !== document.documentElement.parentNode) {
      const cs = getComputedStyle(node);
      const bg = parse(cs.backgroundColor);
      const painted = cs.backgroundImage && cs.backgroundImage !== 'none';
      if (painted && !(bg && bg.a >= 1)) {
        return { rgb: bg && bg.a > 0 ? bg.rgb : [128, 128, 128], unmeasurable: true, why: 'gradient or image fill, no opaque colour behind the text' };
      }
      if (bg && bg.a >= 1) return { rgb: bg.rgb, unmeasurable: false };
      node = node.parentElement;
    }
    return { rgb: [255, 255, 255], unmeasurable: false };
  };

  const visible = (el) => {
    const r = el.getBoundingClientRect();
    const cs = getComputedStyle(el);
    return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' && Number(cs.opacity) > 0.05;
  };

  const contrast = [];
  const unmeasurable = [];
  const seen = new Set();
  for (const el of document.querySelectorAll('body *')) {
    if (!visible(el)) continue;
    const text = [...el.childNodes].filter((n) => n.nodeType === 3).map((n) => n.textContent.trim()).join(' ').trim();
    if (!text) continue;
    const cs = getComputedStyle(el);
    const fg = parse(cs.color);
    if (!fg) continue;
    const bd = backdrop(el);
    const colour = fg.a < 1 ? over(fg.rgb, bd.rgb, fg.a) : fg.rgb;
    const size = parseFloat(cs.fontSize);
    const bold = Number(cs.fontWeight) >= 700;
    const large = size >= 24 || (bold && size >= 18.66);
    const r = ratio(colour, bd.rgb);
    const required = large ? 3 : 4.5;
    const key = `${text.slice(0, 40)}|${r}`;
    if (seen.has(key)) continue;
    seen.add(key);
    if (r < required) {
      const row = {
        text: text.slice(0, 60), ratio: r, required,
        fontSize: size, bold, large,
        fg: `rgb(${colour.join(',')})`, bg: `rgb(${bd.rgb.join(',')})`,
      };
      // Two classes that are never defects, separated here so a lens never has
      // to re-derive them: text painted from a gradient (`background-clip: text`
      // sets colour equal to the backdrop, giving exactly 1.00), and text over
      // a surface with no measurable colour behind it.
      if (r === 1 && colour.join() === bd.rgb.join()) {
        unmeasurable.push({ ...row, why: 'gradient text: background-clip paints the glyphs, colour equals the backdrop' });
      } else if (bd.unmeasurable) {
        unmeasurable.push({ ...row, why: bd.why });
      } else {
        contrast.push(row);
      }
    }
  }

  const targets = [];
  for (const el of document.querySelectorAll('a,button,input,select,textarea,[role=button],[role=link],[onclick]')) {
    if (!visible(el)) continue;
    const r = el.getBoundingClientRect();
    if (r.width < MIN_TARGET || r.height < MIN_TARGET) {
      targets.push({
        tag: el.tagName.toLowerCase(),
        label: (el.getAttribute('aria-label') || el.textContent || '').trim().slice(0, 40),
        width: Math.round(r.width), height: Math.round(r.height),
      });
    }
  }

  const de = document.documentElement;
  let widest = null;
  if (de.scrollWidth > de.clientWidth) {
    for (const el of document.querySelectorAll('body *')) {
      const r = el.getBoundingClientRect();
      if (r.right > de.clientWidth + 1 && (!widest || r.right > widest.right)) {
        widest = { right: Math.round(r.right), tag: el.tagName.toLowerCase(), cls: String(el.className).slice(0, 60) };
      }
    }
  }

  return {
    contrastFailures: contrast,
    contrastUnmeasurable: unmeasurable,
    smallTargets: targets,
    overflow: {
      scrollWidth: de.scrollWidth,
      clientWidth: de.clientWidth,
      overflows: de.scrollWidth > de.clientWidth,
      widestElement: widest,
    },
    // `!complete` means still downloading — that is a lazy image below the fold,
    // not a broken one. Only a finished load with no pixels is actually broken.
    brokenImages: [...document.images]
      .filter((i) => i.complete && i.naturalWidth === 0)
      .map((i) => ({ src: i.currentSrc || i.src, alt: i.alt })),
    stillLoadingImages: [...document.images].filter((i) => !i.complete).length,
    fonts: { ready: true, families: [...new Set([...document.querySelectorAll('body *')].slice(0, 200).map((e) => getComputedStyle(e).fontFamily))].slice(0, 5) },
  };
}, 24);

console.log(JSON.stringify({
  url, viewport: { width, height },
  ...result,
  consoleErrors: consoleErrors.slice(0, 20),
  failedRequests: failedRequests.slice(0, 20),
  note: 'contrast values where backgroundSampled is true sit over an image or gradient — report them as sampled, not as a hard fail',
}, null, 2));

await browser.close();

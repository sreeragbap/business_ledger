// Business Ledger icon: a ledger page whose last line is a total with the
// accountant's double rule under it, a second page behind (several books).
// Regenerate: in a scratch folder `npm i @resvg/resvg-js@2.6.2`, then
// `node generate.mjs <path to assets/icon>`, then `dart run flutter_launcher_icons`.
import { Resvg } from '@resvg/resvg-js';
import { writeFileSync, mkdirSync } from 'node:fs';

const S = 1024;
const TEAL_TOP = '#14897D';
const TEAL = '#0B6B63';
const TEAL_DEEP = '#064943';
const MINT = '#5EEAD4';
const INK = '#0B6B63';
const SOFT = '#B9E4DE';

// The glyph, drawn in a box `w` wide centred on the canvas.
// mode: 'color' | 'mono' (white silhouette with cut-outs) | 'dark' | 'gray'
function glyph(w, mode) {
  const h = w * 1.22;
  const x = (S - w) / 2 + w * 0.045;
  const y = (S - h) / 2 + w * 0.045;
  const off = w * 0.09;
  const r = w * 0.11;
  const u = (v) => (v * w).toFixed(1);
  const bar = w * 0.09;

  // Rows relative to the page: [y, x0, x1] in page widths.
  const rows = [
    [0.28, 0.16, 0.44, 0.58, 0.84],
    [0.48, 0.16, 0.44, 0.58, 0.84],
  ];
  const totalY = 0.71;
  const rule1 = 0.85;
  const rule2 = 0.95;

  const pageFill = { color: '#FFFFFF', mono: '#FFFFFF', dark: '#F2F4F7', gray: '#FFFFFF' }[mode];
  const backFill = { color: MINT, mono: '#FFFFFF', dark: '#2DD4BF', gray: '#FFFFFF' }[mode];
  const backOpacity = { color: 0.9, mono: 0.55, dark: 0.85, gray: 0.5 }[mode];
  const soft = { color: SOFT, dark: '#9ED9D0', gray: '#C8C8C8' }[mode];
  const ink = { color: INK, dark: '#0B6B63', gray: '#3A3A3A' }[mode];

  const line = (yy, x0, x1, t, fill) =>
    `<rect x="${u(x0)}" y="${(yy * w - t / 2).toFixed(1)}" width="${u(x1 - x0)}" height="${t.toFixed(1)}" rx="${(t / 2).toFixed(1)}" fill="${fill}"/>`;

  const marks = (softFill, inkFill) => [
    ...rows.flatMap(([yy, a0, a1, b0, b1]) => [line(yy, a0, a1, bar, softFill), line(yy, b0, b1, bar, softFill)]),
    line(totalY, 0.16, 0.38, bar, inkFill),
    line(totalY, 0.50, 0.84, bar * 1.15, inkFill),
    line(rule1, 0.50, 0.84, bar * 0.6, inkFill),
    line(rule2, 0.50, 0.84, bar * 0.6, inkFill),
  ].join('');

  const back = `<rect x="${(x + off).toFixed(1)}" y="${(y - off).toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" rx="${r.toFixed(1)}" fill="${backFill}" fill-opacity="${backOpacity}"/>`;
  const pageRect = (fill) => `<rect x="0" y="0" width="${w.toFixed(1)}" height="${h.toFixed(1)}" rx="${r.toFixed(1)}" fill="${fill}"/>`;

  if (mode === 'mono') {
    // Cut the marks out of the page so they read through any themed colour.
    return `
      <defs><mask id="cut"><g transform="translate(${x.toFixed(1)} ${y.toFixed(1)})">${pageRect('#fff')}${marks('#000', '#000')}</g></mask></defs>
      ${back.replace('/>', ` mask="url(#backcut)"/>`)}
      <defs><mask id="backcut"><rect width="${S}" height="${S}" fill="#fff"/><rect x="${(x - w * 0.04).toFixed(1)}" y="${(y - w * 0.04).toFixed(1)}" width="${(w * 1.08).toFixed(1)}" height="${(h * 1.0 + w * 0.08).toFixed(1)}" rx="${(r * 1.3).toFixed(1)}" fill="#000"/></mask></defs>
      <rect width="${S}" height="${S}" fill="${pageFill}" mask="url(#cut)"/>`;
  }

  const shadow = mode === 'color'
    ? `<rect x="${x.toFixed(1)}" y="${(y + w * 0.03).toFixed(1)}" width="${w.toFixed(1)}" height="${h.toFixed(1)}" rx="${r.toFixed(1)}" fill="#03302C" fill-opacity="0.35" filter="url(#blur)"/>`
    : '';
  return `${back}${shadow}<g transform="translate(${x.toFixed(1)} ${y.toFixed(1)})">${pageRect(pageFill)}${marks(soft, ink)}</g>`;
}

const background = `
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="${TEAL_TOP}"/>
      <stop offset="0.55" stop-color="${TEAL}"/>
      <stop offset="1" stop-color="${TEAL_DEEP}"/>
    </linearGradient>
    <filter id="blur" x="-20%" y="-20%" width="140%" height="140%"><feGaussianBlur stdDeviation="${S * 0.018}"/></filter>
  </defs>`;

const svg = (body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${S} ${S}" width="${S}" height="${S}">${body}</svg>`;

const variants = {
  // iOS + legacy Android: full square, the system rounds the corners.
  'icon.svg': svg(`${background}<rect width="${S}" height="${S}" fill="url(#bg)"/>${glyph(S * 0.5, 'color')}`),
  // Android adaptive layers (108dp, the inner 66dp circle is always visible).
  // flutter_launcher_icons insets foreground and monochrome by 16% per side,
  // so the glyph is drawn at 0.37 / 0.68 to land at 37% of the final layer.
  'adaptive_foreground.svg': svg(`${background}${glyph(S * 0.545, 'color')}`),
  'adaptive_background.svg': svg(`${background}<rect width="${S}" height="${S}" fill="url(#bg)"/>`),
  // Android 13+ themed icon: alpha only.
  'adaptive_monochrome.svg': svg(glyph(S * 0.545, 'mono')),
  // iOS 18 dark and tinted variants (transparent, the system adds the backdrop).
  'ios_dark.svg': svg(`${background}${glyph(S * 0.5, 'dark')}`),
  'ios_tinted.svg': svg(`<rect width="${S}" height="${S}" fill="#000"/>${background}${glyph(S * 0.5, 'gray')}`),
};

const out = process.argv[2] ?? 'out';
mkdirSync(out, { recursive: true });
for (const [name, text] of Object.entries(variants)) {
  writeFileSync(`${out}/${name}`, text);
  const png = new Resvg(text, { fitTo: { mode: 'width', value: S } }).render().asPng();
  writeFileSync(`${out}/${name.replace('.svg', '.png')}`, png);
}
console.log('ok');

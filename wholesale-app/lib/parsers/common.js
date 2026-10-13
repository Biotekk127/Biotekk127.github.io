// Helpers shared by the site parsers. Nothing here guesses: every helper
// returns undefined when the exact thing it looks for isn't there.

/** Return the text content of every <script> tag whose opening tag matches `attrTest`. */
export function scriptContents(html, attrTest) {
  const out = [];
  const re = /<script\b([^>]*)>([\s\S]*?)<\/script>/gi;
  let m;
  while ((m = re.exec(html))) {
    if (attrTest(m[1])) out.push(m[2]);
  }
  return out;
}

export function scriptById(html, id) {
  const re = new RegExp(`\\bid=["']${id}["']`);
  return scriptContents(html, (attrs) => re.test(attrs))[0];
}

export function safeJson(text) {
  if (typeof text !== 'string') return undefined;
  try {
    return JSON.parse(text);
  } catch {
    return undefined;
  }
}

/** All JSON-LD blocks on the page, flattened (arrays and @graph expanded). */
export function jsonLd(html) {
  const blocks = scriptContents(html, (a) => /type=["']application\/ld\+json["']/i.test(a));
  const out = [];
  const push = (x) => {
    if (!x || typeof x !== 'object') return;
    if (Array.isArray(x)) return x.forEach(push);
    out.push(x);
    if (Array.isArray(x['@graph'])) x['@graph'].forEach(push);
  };
  for (const b of blocks) push(safeJson(b.trim()));
  return out;
}

/** Safe nested lookup: get(obj, 'a.b.0.c'). */
export function get(obj, pathStr) {
  let cur = obj;
  for (const key of pathStr.split('.')) {
    if (cur === null || cur === undefined) return undefined;
    cur = cur[key];
  }
  return cur;
}

export function metaContent(html, nameOrProp) {
  const re = new RegExp(
    `<meta[^>]+(?:name|property)=["']${nameOrProp.replace(/[.:]/g, '\\$&')}["'][^>]*>`,
    'i'
  );
  const tag = html.match(re)?.[0];
  return tag?.match(/content=["']([^"']*)["']/i)?.[1];
}

export function decodeEntities(s) {
  return String(s)
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&#x27;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

export function toNumber(v) {
  if (v === null || v === undefined || v === '') return undefined;
  if (typeof v === 'number') return Number.isFinite(v) ? v : undefined;
  const n = Number(String(v).replace(/[$,\s]/g, ''));
  return Number.isFinite(n) ? n : undefined;
}

/** Normalize a US phone number; returns undefined unless it has exactly 10 digits (or 11 with leading 1). */
export function normalizePhone(v) {
  if (v === null || v === undefined) return undefined;
  if (typeof v === 'object') {
    // Some sites store {areaCode, prefix, number} or {number, ext}
    const joined = [v.areaCode ?? v.area_code, v.prefix, v.number ?? v.phone].filter(Boolean).join('');
    return normalizePhone(joined);
  }
  let d = String(v).replace(/\D/g, '');
  if (d.length === 11 && d.startsWith('1')) d = d.slice(1);
  if (d.length !== 10) return undefined;
  return `(${d.slice(0, 3)}) ${d.slice(3, 6)}-${d.slice(6)}`;
}

export function formatLot(value, unit) {
  const n = toNumber(value);
  if (n === undefined) return undefined;
  const u = String(unit || '').toLowerCase();
  if (u.startsWith('acre')) return `${n} acres`;
  if (u.includes('sq') || u === '' ) return `${n.toLocaleString('en-US')} sqft`;
  return `${n} ${unit}`;
}

/**
 * Result collector used by every parser. `set` records a value and the exact
 * place it came from; the first non-empty value wins.
 */
export class Extraction {
  constructor(site) {
    this.site = site;
    this.fields = {};
    this.sources = {};
    this.notes = [];
  }
  set(field, value, source) {
    if (value === undefined || value === null || value === '') return;
    if (this.fields[field] !== undefined) return;
    this.fields[field] = value;
    this.sources[field] = source;
  }
  note(msg) {
    this.notes.push(msg);
  }
}

/** Detect common bot-wall / captcha pages so we report "blocked" instead of "no data". */
export function detectBlock(html) {
  const checks = [
    [/px-captcha|perimeterx/i, 'PerimeterX bot check (captcha)'],
    [/captcha-delivery|datadome/i, 'DataDome bot check'],
    [/Please verify you're a human|Press & Hold to confirm you are/i, 'human-verification page'],
    [/<title>\s*Access to this page has been denied/i, 'access denied page'],
    [/cf-browser-verification|Just a moment\.\.\./i, 'Cloudflare challenge page'],
    [/Pardon Our Interruption/i, 'bot-protection interstitial'],
  ];
  for (const [re, label] of checks) if (re.test(html)) return label;
  return null;
}

export const FSBO_TEXT = /\bfor\s+sale\s+by\s+owner\b|\bFSBO\b/i;

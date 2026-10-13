// Listing URL import. This is the ONLY place the app makes outbound network
// requests, and only to the three listing sites, only when you click Import.
import * as zillow from './parsers/zillow.js';
import * as realtor from './parsers/realtor.js';
import * as redfin from './parsers/redfin.js';
import { detectBlock } from './parsers/common.js';

const PARSERS = [zillow, realtor, redfin];

// The fields the import tries to fill; anything not found is reported, never filled in.
export const TARGET_FIELDS = {
  list_price: 'List price',
  beds: 'Beds',
  baths: 'Baths',
  sqft: 'Square feet',
  lot_size: 'Lot size',
  property_type: 'Property type',
  listing_phone: 'Contact phone',
};
const EXTRA_FIELDS = ['address', 'city', 'state', 'zip', 'parcel_id'];

const PHONE_LABEL_AGENT = 'listing contact (usually the agent)';
const PHONE_LABEL_FSBO = 'seller direct (listing marked FSBO)';

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

export function pickParser(rawUrl) {
  let url;
  try {
    url = new URL(String(rawUrl).trim());
  } catch {
    return { error: 'That is not a valid URL. Paste the full address starting with https://' };
  }
  if (!/^https?:$/.test(url.protocol)) return { error: 'Only http(s) links can be imported.' };
  const parser = PARSERS.find((p) => p.matches(url));
  if (!parser) {
    return { error: `Unsupported site "${url.hostname}". Only zillow.com, realtor.com and redfin.com listing pages can be imported.` };
  }
  return { url, parser };
}

/**
 * Build the final import result from parsed HTML. Exported separately so it can
 * be tested against saved pages without touching the network.
 */
export function buildResult(parser, html, url) {
  const blocked = detectBlock(html);
  const ex = parser.parse(html, url);
  const fields = {}, sources = {};
  for (const k of [...Object.keys(TARGET_FIELDS), ...EXTRA_FIELDS]) {
    if (ex.fields[k] !== undefined) {
      fields[k] = ex.fields[k];
      sources[k] = ex.sources[k];
    }
  }
  const dt = dealTypeFor(fields.property_type);
  if (dt) {
    fields.deal_type = dt;
    sources.deal_type = `mapped from property type "${fields.property_type}"`;
  }
  const isFsbo = ex.fields.is_fsbo === true;
  if (fields.listing_phone) {
    fields.listing_phone_label = isFsbo ? PHONE_LABEL_FSBO : PHONE_LABEL_AGENT;
  }
  const missing = Object.entries(TARGET_FIELDS)
    .filter(([k]) => fields[k] === undefined)
    .map(([, label]) => label);

  const found = Object.keys(TARGET_FIELDS).filter((k) => fields[k] !== undefined).length;
  const failures = [];
  if (blocked) failures.push(`The site returned a bot-check page (${blocked}) instead of the listing. Nothing on it can be trusted as listing data.`);
  if (!found && !blocked) failures.push('The page loaded but none of the expected listing data was found. The site layout may have changed — see notes below.');
  for (const n of ex.notes) failures.push(n);
  if (missing.length && found) failures.push(`Not found on page: ${missing.join(', ')}. Fill these in manually if you need them.`);

  return {
    ok: found > 0 && !blocked,
    site: parser.site,
    url: url.href,
    fields: blocked ? {} : fields,
    sources: blocked ? {} : sources,
    isFsbo: blocked ? false : isFsbo,
    fsboSource: blocked ? null : ex.sources.is_fsbo ?? null,
    missing: blocked ? Object.values(TARGET_FIELDS) : missing,
    failures,
  };
}

/** Map a site's property type to one of the app's deal types; undefined when unclear. */
export function dealTypeFor(propertyType) {
  const t = String(propertyType || '').toLowerCase();
  if (!t) return undefined;
  if (/\b(lot|land|lots\/land|vacant)\b/.test(t)) return 'Vacant land';
  if (/multi/.test(t)) return 'Multi-family';
  if (/condo|town ?house|townhome|co-?op/.test(t)) return 'Condo/Townhouse';
  if (/single/.test(t)) return 'Single-family';
  return undefined;
}

export async function importListing(rawUrl, { fetchImpl = fetch, timeoutMs = 20000 } = {}) {
  const picked = pickParser(rawUrl);
  if (picked.error) return { ok: false, site: null, url: rawUrl, fields: {}, sources: {}, missing: Object.values(TARGET_FIELDS), failures: [picked.error] };
  const { url, parser } = picked;

  let res, html;
  try {
    res = await fetchImpl(url.href, {
      headers: {
        'User-Agent': UA,
        Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
      },
      redirect: 'follow',
      signal: AbortSignal.timeout(timeoutMs),
    });
    html = await res.text();
  } catch (err) {
    const code = err?.cause?.code;
    const why =
      err?.name === 'TimeoutError' ? `the site did not answer within ${timeoutMs / 1000}s`
      : code === 'ENOTFOUND' || code === 'EAI_AGAIN' ? `could not look up ${url.hostname} (ENOTFOUND — are you online?)`
      : code === 'ECONNRESET' || code === 'ECONNREFUSED' ? `the connection was cut off (${code}) — often bot protection`
      : code || err?.message || String(err);
    return fail(parser, url, `Could not download the page: ${why}. Try again later, or open the listing in your browser and enter the details manually.`);
  }

  if (!res.ok) {
    const hint =
      res.status === 403 || res.status === 429
        ? ' The site is blocking automated requests (bot protection). Open the listing in your browser and copy the details in manually.'
        : res.status === 404 ? ' The listing may have been removed or the URL is wrong.' : '';
    return fail(parser, url, `The site answered HTTP ${res.status} ${res.statusText || ''}.${hint}`);
  }

  try {
    return buildResult(parser, html, url);
  } catch (err) {
    return fail(parser, url, `The ${parser.site} parser crashed: ${err.message}. The page layout has probably changed; update lib/parsers/${parser.site}.js.`);
  }
}

function fail(parser, url, msg) {
  return { ok: false, site: parser.site, url: url.href, fields: {}, sources: {}, missing: Object.values(TARGET_FIELDS), failures: [msg] };
}

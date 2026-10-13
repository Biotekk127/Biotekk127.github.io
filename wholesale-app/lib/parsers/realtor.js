// Realtor.com listing parser. If Realtor.com changes its page layout, only this
// file should need to change. See README "Parser dependencies" for every path used.
import {
  Extraction, scriptById, safeJson, jsonLd, get, toNumber, normalizePhone,
  formatLot, metaContent, decodeEntities, FSBO_TEXT,
} from './common.js';

export const site = 'realtor';

export function matches(url) {
  return /(^|\.)realtor\.com$/i.test(url.hostname);
}

function findProperty(next, ex) {
  const paths = [
    'props.pageProps.initialReduxState.propertyDetails',
    'props.pageProps.property',
    'props.pageProps.propertyDetails',
    'props.pageProps.initialProps.property',
  ];
  for (const p of paths) {
    const v = get(next, p);
    if (v && typeof v === 'object' && (v.list_price !== undefined || v.description || v.location)) return { prop: v, where: p };
  }
  ex.note(`__NEXT_DATA__ present but none of these paths held a property: ${paths.join(', ')}`);
  return null;
}

export function parse(html) {
  const ex = new Extraction(site);
  const next = safeJson(scriptById(html, '__NEXT_DATA__'));
  if (!next) ex.note('No __NEXT_DATA__ JSON block found on page.');
  const found = next && findProperty(next, ex);

  if (found) {
    const p = found.prop, w = found.where, d = p.description || {};
    ex.set('list_price', toNumber(p.list_price), `${w}.list_price`);
    ex.set('beds', toNumber(d.beds), `${w}.description.beds`);
    ex.set('baths', toNumber(d.baths_consolidated ?? d.baths), `${w}.description.baths_consolidated / baths`);
    ex.set('sqft', toNumber(d.sqft), `${w}.description.sqft`);
    ex.set('lot_size', formatLot(d.lot_sqft, 'sqft'), `${w}.description.lot_sqft`);
    ex.set('property_type', d.type ? String(d.type).replace(/_/g, ' ') : undefined, `${w}.description.type`);
    const addr = p.location?.address || {};
    ex.set('address', addr.line, `${w}.location.address.line`);
    ex.set('city', addr.city, `${w}.location.address.city`);
    ex.set('state', addr.state_code, `${w}.location.address.state_code`);
    ex.set('zip', addr.postal_code, `${w}.location.address.postal_code`);

    // Listing contact: the advertisers block (the listing agent / office)
    const advertisers = [].concat(p.advertisers || []);
    advertisers.forEach((a, i) => {
      for (const ph of [].concat(a?.phones || [])) {
        ex.set('listing_phone', normalizePhone(ph?.number ?? ph), `${w}.advertisers[${i}].phones[].number`);
      }
      ex.set('listing_phone', normalizePhone(a?.phone), `${w}.advertisers[${i}].phone`);
    });
    advertisers.forEach((a, i) => {
      for (const ph of [].concat(a?.office?.phones || [])) {
        ex.set('listing_phone', normalizePhone(ph?.number ?? ph), `${w}.advertisers[${i}].office.phones[].number`);
      }
    });
    [].concat(p.consumer_advertisers || []).forEach((a, i) => {
      ex.set('listing_phone', normalizePhone(a?.phone), `${w}.consumer_advertisers[${i}].phone`);
    });

    const srcType = String(p.source?.type ?? p.source?.name ?? '').toLowerCase();
    if (srcType.includes('fsbo') || srcType.includes('by owner')) ex.set('is_fsbo', true, `${w}.source.type`);
    if (p.flags?.is_fsbo === true) ex.set('is_fsbo', true, `${w}.flags.is_fsbo`);
  }

  for (const n of jsonLd(html)) {
    ex.set('list_price', toNumber(n.offers?.price), 'JSON-LD offers.price');
    ex.set('sqft', toNumber(n.floorSize?.value), 'JSON-LD floorSize.value');
    ex.set('beds', toNumber(n.numberOfBedrooms), 'JSON-LD numberOfBedrooms');
    ex.set('baths', toNumber(n.numberOfBathroomsTotal), 'JSON-LD numberOfBathroomsTotal');
    ex.set('address', n.address?.streetAddress, 'JSON-LD address.streetAddress');
    ex.set('city', n.address?.addressLocality, 'JSON-LD address.addressLocality');
    ex.set('state', n.address?.addressRegion, 'JSON-LD address.addressRegion');
    ex.set('zip', n.address?.postalCode, 'JSON-LD address.postalCode');
  }

  const title = decodeEntities(metaContent(html, 'og:title') || '');
  const desc = decodeEntities(metaContent(html, 'description') || '');
  if (FSBO_TEXT.test(title) || FSBO_TEXT.test(desc)) ex.set('is_fsbo', true, 'og:title / meta description wording');

  return ex;
}

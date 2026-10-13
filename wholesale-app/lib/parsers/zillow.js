// Zillow listing parser. If Zillow changes its page layout, only this file
// should need to change. See README "Parser dependencies" for every path used.
import {
  Extraction, scriptById, safeJson, jsonLd, get, toNumber, normalizePhone,
  formatLot, metaContent, decodeEntities, FSBO_TEXT,
} from './common.js';

export const site = 'zillow';

export function matches(url) {
  return /(^|\.)zillow\.com$/i.test(url.hostname);
}

/** Find the subject property object inside Zillow's embedded Next.js data. */
function findProperty(html, ex) {
  const next = safeJson(scriptById(html, '__NEXT_DATA__'));
  if (!next) {
    ex.note('No __NEXT_DATA__ JSON block found on page.');
  } else {
    // gdpClientCache is a JSON *string* keyed by a GraphQL query name; each value has .property
    for (const p of ['props.pageProps.componentProps.gdpClientCache', 'props.pageProps.gdpClientCache']) {
      let cache = get(next, p);
      if (typeof cache === 'string') cache = safeJson(cache);
      if (cache && typeof cache === 'object') {
        for (const v of Object.values(cache)) {
          if (v?.property && typeof v.property === 'object') return { prop: v.property, where: p };
        }
      }
    }
    const direct = get(next, 'props.pageProps.componentProps.initialReduxState.gdp.building');
    if (direct) ex.note('Page looks like a building/apartment page, not a single listing.');
    ex.note('__NEXT_DATA__ present but gdpClientCache[*].property not found.');
  }
  // Older layout: hdpApolloPreloadedData → apiCache (string) → {*: {property}}
  const apollo = safeJson(scriptById(html, 'hdpApolloPreloadedData'));
  if (apollo) {
    const cache = typeof apollo.apiCache === 'string' ? safeJson(apollo.apiCache) : apollo.apiCache;
    for (const v of Object.values(cache || {})) {
      if (v?.property) return { prop: v.property, where: 'hdpApolloPreloadedData.apiCache' };
    }
  }
  return null;
}

export function parse(html) {
  const ex = new Extraction(site);
  const found = findProperty(html, ex);

  if (found) {
    const p = found.prop, w = found.where + '[*].property';
    ex.set('list_price', toNumber(p.price), `${w}.price`);
    ex.set('beds', toNumber(p.bedrooms), `${w}.bedrooms`);
    ex.set('baths', toNumber(p.bathrooms), `${w}.bathrooms`);
    ex.set('sqft', toNumber(p.livingArea ?? p.livingAreaValue), `${w}.livingArea`);
    if (p.lotAreaValue !== undefined && p.lotAreaUnits) {
      ex.set('lot_size', formatLot(p.lotAreaValue, p.lotAreaUnits), `${w}.lotAreaValue + lotAreaUnits`);
    }
    ex.set('lot_size', formatLot(p.lotSize, 'sqft'), `${w}.lotSize`);
    ex.set('lot_size', p.resoFacts?.lotSize, `${w}.resoFacts.lotSize`);
    ex.set('property_type', p.homeType ? String(p.homeType).replace(/_/g, ' ').toLowerCase() : undefined, `${w}.homeType`);
    ex.set('address', p.streetAddress ?? p.address?.streetAddress, `${w}.streetAddress`);
    ex.set('city', p.city ?? p.address?.city, `${w}.city`);
    ex.set('state', p.state ?? p.address?.state, `${w}.state`);
    ex.set('zip', p.zipcode ?? p.address?.zipcode, `${w}.zipcode`);
    ex.set('parcel_id', p.parcelId ?? p.resoFacts?.parcelNumber, `${w}.parcelId / resoFacts.parcelNumber`);

    const fsbo =
      p.listingSubType?.isFSBO === true ||
      p.listingSubType?.is_FSBO === true ||
      p.listing_sub_type?.is_FSBO === true ||
      /fsbo|by_owner/i.test(String(p.listingTypeDimension ?? ''));
    if (fsbo) ex.set('is_fsbo', true, `${w}.listingSubType.isFSBO`);

    const a = p.attributionInfo || {};
    ex.set('listing_phone', normalizePhone(a.agentPhoneNumber), `${w}.attributionInfo.agentPhoneNumber`);
    ex.set('listing_phone', normalizePhone(a.brokerPhoneNumber), `${w}.attributionInfo.brokerPhoneNumber`);
    // FSBO listings sometimes carry the owner's number in the listed-by block
    const lb = p.listed_by || p.listedBy;
    if (lb) {
      const phones = [].concat(lb.phone ?? lb.phoneNumber ?? []);
      for (const ph of phones) ex.set('listing_phone', normalizePhone(ph), `${w}.listed_by.phone`);
    }
  }

  // Fallback: schema.org JSON-LD for the subject home
  for (const n of jsonLd(html)) {
    const t = [].concat(n['@type'] || []).join(',');
    if (!/SingleFamilyResidence|House|Residence|Apartment|Accommodation|Product|RealEstateListing/i.test(t)) continue;
    ex.set('sqft', toNumber(n.floorSize?.value), 'JSON-LD floorSize.value');
    ex.set('beds', toNumber(n.numberOfBedrooms), 'JSON-LD numberOfBedrooms');
    ex.set('baths', toNumber(n.numberOfBathroomsTotal), 'JSON-LD numberOfBathroomsTotal');
    ex.set('list_price', toNumber(n.offers?.price), 'JSON-LD offers.price');
    ex.set('address', n.address?.streetAddress, 'JSON-LD address.streetAddress');
    ex.set('city', n.address?.addressLocality, 'JSON-LD address.addressLocality');
    ex.set('state', n.address?.addressRegion, 'JSON-LD address.addressRegion');
    ex.set('zip', n.address?.postalCode, 'JSON-LD address.postalCode');
  }

  // FSBO wording in the page's own title/description (not the whole page — Zillow's
  // site menu contains "For Sale By Owner" links on every page).
  const title = decodeEntities(metaContent(html, 'og:title') || '');
  const desc = decodeEntities(metaContent(html, 'description') || '');
  if (FSBO_TEXT.test(title) || FSBO_TEXT.test(desc)) ex.set('is_fsbo', true, 'og:title / meta description wording');

  return ex;
}

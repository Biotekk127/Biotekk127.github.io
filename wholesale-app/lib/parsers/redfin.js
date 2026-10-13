// Redfin listing parser. If Redfin changes its page layout, only this file
// should need to change. See README "Parser dependencies" for every path used.
import {
  Extraction, jsonLd, toNumber, normalizePhone, metaContent, decodeEntities, FSBO_TEXT,
} from './common.js';

export const site = 'redfin';

export function matches(url) {
  return /(^|\.)redfin\.com$/i.test(url.hostname);
}

function visibleText(html) {
  return decodeEntities(
    html
      .replace(/<script\b[\s\S]*?<\/script>/gi, ' ')
      .replace(/<style\b[\s\S]*?<\/style>/gi, ' ')
      .replace(/<[^>]+>/g, ' ')
  ).replace(/\s+/g, ' ');
}

export function parse(html) {
  const ex = new Extraction(site);

  // 1) schema.org JSON-LD (Redfin marks up the subject listing)
  const nodes = jsonLd(html);
  if (!nodes.length) ex.note('No JSON-LD blocks found on page.');
  for (const n of nodes) {
    const t = [].concat(n['@type'] || []).join(',');
    if (/Product|RealEstateListing|Offer/i.test(t)) {
      ex.set('list_price', toNumber(n.offers?.price ?? n.price), 'JSON-LD (RealEstateListing) offers.price');
    }
    const home = n.mainEntity && typeof n.mainEntity === 'object' ? n.mainEntity : n;
    const ht = [].concat(home['@type'] || []).join(',');
    if (/Residence|House|Apartment|Accommodation|SingleFamily|Place/i.test(ht)) {
      ex.set('beds', toNumber(home.numberOfBedrooms), 'JSON-LD numberOfBedrooms');
      ex.set('baths', toNumber(home.numberOfBathroomsTotal), 'JSON-LD numberOfBathroomsTotal');
      ex.set('sqft', toNumber(home.floorSize?.value), 'JSON-LD floorSize.value');
      ex.set('address', home.address?.streetAddress, 'JSON-LD address.streetAddress');
      ex.set('city', home.address?.addressLocality, 'JSON-LD address.addressLocality');
      ex.set('state', home.address?.addressRegion, 'JSON-LD address.addressRegion');
      ex.set('zip', home.address?.postalCode, 'JSON-LD address.postalCode');
      if (/SingleFamily/i.test(ht)) ex.set('property_type', 'single family residence', 'JSON-LD @type');
    }
  }

  // 2) Redfin's twitter:text:* meta tags
  ex.set('list_price', toNumber(metaContent(html, 'twitter:text:price')), 'meta twitter:text:price');
  ex.set('beds', toNumber(metaContent(html, 'twitter:text:beds')), 'meta twitter:text:beds');
  ex.set('baths', toNumber(metaContent(html, 'twitter:text:baths')), 'meta twitter:text:baths');
  ex.set('sqft', toNumber(metaContent(html, 'twitter:text:sqft')), 'meta twitter:text:sqft');

  // 3) Labeled values in the page's visible text
  const text = visibleText(html);
  const lotPatterns = [
    [/Lot Size \(Sq\.?\s?Ft\.?\):\s*([\d,]+)/i, (m) => `${m[1]} sqft`, 'text "Lot Size (Sq. Ft.): N"'],
    [/Lot Size \(Acres\):\s*([\d.,]+)/i, (m) => `${m[1]} acres`, 'text "Lot Size (Acres): N"'],
    [/Lot Size:\s*([\d.,]+\s*(?:acres?|sq\.?\s?ft\.?|square feet|sqft))/i, (m) => m[1], 'text "Lot Size: N unit"'],
    [/([\d.,]+\s*(?:acres?|sq\.?\s?ft\.?))\s+Lot Size\b/i, (m) => m[1], 'text "N unit Lot Size" (key details)'],
  ];
  for (const [re, fmt, src] of lotPatterns) {
    const m = text.match(re);
    if (m) ex.set('lot_size', fmt(m).trim(), src);
  }

  // Listing contact: only a number inside the "Listed by" agent block. We never
  // take an arbitrary number from the page (that could be Redfin's own line).
  const idx = text.search(/Listed by/i);
  if (idx !== -1) {
    const block = text.slice(idx, idx + 400);
    const m = block.match(/\(?\b\d{3}\)?[\s.-]?\d{3}[\s.-]\d{4}\b/);
    if (m) ex.set('listing_phone', normalizePhone(m[0]), 'phone within 400 chars after "Listed by"');
    else ex.note('"Listed by" block found but it contains no phone number.');
  } else {
    ex.note('No "Listed by" block found for the listing contact.');
  }

  const title = decodeEntities(metaContent(html, 'og:title') || '');
  const desc = decodeEntities(metaContent(html, 'description') || '');
  if (FSBO_TEXT.test(title) || FSBO_TEXT.test(desc)) ex.set('is_fsbo', true, 'og:title / meta description wording');
  if (idx !== -1 && /Listed by\s+(the\s+)?owner|For Sale By Owner/i.test(text.slice(idx, idx + 120))) {
    ex.set('is_fsbo', true, '"Listed by" block says owner');
  }

  return ex;
}

// Parser tests run against SYNTHETIC fixtures in test/fixtures (hand-built to
// mirror each site's embedded data structure; not real listings).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import { buildResult, pickParser, importListing } from '../lib/importer.js';

const fx = (name) => fs.readFileSync(new URL(`./fixtures/${name}`, import.meta.url), 'utf8');
const run = (url, file) => { const { parser, url: u } = pickParser(url); return buildResult(parser, fx(file), u); };

test('zillow: agent listing', () => {
  const r = run('https://www.zillow.com/homedetails/x/1_zpid/', 'zillow-agent.html');
  assert.equal(r.ok, true);
  assert.equal(r.fields.list_price, 289900);
  assert.equal(r.fields.beds, 3);
  assert.equal(r.fields.sqft, 1450);
  assert.equal(r.fields.lot_size, '0.52 acres');
  assert.equal(r.fields.listing_phone, '(860) 555-0100');
  assert.equal(r.fields.listing_phone_label, 'listing contact (usually the agent)');
  assert.equal(r.isFsbo, false, 'site nav "For Sale by Owner" link must not mark listing FSBO');
  assert.deepEqual(r.missing, []);
});

test('zillow: FSBO land labels phone as seller direct and reports missing fields', () => {
  const r = run('https://www.zillow.com/homedetails/y/2_zpid/', 'zillow-fsbo-land.html');
  assert.equal(r.isFsbo, true);
  assert.equal(r.fields.listing_phone, '(203) 555-0142');
  assert.equal(r.fields.listing_phone_label, 'seller direct (listing marked FSBO)');
  assert.ok(r.missing.includes('Beds'));
  assert.equal(r.fields.beds, undefined);
});

test('zillow: captcha page is reported as blocked with no data', () => {
  const r = run('https://www.zillow.com/homedetails/z/3_zpid/', 'zillow-captcha.html');
  assert.equal(r.ok, false);
  assert.deepEqual(r.fields, {});
  assert.match(r.failures[0], /bot-check/);
});

test('realtor: agent listing', () => {
  const r = run('https://www.realtor.com/realestateandhomes-detail/x', 'realtor-agent.html');
  assert.equal(r.ok, true);
  assert.equal(r.fields.list_price, 410000);
  assert.equal(r.fields.baths, 2.5);
  assert.equal(r.fields.lot_size, '21,780 sqft');
  assert.equal(r.fields.listing_phone, '(203) 555-0111');
  assert.equal(r.fields.city, 'Exampleville');
});

test('realtor: changed layout fails loudly and never grabs stray page numbers', () => {
  const r = run('https://www.realtor.com/realestateandhomes-detail/x', 'realtor-changed.html');
  assert.equal(r.ok, false);
  assert.equal(r.fields.listing_phone, undefined);
  assert.ok(r.failures.some((f) => /layout may have changed/.test(f)));
});

test('redfin: JSON-LD + listed-by phone, ignores site support number', () => {
  const r = run('https://www.redfin.com/CT/Sampleton/5-Fixture-Ct-06002/home/1', 'redfin-agent.html');
  assert.equal(r.ok, true);
  assert.equal(r.fields.list_price, 350000);
  assert.equal(r.fields.beds, 3);
  assert.equal(r.fields.sqft, 1720);
  assert.equal(r.fields.lot_size, '0.46 acres');
  assert.equal(r.fields.listing_phone, '(860) 555-0177');
});

test('redfin: page without listing data', () => {
  const r = run('https://www.redfin.com/CT/x', 'redfin-nothing.html');
  assert.equal(r.ok, false);
  assert.equal(r.fields.listing_phone, undefined);
});

test('unsupported and malformed URLs are rejected before any network call', async () => {
  let called = false;
  const fetchImpl = async () => { called = true; };
  assert.match((await importListing('https://example.com/house', { fetchImpl })).failures[0], /Unsupported site/);
  assert.match((await importListing('not a url', { fetchImpl })).failures[0], /not a valid URL/);
  assert.equal(called, false);
});

test('HTTP 403 and network errors are explained', async () => {
  const r403 = await importListing('https://www.zillow.com/homedetails/a', { fetchImpl: async () => new Response('no', { status: 403 }) });
  assert.match(r403.failures[0], /HTTP 403.*bot protection/s);
  const rErr = await importListing('https://www.zillow.com/homedetails/a', { fetchImpl: async () => { throw new TypeError('fetch failed', { cause: { code: 'ENOTFOUND' } }); } });
  assert.match(rErr.failures[0], /ENOTFOUND/);
});

test('deal type mapped from property type only when clear', () => {
  const r = run('https://www.zillow.com/homedetails/y/2_zpid/', 'zillow-fsbo-land.html');
  assert.equal(r.fields.deal_type, 'Vacant land');
  const r2 = run('https://www.zillow.com/homedetails/x/1_zpid/', 'zillow-agent.html');
  assert.equal(r2.fields.deal_type, 'Single-family');
  const r3 = run('https://www.realtor.com/realestateandhomes-detail/x', 'realtor-agent.html');
  assert.equal(r3.fields.deal_type, 'Single-family');
});

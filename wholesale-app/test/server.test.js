import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

process.env.WD_DATA_DIR = fs.mkdtempSync(path.join(os.tmpdir(), 'wd-test-'));
const { createApp } = await import('../server.js');

let server, base;
before(async () => {
  const { handler } = createApp({ dbFile: ':memory:', importer: async (url) => ({ ok: false, url, site: 'zillow', fields: {}, sources: {}, missing: [], failures: ['stubbed'] }) });
  server = http.createServer(handler);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  base = `http://127.0.0.1:${server.address().port}`;
});
after(() => server.close());

const call = async (method, url, body) => {
  const res = await fetch(base + url, { method, headers: { 'Content-Type': 'application/json' }, body: body && JSON.stringify(body) });
  return { status: res.status, body: await res.json() };
};

test('lead lifecycle with CT disclosure gate', async () => {
  const { body: lead } = await call('POST', '/api/leads', { address: '1 Main St', city: 'Hartford', deal_type: 'Single-family', asking_price: '$120,000' });
  assert.equal(lead.asking_price, 120000);
  assert.equal(lead.status, 'New');

  assert.equal((await call('POST', `/api/leads/${lead.id}/status`, { status: 'Offer Made' })).status, 200);
  const blocked = await call('POST', `/api/leads/${lead.id}/status`, { status: 'Under Contract' });
  assert.equal(blocked.status, 409);
  assert.match(blocked.body.blockers[0], /disclosure/);

  await call('PUT', `/api/leads/${lead.id}`, { ct_disclosure_signed: true });
  assert.equal((await call('POST', `/api/leads/${lead.id}/status`, { status: 'Under Contract' })).status, 200);

  // can't untick the disclosure while under contract
  assert.equal((await call('PUT', `/api/leads/${lead.id}`, { ct_disclosure_signed: false })).status, 409);

  await call('PUT', `/api/leads/${lead.id}`, { fee_collected: 12000 });
  await call('POST', `/api/leads/${lead.id}/status`, { status: 'Closed' });
  const { body: d } = await call('GET', '/api/dashboard');
  assert.equal(d.offersMade, 1);
  assert.equal(d.contracts, 1);
  assert.equal(d.feesCollected, 12000);
  assert.equal(d.byStatus.Closed, 1);
});

test('land checklist gate', async () => {
  const { body: lead } = await call('POST', '/api/leads', { address: 'Lot 4 Oak Rd', deal_type: 'Vacant land' });
  const r = await call('POST', `/api/leads/${lead.id}/status`, { status: 'Offer Made' });
  assert.equal(r.status, 409);
  await call('PUT', `/api/leads/${lead.id}`, { land_road: true, land_zoning: true, land_min_lot: true, land_utilities: true, land_wetlands: true });
  assert.equal((await call('POST', `/api/leads/${lead.id}/status`, { status: 'Offer Made' })).status, 200);
});

test('search across fields, comps, buyers and matches', async () => {
  const { body: lead } = await call('POST', '/api/leads', { address: '77 Elm St', city: 'Bristol', owner_name: 'Jane Q Owner', parcel_id: 'MBL-12-34', deal_type: 'Single-family', assignment_price: 150000 });
  assert.equal((await call('GET', '/api/leads?q=MBL-12')).body.length, 1);
  assert.equal((await call('GET', '/api/leads?q=jane%20bristol')).body.length, 1);
  assert.equal((await call('GET', '/api/leads?q=nomatchxyz')).body.length, 0);

  assert.equal((await call('POST', `/api/leads/${lead.id}/comps`, { address: 'x' })).status, 400);
  assert.equal((await call('POST', `/api/leads/${lead.id}/comps`, { sold_price: '210000' })).status, 200);

  await call('POST', '/api/buyers', { name: 'Fits LLC', areas: 'Bristol', property_types: 'Single-family', max_price: 200000 });
  await call('POST', '/api/buyers', { name: 'Elsewhere Inc', areas: 'Stamford' });
  const m = (await call('GET', `/api/leads/${lead.id}/matches`)).body;
  assert.deepEqual(m.buyers.filter((b) => b.match).map((b) => b.name), ['Fits LLC']);
});

test('bad numbers are rejected, not silently zeroed', async () => {
  const r = await call('POST', '/api/leads', { asking_price: 'abc' });
  assert.equal(r.status, 400);
});

test('cross-origin writes are refused', async () => {
  const res = await fetch(base + '/api/leads', { method: 'POST', headers: { Origin: 'https://evil.example', 'Content-Type': 'application/json' }, body: '{}' });
  assert.equal(res.status, 403);
});

import { test } from 'node:test';
import assert from 'node:assert/strict';
import { houseMao, landMao, arvFromComps, statusBlockers, matchBuyer, complianceWarnings } from '../shared/rules.js';

test('house MAO = ARV*0.70 - repairs - fee, with steps', () => {
  const r = houseMao({ arv: 200000, repairs: 30000, fee: 10000, asking: 90000 });
  assert.equal(r.mao, 100000);
  assert.equal(r.steps.length, 3);
  assert.equal(r.vsAsking.gap, 10000);
});

test('blank inputs are reported missing, never treated as zero', () => {
  const r = houseMao({ arv: 200000, repairs: '', fee: 10000 });
  assert.equal(r.mao, null);
  assert.deepEqual(r.missing, ['Repair estimate']);
});

test('land MAO = builder value - fee', () => {
  assert.equal(landMao({ lotPrice: 40000, builderValue: 75000, fee: 10000 }).mao, 65000);
});

test('ARV from comps: median, average, range', () => {
  const s = arvFromComps([{ sold_price: 100 }, { sold_price: 300 }, { sold_price: 200 }, { sold_price: null }]);
  assert.deepEqual([s.count, s.low, s.median, s.average, s.high], [3, 100, 200, 200, 300]);
  assert.equal(arvFromComps([]), null);
});

test('land deal blocked from Offer Made (and beyond) until checklist complete', () => {
  const lead = { deal_type: 'Vacant land', land_road: 1, land_zoning: 1, land_min_lot: 1, land_utilities: 1, land_wetlands: 0 };
  assert.equal(statusBlockers(lead, 'Contacted').length, 0);
  assert.equal(statusBlockers(lead, 'Offer Made').length, 1);
  assert.ok(statusBlockers(lead, 'Closed').length >= 1);
  assert.equal(statusBlockers({ ...lead, land_wetlands: 1 }, 'Offer Made').length, 0);
  assert.equal(statusBlockers({ deal_type: 'Single-family' }, 'Offer Made').length, 0);
});

test('Under Contract (and later) blocked until disclosure signed', () => {
  const b = statusBlockers({ deal_type: 'Single-family' }, 'Under Contract');
  assert.equal(b.length, 1);
  assert.match(b[0], /BEFORE the purchase contract/);
  assert.equal(statusBlockers({ deal_type: 'Single-family' }, 'Assigned').length, 1);
  assert.equal(statusBlockers({ deal_type: 'Single-family', ct_disclosure_signed: 1 }, 'Under Contract').length, 0);
  assert.equal(statusBlockers({}, 'Dead').length, 0);
});

test('compliance warnings for >90 days and late disclosure', () => {
  const w = complianceWarnings({ contract_date: '2026-01-01', closing_date: '2026-05-01', ct_disclosure_date: '2026-01-02', ct_closing_90: 1 });
  assert.equal(w.length, 3);
});

test('buyer matching on area, type, price', () => {
  const lead = { city: 'Hartford', zip: '06106', deal_type: 'Single-family', assignment_price: 150000 };
  assert.equal(matchBuyer({ areas: 'hartford, New Britain', property_types: 'Single-family', min_price: 100000, max_price: 200000 }, lead).match, true);
  assert.equal(matchBuyer({ areas: '06106' }, lead).match, true);
  assert.equal(matchBuyer({ areas: 'Bristol' }, lead).match, false);
  assert.equal(matchBuyer({ max_price: 100000 }, lead).match, false);
  assert.equal(matchBuyer({ property_types: 'Vacant land' }, lead).match, false);
  assert.equal(matchBuyer({}, lead).match, true);
});

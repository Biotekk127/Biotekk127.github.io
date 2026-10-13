// Business rules shared by the server (enforcement) and the browser (display).
// Pure functions only: no I/O, no network, no guessing. Every number returned
// here is derived from values the user typed or a successful listing import.

export const STATUSES = [
  'New',
  'Researching',
  'Contacted',
  'Offer Made',
  'Under Contract',
  'Assigned',
  'Closed',
  'Dead',
];

// Dead is a side exit, not a stage further along than Closed.
const PIPELINE = STATUSES.filter((s) => s !== 'Dead');

export const DEAL_TYPES = ['Single-family', 'Multi-family', 'Condo/Townhouse', 'Vacant land', 'Other'];

export const LEAD_SOURCES = [
  'Zillow',
  'Realtor.com',
  'Redfin',
  'Driving for dollars',
  'Direct mail',
  'Cold call / text',
  'Referral',
  'Facebook / Craigslist',
  'Tax / probate list',
  'Other',
];

export const LAND_CHECKLIST = [
  ['land_road', 'Paved road frontage'],
  ['land_zoning', 'Zoning allows residential'],
  ['land_min_lot', 'Meets minimum lot size'],
  ['land_utilities', 'Utilities reachable or perc test viable'],
  ['land_wetlands', 'Wetlands / inland wetlands checked'],
];

export const CT_CHECKLIST = [
  ['ct_registration', 'Wholesaler registration confirmed'],
  ['ct_disclosure_signed', 'Written DCP wholesale disclosure signed by seller BEFORE contract'],
  ['ct_closing_90', 'Closing date within 90 days of contract'],
  ['ct_assignment_clause', 'Assignment clause in contract'],
];

export function isLand(lead) {
  return lead?.deal_type === 'Vacant land';
}

function stageIndex(status) {
  return PIPELINE.indexOf(status);
}

/** True when `status` is `target` or a later pipeline stage (Dead never counts). */
export function atOrBeyond(status, target) {
  const i = stageIndex(status);
  return i !== -1 && i >= stageIndex(target);
}

const truthy = (v) => v === true || v === 1 || v === '1';

/**
 * Check whether a lead may be in `status`. Returns a list of blocking
 * problems (plain-language strings); an empty list means allowed.
 * Applied both when changing status and when editing a lead that is already
 * past a gate, so a gate can't be bypassed by skipping stages or unticking later.
 */
export function statusBlockers(lead, status) {
  const problems = [];
  if (!STATUSES.includes(status)) {
    problems.push(`Unknown status "${status}".`);
    return problems;
  }

  if (isLand(lead) && atOrBeyond(status, 'Offer Made')) {
    const missing = LAND_CHECKLIST.filter(([k]) => !truthy(lead[k])).map(([, label]) => label);
    if (missing.length) {
      problems.push(
        'Land buildability checklist is not complete. Before making an offer on vacant land, ' +
          'confirm every item so you are not locking up a lot that no builder can use. Still unchecked: ' +
          missing.join('; ') + '.'
      );
    }
  }

  if (atOrBeyond(status, 'Under Contract') && !truthy(lead.ct_disclosure_signed)) {
    problems.push(
      'The seller has not signed the written wholesale disclosure. In Connecticut the seller must ' +
        'receive and sign a written disclosure that you are a wholesaler (that you intend to assign ' +
        'or resell your contract rather than buy the property yourself) BEFORE the purchase contract ' +
        'is signed. Signing a contract without it can expose you to penalties and let the seller ' +
        'cancel. Get the disclosure signed first, tick the box on the Compliance tab, then move this ' +
        'deal to Under Contract.'
    );
  }

  return problems;
}

/** Non-blocking warnings about dates on the compliance checklist. */
export function complianceWarnings(lead) {
  const warnings = [];
  const days = daysBetween(lead.contract_date, lead.closing_date);
  if (days !== null) {
    if (days > 90) {
      warnings.push(`Closing date is ${days} days after the contract date — more than 90 days.`);
      if (truthy(lead.ct_closing_90)) {
        warnings.push('"Closing within 90 days" is ticked but the dates you entered disagree.');
      }
    } else if (days < 0) {
      warnings.push('Closing date is before the contract date.');
    }
  }
  if (lead.ct_disclosure_date && lead.contract_date && lead.ct_disclosure_date > lead.contract_date) {
    warnings.push('Disclosure date is AFTER the contract date. The disclosure must be signed before the contract.');
  }
  return warnings;
}

export function daysBetween(a, b) {
  if (!a || !b) return null;
  const da = Date.parse(a + 'T00:00:00Z');
  const db = Date.parse(b + 'T00:00:00Z');
  if (Number.isNaN(da) || Number.isNaN(db)) return null;
  return Math.round((db - da) / 86400000);
}

export function num(v) {
  if (v === null || v === undefined || v === '') return null;
  const n = typeof v === 'number' ? v : Number(String(v).replace(/[$,\s]/g, ''));
  return Number.isFinite(n) ? n : null;
}

/**
 * House MAO = (ARV × 0.70) − repairs − fee. Returns null result with a list of
 * missing inputs instead of assuming zero for anything not entered.
 */
export function houseMao({ arv, repairs, fee, asking }) {
  const a = num(arv), r = num(repairs), f = num(fee), ask = num(asking);
  const missing = [];
  if (a === null) missing.push('ARV');
  if (r === null) missing.push('Repair estimate');
  if (f === null) missing.push('Target fee');
  if (missing.length) return { mao: null, missing, steps: [] };
  const seventy = a * 0.7;
  const mao = seventy - r - f;
  const steps = [
    ['ARV × 0.70', `${fmtMoney(a)} × 0.70`, seventy],
    ['− Repairs', `${fmtMoney(seventy)} − ${fmtMoney(r)}`, seventy - r],
    ['− Your fee', `${fmtMoney(seventy - r)} − ${fmtMoney(f)}`, mao],
  ];
  const out = { mao, missing, steps };
  if (ask !== null) out.vsAsking = { asking: ask, gap: mao - ask };
  return out;
}

/**
 * Land: a builder pays `builderValue` for the lot; you keep `fee`.
 * Max you can offer the seller = builder value − fee.
 */
export function landMao({ lotPrice, builderValue, fee }) {
  const lp = num(lotPrice), bv = num(builderValue), f = num(fee);
  const missing = [];
  if (bv === null) missing.push('Builder resale value');
  if (f === null) missing.push('Target fee');
  if (missing.length) return { mao: null, missing, steps: [] };
  const mao = bv - f;
  const steps = [['Builder resale value − your fee', `${fmtMoney(bv)} − ${fmtMoney(f)}`, mao]];
  const out = { mao, missing, steps };
  if (lp !== null) out.vsAsking = { asking: lp, gap: mao - lp };
  return out;
}

/** ARV range from the user's own comps only. */
export function arvFromComps(comps) {
  const prices = comps.map((c) => num(c.sold_price)).filter((n) => n !== null && n > 0).sort((a, b) => a - b);
  if (!prices.length) return null;
  const sum = prices.reduce((s, n) => s + n, 0);
  const mid = Math.floor(prices.length / 2);
  const median = prices.length % 2 ? prices[mid] : (prices[mid - 1] + prices[mid]) / 2;
  const out = { count: prices.length, low: prices[0], high: prices[prices.length - 1], average: sum / prices.length, median };

  const ppsf = comps
    .map((c) => {
      const p = num(c.sold_price), s = num(c.sqft);
      return p && s ? p / s : null;
    })
    .filter((n) => n !== null)
    .sort((a, b) => a - b);
  if (ppsf.length) {
    const m = Math.floor(ppsf.length / 2);
    out.ppsfCount = ppsf.length;
    out.medianPpsf = ppsf.length % 2 ? ppsf[m] : (ppsf[m - 1] + ppsf[m]) / 2;
  }
  return out;
}

function splitList(s) {
  return String(s || '')
    .split(/[,;\n]/)
    .map((x) => x.trim().toLowerCase())
    .filter(Boolean);
}

/** The price a buyer would pay for this deal, with where it came from. */
export function dealPriceForBuyers(lead) {
  const ap = num(lead.assignment_price);
  if (ap !== null) return { price: ap, from: 'your assignment price' };
  const cp = num(lead.contract_price), fee = num(lead.target_fee);
  if (cp !== null && fee !== null) return { price: cp + fee, from: 'contract price + target fee' };
  const ask = num(lead.asking_price);
  if (ask !== null) return { price: ask, from: 'asking price' };
  const lp = num(lead.list_price);
  if (lp !== null) return { price: lp, from: 'list price (imported)' };
  return { price: null, from: null };
}

/**
 * Match one buyer against a deal. Empty buy-box fields mean "any".
 * Returns { match, reasons[] , misses[] }.
 */
export function matchBuyer(buyer, lead) {
  const reasons = [], misses = [];

  const areas = splitList(buyer.areas);
  if (areas.length) {
    const leadAreas = [lead.city, lead.zip].filter(Boolean).map((s) => String(s).trim().toLowerCase());
    const hit = areas.find((a) => leadAreas.includes(a));
    if (hit) reasons.push(`Area: ${hit}`);
    else misses.push(`Area not in buy box (${buyer.areas})`);
  } else reasons.push('Area: any');

  const types = splitList(buyer.property_types);
  if (types.length) {
    const t = String(lead.deal_type || '').toLowerCase();
    if (t && types.includes(t)) reasons.push(`Type: ${lead.deal_type}`);
    else misses.push(t ? `Type ${lead.deal_type} not in buy box` : 'Deal type not set on lead');
  } else reasons.push('Type: any');

  const { price, from } = dealPriceForBuyers(lead);
  const min = num(buyer.min_price), max = num(buyer.max_price);
  if (min === null && max === null) reasons.push('Price: any');
  else if (price === null) misses.push('No deal price entered to compare');
  else if ((min === null || price >= min) && (max === null || price <= max)) reasons.push(`Price ${fmtMoney(price)} (${from}) in range`);
  else misses.push(`Price ${fmtMoney(price)} (${from}) outside ${fmtMoney(min)}–${fmtMoney(max)}`);

  return { match: misses.length === 0, reasons, misses };
}

export function fmtMoney(n) {
  if (n === null || n === undefined || !Number.isFinite(n)) return '—';
  const sign = n < 0 ? '−' : '';
  return sign + '$' + Math.abs(Math.round(n)).toLocaleString('en-US');
}

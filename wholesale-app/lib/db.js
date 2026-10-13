// Local SQLite database (Node's built-in node:sqlite — no install, no server).
// The file lives at wholesale-app/data/wholesale.db and never leaves this machine.
import { DatabaseSync } from 'node:sqlite';
import fs from 'node:fs';
import path from 'node:path';

export const LEAD_FIELDS = {
  // identity
  deal_type: 'TEXT',
  address: 'TEXT',
  city: 'TEXT',
  state: "TEXT DEFAULT 'CT'",
  zip: 'TEXT',
  parcel_id: 'TEXT',
  owner_name: 'TEXT',
  asking_price: 'REAL',
  source: 'TEXT',
  notes: 'TEXT',
  links: "TEXT DEFAULT '[]'", // JSON array of {label,url}
  // owner contact (found by the user via free sources)
  owner_phone: 'TEXT',
  owner_email: 'TEXT',
  owner_contact_source: 'TEXT',
  assessor_url: 'TEXT',
  // listing import
  listing_url: 'TEXT',
  list_price: 'REAL',
  beds: 'REAL',
  baths: 'REAL',
  sqft: 'REAL',
  lot_size: 'TEXT',
  property_type: 'TEXT',
  listing_phone: 'TEXT',
  listing_phone_label: 'TEXT',
  listing_imported_at: 'TEXT',
  // analyzer
  arv: 'REAL',
  repairs: 'REAL',
  target_fee: 'REAL',
  land_lot_price: 'REAL',
  land_builder_value: 'REAL',
  land_road: 'INTEGER DEFAULT 0',
  land_zoning: 'INTEGER DEFAULT 0',
  land_min_lot: 'INTEGER DEFAULT 0',
  land_utilities: 'INTEGER DEFAULT 0',
  land_wetlands: 'INTEGER DEFAULT 0',
  // deal
  offer_amount: 'REAL',
  contract_price: 'REAL',
  assignment_price: 'REAL',
  fee_collected: 'REAL',
  // CT compliance
  ct_registration: 'INTEGER DEFAULT 0',
  ct_disclosure_signed: 'INTEGER DEFAULT 0',
  ct_disclosure_date: 'TEXT',
  ct_closing_90: 'INTEGER DEFAULT 0',
  ct_assignment_clause: 'INTEGER DEFAULT 0',
  contract_date: 'TEXT',
  closing_date: 'TEXT',
};

export const BUYER_FIELDS = {
  name: 'TEXT NOT NULL',
  phone: 'TEXT',
  email: 'TEXT',
  areas: 'TEXT',
  min_price: 'REAL',
  max_price: 'REAL',
  property_types: 'TEXT',
  pof_notes: 'TEXT',
  notes: 'TEXT',
};

export const COMP_FIELDS = {
  address: 'TEXT',
  sold_price: 'REAL',
  sold_date: 'TEXT',
  beds: 'REAL',
  baths: 'REAL',
  sqft: 'REAL',
  distance_mi: 'REAL',
  notes: 'TEXT',
};

function cols(fields) {
  return Object.entries(fields).map(([k, t]) => `${k} ${t}`).join(',\n  ');
}

export function openDb(file) {
  if (file !== ':memory:') fs.mkdirSync(path.dirname(file), { recursive: true });
  const db = new DatabaseSync(file);
  db.exec(`
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
CREATE TABLE IF NOT EXISTS leads (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  status TEXT NOT NULL DEFAULT 'New',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  ${cols(LEAD_FIELDS)}
);
CREATE TABLE IF NOT EXISTS status_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  from_status TEXT,
  to_status TEXT NOT NULL,
  at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS comps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  ${cols(COMP_FIELDS)}
);
CREATE TABLE IF NOT EXISTS buyers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  ${cols(BUYER_FIELDS)}
);
CREATE TABLE IF NOT EXISTS photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
  filename TEXT NOT NULL,
  original_name TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS import_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  lead_id INTEGER REFERENCES leads(id) ON DELETE SET NULL,
  url TEXT,
  site TEXT,
  ok INTEGER,
  detail TEXT,
  at TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE TABLE IF NOT EXISTS town_links (
  town TEXT PRIMARY KEY,
  assessor_url TEXT
);
`);
  // Add any columns introduced after the database was first created.
  addMissingColumns(db, 'leads', LEAD_FIELDS);
  addMissingColumns(db, 'buyers', BUYER_FIELDS);
  addMissingColumns(db, 'comps', COMP_FIELDS);
  return db;
}

function addMissingColumns(db, table, fields) {
  const have = new Set(db.prepare(`PRAGMA table_info(${table})`).all().map((r) => r.name));
  for (const [k, t] of Object.entries(fields)) {
    if (!have.has(k)) db.exec(`ALTER TABLE ${table} ADD COLUMN ${k} ${t.replace('NOT NULL', '')}`);
  }
}

const REAL = (t) => t.startsWith('REAL');
const INT = (t) => t.startsWith('INTEGER');

/** Keep only known fields and coerce types. Blank strings become NULL (never 0). */
export function clean(fields, input) {
  const out = {};
  for (const [k, t] of Object.entries(fields)) {
    if (!(k in input)) continue;
    let v = input[k];
    if (v === undefined) continue;
    if (k === 'links' && typeof v !== 'string') v = JSON.stringify(Array.isArray(v) ? v : []);
    if (REAL(t)) {
      if (v === null || v === '') v = null;
      else {
        const n = Number(String(v).replace(/[$,\s]/g, ''));
        if (!Number.isFinite(n)) throw new Error(`${k} must be a number`);
        v = n;
      }
    } else if (INT(t)) {
      v = v === true || v === 1 || v === '1' || v === 'on' ? 1 : 0;
    } else {
      v = v === null ? null : String(v).trim();
      if (v === '') v = null;
    }
    out[k] = v;
  }
  return out;
}

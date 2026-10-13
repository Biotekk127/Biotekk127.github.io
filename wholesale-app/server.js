// Wholesale Desk — local-only server. Listens on 127.0.0.1 so nothing outside
// this computer can reach it. Run with: npm start  (or: node server.js)
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { openDb, clean, LEAD_FIELDS, BUYER_FIELDS, COMP_FIELDS } from './lib/db.js';
import { importListing } from './lib/importer.js';
import { STATUSES, statusBlockers, matchBuyer, dealPriceForBuyers } from './shared/rules.js';

const ROOT = path.dirname(fileURLToPath(import.meta.url));
const DATA_DIR = process.env.WD_DATA_DIR || path.join(ROOT, 'data');
const UPLOAD_DIR = path.join(DATA_DIR, 'uploads');
const IMPORT_LOG = path.join(DATA_DIR, 'import.log');
const PORT = Number(process.env.PORT) || 3000;
const HOST = '127.0.0.1';

export function createApp({ dbFile = path.join(DATA_DIR, 'wholesale.db'), importer = importListing } = {}) {
  const db = openDb(dbFile);

  // ---------- helpers ----------
  const leadById = (id) => db.prepare('SELECT * FROM leads WHERE id = ?').get(id);

  function insert(table, data) {
    const keys = Object.keys(data);
    if (!keys.length) return db.prepare(`INSERT INTO ${table} DEFAULT VALUES`).run().lastInsertRowid;
    const sql = `INSERT INTO ${table} (${keys.join(',')}) VALUES (${keys.map(() => '?').join(',')})`;
    return db.prepare(sql).run(...keys.map((k) => data[k])).lastInsertRowid;
  }
  function update(table, id, data, touch = false) {
    const keys = Object.keys(data);
    if (!keys.length && !touch) return;
    const sets = keys.map((k) => `${k} = ?`);
    if (touch) sets.push("updated_at = datetime('now')");
    db.prepare(`UPDATE ${table} SET ${sets.join(', ')} WHERE id = ?`).run(...keys.map((k) => data[k]), id);
  }

  function logImport(leadId, result) {
    const detail = JSON.stringify({ fields: result.fields, sources: result.sources, failures: result.failures });
    db.prepare('INSERT INTO import_log (lead_id, url, site, ok, detail) VALUES (?,?,?,?,?)')
      .run(leadId ?? null, result.url ?? null, result.site ?? null, result.ok ? 1 : 0, detail);
    const line = `[${new Date().toISOString()}] ${result.ok ? 'OK  ' : 'FAIL'} ${result.site || '?'} ${result.url}\n` +
      (result.failures.length ? result.failures.map((f) => `    - ${f}\n`).join('') : '') +
      Object.entries(result.sources || {}).map(([k, s]) => `    ${k} <- ${s}\n`).join('');
    try {
      fs.mkdirSync(DATA_DIR, { recursive: true });
      fs.appendFileSync(IMPORT_LOG, line);
    } catch { /* logging must never break the import */ }
    (result.ok ? console.log : console.warn)(line.trimEnd());
  }

  const SEARCHABLE = Object.entries(LEAD_FIELDS).map(([k]) => k).concat(['status']);

  // ---------- routes ----------
  const routes = [];
  const route = (method, pattern, handler) => {
    const keys = [];
    const re = new RegExp('^' + pattern.replace(/:(\w+)/g, (_, k) => (keys.push(k), '([^/]+)')) + '$');
    routes.push({ method, re, keys, handler });
  };

  route('GET', '/api/meta', () => ({ statuses: STATUSES }));

  route('GET', '/api/leads', (req, _p, query) => {
    const where = [], args = [];
    const q = (query.get('q') || '').trim();
    if (q) {
      for (const term of q.split(/\s+/)) {
        where.push('(' + SEARCHABLE.map((c) => `COALESCE(CAST(${c} AS TEXT),'') LIKE ?`).join(' OR ') + ')');
        SEARCHABLE.forEach(() => args.push(`%${term}%`));
      }
    }
    for (const f of ['status', 'deal_type', 'source']) {
      const v = query.get(f);
      if (v) { where.push(`${f} = ?`); args.push(v); }
    }
    const sql = `SELECT * FROM leads ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY updated_at DESC, id DESC`;
    return db.prepare(sql).all(...args);
  });

  route('POST', '/api/leads', async (req) => {
    const body = await readJson(req);
    const data = clean(LEAD_FIELDS, body);
    const id = insert('leads', data);
    db.prepare("INSERT INTO status_history (lead_id, from_status, to_status) VALUES (?, NULL, 'New')").run(id);
    return leadById(id);
  });

  route('GET', '/api/leads/:id', (req, p) => {
    const lead = leadById(p.id);
    if (!lead) throw httpError(404, 'Lead not found');
    lead.history = db.prepare('SELECT * FROM status_history WHERE lead_id = ? ORDER BY id').all(p.id);
    lead.photos = db.prepare('SELECT * FROM photos WHERE lead_id = ? ORDER BY id').all(p.id);
    lead.imports = db.prepare('SELECT id, url, site, ok, detail, at FROM import_log WHERE lead_id = ? ORDER BY id DESC LIMIT 10').all(p.id);
    return lead;
  });

  route('PUT', '/api/leads/:id', async (req, p) => {
    const lead = leadById(p.id);
    if (!lead) throw httpError(404, 'Lead not found');
    const data = clean(LEAD_FIELDS, await readJson(req));
    // An edit may not undo a gate the lead has already passed (e.g. unticking the disclosure).
    const blockers = statusBlockers({ ...lead, ...data }, lead.status);
    if (blockers.length) {
      throw httpError(409, `This change conflicts with the lead's current status "${lead.status}". Move the lead back to an earlier status first.`, blockers);
    }
    update('leads', p.id, data, true);
    return leadById(p.id);
  });

  route('POST', '/api/leads/:id/status', async (req, p) => {
    const lead = leadById(p.id);
    if (!lead) throw httpError(404, 'Lead not found');
    const { status } = await readJson(req);
    const blockers = statusBlockers(lead, status);
    if (blockers.length) throw httpError(409, `Can't move to "${status}" yet.`, blockers);
    if (status !== lead.status) {
      db.prepare("UPDATE leads SET status = ?, updated_at = datetime('now') WHERE id = ?").run(status, p.id);
      db.prepare('INSERT INTO status_history (lead_id, from_status, to_status) VALUES (?,?,?)').run(p.id, lead.status, status);
    }
    return leadById(p.id);
  });

  route('DELETE', '/api/leads/:id', (req, p) => {
    for (const ph of db.prepare('SELECT filename FROM photos WHERE lead_id = ?').all(p.id)) {
      fs.rmSync(path.join(UPLOAD_DIR, ph.filename), { force: true });
    }
    db.prepare('DELETE FROM leads WHERE id = ?').run(p.id);
    return { ok: true };
  });

  // Listing import (the app's only outbound network call)
  route('POST', '/api/import', async (req) => {
    const { url, lead_id } = await readJson(req);
    if (!url) throw httpError(400, 'Paste a listing URL first.');
    const result = await importer(url);
    logImport(lead_id && leadById(lead_id) ? lead_id : null, result);
    return result;
  });

  // Comps
  route('GET', '/api/leads/:id/comps', (req, p) => db.prepare('SELECT * FROM comps WHERE lead_id = ? ORDER BY id').all(p.id));
  route('POST', '/api/leads/:id/comps', async (req, p) => {
    if (!leadById(p.id)) throw httpError(404, 'Lead not found');
    const data = clean(COMP_FIELDS, await readJson(req));
    if (data.sold_price === undefined || data.sold_price === null) throw httpError(400, 'A comp needs a sold price.');
    const id = insert('comps', { ...data, lead_id: Number(p.id) });
    return db.prepare('SELECT * FROM comps WHERE id = ?').get(id);
  });
  route('DELETE', '/api/comps/:id', (req, p) => (db.prepare('DELETE FROM comps WHERE id = ?').run(p.id), { ok: true }));

  // Buyers
  route('GET', '/api/buyers', () => db.prepare('SELECT * FROM buyers ORDER BY name COLLATE NOCASE').all());
  route('POST', '/api/buyers', async (req) => {
    const data = clean(BUYER_FIELDS, await readJson(req));
    if (!data.name) throw httpError(400, 'Buyer name is required.');
    return db.prepare('SELECT * FROM buyers WHERE id = ?').get(insert('buyers', data));
  });
  route('PUT', '/api/buyers/:id', async (req, p) => {
    const data = clean(BUYER_FIELDS, await readJson(req));
    if ('name' in data && !data.name) throw httpError(400, 'Buyer name is required.');
    update('buyers', p.id, data);
    return db.prepare('SELECT * FROM buyers WHERE id = ?').get(p.id);
  });
  route('DELETE', '/api/buyers/:id', (req, p) => (db.prepare('DELETE FROM buyers WHERE id = ?').run(p.id), { ok: true }));

  route('GET', '/api/leads/:id/matches', (req, p) => {
    const lead = leadById(p.id);
    if (!lead) throw httpError(404, 'Lead not found');
    const buyers = db.prepare('SELECT * FROM buyers ORDER BY name COLLATE NOCASE').all();
    return {
      dealPrice: dealPriceForBuyers(lead),
      buyers: buyers.map((b) => ({ ...b, ...matchBuyer(b, lead) })),
    };
  });

  // Photos (stored as files under data/uploads)
  route('POST', '/api/leads/:id/photos', async (req, p) => {
    if (!leadById(p.id)) throw httpError(404, 'Lead not found');
    const { name, data } = await readJson(req);
    const ext = path.extname(String(name || '')).toLowerCase();
    if (!['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].includes(ext)) throw httpError(400, 'Only image files (jpg, png, gif, webp, heic) can be uploaded.');
    const buf = Buffer.from(String(data || ''), 'base64');
    if (!buf.length) throw httpError(400, 'Empty file.');
    const filename = `${p.id}/${Date.now()}-${Math.random().toString(36).slice(2, 8)}${ext}`;
    fs.mkdirSync(path.join(UPLOAD_DIR, String(p.id)), { recursive: true });
    fs.writeFileSync(path.join(UPLOAD_DIR, filename), buf);
    const id = db.prepare('INSERT INTO photos (lead_id, filename, original_name) VALUES (?,?,?)').run(p.id, filename, String(name)).lastInsertRowid;
    return db.prepare('SELECT * FROM photos WHERE id = ?').get(id);
  });
  route('DELETE', '/api/photos/:id', (req, p) => {
    const ph = db.prepare('SELECT * FROM photos WHERE id = ?').get(p.id);
    if (ph) {
      fs.rmSync(path.join(UPLOAD_DIR, ph.filename), { force: true });
      db.prepare('DELETE FROM photos WHERE id = ?').run(p.id);
    }
    return { ok: true };
  });

  // Saved assessor links per town (CT property records are kept by each town)
  route('GET', '/api/town-links', () => db.prepare('SELECT * FROM town_links ORDER BY town').all());
  route('PUT', '/api/town-links', async (req) => {
    const { town, assessor_url } = await readJson(req);
    const t = String(town || '').trim().toLowerCase();
    if (!t) throw httpError(400, 'Town is required.');
    const u = String(assessor_url || '').trim();
    if (!u) db.prepare('DELETE FROM town_links WHERE town = ?').run(t);
    else {
      if (!/^https?:\/\//i.test(u)) throw httpError(400, 'Link must start with http:// or https://');
      db.prepare('INSERT INTO town_links (town, assessor_url) VALUES (?,?) ON CONFLICT(town) DO UPDATE SET assessor_url = excluded.assessor_url').run(t, u);
    }
    return { ok: true };
  });

  route('GET', '/api/dashboard', () => {
    const byStatus = Object.fromEntries(STATUSES.map((s) => [s, 0]));
    for (const r of db.prepare('SELECT status, COUNT(*) n FROM leads GROUP BY status').all()) byStatus[r.status] = r.n;
    const total = Object.values(byStatus).reduce((a, b) => a + b, 0);
    const reached = (stages) =>
      db.prepare(`SELECT COUNT(DISTINCT lead_id) n FROM status_history WHERE to_status IN (${stages.map(() => '?').join(',')}) AND lead_id IN (SELECT id FROM leads)`).get(...stages).n;
    const offersMade = reached(['Offer Made', 'Under Contract', 'Assigned', 'Closed']);
    const contracts = reached(['Under Contract', 'Assigned', 'Closed']);
    const closedRow = db.prepare("SELECT COUNT(*) n, SUM(fee_collected) fees, SUM(CASE WHEN fee_collected IS NULL THEN 1 ELSE 0 END) missing FROM leads WHERE status = 'Closed'").get();
    return {
      total,
      byStatus,
      offersMade,
      contracts,
      closed: closedRow.n,
      feesCollected: closedRow.fees ?? 0,
      closedMissingFee: closedRow.missing ?? 0,
    };
  });

  // ---------- request handling ----------
  const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8',
    '.png': 'image/png', '.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.webp': 'image/webp', '.heic': 'image/heic', '.svg': 'image/svg+xml' };

  function serveFile(res, base, rel) {
    const file = path.resolve(base, '.' + path.posix.normalize('/' + rel));
    if (!file.startsWith(path.resolve(base) + path.sep)) return send(res, 403, { error: 'Forbidden' });
    fs.readFile(file, (err, buf) => {
      if (err) return send(res, 404, { error: 'Not found' });
      res.writeHead(200, { 'Content-Type': MIME[path.extname(file).toLowerCase()] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
      res.end(buf);
    });
  }

  async function handler(req, res) {
    const u = new URL(req.url, 'http://localhost');
    const pathname = decodeURIComponent(u.pathname);
    if (pathname.startsWith('/api/')) {
      // Reject cross-site writes from other web pages open in your browser.
      if (req.method !== 'GET' && req.headers.origin && !/^http:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/.test(req.headers.origin)) {
        return send(res, 403, { error: 'Cross-origin request refused' });
      }
      for (const r of routes) {
        if (r.method !== req.method) continue;
        const m = pathname.match(r.re);
        if (!m) continue;
        const params = Object.fromEntries(r.keys.map((k, i) => [k, m[i + 1]]));
        try {
          return send(res, 200, await r.handler(req, params, u.searchParams));
        } catch (err) {
          if (err.status) return send(res, err.status, { error: err.message, blockers: err.blockers });
          if (/must be a number/.test(err.message)) return send(res, 400, { error: err.message });
          console.error(err);
          return send(res, 500, { error: err.message });
        }
      }
      return send(res, 404, { error: 'No such API route' });
    }
    if (pathname.startsWith('/uploads/')) return serveFile(res, UPLOAD_DIR, pathname.slice('/uploads/'.length));
    if (pathname.startsWith('/shared/')) return serveFile(res, path.join(ROOT, 'shared'), pathname.slice('/shared/'.length));
    return serveFile(res, path.join(ROOT, 'public'), pathname === '/' ? 'index.html' : pathname.slice(1));
  }

  return { db, handler };
}

function httpError(status, message, blockers) {
  return Object.assign(new Error(message), { status, blockers });
}

function send(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(body));
}

const MAX_BODY = 25 * 1024 * 1024;
function readJson(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    req.on('data', (c) => {
      size += c.length;
      if (size > MAX_BODY) { reject(httpError(413, 'Upload too large (25 MB max).')); req.destroy(); }
      else chunks.push(c);
    });
    req.on('end', () => {
      if (!chunks.length) return resolve({});
      try { resolve(JSON.parse(Buffer.concat(chunks).toString('utf8'))); }
      catch { reject(httpError(400, 'Invalid JSON body')); }
    });
    req.on('error', reject);
  });
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const { handler } = createApp();
  http.createServer(handler).listen(PORT, HOST, () => {
    console.log(`Wholesale Desk running at http://${HOST}:${PORT}  (data: ${DATA_DIR})`);
  });
}

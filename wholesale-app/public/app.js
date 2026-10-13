import {
  STATUSES, DEAL_TYPES, LEAD_SOURCES, LAND_CHECKLIST, CT_CHECKLIST,
  isLand, statusBlockers, complianceWarnings, daysBetween, houseMao, landMao,
  arvFromComps, fmtMoney, num,
} from '/shared/rules.js';

const app = document.getElementById('app');

// ---------- utilities ----------
const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const money = (v) => (num(v) === null ? '—' : fmtMoney(num(v)));
const n0 = (v) => (num(v) === null ? '—' : num(v).toLocaleString('en-US'));
const enc = encodeURIComponent;

async function api(method, url, body) {
  const res = await fetch(url, {
    method,
    headers: body ? { 'Content-Type': 'application/json' } : {},
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw Object.assign(new Error(data.error || `HTTP ${res.status}`), { blockers: data.blockers, status: res.status });
  return data;
}

let toastTimer;
function toast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (t.hidden = true), 2600);
}

function errorBox(err) {
  return `<div class="alert bad"><strong>${esc(err.message)}</strong>${
    err.blockers?.length ? `<ul>${err.blockers.map((b) => `<li>${esc(b)}</li>`).join('')}</ul>` : ''
  }</div>`;
}

/** Collect a form's named inputs into an object (checkboxes → booleans). */
function formData(form) {
  const out = {};
  for (const el of form.elements) {
    if (!el.name) continue;
    out[el.name] = el.type === 'checkbox' ? el.checked : el.value;
  }
  return out;
}

function field(name, label, value, { type = 'text', options, wide, placeholder = '', step } = {}) {
  let input;
  if (options) {
    input = `<select name="${name}"><option value=""></option>${options
      .map((o) => `<option ${o === value ? 'selected' : ''}>${esc(o)}</option>`).join('')}</select>`;
  } else if (type === 'textarea') {
    input = `<textarea name="${name}" placeholder="${esc(placeholder)}">${esc(value)}</textarea>`;
  } else {
    input = `<input name="${name}" type="${type}" value="${esc(value)}" placeholder="${esc(placeholder)}" ${step ? `step="${step}"` : ''}>`;
  }
  return `<label class="f ${wide ? 'wide' : ''}">${esc(label)}${input}</label>`;
}
const moneyField = (name, label, value, opts = {}) => field(name, label, value ?? '', { type: 'number', step: 'any', ...opts });
const check = (name, label, checked) =>
  `<label class="check"><input type="checkbox" name="${name}" ${checked ? 'checked' : ''}> <span>${esc(label)}</span></label>`;

function setNav(key) {
  document.querySelectorAll('[data-nav]').forEach((a) => a.classList.toggle('active', a.dataset.nav === key));
}

const addressLine = (l) => [l.address, l.city, [l.state, l.zip].filter(Boolean).join(' ')].filter(Boolean).join(', ');

// ---------- router ----------
async function route() {
  const parts = location.hash.replace(/^#\/?/, '').split('/').filter(Boolean);
  try {
    if (!parts.length) return await dashboard();
    if (parts[0] === 'leads') return await leadsView();
    if (parts[0] === 'lead' && parts[1] === 'new') return newLeadView();
    if (parts[0] === 'lead') return await leadView(parts[1], parts[2] || 'details');
    if (parts[0] === 'buyers') return await buyersView(parts[1]);
    app.innerHTML = '<p>Not found.</p>';
  } catch (err) {
    app.innerHTML = errorBox(err);
  }
}
window.addEventListener('hashchange', route);
route();

// ---------- dashboard ----------
async function dashboard() {
  setNav('dashboard');
  const d = await api('GET', '/api/dashboard');
  const max = Math.max(1, ...Object.values(d.byStatus));
  const pct = (a, b) => (b ? `${((a / b) * 100).toFixed(1)}%` : '—');
  app.innerHTML = `
    <h1>Dashboard</h1>
    <p class="muted">Counts come only from leads in your local database.</p>
    <div class="stats">
      <div class="stat"><div class="v">${d.total}</div><div class="l">Total leads</div></div>
      <div class="stat"><div class="v">${d.offersMade}</div><div class="l">Offers made<br><span class="small">leads that ever reached Offer Made</span></div></div>
      <div class="stat"><div class="v">${d.contracts}</div><div class="l">Contracts signed<br><span class="small">leads that ever reached Under Contract</span></div></div>
      <div class="stat"><div class="v">${fmtMoney(d.feesCollected)}</div><div class="l">Fees collected<br><span class="small">sum of "fee collected" on Closed deals</span></div></div>
      <div class="stat"><div class="v">${pct(d.contracts, d.offersMade)}</div><div class="l">Offer → contract<br><span class="small">${d.contracts} of ${d.offersMade} offers</span></div></div>
      <div class="stat"><div class="v">${pct(d.closed, d.total)}</div><div class="l">Lead → closed<br><span class="small">${d.closed} of ${d.total} leads</span></div></div>
    </div>
    ${d.closedMissingFee ? `<div class="alert warn">${d.closedMissingFee} closed deal(s) have no "fee collected" entered, so they count as $0 above.</div>` : ''}
    <div class="panel" style="margin-top:16px">
      <h2>Pipeline</h2>
      ${STATUSES.map((s) => `
        <div class="bar"><a class="name" href="#/leads?status=${enc(s)}">${esc(s)}</a>
          <div class="track"><div class="fill" style="width:${(d.byStatus[s] / max) * 100}%"></div></div>
          <span class="n">${d.byStatus[s]}</span></div>`).join('')}
    </div>`;
  app.querySelectorAll('.bar a').forEach((a) => a.addEventListener('click', (e) => {
    e.preventDefault();
    sessionStorage.setItem('leadFilters', JSON.stringify({ status: decodeURIComponent(a.getAttribute('href').split('=')[1]) }));
    location.hash = '#/leads';
  }));
}

// ---------- leads list ----------
async function leadsView() {
  setNav('leads');
  let filters = {};
  try { filters = JSON.parse(sessionStorage.getItem('leadFilters') || '{}'); } catch {}
  app.innerHTML = `
    <div class="row"><h1>Leads</h1><span class="spacer"></span>
      <a class="btn" href="#/lead/new">+ New lead</a></div>
    <div class="panel">
      <form id="filters" class="row">
        <input name="q" placeholder="Search address, owner, parcel, notes, phone…" style="flex:1;min-width:240px" value="${esc(filters.q)}">
        <select name="status"><option value="">All statuses</option>${STATUSES.map((s) => `<option ${s === filters.status ? 'selected' : ''}>${s}</option>`).join('')}</select>
        <select name="deal_type"><option value="">All types</option>${DEAL_TYPES.map((s) => `<option ${s === filters.deal_type ? 'selected' : ''}>${s}</option>`).join('')}</select>
        <select name="source"><option value="">All sources</option>${LEAD_SOURCES.map((s) => `<option ${s === filters.source ? 'selected' : ''}>${s}</option>`).join('')}</select>
      </form>
    </div>
    <div class="panel" id="list"></div>`;
  const form = app.querySelector('#filters');
  const load = async () => {
    const f = formData(form);
    sessionStorage.setItem('leadFilters', JSON.stringify(f));
    const qs = new URLSearchParams(Object.entries(f).filter(([, v]) => v)).toString();
    const leads = await api('GET', '/api/leads?' + qs);
    const list = app.querySelector('#list');
    if (!leads.length) {
      list.innerHTML = `<p class="muted">No leads${qs ? ' match these filters' : ' yet — click “New lead” to add one'}.</p>`;
      return;
    }
    list.innerHTML = `<table><thead><tr><th>Address</th><th>Type</th><th>Owner</th><th>Source</th><th class="num">Asking</th><th>Status</th><th>Updated</th></tr></thead><tbody>
      ${leads.map((l) => `<tr class="click" data-id="${l.id}">
        <td><strong>${esc(l.address || '(no address)')}</strong><div class="small muted">${esc([l.city, l.zip].filter(Boolean).join(' '))}${l.parcel_id ? ' · parcel ' + esc(l.parcel_id) : ''}</div></td>
        <td>${l.deal_type ? `<span class="pill ${isLand(l) ? 'land' : ''}">${esc(l.deal_type)}</span>` : ''}</td>
        <td>${esc(l.owner_name)}</td><td>${esc(l.source)}</td>
        <td class="num">${money(l.asking_price ?? l.list_price)}</td>
        <td><span class="pill ${esc(l.status)}">${esc(l.status)}</span></td>
        <td class="small muted">${esc(l.updated_at.slice(0, 10))}</td></tr>`).join('')}
      </tbody></table><p class="small muted">${leads.length} lead(s)</p>`;
    list.querySelectorAll('tr.click').forEach((tr) => tr.addEventListener('click', () => (location.hash = `#/lead/${tr.dataset.id}`)));
  };
  let t;
  form.addEventListener('input', () => { clearTimeout(t); t = setTimeout(load, 200); });
  form.addEventListener('submit', (e) => e.preventDefault());
  await load();
}

// ---------- new lead ----------
function newLeadView() {
  setNav('leads');
  app.innerHTML = `
    <h1>New lead</h1>
    <div class="panel">
      <h2>Option A — import from a listing URL</h2>
      <p class="muted small">Paste a Zillow, Realtor.com or Redfin listing link. The app downloads that one public page and fills in only what it actually finds.</p>
      ${importBox()}
    </div>
    <div class="panel">
      <h2>Option B — enter it yourself</h2>
      <form id="f">${leadCoreFields({ state: 'CT' })}
        <div class="row" style="margin-top:12px"><button class="primary">Create lead</button></div>
      </form>
      <div id="err"></div>
    </div>`;
  app.querySelector('#f').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      const lead = await api('POST', '/api/leads', formData(e.target));
      location.hash = `#/lead/${lead.id}`;
    } catch (err) { app.querySelector('#err').innerHTML = errorBox(err); }
  });
  wireImport(null);
}

function leadCoreFields(l) {
  return `<div class="grid">
    ${field('address', 'Street address', l.address)}
    ${field('city', 'Town / city', l.city)}
    ${field('state', 'State', l.state)}
    ${field('zip', 'ZIP', l.zip)}
    ${field('deal_type', 'Deal type', l.deal_type, { options: DEAL_TYPES })}
    ${field('parcel_id', 'Parcel ID / Map-Block-Lot', l.parcel_id)}
    ${field('owner_name', 'Owner name', l.owner_name)}
    ${moneyField('asking_price', 'Asking price ($)', l.asking_price)}
    ${field('source', 'Lead source', l.source, { options: LEAD_SOURCES })}
    ${field('notes', 'Notes', l.notes, { type: 'textarea', wide: true })}
  </div>`;
}

// ---------- listing import widget ----------
function importBox(lead) {
  return `<form class="row" id="importForm">
      <input name="url" type="url" required placeholder="https://www.zillow.com/homedetails/…" style="flex:1;min-width:280px" value="${esc(lead?.listing_url)}">
      <button class="primary">Import</button>
    </form>
    <div id="importResult"></div>`;
}

const IMPORT_LABELS = {
  list_price: 'List price', beds: 'Beds', baths: 'Baths', sqft: 'Square feet', lot_size: 'Lot size',
  property_type: 'Property type', deal_type: 'Deal type', listing_phone: 'Contact phone', address: 'Street address', city: 'Town / city',
  state: 'State', zip: 'ZIP', parcel_id: 'Parcel ID',
};

function wireImport(lead) {
  const form = app.querySelector('#importForm');
  const out = app.querySelector('#importResult');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const url = form.url.value.trim();
    out.innerHTML = '<p class="muted">Fetching the listing page…</p>';
    form.querySelector('button').disabled = true;
    let r;
    try { r = await api('POST', '/api/import', { url, lead_id: lead?.id }); }
    catch (err) { out.innerHTML = errorBox(err); return; }
    finally { form.querySelector('button').disabled = false; }

    const keys = Object.keys(IMPORT_LABELS).filter((k) => r.fields[k] !== undefined);
    out.innerHTML = `
      ${r.ok ? `<div class="alert ok"><strong>Imported from ${esc(r.site)}: found ${keys.length} field(s).</strong></div>`
             : `<div class="alert bad"><strong>Import failed${r.site ? ` (${esc(r.site)})` : ''}. Nothing was filled in — enter the details manually.</strong></div>`}
      ${r.failures.length ? `<div class="alert ${r.ok ? 'warn' : 'bad'}"><strong>What went wrong / what's missing</strong><ul>${r.failures.map((f) => `<li>${esc(f)}</li>`).join('')}</ul></div>` : ''}
      ${keys.length ? `
        <form id="applyForm">
        <table><thead><tr><th></th><th>Field</th><th>Value from page</th><th>Where it came from</th>${lead ? '<th>Currently on lead</th>' : ''}</tr></thead><tbody>
        ${keys.map((k) => `<tr>
          <td><input type="checkbox" name="${k}" checked></td>
          <td>${esc(IMPORT_LABELS[k])}</td>
          <td><strong>${esc(k === 'list_price' ? fmtMoney(r.fields[k]) : r.fields[k])}</strong>${k === 'listing_phone' ? `<div class="small">${esc(r.fields.listing_phone_label)}</div>` : ''}</td>
          <td class="src">${esc(r.sources[k])}</td>
          ${lead ? `<td class="small muted">${esc(lead[k] ?? '—')}</td>` : ''}</tr>`).join('')}
        </tbody></table>
        <p class="small muted">${r.isFsbo ? `Listing is marked For Sale By Owner (${esc(r.fsboSource)}), so the phone is labelled “seller direct”.` : 'No FSBO marker found, so any phone is labelled as the listing contact (usually the agent).'}</p>
        <div class="row"><button class="primary">${lead ? 'Apply checked fields to this lead' : 'Create lead with checked fields'}</button></div>
        </form>` : ''}`;

    const apply = out.querySelector('#applyForm');
    if (!apply) return;
    apply.addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const chosen = formData(apply);
      const data = { listing_url: r.url, listing_imported_at: new Date().toISOString().slice(0, 16).replace('T', ' ') };
      for (const k of keys) if (chosen[k]) data[k] = r.fields[k];
      if (chosen.listing_phone) data.listing_phone_label = r.fields.listing_phone_label;
      try {
        if (lead) {
          await api('PUT', `/api/leads/${lead.id}`, data);
          toast('Imported fields saved');
          route();
        } else {
          const src = { zillow: 'Zillow', realtor: 'Realtor.com', redfin: 'Redfin' }[r.site];
          const created = await api('POST', '/api/leads', { ...data, source: src, state: data.state || 'CT' });
          location.hash = `#/lead/${created.id}`;
        }
      } catch (err) { out.insertAdjacentHTML('beforeend', errorBox(err)); }
    });
  });
}

// ---------- lead detail ----------
const TABS = [
  ['details', 'Details'], ['import', 'Listing import'], ['owner', 'Owner lookup'], ['analyzer', 'Analyzer'],
  ['comps', 'Comps'], ['compliance', 'CT compliance'], ['buyers', 'Buyer matches'],
];

async function leadView(id, tab) {
  setNav('leads');
  const lead = await api('GET', `/api/leads/${id}`);
  const curIdx = STATUSES.indexOf(lead.status);
  app.innerHTML = `
    <div class="row"><a href="#/leads">← Leads</a></div>
    <div class="row" style="margin-top:8px">
      <div><h1>${esc(lead.address || '(no address)')}</h1>
        <div class="muted">${esc(addressLine(lead))}${lead.deal_type ? ` · <span class="pill ${isLand(lead) ? 'land' : ''}">${esc(lead.deal_type)}</span>` : ''}</div></div>
      <span class="spacer"></span><button class="danger" id="del">Delete lead</button>
    </div>
    <div class="pipeline">${STATUSES.map((s, i) => {
      const blocked = statusBlockers(lead, s).length > 0;
      return `<button data-status="${esc(s)}" class="${s === lead.status ? 'current' : i < curIdx && s !== 'Dead' && lead.status !== 'Dead' ? 'done' : ''}" title="${blocked ? 'Blocked — click to see why' : ''}">${blocked ? '🔒 ' : ''}${esc(s)}</button>`;
    }).join('')}</div>
    <div id="statusMsg"></div>
    <nav class="tabs">${TABS.map(([k, l]) => `<a href="#/lead/${lead.id}/${k}" class="${k === tab ? 'active' : ''}">${l}</a>`).join('')}</nav>
    <div id="tab"></div>`;

  app.querySelectorAll('[data-status]').forEach((b) => b.addEventListener('click', async () => {
    const msg = app.querySelector('#statusMsg');
    try {
      await api('POST', `/api/leads/${lead.id}/status`, { status: b.dataset.status });
      toast(`Moved to ${b.dataset.status}`);
      route();
    } catch (err) { msg.innerHTML = errorBox(err); }
  }));
  app.querySelector('#del').addEventListener('click', async () => {
    if (!confirm('Delete this lead, its comps and photos? This cannot be undone.')) return;
    await api('DELETE', `/api/leads/${lead.id}`);
    location.hash = '#/leads';
  });

  const el = app.querySelector('#tab');
  const views = { details: tabDetails, import: tabImport, owner: tabOwner, analyzer: tabAnalyzer, comps: tabComps, compliance: tabCompliance, buyers: tabBuyers };
  await (views[tab] || tabDetails)(el, lead);
}

/** Save a section form via PUT and re-render; shows blockers inline on failure. */
function wireSave(form, lead, msgEl, transform = (d) => d) {
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await api('PUT', `/api/leads/${lead.id}`, transform(formData(form)));
      toast('Saved');
      route();
    } catch (err) { msgEl.innerHTML = errorBox(err); }
  });
}

function tabDetails(el, lead) {
  let links = [];
  try { links = JSON.parse(lead.links || '[]'); } catch {}
  el.innerHTML = `
    <form class="panel" id="f">
      <h2>Property & lead</h2>
      ${leadCoreFields(lead)}
      <h3>Deal numbers</h3>
      <div class="grid">
        ${moneyField('offer_amount', 'Offer made to seller ($)', lead.offer_amount)}
        ${moneyField('contract_price', 'Contract price ($)', lead.contract_price)}
        ${moneyField('assignment_price', 'Price to end buyer ($)', lead.assignment_price)}
        ${moneyField('fee_collected', 'Fee collected ($)', lead.fee_collected)}
      </div>
      <h3>Links</h3>
      ${field('links', 'One link per line (listing, Street View, GIS map, photos album…)', links.join('\n'), { type: 'textarea', wide: true })}
      ${links.length ? `<div class="linklist" style="margin-top:8px">${links.map((u) => `<a href="${esc(u)}" target="_blank" rel="noopener noreferrer">${esc(u)}</a>`).join('')}</div>` : ''}
      <div class="row" style="margin-top:12px"><button class="primary">Save</button><span class="small muted">Created ${esc(lead.created_at)} · updated ${esc(lead.updated_at)}</span></div>
      <div id="msg"></div>
    </form>
    <div class="panel">
      <h2>Photos</h2>
      <div class="photos">${lead.photos.map((p) => `<figure><a href="/uploads/${esc(p.filename)}" target="_blank"><img src="/uploads/${esc(p.filename)}" alt=""></a>
        <figcaption><span>${esc((p.original_name || '').slice(0, 18))}</span><a href="#" data-photo="${p.id}">remove</a></figcaption></figure>`).join('') || '<p class="muted">No photos yet.</p>'}</div>
      <p><input type="file" id="photo" accept="image/*" multiple></p>
    </div>
    <div class="panel"><h2>Status history</h2>
      <table>${lead.history.map((h) => `<tr><td class="small muted">${esc(h.at)}</td><td>${h.from_status ? esc(h.from_status) + ' → ' : ''}<strong>${esc(h.to_status)}</strong></td></tr>`).join('')}</table>
    </div>`;
  wireSave(el.querySelector('#f'), lead, el.querySelector('#msg'), (d) => ({
    ...d, links: d.links.split('\n').map((s) => s.trim()).filter(Boolean),
  }));
  el.querySelector('#photo').addEventListener('change', async (e) => {
    for (const file of e.target.files) {
      const data = await new Promise((res, rej) => {
        const r = new FileReader();
        r.onload = () => res(String(r.result).split(',')[1]);
        r.onerror = rej;
        r.readAsDataURL(file);
      });
      try { await api('POST', `/api/leads/${lead.id}/photos`, { name: file.name, data }); }
      catch (err) { alert(err.message); }
    }
    route();
  });
  el.querySelectorAll('[data-photo]').forEach((a) => a.addEventListener('click', async (e) => {
    e.preventDefault();
    if (!confirm('Remove this photo?')) return;
    await api('DELETE', `/api/photos/${a.dataset.photo}`);
    route();
  }));
}

function tabImport(el, lead) {
  el.innerHTML = `
    <div class="panel">
      <h2>Import from a listing URL</h2>
      <p class="muted small">Works with Zillow, Realtor.com and Redfin listing pages. Only that one page is downloaded. If the site blocks the request or the layout has changed, you'll see exactly what failed — nothing is guessed.</p>
      ${importBox(lead)}
    </div>
    <form class="panel" id="f">
      <h2>Listing data on this lead</h2>
      <p class="small muted">${lead.listing_imported_at ? `Last import applied ${esc(lead.listing_imported_at)}.` : 'Nothing imported yet.'} You can also type or correct these by hand.</p>
      <div class="grid">
        ${field('listing_url', 'Listing URL', lead.listing_url, { wide: true })}
        ${moneyField('list_price', 'List price ($)', lead.list_price)}
        ${moneyField('beds', 'Beds', lead.beds)}
        ${moneyField('baths', 'Baths', lead.baths)}
        ${moneyField('sqft', 'Square feet', lead.sqft)}
        ${field('lot_size', 'Lot size (with units)', lead.lot_size)}
        ${field('property_type', 'Property type', lead.property_type)}
        ${field('listing_phone', 'Contact phone', lead.listing_phone)}
        ${field('listing_phone_label', 'Phone is…', lead.listing_phone_label, { options: ['listing contact (usually the agent)', 'seller direct (listing marked FSBO)'] })}
      </div>
      <div class="row" style="margin-top:12px"><button class="primary">Save</button></div>
      <div id="msg"></div>
    </form>
    ${lead.imports.length ? `<div class="panel"><h2>Import log (this lead)</h2><table>
      ${lead.imports.map((i) => { const d = JSON.parse(i.detail || '{}'); return `<tr><td class="small muted">${esc(i.at)}</td><td>${i.ok ? '✅' : '❌'} ${esc(i.site)}</td>
        <td class="small">${(d.failures || []).map(esc).join('<br>') || 'no problems'}</td></tr>`; }).join('')}
    </table><p class="small muted">Full log of every import: <code>data/import.log</code></p></div>` : ''}`;
  wireImport(lead);
  wireSave(el.querySelector('#f'), lead, el.querySelector('#msg'));
}

async function tabOwner(el, lead) {
  const towns = await api('GET', '/api/town-links');
  const town = (lead.city || '').trim();
  const saved = towns.find((t) => t.town === town.toLowerCase());
  const street = lead.address || '';
  const cityState = [town, lead.state || 'CT'].filter(Boolean).join(', ');
  const fullAddr = addressLine(lead);
  const links = [];
  if (street) links.push(['TruePeopleSearch — by address', `https://www.truepeoplesearch.com/resultaddress?streetaddress=${enc(street)}&citystatezip=${enc(cityState)}`]);
  if (lead.owner_name) links.push(['TruePeopleSearch — by owner name', `https://www.truepeoplesearch.com/results?name=${enc(lead.owner_name)}&citystatezip=${enc(cityState)}`]);
  if (fullAddr) links.push(['Google — address in quotes', `https://www.google.com/search?q=${enc(`"${street || fullAddr}"${town ? ' ' + town : ''}`)}`]);
  if (saved) links.push([`${town} assessor (your saved link)`, saved.assessor_url]);
  if (town) links.push([`Find the ${town} assessor online database (Google)`, `https://www.google.com/search?q=${enc(`${town} ${lead.state || 'CT'} assessor online database property card`)}`]);
  if (town) links.push([`Find ${town} town clerk land records (Google)`, `https://www.google.com/search?q=${enc(`${town} ${lead.state || 'CT'} town clerk land records search`)}`]);
  if (lead.assessor_url) links.push(['Property card (saved on this lead)', lead.assessor_url]);

  el.innerHTML = `
    <div class="panel">
      <h2>Free lookup links</h2>
      <p class="muted small">These open in your browser — the app itself does not contact these sites. Look the owner up, then paste what you find below.
      In Connecticut, property records are kept by each <em>town</em> (there's no county assessor), and many towns use the Vision Government Solutions online database.</p>
      ${links.length ? `<div class="linklist">${links.map(([l, u]) => `<a href="${esc(u)}" target="_blank" rel="noopener noreferrer">↗ ${esc(l)}</a>`).join('')}</div>`
        : '<p class="muted">Add a street address and town on the Details tab to get lookup links.</p>'}
      ${town ? `<form id="townForm" class="row" style="margin-top:12px">
        <input name="assessor_url" type="url" style="flex:1;min-width:260px" placeholder="Paste the ${esc(town)} assessor search page URL to reuse for every ${esc(town)} lead" value="${esc(saved?.assessor_url)}">
        <button>Save town link</button></form>` : ''}
    </div>
    <form class="panel" id="f">
      <h2>Owner contact (what you found)</h2>
      <div class="grid">
        ${field('owner_name', 'Owner name', lead.owner_name)}
        ${field('owner_phone', 'Owner phone(s)', lead.owner_phone)}
        ${field('owner_email', 'Owner email', lead.owner_email)}
        ${field('assessor_url', 'Property card / assessor URL for this parcel', lead.assessor_url)}
        ${field('owner_contact_source', 'Where did this number/email come from? (e.g. TruePeopleSearch 10/12, tax bill mailing address)', lead.owner_contact_source, { type: 'textarea', wide: true })}
      </div>
      ${lead.listing_phone ? `<p class="small muted">Listing phone on file: ${esc(lead.listing_phone)} — ${esc(lead.listing_phone_label || 'listing contact')}</p>` : ''}
      <div class="row" style="margin-top:12px"><button class="primary">Save</button></div>
      <div id="msg"></div>
    </form>`;
  wireSave(el.querySelector('#f'), lead, el.querySelector('#msg'));
  el.querySelector('#townForm')?.addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
      await api('PUT', '/api/town-links', { town, assessor_url: e.target.assessor_url.value });
      toast('Town link saved'); route();
    } catch (err) { alert(err.message); }
  });
}

function mathTable(result) {
  if (result.mao === null) return `<div class="alert info">Enter ${result.missing.join(', ')} to calculate. Blank fields are never treated as $0.</div>`;
  return `<table class="math">${result.steps.map(([l, expr, v]) => `<tr><td>${esc(l)}</td><td class="muted">${esc(expr)}</td><td>${fmtMoney(v)}</td></tr>`).join('')}</table>
    <p>Maximum allowable offer: <span class="mao">${fmtMoney(result.mao)}</span></p>
    ${result.mao < 0 ? '<div class="alert bad">MAO is negative — these numbers do not support a deal.</div>' : ''}
    ${result.vsAsking ? `<div class="alert ${result.vsAsking.gap >= 0 ? 'ok' : 'warn'}">Seller's price ${fmtMoney(result.vsAsking.asking)} is
      ${result.vsAsking.gap >= 0 ? `${fmtMoney(result.vsAsking.gap)} <strong style="display:inline">under</strong> your MAO — room to make the deal.` : `${fmtMoney(-result.vsAsking.gap)} <strong style="display:inline">over</strong> your MAO — you'd need to negotiate down.`}</div>` : ''}`;
}

async function tabAnalyzer(el, lead) {
  const comps = await api('GET', `/api/leads/${lead.id}/comps`);
  const arvS = arvFromComps(comps);
  const land = isLand(lead);
  el.innerHTML = `
    ${!lead.deal_type ? '<div class="alert info">Set the deal type on the Details tab. “Vacant land” switches this tab to land mode.</div>' : ''}
    <form class="panel" id="f">
      ${land ? `
        <h2>Vacant land analyzer</h2>
        <div class="grid">
          ${moneyField('land_lot_price', "Lot price (seller's asking) ($)", lead.land_lot_price ?? lead.asking_price ?? lead.list_price ?? '')}
          ${moneyField('land_builder_value', 'Builder resale value — what a builder will pay ($)', lead.land_builder_value)}
          ${moneyField('target_fee', 'Your target fee ($)', lead.target_fee)}
        </div>
        <div id="calc" style="margin-top:12px"></div>
        <h3>Buildability checklist</h3>
        <p class="small muted">All five must be ticked before this lead can move to Offer Made.</p>
        ${LAND_CHECKLIST.map(([k, l]) => check(k, l, lead[k])).join('')}
      ` : `
        <h2>House analyzer</h2>
        <div class="grid">
          ${moneyField('arv', 'ARV — after-repair value ($)', lead.arv)}
          ${moneyField('repairs', 'Repair estimate ($)', lead.repairs)}
          ${moneyField('asking_price', "Seller's asking price ($)", lead.asking_price)}
          ${moneyField('target_fee', 'Your target fee ($)', lead.target_fee)}
        </div>
        ${arvS ? `<p class="small">Your comps (${arvS.count}) suggest ARV ${fmtMoney(arvS.low)}–${fmtMoney(arvS.high)}, median ${fmtMoney(arvS.median)}.
          <a href="#" id="useMedian">Use median</a> · <a href="#" id="useAvg">Use average</a> <span class="muted">(based only on comps you entered)</span></p>`
          : `<p class="small muted">No comps entered yet — add some on the Comps tab for an ARV range.</p>`}
        <div id="calc" style="margin-top:12px"></div>
        <p class="small muted">Formula: MAO = (ARV × 0.70) − repairs − your fee.</p>
      `}
      <div class="row" style="margin-top:12px"><button class="primary">Save</button></div>
      <div id="msg"></div>
    </form>`;
  const form = el.querySelector('#f');
  const calc = () => {
    const d = formData(form);
    el.querySelector('#calc').innerHTML = land
      ? mathTable(landMao({ lotPrice: d.land_lot_price, builderValue: d.land_builder_value, fee: d.target_fee }))
      : mathTable(houseMao({ arv: d.arv, repairs: d.repairs, fee: d.target_fee, asking: d.asking_price }));
  };
  form.addEventListener('input', calc);
  calc();
  const setArv = (v) => (e) => { e.preventDefault(); form.arv.value = Math.round(v); calc(); };
  el.querySelector('#useMedian')?.addEventListener('click', setArv(arvS?.median));
  el.querySelector('#useAvg')?.addEventListener('click', setArv(arvS?.average));
  wireSave(form, lead, el.querySelector('#msg'));
}

async function tabComps(el, lead) {
  const comps = await api('GET', `/api/leads/${lead.id}/comps`);
  const s = arvFromComps(comps);
  el.innerHTML = `
    <div class="panel">
      <h2>Comparable sales</h2>
      <p class="small muted">Enter sold comps you found yourself (town records, Zillow/Redfin "recently sold", an agent). Nothing here is pulled from the MLS or estimated.</p>
      ${comps.length ? `<table><thead><tr><th>Address</th><th class="num">Sold price</th><th>Sold date</th><th class="num">Bd/Ba</th><th class="num">Sqft</th><th class="num">$/sqft</th><th class="num">Distance</th><th>Notes</th><th></th></tr></thead><tbody>
        ${comps.map((c) => `<tr><td>${esc(c.address)}</td><td class="num">${money(c.sold_price)}</td><td>${esc(c.sold_date)}</td>
          <td class="num">${c.beds ?? '—'}/${c.baths ?? '—'}</td><td class="num">${n0(c.sqft)}</td>
          <td class="num">${c.sold_price && c.sqft ? fmtMoney(c.sold_price / c.sqft) : '—'}</td>
          <td class="num">${c.distance_mi !== null ? c.distance_mi + ' mi' : '—'}</td><td class="small">${esc(c.notes)}</td>
          <td><button class="danger" data-del="${c.id}">✕</button></td></tr>`).join('')}</tbody></table>` : '<p class="muted">No comps yet.</p>'}
      ${s ? `<div class="alert info"><strong>ARV range based only on the ${s.count} comp(s) you entered</strong>
        Low ${fmtMoney(s.low)} · Median ${fmtMoney(s.median)} · Average ${fmtMoney(s.average)} · High ${fmtMoney(s.high)}
        ${s.medianPpsf ? `<br>Median $/sqft ${fmtMoney(s.medianPpsf)} (${s.ppsfCount} comps with sqft)${num(lead.sqft) ? ` × subject ${n0(lead.sqft)} sqft = ${fmtMoney(s.medianPpsf * num(lead.sqft))}` : ''}` : ''}
        <br><span class="small">This is arithmetic on your inputs, not an appraisal. ${s.count < 3 ? 'Fewer than 3 comps — treat with caution.' : ''}</span></div>` : ''}
    </div>
    <form class="panel" id="f">
      <h2>Add comp</h2>
      <div class="grid">
        ${field('address', 'Address', '')}
        ${moneyField('sold_price', 'Sold price ($) *', '')}
        ${field('sold_date', 'Sold date', '', { type: 'date' })}
        ${moneyField('beds', 'Beds', '')}
        ${moneyField('baths', 'Baths', '')}
        ${moneyField('sqft', 'Sqft', '')}
        ${moneyField('distance_mi', 'Distance from subject (miles)', '')}
        ${field('notes', 'Notes (condition, source)', '')}
      </div>
      <div class="row" style="margin-top:12px"><button class="primary">Add comp</button></div>
      <div id="msg"></div>
    </form>`;
  el.querySelector('#f').addEventListener('submit', async (e) => {
    e.preventDefault();
    try { await api('POST', `/api/leads/${lead.id}/comps`, formData(e.target)); toast('Comp added'); route(); }
    catch (err) { el.querySelector('#msg').innerHTML = errorBox(err); }
  });
  el.querySelectorAll('[data-del]').forEach((b) => b.addEventListener('click', async () => {
    await api('DELETE', `/api/comps/${b.dataset.del}`); route();
  }));
}

function tabCompliance(el, lead) {
  const warnings = complianceWarnings(lead);
  const days = daysBetween(lead.contract_date, lead.closing_date);
  const done = CT_CHECKLIST.filter(([k]) => lead[k]).length;
  el.innerHTML = `
    <form class="panel" id="f">
      <h2>Connecticut wholesaling checklist <span class="pill">${done}/${CT_CHECKLIST.length}</span></h2>
      <div class="alert warn"><strong>Why this matters</strong>
        Connecticut regulates real estate wholesaling. The seller must get a written disclosure that you are a wholesaler
        <em>before</em> signing your purchase contract, so this lead can't move to <strong style="display:inline">Under Contract</strong> until the disclosure box is ticked.
        This checklist is a reminder, not legal advice — confirm current rules with the CT Department of Consumer Protection (DCP) or a CT real estate attorney.</div>
      ${CT_CHECKLIST.map(([k, l]) => check(k, l, lead[k])).join('')}
      <div class="grid" style="margin-top:10px">
        ${field('ct_disclosure_date', 'Disclosure signed on', lead.ct_disclosure_date, { type: 'date' })}
        ${field('contract_date', 'Contract signed on', lead.contract_date, { type: 'date' })}
        ${field('closing_date', 'Scheduled closing date', lead.closing_date, { type: 'date' })}
      </div>
      ${days !== null ? `<p class="small">Contract → closing: <strong style="display:inline">${days} days</strong>${days <= 90 && days >= 0 ? ' (within 90)' : ''}</p>` : ''}
      ${warnings.length ? `<div class="alert bad"><ul>${warnings.map((w) => `<li>${esc(w)}</li>`).join('')}</ul></div>` : ''}
      <div class="row" style="margin-top:12px"><button class="primary">Save</button></div>
      <div id="msg"></div>
    </form>`;
  wireSave(el.querySelector('#f'), lead, el.querySelector('#msg'));
}

async function tabBuyers(el, lead) {
  const m = await api('GET', `/api/leads/${lead.id}/matches`);
  const matches = m.buyers.filter((b) => b.match);
  const others = m.buyers.filter((b) => !b.match);
  const row = (b) => `<tr><td><a href="#/buyers/${b.id}">${esc(b.name)}</a><div class="small muted">${esc([b.phone, b.email].filter(Boolean).join(' · '))}</div></td>
    <td class="small">${b.reasons.map(esc).join('<br>')}</td><td class="small" style="color:var(--bad)">${b.misses.map(esc).join('<br>')}</td>
    <td class="small">${esc(b.pof_notes)}</td></tr>`;
  el.innerHTML = `
    <div class="panel">
      <h2>Buyers whose buy box fits (${matches.length})</h2>
      <p class="small muted">Deal price used: ${m.dealPrice.price !== null ? `${fmtMoney(m.dealPrice.price)} (${esc(m.dealPrice.from)})` : 'none entered — set “Price to end buyer” on Details for price matching'}.
        Matched on town/ZIP, deal type and price range. Empty buy-box fields count as “any”.</p>
      ${m.buyers.length ? '' : '<p class="muted">No buyers yet. <a href="#/buyers">Add buyers</a>.</p>'}
      ${matches.length ? `<table><thead><tr><th>Buyer</th><th>Fits because</th><th></th><th>Proof of funds</th></tr></thead><tbody>${matches.map(row).join('')}</tbody></table>` : m.buyers.length ? '<p>No buyer fits this deal.</p>' : ''}
    </div>
    ${others.length ? `<details class="panel"><summary>Not a match (${others.length})</summary>
      <table><thead><tr><th>Buyer</th><th>Fits</th><th>Doesn't fit</th><th>Proof of funds</th></tr></thead><tbody>${others.map(row).join('')}</tbody></table></details>` : ''}`;
}

// ---------- buyers ----------
async function buyersView(editId) {
  setNav('buyers');
  const buyers = await api('GET', '/api/buyers');
  const b = editId ? buyers.find((x) => String(x.id) === editId) || {} : {};
  const types = String(b.property_types || '').split(',').map((s) => s.trim().toLowerCase());
  app.innerHTML = `
    <h1>Cash buyers</h1>
    <div class="panel">
      ${buyers.length ? `<table><thead><tr><th>Name</th><th>Contact</th><th>Areas</th><th>Price range</th><th>Types</th><th>Proof of funds</th></tr></thead><tbody>
        ${buyers.map((x) => `<tr class="click" data-id="${x.id}"><td><strong>${esc(x.name)}</strong></td><td class="small">${esc([x.phone, x.email].filter(Boolean).join(' · '))}</td>
          <td class="small">${esc(x.areas || 'any')}</td><td class="small">${money(x.min_price)} – ${money(x.max_price)}</td>
          <td class="small">${esc(x.property_types || 'any')}</td><td class="small">${esc(x.pof_notes)}</td></tr>`).join('')}
      </tbody></table>` : '<p class="muted">No buyers yet.</p>'}
    </div>
    <form class="panel" id="f">
      <h2>${b.id ? `Edit ${esc(b.name)}` : 'Add buyer'}</h2>
      <div class="grid">
        ${field('name', 'Name / company *', b.name)}
        ${field('phone', 'Phone', b.phone)}
        ${field('email', 'Email', b.email)}
        ${field('areas', 'Areas — towns or ZIPs, comma separated (blank = any)', b.areas, { wide: true, placeholder: 'Hartford, New Britain, 06106' })}
        ${moneyField('min_price', 'Min price ($)', b.min_price)}
        ${moneyField('max_price', 'Max price ($)', b.max_price)}
      </div>
      <h3>Property types (none ticked = any)</h3>
      <div class="row">${DEAL_TYPES.map((t) => `<label class="check"><input type="checkbox" data-type="${esc(t)}" ${types.includes(t.toLowerCase()) ? 'checked' : ''}> ${esc(t)}</label>`).join('')}</div>
      <div class="grid">
        ${field('pof_notes', 'Proof of funds notes', b.pof_notes, { type: 'textarea' })}
        ${field('notes', 'Notes', b.notes, { type: 'textarea' })}
      </div>
      <div class="row" style="margin-top:12px"><button class="primary">${b.id ? 'Save buyer' : 'Add buyer'}</button>
        ${b.id ? '<a class="btn" href="#/buyers">Cancel</a><span class="spacer"></span><button type="button" class="danger" id="del">Delete buyer</button>' : ''}</div>
      <div id="msg"></div>
    </form>`;
  app.querySelectorAll('tr.click').forEach((tr) => tr.addEventListener('click', () => (location.hash = `#/buyers/${tr.dataset.id}`)));
  const form = app.querySelector('#f');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const d = formData(form);
    for (const k of Object.keys(d)) if (!['name', 'phone', 'email', 'areas', 'min_price', 'max_price', 'pof_notes', 'notes'].includes(k)) delete d[k];
    d.property_types = [...form.querySelectorAll('[data-type]')].filter((c) => c.checked).map((c) => c.dataset.type).join(', ');
    try {
      if (b.id) await api('PUT', `/api/buyers/${b.id}`, d);
      else await api('POST', '/api/buyers', d);
      toast('Buyer saved');
      if (b.id) location.hash = '#/buyers'; else route();
    } catch (err) { app.querySelector('#msg').innerHTML = errorBox(err); }
  });
  app.querySelector('#del')?.addEventListener('click', async () => {
    if (!confirm(`Delete ${b.name}?`)) return;
    await api('DELETE', `/api/buyers/${b.id}`);
    location.hash = '#/buyers';
  });
}

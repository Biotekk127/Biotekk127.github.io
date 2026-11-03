// Deploy a static directory to Vercel as a preview via the REST API.
// Usage (from a site folder, after `npm run build`):
//   NODE_USE_ENV_PROXY=1 NODE_EXTRA_CA_CERTS=/root/.ccr/ca-bundle.crt node ../_tools/vercel-deploy.js out cyberedge-<slug>
// Auth comes from the VERCEL_TOKEN network secret the environment adds to api.vercel.com requests.
const fs = require('fs'), path = require('path'), crypto = require('crypto');
const [dir, name] = process.argv.slice(2);
const API = 'https://api.vercel.com';
const walk = d => fs.readdirSync(d, { withFileTypes: true }).flatMap(e => e.isDirectory() ? walk(path.join(d, e.name)) : [path.join(d, e.name)]);
(async () => {
  const files = [];
  for (const f of walk(dir)) {
    const buf = fs.readFileSync(f), sha = crypto.createHash('sha1').update(buf).digest('hex');
    const r = await fetch(`${API}/v2/files`, { method: 'POST', headers: { 'Content-Type': 'application/octet-stream', 'x-vercel-digest': sha, 'Content-Length': buf.length }, body: buf });
    if (!r.ok) throw new Error(`upload ${f}: ${r.status} ${await r.text()}`);
    files.push({ file: path.relative(dir, f).split(path.sep).join('/'), sha, size: buf.length });
  }
  const r = await fetch(`${API}/v13/deployments?skipAutoDetectionConfirmation=1`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name, files, projectSettings: { framework: null, buildCommand: '', outputDirectory: '.', installCommand: '' } }),
  });
  const j = await r.json(); if (!r.ok) throw new Error(JSON.stringify(j));
  console.log('id', j.id, 'url https://' + j.url);
  for (let i = 0; i < 60; i++) {
    const s = await (await fetch(`${API}/v13/deployments/${j.id}`)).json();
    if (['READY', 'ERROR', 'CANCELED'].includes(s.readyState)) { console.log('state', s.readyState, 'alias', (s.alias || []).join(' ')); break; }
    await new Promise(r => setTimeout(r, 3000));
  }
})().catch(e => { console.error(e.message); process.exit(1); });

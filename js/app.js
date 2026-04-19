// ─── State ────────────────────────────────────────────────────────────────────
let config = null;
let currentPage = 'loader';

// ─── Theme ────────────────────────────────────────────────────────────────────
function setTheme(t) {
  document.documentElement.setAttribute('data-theme', t === 'light' ? 'light' : '');
  document.getElementById('btnDark').classList.toggle('active', t === 'dark');
  document.getElementById('btnLight').classList.toggle('active', t === 'light');
}

// ─── Page routing ─────────────────────────────────────────────────────────────
function showPage(id, extra) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.sb-link').forEach(l => l.classList.remove('active'));
  const page = document.getElementById('page-' + id);
  if (page) page.classList.add('active');
  const link = document.querySelector(`.sb-link[onclick*="'${id}'"]`);
  if (link) link.classList.add('active');
  currentPage = id;

  const titles = { loader:'HumbleStudio', tokens:'Tokens', typography:'Typography', spacing:'Spacing & Radius', components:'Components', views:'Views', navmap:'Navigation Map', viewdetail: extra || 'View' };
  document.getElementById('topTitle').textContent = titles[id] || id;
  document.getElementById('topBreadcrumb').textContent = config ? (config.meta?.name || '') : '';

  if (id === 'viewdetail' && extra) renderViewDetail(extra);
  if (id === 'navmap') renderNavMap();
}

// ─── Config loaders ───────────────────────────────────────────────────────────
async function loadFromUrl() {
  const url = document.getElementById('urlInput').value.trim();
  if (!url) return;
  setStatus('loading', 'Loading...');
  try {
    const r = await fetch(url);
    if (!r.ok) throw new Error('HTTP ' + r.status);
    applyConfig(await r.json());
  } catch (e) {
    setStatus('err', 'Load failed: ' + e.message);
  }
}

function loadFromFile(e) {
  const file = e.target.files[0];
  if (!file) return;
  setStatus('loading', 'Reading file...');
  const reader = new FileReader();
  reader.onload = ev => {
    try { applyConfig(JSON.parse(ev.target.result)); }
    catch (err) { setStatus('err', 'Invalid JSON: ' + err.message); }
  };
  reader.readAsText(file);
}

function loadDemo() { applyConfig(DEMO_CONFIG); }

function applyConfig(data) {
  config = data;
  buildSidebar();
  renderTokens();
  renderTypography();
  renderSpacing();
  renderComponents();
  renderViews();
  setStatus('ok', data.meta?.name || 'Loaded');
  document.getElementById('sbAppName').textContent = (data.meta?.name || 'App') + ' v' + (data.meta?.version || '?');
  document.getElementById('btnExport').style.display = '';
  showPage('tokens');
}

function setStatus(type, msg) {
  const dot = document.getElementById('statusDot');
  dot.className = 'status-dot';
  if (type === 'loading') dot.classList.add('loading');
  if (type === 'err')     dot.classList.add('err');
  document.getElementById('statusText').textContent = msg;
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
function buildSidebar() {
  if (!config) return;
  document.getElementById('sbDesignSections').style.display    = '';
  document.getElementById('sbComponentSections').style.display = '';
  document.getElementById('sbViewSections').style.display      = '';
  document.getElementById('cntTokens').textContent = Object.keys(config.tokens?.colors || {}).length;

  const compLinks = document.getElementById('sbComponentLinks');
  compLinks.innerHTML = '';
  const groups = {};
  (config.components || []).forEach(c => { const g = c.group || 'General'; if (!groups[g]) groups[g] = []; groups[g].push(c); });
  Object.entries(groups).forEach(([grp, comps]) => {
    if (Object.keys(groups).length > 1) {
      const lbl = document.createElement('div');
      lbl.style.cssText = 'font-size:9px;color:var(--t3);padding:8px 10px 2px;font-weight:600;text-transform:uppercase;letter-spacing:.5px';
      lbl.textContent = grp;
      compLinks.appendChild(lbl);
    }
    comps.forEach(c => {
      const el = document.createElement('div');
      el.className = 'sb-link';
      el.innerHTML = `<span class="sb-link-icon">⬡</span>${c.name}<span class="sb-count">${(c.mocks || []).length}</span>`;
      el.onclick = () => showComponentPage(c.id);
      compLinks.appendChild(el);
    });
  });

  const viewLinks = document.getElementById('sbViewLinks');
  viewLinks.innerHTML = '';
  (config.views || []).forEach(v => {
    const el = document.createElement('div');
    el.className = 'sb-link';
    el.innerHTML = `<span class="sb-link-icon">▭</span>${v.name}`;
    el.onclick = () => showPage('viewdetail', v.id);
    viewLinks.appendChild(el);
  });
}

function showComponentPage(compId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  if (!comp) return;
  document.getElementById('compPageTitle').textContent = comp.name;
  document.getElementById('compPageDesc').textContent  = comp.description || '';
  document.getElementById('componentsContent').innerHTML = `<div class="component-grid">${buildComponentCard(comp)}</div>`;
  const sel = document.getElementById('mock-sel-' + comp.id);
  if (sel) sel.onchange = () => updateMockPreview(comp.id, sel.value);
  showPage('components');
  document.querySelectorAll('.sb-link').forEach(l => l.classList.remove('active'));
}

// ─── Export ───────────────────────────────────────────────────────────────────
function exportConfig() {
  if (!config) return;
  const blob = new Blob([JSON.stringify(config, null, 2)], { type:'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'design.json';
  a.click();
}

// ─── State ────────────────────────────────────────────────────────────────────
let config = null;
let currentPage = 'loader';
let validationReport = { errors: [], warnings: [] };
let componentEditorState = {};
let currentFoundationDetail = null;
let navMapZoom = 1;

const NAVIGATION_TYPES = new Set(['push', 'sheet', 'replace', 'pop']);

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

// ─── Theme ────────────────────────────────────────────────────────────────────
function setTheme(t) {
  document.documentElement.setAttribute('data-theme', t === 'light' ? 'light' : '');
  document.getElementById('btnDark').classList.toggle('active', t === 'dark');
  document.getElementById('btnLight').classList.toggle('active', t === 'light');
  syncNavMapZoomLabel();
}

// ─── Page routing ─────────────────────────────────────────────────────────────
function showPage(id, extra) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const page = document.getElementById('page-' + id);
  if (page) page.classList.add('active');
  currentPage = id;
  syncSidebarActive(id, extra);

  const titles = { loader:'HumbleStudio', tokens:'Tokens', icons:'Icons', foundationdetail: 'Foundation Detail', typography:'Typography', spacing:'Spacing & Radius', components:'Components', views:'Views', navmap:'Navigation Map', viewdetail: extra || 'View' };
  document.getElementById('topTitle').textContent = titles[id] || id;
  document.getElementById('topBreadcrumb').textContent = config ? (config.meta?.name || '') : '';

  if (id === 'viewdetail' && extra) renderViewDetail(extra);
  if (id === 'foundationdetail' && extra) renderFoundationDetail(extra.kind, extra.id);
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
  const label = document.getElementById('fileInputLabel');
  if (label) label.textContent = file.name;
  setStatus('loading', 'Reading file...');
  const reader = new FileReader();
  reader.onload = ev => {
    try { applyConfig(JSON.parse(ev.target.result)); }
    catch (err) { setStatus('err', 'Invalid JSON: ' + err.message); }
  };
  reader.readAsText(file);
}

function loadDemo() { applyConfig(DEMO_CONFIG); }

function getComponentStates(component) {
  return component?.states || component?.mocks || [];
}

function getDefaultMock(component) {
  return getComponentStates(component)[0] || { id: 'default', label: 'Default', props: {} };
}

function isCatalogOnlyComponent(component) {
  return component?.interactionMode === 'catalog';
}

function getComponentEditorState(component) {
  if (!component) return null;
  if (!componentEditorState[component.id]) {
    const mock = getDefaultMock(component);
    componentEditorState[component.id] = {
      mode: component.snapshot ? 'snapshot' : 'mock',
      selectedMockId: mock.id,
      draft: JSON.stringify(mock.props || {}, null, 2),
      error: '',
    };
  }
  return componentEditorState[component.id];
}

function validateConfig(data) {
  const errors = [];
  const warnings = [];
  const normalized = isPlainObject(data) ? { ...data } : {};

  normalized.meta = isPlainObject(data?.meta) ? data.meta : {};
  normalized.tokens = isPlainObject(data?.tokens) ? data.tokens : {};
  normalized.tokens.colors = isPlainObject(normalized.tokens.colors) ? normalized.tokens.colors : {};
  normalized.tokens.gradients = isPlainObject(normalized.tokens.gradients) ? normalized.tokens.gradients : {};
  normalized.tokens.icons = Array.isArray(normalized.tokens.icons) ? normalized.tokens.icons : [];
  normalized.tokens.spacing = isPlainObject(normalized.tokens.spacing) ? normalized.tokens.spacing : {};
  normalized.tokens.radius = isPlainObject(normalized.tokens.radius) ? normalized.tokens.radius : {};
  normalized.tokens.typography = Array.isArray(normalized.tokens.typography) ? normalized.tokens.typography : [];
  normalized.components = Array.isArray(data?.components) ? data.components : [];
  normalized.views = Array.isArray(data?.views) ? data.views : [];
  normalized.navigation = isPlainObject(data?.navigation) ? data.navigation : {};

  if (!isPlainObject(data)) {
    errors.push({ path: 'root', message: 'Config must be a JSON object.' });
  }
  if (!isPlainObject(data?.meta)) {
    warnings.push({ path: 'meta', message: 'Missing or invalid `meta`; app info will fall back to defaults.' });
  }
  if (!isPlainObject(data?.tokens)) {
    warnings.push({ path: 'tokens', message: 'Missing or invalid `tokens`; foundation pages will be mostly empty.' });
  }
  if (!Array.isArray(data?.components)) {
    warnings.push({ path: 'components', message: 'Missing or invalid `components`; component previews cannot be rendered.' });
  }
  if (!Array.isArray(data?.views)) {
    warnings.push({ path: 'views', message: 'Missing or invalid `views`; screen previews and navigation map cannot be rendered.' });
  }

  const componentIds = new Set();
  normalized.components.forEach((component, index) => {
    if (!isPlainObject(component)) {
      errors.push({ path: `components[${index}]`, message: 'Each component must be an object.' });
      return;
    }
    if (!component.id) {
      errors.push({ path: `components[${index}].id`, message: 'Component is missing `id`.' });
      return;
    }
    if (componentIds.has(component.id)) {
      errors.push({ path: `components[${index}].id`, message: `Duplicate component id "${component.id}".` });
    }
    componentIds.add(component.id);
    if (component.mocks && !Array.isArray(component.mocks)) {
      warnings.push({ path: `components[${index}].mocks`, message: '`mocks` should be an array.' });
    }
  });

  const viewIds = new Set();
  normalized.views.forEach((view, index) => {
    if (!isPlainObject(view)) {
      errors.push({ path: `views[${index}]`, message: 'Each view must be an object.' });
      return;
    }
    if (!view.id) {
      errors.push({ path: `views[${index}].id`, message: 'View is missing `id`.' });
      return;
    }
    if (viewIds.has(view.id)) {
      errors.push({ path: `views[${index}].id`, message: `Duplicate view id "${view.id}".` });
    }
    viewIds.add(view.id);
  });

  normalized.views.forEach((view, index) => {
    (view.components || []).forEach((componentId, componentIndex) => {
      if (!componentIds.has(componentId)) {
        warnings.push({
          path: `views[${index}].components[${componentIndex}]`,
          message: `Unknown component reference "${componentId}".`,
        });
      }
    });
    (view.navigatesTo || []).forEach((transition, transitionIndex) => {
      if (!isPlainObject(transition)) {
        errors.push({
          path: `views[${index}].navigatesTo[${transitionIndex}]`,
          message: 'Navigation entries must be objects.',
        });
        return;
      }
      if (!viewIds.has(transition.viewId)) {
        warnings.push({
          path: `views[${index}].navigatesTo[${transitionIndex}].viewId`,
          message: `Unknown target view "${transition.viewId}".`,
        });
      }
      if (transition.type && !NAVIGATION_TYPES.has(transition.type)) {
        warnings.push({
          path: `views[${index}].navigatesTo[${transitionIndex}].type`,
          message: `Unsupported navigation type "${transition.type}".`,
        });
      }
    });
  });

  if (normalized.navigation.root && !viewIds.has(normalized.navigation.root)) {
    warnings.push({
      path: 'navigation.root',
      message: `Root view "${normalized.navigation.root}" was not found in \`views\`.`,
    });
  }

  return { normalized, errors, warnings };
}

function applyConfig(data) {
  const report = validateConfig(data);
  config = report.normalized;
  validationReport = { errors: report.errors, warnings: report.warnings };
  componentEditorState = {};
  buildSidebar();
  renderTokens();
  renderIcons();
  renderTypography();
  renderSpacing();
  renderComponents();
  renderViews();
  renderValidationBanner();
  if (report.errors.length) {
    setStatus('err', `Loaded with ${report.errors.length} error${report.errors.length === 1 ? '' : 's'}`);
  } else if (report.warnings.length) {
    setStatus('warn', `Loaded with ${report.warnings.length} warning${report.warnings.length === 1 ? '' : 's'}`);
  } else {
    setStatus('ok', config.meta?.name || 'Loaded');
  }
  document.getElementById('sbAppName').textContent = (config.meta?.name || 'App') + ' v' + (config.meta?.version || '?');
  document.getElementById('btnExport').style.display = '';
  showPage('tokens');
}

function setStatus(type, msg) {
  const dot = document.getElementById('statusDot');
  dot.className = 'status-dot';
  if (type === 'loading') dot.classList.add('loading');
  if (type === 'err')     dot.classList.add('err');
  if (type === 'warn')    dot.classList.add('warn');
  document.getElementById('statusText').textContent = msg;
}

function renderValidationBanner() {
  const banner = document.getElementById('validationBanner');
  const issues = [...validationReport.errors, ...validationReport.warnings].slice(0, 6);
  if (!issues.length) {
    banner.style.display = 'none';
    banner.innerHTML = '';
    banner.className = 'validation-banner';
    return;
  }

  const level = validationReport.errors.length ? 'err' : 'warn';
  const summary = `${validationReport.errors.length} error${validationReport.errors.length === 1 ? '' : 's'}, ${validationReport.warnings.length} warning${validationReport.warnings.length === 1 ? '' : 's'}`;
  banner.className = `validation-banner ${level}`;
  banner.style.display = '';
  banner.innerHTML = `
    <div class="validation-title">Config validation report</div>
    <div class="validation-copy">${summary}. Rendering continues with safe fallbacks where possible.</div>
    <div class="validation-list">
      ${issues.map(issue => `<div class="validation-item"><span>${escapeHtml(issue.path)}</span>${escapeHtml(issue.message)}</div>`).join('')}
    </div>
  `;
}

function syncSidebarActive(id, extra) {
  let navKey = `page:${id}`;
  if (id === 'components' && extra) navKey = `component:${extra}`;
  if (id === 'viewdetail' && extra) navKey = `view:${extra}`;
  if (id === 'foundationdetail') {
    navKey = extra?.kind === 'icon' ? 'page:icons' : 'page:tokens';
  }

  document.querySelectorAll('.sb-link').forEach(link => {
    link.classList.toggle('active', link.dataset.navKey === navKey);
  });
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────
function buildSidebar() {
  if (!config) return;
  document.getElementById('sbDesignSections').style.display    = '';
  document.getElementById('sbComponentSections').style.display = '';
  document.getElementById('sbViewSections').style.display      = '';
  document.getElementById('cntTokens').textContent = Object.keys(config.tokens?.colors || {}).length + Object.keys(config.tokens?.gradients || {}).length;
  document.getElementById('cntIcons').textContent = (config.tokens?.icons || []).length;

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
      el.dataset.navKey = `component:${c.id}`;
      el.innerHTML = `<span class="sb-link-icon">⬡</span>${escapeHtml(c.name)}<span class="sb-count">${getComponentStates(c).length}</span>`;
      el.onclick = () => showComponentPage(c.id);
      compLinks.appendChild(el);
    });
  });

  const viewLinks = document.getElementById('sbViewLinks');
  viewLinks.innerHTML = '';
  (config.views || []).forEach(v => {
    const el = document.createElement('div');
    el.className = 'sb-link';
    el.dataset.navKey = `view:${v.id}`;
    el.innerHTML = `<span class="sb-link-icon">▭</span>${escapeHtml(v.name)}`;
    el.onclick = () => showPage('viewdetail', v.id);
    viewLinks.appendChild(el);
  });
}

function showComponentPage(compId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  if (!comp) return;
  getComponentEditorState(comp);
  document.getElementById('compPageTitle').textContent = comp.name;
  document.getElementById('compPageDesc').textContent  = comp.description || '';
  document.getElementById('componentsContent').innerHTML = `<div class="component-grid component-grid-detail">${buildComponentCard(comp, { detailed: true })}</div>`;
  showPage('components', comp.id);
}

function showFoundationDetail(kind, id) {
  currentFoundationDetail = { kind, id };
  showPage('foundationdetail', currentFoundationDetail);
}

function setComponentPreviewMode(compId, mode) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!state) return;
  state.mode = mode === 'mock' ? 'mock' : 'snapshot';
  rerenderComponentCard(compId);
}

function handleMockSelection(compId, mockId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state) return;
  const mock = getComponentStates(comp).find(entry => entry.id === mockId) || getDefaultMock(comp);
  state.selectedMockId = mock.id;
  state.draft = JSON.stringify(mock.props || {}, null, 2);
  state.error = '';
  rerenderComponentCard(compId);
}

function handleMockDraftChange(compId, value) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state || isCatalogOnlyComponent(comp)) return;
  state.draft = value;
}

function applyMockDraft(compId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state || isCatalogOnlyComponent(comp)) return;
  try {
    JSON.parse(state.draft || '{}');
    state.error = '';
    state.mode = 'mock';
  } catch (error) {
    state.error = error.message;
  }
  rerenderComponentCard(compId);
}

function resetMockDraft(compId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state) return;
  const mock = getComponentStates(comp).find(entry => entry.id === state.selectedMockId) || getDefaultMock(comp);
  state.draft = JSON.stringify(mock.props || {}, null, 2);
  state.error = '';
  rerenderComponentCard(compId);
}

function rerenderComponentCard(compId) {
  const comp = (config?.components || []).find(c => c.id === compId);
  if (!comp) return;
  const card = document.getElementById(`component-card-${compId}`);
  if (!card) return;
  card.outerHTML = buildComponentCard(comp, { detailed: true });
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

function openSnapshotLightbox(src, title, subtitle = '') {
  const lightbox = document.getElementById('snapshotLightbox');
  const image = document.getElementById('lightboxImage');
  const titleEl = document.getElementById('lightboxTitle');
  const subtitleEl = document.getElementById('lightboxSubtitle');
  if (!lightbox || !image || !titleEl || !subtitleEl) return;
  image.src = src;
  titleEl.textContent = title || 'Snapshot';
  subtitleEl.textContent = subtitle;
  lightbox.style.display = 'flex';
}

function closeSnapshotLightbox() {
  const lightbox = document.getElementById('snapshotLightbox');
  const image = document.getElementById('lightboxImage');
  if (!lightbox || !image) return;
  lightbox.style.display = 'none';
  image.src = '';
}

function syncNavMapZoomLabel() {
  const label = document.getElementById('navMapZoomLabel');
  if (!label) return;
  label.textContent = `${Math.round(navMapZoom * 100)}%`;
}

function changeNavMapZoom(delta) {
  navMapZoom = Math.max(0.55, Math.min(2, Math.round((navMapZoom + delta) * 100) / 100));
  syncNavMapZoomLabel();
  if (currentPage === 'navmap') renderNavMap();
}

function resetNavMapZoom() {
  navMapZoom = 1;
  syncNavMapZoomLabel();
  if (currentPage === 'navmap') renderNavMap();
}

// ─── State ────────────────────────────────────────────────────────────────────
let config = null;
let currentPage = 'loader';
let validationReport = { errors: [], warnings: [] };
let componentEditorState = {};
let viewDetailState = {};
let currentFoundationDetail = null;
let currentComponentDetailId = null;
let currentViewDetailId = null;
let currentInspectorPreview = null;
let navMapZoom = 1;
let globalSearchQuery = '';
let pageFilterState = { tokens: 'all', icons: 'all', components: 'all', views: 'all' };
let currentLoadSource = null;
let currentStatus = { type: 'loading', text: 'Booting studio…' };
let pendingInitialRoute = null;
let routeHistoryIndex = 0;
let routeHistoryMax = 0;
let isRestoringRoute = false;
window.__humbleAssetMap = new Map();

const NAVIGATION_TYPES = new Set(['push', 'sheet', 'replace', 'pop']);
const BUNDLE_EXTENSIONS = ['.humblebundle', '.zip'];
const LAST_SOURCE_STORAGE_KEY = 'humbleStudio:lastSource';

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

// ─── Route history ────────────────────────────────────────────────────────────
function routesMatch(a, b) {
  return JSON.stringify(a || null) === JSON.stringify(b || null);
}

function getCurrentRoute() {
  if (currentPage === 'components' && currentComponentDetailId) {
    return { page: 'componentdetail', componentId: currentComponentDetailId };
  }
  if (currentPage === 'viewdetail' && currentViewDetailId) {
    return { page: 'viewdetail', viewId: currentViewDetailId };
  }
  if (currentPage === 'foundationdetail' && currentFoundationDetail?.kind && currentFoundationDetail?.id) {
    return { page: 'foundationdetail', kind: currentFoundationDetail.kind, id: currentFoundationDetail.id };
  }
  return { page: currentPage || 'loader' };
}

function encodeRouteHash(route) {
  if (!route?.page || route.page === 'loader') return '';
  if (route.page === 'componentdetail' && route.componentId) {
    return `#/components/${encodeURIComponent(route.componentId)}`;
  }
  if (route.page === 'viewdetail' && route.viewId) {
    return `#/views/${encodeURIComponent(route.viewId)}`;
  }
  if (route.page === 'foundationdetail' && route.kind && route.id) {
    return `#/foundation/${encodeURIComponent(route.kind)}/${encodeURIComponent(route.id)}`;
  }
  return `#/${encodeURIComponent(route.page)}`;
}

function decodeRouteHash(hash) {
  const cleaned = String(hash || '').replace(/^#\/?/, '').trim();
  if (!cleaned) return { page: 'loader' };
  const parts = cleaned.split('/').map(part => decodeURIComponent(part));
  if (parts[0] === 'components' && parts[1]) return { page: 'componentdetail', componentId: parts[1] };
  if (parts[0] === 'views' && parts[1]) return { page: 'viewdetail', viewId: parts[1] };
  if (parts[0] === 'foundation' && parts[1] && parts[2]) return { page: 'foundationdetail', kind: parts[1], id: parts[2] };
  if (parts[0] === 'tokens' || parts[0] === 'icons' || parts[0] === 'typography' || parts[0] === 'spacing' || parts[0] === 'components' || parts[0] === 'views' || parts[0] === 'navmap' || parts[0] === 'loader') {
    return { page: parts[0] };
  }
  return { page: 'loader' };
}

function routeNeedsConfig(route) {
  return route?.page && route.page !== 'loader';
}

function buildHistoryState(route, index) {
  return {
    humbleStudio: true,
    route,
    routeIndex: index,
  };
}

function syncCurrentRoute(options = {}) {
  const route = getCurrentRoute();
  if (!route) {
    syncNativeShellState();
    return;
  }

  const currentStateRoute = history.state?.humbleStudio ? history.state.route : decodeRouteHash(window.location.hash);
  const url = new URL(window.location.href);
  url.hash = encodeRouteHash(route);

  if (!isRestoringRoute && !options.skipHistory) {
    if (options.replaceHistory) {
      history.replaceState(buildHistoryState(route, routeHistoryIndex), '', url);
    } else if (!routesMatch(route, currentStateRoute)) {
      routeHistoryIndex += 1;
      routeHistoryMax = routeHistoryIndex;
      history.pushState(buildHistoryState(route, routeHistoryIndex), '', url);
    }
  }

  syncNativeShellState();
}

function showRoute(route, options = {}) {
  if (!route?.page) {
    showPage('loader', null, options);
    return;
  }

  if (routeNeedsConfig(route) && !config) {
    pendingInitialRoute = route;
    showPage('loader', null, { ...options, skipHistory: true });
    return;
  }

  if (route.page === 'componentdetail') {
    showComponentPage(route.componentId, options);
    return;
  }
  if (route.page === 'viewdetail') {
    showPage('viewdetail', route.viewId, options);
    return;
  }
  if (route.page === 'foundationdetail') {
    showFoundationDetail(route.kind, route.id, options);
    return;
  }
  showPage(route.page, null, options);
}

function bootstrapRouteHistory() {
  const stateRoute = history.state?.humbleStudio ? history.state.route : null;
  const initialRoute = stateRoute || decodeRouteHash(window.location.hash);
  routeHistoryIndex = history.state?.humbleStudio ? (history.state.routeIndex || 0) : 0;
  routeHistoryMax = routeHistoryIndex;

  if (!history.state?.humbleStudio) {
    const url = new URL(window.location.href);
    url.hash = encodeRouteHash(initialRoute);
    history.replaceState(buildHistoryState(initialRoute, 0), '', url);
  }

  if (routeNeedsConfig(initialRoute)) {
    pendingInitialRoute = initialRoute;
  }

  window.addEventListener('popstate', event => {
    const route = event.state?.humbleStudio ? event.state.route : decodeRouteHash(window.location.hash);
    routeHistoryIndex = event.state?.humbleStudio ? (event.state.routeIndex || 0) : routeHistoryIndex;
    isRestoringRoute = true;
    showRoute(route, { skipHistory: true });
    isRestoringRoute = false;
  });
}

// ─── Page routing ─────────────────────────────────────────────────────────────
function showPage(id, extra, options = {}) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  const page = document.getElementById('page-' + id);
  if (page) page.classList.add('active');
  currentPage = id;
  if (id === 'components' && !extra) currentComponentDetailId = null;
  if (id !== 'viewdetail') currentViewDetailId = null;
  if (id !== 'foundationdetail') currentFoundationDetail = null;
  syncSidebarActive(id, extra);

  const viewTitle = id === 'viewdetail' && extra
    ? ((config?.views || []).find(view => view.id === extra)?.name || extra)
    : 'View';
  const titles = { loader:'HumbleStudio', tokens:'Tokens', icons:'Icons', foundationdetail: 'Foundation Detail', typography:'Typography', spacing:'Spacing & Radius', components:'Components', views:'Views', navmap:'Navigation Map', viewdetail: viewTitle };
  document.getElementById('topTitle').textContent = titles[id] || id;
  document.getElementById('topBreadcrumb').textContent = config ? (config.meta?.name || '') : '';
  renderTopbarSource();
  renderPageFilters();

  if (id === 'viewdetail' && extra) renderViewDetail(extra);
  if (id === 'foundationdetail' && extra) renderFoundationDetail(extra.kind, extra.id);
  if (id === 'components' && !extra) {
    syncComponentsPageChrome('dashboard');
    renderComponents();
  }
  if (id === 'views') renderViews();
  if (id === 'navmap') renderNavMap();
  syncCurrentRoute(options);
}

// ─── Config loaders ───────────────────────────────────────────────────────────
async function loadFromUrl() {
  const url = document.getElementById('urlInput').value.trim();
  if (!url) return;
  rememberLastSource({ type: 'url', value: url });
  setCurrentLoadSource({ type: 'url', value: url });
  updateLoaderSourceUi();
  await loadConfigFromUrl(url);
}

async function loadConfigFromUrl(url) {
  setStatus('loading', 'Loading...');
  try {
    const r = await fetch(url);
    if (!r.ok) throw new Error('HTTP ' + r.status);
    const buffer = await r.arrayBuffer();
    if (isBundlePayload(buffer, url) || isBundleResponse(r)) {
      loadBundleFromArrayBuffer(buffer, url);
      return;
    }

    clearBundleAssets();
    const raw = new TextDecoder().decode(buffer);
    applyConfig(JSON.parse(raw));
  } catch (e) {
    setStatus('err', 'Load failed: ' + e.message);
  }
}

async function loadFromFile(e) {
  const file = e.target.files[0];
  if (!file) return;
  await loadConfigFromFile(file);
}

async function loadConfigFromFile(file) {
  const label = document.getElementById('fileInputLabel');
  if (label) label.textContent = file.name;
  rememberLastSource({ type: 'file', value: file.name });
  setCurrentLoadSource({ type: 'file', value: file.name });
  updateLoaderSourceUi();
  setStatus('loading', 'Reading file...');
  try {
    const buffer = await file.arrayBuffer();
    if (isBundlePayload(buffer, file.name)) {
      loadBundleFromArrayBuffer(buffer, file.name);
      return;
    }
    clearBundleAssets();
    applyConfig(JSON.parse(new TextDecoder().decode(buffer)));
  } catch (err) {
    setStatus('err', 'Invalid file: ' + err.message);
  }
}

function base64ToArrayBuffer(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

async function loadNativePayload(fileName, base64) {
  if (!fileName || !base64) {
    setStatus('err', 'Native import failed: missing file payload.');
    return false;
  }

  const label = document.getElementById('fileInputLabel');
  if (label) label.textContent = fileName;

  rememberLastSource({ type: 'file', value: fileName });
  setCurrentLoadSource({ type: 'file', value: fileName });
  updateLoaderSourceUi();
  setStatus('loading', 'Importing native file...');

  try {
    const buffer = base64ToArrayBuffer(base64);
    if (isBundlePayload(buffer, fileName)) {
      loadBundleFromArrayBuffer(buffer, fileName);
      return true;
    }

    clearBundleAssets();
    applyConfig(JSON.parse(new TextDecoder().decode(buffer)));
    return true;
  } catch (error) {
    setStatus('err', `Native import failed: ${error.message}`);
    return false;
  }
}

function loadDemo() {
  clearBundleAssets();
  rememberLastSource({ type: 'demo', value: 'HumbleSudoku demo config' });
  setCurrentLoadSource({ type: 'demo', value: 'HumbleSudoku demo config' });
  updateLoaderSourceUi();
  applyConfig(DEMO_CONFIG);
}

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
      detailTab: 'preview',
      draft: JSON.stringify(mock.props || {}, null, 2),
      error: '',
    };
  }
  return componentEditorState[component.id];
}

function isEditablePrimitiveValue(value) {
  return value == null || ['string', 'number', 'boolean'].includes(typeof value);
}

function flattenEditableProps(value, prefix = '', bucket = []) {
  if (isEditablePrimitiveValue(value)) {
    if (prefix) bucket.push([prefix, value]);
    return bucket;
  }
  if (Array.isArray(value)) return bucket;
  if (!isPlainObject(value)) return bucket;
  Object.entries(value).forEach(([key, entry]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    flattenEditableProps(entry, path, bucket);
  });
  return bucket;
}

function getDraftProps(component) {
  const state = getComponentEditorState(component);
  if (!state?.draft) return { ...(getDefaultMock(component).props || {}) };
  try {
    return JSON.parse(state.draft);
  } catch {
    return { ...(getDefaultMock(component).props || {}) };
  }
}

function getViewDetailState(view) {
  if (!view) return null;
  if (!viewDetailState[view.id]) {
    viewDetailState[view.id] = {
      detailTab: 'preview',
    };
  }
  return viewDetailState[view.id];
}

function getValueAtPath(object, path) {
  return String(path || '')
    .split('.')
    .filter(Boolean)
    .reduce((current, key) => (current == null ? undefined : current[key]), object);
}

function setValueAtPath(object, path, value) {
  const keys = String(path || '').split('.').filter(Boolean);
  if (!keys.length) return object;
  const nextObject = isPlainObject(object) ? { ...object } : {};
  let cursor = nextObject;
  keys.forEach((key, index) => {
    if (index === keys.length - 1) {
      cursor[key] = value;
      return;
    }
    const current = cursor[key];
    cursor[key] = isPlainObject(current) ? { ...current } : {};
    cursor = cursor[key];
  });
  return nextObject;
}

function titleCaseToken(token) {
  return String(token || '')
    .replace(/([a-z0-9])([A-Z])/g, '$1 $2')
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, char => char.toUpperCase());
}

function getGuidedControlMeta(path, kind) {
  const explicit = {
    selected: { label: 'Selected Number', hint: 'Pick the currently highlighted value.' },
    disabled: { label: 'Disabled State', hint: 'Toggle whether the control is inactive.' },
    title: { label: 'Title', hint: 'Main visible title for this component.' },
    subtitle: { label: 'Subtitle', hint: 'Secondary helper copy shown under the title.' },
    message: { label: 'Message', hint: 'Inline feedback text shown to the user.' },
    value: { label: 'Value', hint: 'Primary displayed value.' },
    badge: { label: 'Badge', hint: 'Small supporting label shown on the right.' },
    icon: { label: 'Icon', hint: 'Symbol used by this component state.' },
    rows: { label: 'Rows Preset', hint: 'Switch between declared row configurations.' },
    tiles: { label: 'Import Tiles', hint: 'Swap between declared tile layouts.' },
    buttons: { label: 'Button Set', hint: 'Choose a declared button arrangement.' },
    actions: { label: 'Action Buttons', hint: 'Switch between declared action groups.' },
    success: { label: 'Success Message', hint: 'Choose a declared success state block.' },
    error: { label: 'Error Message', hint: 'Inline error feedback shown in this state.' },
    statusIcon: { label: 'Status Icon', hint: 'Visual status marker for this row.' },
    trailingIcon: { label: 'Trailing Icon', hint: 'Accessory icon shown on the right.' },
    style: { label: 'Visual Style', hint: 'Declared visual variant for this component.' },
    label: { label: 'Label', hint: 'Primary label shown to the user.' },
    counts: { label: 'Counts Preset', hint: 'Use a declared availability/counts setup.' },
  };

  const token = String(path || '').split('.').pop();
  const meta = explicit[path] || explicit[token] || {};
  const label = meta.label || String(path || '').split('.').map(titleCaseToken).join(' / ');
  const hint = meta.hint || (kind === 'preset'
    ? 'Switch between declared structured variants.'
    : kind === 'boolean'
      ? 'Toggle this declared state value.'
      : 'Choose from values declared in the component states.');
  return { label, hint };
}

function getStructuredPropControls(component) {
  const states = getComponentStates(component);
  if (!states.length) return [];
  const valuesByPath = new Map();
  const complexValuesByPath = new Map();

  states.forEach(state => {
    const props = state.props || {};
    flattenEditableProps(props).forEach(([path, value]) => {
      if (!valuesByPath.has(path)) valuesByPath.set(path, []);
      valuesByPath.get(path).push(value);
    });
    Object.entries(props).forEach(([key, value]) => {
      if (Array.isArray(value) || isPlainObject(value)) {
        if (!complexValuesByPath.has(key)) complexValuesByPath.set(key, []);
        complexValuesByPath.get(key).push({ value, stateId: state.id, stateLabel: state.label });
      }
    });
  });

  const primitiveControls = [...valuesByPath.entries()]
    .map(([path, values]) => {
      const uniqueValues = [...new Map(values.map(value => [JSON.stringify(value), value])).values()];
      const sample = uniqueValues.find(value => value != null) ?? uniqueValues[0];
      const kind = typeof sample === 'boolean'
        ? 'boolean'
        : typeof sample === 'number'
          ? 'number'
          : 'string';
      return {
        path,
        ...getGuidedControlMeta(path, kind),
        kind,
        options: uniqueValues,
      };
    })
    .filter(control => control.path && (control.options.length > 1 || control.kind === 'boolean'))
    .sort((left, right) => left.path.localeCompare(right.path));

  const complexControls = [...complexValuesByPath.entries()]
    .map(([path, entries]) => {
      const uniqueEntries = [...new Map(entries.map(entry => [JSON.stringify(entry.value), entry])).values()];
      if (uniqueEntries.length <= 1) return null;
      return {
        path,
        ...getGuidedControlMeta(path, 'preset'),
        kind: 'preset',
        options: uniqueEntries.map(entry => ({
          value: entry.value,
          label: entry.stateLabel || entry.stateId || path,
        })),
      };
    })
    .filter(Boolean)
    .sort((left, right) => left.path.localeCompare(right.path));

  return [...primitiveControls, ...complexControls];
}

function isBundleFileName(name = '') {
  const normalized = String(name || '').toLowerCase();
  return BUNDLE_EXTENSIONS.some(ext => normalized.endsWith(ext));
}

function isBundlePayload(buffer, name = '') {
  if (isBundleFileName(name)) return true;
  if (!(buffer instanceof ArrayBuffer) || buffer.byteLength < 4) return false;
  const bytes = new Uint8Array(buffer.slice(0, 4));
  return bytes[0] === 0x50 && bytes[1] === 0x4b && bytes[2] === 0x03 && bytes[3] === 0x04;
}

function isBundleResponse(response) {
  const contentType = response.headers.get('content-type') || '';
  return contentType.includes('zip');
}

function inferBundleMimeType(name) {
  const normalized = name.toLowerCase();
  if (normalized.endsWith('.png')) return 'image/png';
  if (normalized.endsWith('.jpg') || normalized.endsWith('.jpeg')) return 'image/jpeg';
  if (normalized.endsWith('.webp')) return 'image/webp';
  if (normalized.endsWith('.gif')) return 'image/gif';
  if (normalized.endsWith('.svg')) return 'image/svg+xml';
  if (normalized.endsWith('.json')) return 'application/json';
  return 'application/octet-stream';
}

function clearBundleAssets() {
  const currentAssets = window.__humbleAssetMap;
  if (!(currentAssets instanceof Map)) {
    window.__humbleAssetMap = new Map();
    return;
  }
  currentAssets.forEach(url => URL.revokeObjectURL(url));
  currentAssets.clear();
}

function normalizeBundleAssetKey(name) {
  return String(name || '').replace(/^\.?\//, '').replace(/^\/+/, '');
}

function registerBundleAssets(entries) {
  clearBundleAssets();
  const assetMap = new Map();
  Object.entries(entries).forEach(([name, bytes]) => {
    const normalizedName = normalizeBundleAssetKey(name);
    if (!normalizedName || normalizedName.endsWith('/') || normalizedName.endsWith('design.json')) return;

    const blob = new Blob([bytes], { type: inferBundleMimeType(normalizedName) });
    const blobUrl = URL.createObjectURL(blob);
    const baseName = normalizedName.split('/').pop();
    assetMap.set(normalizedName, blobUrl);
    if (baseName && !assetMap.has(baseName)) assetMap.set(baseName, blobUrl);
  });
  window.__humbleAssetMap = assetMap;
}

function findBundleDesignEntry(entries) {
  const names = Object.keys(entries);
  return names.find(name => normalizeBundleAssetKey(name) === 'design.json')
    || names.find(name => normalizeBundleAssetKey(name).endsWith('/design.json'))
    || null;
}

function loadBundleFromArrayBuffer(buffer, sourceName = 'bundle') {
  if (!window.fflate?.unzipSync) {
    setStatus('err', 'Bundle support is not available because the unzip library failed to load.');
    return;
  }

  try {
    setStatus('loading', 'Unpacking bundle...');
    const archive = window.fflate.unzipSync(new Uint8Array(buffer));
    const designEntry = findBundleDesignEntry(archive);
    if (!designEntry) throw new Error('Bundle does not contain `design.json`.');

    registerBundleAssets(archive);

    const rawConfig = new TextDecoder().decode(archive[designEntry]);
    applyConfig(JSON.parse(rawConfig));
    setStatus('ok', `Loaded bundle: ${sourceName}`);
  } catch (error) {
    clearBundleAssets();
    setStatus('err', `Bundle load failed: ${error.message}`);
  }
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
  if (!(window.__humbleAssetMap instanceof Map)) {
    window.__humbleAssetMap = new Map();
  }
  const report = validateConfig(data);
  config = report.normalized;
  validationReport = { errors: report.errors, warnings: report.warnings };
  componentEditorState = {};
  viewDetailState = {};
  globalSearchQuery = '';
  pageFilterState = { tokens: 'all', icons: 'all', components: 'all', views: 'all' };
  buildSidebar();
  syncSearchUi();
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
  document.getElementById('topbarSearch').style.display = '';
  updateLoaderSourceUi();
  renderTopbarSource();
  const routeToRestore = pendingInitialRoute;
  pendingInitialRoute = null;
  if (routeToRestore && routeNeedsConfig(routeToRestore)) {
    showRoute(routeToRestore, { replaceHistory: true });
  } else {
    showPage('tokens', null, { replaceHistory: true });
  }
  syncNativeShellState();
}

function setStatus(type, msg) {
  currentStatus = { type, text: msg };
  const dot = document.getElementById('statusDot');
  dot.className = 'status-dot';
  if (type === 'loading') dot.classList.add('loading');
  if (type === 'err')     dot.classList.add('err');
  if (type === 'warn')    dot.classList.add('warn');
  document.getElementById('statusText').textContent = msg;
  syncNativeShellState();
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
  if (id === 'components' && extra) navKey = 'page:components';
  if (id === 'viewdetail' && extra) navKey = 'page:views';
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
  document.getElementById('sbExploreSections').style.display   = '';
  document.getElementById('cntTokens').textContent = Object.keys(config.tokens?.colors || {}).length + Object.keys(config.tokens?.gradients || {}).length;
  document.getElementById('cntIcons').textContent = (config.tokens?.icons || []).length;
  document.getElementById('cntComponents').textContent = (config.components || []).length;
  document.getElementById('cntViews').textContent = (config.views || []).length;
}

function syncSearchUi() {
  const input = document.getElementById('globalSearchInput');
  const clearBtn = document.getElementById('globalSearchClear');
  if (input) input.value = globalSearchQuery;
  if (clearBtn) clearBtn.style.display = globalSearchQuery ? '' : 'none';
}

function rerenderCurrentPage() {
  if (!config) return;
  if (currentPage === 'tokens') renderTokens();
  if (currentPage === 'icons') renderIcons();
  if (currentPage === 'components') {
    const currentComp = (config.components || []).find(component => component.id === currentComponentDetailId);
    if (currentComp && document.getElementById(`component-card-${currentComp.id}`)) {
      showComponentPage(currentComp.id);
    } else {
      syncComponentsPageChrome('dashboard');
      renderComponents();
    }
  }
  if (currentPage === 'views') renderViews();
  if (currentPage === 'viewdetail') {
    const currentView = (config.views || []).find(view => view.id === currentViewDetailId);
    if (currentView) renderViewDetail(currentView.id);
  }
  if (currentPage === 'foundationdetail' && currentFoundationDetail) {
    renderFoundationDetail(currentFoundationDetail.kind, currentFoundationDetail.id);
  }
}

function resetDiscoveryPage(page) {
  globalSearchQuery = '';
  if (page && pageFilterState[page] !== undefined) pageFilterState[page] = 'all';
  syncSearchUi();
  renderPageFilters();
  rerenderCurrentPage();
}

function handleGlobalSearch(value) {
  globalSearchQuery = String(value || '').trim();
  syncSearchUi();
  rerenderCurrentPage();
}

function clearGlobalSearch() {
  globalSearchQuery = '';
  syncSearchUi();
  rerenderCurrentPage();
}

function setPageFilter(page, value) {
  pageFilterState[page] = value;
  renderPageFilters();
  rerenderCurrentPage();
}

function buildFilterButton(page, value, label) {
  const active = pageFilterState[page] === value ? ' active' : '';
  return `<button class="filter-chip${active}" onclick="setPageFilter('${page}','${value}')">${label}</button>`;
}

function renderPageFilters() {
  const el = document.getElementById('pageFilters');
  if (!el || !config) return;
  let html = '';
  if (currentPage === 'tokens') {
    html = [
      buildFilterButton('tokens', 'all', 'All'),
      buildFilterButton('tokens', 'colors', 'Colors'),
      buildFilterButton('tokens', 'gradients', 'Gradients'),
      buildFilterButton('tokens', 'linked', 'Linked Only'),
    ].join('');
  } else if (currentPage === 'icons') {
    html = [
      buildFilterButton('icons', 'all', 'All'),
      buildFilterButton('icons', 'components', 'With Components'),
      buildFilterButton('icons', 'views', 'With Views'),
    ].join('');
  } else if (currentPage === 'components') {
    html = [
      buildFilterButton('components', 'all', 'All'),
      buildFilterButton('components', 'used', 'Used'),
      buildFilterButton('components', 'catalog', 'Catalog'),
      buildFilterButton('components', 'snapshot', 'Snapshot'),
    ].join('');
  } else if (currentPage === 'views') {
    html = [
      buildFilterButton('views', 'all', 'All'),
      buildFilterButton('views', 'root', 'Root'),
      buildFilterButton('views', 'snapshot', 'Snapshot'),
      buildFilterButton('views', 'navigating', 'Has Navigation'),
    ].join('');
  }

  if (!html) {
    el.style.display = 'none';
    el.innerHTML = '';
    return;
  }

  el.style.display = '';
  el.innerHTML = html;
}

function rememberLastSource(source) {
  try {
    localStorage.setItem(LAST_SOURCE_STORAGE_KEY, JSON.stringify(source));
  } catch {}
}

function setCurrentLoadSource(source) {
  currentLoadSource = source || null;
  syncNativeShellState();
}

function getRememberedSource() {
  try {
    const raw = localStorage.getItem(LAST_SOURCE_STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

function getSourceLabel(source) {
  if (!source?.value) return '';
  if (source.type === 'url') return 'URL source';
  if (source.type === 'file') return 'Local file';
  if (source.type === 'demo') return 'Demo source';
  return 'Source';
}

function getSourceValueLabel(source) {
  if (!source?.value) return '';
  if (source.type === 'url') {
    try {
      const parsed = new URL(source.value);
      return `${parsed.host}${parsed.pathname}`;
    } catch {
      return source.value;
    }
  }
  return source.value;
}

function renderTopbarSource() {
  const el = document.getElementById('topSource');
  if (!el) return;
  if (!currentLoadSource?.value) {
    el.style.display = 'none';
    el.textContent = '';
    return;
  }
  el.style.display = '';
  el.textContent = `${getSourceLabel(currentLoadSource)} · ${getSourceValueLabel(currentLoadSource)}`;
}

function getNativeShellTitle() {
  if (currentPage === 'components' && currentComponentDetailId) {
    const component = (config?.components || []).find(entry => entry.id === currentComponentDetailId);
    if (component?.name) return component.name;
  }
  if (currentPage === 'viewdetail' && currentViewDetailId) {
    const view = (config?.views || []).find(entry => entry.id === currentViewDetailId);
    if (view?.name) return view.name;
  }
  if (currentPage === 'foundationdetail' && currentFoundationDetail?.id) {
    return currentFoundationDetail.id;
  }
  return document.getElementById('topTitle')?.textContent?.trim() || 'HumbleStudio';
}

function postNativeShellMessage(type, payload) {
  try {
    const handler = window.webkit?.messageHandlers?.studioShell;
    if (!handler?.postMessage) return;
    handler.postMessage({ type, payload });
  } catch {}
}

function syncNativeShellState() {
  postNativeShellMessage('shellState', {
    title: getNativeShellTitle(),
    breadcrumb: document.getElementById('topBreadcrumb')?.textContent?.trim() || '',
    sourceType: currentLoadSource?.type || '',
    sourceLabel: getSourceLabel(currentLoadSource),
    sourceValue: getSourceValueLabel(currentLoadSource),
    statusText: currentStatus.text || '',
    statusLevel: currentStatus.type || '',
    canGoBack: routeHistoryIndex > 0,
    canGoForward: routeHistoryIndex < routeHistoryMax,
  });
}

function navigateBack() {
  if (routeHistoryIndex <= 0) return false;
  window.history.back();
  return true;
}

function navigateForward() {
  if (routeHistoryIndex >= routeHistoryMax) return false;
  window.history.forward();
  return true;
}

function clearRememberedSource() {
  try {
    localStorage.removeItem(LAST_SOURCE_STORAGE_KEY);
  } catch {}
  if (currentLoadSource && currentLoadSource.type !== 'file') {
    currentLoadSource = null;
    renderTopbarSource();
  }
  updateLoaderSourceUi();
}

async function reloadLastSource() {
  const source = getRememberedSource();
  if (!source) return;
  if (source.type === 'url' && source.value) {
    document.getElementById('urlInput').value = source.value;
    await loadConfigFromUrl(source.value);
    return;
  }
  if (source.type === 'demo') {
    loadDemo();
    return;
  }
  setStatus('warn', 'Local files cannot be restored automatically. Please drop or choose the file again.');
}

function updateLoaderSourceUi() {
  const actions = document.getElementById('loaderUrlActions');
  const reloadBtn = document.getElementById('reloadLastSourceBtn');
  const urlInput = document.getElementById('urlInput');
  const source = getRememberedSource();
  if (source?.type === 'url' && urlInput && !urlInput.value) {
    urlInput.value = source.value || '';
  }
  if (!currentLoadSource && source?.value) {
    setCurrentLoadSource(source);
    renderTopbarSource();
  }
  if (!actions || !reloadBtn) return;
  if (!source?.value) {
    actions.style.display = 'none';
    reloadBtn.textContent = '';
    return;
  }
  actions.style.display = 'flex';
  if (source.type === 'url') {
    reloadBtn.textContent = `Reload ${source.value}`;
  } else if (source.type === 'demo') {
    reloadBtn.textContent = 'Reload HumbleSudoku demo';
  } else {
    reloadBtn.textContent = `Last local file: ${source.value}`;
  }
}

function setDropzoneState(active) {
  const dropzone = document.getElementById('loaderDropzone');
  if (!dropzone) return;
  dropzone.classList.toggle('drag-active', Boolean(active));
}

function handleGlobalDropState(event) {
  if (!event.dataTransfer?.types?.includes('Files')) return;
  event.preventDefault();
  setDropzoneState(event.type === 'dragenter' || event.type === 'dragover');
}

async function handleDroppedFiles(event) {
  if (!event.dataTransfer?.files?.length) return;
  event.preventDefault();
  setDropzoneState(false);
  await loadConfigFromFile(event.dataTransfer.files[0]);
}

async function bootstrapLoaderExperience() {
  updateLoaderSourceUi();
  syncNavMapZoomLabel();

  const dropzone = document.getElementById('loaderDropzone');
  if (dropzone) {
    dropzone.addEventListener('dragenter', handleGlobalDropState);
    dropzone.addEventListener('dragover', handleGlobalDropState);
    dropzone.addEventListener('dragleave', () => setDropzoneState(false));
    dropzone.addEventListener('drop', handleDroppedFiles);
  }

  window.addEventListener('dragenter', handleGlobalDropState);
  window.addEventListener('dragover', handleGlobalDropState);
  window.addEventListener('drop', handleDroppedFiles);
  window.addEventListener('dragleave', event => {
    if (event.target === document.documentElement || event.target === document.body) {
      setDropzoneState(false);
    }
  });

  const params = new URLSearchParams(window.location.search);
  const sourceUrl = params.get('bundle') || params.get('config');
  if (sourceUrl) {
    document.getElementById('urlInput').value = sourceUrl;
    rememberLastSource({ type: 'url', value: sourceUrl });
    setCurrentLoadSource({ type: 'url', value: sourceUrl });
    updateLoaderSourceUi();
    await loadConfigFromUrl(sourceUrl);
  }
}

function showComponentPage(compId, options = {}) {
  const detail = renderComponentDetail(compId);
  if (!detail) return;
  showPage('components', compId, options);
}

function syncComponentsPageChrome(mode = 'dashboard', comp = null) {
  const dashboardHeader = document.getElementById('componentsDashboardHeader');
  const detailHeader = document.getElementById('componentsDetailHeader');
  const titleEl = document.getElementById('compPageTitle');
  const descEl = document.getElementById('compPageDesc');
  const dashboardDescEl = document.getElementById('componentsDashboardDesc');

  if (mode === 'detail' && comp) {
    if (dashboardHeader) dashboardHeader.style.display = 'none';
    if (detailHeader) detailHeader.style.display = 'flex';
    if (titleEl) titleEl.textContent = comp.name;
    if (descEl) {
      descEl.textContent = comp.description || [
        comp.group || null,
        comp.snapshot?.path ? 'Snapshot-backed' : (isCatalogOnlyComponent(comp) ? 'Catalog states' : 'Interactive preview'),
      ].filter(Boolean).join(' · ');
    }
    return;
  }

  if (dashboardHeader) dashboardHeader.style.display = '';
  if (detailHeader) detailHeader.style.display = 'none';
  if (dashboardDescEl) dashboardDescEl.textContent = 'All reusable UI pieces. Click to preview.';
  if (titleEl) titleEl.textContent = '';
  if (descEl) descEl.textContent = '';
}

function showComponentsDashboard(options = {}) {
  currentComponentDetailId = null;
  showPage('components', null, options);
}

function renderComponentDetail(compId, target = null) {
  const comp = (config?.components || []).find(c => c.id === compId);
  if (!comp) return null;
  if (!target?.preview) currentComponentDetailId = compId;
  getComponentEditorState(comp);
  const contentEl = target?.contentEl || document.getElementById('componentsContent');
  if (!target?.preview) syncComponentsPageChrome('detail', comp);
  if (contentEl) contentEl.innerHTML = `<div class="component-grid component-grid-detail">${buildComponentCard(comp, { detailed: true })}</div>`;
  const subtitle = [
    comp.group || null,
    comp.snapshot?.path ? 'Snapshot-backed' : (isCatalogOnlyComponent(comp) ? 'Catalog states' : 'Interactive preview'),
  ].filter(Boolean).join(' · ');
  return { title: comp.name, subtitle, openLabel: 'Open component detail' };
}

function showFoundationDetail(kind, id, options = {}) {
  currentFoundationDetail = { kind, id };
  showPage('foundationdetail', currentFoundationDetail, options);
}

function closeInspectorPreview() {
  const modal = document.getElementById('inspectorPreviewModal');
  if (!modal) return;
  modal.style.display = 'none';
  currentInspectorPreview = null;
}

function getInspectorPreviewCollection(entityType, extra = '') {
  if (entityType === 'component') {
    const components = currentPage === 'components' && !currentComponentDetailId
      ? getFilteredComponents()
      : (config?.components || []);
    return components.map(component => ({ entityType: 'component', id: component.id, extra: '' }));
  }

  if (entityType === 'view') {
    const views = currentPage === 'views'
      ? getFilteredViews()
      : (config?.views || []);
    return views.map(view => ({ entityType: 'view', id: view.id, extra: '' }));
  }

  if (entityType === 'foundation') {
    if (extra === 'icon') {
      const icons = currentPage === 'icons'
        ? getFilteredIcons()
        : (config?.tokens?.icons || []);
      return icons.map(icon => ({ entityType: 'foundation', id: icon.id || icon.name || icon.symbol, extra: 'icon' }));
    }

    if (extra === 'gradient') {
      const gradients = currentPage === 'tokens'
        ? getFilteredGradientEntries()
        : Object.entries(config?.tokens?.gradients || {});
      return gradients.map(([id]) => ({ entityType: 'foundation', id, extra: 'gradient' }));
    }

    if (extra === 'typography') {
      const entries = currentPage === 'typography'
        ? getFilteredTypographyEntries()
        : getTypographyEntries();
      return entries.map(([id]) => ({ entityType: 'foundation', id, extra: 'typography' }));
    }

    if (extra === 'spacing') {
      const entries = currentPage === 'spacing'
        ? getFilteredSpacingEntries()
        : Object.entries(config?.tokens?.spacing || {});
      return entries.map(([id]) => ({ entityType: 'foundation', id, extra: 'spacing' }));
    }

    if (extra === 'radius') {
      const entries = currentPage === 'spacing'
        ? getFilteredRadiusEntries()
        : Object.entries(config?.tokens?.radius || {});
      return entries.map(([id]) => ({ entityType: 'foundation', id, extra: 'radius' }));
    }

    const colors = currentPage === 'tokens'
      ? getFilteredColorEntries()
      : Object.entries(config?.tokens?.colors || {});
    return colors.map(([id]) => ({ entityType: 'foundation', id, extra: 'color' }));
  }

  return [];
}

function getInspectorPreviewPosition(entityType, id, extra = '') {
  const items = getInspectorPreviewCollection(entityType, extra);
  const index = items.findIndex(item => item.id === id && item.extra === extra);
  return { items, index };
}

function buildInspectorPreviewPayload(entityType, id, extra = '') {
  let detail = null;
  let bodyHtml = '';

  if (entityType === 'component') {
    const comp = (config?.components || []).find(c => c.id === id);
    if (!comp) return null;
    detail = {
      title: comp.name,
      subtitle: [comp.group || null, comp.snapshot?.path ? 'Snapshot-backed' : (isCatalogOnlyComponent(comp) ? 'Catalog states' : 'Interactive preview')].filter(Boolean).join(' · '),
      openLabel: 'Open component detail',
    };
    bodyHtml = buildComponentInspectorPreview(comp);
  } else if (entityType === 'view') {
    const view = (config?.views || []).find(v => v.id === id);
    if (!view) return null;
    const subtitleParts = [];
    if (view.root || config.navigation?.root === view.id) subtitleParts.push('Root screen');
    else subtitleParts.push(view.presentation === 'sheet' ? 'Sheet screen' : 'Screen');
    if (view.snapshot?.path) subtitleParts.push('Snapshot-backed');
    detail = {
      title: view.name,
      subtitle: subtitleParts.join(' · '),
      openLabel: 'Open view detail',
    };
    bodyHtml = buildViewInspectorPreview(view);
  } else if (entityType === 'foundation') {
    const foundationLabels = {
      color: 'Color',
      gradient: 'Gradient',
      icon: 'Icon',
      typography: 'Typography',
      spacing: 'Spacing',
      radius: 'Corner radius',
    };
    detail = {
      title: id,
      subtitle: `${foundationLabels[extra] || 'Foundation'} preview`,
      openLabel: `Open ${foundationLabels[extra] || 'foundation'} detail`,
    };
    bodyHtml = buildFoundationInspectorPreview(extra, id);
    if (!bodyHtml) return null;

    if (extra === 'icon') {
      const icon = (config?.tokens?.icons || []).find(item => (item.id || item.name || item.symbol) === id);
      if (icon?.name) detail.title = icon.name;
    } else if (extra === 'typography') {
      const token = getTypographyTokenById(id);
      if (token?.role) detail.title = token.role;
      if (token?.swiftui) detail.subtitle = `${foundationLabels[extra]} · ${token.swiftui}`;
    }
  }

  return { detail, bodyHtml };
}

function renderInspectorPreview() {
  const titleEl = document.getElementById('inspectorPreviewTitle');
  const subtitleEl = document.getElementById('inspectorPreviewSubtitle');
  const bodyEl = document.getElementById('inspectorPreviewBody');
  const openBtn = document.getElementById('inspectorPreviewOpenBtn');
  const modal = document.getElementById('inspectorPreviewModal');
  if (!titleEl || !subtitleEl || !bodyEl || !openBtn || !modal) return;
  if (!currentInspectorPreview) return;

  const { entityType, id, extra } = currentInspectorPreview;
  const payload = buildInspectorPreviewPayload(entityType, id, extra);
  if (!payload) {
    closeInspectorPreview();
    return;
  }

  const { detail, bodyHtml } = payload;
  const { items, index } = getInspectorPreviewPosition(entityType, id, extra);
  const galleryHint = items.length > 1 && index >= 0
    ? `${index + 1} of ${items.length} · Use ← →`
    : '';

  titleEl.textContent = detail.title || 'Detail preview';
  subtitleEl.textContent = [detail.subtitle || '', galleryHint].filter(Boolean).join(' · ');
  bodyEl.innerHTML = bodyHtml;
  openBtn.setAttribute('title', detail.openLabel || 'Open detail');
  openBtn.setAttribute('aria-label', detail.openLabel || 'Open detail');
  modal.style.display = 'flex';
}

function openInspectorPreview(entityType, id, extra = '') {
  currentInspectorPreview = { entityType, id, extra };
  renderInspectorPreview();
}

function shiftInspectorPreview(delta) {
  if (!currentInspectorPreview || !delta) return false;
  const { entityType, id, extra } = currentInspectorPreview;
  const { items, index } = getInspectorPreviewPosition(entityType, id, extra);
  if (index === -1 || items.length < 2) return false;
  const nextIndex = (index + delta + items.length) % items.length;
  currentInspectorPreview = items[nextIndex];
  renderInspectorPreview();
  return true;
}

function openInspectorPreviewDetail() {
  if (!currentInspectorPreview) return;
  const { entityType, id, extra } = currentInspectorPreview;
  closeInspectorPreview();
  if (entityType === 'component') {
    showComponentPage(id);
    return;
  }
  if (entityType === 'view') {
    showPage('viewdetail', id);
    return;
  }
  if (entityType === 'foundation') {
    showFoundationDetail(extra, id);
  }
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

function handleGuidedPropChange(compId, path, rawValue, kind) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state || isCatalogOnlyComponent(comp)) return;

  let nextValue = rawValue;
  if (kind === 'boolean') nextValue = rawValue === 'true';
  else if (kind === 'number') nextValue = Number(rawValue);
  else if (kind === 'preset') nextValue = JSON.parse(rawValue);

  const nextProps = setValueAtPath(getDraftProps(comp), path, nextValue);
  state.draft = JSON.stringify(nextProps, null, 2);
  state.error = '';
  state.mode = 'mock';
  rerenderComponentCard(compId);
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

function setComponentDetailTab(compId, tab) {
  const comp = (config?.components || []).find(c => c.id === compId);
  const state = getComponentEditorState(comp);
  if (!comp || !state) return;
  state.detailTab = tab || 'preview';
  rerenderComponentCard(compId);
}

function setViewDetailTab(viewId, tab) {
  const view = (config?.views || []).find(entry => entry.id === viewId);
  const state = getViewDetailState(view);
  if (!view || !state) return;
  state.detailTab = tab || 'preview';
  renderViewDetail(viewId);
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

function isTypingTarget(target) {
  if (!target) return false;
  const tag = target.tagName;
  return target.isContentEditable || tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT';
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

window.addEventListener('DOMContentLoaded', () => {
  bootstrapRouteHistory();
  bootstrapLoaderExperience();
  window.addEventListener('keydown', event => {
    if (!currentInspectorPreview) return;
    const modal = document.getElementById('inspectorPreviewModal');
    if (!modal || modal.style.display === 'none') return;
    if (event.defaultPrevented || event.metaKey || event.ctrlKey || event.altKey) return;
    if (isTypingTarget(event.target)) return;
    if (event.key === 'ArrowLeft') {
      event.preventDefault();
      shiftInspectorPreview(-1);
      return;
    }
    if (event.key === 'ArrowRight') {
      event.preventDefault();
      shiftInspectorPreview(1);
      return;
    }
    if (event.key === 'Escape') {
      event.preventDefault();
      closeInspectorPreview();
    }
  });
});

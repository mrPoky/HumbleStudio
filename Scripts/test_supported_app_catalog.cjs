'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const root = path.resolve(__dirname, '..');
const appCode = fs.readFileSync(path.join(root, 'js/app.js'), 'utf8');
const demoCode = fs.readFileSync(path.join(root, 'js/demo.js'), 'utf8');
const helperCode = fs.readFileSync(path.join(root, 'Scripts/serve_local_preview.py'), 'utf8');
const apps = vm.runInNewContext(demoCode + '\nSUPPORTED_APP_SOURCES', {});
const functionNames = [
  'normalizeSearchValue', 'getSupportedAppSource', 'filterSupportedApps',
  'isLocalhostPreview', 'getLocalSupportedAppHelperPath',
  'canUseLocalSupportedAppHelper', 'getSupportedAppLocalReadiness',
  'refreshSupportedAppSourceCatalog', 'renderSupportedApps',
  'buildSupportedAppSourceState', 'buildLocalSupportedAppSourceState',
  'readLocalHelperError', 'loadSupportedAppFromLocalHelper', 'loadSupportedApp',
];

function extract(name) {
  const match = appCode.match(new RegExp('(?:async )?function ' + name + '\\([^]*?\\n}\\n'));
  assert.ok(match, 'Missing web function: ' + name);
  return match[0];
}

const harnessCode = [
  "let supportedAppFilterQuery = '';",
  'let supportedAppStatusById = null;',
  'let supportedAppStatusChecked = false;',
  "const LOCALHOST_PREVIEW_HOSTS = new Set(['localhost','127.0.0.1','::1']);",
  "const LOCAL_SUPPORTED_APP_CATALOG_PATH = '/api/supported-apps/catalog';",
  "const LOCAL_SUPPORTED_APP_CATALOG_SCHEMA = 'humble.studio.supported-app-catalog.v1';",
  "const LOCAL_SUPPORTED_APP_EXPORT_HEADER = 'X-HumbleStudio-Local-Export';",
  ...functionNames.map(extract),
  '({filterSupportedApps,refreshSupportedAppSourceCatalog,renderSupportedApps,canUseLocalSupportedAppHelper,loadSupportedApp})',
].join('\n');

function harness(hostname, fetchImpl) {
  const nodes = {
    loaderSupportedApps: { innerHTML: '' },
    supportedAppsCount: { textContent: '' },
  };
  const trace = { status: [], remoteLoads: [], localConfigs: [], remembered: [] };
  const context = {
    window: { location: { protocol: 'http:', hostname } },
    document: { getElementById: id => nodes[id] || null },
    fetch: fetchImpl,
    SUPPORTED_APP_SOURCES: apps,
    escapeHtml: value => String(value),
    TextDecoder,
    setStatus: (level, message) => trace.status.push({ level, message }),
    rememberLastSource: source => trace.remembered.push(source),
    setCurrentLoadSource: () => {},
    updateLoaderSourceUi: () => {},
    clearBundleAssets: () => {},
    applyConfig: config => trace.localConfigs.push(config),
    isBundlePayload: () => false,
    isBundleResponse: () => false,
    loadBundleFromArrayBuffer: () => {},
    loadConfigFromUrl: async url => trace.remoteLoads.push(url),
  };
  return { api: vm.runInNewContext(harnessCode, context), nodes, trace };
}

async function main() {
  assert.equal(apps.length, 12);
  const helperCatalog = helperCode.split('def build_supported_app_catalog()')[1]
    .split('SUPPORTED_APP_EXPORTS =')[0];
  for (const app of apps) {
    assert.ok(helperCatalog.includes('"' + app.id + '"'), 'Missing local resolver: ' + app.id);
  }

  const remote = harness('example.com', async () => { throw Error('unexpected fetch'); });
  remote.api.renderSupportedApps();
  assert.equal(remote.nodes.supportedAppsCount.textContent, '12 supported apps');
  assert.ok(remote.nodes.loaderSupportedApps.innerHTML.includes('URL source'));
  remote.api.filterSupportedApps('KAKURO');
  assert.equal(remote.nodes.supportedAppsCount.textContent, '1 of 12 apps');
  assert.ok(!remote.nodes.loaderSupportedApps.innerHTML.includes('HumbleSudoku'));
  remote.api.filterSupportedApps('nothing-matches');
  assert.equal(remote.nodes.supportedAppsCount.textContent, '0 of 12 apps');
  assert.ok(remote.nodes.loaderSupportedApps.innerHTML.includes('No apps match this search.'));

  const states = apps.map(app => ({
    id: app.id,
    localStatus: 'available',
    localExportUrl: app.localSource.value,
  }));
  states.find(app => app.id === 'humble-workout').localStatus = 'repository_missing';
  states.find(app => app.id === 'humble-control').localStatus = 'generatable';
  const local = harness('localhost', async () => ({
    ok: true,
    json: async () => ({ schema: 'humble.studio.supported-app-catalog.v1', apps: states }),
  }));
  await local.api.refreshSupportedAppSourceCatalog();
  const find = id => apps.find(app => app.id === id);
  assert.equal(local.api.canUseLocalSupportedAppHelper(find('humble-sudoku')), true);
  assert.equal(local.api.canUseLocalSupportedAppHelper(find('humble-control')), true);
  assert.equal(local.api.canUseLocalSupportedAppHelper(find('humble-workout')), false);
  assert.ok(local.nodes.loaderSupportedApps.innerHTML.includes('Local repository missing · URL'));
  assert.ok(local.nodes.loaderSupportedApps.innerHTML.includes('Local export can be generated'));
  assert.ok(local.nodes.loaderSupportedApps.innerHTML.includes('Load URL'));

  // Old localhost helpers have no catalog route: retain local-first loading.
  const requests = [];
  const absent = harness('127.0.0.1', async url => {
    requests.push(url);
    return { ok: false, status: 404 };
  });
  await absent.api.refreshSupportedAppSourceCatalog();
  assert.equal(absent.api.canUseLocalSupportedAppHelper(find('humble-sudoku')), true);
  assert.ok(absent.nodes.loaderSupportedApps.innerHTML.includes('Local status unknown · try local'));
  await absent.api.loadSupportedApp('humble-sudoku');
  assert.equal(requests.length, 2);
  assert.equal(absent.trace.remoteLoads[0], find('humble-sudoku').source.value);

  for (const code of ['repository_missing', 'export_missing']) {
    const legacyMissing = harness('localhost', async url => url.endsWith('/catalog')
      ? { ok: false, status: 404 }
      : { ok: false, status: 500, json: async () => ({ error: code, message: 'Local source missing' }) });
    await legacyMissing.api.refreshSupportedAppSourceCatalog();
    await legacyMissing.api.loadSupportedApp('humble-control');
    assert.equal(legacyMissing.trace.remoteLoads[0], find('humble-control').source.value);
  }

  const legacyReady = harness('localhost', async url => url.endsWith('/catalog')
    ? { ok: false, status: 404 }
    : {
      ok: true,
      status: 200,
      headers: { get: name => name === 'X-HumbleStudio-Local-Export' ? '1' : null },
      arrayBuffer: async () => new TextEncoder().encode('{"meta":{"name":"HumbleControl"}}').buffer,
    });
  await legacyReady.api.refreshSupportedAppSourceCatalog();
  await legacyReady.api.loadSupportedApp('humble-control');
  assert.equal(legacyReady.trace.localConfigs[0].meta.name, 'HumbleControl');
  assert.equal(legacyReady.trace.remoteLoads.length, 0);

  const generatorFailure = harness('localhost', async url => url.endsWith('/catalog')
    ? { ok: false, status: 404 }
    : { ok: false, status: 500, json: async () => ({ error: 'generator_failed', message: 'Generation failed' }) });
  await generatorFailure.api.refreshSupportedAppSourceCatalog();
  await generatorFailure.api.loadSupportedApp('humble-sudoku');
  assert.equal(generatorFailure.trace.remoteLoads.length, 0);
  assert.ok(generatorFailure.trace.status.some(item => item.level === 'err'
    && item.message.includes('Generation failed')));

  const mismatched = harness('localhost', async () => ({
    ok: true,
    json: async () => ({
      schema: 'humble.studio.supported-app-catalog.v1',
      apps: [{ id: 'humble-sudoku', localStatus: 'available', localExportUrl: '/wrong/path' }],
    }),
  }));
  await mismatched.api.refreshSupportedAppSourceCatalog();
  assert.equal(mismatched.api.canUseLocalSupportedAppHelper(find('humble-sudoku')), false);

  console.log('Supported app catalog: search, readiness, legacy helper fallback, errors and 12-source parity PASS');
}

main().catch(error => { console.error(error); process.exitCode = 1; });

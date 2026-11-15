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
  ...functionNames.map(extract),
  '({filterSupportedApps,refreshSupportedAppSourceCatalog,renderSupportedApps,canUseLocalSupportedAppHelper})',
].join('\n');

function harness(hostname, fetchImpl) {
  const nodes = {
    loaderSupportedApps: { innerHTML: '' },
    supportedAppsCount: { textContent: '' },
  };
  const context = {
    window: { location: { protocol: 'http:', hostname } },
    document: { getElementById: id => nodes[id] || null },
    fetch: fetchImpl,
    SUPPORTED_APP_SOURCES: apps,
    escapeHtml: value => String(value),
  };
  return { api: vm.runInNewContext(harnessCode, context), nodes };
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

  const absent = harness('127.0.0.1', async () => ({ ok: false, status: 404 }));
  await absent.api.refreshSupportedAppSourceCatalog();
  assert.equal(absent.api.canUseLocalSupportedAppHelper(find('humble-sudoku')), false);
  assert.ok(absent.nodes.loaderSupportedApps.innerHTML.includes('Helper unavailable · URL'));

  const mismatched = harness('localhost', async () => ({
    ok: true,
    json: async () => ({
      schema: 'humble.studio.supported-app-catalog.v1',
      apps: [{ id: 'humble-sudoku', localStatus: 'available', localExportUrl: '/wrong/path' }],
    }),
  }));
  await mismatched.api.refreshSupportedAppSourceCatalog();
  assert.equal(mismatched.api.canUseLocalSupportedAppHelper(find('humble-sudoku')), false);

  console.log('Supported app catalog: search, readiness, URL fallback, 12-source parity PASS');
}

main().catch(error => { console.error(error); process.exitCode = 1; });

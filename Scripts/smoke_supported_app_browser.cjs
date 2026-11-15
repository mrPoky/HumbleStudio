'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const os = require('node:os');
const net = require('node:net');
const { spawn } = require('node:child_process');
const { chromium } = require('playwright');
const ROOT = path.resolve(__dirname, '..');
const output = process.env.HUMBLESTUDIO_SMOKE_OUTPUT_DIR || path.join(os.tmpdir(), 'humble-studio-smoke');
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
async function freePort() {
  const server = net.createServer();
  await new Promise((ok, fail) => { server.once('error', fail); server.listen(0, '127.0.0.1', ok); });
  const port = server.address().port;
  await new Promise(ok => server.close(ok));
  return port;
}
function fixture(name) {
  const data = JSON.parse(fs.readFileSync(path.join(ROOT, 'configs/humble-sudoku.json'), 'utf8'));
  data.meta.name = name;
  return JSON.stringify(data);
}
async function waitForService(origin, helper) {
  for (let i = 0; i < 70; i += 1) {
    if (helper.exitCode !== null) throw Error('Local preview helper exited');
    try {
      const r = await fetch(origin + '/api/supported-apps/catalog', { signal: AbortSignal.timeout(1000) });
      if (r.ok) return;
    } catch {}
    await pause(150);
  }
  throw Error('Local preview helper did not respond');
}
async function contains(page, selector, text) {
  await page.waitForFunction(
    args => document.querySelector(args[0])?.textContent?.includes(args[1]),
    [selector, text],
    { timeout: 12000 },
  );
}
async function main() {
  fs.mkdirSync(output, { recursive: true });
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'humble-studio-browser-'));
  const control = path.join(tmp, 'control');
  const workout = path.join(tmp, 'workout');
  fs.mkdirSync(path.join(control, '.humble'), { recursive: true });
  fs.writeFileSync(path.join(control, '.humble/design.json'), fixture('HumbleControl'));
  const origin = 'http://127.0.0.1:' + (await freePort());
  const helper = spawn('python3', [
    path.join(ROOT, 'Scripts/serve_local_preview.py'), '--host', '127.0.0.1',
    '--port', new URL(origin).port,
  ], {
    cwd: ROOT,
    env: { ...process.env, HUMBLESTUDIO_HUMBLECONTROL_REPO: control,
      HUMBLESTUDIO_HUMBLEWORKOUT_REPO: workout,
      HUMBLESTUDIO_HUMBLESUDOKU_REPO: path.join(tmp, 'missing-sudoku') },
    stdio: 'ignore',
  });
  let browser;
  let page;
  let remoteRequests = 0;
  const pageErrors = [];
  try {
    await waitForService(origin, helper);
    browser = await chromium.launch({ headless: true });
    page = await browser.newPage({ viewport: { width: 1320, height: 920 } });
    page.on('pageerror', error => pageErrors.push(error.message));
    await page.route('https://raw.githubusercontent.com/mrPoky/HumbleWorkout/main/.humble/design.json',
      route => {
        remoteRequests += 1;
        return route.fulfill({ status: 200, contentType: 'application/json',
          headers: { 'access-control-allow-origin': '*' }, body: fixture('HumbleWorkout') });
      });
    await page.goto(origin, { waitUntil: 'domcontentloaded' });
    await contains(page, '#supportedAppsCount', '12 supported apps');
    await page.locator('#supportedAppsRefresh:not([disabled])').waitFor();
    await page.locator('#supportedAppSearch').fill('HumbleControl');
    await contains(page, '#supportedAppsCount', '1 of 12 apps');
    await page.locator('.loader-supported-source-state.available').waitFor();
    await page.locator('#loaderSupportedApps .btn-full').click();
    await contains(page, '#sbAppName', 'HumbleControl v1.0');
    assert.equal(remoteRequests, 0);
    assert.equal(await page.evaluate(() => JSON.parse(localStorage.getItem('humbleStudio:lastSource')).mode), 'local');
    await page.getByRole('button', { name: /Load config/ }).click();
    await page.locator('#supportedAppSearch').fill('HumbleWorkout');
    await page.locator('.loader-supported-source-state.warning').waitFor();
    await contains(page, '.loader-supported-source-state', 'Local repository missing');
    await page.locator('#loaderSupportedApps .btn-full').click();
    await contains(page, '#sbAppName', 'HumbleWorkout v1.0');
    assert.equal(remoteRequests, 1);
    assert.equal(await page.evaluate(() => JSON.parse(localStorage.getItem('humbleStudio:lastSource')).mode), 'url');
    fs.mkdirSync(path.join(workout, '.humble'), { recursive: true });
    fs.writeFileSync(path.join(workout, '.humble/design.json'), fixture('HumbleWorkout'));
    await page.getByRole('button', { name: /Load config/ }).click();
    await page.locator('#supportedAppsRefresh').click();
    await page.locator('.loader-supported-source-state.available').waitFor();
    await page.locator('#loaderSupportedApps .btn-full').click();
    await contains(page, '#sbAppName', 'HumbleWorkout v1.0');
    assert.equal(remoteRequests, 1);
    assert.equal(await page.evaluate(() => JSON.parse(localStorage.getItem('humbleStudio:lastSource')).mode), 'local');
    await page.screenshot({ path: path.join(output, 'desktop-loaded.png'), fullPage: true });
    await page.setViewportSize({ width: 390, height: 844 });
    await page.getByRole('button', { name: /Load config/ }).click();
    await page.locator('#supportedAppSearch').fill('no-such-app');
    await contains(page, '#supportedAppsCount', '0 of 12 apps');
    await page.locator('.loader-supported-empty').waitFor();
    await page.screenshot({ path: path.join(output, 'mobile-empty.png'), fullPage: true });
    const staticPage = await browser.newPage();
    staticPage.on('pageerror', error => pageErrors.push(error.message));
    try {
      await staticPage.goto('file://' + path.join(ROOT, 'index.html'), { waitUntil: 'domcontentloaded' });
      await contains(staticPage, '#supportedAppsCount', '12 supported apps');
      assert.equal(await staticPage.locator('#supportedAppsRefresh').isVisible(), false);
      await staticPage.locator('#supportedAppSearch').fill('kakuro');
      await contains(staticPage, '#supportedAppsCount', '1 of 12 apps');
      await staticPage.screenshot({ path: path.join(output, 'static-viewer.png') });
    } finally { await staticPage.close(); }
    assert.deepEqual(pageErrors, []);
    console.log('PASS: Chromium local export, remote fallback, refresh, mobile and static viewer');
  } catch (error) {
    if (page) { try { await page.screenshot({ path: path.join(output, 'failure.png'), fullPage: true }); } catch {} }
    throw error;
  } finally {
    if (browser) await browser.close();
    helper.kill('SIGTERM');
    fs.rmSync(tmp, { recursive: true, force: true });
  }
}
main().catch(error => { console.error(error.stack || error); process.exitCode = 1; });

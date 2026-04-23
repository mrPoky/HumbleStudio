// ─── Component renderers ──────────────────────────────────────────────────────
// Note: innerHTML is used intentionally — all content comes from the developer's
// own design.json config, not from untrusted user input.

function escapeHtml(value) {
  return String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function escapeJsString(value) {
  return JSON.stringify(String(value ?? ''));
}

function resolveAssetPath(path, basePathKey = 'snapshotBasePath') {
  if (!path) return '';
  if (/^(https?:|data:|blob:|file:)/.test(path)) return path;

  const bundleAssets = window.__humbleAssetMap;
  if (bundleAssets instanceof Map && bundleAssets.size) {
    const normalizedPath = String(path).replace(/^\.?\//, '').replace(/^\/+/, '');
    const base = String(config?.assets?.[basePathKey] || '').replace(/^\.?\//, '').replace(/^\/+/, '').replace(/\/$/, '');
    const fileName = normalizedPath.split('/').pop();
    const candidates = [
      normalizedPath,
      fileName,
      base ? `${base}/${normalizedPath}` : '',
      base ? `${base}/${fileName}` : '',
    ].filter(Boolean);

    for (const candidate of candidates) {
      if (bundleAssets.has(candidate)) return bundleAssets.get(candidate);
    }
  }

  if (path.startsWith('/')) return `file://${encodeURI(path)}`;

  const base = config?.assets?.[basePathKey] || '';
  if (!base) return path;
  if (/^(https?:|file:)/.test(base)) {
    const cleanBase = base.endsWith('/') ? base.slice(0, -1) : base;
    return `${cleanBase}/${encodeURIComponent(path.split('/').pop())}`;
  }
  if (base.startsWith('/')) {
    const cleanBase = base.endsWith('/') ? base.slice(0, -1) : base;
    return `file://${encodeURI(`${cleanBase}/${path.split('/').pop()}`)}`;
  }
  return `${base.replace(/\/$/, '')}/${path.split('/').pop()}`;
}

function buildSnapshotPreview(snapshot, alt, className = 'snapshot-frame', clickable = true, compact = false) {
  if (!snapshot?.path) return '';
  const src = resolveAssetPath(snapshot.path);
  const title = snapshot.name || alt || 'Snapshot';
  const subtitle = snapshot.path || '';
  const clickAttrs = clickable ? `
      class="${className} snapshot-clickable"
      data-lightbox-src="${escapeHtml(src)}"
      data-lightbox-title="${escapeHtml(title)}"
      data-lightbox-subtitle="${escapeHtml(subtitle)}"
      onclick="openSnapshotLightbox(this.dataset.lightboxSrc, this.dataset.lightboxTitle, this.dataset.lightboxSubtitle)"`
    : ` class="${className}"`;
  return `
    <div${clickAttrs}>
      <img src="${escapeHtml(src)}" alt="${escapeHtml(alt)}" loading="lazy"
        onerror="this.closest('.snapshot-frame').classList.add('snapshot-missing')">
      ${clickable ? `<button class="snapshot-zoom" onclick="event.stopPropagation();openSnapshotLightbox(this.parentElement.dataset.lightboxSrc, this.parentElement.dataset.lightboxTitle, this.parentElement.dataset.lightboxSubtitle)">Zoom</button>` : ''}
      ${compact ? '' : `<div class="snapshot-label">${escapeHtml(snapshot.name || 'Snapshot')}</div>`}
    </div>
  `;
}

function buildIconAssetPreview(icon) {
  if (!icon?.path) return '';
  const src = resolveAssetPath(icon.path, 'iconBasePath');
  return `<img class="icon-preview-image" src="${escapeHtml(src)}" alt="${escapeHtml(icon.name || icon.symbol || 'Icon')}" loading="lazy">`;
}

function getPreviewAppearanceLabel(mode) {
  return {
    light: 'Light',
    both: 'Both',
    dark: 'Dark',
  }[mode] || 'Dark';
}

function buildPreviewAppearanceToggle(entityType, extra = '', toolbarClass = 'preview-appearance-toolbar') {
  if (typeof getSupportedPreviewAppearances !== 'function' || typeof getPreviewAppearance !== 'function') return '';
  const options = getSupportedPreviewAppearances(entityType, extra);
  if (options.length <= 1) return '';
  const active = getPreviewAppearance(entityType, extra);
  return `
    <div class="${escapeHtml(toolbarClass)}">
      <div class="cc-mode-toggle preview-appearance-toggle">
        ${options.map(option => `
          <button
            class="cc-mode-btn${option === active ? ' active' : ''}"
            onclick="setPreviewAppearance(${escapeHtml(escapeJsString(entityType))}, ${escapeHtml(escapeJsString(option))}, ${escapeHtml(escapeJsString(extra))})">
            ${escapeHtml(getPreviewAppearanceLabel(option))}
          </button>
        `).join('')}
      </div>
    </div>
  `;
}

function buildFoundationModeCompareLayout(appearance, values) {
  const normalized = appearance === 'light' || appearance === 'dark' || appearance === 'both'
    ? appearance
    : 'both';
  const dark = values.dark;
  const light = values.light;
  const sameValue = Boolean(values.sameValue);
  const panelBuilder = (label, stageClass, styleValue) => `
    <div class="${escapeHtml(values.panelClass)}">
      <div class="${escapeHtml(values.labelClass)}">${escapeHtml(label)}</div>
      <div class="${escapeHtml(stageClass)}" style="background:${escapeHtml(styleValue)}"></div>
    </div>
  `;

  if (normalized === 'light') {
    return `<div class="${escapeHtml(values.containerClass)} ${escapeHtml(values.singleClass)}">
      ${panelBuilder('Light', values.stageClass, light)}
    </div>`;
  }

  if (normalized === 'dark') {
    return `<div class="${escapeHtml(values.containerClass)} ${escapeHtml(values.singleClass)}">
      ${panelBuilder('Dark', values.stageClass, dark)}
    </div>`;
  }

  if (sameValue) {
    return `<div class="${escapeHtml(values.containerClass)} ${escapeHtml(values.singleClass)}">
      ${panelBuilder('Dark / Light', values.stageClass, dark)}
    </div>`;
  }

  return `<div class="${escapeHtml(values.containerClass)}">
    ${panelBuilder('Dark', values.stageClass, dark)}
    ${panelBuilder('Light', values.stageClass, light)}
  </div>`;
}

function buildPreviewAppearancePanels(appearance, renderMarkup, options = {}) {
  const normalized = appearance === 'light' || appearance === 'both' || appearance === 'dark'
    ? appearance
    : 'dark';
  const modes = normalized === 'both' ? ['dark', 'light'] : [normalized];
  const containerClass = normalized === 'both'
    ? 'preview-appearance-compare'
    : 'preview-appearance-single';
  const viewportClass = options.viewportClass ? ` ${options.viewportClass}` : '';

  return `
    <div class="${containerClass}">
      ${modes.map(mode => `
        <div class="preview-appearance-panel${modes.length === 1 ? ' preview-appearance-panel-single' : ''}">
          ${modes.length > 1 ? `<div class="preview-appearance-label">${escapeHtml(getPreviewAppearanceLabel(mode))}</div>` : ''}
          <div class="preview-appearance-viewport preview-appearance-viewport-${escapeHtml(mode)}${viewportClass}">
            ${renderMarkup(mode, modes.length > 1)}
          </div>
        </div>
      `).join('')}
    </div>
  `;
}

function buildComponentInspectorPreview(comp) {
  if (!comp) return '';
  const state = getComponentEditorState(comp);
  const preview = buildComponentPreviewStage(comp, state, false);
  const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('component') : 'dark';
  return `
    <div class="inspector-preview-shell inspector-preview-shell-flat">
      ${buildPreviewAppearancePanels(appearance, () => `
        <div class="inspector-preview-stage inspector-preview-stage-flat">${preview}</div>
      `, { viewportClass: 'preview-appearance-viewport-flat' })}
    </div>
  `;
}

function buildViewInspectorPreview(view) {
  if (!view) return '';
  const stage = view.snapshot?.path
    ? buildSnapshotPreview(view.snapshot, `${view.name} snapshot`, 'snapshot-frame inspector-preview-snapshot', false, true)
    : buildMiniScreen(view);
  const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('view') : 'dark';
  return `
    <div class="inspector-preview-shell inspector-preview-shell-flat">
      ${buildPreviewAppearancePanels(appearance, () => `
        <div class="inspector-preview-stage inspector-preview-stage-flat">${stage}</div>
      `, { viewportClass: 'preview-appearance-viewport-flat' })}
    </div>
  `;
}

function buildFoundationInspectorPreview(kind, id) {
  const colors = config?.tokens?.colors || {};
  const gradients = config?.tokens?.gradients || {};
  const icons = config?.tokens?.icons || [];
  const typography = getTypographyTokenById(id);
  const spacing = config?.tokens?.spacing || {};
  const radius = config?.tokens?.radius || {};

  if (kind === 'icon') {
    const item = icons.find(icon => (icon.id || icon.name || icon.symbol) === id);
    if (!item) return '';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          <div class="foundation-icon-canvas foundation-icon-canvas-flat">
            ${item.path ? buildIconAssetPreview(item) : `<div class="icon-preview-glyph icon-preview-glyph-large">${escapeHtml(item.symbol || '?')}</div>`}
          </div>
        </div>
      </div>
    `;
  }

  if (kind === 'color') {
    const item = colors[id];
    if (!item) return '';
    const dark = item.dark || item.value || item;
    const light = item.light || item.value || item;
    const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('foundation', 'color') : 'both';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          ${buildFoundationModeCompareLayout(appearance, {
            dark,
            light,
            sameValue: normalizeComparableValue(dark) === normalizeComparableValue(light),
            containerClass: 'inspector-preview-foundation-compare',
            singleClass: 'single',
            panelClass: 'inspector-preview-foundation-panel',
            labelClass: 'inspector-preview-foundation-label',
            stageClass: 'foundation-color-stage',
          })}
        </div>
      </div>
    `;
  }

  if (kind === 'gradient') {
    const item = gradients[id];
    if (!item) return '';
    const darkStops = Array.isArray(item.dark) ? item.dark : (Array.isArray(item.value) ? item.value : []);
    const lightStops = Array.isArray(item.light) ? item.light : (Array.isArray(item.value) ? item.value : []);
    const darkGradientCss = darkStops.length ? `linear-gradient(135deg, ${darkStops.join(', ')})` : 'transparent';
    const lightGradientCss = lightStops.length ? `linear-gradient(135deg, ${lightStops.join(', ')})` : darkGradientCss;
    const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('foundation', 'gradient') : 'both';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          ${buildFoundationModeCompareLayout(appearance, {
            dark: darkGradientCss,
            light: lightGradientCss,
            sameValue: arraysEqualNormalized(darkStops, lightStops) || normalizeComparableValue(darkGradientCss) === normalizeComparableValue(lightGradientCss),
            containerClass: 'inspector-preview-foundation-compare',
            singleClass: 'single',
            panelClass: 'inspector-preview-foundation-panel',
            labelClass: 'inspector-preview-foundation-label',
            stageClass: 'foundation-gradient-stage',
          })}
        </div>
      </div>
    `;
  }

  if (kind === 'typography') {
    const item = typography;
    if (!item) return '';
    const previewText = item.preview || item.role || 'Typography';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          <div class="foundation-typography-stage">
            <div class="foundation-typography-sample-wrap">
              <div class="foundation-typography-sample" style="font-size:${escapeHtml(Math.min(Number(item.size) || 16, 36))}px;font-weight:${escapeHtml(item.weight || 600)};${item.mono ? 'font-family:var(--mono);' : ''}${item.caps ? 'text-transform:uppercase;letter-spacing:1px;' : ''}${item.secondary ? 'color:var(--t2);' : ''}">
                ${escapeHtml(previewText)}
              </div>
            </div>
          </div>
        </div>
      </div>
    `;
  }

  if (kind === 'spacing') {
    const item = spacing[id];
    if (!item) return '';
    const px = Number.parseInt(item.value || item, 10) || 0;
    const scale = px % 8 === 0 ? `${px / 8}× 8pt grid` : px % 4 === 0 ? `${px / 4}× 4pt step` : 'Custom spacing step';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          <div class="foundation-metric-stage">
            <div class="foundation-metric-value">${escapeHtml(px)}px</div>
            <div class="foundation-spacing-bar" style="width:${Math.max(10, Math.min(px * 2, 260))}px"></div>
            <div class="foundation-metric-note">${escapeHtml(scale)}</div>
          </div>
        </div>
      </div>
    `;
  }

  if (kind === 'radius') {
    const item = radius[id];
    if (!item) return '';
    const px = Number.parseInt(item.value || item, 10) || 0;
    const softness = px <= 8 ? 'Subtle rounding' : px <= 16 ? 'Card rounding' : px <= 28 ? 'Strong rounding' : 'Pill / large rounding';
    return `
      <div class="inspector-preview-shell inspector-preview-shell-flat">
        <div class="inspector-preview-stage inspector-preview-stage-flat">
          <div class="foundation-metric-stage">
            <div class="foundation-metric-value">${escapeHtml(px)}px</div>
            <div class="foundation-radius-showcase">
              <div class="foundation-radius-chip foundation-radius-chip-small" style="border-radius:${escapeHtml(px)}px"></div>
              <div class="foundation-radius-chip foundation-radius-chip-medium" style="border-radius:${escapeHtml(px)}px"></div>
              <div class="foundation-radius-chip foundation-radius-chip-large" style="border-radius:${escapeHtml(px)}px"></div>
            </div>
            <div class="foundation-metric-note">${escapeHtml(softness)}</div>
          </div>
        </div>
      </div>
    `;
  }

  return '';
}

function getDeclaredUsageEntries(token) {
  return Array.isArray(token?.usedIn) ? token.usedIn : [];
}

function getReferenceCount(token) {
  if (typeof token?.references?.count === 'number') return token.references.count;
  return getDeclaredUsageCount(token);
}

function getDeclaredUsageCount(token) {
  if (typeof token?.usageCount === 'number') return token.usageCount;
  return getDeclaredUsageEntries(token).length;
}

function getComponentById(componentId) {
  return (config?.components || []).find(component => component.id === componentId) || null;
}

function getViewById(viewId) {
  return (config?.views || []).find(view => view.id === viewId) || null;
}

function uniqueById(items) {
  const seen = new Set();
  return items.filter(item => {
    if (!item?.id || seen.has(item.id)) return false;
    seen.add(item.id);
    return true;
  });
}

function designSystemList(entity, ...fieldNames) {
  const designSystem = entity?.designSystem;
  if (!designSystem || typeof designSystem !== 'object') return [];
  const values = [];
  fieldNames.forEach(fieldName => {
    if (Array.isArray(designSystem[fieldName])) values.push(...designSystem[fieldName]);
  });
  return values;
}

function symbolToGlyph(value) {
  const map = {
    qrcodeViewfinder: '⌁',
    photoOnRectangle: '▣',
    exclamationmarkTriangleFill: '⚠',
    checkmarkCircleFill: '✓',
    checkmarkCircle: '✓',
    checkmarkSealFill: '✓',
    bookmarkFill: '🔖',
    bookmark: '🔖',
    starFill: '★',
    circleDotted: '◌',
    chevronRight: '›',
    sparkles: '✦',
  };
  return map[value] || value || '•';
}

function getNavigationRootId() {
  return config?.navigation?.root || (config?.views || []).find(view => view.root)?.id || config?.views?.[0]?.id || null;
}

function getNavigationPath(viewId) {
  const rootId = getNavigationRootId();
  if (!rootId || !viewId) return [];
  const queue = [[rootId]];
  const visited = new Set([rootId]);
  while (queue.length) {
    const path = queue.shift();
    const currentId = path[path.length - 1];
    if (currentId === viewId) return path;
    const currentView = getViewById(currentId);
    (currentView?.navigatesTo || []).forEach(edge => {
      if (!edge?.viewId || visited.has(edge.viewId)) return;
      visited.add(edge.viewId);
      queue.push([...path, edge.viewId]);
    });
  }
  return [];
}

function objectContainsToken(value, tokens) {
  if (!tokens?.size || value == null) return false;
  if (typeof value === 'string') return tokens.has(value);
  if (Array.isArray(value)) return value.some(entry => objectContainsToken(entry, tokens));
  if (typeof value === 'object') return Object.values(value).some(entry => objectContainsToken(entry, tokens));
  return false;
}

function getComponentUsageViews(component) {
  if (!component) return [];
  const explicitIds = Array.isArray(component.usedInViews) ? component.usedInViews : [];
  const candidateIds = explicitIds.length
    ? explicitIds
    : (config?.views || [])
      .filter(view => (view.components || []).includes(component.id))
      .map(view => view.id);
  return uniqueById(candidateIds.map(getViewById).filter(Boolean));
}

function getIncomingViewTransitions(viewId) {
  return (config?.views || []).flatMap(view =>
    (view.navigatesTo || [])
      .filter(transition => transition?.viewId === viewId)
      .map((transition, index) => ({
        id: `${view.id}-${index}-${transition.type || 'push'}`,
        sourceView: view,
        transition,
      }))
  );
}

function getNavigationTypeLabel(type) {
  return {
    push: 'Push',
    sheet: 'Sheet',
    replace: 'Replace',
    pop: 'Back',
  }[type] || 'Push';
}

function getNavigationActionCopy(type, direction = 'outgoing') {
  const outgoing = {
    push: 'Opens next screen',
    sheet: 'Opens as modal sheet',
    replace: 'Replaces current screen',
    pop: 'Returns to previous screen',
  };
  const incoming = {
    push: 'Reached by opening this screen',
    sheet: 'Reached as a modal sheet',
    replace: 'Reached by replacing the previous screen',
    pop: 'Reached by returning back',
  };
  return (direction === 'incoming' ? incoming : outgoing)[type] || (direction === 'incoming' ? incoming.push : outgoing.push);
}

function getNavigationTriggerCopy(trigger, type, direction = 'outgoing') {
  if (trigger) return trigger;
  if (direction === 'incoming') {
    return {
      push: 'user moved here',
      sheet: 'user presented this sheet',
      replace: 'flow replaced the previous screen',
      pop: 'user went back',
    }[type] || 'user moved here';
  }
  return {
    push: 'opens the next step',
    sheet: 'opens a modal flow',
    replace: 'swaps the current screen',
    pop: 'goes back',
  }[type] || 'opens the next step';
}

function buildNavigationCard(targetName, type, trigger, direction = 'outgoing') {
  const badgeClass = {
    push: 'nav-push',
    sheet: 'nav-sheet',
    replace: 'nav-replace',
    pop: 'nav-pop',
  }[type] || 'nav-push';
  const eyebrow = direction === 'incoming' ? 'How users get here' : 'What happens next';
  return `
    <div class="nav-arrow-copy">
      <div class="nav-eyebrow">${escapeHtml(eyebrow)}</div>
      <div class="nav-headline">${escapeHtml(getNavigationActionCopy(type, direction))}</div>
      <div class="nav-trigger">${escapeHtml(getNavigationTriggerCopy(trigger, type, direction))}</div>
    </div>
    <div class="nav-arrow-target">
      <div class="nav-target-name">${escapeHtml(targetName)}</div>
      <span class="nav-badge ${badgeClass}">${escapeHtml(getNavigationTypeLabel(type))}</span>
    </div>
  `;
}

function getSiblingComponents(component) {
  const usageViews = getComponentUsageViews(component);
  const siblingIds = new Set();
  usageViews.forEach(view => {
    (view.components || []).forEach(componentId => {
      if (componentId && componentId !== component.id) siblingIds.add(componentId);
    });
  });
  return uniqueById([...siblingIds].map(getComponentById).filter(Boolean));
}

function getColorImpactEntities(colorId, color) {
  const gradientIds = getColorGradientUsages(colorId, color);
  const gradients = uniqueById(gradientIds.map(gradientId => ({ id: gradientId, ...(config?.tokens?.gradients?.[gradientId] || {}) })));
  const components = uniqueById(
    gradientIds.flatMap(gradientId => getGradientUsageEntities(gradientId, config?.tokens?.gradients?.[gradientId]).components)
  );
  const views = uniqueById(
    gradientIds.flatMap(gradientId => getGradientUsageEntities(gradientId, config?.tokens?.gradients?.[gradientId]).views)
  );
  return { gradients, components, views };
}

function getGradientUsageEntities(gradientId, gradient) {
  const explicitComponentIds = Array.isArray(gradient?.usedInComponents) ? gradient.usedInComponents : [];
  const explicitViewIds = Array.isArray(gradient?.usedInViews) ? gradient.usedInViews : [];

  const components = explicitComponentIds.length
    ? explicitComponentIds.map(getComponentById).filter(Boolean)
    : (config?.components || []).filter(component => designSystemList(component, 'gradients').includes(gradientId));

  const views = explicitViewIds.length
    ? explicitViewIds.map(getViewById).filter(Boolean)
    : (config?.views || []).filter(view => designSystemList(view, 'gradients').includes(gradientId));

  return {
    components: uniqueById(components),
    views: uniqueById(views),
  };
}

function getColorGradientUsages(colorId, color) {
  const explicit = Array.isArray(color?.usedInGradients) ? color.usedInGradients : [];
  if (explicit.length) return explicit;
  return Object.entries(config?.tokens?.gradients || {})
    .filter(([, gradient]) => Array.isArray(gradient?.colorTokens) && gradient.colorTokens.includes(colorId))
    .map(([gradientId]) => gradientId);
}

function getGradientColorTokens(gradientId, gradient) {
  const explicitIds = Array.isArray(gradient?.colorTokens) ? gradient.colorTokens : [];
  const tokenIds = explicitIds.length
    ? explicitIds
    : Object.entries(config?.tokens?.colors || {})
      .filter(([colorId, color]) => getColorGradientUsages(colorId, color).includes(gradientId))
      .map(([colorId]) => colorId);
  return uniqueById(tokenIds.map(colorId => ({ id: colorId, ...(config?.tokens?.colors?.[colorId] || {}) })));
}

function getComponentFoundationGraph(component) {
  const icons = uniqueById(
    (config?.tokens?.icons || []).filter(icon => {
      const explicit = (icon.usedInComponents || []).includes(component.id);
      const declared = designSystemList(component, 'icons', 'preferredIcons').some(value => [icon.id, icon.symbol].includes(value));
      return explicit || declared;
    })
  );

  const gradients = uniqueById(
    Object.entries(config?.tokens?.gradients || {})
      .filter(([gradientId, gradient]) => {
        if ((gradient.usedInComponents || []).includes(component.id)) return true;
        return designSystemList(component, 'gradients').includes(gradientId);
      })
      .map(([gradientId, gradient]) => ({ id: gradientId, ...gradient }))
  );

  const colors = uniqueById(
    gradients.flatMap(gradient => getGradientColorTokens(gradient.id, gradient))
  );

  return {
    colors,
    gradients,
    icons,
    primitives: uniqueById(designSystemList(component, 'primitives').map(value => ({ id: value }))).map(item => item.id),
    surfaces: uniqueById(designSystemList(component, 'surfaces').map(value => ({ id: value }))).map(item => item.id),
    textTones: uniqueById(designSystemList(component, 'textTones').map(value => ({ id: value }))).map(item => item.id),
  };
}

function getIconUsageEntities(iconId, icon) {
  const explicitComponentIds = Array.isArray(icon?.usedInComponents) ? icon.usedInComponents : [];
  const explicitViewIds = Array.isArray(icon?.usedInViews) ? icon.usedInViews : [];
  const tokens = new Set([iconId, icon?.symbol].filter(Boolean));

  const components = explicitComponentIds.length
    ? explicitComponentIds.map(getComponentById).filter(Boolean)
    : (config?.components || []).filter(component => {
      if (designSystemList(component, 'icons', 'preferredIcons').some(value => tokens.has(value))) return true;
      return [...(component.states || []), ...(component.mocks || [])].some(entry => objectContainsToken(entry?.props, tokens));
    });

  const views = explicitViewIds.length
    ? explicitViewIds.map(getViewById).filter(Boolean)
    : (config?.views || []).filter(view => designSystemList(view, 'icons', 'preferredIcons').some(value => tokens.has(value)));

  return {
    components: uniqueById(components),
    views: uniqueById(views),
  };
}

function uniqueStrings(values) {
  return [...new Set((values || []).filter(Boolean))];
}

function buildUsagePills(items, kind) {
  if (!items.length) return '<div class="foundation-empty-note">No linked items found.</div>';
  const pills = items.map(item => {
    if (kind === 'component') {
      return `<button class="usage-pill" onclick="openInspectorPreview('component', ${escapeHtml(escapeJsString(item.id))})">${escapeHtml(item.name)}<span>Component</span></button>`;
    }
    if (kind === 'view') {
      return `<button class="usage-pill" onclick="openInspectorPreview('view', ${escapeHtml(escapeJsString(item.id))})">${escapeHtml(item.name)}<span>View</span></button>`;
    }
    return `<button class="usage-pill" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(item.id))}, 'gradient')">${escapeHtml(item.id)}<span>Gradient</span></button>`;
  }).join('');
  return `<div class="usage-pill-list">${pills}</div>`;
}

function buildCodeReferenceList(entries) {
  if (!entries.length) return '';
  return `<div class="foundation-meta-card foundation-meta-card-wide">
    <div class="foundation-meta-label">Code References</div>
    <div class="foundation-usage-list">${entries.map(entry => `<div class="foundation-usage-item">${escapeHtml(entry)}</div>`).join('')}</div>
  </div>`;
}

function buildFoundationTokenPill(kind, id, subtitle = '', label = id) {
  const normalizedKind = kind === 'colors' ? 'color' : kind === 'gradients' ? 'gradient' : kind === 'icons' ? 'icon' : kind;
  const staticMarkup = `<div class="usage-pill usage-pill-static">${escapeHtml(label)}${subtitle ? `<span>${escapeHtml(subtitle)}</span>` : ''}</div>`;
  if (!id) return staticMarkup;

  if (normalizedKind === 'color' || normalizedKind === 'gradient' || normalizedKind === 'icon') {
    return `<button class="usage-pill" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(id))}, ${escapeHtml(escapeJsString(normalizedKind))})">${escapeHtml(label)}${subtitle ? `<span>${escapeHtml(subtitle)}</span>` : ''}</button>`;
  }

  return staticMarkup;
}

function buildFoundationPills(items, kind) {
  if (!items.length) return '<div class="foundation-empty-note">No linked foundation items found.</div>';
  const pills = items.map(item => {
    const subtitle = kind === 'color' ? 'Color' : kind === 'icon' ? 'Icon' : 'Gradient';
    return buildFoundationTokenPill(kind, item.id, subtitle, item.name || item.id);
  }).join('');
  return `<div class="usage-pill-list">${pills}</div>`;
}

function buildTagList(items) {
  if (!items.length) return '<div class="foundation-empty-note">No metadata declared.</div>';
  return `<div class="usage-pill-list">${items.map(item => `<div class="usage-pill usage-pill-static">${escapeHtml(item)}</div>`).join('')}</div>`;
}

function buildTokenDependencyPills(entries, kind, sourceMode = false) {
  if (!entries.length) return '<div class="foundation-empty-note">No tokens in this category.</div>';
  return `<div class="usage-pill-list">${entries.map(entry => {
    const normalized = typeof entry === 'string' ? { id: entry } : entry;
    const subtitle = sourceMode
      ? `${normalized.count || 1} ref${(normalized.count || 1) === 1 ? '' : 's'}`
      : null;
    return buildFoundationTokenPill(kind, normalized.id, subtitle);
  }).join('')}</div>`;
}

function buildTokenDependencySections(dependencies, sourceMode = false) {
  const categories = [
    ['colors', 'Colors', 'color'],
    ['gradients', 'Gradients', 'gradient'],
    ['icons', 'Icons', 'icon'],
    ['primitives', 'Primitives', 'primitive'],
    ['surfaces', 'Surfaces', 'surface'],
    ['textTones', 'Text Tones', 'textTone'],
    ['spacing', 'Spacing', 'spacing'],
    ['radius', 'Radius', 'radius'],
    ['typography', 'Typography', 'typography'],
    ['frames', 'Frames', 'frame'],
    ['actionRoles', 'Action Roles', 'actionRole'],
    ['preferredIcons', 'Preferred Icons', 'icon'],
  ];

  const sections = categories
    .filter(([key]) => Array.isArray(dependencies?.[key]) && dependencies[key].length)
    .map(([key, label, kind]) => `
      <div class="dependency-group">
        <div class="cc-related-label">${escapeHtml(label)}</div>
        ${buildTokenDependencyPills(dependencies[key], kind, sourceMode)}
      </div>
    `);

  return sections.length
    ? `<div class="dependency-group-list">${sections.join('')}</div>`
    : '<div class="foundation-empty-note">No token dependencies recorded.</div>';
}

function buildTokenDependencyPanel(entity, title = 'Token Dependencies') {
  const dependencies = entity?.tokenDependencies;
  if (!dependencies) return '';

  const summary = dependencies.summary || {};
  return `
    <div class="cc-related-panel">
      <div class="cc-usage-title">${escapeHtml(title)}</div>
      <div class="cc-capability-grid">
        <div class="cc-capability-card">
          <div class="cc-capability-label">Declared Tokens</div>
          <div class="cc-capability-value">${escapeHtml(String(summary.designTokenCount || 0))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Observed Tokens</div>
          <div class="cc-capability-value">${escapeHtml(String(summary.sourceTokenCount || 0))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Categories</div>
          <div class="cc-capability-value">${escapeHtml(String((summary.categories || []).length))}</div>
        </div>
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Declared Design Tokens</div>
        ${buildTokenDependencySections(dependencies.design || {}, false)}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Observed Source Tokens</div>
        ${buildTokenDependencySections(dependencies.source || {}, true)}
      </div>
    </div>
  `;
}

function buildTokenReferenceCards(kind, item) {
  const references = item?.references;
  if (!references || !references.count) return '';

  const designComponents = (references.design || [])
    .filter(reference => reference.type === 'component')
    .map(reference => getComponentById(reference.id))
    .filter(Boolean);
  const designViews = (references.design || [])
    .filter(reference => reference.type === 'view')
    .map(reference => getViewById(reference.id))
    .filter(Boolean);
  const derivedFoundations = uniqueById(
    (references.derived || [])
      .filter(reference => ['color', 'gradient', 'icon'].includes(reference.type))
      .map(reference => ({ id: reference.id, kind: reference.type }))
  );
  const sourceEntries = (references.source || []).map(reference =>
    `${reference.path}${reference.count ? ` · ${reference.count}×` : ''}`
  );

  return `
    <div class="foundation-meta-card">
      <div class="foundation-meta-label">Observed References</div>
      <div class="foundation-meta-value">${escapeHtml(String(references.count))}</div>
    </div>
    ${(designComponents.length || designViews.length) ? `
      <div class="foundation-meta-card foundation-meta-card-wide">
        <div class="foundation-meta-label">Design References</div>
        <div class="dependency-group-list">
          <div class="dependency-group">
            <div class="cc-related-label">Components</div>
            ${buildUsagePills(designComponents, 'component')}
          </div>
          <div class="dependency-group">
            <div class="cc-related-label">Views</div>
            ${buildUsagePills(designViews, 'view')}
          </div>
        </div>
      </div>
    ` : ''}
    ${derivedFoundations.length ? `
      <div class="foundation-meta-card foundation-meta-card-wide">
        <div class="foundation-meta-label">Derived Through</div>
        <div class="usage-pill-list">
          ${derivedFoundations.map(reference => buildFoundationTokenPill(reference.kind, reference.id, titleCaseToken(reference.kind))).join('')}
        </div>
      </div>
    ` : ''}
    ${buildCodeReferenceList(sourceEntries)}
  `;
}

function buildNormalizationCard(kind, item) {
  const hasNormalization = item?.normalizationHint || item?.canonicalToken || (item?.sameValuePeers || []).length;
  if (!hasNormalization) return '';

  const hintCopy = {
    alias: 'This token is an alias and should usually resolve through the canonical token below.',
    sharedValuePeer: 'This token currently shares a value with peers, but remains distinct in design intent.',
  }[item.normalizationHint] || 'This token includes normalization metadata.';

  return `
    <div class="foundation-meta-card foundation-meta-card-wide">
      <div class="foundation-meta-label">Normalization</div>
      <div class="foundation-meta-copy">${escapeHtml(hintCopy)}</div>
      <div class="dependency-group-list">
        ${item.normalizationHint ? `
          <div class="dependency-group">
            <div class="cc-related-label">Hint</div>
            <div class="usage-pill-list">
              <div class="usage-pill usage-pill-static">${escapeHtml(item.normalizationHint)}</div>
            </div>
          </div>
        ` : ''}
        ${item.canonicalToken ? `
          <div class="dependency-group">
            <div class="cc-related-label">Canonical Token</div>
            <div class="usage-pill-list">
              ${buildFoundationTokenPill(kind, item.canonicalToken, item.canonicalValue || '')}
            </div>
          </div>
        ` : ''}
        ${(item.sameValuePeers || []).length ? `
          <div class="dependency-group">
            <div class="cc-related-label">Same Value Peers</div>
            <div class="usage-pill-list">
              ${(item.sameValuePeers || []).map(peerId => buildFoundationTokenPill(kind, peerId)).join('')}
            </div>
          </div>
        ` : ''}
      </div>
    </div>
  `;
}

function renderUsageMeta(token, noun = 'usage') {
  const count = getDeclaredUsageCount(token);
  if (count) return `${count} declared ${noun}${count === 1 ? '' : 's'}`;
  return 'No declared usage';
}

function buildEmptyState(icon, title, subtitle = '', action = null) {
  const actionMarkup = action?.label && action?.onclick
    ? `<button class="empty-action" onclick="${action.onclick}">${escapeHtml(action.label)}</button>`
    : '';
  return `<div class="empty"><div class="empty-icon">${escapeHtml(icon)}</div><div class="empty-title">${escapeHtml(title)}</div>${subtitle ? `<div class="empty-sub">${escapeHtml(subtitle)}</div>` : ''}${actionMarkup}</div>`;
}

function normalizeComparableValue(value) {
  return String(value ?? '').trim().toLowerCase();
}

function matchesGlobalSearch(...values) {
  const query = normalizeComparableValue(window.globalSearchQuery || globalSearchQuery || '');
  if (!query) return true;
  return values.flatMap(value => Array.isArray(value) ? value : [value]).some(value => normalizeComparableValue(value).includes(query));
}

function componentSearchText(component) {
  return [
    component.id,
    component.name,
    component.group,
    component.description,
    component.source,
    component.swiftui,
    ...designSystemList(component, 'primitives', 'surfaces', 'textTones', 'icons', 'preferredIcons', 'gradients'),
  ];
}

function viewSearchText(view) {
  return [
    view.id,
    view.name,
    view.description,
    view.source,
    ...(view.components || []),
    ...designSystemList(view, 'primitives', 'surfaces', 'textTones', 'icons', 'preferredIcons', 'gradients'),
  ];
}

function tokenSearchText(id, token) {
  return [
    id,
    token.group,
    token.swiftui,
    token.usage,
    ...(token.colorTokens || []),
    ...(token.usedInGradients || []),
  ];
}

function iconSearchText(icon) {
  return [
    icon.id,
    icon.name,
    icon.symbol,
    icon.description,
    ...(icon.usedIn || []),
    ...(icon.usedInComponents || []),
    ...(icon.usedInViews || []),
  ];
}

function resolveTypographyId(token, index = 0) {
  return token?.id || token?.role || token?.swiftui || `typography-${index + 1}`;
}

function getTypographyEntries() {
  return (config?.tokens?.typography || []).map((token, index) => [resolveTypographyId(token, index), token]);
}

function getTypographyTokenById(id) {
  return getTypographyEntries().find(([entryId]) => entryId === id)?.[1] || null;
}

function typographySearchText(id, token) {
  return [
    id,
    token.role,
    token.swiftui,
    token.preview,
    token.weight,
    token.size,
  ];
}

function spacingSearchText(id, token) {
  return [
    id,
    token.value || token,
    token.usage,
    token.swiftui,
  ];
}

function getFilteredColorEntries() {
  const colors = config?.tokens?.colors || {};
  return Object.entries(colors).filter(([key, value]) => {
    const linked = getReferenceCount(value) > 0 || (Array.isArray(value.usedInGradients) && value.usedInGradients.length);
    const tokenFilter = pageFilterState?.tokens || 'all';
    if (tokenFilter === 'gradients') return false;
    if (tokenFilter === 'linked' && !linked) return false;
    return matchesGlobalSearch(...tokenSearchText(key, value), `tokens.colors.${key}`);
  });
}

function getFilteredGradientEntries() {
  const gradients = config?.tokens?.gradients || {};
  return Object.entries(gradients).filter(([key, value]) => {
    const linked = getReferenceCount(value) > 0
      || (Array.isArray(value.usedInComponents) && value.usedInComponents.length)
      || (Array.isArray(value.usedInViews) && value.usedInViews.length);
    const tokenFilter = pageFilterState?.tokens || 'all';
    if (tokenFilter === 'colors') return false;
    if (tokenFilter === 'linked' && !linked) return false;
    return matchesGlobalSearch(...tokenSearchText(key, value), `tokens.gradients.${key}`);
  });
}

function getFilteredIcons() {
  const filter = pageFilterState?.icons || 'all';
  return (config?.tokens?.icons || []).filter(icon => {
    if (filter === 'components' && !(icon.usedInComponents || []).length && !((icon.references?.design || []).some(reference => reference.type === 'component'))) return false;
    if (filter === 'views' && !(icon.usedInViews || []).length && !((icon.references?.design || []).some(reference => reference.type === 'view'))) return false;
    return matchesGlobalSearch(...iconSearchText(icon));
  });
}

function getComponentTruthStatus(component) {
  if (component?.snapshot?.path) {
    return {
      kind: 'reference',
      tag: 'Reference',
      label: 'Reference snapshot',
      summary: 'A standalone exported snapshot is available, so this preview has a 1:1 visual source of truth.',
      tone: 'good',
      needsAttention: false,
    };
  }
  if (isCatalogOnlyComponent(component)) {
    return {
      kind: 'catalog',
      tag: 'Catalog only',
      label: 'Catalog states',
      summary: 'This component is driven by declared app states, but it still lacks a standalone exported snapshot.',
      tone: 'caution',
      needsAttention: true,
    };
  }
  return {
    kind: 'approximation',
    tag: 'Approximation',
    label: 'Approximation only',
    summary: 'This preview is a best-effort approximation because no standalone snapshot was exported for the component.',
    tone: 'caution',
    needsAttention: true,
  };
}

function getViewTruthStatus(view) {
  if (view?.snapshot?.path) {
    return {
      kind: 'reference',
      tag: 'Reference',
      label: 'Reference snapshot',
      summary: 'A screen snapshot is available, so this view uses an exported visual source of truth.',
      tone: 'good',
      needsAttention: false,
    };
  }
  return {
    kind: 'approximation',
    tag: 'Approximation',
    label: 'Approximation only',
    summary: 'This screen is synthesized from config data because no exported snapshot exists yet.',
    tone: 'caution',
    needsAttention: true,
  };
}

function getComponentStatusSubtitle(component) {
  return [component?.group || null, getComponentTruthStatus(component).label].filter(Boolean).join(' · ');
}

function getViewStatusSubtitle(view) {
  return [
    view?.root || config?.navigation?.root === view?.id ? 'Root screen' : (view?.presentation === 'sheet' ? 'Sheet screen' : 'Screen'),
    getViewTruthStatus(view).label,
  ].filter(Boolean).join(' · ');
}

function buildPreviewStatusSummary(items, resolver, noun) {
  if (!items.length) return '';
  const counts = items.reduce((acc, item) => {
    const status = resolver(item);
    acc.total += 1;
    if (status.kind === 'reference') acc.reference += 1;
    if (status.kind === 'catalog') acc.catalog += 1;
    if (status.needsAttention) acc.attention += 1;
    return acc;
  }, { total: 0, reference: 0, catalog: 0, attention: 0 });

  const pills = [
    `<div class="coverage-pill"><strong>${counts.total}</strong><span>${escapeHtml(noun)}</span></div>`,
    `<div class="coverage-pill coverage-pill-good"><strong>${counts.reference}</strong><span>Reference</span></div>`,
    counts.catalog ? `<div class="coverage-pill coverage-pill-caution"><strong>${counts.catalog}</strong><span>Catalog only</span></div>` : '',
    counts.attention ? `<div class="coverage-pill coverage-pill-caution"><strong>${counts.attention}</strong><span>Needs attention</span></div>` : '',
  ].filter(Boolean).join('');

  return `<div class="coverage-summary">${pills}</div>`;
}

function getReviewQueueCounts() {
  const components = (config?.components || []).filter(component => getComponentTruthStatus(component).needsAttention);
  const views = (config?.views || []).filter(view => getViewTruthStatus(view).needsAttention);
  return {
    components: components.length,
    views: views.length,
    total: components.length + views.length,
  };
}

function getReviewQueueData() {
  const severityRank = status => status.kind === 'approximation' ? 0 : status.kind === 'catalog' ? 1 : 2;
  const components = (config?.components || [])
    .filter(component => getComponentTruthStatus(component).needsAttention)
    .sort((left, right) => {
      const severity = severityRank(getComponentTruthStatus(left)) - severityRank(getComponentTruthStatus(right));
      if (severity) return severity;
      const usageDiff = getComponentUsageViews(right).length - getComponentUsageViews(left).length;
      if (usageDiff) return usageDiff;
      return left.name.localeCompare(right.name);
    });

  const views = (config?.views || [])
    .filter(view => getViewTruthStatus(view).needsAttention)
    .sort((left, right) => {
      const navDiff = (right.navigatesTo || []).length - (left.navigatesTo || []).length;
      if (navDiff) return navDiff;
      return left.name.localeCompare(right.name);
    });

  return { components, views };
}

function buildReviewActionCard(type, item) {
  const truth = type === 'component' ? getComponentTruthStatus(item) : getViewTruthStatus(item);
  const collectionKey = type === 'component' ? 'review:component' : 'review:view';
  const countLabel = type === 'component'
    ? `${getComponentUsageViews(item).length} view${getComponentUsageViews(item).length === 1 ? '' : 's'}`
    : `${(item.navigatesTo || []).length} next step${(item.navigatesTo || []).length === 1 ? '' : 's'}`;
  const secondaryLabel = type === 'component'
    ? [item.group || null, countLabel].filter(Boolean).join(' · ')
    : [item.root || config?.navigation?.root === item.id ? 'Root screen' : 'Screen', countLabel].filter(Boolean).join(' · ');
  const nextStep = type === 'component'
    ? (truth.kind === 'catalog'
      ? 'Export a standalone component snapshot so the catalog states can be visually validated.'
      : 'Export a standalone component snapshot so this preview no longer relies on approximation.')
    : 'Export a screen snapshot so this view can use a visual source of truth.';

  return `
    <div class="review-card review-card-${escapeHtml(truth.tone)}">
      <div class="review-card-head">
        <div class="review-card-copy">
          <div class="review-card-title">${escapeHtml(item.name)}</div>
          <div class="review-card-subtitle">${escapeHtml(secondaryLabel)}</div>
        </div>
        <div class="review-card-badge">${escapeHtml(truth.label)}</div>
      </div>
      <div class="review-card-body">
        <div class="review-card-summary">${escapeHtml(truth.summary)}</div>
        <div class="review-card-next">${escapeHtml(nextStep)}</div>
      </div>
      <div class="review-card-actions">
        <button class="btn-sm" onclick="openInspectorPreview(${escapeHtml(escapeJsString(type))}, ${escapeHtml(escapeJsString(item.id))}, '', ${escapeHtml(escapeJsString(collectionKey))})">Preview</button>
        <button class="btn-sm" onclick="${type === 'component' ? `showComponentPage(${escapeHtml(escapeJsString(item.id))}, { collectionKey: ${escapeHtml(escapeJsString(collectionKey))} })` : `showViewPage(${escapeHtml(escapeJsString(item.id))}, { collectionKey: ${escapeHtml(escapeJsString(collectionKey))} })`}">Open detail</button>
      </div>
    </div>
  `;
}

function getFilteredComponents() {
  const filter = pageFilterState?.components || 'all';
  return (config?.components || []).filter(component => {
    const truth = getComponentTruthStatus(component);
    if (filter === 'attention' && !truth.needsAttention) return false;
    if (filter === 'used' && !getComponentUsageViews(component).length) return false;
    if (filter === 'catalog' && !isCatalogOnlyComponent(component)) return false;
    if (filter === 'snapshot' && !component.snapshot?.path) return false;
    return matchesGlobalSearch(...componentSearchText(component));
  });
}

function getFilteredViews() {
  const filter = pageFilterState?.views || 'all';
  return (config?.views || []).filter(view => {
    const truth = getViewTruthStatus(view);
    if (filter === 'attention' && !truth.needsAttention) return false;
    if (filter === 'root' && !view.root && config.navigation?.root !== view.id) return false;
    if (filter === 'snapshot' && !view.snapshot?.path) return false;
    if (filter === 'navigating' && !(view.navigatesTo || []).length) return false;
    return matchesGlobalSearch(...viewSearchText(view));
  });
}

function getFilteredTypographyEntries() {
  return getTypographyEntries().filter(([id, token]) => (
    matchesGlobalSearch(...typographySearchText(id, token))
  ));
}

function getFilteredSpacingEntries() {
  return Object.entries(config?.tokens?.spacing || {}).filter(([id, token]) => (
    matchesGlobalSearch(...spacingSearchText(id, token), `tokens.spacing.${id}`)
  ));
}

function getFilteredRadiusEntries() {
  return Object.entries(config?.tokens?.radius || {}).filter(([id, token]) => (
    matchesGlobalSearch(...spacingSearchText(id, token), `tokens.radius.${id}`)
  ));
}

function arraysEqualNormalized(a, b) {
  if (a.length !== b.length) return false;
  return a.every((value, index) => normalizeComparableValue(value) === normalizeComparableValue(b[index]));
}

function inferType(id) {
  if (id.includes('button') || id.includes('btn'))        return 'button';
  if (id.includes('badge'))                               return 'badge';
  if (id.includes('timer'))                               return 'timer';
  if (id.includes('difficulty') || id.includes('picker')) return 'difficulty-picker';
  if (id.includes('numpad'))                              return 'numpad';
  if (id.includes('list'))                               return 'list';
  if (id.includes('navbar') || id.includes('nav-bar'))    return 'navbar';
  if (id.includes('stat'))                               return 'stat-chips';
  if (id.includes('cell'))                               return 'cell-states';
  return 'button';
}

function renderComponentPreview(comp, props) {
  const type = comp.renderer || comp.type || inferType(comp.id);
  const disabled = props.disabled ? 'opacity:.4;pointer-events:none' : '';
  const componentName = (comp.name || '').toLowerCase();
  const componentId = String(comp.id || '').toLowerCase();

  switch (type) {
    case 'button': {
      if (componentName.includes('gamecontrolbutton') || componentId === 'game-control-button') {
        const isActive = Boolean(props.active);
        return `
          <div class="r-game-control${isActive ? ' r-game-control-active' : ''}" style="${disabled}">
            <div class="r-game-control-icon">${escapeHtml(symbolToGlyph(props.symbol || props.icon || 'sparkles'))}</div>
            <div class="r-game-control-title">${escapeHtml(props.title || 'Hint')}</div>
          </div>
        `;
      }
      const normalizedStyle = props.style || 'primary';
      const cls = {
        primary: 'r-btn-primary',
        secondary: 'r-btn-secondary',
        destructive: 'r-btn-destructive',
        blue: 'r-btn-blue',
        ghost: 'r-btn-ghost',
      }[normalizedStyle] || 'r-btn-primary';
      const icon = props.icon ? `<span class="r-btn-icon">${escapeHtml(props.icon)}</span>` : '';
      const buttonClass = componentName.includes('settingsactionbutton')
        ? `${cls} r-btn-wide r-btn-settings`
        : componentName.includes('startbutton')
          ? `${cls} r-btn-start${normalizedStyle === 'blue' ? ' r-btn-start-warm' : ''}${props.gradientVariant === 'warm' ? ' r-btn-start-warm' : ''}`
          : cls;
      return `<div class="${buttonClass}" style="${disabled}">${icon}<span>${escapeHtml(props.title || 'Button')}</span></div>`;
    }
    case 'badge': {
      const cls = {
        teal: 'r-badge-teal',
        surface: 'r-badge-surface',
        secondary: 'r-badge-surface',
        accent: 'r-badge-teal',
        blue: 'r-badge-blue',
        success: 'r-badge-success',
        gradient: 'r-badge-gradient',
      }[props.style || 'teal'] || 'r-badge-teal';
      return `<span class="${cls}">${escapeHtml(props.label||'Badge')}</span>`;
    }
    case 'timer':
      return `<div class="r-timer" style="color:${props.accent?'var(--accent)':'var(--t1)'}">${escapeHtml(props.value||'00:00')}</div>`;
    case 'difficulty-picker': {
      const options = props.options || ['Extra lehke', 'Lehke', 'Stredni', 'Tezke', 'Extra tezke'];
      const sel = props.selected ?? 2;
      const title = props.title || 'Difficulty';
      if (componentId === 'difficulty-picker-card' || componentName.includes('difficultypickercard')) {
        return `
          <div class="r-difficulty-card">
            <div class="r-difficulty-card-title">${escapeHtml(title)}</div>
            <div class="r-difficulty-card-panel">
              <div class="r-difficulty-options">
                ${options.map((o, i) => `<div class="r-difficulty-option${i === sel ? ' r-difficulty-option-selected' : ''}">${escapeHtml(o)}</div>`).join('')}
              </div>
            </div>
          </div>
        `;
      }
      return `
        <div class="r-panel-card r-diff-card">
          <div class="r-panel-title">${escapeHtml(title)}</div>
          <div class="r-diff-picker-shell">
            <div class="r-diff-picker">${options.map((o, i) => `<div class="r-diff-chip${i === sel ? ' r-sel' : ''}">${escapeHtml(o)}</div>`).join('')}</div>
          </div>
        </div>
      `;
    }
    case 'numpad': {
      const selNum = props.selected??5;
      const counts = props.counts || {};
      return `<div class="r-numpad">${[1,2,3,4,5,6,7,8,9].map(n=>{
        const count = Number(counts[n] ?? 0);
        const exhausted = count >= 9;
        return `<div class="r-num-btn${n===selNum?' r-sel':''}${exhausted?' r-disabled':''}${count > 0 && !exhausted ? ' r-used' : ''}"><span class="r-num-value">${n}</span></div>`;
      }).join('')}</div>`;
    }
    case 'list': {
      const rows = props.rows || [{ label: 'Item', value: 'Value' }];
      if (componentName.includes('settingslist') || componentId === 'settings-list') {
        return `
          <div class="r-settings-list">
            ${rows.map(r => `
              <div class="r-settings-row">
                <span class="r-settings-row-label">${escapeHtml(r.label)}</span>
                <span class="r-settings-row-right">
                  ${r.value ? `<span class="r-settings-row-value">${escapeHtml(r.value)}</span>` : ''}
                  ${r.rightType === 'checkmark' ? `<span class="r-settings-row-check">✓</span>` : r.rightType === 'empty' ? '' : `<span class="r-settings-row-chevron">›</span>`}
                </span>
              </div>
            `).join('')}
          </div>
        `;
      }
      return `
        <div class="r-list-shell">
          <div class="r-list-card">
            ${rows.map(r => `
              <div class="r-list-row">
                <div class="r-list-copy">
                  <span class="r-list-label">${escapeHtml(r.label)}</span>
                  ${r.caption || r.subtitle ? `<span class="r-list-caption">${escapeHtml(r.caption || r.subtitle)}</span>` : ''}
                </div>
                <span class="r-list-val">
                  ${r.badge ? `<span class="r-list-badge">${escapeHtml(r.badge)}</span>` : ''}
                  ${r.value ? `<span class="r-list-value-text">${escapeHtml(r.value)}</span>` : ''}
                  ${r.rightType === 'checkmark' ? `<span class="r-list-check">✓</span>` : r.rightType === 'empty' ? '' : `<span class="r-list-chevron">›</span>`}
                </span>
              </div>
            `).join('')}
          </div>
        </div>
      `;
    }
    case 'navbar': {
      const actions = props.actions||['🔖','⊞','⚙'];
      return `<div class="r-navbar"><div style="display:flex;align-items:center;gap:8px"><div class="r-circle">‹</div><span style="font-size:14px;font-weight:700">${escapeHtml(props.title||'Screen')}</span></div><div style="display:flex;gap:6px">${actions.map(a=>`<div class="r-circle" style="width:30px;height:30px;font-size:12px">${escapeHtml(a)}</div>`).join('')}</div></div>`;
    }
    case 'stat-chips': {
      const chips = props.chips||[{label:'Obtížnost',value:'Střední'},{label:'Čas',value:'00:06',accent:true}];
      if (componentId === 'puzzle-detail-meta' || componentName.includes('puzzledetail')) {
        return `
          <div class="r-puzzle-meta">
            ${chips.map(c => `
              <div class="r-puzzle-meta-badge${c.accent ? ' r-puzzle-meta-badge-accent' : ''}">
                <span class="r-puzzle-meta-label">${escapeHtml(c.label)}</span>
                <span class="r-puzzle-meta-value">${escapeHtml(c.value)}</span>
              </div>
            `).join('')}
          </div>
        `;
      }
      return `<div class="r-stat-row">${chips.map(c=>`<div class="r-stat-chip"><div class="r-stat-label">${escapeHtml(c.label)}</div><div class="r-stat-val" style="${c.accent?'color:var(--accent);font-family:var(--mono)':''}">${escapeHtml(c.value)}</div></div>`).join('')}</div>`;
    }
    case 'cell-states': {
      const cells=[
        {bg:'var(--surface2)',color:'var(--t2)',val:'2',label:'given'},
        {bg:'var(--surface2)',color:'var(--t1)',val:'7',label:'filled'},
        {bg:'var(--accent)',color:'#fff',val:'5',label:'selected'},
        {bg:'rgba(29,184,160,.18)',color:'var(--accent)',val:'5',label:'highlight',border:'1.5px solid var(--accent)'},
        {bg:'rgba(248,113,113,.18)',color:'var(--dest)',val:'3',label:'error',border:'1.5px solid var(--dest)'},
        {bg:'var(--surface2)',color:'transparent',val:'',label:'empty'},
      ];
      return `<div style="text-align:center"><div class="r-cell-row">${cells.map(c=>`<div style="text-align:center"><div class="r-cell" style="background:${c.bg};color:${c.color};${c.border?'border:'+c.border:''}">${c.val}</div><div style="font-size:9px;color:var(--t3);margin-top:3px">${c.label}</div></div>`).join('')}</div></div>`;
    }
    case 'action-card': {
      const tiles = props.tiles || props.buttons || [{ icon: '⌁', label: 'Camera' }, { icon: '▣', label: 'Gallery' }];
      const error = props.error;
      const success = props.success;
      const actions = props.actions || [];
      if (componentId === 'puzzle-import-card' || componentName.includes('puzzleimportcard')) {
        const resolveImportLabel = (label) => {
          if (label === 'Camera') return 'Scan with camera';
          if (label === 'Gallery') return 'Pick from Photos';
          return label;
        };
        return `
          <div class="r-import-card">
            <div class="r-import-copy">
              <div class="r-import-title">${escapeHtml(props.title || 'Import puzzle code')}</div>
              <div class="r-import-subtitle">${escapeHtml(props.subtitle || '')}</div>
            </div>
            <div class="r-import-tiles">
              ${tiles.map(tile => `
                <div class="r-scan-tile r-scan-tile-outline r-import-tile">
                  <div class="r-scan-tile-icon">${escapeHtml(symbolToGlyph(tile.icon))}</div>
                  <div class="r-scan-tile-title">${escapeHtml(resolveImportLabel(tile.label))}</div>
                </div>
              `).join('')}
            </div>
            ${error ? `
              <div class="r-inline-banner r-import-banner">
                <div class="r-inline-banner-icon">${escapeHtml(symbolToGlyph('exclamationmarkTriangleFill'))}</div>
                <div class="r-inline-banner-message">${escapeHtml(error)}</div>
              </div>
            ` : ''}
            ${success ? `
              <div class="r-import-success-wrap">
                <div class="r-success-card r-import-success">
                  <div class="r-success-icon">${escapeHtml(symbolToGlyph('checkmarkCircleFill'))}</div>
                  <div class="r-success-copy">
                    <div class="r-success-title">${escapeHtml(success.title || 'Puzzle loaded')}</div>
                    <div class="r-success-subtitle">${escapeHtml(success.subtitle || '')}</div>
                  </div>
                  <div class="r-success-spacer"></div>
                </div>
              </div>
            ` : ''}
            ${actions.length ? `
              <div class="r-import-actions">
                ${actions.map(action => {
                  const style = action.style || 'secondary';
                  const cls = style === 'primary' || style === 'filled'
                    ? 'r-btn-primary'
                    : style === 'destructive'
                      ? 'r-btn-destructive'
                      : 'r-btn-secondary';
                  return `<div class="${cls} r-btn-wide r-btn-settings r-import-action-btn">${escapeHtml(action.label)}</div>`;
                }).join('')}
              </div>
            ` : ''}
          </div>
        `;
      }
      return `
        <div class="r-action-card">
          <div class="r-action-head">
            <div class="r-action-title">${escapeHtml(props.title || 'Import puzzle code')}</div>
            <div class="r-action-sub">${escapeHtml(props.subtitle || '')}</div>
          </div>
          <div class="r-action-tiles">
            ${tiles.map(b => `
              <div class="r-action-tile">
                <span class="r-action-icon">${escapeHtml(b.icon)}</span>
                <span class="r-action-label">${escapeHtml(b.label === 'Camera' ? 'Scan with camera' : b.label === 'Gallery' ? 'Pick from Photos' : b.label)}</span>
              </div>
            `).join('')}
          </div>
          ${error ? `<div class="r-action-banner r-action-banner-error">${escapeHtml(error)}</div>` : ''}
          ${success ? `<div class="r-action-success"><div class="r-action-success-title">${escapeHtml(success.title)}</div><div class="r-action-success-sub">${escapeHtml(success.subtitle || '')}</div></div>` : ''}
          ${actions.length ? `<div class="r-action-footer">${actions.map(b => `<div class="r-action-cta${b.style === 'primary' || b.style === 'filled' ? ' primary' : ''}${b.style === 'destructive' ? ' destructive' : ''}${b.style === 'secondary' ? ' secondary' : ''}">${escapeHtml(b.label)}</div>`).join('')}</div>` : ''}
        </div>
      `;
    }
    case 'history-row': {
      return `
        <div class="r-history-row">
          <div class="r-history-status r-history-status-${escapeHtml(String(props.statusIcon || '').toLowerCase())}">${escapeHtml(symbolToGlyph(props.statusIcon))}</div>
          <div class="r-history-copy">
            <div class="r-history-title">${escapeHtml(props.title || 'Puzzle')}</div>
            <div class="r-history-subtitle">${escapeHtml(props.subtitle || '')}</div>
          </div>
          <div class="r-history-trailing">
            ${props.badge ? `<span class="r-history-badge">${escapeHtml(props.badge)}</span>` : ''}
            ${props.trailingIcon ? `<span class="r-history-chevron">${escapeHtml(symbolToGlyph(props.trailingIcon))}</span>` : ''}
          </div>
        </div>
      `;
    }
    case 'inline-banner': {
      return `
        <div class="r-inline-banner">
          <div class="r-inline-banner-icon">${escapeHtml(symbolToGlyph(props.icon))}</div>
          <div class="r-inline-banner-message">${escapeHtml(props.message || 'Message')}</div>
        </div>
      `;
    }
    case 'labeled-value': {
      return `
        <div class="r-labeled-value-card">
          <div class="r-labeled-value-title">${escapeHtml(props.title || 'Label')}</div>
          <div class="r-labeled-value-value">${escapeHtml(props.value || 'Value')}</div>
        </div>
      `;
    }
    case 'empty-state': {
      return `
        <div class="r-empty-state-card">
          <div class="r-empty-state-icon">${escapeHtml(symbolToGlyph(props.icon))}</div>
          <div class="r-empty-state-title">${escapeHtml(props.title || 'Empty state')}</div>
          <div class="r-empty-state-subtitle">${escapeHtml(props.subtitle || '')}</div>
        </div>
      `;
    }
    case 'success-card': {
      return `
        <div class="r-success-card">
          <div class="r-success-icon">${escapeHtml(symbolToGlyph(props.icon))}</div>
          <div class="r-success-copy">
            <div class="r-success-title">${escapeHtml(props.title || 'Success')}</div>
            <div class="r-success-subtitle">${escapeHtml(props.subtitle || '')}</div>
          </div>
          <div class="r-success-spacer"></div>
        </div>
      `;
    }
    case 'sheet': {
      if (componentId === 'hint-panel' || componentName.includes('hintpanelview') || props.level != null) {
        const level = Math.min(3, Math.max(0, Number(props.level ?? 0)));
        const hintCopy = [
          'Look at the center row first.',
          'Only one empty cell in the middle block can take a seven.',
          'Row 5 and column 5 eliminate every other option, so the answer here is 7.',
          'The answer here is 7.',
        ][level];
        return `
          <div class="r-sheet r-sheet-hint">
            <div class="r-sheet-icon r-sheet-icon-plain-accent">${escapeHtml(symbolToGlyph('sparkles'))}</div>
            <div class="r-sheet-title">Hint</div>
            <div class="r-sheet-message">${escapeHtml(hintCopy)}</div>
            ${level === 3 ? `<div class="r-sheet-answer"><span class="r-sheet-answer-value">7</span><span class="r-sheet-answer-copy">Final answer</span></div>` : ''}
            <div class="r-sheet-dots">${[0,1,2,3].map(index => `<span class="r-sheet-dot${index === level ? ' active' : ''}"></span>`).join('')}</div>
          </div>
        `;
      }

      if (componentId === 'game-feedback-sheet' || componentName.includes('gamefeedbacksheet') || props.kind) {
        const kind = String(props.kind || 'check');
        const feedback = {
          check: {
            icon: 'checkmarkCircle',
            title: 'Check',
            message: 'Two cells are currently conflicting. Fix them before you continue.',
            iconClass: 'r-sheet-icon-accent',
            action: '',
          },
          evaluation: {
            icon: 'checkmarkSealFill',
            title: 'Evaluation',
            message: 'Nice progress. The board is not solved yet, but there are no immediate conflicts.',
            iconClass: 'r-sheet-icon-plain-accent',
            action: '<div class="r-sheet-action">Close</div>',
          },
          hint: {
            icon: 'sparkles',
            title: 'Hint',
            message: 'Try stepping through the hint levels before revealing the final answer.',
            iconClass: 'r-sheet-icon-plain-accent',
            action: '<div class="r-sheet-action">Close</div>',
          },
        }[kind] || {
          icon: 'checkmarkCircle',
          title: 'Status',
          message: 'Current game feedback.',
          iconClass: 'r-sheet-icon-accent',
          action: '',
        };
        return `
          <div class="r-sheet r-sheet-feedback">
            <div class="r-sheet-icon ${feedback.iconClass}">${escapeHtml(symbolToGlyph(feedback.icon))}</div>
            <div class="r-sheet-title">${escapeHtml(feedback.title)}</div>
            <div class="r-sheet-message">${escapeHtml(feedback.message)}</div>
            ${feedback.action}
          </div>
        `;
      }

      return `<div class="r-sheet"><div class="r-sheet-title">${escapeHtml(props.title || comp.name || 'Sheet')}</div></div>`;
    }
    case 'tile-button':
    case 'tile-label': {
      const isButton = type === 'tile-button';
      const styleClass = `${props.style === 'outline' || !isButton ? ' r-scan-tile-outline' : ''}${isButton ? ' r-scan-tile-button' : ' r-scan-tile-label'}`;
      return `
        <div class="r-scan-tile${styleClass}">
          <div class="r-scan-tile-icon">${escapeHtml(symbolToGlyph(props.icon))}</div>
          <div class="r-scan-tile-title">${escapeHtml(props.title || 'Action')}</div>
        </div>
      `;
    }
    default:
      return `<div style="color:var(--t3);font-size:12px;font-family:var(--mono)">renderer: "${escapeHtml(type)}"<br>props: ${escapeHtml(JSON.stringify(props,null,1))}</div>`;
  }
}

function renderComponentInteractivePreview(comp) {
  const state = getComponentEditorState(comp);
  if (!state) return renderComponentPreview(comp, getDefaultMock(comp).props || {});

  let parsedProps = {};
  if (state.draft) {
    try {
      parsedProps = JSON.parse(state.draft);
    } catch {
      parsedProps = (getDefaultMock(comp).props || {});
    }
  }
  return renderComponentPreview(comp, parsedProps);
}

function buildGuidedControlField(component, control, currentProps) {
  const currentValue = getValueAtPath(currentProps, control.path);
  const options = control.options || [];
  const optionValues = options.map(value => ({ key: JSON.stringify(value), value }));
  const label = control.label || control.path;
  const sharedOnChange = `handleGuidedPropChange(${escapeJsString(component.id)}, ${escapeJsString(control.path)}, this.type === 'checkbox' ? String(this.checked) : this.value, ${escapeJsString(control.kind)})`;

  if (control.kind === 'boolean') {
    return `
      <label class="guided-field guided-field-toggle">
        <span class="guided-field-copy">
          <span class="guided-field-label">${escapeHtml(label)}</span>
          <span class="guided-field-hint">${escapeHtml(control.hint || 'Declared boolean state')}</span>
        </span>
        <input type="checkbox" class="guided-toggle" ${currentValue ? 'checked' : ''} onchange="${sharedOnChange}">
      </label>
    `;
  }

  if (control.kind === 'preset') {
    return `
      <label class="guided-field">
        <span class="guided-field-label">${escapeHtml(label)}</span>
        <select class="guided-select" onchange="handleGuidedPropChange(${escapeJsString(component.id)}, ${escapeJsString(control.path)}, this.value, 'preset')">
          ${options.map(option => {
            const valueKey = JSON.stringify(option.value);
            return `<option value="${escapeHtml(valueKey)}"${JSON.stringify(currentValue) === valueKey ? ' selected' : ''}>${escapeHtml(option.label || control.label || control.path)}</option>`;
          }).join('')}
        </select>
        <span class="guided-field-hint">${escapeHtml(control.hint || 'Structured preset from declared component states')}</span>
      </label>
    `;
  }

  if (optionValues.length > 1 && optionValues.length <= 8) {
    return `
      <label class="guided-field">
        <span class="guided-field-label">${escapeHtml(label)}</span>
        <select class="guided-select" onchange="${sharedOnChange}">
          ${optionValues.map(option => `<option value="${escapeHtml(String(option.value))}"${JSON.stringify(currentValue) === option.key ? ' selected' : ''}>${escapeHtml(String(option.value))}</option>`).join('')}
        </select>
        <span class="guided-field-hint">${escapeHtml(control.hint || 'Choose from values declared in the component states.')}</span>
      </label>
    `;
  }

  return `
    <label class="guided-field">
      <span class="guided-field-label">${escapeHtml(label)}</span>
      <input
        class="guided-input"
        type="${control.kind === 'number' ? 'number' : 'text'}"
        value="${escapeHtml(currentValue ?? '')}"
        onchange="${sharedOnChange}">
      <span class="guided-field-hint">${escapeHtml(control.hint || 'Edit this declared prop value.')}</span>
    </label>
  `;
}

function buildGuidedEditor(component) {
  const controls = getStructuredPropControls(component);
  if (!controls.length || isCatalogOnlyComponent(component)) return '';
  const currentProps = getDraftProps(component);
  return `
    <div class="cc-guided-panel">
      <div class="cc-editor-head">
        <span class="mock-label">Guided Controls</span>
        <span class="cc-guided-copy">Only declared values from the component catalog are offered here.</span>
      </div>
      <div class="guided-grid">
        ${controls.map(control => buildGuidedControlField(component, control, currentProps)).join('')}
      </div>
    </div>
  `;
}

function buildComponentPreviewStage(component, state, detailed) {
  const hasSnapshot = Boolean(component?.snapshot?.path);
  const shouldShowSnapshotOnly = hasSnapshot && (!detailed || state?.mode === 'snapshot');
  if (shouldShowSnapshotOnly) {
    return buildSnapshotPreview(component.snapshot, `${component.name} snapshot`, 'snapshot-frame component-snapshot-frame', detailed, !detailed);
  }

  const approximation = renderComponentInteractivePreview(component);
  if (detailed && hasSnapshot && state?.mode === 'mock') {
    return `
      <div class="cc-compare-stage">
        <div class="cc-compare-pane">
          <div class="cc-compare-label">Approximation</div>
          <div class="cc-compare-shell">${approximation}</div>
        </div>
        <div class="cc-compare-pane">
          <div class="cc-compare-label">Reference Snapshot</div>
          ${buildSnapshotPreview(component.snapshot, `${component.name} snapshot`, 'snapshot-frame component-snapshot-frame component-snapshot-frame-compare', true, false)}
        </div>
      </div>
    `;
  }

  if (!detailed) {
    return `<div class="cc-preview-approx cc-preview-approx-summary">${approximation}</div>`;
  }

  return approximation;
}

// ─── Page renderers ───────────────────────────────────────────────────────────

function renderTokens() {
  if (!config) return;
  const groups = {};
  getFilteredColorEntries().forEach(([k,v]) => {
    const g = v.group || 'Colors';
    if (!groups[g]) groups[g] = { colors: [], gradients: [] };
    groups[g].colors.push([k, v]);
  });
  getFilteredGradientEntries().forEach(([k, v]) => {
    const g = v.group || 'Gradients';
    if (!groups[g]) groups[g] = { colors: [], gradients: [] };
    groups[g].gradients.push([k, v]);
  });
  let html = '';
  Object.entries(groups).forEach(([grp, entries]) => {
    html += `<div class="subsection">${escapeHtml(grp)}</div><div class="token-grid">`;
    entries.colors.forEach(([k, v]) => {
      const dv=v.dark||v.value||v, lv=v.light||v.value||v;
      html += `<button class="swatch swatch-button" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(k))}, 'color')"><div class="swatch-block" style="background:${dv}"></div><div class="swatch-info"><div class="swatch-name">${escapeHtml(k)}</div><div class="swatch-token">tokens.colors.${escapeHtml(k)}</div></div></button>`;
    });
    entries.gradients.forEach(([k, v]) => {
      const darkStops = Array.isArray(v.dark) ? v.dark : (Array.isArray(v.value) ? v.value : []);
      const lightStops = Array.isArray(v.light) ? v.light : (Array.isArray(v.value) ? v.value : []);
      const previewStops = darkStops.length ? darkStops : lightStops;
      const gradientCss = previewStops.length ? `linear-gradient(135deg, ${previewStops.join(', ')})` : 'transparent';
      const direction = [v.startPoint, v.endPoint].filter(Boolean).join(' -> ') || 'custom';
      html += `<button class="swatch swatch-button gradient-swatch" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(k))}, 'gradient')"><div class="swatch-block" style="background:${gradientCss}"></div><div class="swatch-info"><div class="swatch-name">${escapeHtml(k)}</div><div class="swatch-token">tokens.gradients.${escapeHtml(k)}</div></div></button>`;
    });
    html += '</div>';
  });
  document.getElementById('tokensContent').innerHTML = html || buildEmptyState('◉', 'No matching tokens', 'Try clearing search or switching the token filter.', { label: 'Reset filters', onclick: "resetDiscoveryPage('tokens')" });
}

function renderTypography() {
  if (!config) return;
  const entries = getFilteredTypographyEntries();
  if (!entries.length) { document.getElementById('typographyContent').innerHTML = buildEmptyState('T', 'No type scale', 'Load a config with `tokens.typography` to inspect text styles.'); return; }
  document.getElementById('typographyContent').innerHTML = `
    <div class="foundation-list">
      ${entries.map(([id, t]) => `
        <button class="foundation-list-item" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(id))}, 'typography')">
          <div class="foundation-list-main">
            <div class="foundation-list-name">${escapeHtml(t.role || id)}</div>
            <div class="foundation-list-token">${escapeHtml(t.swiftui || 'Text style')} · ${escapeHtml(t.size)}pt / ${escapeHtml(t.weight)}</div>
          </div>
          <div class="foundation-list-preview" style="font-size:${Math.min(t.size, 26)}px;font-weight:${escapeHtml(t.weight)};${t.mono ? 'font-family:var(--mono);' : ''}${t.caps ? 'text-transform:uppercase;letter-spacing:1px;' : ''}${t.secondary ? 'color:var(--t2);' : ''}">
            ${escapeHtml(t.preview || t.role || id)}
          </div>
        </button>
      `).join('')}
    </div>
  `;
}

function renderIcons() {
  if (!config) return;
  const icons = getFilteredIcons();
  if (!icons.length) {
    document.getElementById('iconsContent').innerHTML = buildEmptyState('⌘', 'No matching icons', 'Try clearing search or switching the icon filter.', { label: 'Reset filters', onclick: "resetDiscoveryPage('icons')" });
    return;
  }
  document.getElementById('iconsContent').innerHTML = `
    <div class="icon-grid">
      ${icons.map(icon => `
        <button class="icon-card icon-card-button" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(icon.id || icon.name || icon.symbol))}, 'icon')">
          <div class="icon-preview">
            ${icon.path ? buildIconAssetPreview(icon) : `<div class="icon-preview-glyph">${escapeHtml((icon.symbol || '?').split('.').slice(0, 2).join('.'))}</div>`}
          </div>
          <div class="icon-name">${escapeHtml(icon.name || icon.id || 'Icon')}</div>
          <div class="icon-subtitle">${escapeHtml(icon.symbol || icon.description || '')}</div>
        </button>
      `).join('')}
    </div>
  `;
}

function renderFoundationDetail(kind, id, target = null) {
  if (!config) return;
  const titleEl = target?.titleEl || document.getElementById('foundationDetailTitle');
  const backBtn = target?.backBtn || document.getElementById('foundationBackBtn');
  const contentEl = target?.contentEl || document.getElementById('foundationDetailContent');
  if (!contentEl) return null;

  const colors = config.tokens?.colors || {};
  const gradients = config.tokens?.gradients || {};
  const icons = config.tokens?.icons || [];
  const typography = getTypographyTokenById(id);
  const spacing = config.tokens?.spacing || {};
  const radius = config.tokens?.radius || {};
  let item = null;
  let title = 'Foundation Detail';
  let sourcePage = 'tokens';

  if (kind === 'color') {
    item = colors[id];
    title = id;
    sourcePage = 'tokens';
  } else if (kind === 'gradient') {
    item = gradients[id];
    title = id;
    sourcePage = 'tokens';
  } else if (kind === 'icon') {
    item = icons.find(icon => (icon.id || icon.name || icon.symbol) === id);
    title = item?.name || item?.id || item?.symbol || id;
    sourcePage = 'icons';
  } else if (kind === 'typography') {
    item = typography;
    title = item?.role || id;
    sourcePage = 'typography';
  } else if (kind === 'spacing') {
    item = spacing[id];
    title = id;
    sourcePage = 'spacing';
  } else if (kind === 'radius') {
    item = radius[id];
    title = id;
    sourcePage = 'spacing';
  }

  if (backBtn) {
    backBtn.setAttribute('onclick', `showPage('${sourcePage}')`);
    backBtn.textContent = sourcePage === 'icons' ? '‹ Icons' : sourcePage === 'typography' ? '‹ Typography' : sourcePage === 'spacing' ? '‹ Spacing & Radius' : '‹ Tokens';
  }
  if (titleEl) titleEl.textContent = title;

  if (!item) {
    contentEl.innerHTML = buildEmptyState('◌', 'Detail not found', 'The selected foundation item is missing from the current config.');
    return { title, subtitle: 'Foundation item', sourcePage, openLabel: 'Open detail' };
  }

  const usages = getDeclaredUsageEntries(item);

  if (kind === 'icon') {
    const linked = getIconUsageEntities(id, item);
    const usageCount = getReferenceCount(item) || linked.components.length + linked.views.length;
    contentEl.innerHTML = `
      <div class="foundation-detail-layout">
        <div class="foundation-detail-stage">
          <div class="foundation-icon-stage">
            <div class="foundation-icon-canvas">
              ${item.path ? buildIconAssetPreview(item) : `<div class="icon-preview-glyph icon-preview-glyph-large">${escapeHtml(item.symbol || '?')}</div>`}
            </div>
          </div>
        </div>
        <div class="foundation-detail-meta">
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Type</div>
            <div class="foundation-meta-value">Icon</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Symbol</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(item.symbol || '-')}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Usage</div>
            <div class="foundation-meta-value">${usageCount} linked items</div>
          </div>
          ${buildNormalizationCard('icon', item)}
          ${item.description ? `<div class="foundation-meta-card foundation-meta-card-wide"><div class="foundation-meta-label">Notes</div><div class="foundation-meta-copy">${escapeHtml(item.description)}</div></div>` : ''}
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Components</div>
            ${buildUsagePills(linked.components, 'component')}
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Views</div>
            ${buildUsagePills(linked.views, 'view')}
          </div>
          ${buildTokenReferenceCards('icon', item)}
          ${item.references?.count ? '' : buildCodeReferenceList(usages)}
        </div>
      </div>
    `;
    return { title, subtitle: 'Icon detail', sourcePage, openLabel: 'Open icon detail' };
  }

  if (kind === 'color') {
    const dark = item.dark || item.value || item;
    const light = item.light || item.value || item;
    const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('foundation', 'color') : 'both';
    const impact = getColorImpactEntities(id, item);
    const usageCount = getReferenceCount(item) || impact.gradients.length + impact.components.length + impact.views.length;
    contentEl.innerHTML = `
      <div class="foundation-detail-layout">
        <div class="foundation-detail-stage">
          <div class="foundation-preview-stack">
            ${buildPreviewAppearanceToggle('foundation', 'color', 'preview-appearance-toolbar preview-appearance-toolbar-detail')}
            ${buildFoundationModeCompareLayout(appearance, {
              dark,
              light,
              sameValue: normalizeComparableValue(dark) === normalizeComparableValue(light),
              containerClass: 'foundation-mode-compare',
              singleClass: 'foundation-mode-compare-single',
              panelClass: 'foundation-mode-panel',
              labelClass: 'foundation-mode-label',
              stageClass: 'foundation-color-stage',
            })}
          </div>
        </div>
        <div class="foundation-detail-meta">
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Type</div>
            <div class="foundation-meta-value">Color Token</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Dark</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(dark)}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Light</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(light)}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Usage</div>
            <div class="foundation-meta-value">${usageCount} linked items</div>
          </div>
          ${buildNormalizationCard('color', item)}
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Indirectly Affects Gradients</div>
            ${buildFoundationPills(impact.gradients, 'gradient')}
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Indirectly Affects Components</div>
            ${buildUsagePills(impact.components, 'component')}
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Indirectly Affects Views</div>
            ${buildUsagePills(impact.views, 'view')}
          </div>
          ${buildTokenReferenceCards('color', item)}
        </div>
      </div>
    `;
    return { title, subtitle: 'Color detail', sourcePage, openLabel: 'Open color detail' };
  }

  if (kind === 'typography') {
    const previewText = item.preview || item.role || id;
    contentEl.innerHTML = `
      <div class="foundation-detail-layout">
        <div class="foundation-detail-stage">
          <div class="foundation-typography-stage foundation-typography-stage-large">
            <div class="foundation-typography-spec foundation-typography-spec-large">
              <div class="foundation-typography-spec-value">${escapeHtml(item.swiftui || item.role || 'Text style')}</div>
            </div>
            <div class="foundation-typography-sample-wrap foundation-typography-sample-wrap-large">
              <div class="foundation-typography-sample foundation-typography-sample-large" style="font-size:${escapeHtml(Math.min(Number(item.size) || 16, 44))}px;font-weight:${escapeHtml(item.weight || 600)};${item.mono ? 'font-family:var(--mono);' : ''}${item.caps ? 'text-transform:uppercase;letter-spacing:1px;' : ''}${item.secondary ? 'color:var(--t2);' : ''}">
                ${escapeHtml(previewText)}
              </div>
            </div>
          </div>
        </div>
        <div class="foundation-detail-meta">
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Type</div>
            <div class="foundation-meta-value">Typography</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">SwiftUI</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(item.swiftui || '-')}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Size</div>
            <div class="foundation-meta-value">${escapeHtml(item.size)}pt</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Weight</div>
            <div class="foundation-meta-value">${escapeHtml(item.weight || '-')}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Monospace</div>
            <div class="foundation-meta-value">${item.mono ? 'Yes' : 'No'}</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Uppercase</div>
            <div class="foundation-meta-value">${item.caps ? 'Yes' : 'No'}</div>
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Preview Text</div>
            <div class="foundation-meta-copy">${escapeHtml(previewText)}</div>
          </div>
        </div>
      </div>
  `;
    return { title, subtitle: 'Typography detail', sourcePage, openLabel: 'Open typography detail' };
  }

  if (kind === 'spacing') {
    const px = Number.parseInt(item.value || item, 10) || 0;
    const scale = px % 8 === 0 ? `${px / 8}× 8pt grid` : px % 4 === 0 ? `${px / 4}× 4pt step` : 'Custom spacing step';
    contentEl.innerHTML = `
      <div class="foundation-detail-layout foundation-detail-layout-metric">
        <div class="foundation-detail-stage">
          <div class="foundation-metric-stage foundation-metric-stage-large">
            <div class="foundation-metric-value foundation-metric-value-large">${escapeHtml(px)}px</div>
            <div class="foundation-spacing-bar" style="width:${Math.max(12, Math.min(px * 2.2, 320))}px"></div>
            <div class="foundation-metric-note">${escapeHtml(scale)}</div>
          </div>
        </div>
        <div class="foundation-detail-meta foundation-detail-meta-metric">
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Value</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(px)}px</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Scale</div>
            <div class="foundation-meta-copy">${escapeHtml(scale)}</div>
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Token Path</div>
            <div class="foundation-meta-value foundation-meta-mono">tokens.spacing.${escapeHtml(id)}</div>
          </div>
          ${item.usage ? `<div class="foundation-meta-card foundation-meta-card-wide"><div class="foundation-meta-label">Usage</div><div class="foundation-meta-copy">${escapeHtml(item.usage)}</div></div>` : ''}
        </div>
      </div>
    `;
    return { title, subtitle: 'Spacing detail', sourcePage, openLabel: 'Open spacing detail' };
  }

  if (kind === 'radius') {
    const px = Number.parseInt(item.value || item, 10) || 0;
    const softness = px <= 8 ? 'Subtle rounding' : px <= 16 ? 'Card rounding' : px <= 28 ? 'Strong rounding' : 'Pill / large rounding';
    contentEl.innerHTML = `
      <div class="foundation-detail-layout foundation-detail-layout-metric">
        <div class="foundation-detail-stage">
          <div class="foundation-metric-stage foundation-metric-stage-large">
            <div class="foundation-metric-value foundation-metric-value-large">${escapeHtml(px)}px</div>
            <div class="foundation-radius-showcase foundation-radius-showcase-large">
              <div class="foundation-radius-chip foundation-radius-chip-small" style="border-radius:${escapeHtml(px)}px"></div>
              <div class="foundation-radius-chip foundation-radius-chip-medium" style="border-radius:${escapeHtml(px)}px"></div>
              <div class="foundation-radius-chip foundation-radius-chip-large" style="border-radius:${escapeHtml(px)}px"></div>
            </div>
            <div class="foundation-metric-note">${escapeHtml(softness)}</div>
          </div>
        </div>
        <div class="foundation-detail-meta foundation-detail-meta-metric">
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Value</div>
            <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(px)}px</div>
          </div>
          <div class="foundation-meta-card">
            <div class="foundation-meta-label">Profile</div>
            <div class="foundation-meta-copy">${escapeHtml(softness)}</div>
          </div>
          <div class="foundation-meta-card foundation-meta-card-wide">
            <div class="foundation-meta-label">Token Path</div>
            <div class="foundation-meta-value foundation-meta-mono">tokens.radius.${escapeHtml(id)}</div>
          </div>
          ${item.usage ? `<div class="foundation-meta-card foundation-meta-card-wide"><div class="foundation-meta-label">Usage</div><div class="foundation-meta-copy">${escapeHtml(item.usage)}</div></div>` : ''}
        </div>
      </div>
    `;
    return { title, subtitle: 'Corner radius detail', sourcePage, openLabel: 'Open radius detail' };
  }

  const darkStops = Array.isArray(item.dark) ? item.dark : (Array.isArray(item.value) ? item.value : []);
  const lightStops = Array.isArray(item.light) ? item.light : (Array.isArray(item.value) ? item.value : []);
  const previewStops = darkStops.length ? darkStops : lightStops;
  const gradientCss = previewStops.length ? `linear-gradient(135deg, ${previewStops.join(', ')})` : 'transparent';
  const lightGradientCss = lightStops.length ? `linear-gradient(135deg, ${lightStops.join(', ')})` : gradientCss;
  const darkGradientCss = darkStops.length ? `linear-gradient(135deg, ${darkStops.join(', ')})` : gradientCss;
  const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('foundation', 'gradient') : 'both';
  const direction = [item.startPoint, item.endPoint].filter(Boolean).join(' -> ') || 'custom';
  const linked = getGradientUsageEntities(id, item);
  const linkedColors = getGradientColorTokens(id, item);
  const incomingColors = uniqueById(
    Object.entries(config?.tokens?.colors || {})
      .filter(([colorId, color]) => getColorGradientUsages(colorId, color).includes(id))
      .map(([colorId, color]) => ({ id: colorId, ...color }))
  );
  const usageCount = getReferenceCount(item) || linked.components.length + linked.views.length;
  contentEl.innerHTML = `
    <div class="foundation-detail-layout">
      <div class="foundation-detail-stage">
        <div class="foundation-preview-stack">
          ${buildPreviewAppearanceToggle('foundation', 'gradient', 'preview-appearance-toolbar preview-appearance-toolbar-detail')}
          ${buildFoundationModeCompareLayout(appearance, {
            dark: darkGradientCss,
            light: lightGradientCss,
            sameValue: arraysEqualNormalized(darkStops, lightStops) || normalizeComparableValue(darkGradientCss) === normalizeComparableValue(lightGradientCss),
            containerClass: 'foundation-mode-compare',
            singleClass: 'foundation-mode-compare-single',
            panelClass: 'foundation-mode-panel',
            labelClass: 'foundation-mode-label',
            stageClass: 'foundation-gradient-stage',
          })}
        </div>
      </div>
      <div class="foundation-detail-meta">
        <div class="foundation-meta-card">
          <div class="foundation-meta-label">Type</div>
          <div class="foundation-meta-value">${escapeHtml(item.type || 'linear')}</div>
        </div>
        <div class="foundation-meta-card">
          <div class="foundation-meta-label">Direction</div>
          <div class="foundation-meta-value foundation-meta-mono">${escapeHtml(direction)}</div>
        </div>
        <div class="foundation-meta-card">
          <div class="foundation-meta-label">Stops</div>
          <div class="foundation-meta-value">${previewStops.length}</div>
        </div>
        <div class="foundation-meta-card">
          <div class="foundation-meta-label">Usage</div>
          <div class="foundation-meta-value">${usageCount} linked items</div>
        </div>
        ${buildNormalizationCard('gradient', item)}
        <div class="foundation-meta-card foundation-meta-card-wide">
          <div class="foundation-meta-label">Reached From Colors</div>
          ${buildFoundationPills(incomingColors.length ? incomingColors : linkedColors, 'color')}
        </div>
        <div class="foundation-meta-card foundation-meta-card-wide">
          <div class="foundation-meta-label">Gradient Stops</div>
          <div class="foundation-stop-list">${previewStops.map(stop => `<div class="foundation-stop">${escapeHtml(stop)}</div>`).join('')}</div>
        </div>
        <div class="foundation-meta-card foundation-meta-card-wide">
          <div class="foundation-meta-label">Components</div>
          ${buildUsagePills(linked.components, 'component')}
        </div>
        <div class="foundation-meta-card foundation-meta-card-wide">
          <div class="foundation-meta-label">Views</div>
          ${buildUsagePills(linked.views, 'view')}
        </div>
        ${buildTokenReferenceCards('gradient', item)}
      </div>
    </div>
  `;
  return { title, subtitle: 'Gradient detail', sourcePage, openLabel: 'Open gradient detail' };
}

function renderSpacing() {
  if (!config) return;
  const spacing = getFilteredSpacingEntries();
  const radius = getFilteredRadiusEntries();
  let html = '';
  if (spacing.length) {
    html += '<div class="subsection">Spacing</div><div class="foundation-metric-grid">';
    spacing.forEach(([k,v]) => {
      const px = parseInt(v.value||v, 10) || 0;
      html += `
        <button class="foundation-metric-card" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(k))}, 'spacing')">
          <div class="foundation-metric-visual">
            <div class="foundation-spacing-bar" style="width:${Math.max(8, Math.min(px * 2, 140))}px"></div>
          </div>
          <div class="foundation-metric-name">${escapeHtml(k)}</div>
          <div class="foundation-metric-token">tokens.spacing.${escapeHtml(k)}</div>
        </button>
      `;
    });
    html += '</div>';
  }
  if (radius.length) {
    html += '<div class="subsection" style="margin-top:24px">Corner Radius</div><div class="foundation-metric-grid">';
    radius.forEach(([k,v]) => {
      const px = Number.parseInt(v.value||v, 10) || 0;
      html += `
        <button class="foundation-metric-card" onclick="openInspectorPreview('foundation', ${escapeHtml(escapeJsString(k))}, 'radius')">
          <div class="foundation-metric-visual">
            <div class="foundation-radius-shape" style="border-radius:${escapeHtml(px)}px"></div>
          </div>
          <div class="foundation-metric-name">${escapeHtml(k)}</div>
          <div class="foundation-metric-token">tokens.radius.${escapeHtml(k)}</div>
        </button>
      `;
    });
    html += '</div>';
  }
  document.getElementById('spacingContent').innerHTML = html || buildEmptyState('⬚', 'No spacing tokens', 'Load a config with `tokens.spacing` or `tokens.radius` to inspect layout primitives.');
}

function buildComponentCard(c, options = {}) {
  const detailed = Boolean(options.detailed);
  const mocks = getComponentStates(c);
  const state = getComponentEditorState(c);
  const selectedMockId = state?.selectedMockId || mocks[0]?.id || '';
  const catalogOnly = isCatalogOnlyComponent(c);
  const truth = getComponentTruthStatus(c);
  const previewBase = buildComponentPreviewStage(c, state, detailed);
  const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('component') : 'dark';
  const preview = detailed
    ? buildPreviewAppearancePanels(appearance, () => previewBase, { viewportClass: 'preview-appearance-viewport-detail' })
    : previewBase;
  const mockOpts = mocks.map(m=>`<option value="${escapeHtml(m.id)}"${m.id === selectedMockId ? ' selected' : ''}>${escapeHtml(m.label)}</option>`).join('');
  const compactSubtitle = getComponentStatusSubtitle(c);
  const detailControls = !detailed ? '' : `
    <div class="cc-mode-toggle">
      <div class="cc-mode-cluster">
        ${c.snapshot ? `<button class="cc-mode-btn${state?.mode === 'snapshot' ? ' active' : ''}" onclick="setComponentPreviewMode('${c.id}','snapshot')">Snapshot</button>` : ''}
        <button class="cc-mode-btn${state?.mode === 'mock' ? ' active' : ''}" onclick="setComponentPreviewMode('${c.id}','mock')">${catalogOnly ? 'State Preview' : 'Live Approximation'}</button>
      </div>
      ${buildPreviewAppearanceToggle('component', '', 'preview-appearance-toolbar preview-appearance-toolbar-detail')}
    </div>
  `;
  const stateMeta = detailed && mocks.length ? `
    <div class="cc-state-meta">
      ${mocks.find(m => m.id === selectedMockId)?.description ? `<div class="cc-state-copy">${escapeHtml(mocks.find(m => m.id === selectedMockId).description)}</div>` : ''}
      ${catalogOnly ? `<div class="cc-state-badge">Catalog only</div>` : ''}
    </div>
  ` : '';
  const approximationNote = detailed && c.snapshot && state?.mode === 'mock' ? `
    <div class="cc-approx-note">
      <div class="cc-approx-note-card">
        <div class="cc-approx-note-title">Reference Available</div>
        <div class="cc-approx-note-copy">This mode is an interactive approximation. Use <strong>Snapshot</strong> for the 1:1 visual source of truth.</div>
      </div>
    </div>
  ` : '';
  const usageViews = getComponentUsageViews(c);
  const siblingComponents = getSiblingComponents(c);
  const foundationGraph = getComponentFoundationGraph(c);
  const usageSummary = detailed && usageViews.length
    ? `<div class="cc-usage-summary">${usageViews.length} view${usageViews.length === 1 ? '' : 's'}</div>`
    : '';
  const usagePanel = !detailed ? '' : `
    <div class="cc-usage-panel">
      <div class="cc-usage-title">Used In Views</div>
      ${buildUsagePills(usageViews, 'view')}
    </div>
  `;
  const capabilityPanel = !detailed ? '' : `
    <div class="cc-capability-panel">
      <div class="cc-usage-title">Capabilities</div>
      <div class="cc-capability-card cc-capability-card-wide cc-capability-card-${escapeHtml(truth.tone)}">
        <div class="cc-capability-label">Preview Truth</div>
        <div class="cc-capability-value">${escapeHtml(truth.label)}</div>
        <div class="cc-capability-copy">${escapeHtml(truth.summary)}</div>
      </div>
      <div class="cc-capability-grid">
        <div class="cc-capability-card">
          <div class="cc-capability-label">Renderer</div>
          <div class="cc-capability-value">${escapeHtml(c.renderer || c.type || inferType(c.id))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Interaction</div>
          <div class="cc-capability-value">${escapeHtml(c.interactionMode || 'editable')}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Preview Modes</div>
          <div class="cc-capability-value">${escapeHtml(c.snapshot ? (catalogOnly ? 'snapshot + catalog' : 'snapshot + approximation') : (catalogOnly ? 'catalog only' : 'approximation only'))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Declared States</div>
          <div class="cc-capability-value">${escapeHtml(String(mocks.length))}</div>
        </div>
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">State IDs</div>
        ${buildTagList(mocks.map(mock => mock.id))}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Supported Props</div>
        ${buildTagList([...new Set(mocks.flatMap(mock => Object.keys(mock.props || {})))])}
      </div>
    </div>
  `;
  const relatedPanel = !detailed ? '' : `
    <div class="cc-related-panel">
      <div class="cc-usage-title">Related</div>
      <div class="cc-related-section">
        <div class="cc-related-label">Used With Components</div>
        ${buildUsagePills(siblingComponents, 'component')}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Colors</div>
        ${buildFoundationPills(foundationGraph.colors, 'color')}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Gradients</div>
        ${buildFoundationPills(foundationGraph.gradients, 'gradient')}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Icons</div>
        ${buildFoundationPills(foundationGraph.icons, 'icon')}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Primitives</div>
        ${buildTagList(foundationGraph.primitives)}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Surfaces</div>
        ${buildTagList(foundationGraph.surfaces)}
      </div>
      <div class="cc-related-section">
        <div class="cc-related-label">Text Tones</div>
        ${buildTagList(foundationGraph.textTones)}
      </div>
    </div>
  `;
  const dependencyPanel = !detailed ? '' : buildTokenDependencyPanel(c);
  const sourceFiles = uniqueStrings([
    c.source,
    ...usageViews.map(view => view.source),
  ]);
  const sourceSnippet = c.sourceSnippet || null;
  const sourceSnippetMeta = !sourceSnippet ? '' : [
    sourceSnippet.symbol || null,
    sourceSnippet.startLine && sourceSnippet.endLine
      ? `lines ${sourceSnippet.startLine}-${sourceSnippet.endLine}`
      : null,
    sourceSnippet.truncated ? 'excerpt trimmed' : null,
  ].filter(Boolean).join(' · ');
  const sourcePanel = !detailed || (!c.source && !c.swiftui && !sourceFiles.length && !sourceSnippet) ? '' : `
    <div class="cc-related-panel">
      <div class="cc-usage-title">Source</div>
      ${c.swiftui ? `
        <div class="cc-related-section">
          <div class="cc-related-label">SwiftUI API</div>
          <div class="cc-source-card">
            <div class="cc-source-code">${escapeHtml(c.swiftui)}</div>
          </div>
        </div>
      ` : ''}
      ${sourceSnippet ? `
        <div class="cc-related-section">
          <div class="cc-related-label">Source Excerpt</div>
          <div class="cc-source-card">
            ${sourceSnippetMeta ? `<div class="cc-source-meta">${escapeHtml(sourceSnippetMeta)}</div>` : ''}
            <pre class="cc-source-code">${escapeHtml(sourceSnippet.excerpt || '')}</pre>
          </div>
        </div>
      ` : ''}
      ${c.source ? `
        <div class="cc-related-section">
          <div class="cc-related-label">Component File</div>
          <div class="cc-source-card">
            <div class="cc-source-path">${escapeHtml(c.source)}</div>
          </div>
        </div>
      ` : ''}
      ${sourceFiles.length > 1 ? `
        <div class="cc-related-section">
          <div class="cc-related-label">Appears In View Files</div>
          <div class="cc-source-list">
            ${sourceFiles
              .filter(path => path !== c.source)
              .map(path => `<div class="cc-source-card"><div class="cc-source-path">${escapeHtml(path)}</div></div>`)
              .join('')}
          </div>
        </div>
      ` : ''}
    </div>
  `;
  const guidedEditor = !detailed ? '' : buildGuidedEditor(c);
  const editor = !detailed ? '' : catalogOnly ? `
    <div class="cc-editor cc-editor-locked">
      <div class="cc-editor-head">
        <span class="mock-label">Allowed States</span>
      </div>
      <div class="cc-locked-copy">This component uses a curated state catalog from the app. You can switch only between declared states.</div>
    </div>
  ` : `
    <div class="cc-editor">
      <div class="cc-editor-head">
        <span class="mock-label">Mock Props</span>
        <div class="cc-editor-actions">
          <button class="btn-sm" onclick="applyMockDraft('${c.id}')">Apply</button>
          <button class="btn-sm" onclick="resetMockDraft('${c.id}')">Reset</button>
        </div>
      </div>
      <textarea class="mock-editor" spellcheck="false" oninput="handleMockDraftChange('${c.id}', this.value)">${escapeHtml(state?.draft || JSON.stringify(mocks[0]?.props || {}, null, 2))}</textarea>
      ${state?.error ? `<div class="mock-error">${escapeHtml(state.error)}</div>` : ''}
    </div>
  `;
  const footer = detailed
    ? `<div class="cc-footer"><span class="mock-label">${catalogOnly ? 'State' : 'Mock'}</span><select class="mock-select" id="mock-sel-${c.id}" onchange="handleMockSelection('${c.id}', this.value)">${mockOpts||'<option>—</option>'}</select></div>`
    : '';
  const availableTabs = [
    { id: 'preview', label: 'Preview', content: `${detailControls}${approximationNote}${footer}${stateMeta}${guidedEditor}${editor}` },
    { id: 'relationships', label: 'Relationships', content: `${usagePanel}${relatedPanel}${dependencyPanel}` },
    { id: 'contract', label: 'Contract', content: capabilityPanel },
    { id: 'source', label: 'Source', content: sourcePanel },
  ].filter(tab => tab.content && tab.content.trim());
  const activeDetailTab = detailed
    ? ((availableTabs.find(tab => tab.id === state?.detailTab)?.id) || availableTabs[0]?.id || 'preview')
    : 'preview';
  if (detailed && state && state.detailTab !== activeDetailTab) {
    state.detailTab = activeDetailTab;
  }
  const header = detailed
    ? `<div class="cc-header cc-header-detail">
        <div class="cc-head-row">
          <div class="cc-head-tags">
            ${c.group ? `<span class="cc-head-tag">${escapeHtml(c.group)}</span>` : ''}
            <span class="cc-head-tag">${escapeHtml(truth.label)}</span>
            <span class="cc-head-tag">${escapeHtml(c.renderer || c.type || inferType(c.id))}</span>
          </div>
          ${usageSummary}
        </div>
      </div>`
    : `<div class="cc-header cc-header-compact"><div class="cc-name">${escapeHtml(c.name)}</div>${compactSubtitle ? `<div class="cc-summary-subtitle">${escapeHtml(compactSubtitle)}</div>` : ''}</div>`;
  if (!detailed) {
    return `<div class="component-card component-card-summary" id="component-card-${c.id}" role="button" tabindex="0" onclick="openInspectorPreview('component', ${escapeHtml(escapeJsString(c.id))})" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openInspectorPreview('component', ${escapeHtml(escapeJsString(c.id))})}">${header}<div class="cc-preview" id="preview-${c.id}">${preview}</div></div>`;
  }
  const tabButtons = availableTabs.map(tab => `<button class="cc-detail-tab${tab.id === activeDetailTab ? ' active' : ''}" onclick="setComponentDetailTab('${c.id}', '${tab.id}')">${escapeHtml(tab.label)}</button>`).join('');
  const activeTabContent = availableTabs.find(tab => tab.id === activeDetailTab)?.content || '';
  return `<div class="component-card component-card-detail" id="component-card-${c.id}">${header}<div class="cc-detail-shell"><div class="cc-preview-shell"><div class="cc-preview" id="preview-${c.id}">${preview}</div></div><div class="cc-detail-body"><div class="cc-detail-tabs">${tabButtons}</div><div class="cc-detail-content">${activeTabContent}</div></div></div></div>`;
}

function renderComponents() {
  if (!config) return;
  const comps = getFilteredComponents();
  if (!comps.length) { document.getElementById('componentsContent').innerHTML = buildEmptyState('⬡', 'No matching components', 'Try clearing search or switching the component filter.', { label: 'Reset filters', onclick: "resetDiscoveryPage('components')" }); return; }
  document.getElementById('componentsContent').innerHTML = `${buildPreviewStatusSummary(comps, getComponentTruthStatus, 'components')}<div class="component-grid">${comps.map(c=>buildComponentCard(c)).join('')}</div>`;
}

function updateMockPreview(compId, mockId) {
  const comp = (config?.components||[]).find(c=>c.id===compId);
  if (!comp) return;
  const mock = getComponentStates(comp).find(m=>m.id===mockId);
  const el = document.getElementById('preview-'+compId);
  if (el) el.innerHTML = renderComponentPreview(comp, mock?.props||{});
}

function buildMiniScreen(view) {
  if (view.snapshot?.path) {
    return buildSnapshotPreview(view.snapshot, `${view.name} snapshot`, 'snapshot-frame view-snapshot-frame', false, true);
  }
  const style = view.presentation==='sheet'
    ? 'width:75px;max-height:170px;background:var(--surface);border-radius:10px 10px 6px 6px;border:1px solid var(--border);overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.3)'
    : 'width:75px;height:140px;background:var(--surface);border-radius:10px;border:1px solid var(--border);overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.3)';
  let inner = `<div style="height:22px;background:var(--bg);display:flex;align-items:center;justify-content:center;border-bottom:1px solid var(--border2)"><span style="font-size:7px;font-weight:700;color:var(--t1)">${escapeHtml(view.name)}</span></div>`;
  (view.components||[]).slice(0,3).forEach(()=>{ inner+=`<div style="margin:4px 4px 0;height:14px;background:var(--surface2);border-radius:3px;opacity:.7"></div>`; });
  if ((view.navigatesTo||[]).length) inner+=`<div style="margin:6px 4px 4px;height:18px;background:var(--accent);border-radius:5px;opacity:.8;display:flex;align-items:center;justify-content:center"><span style="font-size:7px;font-weight:700;color:#fff">${escapeHtml((view.navigatesTo || []).length)} link${(view.navigatesTo || []).length === 1 ? '' : 's'}</span></div>`;
  return `<div style="${style}">${inner}</div>`;
}

function renderViews() {
  if (!config) return;
  const views = getFilteredViews();
  if (!views.length) { document.getElementById('viewsContent').innerHTML = buildEmptyState('▭', 'No matching views', 'Try clearing search or switching the view filter.', { label: 'Reset filters', onclick: "resetDiscoveryPage('views')" }); return; }
  let html = `${buildPreviewStatusSummary(views, getViewTruthStatus, 'views')}<div class="view-grid">`;
  views.forEach(v => {
    html+=`<div class="view-card" role="button" tabindex="0" onclick="openInspectorPreview('view', ${escapeHtml(escapeJsString(v.id))})" onkeydown="if(event.key==='Enter'||event.key===' '){event.preventDefault();openInspectorPreview('view', ${escapeHtml(escapeJsString(v.id))})}"><div class="vc-screen">${buildMiniScreen(v)}</div><div class="vc-info"><div class="vc-name">${escapeHtml(v.name)}</div><div class="vc-summary-subtitle">${escapeHtml(getViewStatusSubtitle(v))}</div></div></div>`;
  });
  document.getElementById('viewsContent').innerHTML = html + '</div>';
}

function renderReview() {
  if (!config) return;
  const { components, views } = getReviewQueueData();
  const counts = getReviewQueueCounts();
  const contentEl = document.getElementById('reviewContent');
  if (!contentEl) return;
  if (!counts.total) {
    contentEl.innerHTML = buildEmptyState('✓', 'Nothing needs review', 'All current views and components are backed by exported truth the inspector understands.');
    return;
  }

  contentEl.innerHTML = `
    ${buildPreviewStatusSummary([
      ...components.map(component => ({ kind: 'component', ...component })),
      ...views.map(view => ({ kind: 'view', ...view })),
    ], item => item.kind === 'component' ? getComponentTruthStatus(item) : getViewTruthStatus(item), 'items')}
    ${components.length ? `
      <div class="subsection">Components Needing Review</div>
      <div class="review-grid">
        ${components.map(component => buildReviewActionCard('component', component)).join('')}
      </div>
    ` : ''}
    ${views.length ? `
      <div class="subsection" style="margin-top:24px">Views Needing Review</div>
      <div class="review-grid">
        ${views.map(view => buildReviewActionCard('view', view)).join('')}
      </div>
    ` : ''}
  `;
}

function renderViewDetail(viewId, target = null) {
  const view = (config?.views||[]).find(v=>v.id===viewId);
  if (!view) return null;
  const truth = getViewTruthStatus(view);
  const appearance = typeof getPreviewAppearance === 'function' ? getPreviewAppearance('view') : 'dark';
  if (!target?.preview) currentViewDetailId = viewId;
  const state = getViewDetailState(view);
  const titleEl = target?.titleEl || document.getElementById('vdTitle');
  const contentEl = target?.contentEl || document.getElementById('viewDetailContent');
  if (titleEl) titleEl.textContent = view.name;
  if (!target?.preview) syncViewDetailContextNav(view);
  if (!contentEl) return null;
  let phoneContent = '';
  const snapshotMarkup = view.snapshot?.path ? buildSnapshotPreview(view.snapshot, `${view.name} snapshot`, 'snapshot-frame detail-snapshot-frame') : '';
  if (view.navbar) {
    const nb = view.navbar;
    phoneContent+=`<div class="phone-navbar">${nb.back?`<div class="phone-btn">‹</div>`:'<div style="width:28px"></div>'}<div class="phone-title">${nb.title||view.name}</div><div style="display:flex;gap:4px">${(nb.actions||[]).map(a=>`<div class="phone-btn" style="font-size:10px">${a}</div>`).join('')}</div></div>`;
  }
  phoneContent += '<div class="phone-content">';
  (view.components||[]).forEach(cid => {
    const comp=(config?.components||[]).find(c=>c.id===cid);
    phoneContent+=comp?`<div style="margin-bottom:8px">${renderComponentPreview(comp, getDefaultMock(comp).props || {})}</div>`:`<div style="height:24px;background:var(--surface2);border-radius:5px;margin-bottom:6px;opacity:.5"></div>`;
  });
  phoneContent += '</div>';
  const compPills=(view.components||[]).map(cid=>{ const comp=(config?.components||[]).find(c=>c.id===cid); return `<div class="vd-comp-pill" onclick="openInspectorPreview('component', ${escapeHtml(escapeJsString(cid))})">${escapeHtml(comp?comp.name:cid)}<span style="font-size:10px;color:var(--t3)">›</span></div>`; }).join('');
  const navArrows=(view.navigatesTo||[]).map(n=>{
    const targetView = getViewById(n.viewId);
    return `<div class="nav-arrow" onclick="openInspectorPreview('view', ${escapeHtml(escapeJsString(n.viewId))})">${buildNavigationCard(targetView ? targetView.name : n.viewId, n.type || 'push', n.trigger, 'outgoing')}</div>`;
  }).join('');
  const incomingViews = getIncomingViewTransitions(view.id);
  const incomingArrows = incomingViews.map(entry => {
    const sourceView = entry.sourceView;
    const transition = entry.transition || {};
    return `<div class="nav-arrow" onclick="openInspectorPreview('view', ${escapeHtml(escapeJsString(sourceView.id))})">${buildNavigationCard(sourceView.name, transition.type || 'push', transition.trigger, 'incoming')}</div>`;
  }).join('');
  const navigationPath = getNavigationPath(view.id).map(id => getViewById(id)?.name || id);
  const routeSummary = navigationPath.length
    ? `<div class="vd-route">${navigationPath.map(step => `<span class="vd-route-step">${escapeHtml(step)}</span>`).join('<span class="vd-route-sep">›</span>')}</div>`
    : '<div class="foundation-empty-note">No route from root was derived for this view.</div>';
  const flowMeta = `
    <div class="vd-panel">
      <div class="vd-panel-title">Navigation Context</div>
      <div class="vd-graph-section">
        <div class="vd-graph-label">Route Path</div>
        ${routeSummary}
      </div>
      <div class="vd-graph-section">
        <div class="vd-graph-label">Role</div>
        <div class="usage-pill-list">
          ${view.root ? '<div class="usage-pill usage-pill-static">Root</div>' : ''}
          ${view.presentation ? `<div class="usage-pill usage-pill-static">${escapeHtml(view.presentation)}</div>` : '<div class="usage-pill usage-pill-static">push</div>'}
          <div class="usage-pill usage-pill-static">${escapeHtml((view.navigatesTo || []).length)} next steps</div>
          <div class="usage-pill usage-pill-static">${escapeHtml(incomingViews.length)} ways in</div>
        </div>
      </div>
    </div>
  `;
  const linkedComponents = (view.components || []).map(getComponentById).filter(Boolean);
  const linkedIcons = uniqueById(
    (config?.tokens?.icons || []).filter(icon => {
      const inView = (icon.usedInViews || []).includes(view.id);
      const inComponents = linkedComponents.some(component => (icon.usedInComponents || []).includes(component.id));
      return inView || inComponents;
    })
  );
  const linkedGradients = uniqueById(
    Object.entries(config?.tokens?.gradients || {})
      .filter(([, gradient]) => (gradient.usedInViews || []).includes(view.id) || linkedComponents.some(component => (gradient.usedInComponents || []).includes(component.id)))
      .map(([gradientId, gradient]) => ({ id: gradientId, ...gradient }))
  );
  const linkedColors = uniqueById(linkedGradients.flatMap(gradient => getGradientColorTokens(gradient.id, gradient)));
  const primitiveTags = uniqueById(linkedComponents.flatMap(component => designSystemList(component, 'primitives')).map(value => ({ id: value }))).map(item => item.id);
  const surfaceTags = uniqueById([
    ...designSystemList(view, 'surfaces'),
    ...linkedComponents.flatMap(component => designSystemList(component, 'surfaces')),
  ].map(value => ({ id: value }))).map(item => item.id);
  const textToneTags = uniqueById([
    ...designSystemList(view, 'textTones'),
    ...linkedComponents.flatMap(component => designSystemList(component, 'textTones')),
  ].map(value => ({ id: value }))).map(item => item.id);
  const sourceSnippet = view.sourceSnippet || null;
  const sourceSnippetMeta = !sourceSnippet ? '' : [
    sourceSnippet.symbol || null,
    sourceSnippet.startLine && sourceSnippet.endLine ? `lines ${sourceSnippet.startLine}-${sourceSnippet.endLine}` : null,
    sourceSnippet.truncated ? 'excerpt trimmed' : null,
  ].filter(Boolean).join(' · ');
  const viewSourcePanel = (!view.source && !sourceSnippet) ? '' : `
    <div class="vd-panel">
      <div class="vd-panel-title">Source</div>
      ${sourceSnippet ? `
        <div class="cc-related-section">
          <div class="cc-related-label">Source Excerpt</div>
          <div class="cc-source-card">
            ${sourceSnippetMeta ? `<div class="cc-source-meta">${escapeHtml(sourceSnippetMeta)}</div>` : ''}
            <pre class="cc-source-code">${escapeHtml(sourceSnippet.excerpt || '')}</pre>
          </div>
        </div>
      ` : ''}
      ${view.source ? `
        <div class="cc-related-section">
          <div class="cc-related-label">View File</div>
          <div class="cc-source-card">
            <div class="cc-source-path">${escapeHtml(view.source)}</div>
          </div>
        </div>
      ` : ''}
    </div>
  `;
  const dependencyPanel = view.tokenDependencies ? `
    <div class="vd-panel">
      <div class="vd-panel-title">Token Dependencies</div>
      <div class="cc-capability-grid">
        <div class="cc-capability-card">
          <div class="cc-capability-label">Declared Tokens</div>
          <div class="cc-capability-value">${escapeHtml(String(view.tokenDependencies?.summary?.designTokenCount || 0))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Observed Tokens</div>
          <div class="cc-capability-value">${escapeHtml(String(view.tokenDependencies?.summary?.sourceTokenCount || 0))}</div>
        </div>
        <div class="cc-capability-card">
          <div class="cc-capability-label">Categories</div>
          <div class="cc-capability-value">${escapeHtml(String((view.tokenDependencies?.summary?.categories || []).length))}</div>
        </div>
      </div>
      <div class="vd-graph-section">
        <div class="vd-graph-label">Declared Design Tokens</div>
        ${buildTokenDependencySections(view.tokenDependencies.design || {}, false)}
      </div>
      <div class="vd-graph-section">
        <div class="vd-graph-label">Observed Source Tokens</div>
        ${buildTokenDependencySections(view.tokenDependencies.source || {}, true)}
      </div>
    </div>
  ` : '';
  const screenMarkup = snapshotMarkup || `<div class="vd-phone"><div class="vd-notch">9:41 AM</div><div class="vd-body">${phoneContent}</div></div>`;
  const previewStageMarkup = `
    <div class="vd-stage-toolbar">
      ${buildPreviewAppearanceToggle('view', '', 'preview-appearance-toolbar preview-appearance-toolbar-detail')}
    </div>
    ${buildPreviewAppearancePanels(appearance, () => screenMarkup, { viewportClass: 'preview-appearance-viewport-detail' })}
  `;
  const configPanel = `
    <div class="vd-panel">
      <div class="vd-panel-title">Config</div>
      <div class="vd-detail-kv-list">
        <div class="vd-detail-kv"><span>ID</span><strong>${escapeHtml(view.id)}</strong></div>
        ${view.snapshot?.path ? `<div class="vd-detail-kv"><span>Snapshot</span><strong>${escapeHtml(view.snapshot.name || view.snapshot.path.split('/').pop())}</strong></div>` : ''}
        <div class="vd-detail-kv"><span>Presentation</span><strong>${escapeHtml(view.presentation || 'push')}</strong></div>
        <div class="vd-detail-kv"><span>Role</span><strong>${view.root ? 'Root' : 'Standard'}</strong></div>
      </div>
    </div>
  `;
  const truthPanel = `
    <div class="vd-panel">
      <div class="vd-panel-title">Preview Truth</div>
      <div class="coverage-pill coverage-pill-${escapeHtml(truth.tone)} coverage-pill-block">
        <strong>${escapeHtml(truth.label)}</strong>
        <span>${escapeHtml(truth.summary)}</span>
      </div>
    </div>
  `;
  const designGraphPanel = `
    <div class="vd-panel">
      <div class="vd-panel-title">Design Graph</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Colors</div>${buildFoundationPills(linkedColors, 'color')}</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Gradients</div>${buildFoundationPills(linkedGradients, 'gradient')}</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Icons</div>${buildFoundationPills(linkedIcons, 'icon')}</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Primitives</div>${buildTagList(primitiveTags)}</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Surfaces</div>${buildTagList(surfaceTags)}</div>
      <div class="vd-graph-section"><div class="vd-graph-label">Text Tones</div>${buildTagList(textToneTags)}</div>
    </div>
  `;
  const previewTab = `
    ${truthPanel}
    ${compPills?`<div class="vd-panel"><div class="vd-panel-title">Components</div>${compPills}</div>`:''}
    ${view.description?`<div class="vd-panel"><div class="vd-panel-title">Notes</div><div class="vd-body-copy">${escapeHtml(view.description)}</div></div>`:''}
    ${configPanel}
  `;
  const flowTab = `
    ${flowMeta}
    ${incomingArrows?`<div class="vd-panel"><div class="vd-panel-title">How Users Get Here</div>${incomingArrows}</div>`:''}
    ${navArrows?`<div class="vd-panel"><div class="vd-panel-title">What Users Can Do Next</div>${navArrows}</div>`:''}
  `;
  const designTab = `
    ${designGraphPanel}
    ${dependencyPanel}
  `;
  const sourceTab = `
    ${viewSourcePanel || `<div class="vd-panel"><div class="vd-panel-title">Source</div><div class="foundation-empty-note">No source metadata is available for this view yet.</div></div>`}
    ${configPanel}
  `;
  const availableTabs = [
    { id: 'preview', label: 'Preview', content: previewTab },
    { id: 'flow', label: 'Flow', content: flowTab },
    { id: 'design', label: 'Design', content: designTab },
    { id: 'source', label: 'Source', content: sourceTab },
  ].filter(tab => tab.content && tab.content.trim());
  const activeDetailTab = ((availableTabs.find(tab => tab.id === state?.detailTab)?.id) || availableTabs[0]?.id || 'preview');
  if (state && state.detailTab !== activeDetailTab) {
    state.detailTab = activeDetailTab;
  }
  const tabButtons = availableTabs.map(tab => `<button class="vd-detail-tab${tab.id === activeDetailTab ? ' active' : ''}" onclick="setViewDetailTab('${view.id}', '${tab.id}')">${escapeHtml(tab.label)}</button>`).join('');
  const activeTabContent = availableTabs.find(tab => tab.id === activeDetailTab)?.content || '';
  contentEl.innerHTML=`<div class="view-detail active"><div class="vd-stage">${previewStageMarkup}</div><div class="vd-detail-body"><div class="vd-detail-tabs">${tabButtons}</div><div class="vd-detail-content">${activeTabContent}</div></div></div>`;
  return { title: view.name, subtitle: getViewStatusSubtitle(view), openLabel: 'Open view detail' };
}

function renderNavMap() {
  if (!config) return;
  const views = config.views || [];
  if (!views.length) { document.getElementById('navMapContainer').innerHTML = buildEmptyState('⬡', 'No views defined', 'Load a config with `views[]` to generate the navigation map.'); return; }
  const nodeW = 208;
  const nodeH = 82;
  const marginX = 68;
  const marginY = 60;
  const colGap = 152;
  const rowGap = 30;
  const rootId = config.navigation?.root || views.find(v => v.root)?.id || views[0].id;
  const viewById = Object.fromEntries(views.map(view => [view.id, view]));
  const forwardEdgesByView = {};
  const incomingForward = {};
  const popTargets = {};
  const auxiliaryTransitions = {};
  views.forEach(view => {
    forwardEdgesByView[view.id] = [];
    incomingForward[view.id] = [];
    popTargets[view.id] = [];
    auxiliaryTransitions[view.id] = [];
  });
  const depths = {};
  depths[rootId] = 0;
  const queue = [rootId];
  while (queue.length) {
    const currentId = queue.shift();
    const currentDepth = depths[currentId];
    (viewById[currentId]?.navigatesTo || []).forEach(edge => {
      if (!edge?.viewId || !viewById[edge.viewId] || edge.type === 'pop') return;
      if (!edge?.viewId || depths[edge.viewId] !== undefined) return;
      depths[edge.viewId] = currentDepth + 1;
      queue.push(edge.viewId);
    });
  }
  views.forEach(view => {
    if (depths[view.id] === undefined) depths[view.id] = Object.keys(depths).length ? Math.max(...Object.values(depths)) + 1 : 0;
  });
  views.forEach(view => {
    (view.navigatesTo || []).forEach(edge => {
      if (!edge?.viewId || !viewById[edge.viewId]) return;
      if (edge.type === 'pop') {
        popTargets[view.id].push(edge.viewId);
        auxiliaryTransitions[view.id].push(edge);
        return;
      }
      const delta = depths[edge.viewId] - depths[view.id];
      const isPrimary = delta === 1 && (edge.type === 'push' || edge.type === 'sheet');
      if (isPrimary) {
        forwardEdgesByView[view.id].push(edge);
        incomingForward[edge.viewId].push(view.id);
      } else {
        auxiliaryTransitions[view.id].push(edge);
      }
    });
  });
  const maxDepth = Math.max(...Object.values(depths));
  const sectionNameFor = view => view.section || (view.presentation === 'sheet' ? 'Sheets' : 'General');
  const sectionOrder = [];
  views.forEach(view => {
    const section = sectionNameFor(view);
    if (!sectionOrder.includes(section)) sectionOrder.push(section);
  });
  const levels = {};
  views.forEach(view => {
    const depth = depths[view.id];
    if (!levels[depth]) levels[depth] = [];
    levels[depth].push(view);
  });
  const sectionRank = section => {
    const index = sectionOrder.indexOf(section);
    return index === -1 ? 999 : index;
  };
  const stableSortBucket = (bucket, metricFn) => {
    bucket.sort((a, b) => {
      const sectionDiff = sectionRank(sectionNameFor(a)) - sectionRank(sectionNameFor(b));
      if (sectionDiff !== 0) return sectionDiff;
      const metricDiff = metricFn(a) - metricFn(b);
      if (Math.abs(metricDiff) > 0.001) return metricDiff;
      return a.name.localeCompare(b.name);
    });
  };
  Object.values(levels).forEach(bucket => stableSortBucket(bucket, view => 0));
  const indexInLevel = (depth, viewId) => (levels[depth] || []).findIndex(candidate => candidate.id === viewId);
  const barycenter = (neighborIds, depth) => {
    const indices = neighborIds.map(id => indexInLevel(depth, id)).filter(index => index >= 0);
    if (!indices.length) return Number.POSITIVE_INFINITY;
    return indices.reduce((sum, index) => sum + index, 0) / indices.length;
  };
  for (let sweep = 0; sweep < 6; sweep += 1) {
    for (let depth = 1; depth <= maxDepth; depth += 1) {
      const bucket = levels[depth] || [];
      stableSortBucket(bucket, view => barycenter(incomingForward[view.id] || [], depth - 1));
    }
    for (let depth = maxDepth - 1; depth >= 0; depth -= 1) {
      const bucket = levels[depth] || [];
      stableSortBucket(bucket, view => barycenter((forwardEdgesByView[view.id] || []).map(edge => edge.viewId), depth + 1));
    }
  }
  const maxRows = Math.max(...Object.values(levels).map(bucket => bucket.length));
  const W = marginX * 2 + (maxDepth + 1) * nodeW + Math.max(0, maxDepth) * colGap;
  const innerH = maxRows * nodeH + Math.max(0, maxRows - 1) * rowGap;
  const topRailBand = 104;
  const bottomRailBand = 92;
  const totalH = marginY * 2 + innerH + topRailBand + bottomRailBand + 32;
  const pos = {};
  Object.entries(levels).forEach(([depth, bucket]) => {
    const blockHeight = bucket.length * nodeH + Math.max(0, bucket.length - 1) * rowGap;
    const startY = marginY + topRailBand + Math.max(0, (innerH - blockHeight) / 2);
    bucket.forEach((view, index) => {
      pos[view.id] = {
        x: marginX + Number(depth) * (nodeW + colGap),
        y: startY + index * (nodeH + rowGap),
      };
    });
  });
  const depthGuides = Array.from({ length: maxDepth + 1 }, (_, depth) => {
    const x = marginX + depth * (nodeW + colGap);
    return `
      <g>
        <text x="${x + nodeW / 2}" y="18" text-anchor="middle" font-size="9" fill="#6F85A6" font-family="-apple-system,sans-serif">Depth ${depth}</text>
        <line x1="${x + nodeW / 2}" y1="28" x2="${x + nodeW / 2}" y2="${totalH - marginY}" stroke="rgba(80,108,145,0.16)" stroke-dasharray="4,8"/>
      </g>
    `;
  }).join('');
  const auxEdges = [];
  views.forEach(v => {
    (auxiliaryTransitions[v.id] || []).forEach((edge, index) => {
      const from = pos[v.id];
      const to = pos[edge.viewId];
      if (!from || !to) return;
      const color = { push: '#1DB8A0', sheet: '#3B82F6', replace: '#FBBF24', pop: '#94A3B8' }[edge.type] || '#8A9BB0';
      const fromX = from.x + nodeW;
      const toX = to.x;
      const fromMidY = from.y + nodeH / 2;
      const toMidY = to.y + nodeH / 2;
      const fromTopY = from.y + 8;
      const toTopY = to.y + 8;
      const fromBottomY = from.y + nodeH - 8;
      const toBottomY = to.y + nodeH - 8;
      const topRailY = 36 + (index % 5) * 14;
      const bottomRailY = totalH - 34 - (index % 5) * 14;
      let path = '';
      let labelX = 0;
      let labelY = 0;
      if (edge.type === 'pop') {
        path = `M${from.x + nodeW / 2},${fromBottomY} L${from.x + nodeW / 2},${bottomRailY} L${to.x + nodeW / 2},${bottomRailY} L${to.x + nodeW / 2},${toBottomY}`;
        labelX = (from.x + to.x + nodeW) / 2;
        labelY = bottomRailY - 8;
      } else if (depths[edge.viewId] <= depths[v.id]) {
        path = `M${from.x + nodeW / 2},${fromTopY} L${from.x + nodeW / 2},${topRailY} L${to.x + nodeW / 2},${topRailY} L${to.x + nodeW / 2},${toTopY}`;
        labelX = (from.x + to.x + nodeW) / 2;
        labelY = topRailY - 6;
      } else {
        const laneX = fromX + Math.max(30, (toX - fromX) / 2);
        path = `M${fromX},${fromMidY} L${laneX},${fromMidY} L${laneX},${toMidY} L${toX},${toMidY}`;
        labelX = laneX;
        labelY = Math.min(fromMidY, toMidY) + Math.abs(toMidY - fromMidY) / 2 - 8;
      }
      auxEdges.push(`
        <path d="${path}" fill="none" stroke="${color}" stroke-width="1.5" stroke-dasharray="${edge.type === 'sheet' ? '7,5' : edge.type === 'replace' ? '4,4' : edge.type === 'pop' ? '3,5' : '2,4'}" opacity=".72" marker-end="url(#arr-${edge.type || 'push'})"/>
        ${edge.trigger ? `<rect x="${labelX - 48}" y="${labelY - 9}" width="96" height="16" rx="8" fill="#0D1628" opacity=".92"/>` : ''}
        ${edge.trigger ? `<text x="${labelX}" y="${labelY + 2}" text-anchor="middle" font-size="8.5" fill="${color}" opacity=".95" font-family="-apple-system,sans-serif">${escapeHtml(edge.trigger.length > 20 ? `${edge.trigger.slice(0, 17)}…` : edge.trigger)}</text>` : ''}
      `);
    });
  });
  let edges = '';
  views.forEach(v => {
    (forwardEdgesByView[v.id] || []).forEach(n => {
      const from = pos[v.id];
      const to = pos[n.viewId];
      if (!from || !to) return;
      const x1 = from.x + nodeW;
      const y1 = from.y + nodeH / 2;
      const x2 = to.x;
      const y2 = to.y + nodeH / 2;
      const color = { push: '#1DB8A0', sheet: '#3B82F6', replace: '#FBBF24', pop: '#94A3B8' }[n.type] || '#1DB8A0';
      const laneX = x1 + Math.max(28, (x2 - x1) / 2);
      edges += `<path d="M${x1},${y1} L${laneX},${y1} L${laneX},${y2} L${x2},${y2}" fill="none" stroke="${color}" stroke-width="1.8" stroke-dasharray="${n.type === 'sheet' ? '7,5' : 'none'}" opacity=".86" marker-end="url(#arr-${n.type || 'push'})"/>`;
      if (n.trigger) {
        const labelX = laneX;
        const labelY = Math.min(y1, y2) + Math.abs(y2 - y1) / 2 - 8;
        edges += `<rect x="${labelX - 48}" y="${labelY - 9}" width="96" height="16" rx="8" fill="#0D1628" opacity=".92"/>`;
        edges += `<text x="${labelX}" y="${labelY + 2}" text-anchor="middle" font-size="8.5" fill="${color}" opacity=".95" font-family="-apple-system,sans-serif">${escapeHtml(n.trigger.length > 20 ? `${n.trigger.slice(0, 17)}…` : n.trigger)}</text>`;
      }
    });
  });
  edges += auxEdges.join('');
  const nodes = views.map(v => {
    const p = pos[v.id];
    const isRoot = v.root || config.navigation?.root === v.id;
    const section = sectionNameFor(v);
    const sectionColor = { Core: '#1DB8A0', Settings: '#3B82F6', Library: '#FBBF24', Sheets: '#A78BFA', General: '#94A3B8' }[section] || '#94A3B8';
    const auxTags = (auxiliaryTransitions[v.id] || []).slice(0, 1).map((edge, index) => {
      const targetName = viewById[edge.viewId]?.name || edge.viewId;
      const prefix = edge.type === 'pop' ? '↩' : edge.type === 'replace' ? '⇄' : edge.type === 'sheet' ? '⬒' : '↗';
      const fill = edge.type === 'pop' ? '#94A3B8' : edge.type === 'replace' ? '#FBBF24' : edge.type === 'sheet' ? '#3B82F6' : '#8A9BB0';
      return `<text x="${p.x + 12}" y="${p.y + 66 + (index * 11)}" font-size="8.5" fill="${fill}" font-family="-apple-system,sans-serif">${prefix} ${escapeHtml(targetName)}</text>`;
    }).join('');
    const auxMore = (auxiliaryTransitions[v.id] || []).length > 1
      ? `<text x="${p.x + nodeW - 12}" y="${p.y + 66}" text-anchor="end" font-size="8" fill="#94A3B8" font-family="-apple-system,sans-serif">+${(auxiliaryTransitions[v.id] || []).length - 1}</text>`
      : '';
    return `
      <g onclick="showPage('viewdetail','${v.id}')" style="cursor:pointer">
        <rect x="${p.x}" y="${p.y}" width="${nodeW}" height="${nodeH}" rx="12" fill="${isRoot ? '#1DB8A0' : '#162035'}" stroke="${isRoot ? '#57E6D0' : 'rgba(84,116,158,0.58)'}" stroke-width="${isRoot ? 2 : 1}"/>
        <rect x="${p.x + 12}" y="${p.y + 10}" width="52" height="16" rx="8" fill="${sectionColor}" opacity=".18" stroke="${sectionColor}" stroke-width=".8"/>
        <text x="${p.x + 38}" y="${p.y + 21}" text-anchor="middle" font-size="8" font-weight="700" fill="${isRoot ? '#ecfffb' : sectionColor}" font-family="-apple-system,sans-serif">${escapeHtml(section)}</text>
        <text x="${p.x + 12}" y="${p.y + 40}" font-size="11" font-weight="700" fill="#fff" font-family="-apple-system,sans-serif">${escapeHtml(v.name)}</text>
        <text x="${p.x + 12}" y="${p.y + 54}" font-size="8.5" fill="${isRoot ? 'rgba(255,255,255,.8)' : '#8A9BB0'}" font-family="-apple-system,sans-serif">${(v.components || []).length} comp</text>
        <text x="${p.x + nodeW - 12}" y="${p.y + 54}" text-anchor="end" font-size="8.5" fill="${isRoot ? 'rgba(255,255,255,.8)' : '#8A9BB0'}" font-family="-apple-system,sans-serif">${(forwardEdgesByView[v.id] || []).length} forward</text>
        ${auxTags}
        ${auxMore}
      </g>
    `;
  }).join('');
  const legend = `<g transform="translate(${W - 236},20)"><rect x="-12" y="-8" width="212" height="106" rx="12" fill="#10192d" opacity=".96"/><line x1="0" y1="8" x2="24" y2="8" stroke="#1DB8A0" stroke-width="1.5" marker-end="url(#arr-push)"/><text x="30" y="12" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">push</text><line x1="0" y1="26" x2="24" y2="26" stroke="#3B82F6" stroke-width="1.5" stroke-dasharray="6,4" marker-end="url(#arr-sheet)"/><text x="30" y="30" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">sheet</text><line x1="0" y1="44" x2="24" y2="44" stroke="#FBBF24" stroke-width="1.5" stroke-dasharray="4,4" marker-end="url(#arr-replace)"/><text x="30" y="48" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">replace</text><line x1="0" y1="62" x2="24" y2="62" stroke="#94A3B8" stroke-width="1.5" stroke-dasharray="3,5" marker-end="url(#arr-pop)"/><text x="30" y="66" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">pop</text><text x="0" y="84" font-size="8.5" fill="#6F85A6" font-family="-apple-system,sans-serif">special routes use top/bottom rails</text><text x="0" y="96" font-size="8.5" fill="#6F85A6" font-family="-apple-system,sans-serif">to avoid running through nodes</text></g>`;
  const zoom = typeof navMapZoom === 'number' ? navMapZoom : 1;
  document.getElementById('navMapContainer').innerHTML = `<svg id="navMapSvg" viewBox="0 0 ${W} ${totalH}" width="${Math.round(W * zoom)}" height="${Math.round(totalH * zoom)}" xmlns="http://www.w3.org/2000/svg"><defs><marker id="arr-push" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#1DB8A0"/></marker><marker id="arr-sheet" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#3B82F6"/></marker><marker id="arr-replace" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#FBBF24"/></marker><marker id="arr-pop" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#94A3B8"/></marker></defs><rect width="${W}" height="${totalH}" fill="#0D1628"/>${depthGuides}${edges}${nodes}${legend}</svg>`;
}

// ─── Component renderers ──────────────────────────────────────────────────────
// Note: innerHTML is used intentionally — all content comes from the developer's
// own design.json config, not from untrusted user input.

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

  switch (type) {
    case 'button': {
      const cls = {primary:'r-btn-primary',secondary:'r-btn-secondary',destructive:'r-btn-destructive',blue:'r-btn-blue',ghost:'r-btn-ghost'}[props.style||'primary']||'r-btn-primary';
      return `<div class="${cls}" style="${disabled}">${props.title||'Button'}</div>`;
    }
    case 'badge': {
      const cls = {teal:'r-badge-teal',surface:'r-badge-surface',blue:'r-badge-blue'}[props.style||'teal']||'r-badge-teal';
      return `<span class="${cls}">${props.label||'Badge'}</span>`;
    }
    case 'timer':
      return `<div class="r-timer" style="color:${props.accent?'var(--accent)':'var(--t1)'}">${props.value||'00:00'}</div>`;
    case 'difficulty-picker': {
      const options = props.options||['Extra lehké','Lehké','Střední','Těžké','Extra těžké'];
      const sel = props.selected??2;
      return `<div class="r-diff-picker">${options.map((o,i)=>`<div class="r-diff-chip${i===sel?' r-sel':''}">${o}</div>`).join('')}</div>`;
    }
    case 'numpad': {
      const selNum = props.selected??5;
      return `<div class="r-numpad">${[1,2,3,4,5,6,7,8,9].map(n=>`<div class="r-num-btn${n===selNum?' r-sel':''}">${n}</div>`).join('')}</div>`;
    }
    case 'list': {
      const rows = props.rows||[{label:'Item',value:'Value'}];
      return `<div class="r-list-card">${rows.map(r=>`<div class="r-list-row"><span style="font-weight:500">${r.label}</span><span class="r-list-val">${r.value||''}<span style="font-size:11px;color:var(--t3)">›</span></span></div>`).join('')}</div>`;
    }
    case 'navbar': {
      const actions = props.actions||['🔖','⊞','⚙'];
      return `<div class="r-navbar"><div style="display:flex;align-items:center;gap:8px"><div class="r-circle">‹</div><span style="font-size:14px;font-weight:700">${props.title||'Screen'}</span></div><div style="display:flex;gap:6px">${actions.map(a=>`<div class="r-circle" style="width:30px;height:30px;font-size:12px">${a}</div>`).join('')}</div></div>`;
    }
    case 'stat-chips': {
      const chips = props.chips||[{label:'Obtížnost',value:'Střední'},{label:'Čas',value:'00:06',accent:true}];
      return `<div class="r-stat-row">${chips.map(c=>`<div class="r-stat-chip"><div class="r-stat-label">${c.label}</div><div class="r-stat-val" style="${c.accent?'color:var(--accent);font-family:var(--mono)':''}">${c.value}</div></div>`).join('')}</div>`;
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
      const btns = props.buttons||[{icon:'⊟',label:'Scan'},{icon:'🖼',label:'Gallery'}];
      return `<div style="background:var(--surface);border:1px solid var(--accent);border-radius:13px;padding:12px;max-width:240px"><div style="font-size:13px;font-weight:700;margin-bottom:3px">${props.title||'Action'}</div><div style="font-size:11px;color:var(--t2);margin-bottom:10px">${props.subtitle||''}</div><div style="display:flex;gap:8px">${btns.map(b=>`<div style="flex:1;background:var(--surface2);border:1px solid var(--border);border-radius:10px;padding:10px;display:flex;flex-direction:column;align-items:center;gap:5px;cursor:pointer"><span style="font-size:20px">${b.icon}</span><span style="font-size:10px;font-weight:600;color:var(--t2)">${b.label}</span></div>`).join('')}</div></div>`;
    }
    default:
      return `<div style="color:var(--t3);font-size:12px;font-family:var(--mono)">renderer: "${type}"<br>props: ${JSON.stringify(props,null,1)}</div>`;
  }
}

// ─── Page renderers ───────────────────────────────────────────────────────────

function renderTokens() {
  if (!config) return;
  const colors = config.tokens?.colors || {};
  const groups = {};
  Object.entries(colors).forEach(([k,v]) => { const g=v.group||'Colors'; if(!groups[g])groups[g]=[]; groups[g].push([k,v]); });
  let html = '';
  Object.entries(groups).forEach(([grp,entries]) => {
    html += `<div class="subsection">${grp}</div><div class="token-grid">`;
    entries.forEach(([k,v]) => {
      const dv=v.dark||v.value||v, lv=v.light||v.value||v;
      html += `<div class="swatch"><div class="swatch-block" style="background:${dv}"></div><div class="swatch-info"><div class="swatch-name">${k}</div><div class="swatch-token">tokens.colors.${k}</div><div class="swatch-hex">${dv} / ${lv}</div></div></div>`;
    });
    html += '</div>';
  });
  document.getElementById('tokensContent').innerHTML = html || '<div class="empty"><div class="empty-icon">◉</div><div class="empty-title">No color tokens</div><div class="empty-sub">Add tokens.colors to your design.json</div></div>';
}

function renderTypography() {
  if (!config) return;
  const scale = config.tokens?.typography || [];
  if (!scale.length) { document.getElementById('typographyContent').innerHTML='<div class="empty"><div class="empty-icon">T</div><div class="empty-title">No type scale</div></div>'; return; }
  let html = '<table style="width:100%;border-collapse:collapse"><thead><tr>';
  ['Role','SwiftUI','Size / Weight','Preview'].forEach(h=>{ html+=`<th style="text-align:left;font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:1px;color:var(--t3);padding:6px 10px;border-bottom:1px solid var(--border)">${h}</th>`; });
  html += '</tr></thead><tbody>';
  scale.forEach(t => {
    html += `<tr><td style="padding:10px;border-bottom:1px solid var(--border2)"><span class="tag">${t.role}</span></td><td style="padding:10px;border-bottom:1px solid var(--border2)"><span class="tag">${t.swiftui||'-'}</span></td><td style="padding:10px;border-bottom:1px solid var(--border2);font-family:var(--mono);font-size:10px;color:var(--t2)">${t.size}pt / ${t.weight}</td><td style="padding:10px;border-bottom:1px solid var(--border2)"><span style="font-size:${Math.min(t.size,28)}px;font-weight:${t.weight};${t.mono?'font-family:var(--mono)':''};${t.caps?'text-transform:uppercase;letter-spacing:1px':''};color:${t.secondary?'var(--t2)':'var(--t1)'}">${t.preview||t.role}</span></td></tr>`;
  });
  document.getElementById('typographyContent').innerHTML = html + '</tbody></table>';
}

function renderSpacing() {
  if (!config) return;
  const spacing = config.tokens?.spacing || {}, radius = config.tokens?.radius || {};
  let html = '';
  if (Object.keys(spacing).length) {
    html += '<div class="subsection">Spacing</div><div style="display:flex;flex-direction:column;gap:6px">';
    Object.entries(spacing).forEach(([k,v]) => {
      const px = parseInt(v.value||v);
      html += `<div style="display:flex;align-items:center;gap:12px"><div style="width:${Math.min(px*2,120)}px;height:18px;background:var(--accent);border-radius:3px;opacity:.7;min-width:4px"></div><span style="font-size:11px;font-family:var(--mono);color:var(--t2);min-width:150px">${k} · ${px}px · ${v.usage||''}</span></div>`;
    });
    html += '</div>';
  }
  if (Object.keys(radius).length) {
    html += '<div class="subsection" style="margin-top:24px">Corner Radius</div><div style="display:flex;gap:16px;flex-wrap:wrap;align-items:flex-end">';
    Object.entries(radius).forEach(([k,v]) => {
      const px = v.value||v;
      html += `<div style="text-align:center"><div style="width:52px;height:52px;background:var(--surface2);border:1px solid var(--border);border-radius:${px};margin:0 auto 6px"></div><div style="font-size:9px;font-family:var(--mono);color:var(--t3)">${px}</div><div style="font-size:10px;font-weight:700;color:var(--t1);margin-top:1px">${k}</div></div>`;
    });
    html += '</div>';
  }
  document.getElementById('spacingContent').innerHTML = html || '<div class="empty"><div class="empty-icon">⬚</div><div class="empty-title">No spacing tokens</div></div>';
}

function buildComponentCard(c) {
  const mocks = c.mocks||[], preview = renderComponentPreview(c, mocks[0]?.props||{});
  const mockOpts = mocks.map(m=>`<option value="${m.id}">${m.label}</option>`).join('');
  return `<div class="component-card"><div class="cc-header"><div class="cc-name">${c.name}</div>${c.swiftui?`<div class="cc-swift">${c.swiftui}</div>`:''} ${c.description?`<div class="cc-desc">${c.description}</div>`:''}</div><div class="cc-preview" id="preview-${c.id}">${preview}</div><div class="cc-footer"><span class="mock-label">Mock</span><select class="mock-select" id="mock-sel-${c.id}">${mockOpts||'<option>—</option>'}</select></div></div>`;
}

function renderComponents() {
  if (!config) return;
  const comps = config.components||[];
  if (!comps.length) { document.getElementById('componentsContent').innerHTML='<div class="empty"><div class="empty-icon">⬡</div><div class="empty-title">No components</div></div>'; return; }
  document.getElementById('componentsContent').innerHTML = `<div class="component-grid">${comps.map(c=>buildComponentCard(c)).join('')}</div>`;
  comps.forEach(c => { const sel=document.getElementById('mock-sel-'+c.id); if(sel) sel.onchange=()=>updateMockPreview(c.id,sel.value); });
}

function updateMockPreview(compId, mockId) {
  const comp = (config?.components||[]).find(c=>c.id===compId);
  if (!comp) return;
  const mock = (comp.mocks||[]).find(m=>m.id===mockId);
  const el = document.getElementById('preview-'+compId);
  if (el) el.innerHTML = renderComponentPreview(comp, mock?.props||{});
}

function buildMiniScreen(view) {
  const style = view.presentation==='sheet'
    ? 'width:75px;max-height:170px;background:var(--surface);border-radius:10px 10px 6px 6px;border:1px solid var(--border);overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.3)'
    : 'width:75px;height:140px;background:var(--surface);border-radius:10px;border:1px solid var(--border);overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,.3)';
  let inner = `<div style="height:22px;background:var(--bg);display:flex;align-items:center;justify-content:center;border-bottom:1px solid var(--border2)"><span style="font-size:7px;font-weight:700;color:var(--t1)">${view.name}</span></div>`;
  (view.components||[]).slice(0,3).forEach(()=>{ inner+=`<div style="margin:4px 4px 0;height:14px;background:var(--surface2);border-radius:3px;opacity:.7"></div>`; });
  if ((view.navigatesTo||[]).length) inner+=`<div style="margin:6px 4px 4px;height:18px;background:var(--accent);border-radius:5px;opacity:.8;display:flex;align-items:center;justify-content:center"><span style="font-size:7px;font-weight:700;color:#fff">CTA</span></div>`;
  return `<div style="${style}">${inner}</div>`;
}

function renderViews() {
  if (!config) return;
  const views = config.views||[];
  if (!views.length) { document.getElementById('viewsContent').innerHTML='<div class="empty"><div class="empty-icon">▭</div><div class="empty-title">No views</div></div>'; return; }
  let html = '<div class="view-grid">';
  views.forEach(v => {
    const navTags=(v.navigatesTo||[]).map(n=>`<span class="vc-nav-tag">→ ${n.viewId}</span>`).join('');
    html+=`<div class="view-card" onclick="showPage('viewdetail','${v.id}')"><div class="vc-screen">${buildMiniScreen(v)}</div><div class="vc-info"><div class="vc-name">${v.name}</div><div class="vc-comps">${(v.components||[]).length} component${(v.components||[]).length!==1?'s':''}</div><div class="vc-nav-tags">${navTags}</div></div></div>`;
  });
  document.getElementById('viewsContent').innerHTML = html + '</div>';
}

function renderViewDetail(viewId) {
  const view = (config?.views||[]).find(v=>v.id===viewId);
  if (!view) return;
  document.getElementById('vdTitle').textContent = view.name;
  let phoneContent = '';
  if (view.navbar) {
    const nb = view.navbar;
    phoneContent+=`<div class="phone-navbar">${nb.back?`<div class="phone-btn">‹</div>`:'<div style="width:28px"></div>'}<div class="phone-title">${nb.title||view.name}</div><div style="display:flex;gap:4px">${(nb.actions||[]).map(a=>`<div class="phone-btn" style="font-size:10px">${a}</div>`).join('')}</div></div>`;
  }
  phoneContent += '<div class="phone-content">';
  (view.components||[]).forEach(cid => {
    const comp=(config?.components||[]).find(c=>c.id===cid);
    phoneContent+=comp?`<div style="margin-bottom:8px">${renderComponentPreview(comp,(comp.mocks||[])[0]?.props||{})}</div>`:`<div style="height:24px;background:var(--surface2);border-radius:5px;margin-bottom:6px;opacity:.5"></div>`;
  });
  phoneContent += '</div>';
  const compPills=(view.components||[]).map(cid=>{ const comp=(config?.components||[]).find(c=>c.id===cid); return `<div class="vd-comp-pill" onclick="showComponentPage('${cid}')">${comp?comp.name:cid}<span style="font-size:10px;color:var(--t3)">›</span></div>`; }).join('');
  const navArrows=(view.navigatesTo||[]).map(n=>{ const t=(config?.views||[]).find(v=>v.id===n.viewId); const bc={push:'nav-push',sheet:'nav-sheet',replace:'nav-replace'}[n.type]||'nav-push'; return `<div class="nav-arrow" onclick="showPage('viewdetail','${n.viewId}')"><div style="flex:1"><div style="font-size:12px;font-weight:600">${t?t.name:n.viewId}</div><div class="nav-trigger">${n.trigger||''}</div></div><span class="nav-badge ${bc}">${n.type||'push'}</span></div>`; }).join('');
  document.getElementById('viewDetailContent').innerHTML=`<div class="view-detail active"><div class="vd-screen"><div class="vd-phone"><div class="vd-notch">9:41 AM</div><div class="vd-body">${phoneContent}</div></div></div><div class="vd-sidebar">${compPills?`<div class="vd-panel"><div class="vd-panel-title">Components</div>${compPills}</div>`:''} ${navArrows?`<div class="vd-panel"><div class="vd-panel-title">Navigates to</div>${navArrows}</div>`:''} ${view.description?`<div class="vd-panel"><div class="vd-panel-title">Notes</div><div style="font-size:12px;color:var(--t2);line-height:1.6">${view.description}</div></div>`:''}<div class="vd-panel"><div class="vd-panel-title">Config</div><div style="font-size:10px;color:var(--t3)">id: <span style="color:var(--accent);font-family:var(--mono)">${view.id}</span></div>${view.presentation?`<div style="font-size:10px;color:var(--t3);margin-top:4px">presentation: <span style="color:var(--t2)">${view.presentation}</span></div>`:''} ${view.root?`<div style="font-size:10px;color:var(--t3);margin-top:4px">root: <span style="color:var(--warn)">true</span></div>`:''}</div></div></div>`;
}

function renderNavMap() {
  if (!config) return;
  const views=config.views||[];
  if (!views.length) { document.getElementById('navMapContainer').innerHTML='<div class="empty" style="padding:60px"><div class="empty-icon">⬡</div><div class="empty-title">No views defined</div></div>'; return; }
  const W=900,H=500,nodeW=130,nodeH=48,cols=3;
  const pos={};
  views.forEach((v,i)=>{ pos[v.id]={x:60+(i%cols)*(nodeW+80),y:60+Math.floor(i/cols)*(nodeH+80)}; });
  const totalH=Math.max(H,60+Math.ceil(views.length/cols)*(nodeH+80)+60);
  let edges='';
  views.forEach(v=>{
    (v.navigatesTo||[]).forEach(n=>{
      const from=pos[v.id],to=pos[n.viewId]; if(!from||!to) return;
      const x1=from.x+nodeW/2,y1=from.y+nodeH,x2=to.x+nodeW/2,y2=to.y;
      const color={push:'#1DB8A0',sheet:'#3B82F6',replace:'#FBBF24'}[n.type]||'#1DB8A0';
      edges+=`<path d="M${x1},${y1} C${x1},${y1+40} ${x2},${y2-40} ${x2},${y2}" fill="none" stroke="${color}" stroke-width="1.5" stroke-dasharray="${n.type==='sheet'?'6,3':'none'}" opacity=".7" marker-end="url(#arr-${n.type||'push'})"/>`;
      if (n.trigger) edges+=`<text x="${(x1+x2)/2}" y="${(y1+y2)/2}" text-anchor="middle" font-size="9" fill="${color}" opacity=".8" font-family="-apple-system,sans-serif">${n.trigger.length>18?n.trigger.slice(0,15)+'…':n.trigger}</text>`;
    });
  });
  let nodes='';
  views.forEach(v=>{
    const p=pos[v.id],isRoot=v.root||config.navigation?.root===v.id;
    nodes+=`<g onclick="showPage('viewdetail','${v.id}')" style="cursor:pointer"><rect x="${p.x}" y="${p.y}" width="${nodeW}" height="${nodeH}" rx="10" fill="${isRoot?'#1DB8A0':'#162035'}" stroke="${isRoot?'#2DD4BF':'rgba(60,90,130,0.5)'}" stroke-width="${isRoot?2:1}"/><text x="${p.x+nodeW/2}" y="${p.y+nodeH/2-4}" text-anchor="middle" font-size="11" font-weight="700" fill="#fff" font-family="-apple-system,sans-serif">${v.name}</text><text x="${p.x+nodeW/2}" y="${p.y+nodeH/2+10}" text-anchor="middle" font-size="8" fill="${isRoot?'rgba(255,255,255,.7)':'#8A9BB0'}" font-family="-apple-system,sans-serif">${(v.components||[]).length} comp · ${(v.navigatesTo||[]).length} nav</text></g>`;
  });
  const legend=`<g transform="translate(${W-140},20)"><line x1="0" y1="8" x2="24" y2="8" stroke="#1DB8A0" stroke-width="1.5" marker-end="url(#arr-push)"/><text x="30" y="12" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">push</text><line x1="0" y1="26" x2="24" y2="26" stroke="#3B82F6" stroke-width="1.5" stroke-dasharray="6,3" marker-end="url(#arr-sheet)"/><text x="30" y="30" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">sheet</text><line x1="0" y1="44" x2="24" y2="44" stroke="#FBBF24" stroke-width="1.5" marker-end="url(#arr-replace)"/><text x="30" y="48" font-size="9" fill="#8A9BB0" font-family="-apple-system,sans-serif">replace</text></g>`;
  document.getElementById('navMapContainer').innerHTML=`<svg id="navMapSvg" viewBox="0 0 ${W} ${totalH}" width="${W}" height="${totalH}" xmlns="http://www.w3.org/2000/svg"><defs><marker id="arr-push" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#1DB8A0"/></marker><marker id="arr-sheet" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#3B82F6"/></marker><marker id="arr-replace" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto"><path d="M0,0 L0,6 L8,3 z" fill="#FBBF24"/></marker></defs><rect width="${W}" height="${totalH}" fill="#0D1628"/>${edges}${nodes}${legend}</svg>`;
}

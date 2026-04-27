/* admin/drugs.js — Drogen-Definitionen */
(function () {
  if (!window.CLPADMIN) return;

  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between">
        <h2>Drogen</h2>
        <div class="toolbar">
          <button class="btn primary" data-new>Neue Droge</button>
          <button class="btn" data-reload>Reload</button>
        </div>
      </div>
      <div class="grid two">
        <div class="card list" id="dList">Lade…</div>
        <div class="card" id="dEdit"><p class="meta">Wähle eine Droge zum Bearbeiten.</p></div>
      </div>`;
    const list = ctx.mount.querySelector('#dList');
    const edit = ctx.mount.querySelector('#dEdit');
    let cache = [];
    async function load() {
      const r = await ctx.request('drugs:list', {});
      cache = (r && r.drugs) || [];
      list.innerHTML = cache.map(d => `
        <div class="row-item">
          <div><strong style="color:${d.color || '#fff'}">${d.label}</strong><div class="meta">${d.id} · Kette: ${(d.chain||[]).join(' → ')}</div></div>
          <span class="tag">${d.base_price}$</span>
          <button class="btn" data-edit="${d.id}">Edit</button>
        </div>`).join('') || '<p class="meta">Keine Drogen.</p>';
      list.querySelectorAll('[data-edit]').forEach(b => {
        b.addEventListener('click', () => open(cache.find(x => x.id === b.dataset.edit)));
      });
    }
    function open(d) {
      const c = d ? JSON.parse(JSON.stringify(d)) : {
        id: '', label: '', color: '#7ee5ff', chain: [], minigame: { id: 'meth', difficulty: 0.5, duration: 20 },
        base_price: 100, heat_per_craft: 5, smell_factor: 1.0, electricity_factor: 1.0,
      };
      edit.innerHTML = `
        <h3>${d ? 'Bearbeiten' : 'Neue Droge'}</h3>
        <div class="grid two">
          <label class="field"><label>ID</label><input id="f_id" value="${c.id}" ${d ? 'disabled' : ''}/></label>
          <label class="field"><label>Label</label><input id="f_label" value="${c.label}"/></label>
          <label class="field"><label>Farbe</label><input id="f_color" value="${c.color}"/></label>
          <label class="field"><label>Kette (komma-separiert)</label><input id="f_chain" value="${(c.chain||[]).join(',')}"/></label>
          <label class="field"><label>Minigame</label>
            <select id="f_mg">${['meth','speed','heroin','lsd'].map(g => `<option ${g === c.minigame.id ? 'selected' : ''}>${g}</option>`).join('')}</select>
          </label>
          <label class="field"><label>Schwierigkeit (0-1)</label><input id="f_diff" type="number" step="0.01" value="${c.minigame.difficulty}"/></label>
          <label class="field"><label>Dauer (s)</label><input id="f_dur" type="number" value="${c.minigame.duration}"/></label>
          <label class="field"><label>Basispreis</label><input id="f_price" type="number" value="${c.base_price}"/></label>
          <label class="field"><label>Heat/Craft</label><input id="f_heat" type="number" value="${c.heat_per_craft}"/></label>
          <label class="field"><label>Smell-Factor</label><input id="f_smell" type="number" step="0.01" value="${c.smell_factor}"/></label>
          <label class="field"><label>Strom-Factor</label><input id="f_elec" type="number" step="0.01" value="${c.electricity_factor}"/></label>
        </div>
        <div class="row" style="margin-top:14px">
          <button class="btn primary" id="bSave">Speichern</button>
          ${d ? '<button class="btn danger" id="bDel">Löschen</button>' : ''}
        </div>`;
      edit.querySelector('#bSave').addEventListener('click', async () => {
        const g = (s) => edit.querySelector(s).value;
        const payload = {
          id: g('#f_id'), label: g('#f_label'), color: g('#f_color'),
          chain: g('#f_chain').split(',').map(s => s.trim()).filter(Boolean),
          minigame: { id: g('#f_mg'), difficulty: parseFloat(g('#f_diff')), duration: parseInt(g('#f_dur'), 10) },
          base_price: parseInt(g('#f_price'), 10), heat_per_craft: parseInt(g('#f_heat'), 10),
          smell_factor: parseFloat(g('#f_smell')), electricity_factor: parseFloat(g('#f_elec')),
        };
        const r = await ctx.request('drugs:upsert', payload);
        if (r && r.ok) { CLPHDS.notify('Gespeichert', 'success'); await load(); }
      });
      const del = edit.querySelector('#bDel');
      if (del) del.addEventListener('click', async () => {
        const r = await ctx.request('drugs:delete', { id: c.id });
        if (r && r.ok) { CLPHDS.notify('Gelöscht', 'success'); await load(); }
      });
    }
    ctx.mount.querySelector('[data-new]').addEventListener('click', () => open(null));
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }
  CLPADMIN.register('drugs', render);
})();

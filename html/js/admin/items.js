/* admin/items.js — Items Manager */
(function () {
  if (!window.CLPADMIN) return;

  const TYPES = ['raw', 'intermediate', 'final', 'tool', 'station'];

  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between">
        <h2>Items</h2>
        <div class="toolbar">
          <button class="btn primary" data-new>Neues Item</button>
          <button class="btn" data-reload>Reload</button>
        </div>
      </div>
      <div class="grid two">
        <div class="card list" id="iList">Lade…</div>
        <div class="card" id="iEdit"><p class="meta">Wähle ein Item zum Bearbeiten.</p></div>
      </div>`;

    const list = ctx.mount.querySelector('#iList');
    const edit = ctx.mount.querySelector('#iEdit');

    let cache = [];
    let current = null;

    async function load() {
      const r = await ctx.request('items:list', {});
      cache = (r && r.items) || [];
      list.innerHTML = cache.map(it => `
        <div class="row-item" data-id="${it.id}">
          <div>
            <strong>${it.label}</strong>
            <div class="meta">${it.id} · ${it.type} · ${it.weight}kg</div>
          </div>
          <span class="tag">${it.type}</span>
          <button class="btn" data-edit="${it.id}">Edit</button>
        </div>`).join('') || '<p class="meta">Keine Items.</p>';
      list.querySelectorAll('[data-edit]').forEach(b => {
        b.addEventListener('click', () => openEdit(cache.find(x => x.id === b.dataset.edit)));
      });
    }

    function openEdit(it) {
      current = it ? Object.assign({}, it) : { id: '', label: '', type: 'raw', weight: 0.1, stack: 100, decay_hours: 0, quality: false };
      edit.innerHTML = `
        <h3>${it ? 'Bearbeiten' : 'Neu anlegen'}</h3>
        <div class="grid two">
          <label class="field"><label>ID</label><input id="f_id"   value="${current.id || ''}" ${it ? 'disabled' : ''}/></label>
          <label class="field"><label>Label</label><input id="f_label" value="${current.label || ''}"/></label>
          <label class="field"><label>Type</label>
            <select id="f_type">${TYPES.map(t => `<option ${t === current.type ? 'selected' : ''}>${t}</option>`).join('')}</select>
          </label>
          <label class="field"><label>Gewicht (kg)</label><input id="f_weight" type="number" step="0.01" value="${current.weight}"/></label>
          <label class="field"><label>Stack</label><input id="f_stack" type="number" value="${current.stack}"/></label>
          <label class="field"><label>Haltbarkeit (h)</label><input id="f_decay" type="number" value="${current.decay_hours || 0}"/></label>
          <label class="field"><label>Qualität?</label>
            <select id="f_quality"><option value="false">Nein</option><option value="true" ${current.quality ? 'selected' : ''}>Ja</option></select>
          </label>
          <label class="field"><label>Modell (optional)</label><input id="f_model" value="${current.model || ''}"/></label>
        </div>
        <div class="row" style="margin-top:14px">
          <button class="btn primary" id="bSave">Speichern</button>
          ${it ? '<button class="btn danger" id="bDel">Löschen</button>' : ''}
        </div>`;
      edit.querySelector('#bSave').addEventListener('click', save);
      const del = edit.querySelector('#bDel'); if (del) del.addEventListener('click', remove);
    }

    async function save() {
      const get = (id) => edit.querySelector(id).value;
      const payload = {
        id: get('#f_id'), label: get('#f_label'), type: get('#f_type'),
        weight: parseFloat(get('#f_weight')), stack: parseInt(get('#f_stack'), 10),
        decay_hours: parseInt(get('#f_decay'), 10), quality: get('#f_quality') === 'true',
        model: get('#f_model') || undefined,
      };
      if (!payload.id || !payload.label) { CLPHDS.notify('ID + Label sind Pflicht', 'error'); return; }
      const r = await ctx.request('items:upsert', payload);
      if (r && r.ok) { CLPHDS.notify('Gespeichert', 'success'); await load(); }
      else CLPHDS.notify(r && r.error || 'Fehler', 'error');
    }

    async function remove() {
      if (!current || !current.id) return;
      const r = await ctx.request('items:delete', { id: current.id });
      if (r && r.ok) { CLPHDS.notify('Gelöscht', 'success'); current = null; edit.innerHTML = '<p class="meta">…</p>'; await load(); }
    }

    ctx.mount.querySelector('[data-new]').addEventListener('click', () => openEdit(null));
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }

  CLPADMIN.register('items', render);
})();

/* admin/recipes.js — Rezept-Editor mit Drag & Drop für Inputs/Outputs */
(function () {
  if (!window.CLPADMIN) return;

  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between">
        <h2>Rezepte</h2>
        <div class="toolbar">
          <button class="btn primary" data-new>Neues Rezept</button>
          <button class="btn" data-reload>Reload</button>
        </div>
      </div>
      <div class="grid two">
        <div class="card list" id="rList">Lade…</div>
        <div class="card" id="rEdit"><p class="meta">Wähle ein Rezept zum Bearbeiten.</p></div>
      </div>`;
    const list = ctx.mount.querySelector('#rList');
    const edit = ctx.mount.querySelector('#rEdit');
    let recipes = [], items = [], drugs = [];
    let current = null;

    async function load() {
      const [a, b, c] = await Promise.all([
        ctx.request('recipes:list', {}),
        ctx.request('items:list',   {}),
        ctx.request('drugs:list',   {}),
      ]);
      recipes = (a && a.recipes) || [];
      items   = (b && b.items)   || [];
      drugs   = (c && c.drugs)   || [];
      list.innerHTML = recipes.map(r => `
        <div class="row-item">
          <div><strong>${r.id}</strong><div class="meta">${r.drug} · ${r.station}</div></div>
          <span class="tag">${r.duration_sec}s</span>
          <button class="btn" data-edit="${r.id}">Edit</button>
        </div>`).join('') || '<p class="meta">Keine Rezepte.</p>';
      list.querySelectorAll('[data-edit]').forEach(b => {
        b.addEventListener('click', () => openEdit(recipes.find(x => x.id === b.dataset.edit)));
      });
    }

    function chip(entry, kind, container) {
      const el = document.createElement('div');
      el.className = 'chip';
      el.draggable = true;
      el.dataset.item = entry.item;
      el.innerHTML = `${entry.item} <input type="number" min="1" value="${entry.count || 1}" style="width:48px"/> <span class="x">×</span>`;
      el.querySelector('input').addEventListener('change', e => entry.count = parseInt(e.target.value, 10) || 1);
      el.querySelector('.x').addEventListener('click', () => { container.list.splice(container.list.indexOf(entry), 1); render(); });
      return el;
    }

    function dz(label, listRef, allowOutputFlag = false) {
      const dropzone = document.createElement('div');
      dropzone.className = 'dropzone';
      function refresh() {
        dropzone.innerHTML = '';
        listRef.list.forEach(e => dropzone.appendChild(chip(e, label, listRef)));
      }
      dropzone.addEventListener('dragover', (ev) => { ev.preventDefault(); dropzone.classList.add('drag'); });
      dropzone.addEventListener('dragleave', () => dropzone.classList.remove('drag'));
      dropzone.addEventListener('drop', (ev) => {
        ev.preventDefault(); dropzone.classList.remove('drag');
        const id = ev.dataTransfer.getData('text/plain');
        if (!id) return;
        const e = { item: id, count: 1 };
        if (allowOutputFlag) e.quality_from_minigame = true;
        listRef.list.push(e); refresh();
      });
      listRef.refresh = refresh;
      refresh();
      return dropzone;
    }

    function paletteEl(filter) {
      const wrap = document.createElement('div');
      wrap.className = 'dropzone';
      items.filter(filter).forEach(it => {
        const c = document.createElement('span');
        c.className = 'chip'; c.draggable = true;
        c.textContent = `${it.label} (${it.id})`;
        c.addEventListener('dragstart', (ev) => ev.dataTransfer.setData('text/plain', it.id));
        wrap.appendChild(c);
      });
      return wrap;
    }

    function openEdit(r) {
      current = r ? JSON.parse(JSON.stringify(r)) : {
        id: '', drug: drugs[0]?.id || 'meth', station: 'station_chem', minigame: 'meth',
        duration_sec: 15, inputs: [], outputs: [], tools: [], success_base: 0.85,
      };
      const inputsRef  = { list: current.inputs };
      const outputsRef = { list: current.outputs };
      const toolsRef   = { list: current.tools };

      edit.innerHTML = `
        <h3>${r ? 'Bearbeiten' : 'Neues Rezept'}</h3>
        <div class="grid two">
          <label class="field"><label>ID</label><input id="f_id" value="${current.id}" ${r ? 'disabled' : ''}/></label>
          <label class="field"><label>Drug</label>
            <select id="f_drug">${drugs.map(d => `<option ${d.id === current.drug ? 'selected' : ''}>${d.id}</option>`).join('')}</select>
          </label>
          <label class="field"><label>Station (Item-ID)</label><input id="f_station" value="${current.station}"/></label>
          <label class="field"><label>Minigame</label>
            <select id="f_mg">${['meth','speed','heroin','lsd'].map(g => `<option ${g === current.minigame ? 'selected' : ''}>${g}</option>`).join('')}</select>
          </label>
          <label class="field"><label>Dauer (s)</label><input id="f_dur" type="number" value="${current.duration_sec}"/></label>
          <label class="field"><label>Erfolgsbasis</label><input id="f_succ" type="number" step="0.01" value="${current.success_base}"/></label>
        </div>
        <h3 style="margin-top:14px">Inputs (drag aus Palette)</h3>
        <div id="paletteInputs"></div>
        <div id="dzInputs"></div>
        <h3 style="margin-top:14px">Outputs</h3>
        <div id="paletteOutputs"></div>
        <div id="dzOutputs"></div>
        <h3 style="margin-top:14px">Werkzeuge</h3>
        <div id="paletteTools"></div>
        <div id="dzTools"></div>
        <div class="row" style="margin-top:14px">
          <button class="btn primary" id="bSave">Speichern</button>
          ${r ? '<button class="btn danger" id="bDel">Löschen</button>' : ''}
        </div>`;
      edit.querySelector('#paletteInputs').appendChild(paletteEl(it => ['raw', 'intermediate'].includes(it.type)));
      edit.querySelector('#dzInputs').appendChild(dz('inputs', inputsRef));
      edit.querySelector('#paletteOutputs').appendChild(paletteEl(it => ['intermediate', 'final'].includes(it.type)));
      edit.querySelector('#dzOutputs').appendChild(dz('outputs', outputsRef, true));
      edit.querySelector('#paletteTools').appendChild(paletteEl(it => it.type === 'tool'));
      edit.querySelector('#dzTools').appendChild(dz('tools', toolsRef));

      edit.querySelector('#bSave').addEventListener('click', async () => {
        const g = (i) => edit.querySelector(i).value;
        const payload = {
          id: g('#f_id'), drug: g('#f_drug'), station: g('#f_station'), minigame: g('#f_mg'),
          duration_sec: parseInt(g('#f_dur'), 10), success_base: parseFloat(g('#f_succ')),
          inputs: inputsRef.list, outputs: outputsRef.list, tools: toolsRef.list,
        };
        if (!payload.id) { CLPHDS.notify('ID fehlt', 'error'); return; }
        const res = await ctx.request('recipes:upsert', payload);
        if (res && res.ok) { CLPHDS.notify('Gespeichert', 'success'); await load(); }
      });
      const del = edit.querySelector('#bDel');
      if (del) del.addEventListener('click', async () => {
        const res = await ctx.request('recipes:delete', { id: current.id });
        if (res && res.ok) { CLPHDS.notify('Gelöscht', 'success'); await load(); edit.innerHTML = '<p class="meta">…</p>'; }
      });
    }

    ctx.mount.querySelector('[data-new]').addEventListener('click', () => openEdit(null));
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }
  CLPADMIN.register('recipes', render);
})();

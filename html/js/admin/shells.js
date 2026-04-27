/* admin/shells.js — Verwaltung der Shell- / MLO-Definitionen */
(function () {
  if (!window.CLPADMIN) return;

  const KIND_OPTIONS = ['apartment', 'house', 'warehouse', 'bunker', 'custom'];

  function blankShell() {
    return {
      id:           '',
      label:        '',
      kind:         'apartment',
      ipl:          '',
      interior_id:  null,
      teleport_in:  { x: 0, y: 0, z: 72, h: 0 },
      teleport_out: null,
      place_bounds: { min: [-12, -12, -2], max: [12, 12, 4] },
      fade_ms:      500,
      doors:        [],
    };
  }

  function vec(label, ref, key) {
    const v = ref[key] || { x: 0, y: 0, z: 0, h: 0 };
    return `
      <fieldset class="vec">
        <legend>${label}</legend>
        <label>X<input type="number" step="0.01" data-vec="${key}.x" value="${v.x ?? 0}"/></label>
        <label>Y<input type="number" step="0.01" data-vec="${key}.y" value="${v.y ?? 0}"/></label>
        <label>Z<input type="number" step="0.01" data-vec="${key}.z" value="${v.z ?? 0}"/></label>
        <label>H<input type="number" step="0.1"  data-vec="${key}.h" value="${v.h ?? 0}"/></label>
        <button type="button" class="btn" data-capture="${key}">Aktuelle Pos</button>
      </fieldset>`;
  }

  function bounds(label, ref) {
    const b = ref.place_bounds || { min: [-12, -12, -2], max: [12, 12, 4] };
    return `
      <fieldset class="vec">
        <legend>${label}</legend>
        <label>min X<input type="number" step="0.1" data-bnd="min.0" value="${b.min[0]}"/></label>
        <label>min Y<input type="number" step="0.1" data-bnd="min.1" value="${b.min[1]}"/></label>
        <label>min Z<input type="number" step="0.1" data-bnd="min.2" value="${b.min[2]}"/></label>
        <label>max X<input type="number" step="0.1" data-bnd="max.0" value="${b.max[0]}"/></label>
        <label>max Y<input type="number" step="0.1" data-bnd="max.1" value="${b.max[1]}"/></label>
        <label>max Z<input type="number" step="0.1" data-bnd="max.2" value="${b.max[2]}"/></label>
      </fieldset>`;
  }

  function form(s) {
    return `
      <h3>${s.id ? 'Shell bearbeiten' : 'Neue Shell'}</h3>
      <div class="grid2">
        <label>ID<input data-f="id" value="${s.id || ''}" placeholder="z.B. shell_meth_lab"/></label>
        <label>Label<input data-f="label" value="${s.label || ''}"/></label>
        <label>Typ
          <select data-f="kind">
            ${KIND_OPTIONS.map(k => `<option value="${k}" ${s.kind === k ? 'selected' : ''}>${k}</option>`).join('')}
          </select>
        </label>
        <label>IPL-Key (optional)<input data-f="ipl" value="${s.ipl || ''}" placeholder="z.B. v_methlab"/></label>
        <label>Interior-ID (optional)<input type="number" data-f="interior_id" value="${s.interior_id ?? ''}"/></label>
        <label>Fade (ms)<input type="number" data-f="fade_ms" value="${s.fade_ms ?? 500}"/></label>
      </div>
      ${vec('Teleport-In (Spawn im Inneren)', s, 'teleport_in')}
      ${vec('Teleport-Out (optional Override)', s, 'teleport_out')}
      ${bounds('Placement-Bounds (relativ zum Innenraum)', s)}
      <div class="row">
        <button class="btn primary" data-save>Speichern</button>
        <button class="btn" data-test ${s.id ? '' : 'disabled'}>Test-Teleport</button>
        ${s.id ? `<button class="btn danger" data-del>Löschen</button>` : ''}
      </div>
      <p id="shellMsg" class="meta"></p>`;
  }

  function readForm(root, base) {
    const s = JSON.parse(JSON.stringify(base));
    root.querySelectorAll('[data-f]').forEach(el => {
      const k = el.dataset.f;
      let v = el.value;
      if (el.type === 'number') v = v === '' ? null : parseFloat(v);
      s[k] = v;
    });
    root.querySelectorAll('[data-vec]').forEach(el => {
      const [grp, key] = el.dataset.vec.split('.');
      s[grp] = s[grp] || { x: 0, y: 0, z: 0, h: 0 };
      s[grp][key] = parseFloat(el.value || 0);
    });
    // Wenn alle Werte 0 sind: Teleport-Out = null (Fallback auf lab.anchor)
    const o = s.teleport_out;
    if (o && o.x === 0 && o.y === 0 && o.z === 0 && o.h === 0) s.teleport_out = null;

    s.place_bounds = s.place_bounds || { min: [0, 0, 0], max: [0, 0, 0] };
    root.querySelectorAll('[data-bnd]').forEach(el => {
      const [grp, idx] = el.dataset.bnd.split('.');
      s.place_bounds[grp][parseInt(idx, 10)] = parseFloat(el.value || 0);
    });
    return s;
  }

  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between">
        <h2>Shells / MLOs</h2>
        <div>
          <button class="btn primary" data-new>Neue Shell</button>
          <button class="btn" data-reload>Reload</button>
        </div>
      </div>
      <div class="grid">
        <div class="card list" id="shList">Lade…</div>
        <div class="card edit" id="shEdit"><p class="meta">Wähle eine Shell zum Bearbeiten.</p></div>
      </div>`;

    const list = ctx.mount.querySelector('#shList');
    const edit = ctx.mount.querySelector('#shEdit');
    let cache = [];

    async function load() {
      const r = await ctx.request('shells:list', {});
      cache = (r && r.shells) || [];
      list.innerHTML = cache.length === 0 ? '<p class="meta">Keine Shells.</p>' : cache.map(s => `
        <div class="row-item" data-id="${s.id}">
          <div>
            <strong>${s.label || s.id}</strong>
            <div class="meta">${s.id} · ${s.kind || 'apartment'} ${s.ipl ? '· IPL: ' + s.ipl : ''}</div>
          </div>
          <button class="btn" data-edit="${s.id}">Edit</button>
        </div>`).join('');

      list.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click', () => {
        const s = cache.find(x => x.id === b.dataset.edit);
        bindEdit(s);
      }));
    }

    function bindEdit(s) {
      edit.innerHTML = form(s);

      edit.querySelector('[data-save]').addEventListener('click', async () => {
        const next = readForm(edit, s);
        if (!next.id) return CLPHDS.notify('ID fehlt', 'error');
        const r = await ctx.request('shells:upsert', next);
        if (r && r.ok) { CLPHDS.notify('Gespeichert', 'success'); await load(); }
        else CLPHDS.notify('Fehler: ' + ((r && r.error) || 'unbekannt'), 'error');
      });

      const test = edit.querySelector('[data-test]');
      if (test) test.addEventListener('click', async () => {
        if (!s.id) return;
        const r = await ctx.request('shells:teleport', { id: s.id });
        if (r && r.ok) CLPHDS.notify('Teleport getriggert', 'info');
      });

      const del = edit.querySelector('[data-del]');
      if (del) del.addEventListener('click', async () => {
        if (!confirm('Wirklich löschen? (geht nur, wenn keine Labore diese Shell nutzen)')) return;
        const r = await ctx.request('shells:delete', { id: s.id });
        if (r && r.ok) { CLPHDS.notify('Gelöscht', 'success'); edit.innerHTML = ''; await load(); }
        else CLPHDS.notify('Fehler: ' + ((r && r.error) || 'unbekannt'), 'error');
      });

      edit.querySelectorAll('[data-capture]').forEach(b => b.addEventListener('click', async () => {
        const grp = b.dataset.capture;
        const r = await ctx.request('shells:capturePos', {});
        if (!r || !r.ok) return CLPHDS.notify('Position konnte nicht gelesen werden', 'error');
        ['x', 'y', 'z', 'h'].forEach(k => {
          const inp = edit.querySelector(`[data-vec="${grp}.${k}"]`);
          if (inp) inp.value = r.pos[k];
        });
        CLPHDS.notify('Position übernommen', 'success');
      }));
    }

    ctx.mount.querySelector('[data-new]').addEventListener('click', () => bindEdit(blankShell()));
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }

  CLPADMIN.register('shells', render);
})();

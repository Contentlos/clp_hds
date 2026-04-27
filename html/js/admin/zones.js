/* admin/zones.js — Sammelzonen Editor (mit Map-Coordinate-Pasting) */
(function () {
  if (!window.CLPADMIN) return;
  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between"><h2>Sammelzonen</h2>
        <div class="toolbar"><button class="btn primary" data-new>Neue Zone</button><button class="btn" data-reload>Reload</button></div>
      </div>
      <div class="grid two">
        <div class="card list" id="zList">Lade…</div>
        <div class="card" id="zEdit"><p class="meta">Wähle eine Zone.</p></div>
      </div>`;
    const list = ctx.mount.querySelector('#zList');
    const edit = ctx.mount.querySelector('#zEdit');
    let zones = [];
    async function load() {
      const r = await ctx.request('zones:list', {});
      zones = (r && r.zones) || [];
      list.innerHTML = zones.map(z => `
        <div class="row-item"><div><strong>${z.label}</strong><div class="meta">${z.id} · ${z.centers?.length||0} Center</div></div>
          <button class="btn" data-edit="${z.id}">Edit</button></div>`).join('') || '<p class="meta">Keine Zonen.</p>';
      list.querySelectorAll('[data-edit]').forEach(b => b.addEventListener('click',
        () => open(zones.find(x => x.id === b.dataset.edit))));
    }
    function open(z) {
      const c = z ? JSON.parse(JSON.stringify(z)) : {
        id: '', label: '', items: [], centers: [], spawn_count: 8, active_minutes: 30, respawn_minutes: 30,
      };
      edit.innerHTML = `
        <h3>${z ? 'Bearbeiten' : 'Neue Zone'}</h3>
        <div class="grid two">
          <label class="field"><label>ID</label><input id="f_id" value="${c.id}" ${z ? 'disabled' : ''}/></label>
          <label class="field"><label>Label</label><input id="f_label" value="${c.label}"/></label>
          <label class="field"><label>Spawn-Count</label><input id="f_sc" type="number" value="${c.spawn_count}"/></label>
          <label class="field"><label>Aktiv (min)</label><input id="f_am" type="number" value="${c.active_minutes}"/></label>
          <label class="field"><label>Respawn (min)</label><input id="f_rm" type="number" value="${c.respawn_minutes}"/></label>
        </div>
        <h3 style="margin-top:14px">Items (1 pro Zeile: <code>itemId,minCount,maxCount,weight</code>)</h3>
        <textarea id="f_items">${(c.items||[]).map(i => `${i.item},${i.count?.[0]||1},${i.count?.[1]||1},${i.weight||1}`).join('\n')}</textarea>
        <h3 style="margin-top:14px">Centers (<code>x,y,z,radius</code> pro Zeile)</h3>
        <textarea id="f_centers">${(c.centers||[]).map(ct => `${ct.pos.join(',')},${ct.radius}`).join('\n')}</textarea>
        <p class="meta">Tipp: ingame mit <code>/clp_pos</code> die aktuellen Koordinaten in die Zwischenablage kopieren.</p>
        <div class="row" style="margin-top:14px">
          <button class="btn primary" id="bSave">Speichern</button>
          ${z ? '<button class="btn danger" id="bDel">Löschen</button>' : ''}
        </div>`;
      edit.querySelector('#bSave').addEventListener('click', async () => {
        const txtItems = edit.querySelector('#f_items').value.trim().split('\n').filter(Boolean);
        const txtCenters = edit.querySelector('#f_centers').value.trim().split('\n').filter(Boolean);
        const payload = {
          id: edit.querySelector('#f_id').value, label: edit.querySelector('#f_label').value,
          spawn_count: parseInt(edit.querySelector('#f_sc').value, 10),
          active_minutes: parseInt(edit.querySelector('#f_am').value, 10),
          respawn_minutes: parseInt(edit.querySelector('#f_rm').value, 10),
          items: txtItems.map(line => {
            const [item, mn, mx, w] = line.split(',').map(s => s.trim());
            return { item, count: [parseInt(mn, 10) || 1, parseInt(mx, 10) || 1], weight: parseInt(w, 10) || 1 };
          }),
          centers: txtCenters.map(line => {
            const p = line.split(',').map(s => parseFloat(s));
            return { pos: [p[0], p[1], p[2]], radius: p[3] || 50 };
          }),
        };
        const r = await ctx.request('zones:upsert', payload);
        if (r && r.ok) { CLPHDS.notify('Gespeichert', 'success'); await load(); }
      });
      const del = edit.querySelector('#bDel');
      if (del) del.addEventListener('click', async () => {
        const r = await ctx.request('zones:delete', { id: c.id });
        if (r && r.ok) { CLPHDS.notify('Gelöscht', 'success'); await load(); }
      });
    }
    ctx.mount.querySelector('[data-new]').addEventListener('click', () => open(null));
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }
  CLPADMIN.register('zones', render);
})();

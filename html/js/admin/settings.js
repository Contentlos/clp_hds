/* admin/settings.js — globale Settings + Export/Import + Versionssystem */
(function () {
  if (!window.CLPADMIN) return;
  function render(ctx) {
    ctx.mount.innerHTML = `
      <h2>Settings</h2>
      <div class="grid two">
        <div class="card" id="sBox">Lade…</div>
        <div class="card">
          <h3>Backup / Versionen</h3>
          <p class="meta">Exportiert die aktuelle Konfiguration als JSON-Snapshot.</p>
          <div class="row">
            <button class="btn primary" id="bExp">Export</button>
            <input type="file" id="bImp" accept="application/json" style="flex:1"/>
          </div>
          <pre id="expOut" class="log" style="max-height:280px;overflow:auto;margin-top:10px"></pre>
        </div>
      </div>`;
    const box = ctx.mount.querySelector('#sBox');
    function form(s) {
      const m = s.market || {}; const c = s.crafting || {}; const g = s.gathering || {};
      box.innerHTML = `
        <h3>Allgemein</h3>
        <div class="grid two">
          <label class="field"><label>Polizei-Jobs (komma-sep.)</label><input id="pj" value="${(s.police_jobs||[]).join(',')}"/></label>
          <label class="field"><label>Admin-Gruppen (komma-sep.)</label><input id="ag" value="${(s.admin_groups||[]).join(',')}"/></label>
          <label class="field"><label>Autosave (sec)</label><input id="as" type="number" value="${s.autosave_interval_sec||60}"/></label>
          <label class="field"><label>Log Retention (Tage)</label><input id="lr" type="number" value="${s.log_retention_days||30}"/></label>
        </div>
        <h3 style="margin-top:14px">Markt</h3>
        <div class="grid two">
          <label class="field"><label>Update Intervall (s)</label><input id="m_u" type="number" value="${m.update_interval_sec||300}"/></label>
          <label class="field"><label>Volatilität</label><input id="m_v" type="number" step="0.01" value="${m.volatility||0.18}"/></label>
          <label class="field"><label>Floor %</label><input id="m_f" type="number" step="0.01" value="${m.price_floor_pct||0.55}"/></label>
          <label class="field"><label>Ceiling %</label><input id="m_c" type="number" step="0.01" value="${m.price_ceiling_pct||1.65}"/></label>
        </div>
        <h3 style="margin-top:14px">Crafting</h3>
        <div class="grid two">
          <label class="field"><label>Perfect-Batch %</label><input id="c_p" type="number" step="0.01" value="${c.perfect_batch_chance||0.05}"/></label>
          <label class="field"><label>Quality Min</label><input id="c_qmin" type="number" value="${c.quality_min||25}"/></label>
          <label class="field"><label>Quality Max</label><input id="c_qmax" type="number" value="${c.quality_max||100}"/></label>
          <label class="field"><label>Fail destroys inputs</label>
            <select id="c_fdi"><option value="true" ${c.fail_destroys_inputs!==false?'selected':''}>Ja</option><option value="false">Nein</option></select>
          </label>
        </div>
        <h3 style="margin-top:14px">Sammelsystem</h3>
        <div class="grid two">
          <label class="field"><label>Rotation (min)</label><input id="g_r" type="number" value="${g.zone_rotation_minutes||45}"/></label>
          <label class="field"><label>Aktive Zonen max</label><input id="g_a" type="number" value="${g.active_zones_max||4}"/></label>
        </div>
        <div class="row" style="margin-top:14px"><button class="btn primary" id="save">Speichern</button></div>`;
      box.querySelector('#save').addEventListener('click', async () => {
        const get = (i) => box.querySelector(i).value;
        const payload = {
          police_jobs:     get('#pj').split(',').map(x=>x.trim()).filter(Boolean),
          admin_groups:    get('#ag').split(',').map(x=>x.trim()).filter(Boolean),
          autosave_interval_sec: parseInt(get('#as'), 10),
          log_retention_days:    parseInt(get('#lr'), 10),
          market: {
            update_interval_sec: parseInt(get('#m_u'), 10),
            volatility: parseFloat(get('#m_v')),
            price_floor_pct:   parseFloat(get('#m_f')),
            price_ceiling_pct: parseFloat(get('#m_c')),
          },
          crafting: {
            perfect_batch_chance: parseFloat(get('#c_p')),
            quality_min: parseInt(get('#c_qmin'), 10),
            quality_max: parseInt(get('#c_qmax'), 10),
            fail_destroys_inputs: get('#c_fdi') === 'true',
          },
          gathering: {
            zone_rotation_minutes: parseInt(get('#g_r'), 10),
            active_zones_max:      parseInt(get('#g_a'), 10),
          },
        };
        await ctx.request('settings:patch', payload);
        CLPHDS.notify('Gespeichert', 'success');
      });
    }
    form(CLPHDS.config('admin_settings') || {});
    CLPHDS.on('config', (c) => { if (c.name === 'admin_settings') form(c.data); });

    ctx.mount.querySelector('#bExp').addEventListener('click', async () => {
      const r = await ctx.request('admin:export', {});
      ctx.mount.querySelector('#expOut').textContent = JSON.stringify(r, null, 2);
      // Download trigger
      const blob = new Blob([JSON.stringify(r, null, 2)], { type: 'application/json' });
      const url  = URL.createObjectURL(blob);
      const a = document.createElement('a'); a.href = url; a.download = 'clp_hds_export.json'; a.click();
      URL.revokeObjectURL(url);
    });
    ctx.mount.querySelector('#bImp').addEventListener('change', async (e) => {
      const file = e.target.files[0]; if (!file) return;
      const text = await file.text();
      try {
        const data = JSON.parse(text);
        const r = await ctx.request('admin:import', data);
        if (r && r.ok) CLPHDS.notify('Import erfolgreich', 'success');
      } catch (err) { CLPHDS.notify('Ungültige JSON-Datei', 'error'); }
    });
  }
  CLPADMIN.register('settings', render);
})();

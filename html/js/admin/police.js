/* admin/police.js — Heat / Polizei Settings */
(function () {
  if (!window.CLPADMIN) return;
  function render(ctx) {
    ctx.mount.innerHTML = '<h2>Heat / Polizei</h2><div class="card" id="pBox">Lade…</div>';
    const box = ctx.mount.querySelector('#pBox');
    function form(s) {
      const h = s.heat || {};
      box.innerHTML = `
        <div class="grid two">
          <label class="field"><label>Decay / Min</label><input id="d" type="number" step="0.1" value="${h.decay_per_minute ?? 1.5}"/></label>
          <label class="field"><label>Smell-Radius (m)</label><input id="r" type="number" value="${h.smell_radius ?? 60}"/></label>
          <label class="field"><label>Smell-Threshold</label><input id="st" type="number" value="${h.smell_threshold ?? 35}"/></label>
          <label class="field"><label>Raid-Threshold</label><input id="rt" type="number" value="${h.raid_threshold ?? 80}"/></label>
          <label class="field"><label>Raid-Chance (0-1)</label><input id="rc" type="number" step="0.01" value="${h.raid_chance ?? 0.35}"/></label>
          <label class="field"><label>Strom-Faktor</label><input id="ef" type="number" step="0.01" value="${h.electricity_factor ?? 0.6}"/></label>
        </div>
        <div class="row" style="margin-top:12px"><button class="btn primary" id="save">Speichern</button></div>`;
      box.querySelector('#save').addEventListener('click', async () => {
        const v = (id) => parseFloat(box.querySelector(id).value);
        const payload = { heat: {
          decay_per_minute: v('#d'),
          smell_radius: v('#r'), smell_threshold: v('#st'),
          raid_threshold: v('#rt'), raid_chance: v('#rc'),
          electricity_factor: v('#ef'),
        }};
        await ctx.request('settings:patch', payload);
        CLPHDS.notify('Gespeichert', 'success');
      });
    }
    form(CLPHDS.config('admin_settings') || {});
    CLPHDS.on('config', (c) => { if (c.name === 'admin_settings') form(c.data); });
  }
  CLPADMIN.register('police', render);
})();

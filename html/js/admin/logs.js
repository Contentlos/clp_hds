/* admin/logs.js — Live-Audit-Log Viewer */
(function () {
  if (!window.CLPADMIN) return;
  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between"><h2>Logs</h2>
        <div class="toolbar">
          <select id="lFilter">
            <option value="">Alle Kategorien</option>
            <option>admin</option><option>labs</option><option>config</option><option>craft</option>
            <option>gather</option><option>heat</option><option>police</option>
          </select>
          <button class="btn" data-reload>Reload</button>
        </div>
      </div>
      <div class="card log" id="lOut" style="max-height:60vh;overflow:auto"></div>`;
    const out = ctx.mount.querySelector('#lOut');
    function fmt(e) {
      const ts = new Date((e.ts || 0) * 1000).toISOString().replace('T', ' ').slice(0, 19);
      const payload = e.payload ? ` ${JSON.stringify(e.payload)}` : '';
      return `<div><span class="time">${ts}</span><span class="cat">[${e.category}/${e.action}]</span>${payload} <span class="meta">${e.identifier || ''}</span></div>`;
    }
    async function load() {
      const filter = ctx.mount.querySelector('#lFilter').value;
      const r = await ctx.request('logs:list', { limit: 250, filter: filter ? { category: filter } : null });
      const entries = (r && r.entries) || [];
      out.innerHTML = entries.map(fmt).join('') || '<p class="meta">Leer.</p>';
    }
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    ctx.mount.querySelector('#lFilter').addEventListener('change', load);
    CLPHDS.on('log', (e) => { out.insertAdjacentHTML('afterbegin', fmt(e)); });
    load();
  }
  CLPADMIN.register('logs', render);
})();

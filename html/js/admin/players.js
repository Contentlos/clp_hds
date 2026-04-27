/* admin/players.js — Spieler-Management */
(function () {
  if (!window.CLPADMIN) return;
  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between"><h2>Spieler</h2><button class="btn" data-reload>Reload</button></div>
      <div class="card list" id="pList">Lade…</div>`;
    const list = ctx.mount.querySelector('#pList');
    async function load() {
      const r = await ctx.request('players:online', {});
      const players = (r && r.players) || [];
      list.innerHTML = `
        <table>
          <thead><tr><th>ID</th><th>Name</th><th>Identifier</th><th>Job</th><th>Item-Aktion</th></tr></thead>
          <tbody>
            ${players.map(p => `
              <tr>
                <td>${p.id}</td><td>${p.name}</td><td>${p.identifier}</td><td>${p.job}</td>
                <td>
                  <input data-item="${p.id}"  placeholder="item id" style="width:140px"/>
                  <input data-count="${p.id}" type="number" value="1" style="width:60px"/>
                  <button class="btn" data-give="${p.id}">+</button>
                  <button class="btn danger" data-take="${p.id}">−</button>
                </td>
              </tr>`).join('')}
          </tbody>
        </table>`;
      list.querySelectorAll('[data-give]').forEach(b => b.addEventListener('click', async () => {
        const id   = parseInt(b.dataset.give, 10);
        const item = list.querySelector(`[data-item="${id}"]`).value;
        const c    = parseInt(list.querySelector(`[data-count="${id}"]`).value, 10) || 1;
        await ctx.request('players:giveItem', { id, item, count: c });
        CLPHDS.notify('Gegeben', 'success');
      }));
      list.querySelectorAll('[data-take]').forEach(b => b.addEventListener('click', async () => {
        const id   = parseInt(b.dataset.take, 10);
        const item = list.querySelector(`[data-item="${id}"]`).value;
        const c    = parseInt(list.querySelector(`[data-count="${id}"]`).value, 10) || 1;
        await ctx.request('players:removeItem', { id, item, count: c });
        CLPHDS.notify('Entfernt', 'success');
      }));
    }
    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }
  CLPADMIN.register('players', render);
})();

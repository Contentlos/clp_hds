/* admin/labs.js — Labor-Übersicht & Verwaltung (inkl. Shell-Picker) */
(function () {
  if (!window.CLPADMIN) return;

  function render(ctx) {
    ctx.mount.innerHTML = `
      <div class="row between">
        <h2>Labore</h2>
        <button class="btn" data-reload>Reload</button>
      </div>
      <div class="card list" id="lList">Lade…</div>`;
    const list = ctx.mount.querySelector('#lList');
    let shellOpts = '';

    async function loadShells() {
      const r = await ctx.request('shells:list', {});
      const shells = (r && r.shells) || [];
      shellOpts = shells.map(s => `<option value="${s.id}">${s.label || s.id}</option>`).join('')
                || '<option value="">– keine Shells –</option>';
    }

    async function load() {
      await loadShells();
      const r = await ctx.request('labs:list', {});
      const labs = (r && r.labs) || [];
      list.innerHTML = labs.length === 0 ? '<p class="meta">Keine Labore.</p>' : `
        <table>
          <thead><tr>
            <th>ID</th><th>Owner</th><th>Shell</th><th>Heat</th>
            <th>Members</th><th>Objekte</th><th>Aktion</th>
          </tr></thead>
          <tbody>
            ${labs.map(l => `
              <tr data-id="${l.id}">
                <td>${l.id}<div class="meta">${l.label || ''}</div></td>
                <td><input value="${l.owner || ''}" data-owner="${l.id}" style="width:200px"/></td>
                <td>
                  <select data-shell="${l.id}">
                    ${shellOpts.replace(`value="${l.shell_id || l.teleport || ''}"`,
                                        `value="${l.shell_id || l.teleport || ''}" selected`)}
                  </select>
                </td>
                <td><span class="tag ${l.heat > 60 ? 'err' : l.heat > 30 ? 'warn' : 'ok'}">${l.heat || 0}</span></td>
                <td>${(l.members || []).length}</td>
                <td>${(l.objects || []).length}</td>
                <td>
                  <button class="btn" data-set-owner="${l.id}">Owner</button>
                  <button class="btn" data-set-shell="${l.id}">Shell</button>
                  <button class="btn" data-reset="${l.id}">Reset</button>
                  <button class="btn danger" data-del="${l.id}">Löschen</button>
                </td>
              </tr>`).join('')}
          </tbody>
        </table>`;

      list.querySelectorAll('[data-set-owner]').forEach(b => b.addEventListener('click', async () => {
        const id = b.dataset.setOwner;
        const inp = list.querySelector(`[data-owner="${id}"]`);
        await ctx.request('labs:setOwner', { id, identifier: inp.value });
        CLPHDS.notify('Owner geändert', 'success'); await load();
      }));
      list.querySelectorAll('[data-set-shell]').forEach(b => b.addEventListener('click', async () => {
        const id = b.dataset.setShell;
        const sel = list.querySelector(`[data-shell="${id}"]`);
        const r = await ctx.request('labs:setShell', { id, shell_id: sel.value });
        if (r && r.ok) { CLPHDS.notify('Shell geändert', 'success'); await load(); }
        else CLPHDS.notify('Fehler: ' + ((r && r.error) || 'unbekannt'), 'error');
      }));
      list.querySelectorAll('[data-reset]').forEach(b => b.addEventListener('click', async () => {
        await ctx.request('labs:reset', { id: b.dataset.reset });
        CLPHDS.notify('Reset', 'success'); await load();
      }));
      list.querySelectorAll('[data-del]').forEach(b => b.addEventListener('click', async () => {
        if (!confirm('Wirklich löschen?')) return;
        await ctx.request('labs:delete', { id: b.dataset.del });
        CLPHDS.notify('Gelöscht', 'success'); await load();
      }));
    }

    ctx.mount.querySelector('[data-reload]').addEventListener('click', load);
    load();
  }
  CLPADMIN.register('labs', render);
})();

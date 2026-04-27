/* =========================================================
 * inventory.js — Hauptpanel + Station-Ansicht (Crafting).
 * Nutzt CLPHDS.state.config + state.activePanel-Payload.
 * =======================================================*/
(function () {
  const root = document.getElementById('mainView');
  if (!root) return;

  function render(panel, payload) {
    if (panel === 'station') return renderStation(payload);
    return renderHome(payload);
  }

  function renderHome() {
    const items   = (CLPHDS.config('items')   || {}).items   || [];
    const drugs   = (CLPHDS.config('drugs')   || {}).drugs   || [];
    const prices  = CLPHDS.config('market_prices') || {};
    const labs    = (CLPHDS.config('labs')    || {}).labs    || [];

    root.innerHTML = `
      <div class="grid two">
        <div class="card">
          <h3>Drogenmarkt (live)</h3>
          <table>
            <thead><tr><th>Droge</th><th>Preis</th></tr></thead>
            <tbody>
              ${drugs.map(d => `<tr><td>${d.label}</td><td>${prices[d.id] ?? d.base_price ?? '?'}$</td></tr>`).join('')}
            </tbody>
          </table>
        </div>
        <div class="card">
          <h3>Items (${items.length})</h3>
          <p class="meta">Items werden serverseitig verwaltet. Im Admin-Panel editierbar.</p>
        </div>
      </div>
      <div class="card" style="margin-top:14px">
        <h3>Deine Labore</h3>
        ${labs.length === 0 ? '<p class="meta">Noch kein Labor vorhanden.</p>' :
          `<table><thead><tr><th>ID</th><th>Label</th><th>Heat</th><th></th></tr></thead><tbody>
            ${labs.map(l => `<tr>
              <td>${l.id}</td><td>${l.label || '-'}</td>
              <td><span class="tag ${(l.heat||0) > 60 ? 'err' : (l.heat||0) > 30 ? 'warn' : 'ok'}">${l.heat || 0}</span></td>
              <td><button class="btn" data-go-lab="${l.id}">Betreten</button></td>
            </tr>`).join('')}
          </tbody></table>`}
      </div>
    `;
    root.querySelectorAll('[data-go-lab]').forEach(btn => {
      btn.addEventListener('click', () => {
        CLPHDS.send('lab:enter', { id: btn.dataset.goLab });
        CLPHDS.hideAll();
        CLPHDS.close();
      });
    });
  }

  function renderStation(payload) {
    const lab     = payload.lab || {};
    const station = payload.station || {};
    const recipes = ((CLPHDS.config('recipes') || {}).recipes || [])
                    .filter(r => r.station === station.item);
    root.innerHTML = `
      <div class="card">
        <h3>${station.item} – Station in ${lab.label || lab.id}</h3>
        <p class="meta">Heat: <span class="tag ${(lab.heat||0) > 60 ? 'err' : 'ok'}">${lab.heat||0}</span></p>
        <h4 style="margin-top:10px">Verfügbare Rezepte</h4>
        <div class="list">
          ${recipes.length === 0 ? '<p class="meta">Keine Rezepte für diese Station.</p>' :
            recipes.map(r => `
              <div class="row-item">
                <div>
                  <strong>${r.id}</strong>
                  <div class="meta">${(r.inputs||[]).map(i => i.count + 'x ' + i.item).join(', ')}
                    → ${(r.outputs||[]).map(o => o.count + 'x ' + o.item).join(', ')}</div>
                </div>
                <span class="tag">${r.duration_sec}s</span>
                <button class="btn primary" data-craft="${r.id}">Crafting starten</button>
              </div>`).join('')}
        </div>
      </div>`;
    root.querySelectorAll('[data-craft]').forEach(btn => {
      btn.addEventListener('click', () => {
        CLPHDS.send('craft:start', {
          labId: lab.id, recipeId: btn.dataset.craft, stationUid: station.uid,
        });
      });
    });
  }

  CLPHDS.on('open', (m) => {
    if (m.panel === 'main' || m.panel === 'station') render(m.panel, m.payload || {});
  });
  CLPHDS.on('config', () => {
    if (CLPHDS.state.activePanel === 'main') render('main');
  });
})();

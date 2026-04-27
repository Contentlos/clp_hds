/* =========================================================
 * admin/app.js — Admin-Panel Router & API.
 *  - Ruft serverseitige Aktionen über send('admin:action', { action, data })
 *  - Antworten kommen als 'admin:response' Events zurück (Promise-basiert)
 * =======================================================*/
(function () {
  if (!window.CLPHDS) return;

  const tabs = {};
  const tabBtns = document.querySelectorAll('#adminNav button');
  const main    = document.getElementById('adminMain');
  const verEl   = document.getElementById('adminVersion');

  let pending = {}; // reqId -> {resolve, reject}

  function request(action, data) {
    return new Promise((resolve, reject) => {
      CLPHDS.send('admin:action', { action, data }).then((r) => {
        if (!r || !r.ok) return reject(new Error('send_failed'));
        pending[r.id] = { resolve, reject };
      });
    });
  }

  CLPHDS.on('admin', (m) => {
    if (m.kind === 'opened' && verEl && m.meta) {
      verEl.textContent = 'v' + (m.meta.version || '0.0');
    } else if (m.kind === 'response') {
      const p = pending[m.id];
      if (p) { p.resolve(m.result); delete pending[m.id]; }
    }
  });

  function register(name, render) { tabs[name] = render; }

  function show(name) {
    tabBtns.forEach(b => b.classList.toggle('active', b.dataset.tab === name));
    main.innerHTML = '';
    if (tabs[name]) {
      const ctx = { request, mount: main, refresh: () => show(name) };
      tabs[name](ctx);
    } else {
      main.innerHTML = `<p class="meta">Tab "${name}" nicht implementiert.</p>`;
    }
  }

  tabBtns.forEach(b => b.addEventListener('click', () => show(b.dataset.tab)));

  CLPHDS.on('open', (m) => { if (m.panel === 'admin') show('items'); });

  // Public API
  window.CLPADMIN = { register, request, show };
})();

/* =========================================================
 * core.js — NUI ↔ Lua Bridge, Router, Konfigcache, Notifies.
 * Globales Objekt: window.CLPHDS
 * =======================================================*/
(function () {
  const RES = (window.GetParentResourceName && GetParentResourceName()) || 'clp_hds';

  const state = {
    config: {},          // name -> data
    activePanel: null,
    pendingMinigame: null,
    pendingAdminReqs: {},
    listeners: { config: [], log: [], minigame: [], admin: [] },
  };

  // ----------------- HTTP zu Lua --------------------
  function post(name, data) {
    return fetch(`https://${RES}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data || {}),
    }).then((r) => r.json()).catch(() => ({ ok: false }));
  }
  function send(type, payload) { return post('clp', { type, payload }); }
  function close()             { return post('close', {}); }

  // ----------------- Panels -------------------------
  const $ = (sel) => document.querySelector(sel);
  function showPanel(name) {
    state.activePanel = name;
    document.querySelectorAll('.panel').forEach((p) => p.classList.add('hidden'));
    document.body.classList.remove('hidden');
    if (name === 'main')     $('#mainPanel').classList.remove('hidden');
    if (name === 'minigame') $('#minigamePanel').classList.remove('hidden');
    if (name === 'admin')    $('#adminPanel').classList.remove('hidden');
    if (name === 'station')  { $('#mainPanel').classList.remove('hidden'); }
  }
  function hideAll() {
    state.activePanel = null;
    document.querySelectorAll('.panel').forEach((p) => p.classList.add('hidden'));
    document.body.classList.add('hidden');
  }

  // ----------------- Notify -------------------------
  function notify(msg, kind = 'info') {
    const stack = document.getElementById('notifyStack');
    if (!stack) return;
    const el = document.createElement('div');
    el.className = `notify ${kind}`;
    el.textContent = msg;
    stack.appendChild(el);
    setTimeout(() => el.remove(), 4500);
  }

  // ----------------- Listener API -------------------
  function on(evt, fn) {
    state.listeners[evt] = state.listeners[evt] || [];
    state.listeners[evt].push(fn);
  }
  function emit(evt, data) {
    (state.listeners[evt] || []).forEach((fn) => { try { fn(data); } catch (e) { console.error(e); } });
  }

  // ----------------- NUI Message Handler ------------
  window.addEventListener('message', (ev) => {
    const m = ev.data || {};
    switch (m.type) {
      case 'open':
        showPanel(m.panel);
        emit('open', m);
        break;
      case 'close':
        hideAll();
        break;
      case 'notify':
        notify(m.message, m.kind);
        break;
      case 'config:push':
        state.config[m.name] = m.data;
        emit('config', { name: m.name, data: m.data });
        break;
      case 'minigame:start':
        state.pendingMinigame = m.payload || {};
        showPanel('minigame');
        emit('minigame', state.pendingMinigame);
        break;
      case 'admin:opened':
        emit('admin', { kind: 'opened', meta: m.meta });
        break;
      case 'admin:response':
        emit('admin', { kind: 'response', id: m.id, result: m.result });
        break;
      case 'admin:log':
        emit('log', m.entry);
        break;
      case 'heat:update':
        emit('heat', m.data);
        break;
    }
  });

  // ----------------- Global UI Wiring ---------------
  document.addEventListener('click', (e) => {
    const btn = e.target.closest('[data-action]');
    if (!btn) return;
    const action = btn.dataset.action;
    if (action === 'close') {
      hideAll();
      close();
    } else if (action === 'mg-cancel') {
      send('minigame:cancel');
      hideAll();
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && state.activePanel) {
      if (state.activePanel === 'minigame') {
        send('minigame:cancel');
      }
      hideAll();
      close();
    }
  });

  // ----------------- Public API ---------------------
  window.CLPHDS = {
    state, send, post, close, notify, showPanel, hideAll, on, emit,
    config(name) { return state.config[name]; },
  };
})();

/* =========================================================
 * heroin.js — Mischverhältnis-Balance Minigame
 *  - Marker driftet, Spieler muss A/D drücken um in den Zielzonen zu bleiben
 *  - Score = Anteil der Zeit alle Bars korrekt
 * =======================================================*/
(function () {
  if (!window.CLPHDS) return;
  const stage = () => document.getElementById('mgStage');
  const title = () => document.getElementById('mgTitle');
  const hint  = () => document.getElementById('mgHint');
  const score = () => document.getElementById('mgScore');

  function start(payload) {
    if (payload.minigameId !== 'heroin') return;
    title().textContent = 'Heroin – Mischverhältnis';
    hint().textContent  = 'A/D pro Bar – halte alle Marker in der grünen Zone.';

    const diff     = payload.difficulty || 0.65;
    const duration = (payload.duration || 25) * 1000;
    const barCount = 3;
    const targetW  = 80 - diff * 30; // schmaler bei höherer difficulty
    const bars = [];
    for (let i = 0; i < barCount; i++) {
      bars.push({ x: 50, drift: (Math.random() - 0.5) * diff * 80, target: 30 + Math.random() * 40, w: targetW });
    }

    stage().innerHTML = `
      <div class="balance-wrap" id="bWrap">
        ${bars.map((_, i) => `
          <div class="row">
            <div style="width:60px">${['Wasser','Säure','Base'][i]}</div>
            <div class="balance-bar" style="flex:1">
              <div class="target" id="bTarget${i}"></div>
              <div class="marker" id="bMark${i}" style="left:50%"></div>
            </div>
            <div style="width:40px;text-align:right" id="bVal${i}">50%</div>
          </div>`).join('')}
      </div>`;

    bars.forEach((b, i) => {
      const t = stage().querySelector(`#bTarget${i}`);
      t.style.left  = `${b.target}%`;
      t.style.width = `${b.w}%`;
    });

    let active = 0;
    function key(e) {
      if (e.key >= '1' && e.key <= '3') active = parseInt(e.key, 10) - 1;
      const step = 2.5;
      if (e.key === 'a' || e.key === 'A') bars[active].x = Math.max(0, bars[active].x - step);
      if (e.key === 'd' || e.key === 'D') bars[active].x = Math.min(100, bars[active].x + step);
    }
    document.addEventListener('keydown', key);

    let started = performance.now(); let last = started;
    let inMs = 0; let stopped = false;

    function tick(now) {
      if (stopped) return;
      const dt = now - last; last = now;
      let allIn = true;
      bars.forEach((b, i) => {
        b.x += b.drift * dt / 1000;
        if (b.x < 0)   { b.x = 0;   b.drift = Math.abs(b.drift); }
        if (b.x > 100) { b.x = 100; b.drift = -Math.abs(b.drift); }
        b.drift += (Math.random() - 0.5) * diff * dt / 1000 * 30;
        b.drift = Math.max(-50, Math.min(50, b.drift));
        const inside = b.x >= b.target && b.x <= b.target + b.w;
        if (!inside) allIn = false;
        const m = stage().querySelector(`#bMark${i}`);
        const v = stage().querySelector(`#bVal${i}`);
        m.style.left = `${b.x}%`;
        v.textContent = `${b.x.toFixed(0)}%`;
      });
      if (allIn) inMs += dt;
      const elapsed = now - started;
      if (elapsed >= duration) return finish(inMs / duration);
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);

    function finish(s) {
      stopped = true;
      document.removeEventListener('keydown', key);
      const sc = Math.max(0, Math.min(1, s));
      score().textContent = `Score: ${(sc * 100).toFixed(0)}%`;
      (sc > 0.5 ? CLPSND.success : CLPSND.fail)();
      CLPHDS.send('minigame:result', { minigameId: 'heroin', score: sc });
      setTimeout(() => CLPHDS.hideAll(), 700);
    }
  }

  CLPHDS.on('minigame', start);
})();

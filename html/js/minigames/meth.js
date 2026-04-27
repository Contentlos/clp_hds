/* =========================================================
 * meth.js — Temperatur-Management Minigame
 *  - Spieler muss die Temperatur in einem Zielfenster halten
 *  - Schwankungen + Drift basieren auf payload.difficulty
 *  - Score: Anteil der Zeit im Zielfenster (0..1)
 * =======================================================*/
(function () {
  if (!window.CLPHDS) return;

  const stage  = () => document.getElementById('mgStage');
  const title  = () => document.getElementById('mgTitle');
  const hint   = () => document.getElementById('mgHint');
  const score  = () => document.getElementById('mgScore');

  function start(payload) {
    if (payload.minigameId !== 'meth') return;
    title().textContent = 'Methamphetamin – Temperatur-Management';
    hint().textContent  = '↑/↓ regulieren. Halte die Temperatur im grünen Bereich.';

    const diff      = Math.max(0.1, Math.min(1.0, payload.difficulty || 0.55));
    const duration  = (payload.duration || 22) * 1000;
    const targetLo  = 35 + Math.random() * 20;       // Zielfenster zufällig
    const targetHi  = targetLo + (18 - 8 * diff);    // schwerer => schmaler
    let temp = 50;                                    // 0..100
    let drift = (Math.random() - 0.5) * 2 * diff;     // initial drift
    let inWindowMs = 0;
    const startedAt = performance.now();

    stage().innerHTML = `
      <div class="therm-wrap">
        <div class="therm">
          <div class="target" id="mTarget"></div>
          <div class="fill"   id="mFill"></div>
        </div>
        <div class="therm-info">
          <div>Ziel: ${targetLo.toFixed(0)}–${targetHi.toFixed(0)} °C</div>
          <div>Aktuell: <span id="mTemp">50</span> °C</div>
          <div class="meter"><i id="mProg"></i></div>
          <div class="knobs">
            <button class="btn" data-mg-up>↑ Heizen</button>
            <button class="btn" data-mg-dn>↓ Kühlen</button>
          </div>
          <div class="meta">Tipp: kleine Korrekturen sind besser als große Sprünge.</div>
        </div>
      </div>`;

    const target = stage().querySelector('#mTarget');
    target.style.bottom = `${targetLo * 2}px`;
    target.style.height = `${(targetHi - targetLo) * 2}px`;

    const fill = stage().querySelector('#mFill');
    const tempEl = stage().querySelector('#mTemp');
    const prog = stage().querySelector('#mProg');

    let userInput = 0;
    function up() { userInput = 0.8; }
    function dn() { userInput = -0.8; }
    stage().querySelector('[data-mg-up]').addEventListener('mousedown', up);
    stage().querySelector('[data-mg-dn]').addEventListener('mousedown', dn);
    stage().querySelector('[data-mg-up]').addEventListener('mouseup', () => userInput = 0);
    stage().querySelector('[data-mg-dn]').addEventListener('mouseup', () => userInput = 0);

    function key(e) {
      if (e.key === 'ArrowUp') up();
      if (e.key === 'ArrowDown') dn();
    }
    function keyup(e) {
      if (e.key === 'ArrowUp' || e.key === 'ArrowDown') userInput = 0;
    }
    document.addEventListener('keydown', key);
    document.addEventListener('keyup', keyup);

    let last = startedAt;
    let stopped = false;

    function tick(now) {
      if (stopped) return;
      const dt = (now - last) / 1000; last = now;

      // drift wandert leicht herum
      drift += (Math.random() - 0.5) * diff * dt * 0.4;
      drift = Math.max(-1.2, Math.min(1.2, drift));

      // Spieler-Input + Drift
      temp += (userInput * 8 + drift * 5) * dt;
      temp = Math.max(0, Math.min(100, temp));

      const inWin = temp >= targetLo && temp <= targetHi;
      if (inWin) inWindowMs += (now - last + dt * 1000);

      tempEl.textContent = temp.toFixed(0);
      fill.style.height = `${temp * 2}px`;
      const elapsed = now - startedAt;
      prog.style.width = `${Math.min(100, (elapsed / duration) * 100).toFixed(0)}%`;

      if (elapsed >= duration) return finish(inWindowMs / duration);
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);

    function finish(s) {
      stopped = true;
      document.removeEventListener('keydown', key);
      document.removeEventListener('keyup', keyup);
      const sc = Math.max(0, Math.min(1, s));
      score().textContent = `Score: ${(sc * 100).toFixed(0)}%`;
      (sc > 0.6 ? CLPSND.success : CLPSND.fail)();
      CLPHDS.send('minigame:result', { minigameId: 'meth', score: sc });
      setTimeout(() => CLPHDS.hideAll(), 700);
    }
  }

  CLPHDS.on('minigame', start);
})();

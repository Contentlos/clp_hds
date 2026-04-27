/* =========================================================
 * speed.js — Rhythm-basiertes Minigame
 *  - Notes wandern durch eine Zielzone, Spieler drückt SPACE im Fenster
 *  - Score = Trefferquote
 * =======================================================*/
(function () {
  if (!window.CLPHDS) return;
  const stage = () => document.getElementById('mgStage');
  const title = () => document.getElementById('mgTitle');
  const hint  = () => document.getElementById('mgHint');
  const score = () => document.getElementById('mgScore');

  function start(payload) {
    if (payload.minigameId !== 'speed') return;
    title().textContent = 'Speed – Rhythm';
    hint().textContent  = 'SPACE im blauen Fenster drücken!';

    const diff     = payload.difficulty || 0.45;
    const duration = (payload.duration || 18) * 1000;
    const noteCount= 6 + Math.floor(diff * 10);
    const noteSpeed= 0.08 + diff * 0.10; // px / ms

    stage().innerHTML = `<div class="rhythm-track" id="rTrack"><div class="target"></div></div>`;
    const track = stage().querySelector('#rTrack');
    const W = track.clientWidth;

    let notes = [];
    for (let i = 0; i < noteCount; i++) {
      notes.push({
        spawnAt: 600 + i * (duration / noteCount),
        x: -60, hit: false, missed: false,
      });
    }
    let hits = 0;
    let started = performance.now();
    let last = started;
    let stopped = false;

    function key(e) {
      if (e.code !== 'Space') return;
      e.preventDefault();
      // Suche aktuelle Note innerhalb Targetbox (60..120)
      for (const n of notes) {
        if (n.hit || n.missed) continue;
        if (n.x >= 30 && n.x <= 130) { n.hit = true; hits++; CLPSND.tick(); break; }
      }
    }
    document.addEventListener('keydown', key);

    function tick(now) {
      if (stopped) return;
      const dt = now - last; last = now;
      const elapsed = now - started;

      track.querySelectorAll('.note').forEach(el => el.remove());
      for (const n of notes) {
        if (n.hit || n.missed) continue;
        if (elapsed < n.spawnAt) continue;
        n.x += noteSpeed * dt;
        if (n.x > W + 60) n.missed = true;
        const el = document.createElement('div');
        el.className = 'note';
        el.style.left = `${n.x}px`;
        el.textContent = '♪';
        track.appendChild(el);
      }

      if (elapsed >= duration + 1000) return finish();
      requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);

    function finish() {
      stopped = true;
      document.removeEventListener('keydown', key);
      const sc = hits / noteCount;
      score().textContent = `Score: ${(sc * 100).toFixed(0)}%`;
      (sc > 0.6 ? CLPSND.success : CLPSND.fail)();
      CLPHDS.send('minigame:result', { minigameId: 'speed', score: sc });
      setTimeout(() => CLPHDS.hideAll(), 700);
    }
  }

  CLPHDS.on('minigame', start);
})();

/* =========================================================
 * lsd.js — Memory / Pattern Minigame
 *  - Sequenz wird abgespielt, Spieler muss sie nachklicken
 *  - Bei vielen Fehlern -> Lua triggert Halluzinationen
 * =======================================================*/
(function () {
  if (!window.CLPHDS) return;
  const stage = () => document.getElementById('mgStage');
  const title = () => document.getElementById('mgTitle');
  const hint  = () => document.getElementById('mgHint');
  const score = () => document.getElementById('mgScore');

  function start(payload) {
    if (payload.minigameId !== 'lsd') return;
    title().textContent = 'LSD – Pattern Memory';
    hint().textContent  = 'Merke dir die Reihenfolge und klicke sie nach.';

    const diff       = payload.difficulty || 0.7;
    const totalRounds= 3 + Math.floor(diff * 5);   // 3..8 Runden
    const cellCount  = 12;
    let round = 0; let success = 0;
    let pattern = []; let inputIdx = 0;

    stage().innerHTML = `
      <div class="memory-grid" id="mgrid">
        ${Array.from({ length: cellCount }).map((_, i) => `<div class="cell" data-i="${i}">${i+1}</div>`).join('')}
      </div>`;
    const grid = stage().querySelector('#mgrid');
    const cells = grid.querySelectorAll('.cell');

    function play(seq, cb) {
      let i = 0;
      cells.forEach(c => c.classList.remove('lit', 'bad', 'ok'));
      const tick = () => {
        if (i >= seq.length) { cb(); return; }
        const idx = seq[i];
        cells[idx].classList.add('lit');
        CLPSND.tick();
        setTimeout(() => { cells[idx].classList.remove('lit'); i++; setTimeout(tick, 180); }, 480 - diff * 200);
      };
      tick();
    }

    function newRound() {
      round++;
      if (round > totalRounds) return finish();
      const len = 2 + Math.floor(round * (1 + diff * 0.5));
      pattern = Array.from({ length: len }, () => Math.floor(Math.random() * cellCount));
      inputIdx = 0;
      hint().textContent = `Runde ${round}/${totalRounds} – Sequenz wird abgespielt…`;
      grid.style.pointerEvents = 'none';
      play(pattern, () => { grid.style.pointerEvents = ''; hint().textContent = 'Klicke nach.'; });
    }

    function onClick(e) {
      const cell = e.target.closest('.cell');
      if (!cell) return;
      const i = parseInt(cell.dataset.i, 10);
      const expected = pattern[inputIdx];
      if (i === expected) {
        cell.classList.add('ok'); CLPSND.tick();
        setTimeout(() => cell.classList.remove('ok'), 220);
        inputIdx++;
        if (inputIdx >= pattern.length) {
          success++;
          setTimeout(newRound, 350);
        }
      } else {
        cell.classList.add('bad'); CLPSND.fail();
        setTimeout(() => cell.classList.remove('bad'), 220);
        setTimeout(newRound, 600);
      }
    }
    grid.addEventListener('click', onClick);

    function finish() {
      grid.removeEventListener('click', onClick);
      const sc = success / totalRounds;
      score().textContent = `Score: ${(sc * 100).toFixed(0)}%`;
      (sc > 0.5 ? CLPSND.success : CLPSND.fail)();
      CLPHDS.send('minigame:result', { minigameId: 'lsd', score: sc });
      setTimeout(() => CLPHDS.hideAll(), 700);
    }

    newRound();
  }

  CLPHDS.on('minigame', start);
})();

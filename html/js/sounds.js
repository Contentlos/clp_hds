/* =========================================================
 * sounds.js — Mini Web-Audio Engine.
 * Spielt Click/Success/Fail Sounds. Asset-Dateien sind Platzhalter.
 * =======================================================*/
(function () {
  const ctx = (window.AudioContext || window.webkitAudioContext) ? new (window.AudioContext || window.webkitAudioContext)() : null;
  function tone(freq, dur = 0.08, type = 'sine', gain = 0.05) {
    if (!ctx) return;
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = type; o.frequency.value = freq;
    g.gain.value = gain;
    o.connect(g).connect(ctx.destination);
    o.start();
    o.stop(ctx.currentTime + dur);
  }
  window.CLPSND = {
    click:   () => tone(880, 0.04, 'square', 0.03),
    success: () => { tone(660, 0.08); setTimeout(() => tone(990, 0.10), 80); },
    fail:    () => { tone(220, 0.18, 'sawtooth'); },
    tick:    () => tone(1500, 0.02, 'square', 0.02),
  };
  document.addEventListener('click', (e) => {
    if (e.target.closest('.btn')) window.CLPSND.click();
  });
})();

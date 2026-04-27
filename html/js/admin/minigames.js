/* admin/minigames.js — Minigame Editor + Test Mode */
(function () {
  if (!window.CLPADMIN) return;

  function render(ctx) {
    ctx.mount.innerHTML = `
      <h2>Minigames</h2>
      <p class="meta">Schwierigkeit & Dauer pro Droge werden im <strong>Drogen</strong>-Tab verwaltet.
      Hier kannst du Minigames im Vorschau-Modus testen oder Crafting-Ergebnisse simulieren.</p>
      <div class="grid two">
        <div class="card">
          <h3>Vorschau-Modus</h3>
          <div class="row">
            <select id="mgPick">
              <option value="meth">Meth – Temperatur</option>
              <option value="speed">Speed – Rhythm</option>
              <option value="heroin">Heroin – Balance</option>
              <option value="lsd">LSD – Memory</option>
            </select>
            <input id="mgDiff" type="number" step="0.05" value="0.5" style="width:80px"/>
            <input id="mgDur"  type="number" value="20" style="width:80px"/>
            <button class="btn primary" id="mgRun">Testen</button>
          </div>
          <p class="meta" style="margin-top:8px">Im Test-Modus werden keine Items konsumiert.</p>
        </div>
        <div class="card">
          <h3>Crafting-Simulation</h3>
          <div class="col">
            <input id="simRecipe" placeholder="Rezept-ID"/>
            <input id="simScore" type="number" step="0.01" value="0.7"/>
            <button class="btn" id="simRun">Berechnen</button>
            <pre id="simOut" class="log" style="white-space:pre-wrap"></pre>
          </div>
        </div>
      </div>`;

    ctx.mount.querySelector('#mgRun').addEventListener('click', () => {
      const id  = ctx.mount.querySelector('#mgPick').value;
      const dif = parseFloat(ctx.mount.querySelector('#mgDiff').value);
      const dur = parseInt(ctx.mount.querySelector('#mgDur').value, 10);
      // Triggert lokal das gleiche Minigame ohne Server-Roundtrip
      window.postMessage({ type: 'minigame:start', payload: { minigameId: id, difficulty: dif, duration: dur } }, '*');
      document.getElementById('minigamePanel').classList.remove('hidden');
    });

    ctx.mount.querySelector('#simRun').addEventListener('click', async () => {
      const rid = ctx.mount.querySelector('#simRecipe').value;
      const sc  = parseFloat(ctx.mount.querySelector('#simScore').value);
      const r = await ctx.request('test:simulateCraft', { recipeId: rid, score: sc });
      ctx.mount.querySelector('#simOut').textContent = JSON.stringify(r, null, 2);
    });
  }

  CLPADMIN.register('minigames', render);
})();

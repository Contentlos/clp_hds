/* placement.js — UI Helfer rund um Object-Platzierung.
 * Die eigentliche 3D-Vorschau läuft im Lua-Client (placement.lua).
 * Diese Datei zeigt ggf. Hinweise/Statusbar während der Platzierung. */
(function () {
  CLPHDS.on('open', (m) => {
    if (m.panel !== 'placement') return;
    CLPHDS.notify('Platziere Objekt — [E] OK / [Q] Drehen / [X] Abbruch', 'info');
  });
})();

# clp_hds — Hardcore Drugs System

Modulares, ingame-konfigurierbares Drogen-Crafting-Framework für **FiveM / ESX**.
Ersetzt klassische `config.json`-Setups durch ein vollständiges Live-Config-System
mit Admin-Panel, Audit-Log und Hot-Reload (kein Server-Restart nötig).

> **Status:** v0.1.0 – produktionsähnliche Foundation. Crafting/Minigames/Admin-Panel/Live-Sync sind funktional.
> Balancing, Sound-Assets und MLO-Innenräume sind als TODOs / Konfiguration ausgelegt.

---

## Features

- **4 Drogen** (Meth, Speed, Heroin, LSD) mit eigener Produktionskette `Roh → Zwischen → End`
- **4 Minigames** (Temperatur, Rhythm, Mischverhältnis, Memory) – alle NUI, modular
- **Labor-System** mit Teleport-Instanz, Object-Placement (Ghost/Rotation/Grid-Snap),
  Auf-/Abbau-Animationen, Schnell-Abbau bei Razzia
- **Rechtesystem**: Owner / Member / Worker pro Labor + Admin-Level
- **Dynamische Sammelzonen** mit Rotation, gewichteter Loot-Tabelle, Map-Blip
- **Heat / Polizei**: Geruchs-Trigger, Stromfaktor, Raid-Wahrscheinlichkeit
- **Dynamische Marktpreise** (Volatilität, Floor/Ceiling)
- **Item-System** mit Gewicht, Qualität, Haltbarkeit
- **Admin-Panel** (Glass UI, Drag&Drop, Sounds) mit:
  Items / Rezepte / Drogen / Minigames / Labore / Spieler / Heat / Sammelzonen /
  Logs / Settings + Export/Import
- **Audit-Log** für jede Adminaktion + Live-Push an Panels
- **Live-Sync** aller Configs ohne Restart
- **Halluzinations-Effekte** bei LSD-Fehlschlag (postfx + timecycle)

---

## Ordnerstruktur

```
clp_hds/
├── fxmanifest.lua
├── README.md
├── LICENSE
├── config/
│   └── default_config.lua          # Bootstrap-Defaults
├── data/                           # Persistente JSON-Stores
│   ├── items.json
│   ├── recipes.json
│   ├── drugs.json
│   ├── labs.json
│   ├── zones.json
│   ├── admin_settings.json
│   └── logs.json
├── shared/
│   ├── constants.lua               # Events, Limits, Adminlevel-Enums
│   ├── utils.lua                   # Helfer (deepcopy, weighted, uuid…)
│   └── bridge.lua                  # ESX Bridge (1 Datei = QB-Port)
├── server/
│   ├── storage.lua                 # JSON Read/Write (atomar)
│   ├── logging.lua                 # Audit-Log
│   ├── live_config.lua             # zentrale Config + Broadcast
│   ├── items.lua                   # Item-Index
│   ├── inventory.lua               # ESX/ox_inventory Adapter
│   ├── permissions.lua             # Lab-ACL + Admin-Level
│   ├── labs.lua                    # CRUD + Heat
│   ├── placement.lua               # Object-Placement Validierung
│   ├── crafting.lua                # Crafting-Pipeline
│   ├── gathering.lua               # Sammelzonen + Rotation
│   ├── heat.lua                    # Decay + Smell-Broadcast
│   ├── police.lua                  # Raid + Konfiszieren
│   ├── market.lua                  # dynamische Preise
│   ├── admin.lua                   # Admin-Action-Router
│   └── main.lua                    # Bootstrap + Befehle
├── client/
│   ├── live_config.lua
│   ├── nui.lua                     # NUI-Bus
│   ├── instance.lua                # Teleport in/aus Labor
│   ├── placement.lua               # Ghost-Vorschau
│   ├── labs.lua                    # Spawn + Interaktion
│   ├── crafting.lua
│   ├── minigames.lua               # Minigame-Bridge
│   ├── gathering.lua               # Blips + Harvest
│   ├── heat.lua
│   ├── police.lua
│   ├── halluc.lua                  # LSD-Postfx
│   ├── admin.lua                   # NUI-Bridge fürs Admin-Panel
│   └── main.lua                    # Befehle, Notifys
└── html/                           # NUI
    ├── index.html
    ├── admin.html                  # Standalone-Variante (browser-testbar)
    ├── css/{common,glass,minigames,admin}.css
    ├── js/
    │   ├── core.js                 # Bridge + Router
    │   ├── sounds.js               # Web-Audio Tones
    │   ├── inventory.js            # Hauptpanel + Stationsansicht
    │   ├── placement.js
    │   ├── minigames/{meth,speed,heroin,lsd}.js
    │   └── admin/
    │       ├── app.js
    │       ├── items.js / recipes.js / drugs.js
    │       ├── minigames.js / labs.js / players.js
    │       ├── police.js  / zones.js / logs.js
    │       └── settings.js
    └── assets/{sounds,img}/        # Platzhalter — eigene Assets hier ablegen
```

---

## Installation

1. Voraussetzungen: laufender FiveM-Server mit **`es_extended`** (≥ 1.10) und
   *optional* **`ox_inventory`** (wird automatisch erkannt).
2. Resource in `resources/[clp]/clp_hds` ablegen (oder klonen).
3. In der `server.cfg` adden:
   ```cfg
   ensure clp_hds
   add_ace group.admin       clp_hds.admin       allow
   add_ace group.superadmin  clp_hds.superadmin  allow
   ```
4. **Erststart**: Wenn `data/*.json` schon mitgeliefert ist, läuft das System sofort.
   Editieren passiert ingame über das Admin-Panel.

---

## In-Game Befehle

| Befehl | Beschreibung |
|---|---|
| `/clp` (`F6`) | Hauptmenü (Markt, eigene Labore) |
| `/clp_admin_open` (`F7`) | Admin-Panel öffnen (nur Berechtigte) |
| `/clp_create_lab <kind> <label>` | Aktuelles Spielerkoord = Anchor, neues Labor anlegen |
| `/clp_enter_lab <labId>` | Labor betreten |
| `/clp_leave` | Labor verlassen |
| `/clp_place <stationItemId> <labId>` | Object-Platzierung starten (E/Q/X) |
| `/clp_giveStation <itemId> <count>` | (Admin) Stations-Item geben |

---

## Architektur-Highlights

### Live-Config statt config.json
Alle Werte (Items, Rezepte, Drogen, Heat-Schwellen, Zonen …) liegen in `data/*.json`
und werden durch `server/live_config.lua` verwaltet. Änderungen aus dem Admin-Panel
gehen über `clp_hds:admin:action` an den Server, werden validiert und atomar persistiert,
danach via `clp_hds:config:push` an alle Clients verteilt → **kein Restart nötig**.

### Sicherheits-Modell
- Jede Adminaktion läuft über `server/admin.lua` und durchläuft `permissions.lua`.
- Felder aus `admin_settings.broadcast_blacklist` (z. B. PIN-Hashes) werden NIE an Clients gesendet.
- Crafting-Inputs werden serverseitig konsumiert, **nicht** im Client.
- Score aus Minigames wird auf `0..1` geclamped, Server entscheidet über Erfolg/Quality.
- Vollständiges Audit-Log in `data/logs.json` (rotierend nach `log_retention_days`).

### Erweiterbar
- Neue Droge ⇒ Eintrag in `data/drugs.json` + neues Rezept in `data/recipes.json` (alles ingame).
- Neues Minigame ⇒ neue Datei `html/js/minigames/<name>.js`, registriert sich auf `CLPHDS.on('minigame', …)`.
- Neuer Adminbereich ⇒ neue Datei `html/js/admin/<tab>.js` mit `CLPADMIN.register('xy', renderFn)`.

### Shells / MLOs (Innenräume für Labore)
Shells werden in `data/shells.json` gepflegt und sind im Admin-Panel unter
**Shells / MLOs** vollständig live editierbar (kein Restart nötig).

Eine Shell-Definition:
```jsonc
{
  "id":           "shell_meth_lab",        // muss eindeutig sein
  "label":        "Meth Lab Interior",
  "kind":         "warehouse",             // apartment|house|warehouse|bunker|custom
  "ipl":          "v_methlab",             // optional, wird via RequestIpl geladen
  "interior_id":  null,                    // optional, GetInteriorAtCoords automatisch
  "teleport_in":  { "x": 1015.0, "y": -3097.0, "z": -39.0, "h": 90.0 },
  "teleport_out": null,                    // null = nutze lab.anchor (Aussenposition)
  "place_bounds": { "min": [-15,-15,-2], "max": [15,15,6] },
  "fade_ms":      500,
  "doors":        []                       // optional fuer Raid-System
}
```

Workflow für neue MLOs:
1. Im Admin-Panel **Shells / MLOs → Neue Shell**.
2. ID, Label, Typ und (falls nötig) IPL eintragen.
3. Zum Innenraum-Spawnpunkt fahren / fly-cammen, dann
   **„Aktuelle Pos"** klicken → Server liest Koordinaten + Heading des Spielers
   serverseitig aus und füllt das Feld.
4. **Speichern** → Live-Push an alle Clients.
5. Optional **Test-Teleport** klickt den Admin sofort in die Shell, ohne ein Lab zu öffnen.
6. Im Tab **Labore** kann man pro Lab via Dropdown die Shell zuweisen → wirkt
   beim nächsten Eintreten ohne Restart.

Beim Eintreten in ein Lab löst `client/instance.lua` die Shell auf (1. `data/shells.json`,
2. legacy `admin_settings.labs.teleport_targets`, 3. hartcodierter Default), lädt bei
Bedarf den IPL und teleportiert den Spieler.

---

## TODO / Bekannte Lücken

- **Sound-Assets** sind aktuell synthetische Web-Audio-Tones. Eigene `.ogg`-Dateien können in `html/assets/sounds/` ergänzt werden.
- **Innenräume**: das System nutzt einen festen Shell-Punkt (`admin_settings.labs.teleport_targets`). MLOs/Custom Shells bitte je nach Server ergänzen.
- **Anti-Cheat-Härtung**: Basisvalidierung ist serverseitig vorhanden; weitergehende Maßnahmen (Rate-Limits, Movement-Checks beim Crafting) sind als nächste Iteration empfohlen.
- **Balancing**: Mengen, Preise und Heat-Werte sind sinnvolle Defaults, aber an dein Servermodell anzupassen.

---

## Dev / Testen

Die NUI lässt sich auch ohne FiveM testen:
```bash
cd html && python3 -m http.server 8080
# danach:  http://localhost:8080/admin.html
```
Im Browser sind Lua-Calls natürlich No-Ops, aber Layout, Tabs und Drag&Drop funktionieren.

---

## Lizenz

MIT — siehe [LICENSE](./LICENSE).

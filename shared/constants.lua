-- ============================================================
--  shared/constants.lua
--  Statische Konstanten, die niemals zur Laufzeit veränderbar sein müssen.
--  Alles was IM ADMIN-PANEL editierbar sein soll, gehört NICHT hierher,
--  sondern in data/*.json (verwaltet via server/live_config.lua).
-- ============================================================

CLPHDS = CLPHDS or {}

CLPHDS.RESOURCE_NAME = GetCurrentResourceName()

-- Versionsstring – wird in Logs / Admin-UI angezeigt.
CLPHDS.VERSION = '0.1.0'

-- Globale Eventnamen (Konvention: clp_hds:<domain>:<action>)
CLPHDS.EVT = {
    -- Live-Config Sync (Server -> Client Broadcast)
    CONFIG_PUSH       = 'clp_hds:config:push',
    CONFIG_REQUEST    = 'clp_hds:config:request',

    -- Labor / Instanz
    LAB_ENTER         = 'clp_hds:lab:enter',
    LAB_LEAVE         = 'clp_hds:lab:leave',
    LAB_SYNC          = 'clp_hds:lab:sync',
    LAB_PLACE_OBJECT  = 'clp_hds:lab:placeObject',
    LAB_REMOVE_OBJECT = 'clp_hds:lab:removeObject',
    LAB_RAID          = 'clp_hds:lab:raid',
    LAB_DESTROY       = 'clp_hds:lab:destroy',

    -- Crafting / Minigames
    CRAFT_START       = 'clp_hds:craft:start',
    CRAFT_FINISH      = 'clp_hds:craft:finish',
    MINIGAME_RESULT   = 'clp_hds:minigame:result',

    -- Sammelsystem
    GATHER_REQUEST    = 'clp_hds:gather:request',
    GATHER_RESULT     = 'clp_hds:gather:result',
    GATHER_ZONES      = 'clp_hds:gather:zones',

    -- Heat / Polizei
    HEAT_UPDATE       = 'clp_hds:heat:update',
    POLICE_ALERT      = 'clp_hds:police:alert',
    POLICE_RAID_START = 'clp_hds:police:raidStart',

    -- Admin
    ADMIN_OPEN        = 'clp_hds:admin:open',
    ADMIN_ACTION      = 'clp_hds:admin:action',
    ADMIN_LOG         = 'clp_hds:admin:log',

    -- NUI
    NUI_OPEN          = 'clp_hds:nui:open',
    NUI_CLOSE         = 'clp_hds:nui:close',
}

-- Admin Stufen
CLPHDS.ADMIN_LEVELS = {
    NONE       = 0,
    MODERATOR  = 1,
    ADMIN      = 2,
    SUPERADMIN = 3,
}

-- Rollen pro Labor
CLPHDS.LAB_ROLES = {
    NONE   = 0,
    WORKER = 1,
    MEMBER = 2,
    OWNER  = 3,
}

-- Standard-Drogen-IDs (in data/drugs.json gepflegt – diese Konstanten dienen
-- nur als Referenz / Default-Bootstrap, keine Hardcoded Logik!).
CLPHDS.DRUG_IDS = {
    METH   = 'meth',
    SPEED  = 'speed',
    HEROIN = 'heroin',
    LSD    = 'lsd',
}

-- Item-Kategorien
CLPHDS.ITEM_TYPES = {
    RAW         = 'raw',         -- Rohstoff
    INTERMEDIATE= 'intermediate',-- Zwischenprodukt
    FINAL       = 'final',       -- Endprodukt (verkaufsfertig)
    TOOL        = 'tool',        -- Werkzeug
    STATION     = 'station',     -- Platzierbares Objekt (Tisch, Chemie, Lager)
}

-- Maximale Werte – harte Caps gegen Exploits
CLPHDS.LIMITS = {
    MAX_LABS_PER_OWNER       = 3,
    MAX_HOUSE_LABS           = 1,
    MAX_OBJECTS_PER_LAB      = 32,
    MAX_LAB_MEMBERS          = 16,
    MAX_INVENTORY_WEIGHT_KG  = 60,
    MAX_QUALITY              = 100,
    MAX_HEAT                 = 100,
}

return CLPHDS

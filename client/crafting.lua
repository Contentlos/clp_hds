-- ============================================================
--  client/crafting.lua
--  Brücke zwischen Station-NUI und Server-Crafting.
-- ============================================================

CLPHDS = CLPHDS or {}
local N = CLPHDS.nui

-- Crafting starten -> Server validiert + triggert Minigame
N.on('craft:start', function(payload)
    TriggerServerEvent(CLPHDS.EVT.CRAFT_START, payload.labId, payload.recipeId, payload.stationUid)
    return { ok = true }
end)

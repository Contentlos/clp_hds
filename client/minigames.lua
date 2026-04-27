-- ============================================================
--  client/minigames.lua
--  Triggert das passende Minigame im NUI und wartet auf das Ergebnis.
-- ============================================================

CLPHDS = CLPHDS or {}
local N = CLPHDS.nui
local U = CLPHDS.util
local B = CLPHDS.bridge

RegisterNetEvent('clp_hds:minigame:start', function(payload)
    SetNuiFocus(true, true)
    SendNUIMessage({ type = 'minigame:start', payload = payload })
end)

-- NUI -> Lua Result
N.on('minigame:result', function(payload)
    SetNuiFocus(false, false)
    local score = tonumber(payload.score) or 0
    TriggerServerEvent(CLPHDS.EVT.MINIGAME_RESULT, score)

    -- LSD: Bei sehr schlechtem Score Halluzinationen triggern
    if (payload.minigameId == 'lsd') and score < 0.4 then
        TriggerEvent('clp_hds:halluc:start', math.floor((1 - score) * 30) + 5)
    end
    return { ok = true }
end)

N.on('minigame:cancel', function()
    SetNuiFocus(false, false)
    TriggerServerEvent(CLPHDS.EVT.MINIGAME_RESULT, 0)
    return { ok = true }
end)

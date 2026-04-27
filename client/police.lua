-- ============================================================
--  client/police.lua
--  Cop-Seite: Smell-/Raid-Alerts, Door-Break, Konfiszieren-NUI.
-- ============================================================

CLPHDS = CLPHDS or {}
local B = CLPHDS.bridge
local U = CLPHDS.util

RegisterNetEvent(CLPHDS.EVT.POLICE_ALERT, function(payload)
    if not B.isCop() then return end
    local p = payload.anchor or {}
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(('Verdächtiger Geruch (Heat %d)'):format(payload.heat or 0))
    EndTextCommandThefeedPostTicker(false, true)
    -- temporärer Blip
    if p.x then
        local blip = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(blip, 51); SetBlipColour(blip, 1); SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('clp_hds Geruch')
        EndTextCommandSetBlipName(blip)
        SetTimeout(60000, function() RemoveBlip(blip) end)
    end
end)

RegisterNetEvent(CLPHDS.EVT.LAB_RAID, function(payload)
    if not B.isCop() then return end
    B.notify(('RAID: Labor %s'):format(payload.lab), 'error')
    local p = payload.anchor or {}
    if p.x then
        local blip = AddBlipForCoord(p.x, p.y, p.z)
        SetBlipSprite(blip, 84); SetBlipColour(blip, 1); SetBlipFlashes(blip, true)
        BeginTextCommandSetBlipName('STRING'); AddTextComponentSubstringPlayerName('clp_hds Raid')
        EndTextCommandSetBlipName(blip)
        SetTimeout(120000, function() RemoveBlip(blip) end)
    end
end)

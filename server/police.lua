-- ============================================================
--  server/police.lua
--  Polizei-Interaktionen: Door-Break, Raid, Konfiszieren.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.police = {}

local PO = CLPHDS.police
local LB = CLPHDS.labs
local B  = CLPHDS.bridge
local L  = CLPHDS.logging

AddEventHandler(CLPHDS.EVT.POLICE_RAID_START, function(labId)
    local lab = LB.get(labId)
    if not lab then return end
    local players = B.getOnlinePlayers()
    for _, pid in ipairs(players) do
        if B.isCop(pid) then
            TriggerClientEvent(CLPHDS.EVT.LAB_RAID, pid, {
                lab    = labId,
                anchor = lab.anchor,
            })
        end
    end
    L.write('police', 'raid_dispatch', { lab = labId, heat = lab.heat })
end)

-- Cop bricht in das Labor ein -> nach Erfolg wird Inventar konfisziert
RegisterNetEvent('clp_hds:police:confiscate', function(labId)
    local src = source
    if not B.isCop(src) then return end
    local lab = LB.get(labId)
    if not lab then return end

    -- alle Items in Cop-Inventar überführen (capped)
    for _, e in ipairs(lab.inventory or {}) do
        B.addItem(src, e.item, e.count, e.meta)
    end
    LB.update(labId, { inventory = {} }, src)
    LB.addHeat(labId, -50, src)
    L.write('police', 'confiscate', { lab = labId, by = src })
    B.notify(src, 'Lager konfisziert', 'success')
    TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, labId, LB.get(labId))
end)

RegisterNetEvent('clp_hds:police:destroy', function(labId)
    local src = source
    if not B.isCop(src) then return end
    LB.delete(labId, src)
    L.write('police', 'destroy', { lab = labId, by = src })
    B.notify(src, 'Labor zerstört', 'success')
    TriggerClientEvent(CLPHDS.EVT.LAB_DESTROY, -1, labId)
end)

return PO

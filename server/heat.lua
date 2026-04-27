-- ============================================================
--  server/heat.lua
--  Hitze-Decay + Smell-Broadcast.
--  Wenn der Hitze-Wert eines Labors einen Schwellenwert übersteigt,
--  werden Cops in der Nähe gewarnt und Raid-Wahrscheinlichkeit steigt.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.heat = {}

local H = CLPHDS.heat
local C = CLPHDS.config
local LB = CLPHDS.labs
local B  = CLPHDS.bridge
local U  = CLPHDS.util
local L  = CLPHDS.logging

CreateThread(function()
    while true do
        Wait(60 * 1000)
        local cfg = C.get('admin_settings') or {}
        local h   = cfg.heat or {}
        LB.decayHeatAll(h.decay_per_minute or 1.5)

        local list = LB.list()
        TriggerClientEvent(CLPHDS.EVT.HEAT_UPDATE, -1, (function()
            local out = {}
            for _, l in ipairs(list) do
                out[l.id] = { heat = l.heat or 0, anchor = l.anchor }
            end
            return out
        end)())

        for _, lab in ipairs(list) do
            if (lab.heat or 0) >= (h.smell_threshold or 35) then
                -- Smell-Alert: alle Cops in Reichweite informieren
                local players = B.getOnlinePlayers()
                for _, pid in ipairs(players) do
                    if B.isCop(pid) then
                        TriggerClientEvent(CLPHDS.EVT.POLICE_ALERT, pid, {
                            type   = 'smell',
                            lab    = lab.id,
                            anchor = lab.anchor,
                            heat   = lab.heat,
                            radius = h.smell_radius or 60.0,
                        })
                    end
                end
            end

            if (lab.heat or 0) >= (h.raid_threshold or 80) and U.chance(h.raid_chance or 0.35) then
                L.write('heat', 'raid_triggered', { lab = lab.id, heat = lab.heat })
                TriggerEvent(CLPHDS.EVT.POLICE_RAID_START, lab.id)
            end
        end
    end
end)

return H

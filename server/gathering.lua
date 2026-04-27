-- ============================================================
--  server/gathering.lua
--  Dynamische Sammelzonen mit Rotation.
--  Jeder Zone wird zu Aktivierungszeit ein zufälliger "center" gewählt.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.gather = {}

local G = CLPHDS.gather
local C = CLPHDS.config
local U = CLPHDS.util
local I = CLPHDS.items
local B = CLPHDS.bridge
local L = CLPHDS.logging

local _active = {} -- zoneId -> { center, expires_at, picked }

local function rebuild()
    _active = {}
    local cfg = C.get('admin_settings') or {}
    cfg = cfg.gathering or { active_zones_max = 4 }
    local zones = (C.get('zones') or {}).zones or {}

    -- Zufällige Auswahl aus den definierten Zonen
    local pool = U.deepcopy(zones)
    local n = math.min(#pool, cfg.active_zones_max or 4)
    for _ = 1, n do
        if #pool == 0 then break end
        local idx = math.random(#pool)
        local z = table.remove(pool, idx)
        if z.centers and #z.centers > 0 then
            local c = z.centers[math.random(#z.centers)]
            _active[z.id] = {
                zone     = z,
                center   = c,
                expires_at = os.time() + ((z.active_minutes or 30) * 60),
            }
        end
    end
end

function G.publicState()
    local out = {}
    for id, a in pairs(_active) do
        out[id] = {
            zoneId  = id,
            label   = a.zone.label,
            pos     = a.center.pos,
            radius  = a.center.radius,
            expires = a.expires_at,
        }
    end
    return out
end

-- Spieler harvested an einer aktiven Zone
RegisterNetEvent(CLPHDS.EVT.GATHER_REQUEST, function(zoneId, position)
    local src = source
    local a = _active[zoneId]
    if not a then return B.notify(src, 'Zone nicht aktiv', 'error') end
    local pos = a.center.pos
    local d = math.sqrt(((position[1] or position.x) - pos[1])^2
                      + ((position[2] or position.y) - pos[2])^2)
    if d > (a.center.radius or 50) + 5.0 then
        return B.notify(src, 'Außerhalb der Zone', 'error')
    end
    -- Item ziehen
    local choices = {}
    for _, it in ipairs(a.zone.items or {}) do
        table.insert(choices, { weight = it.weight or 1, value = it })
    end
    local pick = U.weighted(choices); if not pick then return end
    local count = type(pick.count) == 'table'
                  and math.random(pick.count[1] or 1, pick.count[2] or 1)
                  or (pick.count or 1)
    local item = I.get(pick.item)
    if not item then return end
    local meta = {}
    if item.quality then meta.quality = math.random(40, 80) end
    if item.decay_hours and item.decay_hours > 0 then meta.decay_at = os.time() + item.decay_hours * 3600 end
    B.addItem(src, pick.item, count, meta)
    B.notify(src, ('+%d %s'):format(count, item.label), 'success')
    L.write('gather', 'pick', { zone = zoneId, item = pick.item, count = count }, src)
    TriggerClientEvent(CLPHDS.EVT.GATHER_RESULT, src, zoneId, pick.item, count)
end)

RegisterNetEvent(CLPHDS.EVT.GATHER_ZONES, function()
    TriggerClientEvent(CLPHDS.EVT.GATHER_ZONES, source, G.publicState())
end)

-- Rotation
CreateThread(function()
    Wait(2000)
    rebuild()
    TriggerClientEvent(CLPHDS.EVT.GATHER_ZONES, -1, G.publicState())

    local cfg = C.get('admin_settings') or {}
    local rotMin = (cfg.gathering and cfg.gathering.zone_rotation_minutes) or 45

    while true do
        Wait(rotMin * 60 * 1000)
        rebuild()
        TriggerClientEvent(CLPHDS.EVT.GATHER_ZONES, -1, G.publicState())
    end
end)

return G

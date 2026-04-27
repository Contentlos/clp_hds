-- ============================================================
--  client/gathering.lua
--  Zeigt aktive Sammelzonen auf der Map (Blip + Marker) und
--  erlaubt Harvesting via E.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.gather = {}

local G = CLPHDS.gather
local U = CLPHDS.util
local B = CLPHDS.bridge

local _state  = {}
local _blips  = {}

local function clearBlips()
    for _, b in pairs(_blips) do RemoveBlip(b) end
    _blips = {}
end

local function rebuildBlips()
    clearBlips()
    for id, z in pairs(_state) do
        local p = z.pos
        local blip = AddBlipForRadius(p[1], p[2], p[3], (z.radius or 50) * 1.0)
        SetBlipColour(blip, 2)
        SetBlipAlpha(blip, 90)
        local mb = AddBlipForCoord(p[1], p[2], p[3])
        SetBlipSprite(mb, 568)
        SetBlipColour(mb, 25)
        SetBlipScale(mb, 0.85)
        SetBlipAsShortRange(mb, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(z.label or 'Sammelzone')
        EndTextCommandSetBlipName(mb)
        _blips[#_blips+1] = blip
        _blips[#_blips+1] = mb
    end
end

RegisterNetEvent(CLPHDS.EVT.GATHER_ZONES, function(state)
    _state = state or {}
    rebuildBlips()
end)

CreateThread(function()
    while true do
        Wait(500)
        local ped = PlayerPedId()
        local p   = GetEntityCoords(ped)
        for id, z in pairs(_state) do
            local pos = z.pos
            local d = #(p - vector3(pos[1], pos[2], pos[3]))
            if d < (z.radius or 50) then
                Wait(0)
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('[E] Sammeln in: ' .. (z.label or id))
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) then
                    TriggerServerEvent(CLPHDS.EVT.GATHER_REQUEST, id, { p.x, p.y, p.z })
                end
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then clearBlips() end
end)

return G

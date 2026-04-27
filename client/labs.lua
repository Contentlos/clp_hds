-- ============================================================
--  client/labs.lua
--  Spawnt platzierte Stations in der Labor-Instanz, behandelt
--  Interaktion (E zum Öffnen der Crafting-/Lager-NUI).
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.labs = {}

local LB   = CLPHDS.labs
local INST = CLPHDS.instance
local N    = CLPHDS.nui
local U    = CLPHDS.util
local B    = CLPHDS.bridge

local _spawned = {} -- uid -> entity

local function clearAll()
    for uid, ent in pairs(_spawned) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    _spawned = {}
end

local function spawnObject(o)
    local hash = GetHashKey(o.model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then return end
    end
    local ent = CreateObjectNoOffset(hash, o.pos.x, o.pos.y, o.pos.z, false, false, false)
    SetEntityHeading(ent, o.rot or 0.0)
    FreezeEntityPosition(ent, true)
    SetModelAsNoLongerNeeded(hash)
    _spawned[o.uid] = ent
end

local function syncLab(lab)
    clearAll()
    if not lab then return end
    for _, o in ipairs(lab.objects or {}) do spawnObject(o) end
end

AddEventHandler('clp_hds:lab:entered', function(lab) syncLab(lab) end)
AddEventHandler('clp_hds:lab:left', function() clearAll() end)

RegisterNetEvent(CLPHDS.EVT.LAB_SYNC, function(labId, lab)
    local cur = INST.current()
    if cur and cur.id == labId then syncLab(lab) end
end)

-- Interaktion: bei naher Station E drücken -> NUI öffnet
CreateThread(function()
    while true do
        Wait(0)
        if INST.isInside() then
            local ped = PlayerPedId()
            local p   = GetEntityCoords(ped)
            local nearest, dist
            for uid, ent in pairs(_spawned) do
                if DoesEntityExist(ent) then
                    local ec = GetEntityCoords(ent)
                    local d = #(p - ec)
                    if d < (dist or 2.0) then dist = d; nearest = uid end
                end
            end
            if nearest then
                BeginTextCommandDisplayHelp('STRING')
                AddTextComponentSubstringPlayerName('[E] Station benutzen')
                EndTextCommandDisplayHelp(0, false, true, -1)
                if IsControlJustReleased(0, 38) then
                    local lab = INST.current()
                    local obj
                    for _, o in ipairs(lab.objects or {}) do if o.uid == nearest then obj = o break end end
                    if obj then
                        N.toggle('station', { lab = lab, station = obj })
                    end
                end
            end
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent(CLPHDS.EVT.LAB_DESTROY, function(labId)
    local cur = INST.current()
    if cur and cur.id == labId then
        clearAll()
        INST.leave()
        B.notify('Labor wurde zerstört!', 'error')
    end
end)

return LB

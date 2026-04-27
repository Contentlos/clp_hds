-- ============================================================
--  client/placement.lua
--  Ghost-Placement-System. Zeigt Vorschau-Objekt vor dem Spieler,
--  unterstützt Rotation + Grid-Snap, schickt finale Position an Server.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.place = {}

local PL = CLPHDS.place
local C  = CLPHDS.config
local U  = CLPHDS.util
local B  = CLPHDS.bridge
local I_REF -- aufgelöst über config 'items'

local _ghost      = nil
local _ghostModel = nil
local _itemId     = nil
local _labId      = nil
local _heading    = 0.0

local function getCfg() return ((C.get('admin_settings') or {}).labs) or {} end

local function getItem(id)
    local items = (C.get('items') or {}).items or {}
    for _, i in ipairs(items) do if i.id == id then return i end end
end

local function spawnGhost(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 3000
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() > timeout then return nil end
    end
    local ped = PlayerPedId()
    local fwd = GetEntityForwardVector(ped)
    local pos = GetEntityCoords(ped) + fwd * 1.5
    local obj = CreateObjectNoOffset(hash, pos.x, pos.y, pos.z, false, false, false)
    SetEntityAlpha(obj, 150, false)
    SetEntityCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(hash)
    return obj
end

local function clearGhost()
    if _ghost and DoesEntityExist(_ghost) then DeleteEntity(_ghost) end
    _ghost = nil; _ghostModel = nil; _itemId = nil; _heading = 0.0
end

function PL.start(itemId, labId)
    clearGhost()
    local item = getItem(itemId)
    if not item or item.type ~= 'station' then
        return B.notify('Ungültiges Stations-Item', 'error')
    end
    _itemId     = itemId
    _labId      = labId
    _ghostModel = item.model or 'prop_table_03'
    _ghost      = spawnGhost(_ghostModel)
    if not _ghost then return B.notify('Modell konnte nicht geladen werden', 'error') end
    B.notify('Platzierung: [E] bestätigen, [Q] drehen, [X] abbrechen', 'info')
end

function PL.cancel()
    clearGhost()
end

local function snap(value, step)
    if step <= 0 then return value end
    return math.floor(value / step + 0.5) * step
end

CreateThread(function()
    while true do
        Wait(0)
        if _ghost and DoesEntityExist(_ghost) then
            local cfg = getCfg()
            local ped = PlayerPedId()
            local cam = GetGameplayCamCoord()
            local fwd = GetGameplayCamRot(2)
            local rad = math.rad(fwd.z)
            local px  = cam.x + math.sin(-rad) * 2.5
            local py  = cam.y + math.cos(-rad) * 2.5

            local _, gz = GetGroundZFor_3dCoord(px, py, cam.z + 1.0, false)
            local step = cfg.ghost_grid_step or 0.05
            local sx, sy = snap(px, step), snap(py, step)

            SetEntityCoordsNoOffset(_ghost, sx, sy, gz + 0.01, false, false, false)
            SetEntityHeading(_ghost, _heading)

            -- Inputs
            if IsControlJustReleased(0, 38) then -- E confirm
                TriggerServerEvent(CLPHDS.EVT.LAB_PLACE_OBJECT, _labId, _itemId,
                    { x = sx, y = sy, z = gz + 0.01 }, _heading)
                clearGhost()
            elseif IsControlJustReleased(0, 44) then -- Q rotate
                _heading = (_heading + (cfg.ghost_rotation_step or 5.0)) % 360.0
            elseif IsControlJustReleased(0, 73) then -- X cancel
                clearGhost()
                B.notify('Platzierung abgebrochen', 'info')
            end
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name == GetCurrentResourceName() then clearGhost() end
end)

RegisterCommand('clp_place', function(_, args)
    if not args[1] then return B.notify('Usage: /clp_place <stationItemId> <labId>', 'error') end
    PL.start(args[1], args[2] or 'lab_1')
end, false)

return PL

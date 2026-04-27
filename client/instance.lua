-- ============================================================
--  client/instance.lua
--  Teleport in/aus Labor-Instanz. Nutzt einen "Shell"-MLO oder
--  einen festen Innenraum aus admin_settings.labs.teleport_targets.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.instance = {}

local INST = CLPHDS.instance
local C    = CLPHDS.config
local U    = CLPHDS.util
local B    = CLPHDS.bridge

local _currentLab = nil
local _inside = false

function INST.current() return _currentLab end
function INST.isInside() return _inside end

local function getTarget(labKey)
    local s = C.get('admin_settings') or {}
    s = s.labs or {}
    for _, t in ipairs(s.teleport_targets or {}) do
        if t.id == (labKey or 'default_shell') then return t end
    end
    return s.teleport_targets and s.teleport_targets[1] or
           { id = 'default_shell', interior = { 1453.0, -1100.0, 200.0 }, exit_offset = { 0.0, 0.0, 0.5 } }
end

function INST.enter(lab)
    if _inside then return end
    local target = getTarget(lab.teleport)
    local pos = vector3(target.interior[1] + ((target.exit_offset and target.exit_offset[1]) or 0.0),
                        target.interior[2] + ((target.exit_offset and target.exit_offset[2]) or 0.0),
                        target.interior[3] + ((target.exit_offset and target.exit_offset[3]) or 0.5))
    DoScreenFadeOut(500); Wait(550)
    SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false, false)
    _currentLab = lab
    _inside = true
    SetTimeout(400, function() DoScreenFadeIn(500) end)
    B.notify(('Betritt Labor %s'):format(lab.label or lab.id), 'info')
    TriggerEvent('clp_hds:lab:entered', lab)
end

function INST.leave()
    if not _inside or not _currentLab then return end
    DoScreenFadeOut(500); Wait(550)
    local a = _currentLab.anchor or { x = 0.0, y = 0.0, z = 72.0 }
    SetEntityCoords(PlayerPedId(), a.x or a[1] or 0.0, a.y or a[2] or 0.0, a.z or a[3] or 72.0, false, false, false, false)
    TriggerServerEvent(CLPHDS.EVT.LAB_LEAVE, _currentLab.id)
    _currentLab = nil
    _inside = false
    SetTimeout(400, function() DoScreenFadeIn(500) end)
    TriggerEvent('clp_hds:lab:left')
end

RegisterNetEvent(CLPHDS.EVT.LAB_ENTER, function(lab) INST.enter(lab) end)
RegisterNetEvent(CLPHDS.EVT.LAB_LEAVE, function() INST.leave() end)

RegisterCommand('clp_leave', function() INST.leave() end, false)

return INST

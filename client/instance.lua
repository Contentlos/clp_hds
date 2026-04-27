-- ============================================================
--  client/instance.lua
--  Teleport in/aus Labor-Instanz. Nutzt Shell-Definitionen aus
--  data/shells.json (live editierbar via Admin-Panel).
--  Fallback: admin_settings.labs.teleport_targets oder hartcodierte
--  Default-Apartment-Coords (kein Crash bei fehlenden Shells).
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.instance = {}

local INST = CLPHDS.instance
local C    = CLPHDS.config
local U    = CLPHDS.util
local B    = CLPHDS.bridge

local _currentLab = nil
local _inside     = false

function INST.current()  return _currentLab end
function INST.isInside() return _inside end

-- Sucht die Shell-Definition zum gegebenen Schluessel.
-- Sucht in dieser Reihenfolge:
--   1. data/shells.json (Live-Config)
--   2. legacy admin_settings.labs.teleport_targets
--   3. hartcodierter Last-Resort-Default
local function resolveShell(shellKey)
    local key = shellKey or 'default_shell'

    local sd = C.get('shells')
    if sd and sd.shells then
        for _, s in ipairs(sd.shells) do
            if s.id == key then return s end
        end
    end

    local legacy = ((C.get('admin_settings') or {}).labs or {}).teleport_targets
    if legacy then
        for _, t in ipairs(legacy) do
            if t.id == key then
                -- in das neue Shell-Schema mappen
                return {
                    id           = t.id,
                    label        = t.id,
                    teleport_in  = { x = t.interior[1], y = t.interior[2], z = t.interior[3], h = 0.0 },
                    teleport_out = nil,
                    fade_ms      = 500,
                }
            end
        end
    end

    return {
        id           = 'default_shell',
        label        = 'Default Apartment',
        teleport_in  = { x = 1453.0, y = -1100.0, z = 200.0, h = 0.0 },
        teleport_out = nil,
        fade_ms      = 500,
    }
end

-- Laedt optional einen IPL bevor teleportiert wird.
local function loadIplIfNeeded(shell)
    if shell.ipl and shell.ipl ~= '' and not IsIplActive(shell.ipl) then
        RequestIpl(shell.ipl)
        local timeout = GetGameTimer() + 1500
        while not IsIplActive(shell.ipl) and GetGameTimer() < timeout do Wait(0) end
    end
end

local function doTeleport(shell, lab)
    loadIplIfNeeded(shell)
    local fade = shell.fade_ms or 500
    DoScreenFadeOut(fade); Wait(fade + 50)

    local t = shell.teleport_in or { x = 0.0, y = 0.0, z = 72.0, h = 0.0 }
    local ped = PlayerPedId()
    SetEntityCoords(ped, t.x + 0.0, t.y + 0.0, t.z + 0.0, false, false, false, false)
    if t.h then SetEntityHeading(ped, t.h + 0.0) end

    -- Interior-Hint: stelle sicher dass der Innenraum geladen ist.
    local interior = GetInteriorAtCoords(t.x + 0.0, t.y + 0.0, t.z + 0.0)
    if interior and interior ~= 0 then
        LoadInterior(interior)
    end

    if lab then _currentLab = lab; _inside = true end
    SetTimeout(math.max(fade - 100, 50), function() DoScreenFadeIn(fade) end)
end

function INST.enter(lab)
    if _inside then return end
    local shell = resolveShell(lab.shell_id or lab.teleport)
    doTeleport(shell, lab)
    B.notify(('Betritt Labor %s'):format(lab.label or lab.id), 'info')
    TriggerEvent('clp_hds:lab:entered', lab)
end

function INST.leave()
    if not _inside or not _currentLab then return end
    local shell = resolveShell(_currentLab.shell_id or _currentLab.teleport)
    local fade  = shell.fade_ms or 500
    DoScreenFadeOut(fade); Wait(fade + 50)

    local out = shell.teleport_out
    local a   = _currentLab.anchor or { x = 0.0, y = 0.0, z = 72.0 }
    local x   = (out and out.x) or a.x or a[1] or 0.0
    local y   = (out and out.y) or a.y or a[2] or 0.0
    local z   = (out and out.z) or a.z or a[3] or 72.0
    SetEntityCoords(PlayerPedId(), x + 0.0, y + 0.0, z + 0.0, false, false, false, false)

    TriggerServerEvent(CLPHDS.EVT.LAB_LEAVE, _currentLab.id)
    _currentLab = nil
    _inside     = false
    SetTimeout(math.max(fade - 100, 50), function() DoScreenFadeIn(fade) end)
    TriggerEvent('clp_hds:lab:left')
end

RegisterNetEvent(CLPHDS.EVT.LAB_ENTER, function(lab) INST.enter(lab) end)
RegisterNetEvent(CLPHDS.EVT.LAB_LEAVE, function() INST.leave() end)

-- Admin-Debug-Teleport: ohne Lab in eine Shell springen, um Coords zu pruefen.
RegisterNetEvent('clp_hds:shell:debugTeleport', function(shell)
    if not shell then return end
    doTeleport(shell, nil)
    B.notify(('[Shell-Test] %s'):format(shell.label or shell.id), 'info')
end)

RegisterCommand('clp_leave', function() INST.leave() end, false)

return INST

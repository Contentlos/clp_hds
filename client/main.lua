-- ============================================================
--  client/main.lua
--  Bootstrap, allgemeine Befehle, Notify-Receiver.
-- ============================================================

CLPHDS = CLPHDS or {}
local N = CLPHDS.nui
local B = CLPHDS.bridge
local U = CLPHDS.util

RegisterNetEvent('clp_hds:notify', function(msg, kind)
    SendNUIMessage({ type = 'notify', message = msg, kind = kind or 'info' })
    B.notify(msg, kind)
end)

-- Schnellstart: Spieler öffnet Inventar/Crafting via /clp
RegisterCommand('clp', function() N.toggle('main') end, false)
RegisterKeyMapping('clp', 'clp_hds: Hauptmenü', 'keyboard', 'F6')

RegisterCommand('clp_admin_open', function()
    TriggerServerEvent(CLPHDS.EVT.ADMIN_OPEN)
    N.toggle('admin')
end, false)
RegisterKeyMapping('clp_admin_open', 'clp_hds: Admin-Panel', 'keyboard', 'F7')

-- Lab-Erstellung (Item-Use simulation)
RegisterCommand('clp_create_lab', function(_, args)
    local kind   = args[1] or 'apartment'
    local label  = args[2] or 'Mein Labor'
    local px, py, pz = table.unpack(GetEntityCoords(PlayerPedId()))
    TriggerServerEvent('clp_hds:lab:requestCreate', {
        kind   = kind,
        label  = label,
        anchor = { x = px, y = py, z = pz },
    })
end, false)

RegisterCommand('clp_enter_lab', function(_, args)
    if not args[1] then return B.notify('Usage: /clp_enter_lab <labId>', 'error') end
    TriggerServerEvent(CLPHDS.EVT.LAB_ENTER, args[1])
end, false)

U.info('clp_hds client geladen')

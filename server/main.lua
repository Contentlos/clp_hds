-- ============================================================
--  server/main.lua
--  Bootstrap + globale Spieler-Events.
-- ============================================================

local C  = CLPHDS.config
local LB = CLPHDS.labs
local B  = CLPHDS.bridge
local U  = CLPHDS.util
local P  = CLPHDS.perms

-- Beim Connect Live-Configs schicken
RegisterNetEvent('playerJoining', function()
    local src = source
    SetTimeout(2000, function()
        C.broadcastAll(src)
        TriggerClientEvent(CLPHDS.EVT.GATHER_ZONES, src, CLPHDS.gather.publicState())
    end)
end)

-- Spieler erstellt sich ein neues Labor (z.B. via Item)
RegisterNetEvent('clp_hds:lab:requestCreate', function(payload)
    local src = source
    local p   = B.getPlayer(src); if not p then return end
    local id  = p.identifier
    local lab = LB.create({
        owner    = id,
        label    = payload.label,
        kind     = payload.kind,
        anchor   = payload.anchor,
        teleport = payload.teleport,
    }, src)
    if not lab then
        return B.notify(src, 'Labor konnte nicht erstellt werden (Limit?)', 'error')
    end
    B.notify(src, ('Labor %s angelegt'):format(lab.id), 'success')
    TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, lab.id, lab)
end)

-- Spieler betritt ein eigenes/befreundetes Labor
RegisterNetEvent(CLPHDS.EVT.LAB_ENTER, function(labId)
    local src = source
    local lab = LB.get(labId); if not lab then return end
    local id  = B.getIdentifier(src)
    if P.labRole(lab, id) < CLPHDS.LAB_ROLES.WORKER then
        return B.notify(src, 'Kein Zutritt', 'error')
    end
    TriggerClientEvent(CLPHDS.EVT.LAB_ENTER, src, lab)
end)

RegisterNetEvent(CLPHDS.EVT.LAB_LEAVE, function(labId)
    local src = source
    TriggerClientEvent(CLPHDS.EVT.LAB_LEAVE, src, labId)
end)

-- Convenience: gibt einem Spieler das Build-Item (für Tests)
RegisterCommand('clp_giveStation', function(src, args)
    if not P.requireAdmin(src, CLPHDS.ADMIN_LEVELS.ADMIN) then return end
    local item = args[1] or 'station_table'
    B.addItem(src, item, tonumber(args[2]) or 1)
end, true)

RegisterCommand('clp_admin', function(src)
    if P.adminLevel(src) >= CLPHDS.ADMIN_LEVELS.MODERATOR then
        TriggerClientEvent('clp_hds:admin:openClient', src)
    else
        B.notify(src, 'Keine Adminrechte', 'error')
    end
end, false)

U.info('clp_hds %s gestartet', CLPHDS.VERSION)

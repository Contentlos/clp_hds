-- ============================================================
--  client/admin.lua
--  Brücke zwischen Admin-NUI und Server.
-- ============================================================

CLPHDS = CLPHDS or {}
local N = CLPHDS.nui
local U = CLPHDS.util

local _pending = {}
local _seq     = 0

local function nextId() _seq = _seq + 1 return ('a%d'):format(_seq) end

-- NUI -> Server
N.on('admin:action', function(payload)
    local id = nextId()
    TriggerServerEvent(CLPHDS.EVT.ADMIN_ACTION, payload.action, payload.data, id)
    -- Antwort wird via 'clp_hds:admin:response' an die NUI weitergereicht
    return { ok = true, id = id }
end)

RegisterNetEvent('clp_hds:admin:response', function(reqId, result)
    SendNUIMessage({ type = 'admin:response', id = reqId, result = result })
end)

RegisterNetEvent(CLPHDS.EVT.ADMIN_LOG, function(entry)
    SendNUIMessage({ type = 'admin:log', entry = entry })
end)

RegisterNetEvent('clp_hds:admin:opened', function(meta)
    SendNUIMessage({ type = 'admin:opened', meta = meta })
end)

RegisterNetEvent('clp_hds:admin:openClient', function()
    TriggerServerEvent(CLPHDS.EVT.ADMIN_OPEN)
    N.toggle('admin')
end)

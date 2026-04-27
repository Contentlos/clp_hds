-- ============================================================
--  client/nui.lua
--  Zentraler NUI-Bus. Andere Module registrieren Handler über
--  CLPHDS.nui.on('messageType', fn).
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.nui = {}

local N = CLPHDS.nui
local U = CLPHDS.util

local _focus = false
local _handlers = {}

function N.on(msg, fn)
    _handlers[msg] = _handlers[msg] or {}
    table.insert(_handlers[msg], fn)
end

function N.send(msg)
    SendNUIMessage(msg)
end

function N.setFocus(focus, cursor)
    _focus = focus and true or false
    SetNuiFocus(_focus, cursor and true or false)
end

function N.toggle(panel, payload)
    N.setFocus(true, true)
    SendNUIMessage({ type = 'open', panel = panel, payload = payload })
end

function N.close()
    N.setFocus(false, false)
    SendNUIMessage({ type = 'close' })
end

-- Generisch: jeder NUI-Callback wird hier dispatcht
RegisterNUICallback('clp', function(data, cb)
    local list = _handlers[data.type] or {}
    local result
    for _, fn in ipairs(list) do
        local ok, res = pcall(fn, data.payload or {}, data)
        if not ok then U.error('NUI handler "%s" failed: %s', data.type, tostring(res)) end
        result = res
    end
    cb(result or { ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    N.close()
    cb({ ok = true })
end)

RegisterCommand('clp_close', function() N.close() end, false)
RegisterKeyMapping('clp_close', 'clp_hds: NUI schließen', 'keyboard', 'ESCAPE')

return N

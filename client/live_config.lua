-- ============================================================
--  client/live_config.lua
--  Empfängt + cached Server-Configs. Stellt CLPHDS.config.get(name) bereit.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.config = CLPHDS.config or {}

local _cache = {}
local _listeners = {} -- name -> { fn, fn, ... }

function CLPHDS.config.get(name)
    return _cache[name]
end

function CLPHDS.config.on(name, fn)
    _listeners[name] = _listeners[name] or {}
    table.insert(_listeners[name], fn)
    if _cache[name] then fn(_cache[name]) end
end

RegisterNetEvent(CLPHDS.EVT.CONFIG_PUSH, function(name, data)
    _cache[name] = data
    for _, fn in ipairs(_listeners[name] or {}) do
        local ok, err = pcall(fn, data)
        if not ok then CLPHDS.util.error('config listener "%s" failed: %s', name, tostring(err)) end
    end
    -- broadcast in NUI – Admin Panel etc. dürfen reagieren
    SendNUIMessage({ type = 'config:push', name = name, data = data })
end)

CreateThread(function()
    Wait(500)
    TriggerServerEvent(CLPHDS.EVT.CONFIG_REQUEST)
end)

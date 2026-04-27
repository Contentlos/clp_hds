-- ============================================================
--  server/live_config.lua
--  Zentrale Live-Config-Verwaltung.
--  - lädt JSON beim Start
--  - bietet get/set/patch APIs
--  - pusht Änderungen an alle verbundenen Clients
--  - filtert Felder die laut admin_settings.broadcast_blacklist
--    NICHT an Clients gesendet werden dürfen (z.B. PIN-Hashes)
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.config = {}

local C = CLPHDS.config
local S = CLPHDS.storage
local L = CLPHDS.logging
local U = CLPHDS.util

local _cache = {}

local function loadDefaultsLua()
    -- Bootstrap-Fallback: die Lua-Defaults werden NUR genutzt, wenn die
    -- entsprechende JSON-Datei nicht existiert oder leer ist.
    local f = LoadResourceFile(CLPHDS.RESOURCE_NAME, 'config/default_config.lua')
    if not f then return {} end
    local fn, err = load(f, 'default_config', 't', _G)
    if not fn then U.error('default_config.lua load: %s', err) return {} end
    local ok, res = pcall(fn)
    if not ok then U.error('default_config.lua exec: %s', tostring(res)) return {} end
    return res or {}
end

local function ensureLoaded(name)
    if _cache[name] ~= nil then return _cache[name] end
    local data = S.read(name)
    if not data then
        local defaults = loadDefaultsLua()
        if name == 'admin_settings' and defaults.admin_settings then
            data = defaults.admin_settings
        else
            data = {}
        end
        S.write(name, data)
    end
    _cache[name] = data
    return data
end

function C.get(name)
    return ensureLoaded(name)
end

function C.set(name, value, source)
    _cache[name] = value
    S.write(name, value)
    L.write('config', 'set:' .. name, { keys = (type(value) == 'table' and (function()
        local k = {} for key in pairs(value) do table.insert(k, key) end return k end)() or nil) }, source)
    C.broadcast(name)
end

function C.patch(name, partial, source)
    local current = U.deepcopy(ensureLoaded(name) or {})
    if type(current) ~= 'table' then current = {} end
    U.merge(current, partial)
    C.set(name, current, source)
end

local function filterForClient(name, value)
    if name ~= 'admin_settings' then return value end
    local copy = U.deepcopy(value) or {}
    local blacklist = (value and value.broadcast_blacklist) or {}
    for _, key in ipairs(blacklist) do copy[key] = nil end
    return copy
end

function C.broadcast(name, target)
    local value = ensureLoaded(name)
    local payload = filterForClient(name, value)
    if target then
        TriggerClientEvent(CLPHDS.EVT.CONFIG_PUSH, target, name, payload)
    else
        TriggerClientEvent(CLPHDS.EVT.CONFIG_PUSH, -1, name, payload)
    end
end

function C.broadcastAll(target)
    for name in pairs(S.FILES) do
        if name ~= 'logs' then C.broadcast(name, target) end
    end
end

-- Initial laden
CreateThread(function()
    Wait(0)
    for name in pairs(S.FILES) do ensureLoaded(name) end
    U.info('Live-Config geladen (%d Stores)', U.tlen(_cache))
end)

-- Client kann frische Configs anfordern (z.B. nach Reconnect)
RegisterNetEvent(CLPHDS.EVT.CONFIG_REQUEST, function()
    C.broadcastAll(source)
end)

-- Periodisches Logs-Pruning
CreateThread(function()
    while true do
        Wait(60 * 60 * 1000) -- jede Stunde
        local s = ensureLoaded('admin_settings')
        local days = (s and s.log_retention_days) or 30
        L.purgeOlderThan(days * 86400)
    end
end)

return C

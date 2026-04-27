-- ============================================================
--  server/logging.lua
--  Audit-Log für Adminaktionen, Crafting, Raids, Heat-Spikes …
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.logging = {}

local L = CLPHDS.logging
local S = CLPHDS.storage
local U = CLPHDS.util

-- In-Memory Buffer + periodisches Flushen schont I/O
local _buffer = {}
local _loaded = false

local function loadOnce()
    if _loaded then return end
    local data = S.read('logs') or { entries = {} }
    _buffer = data.entries or {}
    _loaded = true
end

function L.write(category, action, payload, source)
    loadOnce()
    local entry = {
        id         = U.uuid(),
        ts         = os.time(),
        category   = category,
        action     = action,
        source     = source,
        identifier = source and CLPHDS.bridge.getIdentifier and CLPHDS.bridge.getIdentifier(source) or nil,
        payload    = payload or {},
    }
    table.insert(_buffer, entry)
    -- direkt in Disk schreiben damit Crashes nichts verlieren
    S.write('logs', { entries = _buffer })
    -- live an Admin-Panels pushen
    TriggerClientEvent(CLPHDS.EVT.ADMIN_LOG, -1, entry)
    return entry
end

function L.list(limit, filter)
    loadOnce()
    limit = limit or 200
    local out = {}
    for i = #_buffer, 1, -1 do
        local e = _buffer[i]
        if (not filter) or (filter.category and e.category == filter.category)
            or (filter.source and e.source == filter.source) then
            table.insert(out, e)
            if #out >= limit then break end
        end
    end
    return out
end

function L.purgeOlderThan(seconds)
    loadOnce()
    local cutoff = os.time() - seconds
    local kept = {}
    for _, e in ipairs(_buffer) do
        if e.ts >= cutoff then table.insert(kept, e) end
    end
    _buffer = kept
    S.write('logs', { entries = _buffer })
    return #kept
end

return L

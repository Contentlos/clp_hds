-- ============================================================
--  server/items.lua
--  Wrapper rund um items.json. Stellt den anderen Modulen
--  einen Lookup-Index bereit (id -> item).
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.items = {}

local I = CLPHDS.items
local C = CLPHDS.config
local U = CLPHDS.util

local _index = {}

local function rebuild()
    _index = {}
    local data = C.get('items') or { items = {} }
    for _, it in ipairs(data.items or {}) do _index[it.id] = it end
end

function I.get(id)        return _index[id] end
function I.all()          return C.get('items').items or {} end
function I.exists(id)     return _index[id] ~= nil end
function I.byType(t)
    local out = {}
    for _, it in pairs(_index) do
        if it.type == t then table.insert(out, it) end
    end
    return out
end

function I.upsert(item, source)
    if not U.isString(item.id) or not U.isString(item.label) then
        return false, 'invalid_item'
    end
    local data = U.deepcopy(C.get('items') or { items = {} })
    local found
    for i, it in ipairs(data.items) do
        if it.id == item.id then data.items[i] = item; found = true; break end
    end
    if not found then table.insert(data.items, item) end
    C.set('items', data, source)
    rebuild()
    return true
end

function I.delete(id, source)
    local data = U.deepcopy(C.get('items') or { items = {} })
    for i, it in ipairs(data.items) do
        if it.id == id then table.remove(data.items, i); break end
    end
    C.set('items', data, source)
    rebuild()
    return true
end

CreateThread(function() Wait(100); rebuild() end)
AddEventHandler(CLPHDS.EVT.CONFIG_PUSH, function(name)
    if name == 'items' then rebuild() end
end)

return I

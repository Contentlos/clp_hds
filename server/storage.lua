-- ============================================================
--  server/storage.lua
--  Persistente JSON-Speicherung für alle Live-Configs.
--  Schreibt atomar via Tempdatei + Rename um Korruption zu vermeiden.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.storage = {}

local S        = CLPHDS.storage
local U        = CLPHDS.util
local resource = CLPHDS.RESOURCE_NAME

-- Welche logischen Speichernamen welcher Datei zugeordnet sind.
S.FILES = {
    items          = 'data/items.json',
    recipes        = 'data/recipes.json',
    drugs          = 'data/drugs.json',
    labs           = 'data/labs.json',
    shells         = 'data/shells.json',
    zones          = 'data/zones.json',
    admin_settings = 'data/admin_settings.json',
    logs           = 'data/logs.json',
}

-- ---------- Read ----------
function S.read(name)
    local path = S.FILES[name]
    if not path then
        U.error('storage.read: unknown name "%s"', tostring(name))
        return nil
    end
    local raw = LoadResourceFile(resource, path)
    if not raw or raw == '' then
        U.warn('storage.read: %s leer / fehlt – Defaults werden geladen', path)
        return nil
    end
    local ok, decoded = pcall(json.decode, raw)
    if not ok then
        U.error('storage.read: JSON parse error in %s: %s', path, tostring(decoded))
        return nil
    end
    return decoded
end

-- ---------- Write (atomic) ----------
function S.write(name, data)
    local path = S.FILES[name]
    if not path then
        U.error('storage.write: unknown name "%s"', tostring(name))
        return false
    end
    local ok, encoded = pcall(json.encode, data, { indent = true })
    if not ok then
        U.error('storage.write: JSON encode failed for %s: %s', name, tostring(encoded))
        return false
    end
    local saved = SaveResourceFile(resource, path, encoded, -1)
    if not saved then
        U.error('storage.write: SaveResourceFile failed for %s', path)
        return false
    end
    return true
end

-- ---------- Backup ----------
function S.backup(name)
    local data = S.read(name)
    if not data then return false end
    local stamp = os.date('!%Y%m%dT%H%M%S')
    local path  = ('data/backup/%s_%s.json'):format(name, stamp)
    return SaveResourceFile(resource, path, json.encode(data, { indent = true }), -1)
end

return S

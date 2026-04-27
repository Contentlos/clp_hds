-- ============================================================
--  server/admin.lua
--  Zentrale Admin-Action-Verarbeitung.
--  Alle Edit-Aktionen aus dem NUI Admin-Panel laufen hier rein.
--  Strikte Server-Validierung: NIE Client-Daten unbesehen übernehmen!
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.admin = {}

local A   = CLPHDS.admin
local C   = CLPHDS.config
local I   = CLPHDS.items
local LB  = CLPHDS.labs
local SH  = CLPHDS.shells
local P   = CLPHDS.perms
local B   = CLPHDS.bridge
local L   = CLPHDS.logging
local U   = CLPHDS.util

local handlers = {}

-- ----- Helper: prüft Adminlevel + minLevel der Aktion -----
local function gate(src, minLevel)
    if not P.requireAdmin(src, minLevel or CLPHDS.ADMIN_LEVELS.ADMIN) then
        B.notify(src, 'Keine Berechtigung', 'error')
        return false
    end
    return true
end

-- =============== ITEMS ===============
handlers['items:list'] = function(src) return C.get('items') end
handlers['items:upsert'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local ok, err = I.upsert(payload, src)
    L.write('admin', 'items:upsert', { id = payload and payload.id }, src)
    return { ok = ok, error = err }
end
handlers['items:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    I.delete(payload.id, src)
    L.write('admin', 'items:delete', { id = payload.id }, src)
    return { ok = true }
end

-- =============== RECIPES ===============
local function _recipes() return U.deepcopy(C.get('recipes') or { recipes = {} }) end

handlers['recipes:list'] = function(src) return C.get('recipes') end
handlers['recipes:upsert'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    if not U.isString(payload.id) then return { ok = false, error = 'invalid_id' } end
    local d = _recipes()
    local found
    for i, r in ipairs(d.recipes) do
        if r.id == payload.id then d.recipes[i] = payload; found = true; break end
    end
    if not found then table.insert(d.recipes, payload) end
    C.set('recipes', d, src)
    L.write('admin', 'recipes:upsert', { id = payload.id }, src)
    return { ok = true }
end
handlers['recipes:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local d = _recipes()
    for i, r in ipairs(d.recipes) do
        if r.id == payload.id then table.remove(d.recipes, i); break end
    end
    C.set('recipes', d, src)
    L.write('admin', 'recipes:delete', { id = payload.id }, src)
    return { ok = true }
end

-- =============== DRUGS ===============
local function _drugs() return U.deepcopy(C.get('drugs') or { drugs = {} }) end

handlers['drugs:list'] = function(src) return C.get('drugs') end
handlers['drugs:upsert'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    if not U.isString(payload.id) then return { ok = false, error = 'invalid_id' } end
    local d = _drugs()
    local found
    for i, dr in ipairs(d.drugs) do
        if dr.id == payload.id then d.drugs[i] = payload; found = true; break end
    end
    if not found then table.insert(d.drugs, payload) end
    C.set('drugs', d, src)
    L.write('admin', 'drugs:upsert', { id = payload.id }, src)
    return { ok = true }
end
handlers['drugs:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local d = _drugs()
    for i, dr in ipairs(d.drugs) do
        if dr.id == payload.id then table.remove(d.drugs, i); break end
    end
    C.set('drugs', d, src)
    L.write('admin', 'drugs:delete', { id = payload.id }, src)
    return { ok = true }
end

-- =============== LABS ===============
handlers['labs:list']   = function(src) return { labs = LB.list() } end
handlers['labs:create'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    return { ok = true, lab = LB.create(payload, src) }
end
handlers['labs:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    return { ok = LB.delete(payload.id, src) }
end
handlers['labs:setOwner'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    LB.update(payload.id, { owner = payload.identifier }, src)
    return { ok = true }
end
handlers['labs:reset'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    LB.update(payload.id, { objects = {}, inventory = {}, members = {}, heat = 0 }, src)
    return { ok = true }
end
handlers['labs:setShell'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    if not SH.get(payload.shell_id) then return { ok = false, error = 'unknown_shell' } end
    LB.update(payload.id, { shell_id = payload.shell_id, teleport = payload.shell_id }, src)
    return { ok = true }
end
handlers['labs:addMember'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    return { ok = LB.addMember(payload.id, payload.identifier, payload.role or 'worker', src) }
end
handlers['labs:removeMember'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    return { ok = LB.removeMember(payload.id, payload.identifier, src) }
end

-- =============== SHELLS / MLO ===============
handlers['shells:list']   = function(src) return { shells = SH.list() } end
handlers['shells:upsert'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local ok, err = SH.upsert(payload, src)
    return { ok = ok, error = err }
end
handlers['shells:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local ok, err = SH.delete(payload.id, src)
    return { ok = ok, error = err }
end
-- Hilfsaktion: liest die aktuelle Spielerposition serverseitig auf, damit
-- der Admin im Editor "Aktuelle Position uebernehmen" klicken kann.
handlers['shells:capturePos'] = function(src)
    if not gate(src) then return { ok = false } end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return { ok = false, error = 'no_ped (OneSync off?)' } end
    local p = GetEntityCoords(ped)
    local h = GetEntityHeading(ped)
    return { ok = true, pos = { x = (p.x or 0.0) + 0.0, y = (p.y or 0.0) + 0.0, z = (p.z or 0.0) + 0.0, h = (h or 0.0) + 0.0 } }
end
-- Teleportiert den Admin in eine Shell zum Testen.
handlers['shells:teleport'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local s = SH.get(payload.id); if not s then return { ok = false, error = 'not_found' } end
    TriggerClientEvent('clp_hds:shell:debugTeleport', src, s)
    L.write('shells', 'teleport', { id = s.id }, src)
    return { ok = true }
end

-- =============== PLAYERS ===============
handlers['players:online'] = function(src)
    if not gate(src) then return { players = {} } end
    local out = {}
    for _, pid in ipairs(B.getOnlinePlayers()) do
        local pid_n = tonumber(pid) or pid
        local p = B.getPlayer(pid_n)
        if p then
            table.insert(out, {
                id         = pid_n,
                identifier = p.identifier,
                name       = (p.getName and p:getName()) or GetPlayerName(pid_n),
                job        = (p.job and p.job.name) or 'unemployed',
            })
        end
    end
    return { players = out }
end
handlers['players:giveItem'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    B.addItem(payload.id, payload.item, payload.count or 1, payload.meta)
    L.write('admin', 'players:giveItem', payload, src)
    return { ok = true }
end
handlers['players:removeItem'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    B.removeItem(payload.id, payload.item, payload.count or 1)
    L.write('admin', 'players:removeItem', payload, src)
    return { ok = true }
end

-- =============== POLICE / HEAT SETTINGS ===============
handlers['settings:patch'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    if type(payload) ~= 'table' then return { ok = false } end
    C.patch('admin_settings', payload, src)
    L.write('admin', 'settings:patch', { keys = U.tlen(payload) }, src)
    return { ok = true }
end

-- =============== GATHERING ZONES ===============
handlers['zones:list'] = function(src) return C.get('zones') end
handlers['zones:upsert'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local d = U.deepcopy(C.get('zones') or { zones = {} })
    local found
    for i, z in ipairs(d.zones) do
        if z.id == payload.id then d.zones[i] = payload; found = true; break end
    end
    if not found then table.insert(d.zones, payload) end
    C.set('zones', d, src)
    L.write('admin', 'zones:upsert', { id = payload.id }, src)
    return { ok = true }
end
handlers['zones:delete'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    local d = U.deepcopy(C.get('zones') or { zones = {} })
    for i, z in ipairs(d.zones) do
        if z.id == payload.id then table.remove(d.zones, i); break end
    end
    C.set('zones', d, src)
    L.write('admin', 'zones:delete', { id = payload.id }, src)
    return { ok = true }
end

-- =============== LOGS ===============
handlers['logs:list'] = function(src, payload)
    if not gate(src, CLPHDS.ADMIN_LEVELS.MODERATOR) then return { entries = {} } end
    return { entries = L.list(payload and payload.limit or 200, payload and payload.filter) }
end

-- =============== TEST MODE ===============
handlers['test:simulateCraft'] = function(src, payload)
    if not gate(src) then return { ok = false } end
    -- liefert berechnete success/quality ohne tatsächlich Items zu modifizieren
    local d = C.get('drugs').drugs
    local r = nil
    for _, x in ipairs(C.get('recipes').recipes) do
        if x.id == payload.recipeId then r = x; break end
    end
    if not r then return { ok = false, error = 'no_recipe' } end
    local cs = (C.get('admin_settings') or {}).crafting or {}
    local score = U.clamp(payload.score or 0.7, 0, 1)
    local successChance = U.clamp((r.success_base or 0.85) * (0.5 + 0.5 * score), 0.05, 1.0)
    local quality = math.floor(U.lerp(cs.quality_min or 25, cs.quality_max or 100, score))
    return { ok = true, successChance = successChance, quality = quality }
end

-- =============== EXPORT / IMPORT ===============
handlers['admin:export'] = function(src)
    if not gate(src, CLPHDS.ADMIN_LEVELS.SUPERADMIN) then return { ok = false } end
    return {
        ok = true,
        items   = C.get('items'),
        recipes = C.get('recipes'),
        drugs   = C.get('drugs'),
        shells  = C.get('shells'),
        zones   = C.get('zones'),
        admin_settings = C.get('admin_settings'),
    }
end
handlers['admin:import'] = function(src, payload)
    if not gate(src, CLPHDS.ADMIN_LEVELS.SUPERADMIN) then return { ok = false } end
    if type(payload) ~= 'table' then return { ok = false } end
    for _, key in ipairs({ 'items', 'recipes', 'drugs', 'shells', 'zones', 'admin_settings' }) do
        if payload[key] then C.set(key, payload[key], src) end
    end
    L.write('admin', 'import', { keys = U.tlen(payload) }, src)
    return { ok = true }
end

-- =================================================================
--  Eingangs-Event vom Client
-- =================================================================
RegisterNetEvent(CLPHDS.EVT.ADMIN_ACTION, function(action, payload, reqId)
    local src = source
    local h   = handlers[action]
    if not h then
        return TriggerClientEvent('clp_hds:admin:response', src, reqId, { ok = false, error = 'unknown_action' })
    end
    local ok, res = pcall(h, src, payload or {})
    if not ok then
        U.error('admin handler "%s" failed: %s', action, tostring(res))
        return TriggerClientEvent('clp_hds:admin:response', src, reqId, { ok = false, error = 'handler_error' })
    end
    TriggerClientEvent('clp_hds:admin:response', src, reqId, res or { ok = true })
end)

-- Initialer Status für Admin-Panel beim Öffnen
RegisterNetEvent(CLPHDS.EVT.ADMIN_OPEN, function()
    local src = source
    if P.adminLevel(src) < CLPHDS.ADMIN_LEVELS.MODERATOR then
        return B.notify(src, 'Keine Adminrechte', 'error')
    end
    TriggerClientEvent('clp_hds:admin:opened', src, {
        level   = P.adminLevel(src),
        version = CLPHDS.VERSION,
    })
end)

return A

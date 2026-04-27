-- ============================================================
--  server/labs.lua
--  Labor-Verwaltung: anlegen, lesen, Mitglieder, Inventar, Heat,
--  Persistenz nach data/labs.json.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.labs = {}

local LB = CLPHDS.labs
local C  = CLPHDS.config
local P  = CLPHDS.perms
local L  = CLPHDS.logging
local B  = CLPHDS.bridge
local U  = CLPHDS.util

-- ---------- Internals ----------
local function _data() return C.get('labs') or { labs = {}, next_seq = 1 } end
local function _save(d) C.set('labs', d) end

local function _findIndex(labs, id)
    for i, l in ipairs(labs) do if l.id == id then return i end end
end

-- ---------- Public API ----------
function LB.list() return _data().labs end

function LB.get(id)
    local d = _data()
    local i = _findIndex(d.labs, id)
    return i and d.labs[i] or nil
end

function LB.byOwner(identifier)
    local out = {}
    for _, l in ipairs(_data().labs) do
        if l.owner == identifier then table.insert(out, l) end
    end
    return out
end

function LB.create(opts, source)
    local d = U.deepcopy(_data())
    local owner = opts.owner
    if not owner then return nil, 'no_owner' end

    -- Limits prüfen
    local count = 0
    for _, l in ipairs(d.labs) do if l.owner == owner then count = count + 1 end end
    if count >= CLPHDS.LIMITS.MAX_LABS_PER_OWNER then return nil, 'limit_reached' end

    local lab = {
        id        = ('lab_%d'):format(d.next_seq),
        seq       = d.next_seq,
        label     = opts.label or ('Labor #' .. d.next_seq),
        kind      = opts.kind or 'apartment', -- 'house' | 'apartment' | 'warehouse' | 'bunker' | 'custom'
        owner     = owner,
        members   = {},
        objects   = {},
        inventory = {},
        anchor    = opts.anchor or { x = 0.0, y = 0.0, z = 0.0 },
        shell_id  = opts.shell_id or opts.teleport or 'default_shell',
        teleport  = opts.shell_id or opts.teleport or 'default_shell', -- legacy alias
        heat      = 0,
        created   = os.time(),
    }
    d.next_seq = d.next_seq + 1
    table.insert(d.labs, lab)
    _save(d)
    L.write('labs', 'create', { id = lab.id, owner = owner }, source)
    return lab
end

function LB.delete(id, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    local removed = table.remove(d.labs, i)
    _save(d)
    L.write('labs', 'delete', { id = id, owner = removed.owner }, source)
    return true
end

function LB.update(id, patch, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    U.merge(d.labs[i], patch)
    _save(d)
    L.write('labs', 'update', { id = id, keys = U.tlen(patch) }, source)
    return true
end

-- ---------- Members ----------
function LB.addMember(id, identifier, role, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    local lab = d.labs[i]
    if #lab.members >= CLPHDS.LIMITS.MAX_LAB_MEMBERS then return false, 'lab_full' end
    for _, m in ipairs(lab.members) do
        if m.identifier == identifier then m.role = role; _save(d); return true end
    end
    table.insert(lab.members, { identifier = identifier, role = role or 'worker', joined = os.time() })
    _save(d)
    L.write('labs', 'addMember', { lab = id, identifier = identifier, role = role }, source)
    return true
end

function LB.removeMember(id, identifier, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    local lab = d.labs[i]
    for k, m in ipairs(lab.members) do
        if m.identifier == identifier then
            table.remove(lab.members, k)
            _save(d)
            L.write('labs', 'removeMember', { lab = id, identifier = identifier }, source)
            return true
        end
    end
    return false
end

-- ---------- Objects (Stations / Locker) ----------
function LB.addObject(id, obj, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    local lab = d.labs[i]
    if #lab.objects >= CLPHDS.LIMITS.MAX_OBJECTS_PER_LAB then return false, 'object_limit' end
    obj.uid = obj.uid or U.uuid()
    table.insert(lab.objects, obj)
    _save(d)
    L.write('labs', 'addObject', { lab = id, uid = obj.uid, model = obj.model }, source)
    return obj
end

function LB.removeObject(id, uid, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id)
    if not i then return false end
    local lab = d.labs[i]
    for k, o in ipairs(lab.objects) do
        if o.uid == uid then
            table.remove(lab.objects, k)
            _save(d)
            L.write('labs', 'removeObject', { lab = id, uid = uid }, source)
            return true
        end
    end
    return false
end

-- ---------- Inventory (lab-internes Lager) ----------
function LB.addInv(id, item, count, meta)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id); if not i then return false end
    local lab = d.labs[i]
    table.insert(lab.inventory, { item = item, count = count, meta = meta or {} })
    _save(d); return true
end

function LB.takeInv(id, item, count)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id); if not i then return false end
    local lab = d.labs[i]
    local remaining = count
    for k = #lab.inventory, 1, -1 do
        local e = lab.inventory[k]
        if e.item == item and remaining > 0 then
            local take = math.min(e.count, remaining)
            e.count = e.count - take
            remaining = remaining - take
            if e.count <= 0 then table.remove(lab.inventory, k) end
        end
    end
    _save(d)
    return remaining == 0
end

-- ---------- Heat ----------
function LB.addHeat(id, amount, source)
    local d = U.deepcopy(_data())
    local i = _findIndex(d.labs, id); if not i then return false end
    d.labs[i].heat = U.clamp((d.labs[i].heat or 0) + amount, 0, CLPHDS.LIMITS.MAX_HEAT)
    _save(d)
    L.write('heat', 'add', { lab = id, amount = amount, total = d.labs[i].heat }, source)
    return d.labs[i].heat
end

function LB.decayHeatAll(perMinute)
    local d = U.deepcopy(_data())
    for _, lab in ipairs(d.labs) do
        lab.heat = math.max(0, (lab.heat or 0) - (perMinute or 1.0))
    end
    _save(d)
end

return LB

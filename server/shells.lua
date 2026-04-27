-- ============================================================
--  server/shells.lua
--  Verwaltet Shell- / MLO-Definitionen (Innenräume für Labore).
--  Editierbar zur Laufzeit über das Admin-Panel - keine Hardcodes.
--
--  Eine Shell-Definition beschreibt einen Innenraum, in den ein
--  Labor instanziert werden kann:
--    id, label, kind ("apartment"|"house"|"warehouse"|"bunker"|"custom"),
--    ipl (optional IPL-Key fuer Map-Editor / DLC-MLOs),
--    interior_id (optional, zur Laufzeit per GetInteriorAtCoords ermittelbar),
--    teleport_in  { x,y,z,h }       Spawnpunkt im Inneren,
--    teleport_out { x,y,z,h }|null  Optionaler Override fuer Exit (sonst lab.anchor),
--    place_bounds { min,max }       Erlaubte Object-Placement-Box (relativ zu teleport_in),
--    fade_ms       Bildschirm-Fade,
--    doors         Liste mit Door-Hashes / Coords fuer Raid-System.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.shells = {}

local SH = CLPHDS.shells
local C  = CLPHDS.config
local L  = CLPHDS.logging
local U  = CLPHDS.util

local function _data() return C.get('shells') or { shells = {} } end
local function _save(d) C.set('shells', d) end

-- ----- Validation -----
local function isVec(t)
    return type(t) == 'table' and type(t.x) == 'number' and type(t.y) == 'number' and type(t.z) == 'number'
end

local function validate(s)
    if type(s) ~= 'table' then return false, 'not_table' end
    if not U.isString(s.id) then return false, 'invalid_id' end
    if not isVec(s.teleport_in) then return false, 'invalid_teleport_in' end
    if s.teleport_out ~= nil and not isVec(s.teleport_out) then
        if type(s.teleport_out) == 'table' and next(s.teleport_out) == nil then
            s.teleport_out = nil
        else
            return false, 'invalid_teleport_out'
        end
    end
    s.kind     = s.kind or 'apartment'
    s.fade_ms  = tonumber(s.fade_ms) or 500
    s.doors    = type(s.doors) == 'table' and s.doors or {}
    s.place_bounds = s.place_bounds or { min = { -12.0, -12.0, -2.0 }, max = { 12.0, 12.0, 4.0 } }
    return true
end

-- ----- Public API -----
function SH.list() return _data().shells end

function SH.get(id)
    for _, s in ipairs(_data().shells) do if s.id == id then return s end end
    return nil
end

function SH.upsert(s, source)
    local ok, err = validate(s)
    if not ok then return false, err end
    local d = U.deepcopy(_data())
    local found
    for i, x in ipairs(d.shells) do
        if x.id == s.id then d.shells[i] = s; found = true; break end
    end
    if not found then table.insert(d.shells, s) end
    _save(d)
    L.write('shells', 'upsert', { id = s.id }, source)
    return true
end

function SH.delete(id, source)
    local d = U.deepcopy(_data())
    for i, x in ipairs(d.shells) do
        if x.id == id then
            -- Schutz: nicht loeschen wenn noch Labore diese Shell referenzieren
            for _, lab in ipairs((C.get('labs') or {}).labs or {}) do
                if (lab.shell_id or lab.teleport) == id then
                    return false, 'in_use'
                end
            end
            table.remove(d.shells, i)
            _save(d)
            L.write('shells', 'delete', { id = id }, source)
            return true
        end
    end
    return false, 'not_found'
end

return SH

-- ============================================================
--  shared/utils.lua
--  Allgemein nutzbare Helfer (Server + Client)
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.util = {}

local U = CLPHDS.util

-- ---------- Logging ----------
function U.log(level, msg, ...)
    local prefix = ('[clp_hds][%s]'):format(level)
    print(prefix .. ' ' .. msg:format(...))
end

function U.info(msg, ...)  U.log('info',  msg, ...) end
function U.warn(msg, ...)  U.log('warn',  msg, ...) end
function U.error(msg, ...) U.log('error', msg, ...) end

-- ---------- Tabellen ----------
function U.deepcopy(o, seen)
    seen = seen or {}
    if type(o) ~= 'table' then return o end
    if seen[o] then return seen[o] end
    local copy = {}
    seen[o] = copy
    for k, v in pairs(o) do
        copy[U.deepcopy(k, seen)] = U.deepcopy(v, seen)
    end
    return setmetatable(copy, getmetatable(o))
end

function U.merge(target, source)
    for k, v in pairs(source) do
        if type(v) == 'table' and type(target[k]) == 'table' then
            U.merge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

function U.tlen(t)
    if type(t) ~= 'table' then return 0 end
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

function U.find(t, pred)
    for k, v in pairs(t) do
        if pred(v, k) then return v, k end
    end
end

-- ---------- IDs ----------
local function _hex() return ('%x'):format(math.random(0, 0xFFFF)) end
function U.uuid()
    return ('%s%s-%s-%s-%s-%s%s%s'):format(
        _hex(), _hex(), _hex(), _hex(), _hex(), _hex(), _hex(), _hex())
end

-- ---------- Math / Random ----------
function U.clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi end return v end
function U.lerp(a, b, t)    return a + (b - a) * t end

function U.weighted(choices)
    -- choices = { {weight=10, value='x'}, {weight=2, value='y'} }
    local total = 0
    for _, c in ipairs(choices) do total = total + (c.weight or 0) end
    if total <= 0 then return nil end
    local r = math.random() * total
    local acc = 0
    for _, c in ipairs(choices) do
        acc = acc + (c.weight or 0)
        if r <= acc then return c.value end
    end
    return choices[#choices].value
end

function U.chance(p) return math.random() < p end

-- ---------- Geometry ----------
function U.dist3(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- ---------- Validation ----------
function U.isString(s) return type(s) == 'string' and #s > 0 end
function U.isNumber(n) return type(n) == 'number' and n == n end
function U.isTable(t)  return type(t) == 'table' end

return U

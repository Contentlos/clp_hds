-- ============================================================
--  server/inventory.lua
--  Helfer für Item-Operationen, die das clp_hds-Item-Modell
--  (Qualität, Haltbarkeit) berücksichtigen.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.inv = {}

local INV = CLPHDS.inv
local I   = CLPHDS.items
local B   = CLPHDS.bridge
local U   = CLPHDS.util

-- Prüft ob ein Spieler genug Inputs für eine Liste hat
function INV.hasAll(src, list)
    for _, e in ipairs(list) do
        if B.getItemCount(src, e.item) < (e.count or 1) then return false, e.item end
    end
    return true
end

function INV.removeAll(src, list)
    for _, e in ipairs(list) do
        local ok = B.removeItem(src, e.item, e.count or 1)
        if not ok then return false, e.item end
    end
    return true
end

function INV.giveOutputs(src, list, quality)
    for _, o in ipairs(list) do
        local meta = {}
        if o.quality_from_minigame and quality then
            meta.quality = math.floor(U.clamp(quality, 0, CLPHDS.LIMITS.MAX_QUALITY))
        end
        local item = I.get(o.item)
        if item and item.decay_hours and item.decay_hours > 0 then
            meta.decay_at = os.time() + (item.decay_hours * 3600)
        end
        B.addItem(src, o.item, o.count or 1, meta)
    end
    return true
end

return INV

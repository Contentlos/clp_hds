-- ============================================================
--  server/placement.lua
--  Verarbeitet Platz-/Abbau-Anfragen aus dem Client.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.placement = {}

local PL = CLPHDS.placement
local LB = CLPHDS.labs
local I  = CLPHDS.items
local P  = CLPHDS.perms
local B  = CLPHDS.bridge
local U  = CLPHDS.util

-- Validierung: Item ist eine Station, Spieler hat es im Inventar, hat Rechte am Labor
RegisterNetEvent(CLPHDS.EVT.LAB_PLACE_OBJECT, function(labId, itemId, position, rotation)
    local src = source
    local lab = LB.get(labId)
    if not lab then return B.notify(src, 'Labor nicht gefunden', 'error') end

    local id = B.getIdentifier(src)
    if not P.canManageLab(lab, id) then return B.notify(src, 'Keine Berechtigung', 'error') end

    local item = I.get(itemId)
    if not item or item.type ~= CLPHDS.ITEM_TYPES.STATION then
        return B.notify(src, 'Ungültiges Stations-Item', 'error')
    end

    if B.getItemCount(src, itemId) < 1 then
        return B.notify(src, 'Kein passendes Item im Inventar', 'error')
    end

    if not B.removeItem(src, itemId, 1) then
        return B.notify(src, 'Item konnte nicht entfernt werden', 'error')
    end

    local obj = LB.addObject(labId, {
        item     = itemId,
        model    = item.model or 'prop_table_03',
        pos      = position,
        rot      = rotation,
        placed_by= id,
        placed_at= os.time(),
    }, src)

    if not obj then
        B.addItem(src, itemId, 1) -- rollback
        return B.notify(src, 'Limit erreicht oder Fehler', 'error')
    end

    TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, labId, LB.get(labId))
    B.notify(src, 'Objekt platziert', 'success')
end)

RegisterNetEvent(CLPHDS.EVT.LAB_REMOVE_OBJECT, function(labId, uid, rapid)
    local src = source
    local lab = LB.get(labId)
    if not lab then return end
    local id = B.getIdentifier(src)
    if not P.canManageLab(lab, id) then return B.notify(src, 'Keine Berechtigung', 'error') end

    local target
    for _, o in ipairs(lab.objects) do if o.uid == uid then target = o; break end end
    if not target then return end

    -- bei Rapid-Dismantle bekommt der Spieler nur 50% zurück
    local refundCount = rapid and 0 or 1
    if refundCount > 0 then B.addItem(src, target.item, refundCount) end

    LB.removeObject(labId, uid, src)
    TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, labId, LB.get(labId))
    B.notify(src, rapid and 'Schnellabbau erledigt (kein Refund)' or 'Objekt abgebaut', 'success')
end)

return PL

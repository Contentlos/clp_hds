-- ============================================================
--  server/crafting.lua
--  Crafting-Pipeline: Inputs konsumieren, Minigame-Ergebnis bewerten,
--  Outputs gewähren, Heat erzeugen.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.craft = {}

local CR = CLPHDS.craft
local C  = CLPHDS.config
local I  = CLPHDS.items
local INV= CLPHDS.inv
local LB = CLPHDS.labs
local P  = CLPHDS.perms
local B  = CLPHDS.bridge
local U  = CLPHDS.util
local L  = CLPHDS.logging

local function findRecipe(id)
    for _, r in ipairs((C.get('recipes') or {}).recipes or {}) do
        if r.id == id then return r end
    end
end

local function findDrug(id)
    for _, d in ipairs((C.get('drugs') or {}).drugs or {}) do
        if d.id == id then return d end
    end
end

-- Active sessions, keyed by source -> { recipe, lab, started, station_uid }
local _active = {}

ESX_RegisterServerCallback = ESX_RegisterServerCallback or function() end

-- Spieler startet ein Crafting
RegisterNetEvent(CLPHDS.EVT.CRAFT_START, function(labId, recipeId, stationUid)
    local src = source
    local lab = LB.get(labId)
    if not lab then return B.notify(src, 'Labor nicht gefunden', 'error') end

    local id = B.getIdentifier(src)
    if not P.canUseStation(lab, id) then return B.notify(src, 'Kein Zugriff auf Station', 'error') end

    local recipe = findRecipe(recipeId)
    if not recipe then return B.notify(src, 'Rezept unbekannt', 'error') end

    -- Station-Type Check
    local station
    for _, o in ipairs(lab.objects) do
        if o.uid == stationUid then station = o; break end
    end
    if not station or station.item ~= recipe.station then
        return B.notify(src, 'Falsche Station für dieses Rezept', 'error')
    end

    -- Inputs prüfen + entfernen
    local ok, missing = INV.hasAll(src, recipe.inputs)
    if not ok then return B.notify(src, ('Fehlt: %s'):format(missing), 'error') end

    -- Tools: prüfen, ggf. konsumieren
    for _, t in ipairs(recipe.tools or {}) do
        if B.getItemCount(src, t.item) < 1 then
            return B.notify(src, ('Werkzeug fehlt: %s'):format(t.item), 'error')
        end
    end

    INV.removeAll(src, recipe.inputs)
    for _, t in ipairs(recipe.tools or {}) do
        if t.consume then B.removeItem(src, t.item, 1) end
    end

    _active[src] = {
        recipe   = recipe,
        labId    = labId,
        stationUid = stationUid,
        started  = os.time(),
    }

    -- Minigame triggern
    local drug = findDrug(recipe.drug) or {}
    TriggerClientEvent('clp_hds:minigame:start', src, {
        recipeId   = recipe.id,
        drugId     = recipe.drug,
        minigameId = recipe.minigame or (drug.minigame and drug.minigame.id) or 'meth',
        difficulty = (drug.minigame and drug.minigame.difficulty) or 0.5,
        duration   = recipe.duration_sec or (drug.minigame and drug.minigame.duration) or 20,
    })
end)

-- Client meldet Minigame-Ergebnis zurück
RegisterNetEvent(CLPHDS.EVT.MINIGAME_RESULT, function(score)
    local src = source
    local sess = _active[src]
    if not sess then return end
    _active[src] = nil

    local recipe = sess.recipe
    local cs     = C.get('admin_settings') or {}
    cs           = cs.crafting or { perfect_batch_chance = 0.05, quality_min = 25, quality_max = 100, fail_destroys_inputs = true }

    score = U.clamp(tonumber(score) or 0, 0, 1)
    local successRoll  = math.random()
    local successChance = U.clamp((recipe.success_base or 0.85) * (0.5 + 0.5 * score), 0.05, 1.0)
    local success      = successRoll <= successChance

    local quality = math.floor(U.lerp(cs.quality_min or 25, cs.quality_max or 100, score))
    if U.chance(cs.perfect_batch_chance or 0.05) and success then
        quality = CLPHDS.LIMITS.MAX_QUALITY
    end

    local drug = findDrug(recipe.drug) or {}

    if not success then
        if cs.fail_destroys_inputs == false then
            -- Inputs zurückgeben
            for _, e in ipairs(recipe.inputs) do B.addItem(src, e.item, e.count or 1) end
        end
        B.notify(src, 'Crafting fehlgeschlagen!', 'error')
        L.write('craft', 'fail', { recipe = recipe.id, score = score }, src)
        -- Heat trotzdem leicht erhöhen (Aktivität wurde wahrgenommen)
        LB.addHeat(sess.labId, math.floor((drug.heat_per_craft or 5) * 0.4), src)
        TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, sess.labId, LB.get(sess.labId))
        return
    end

    INV.giveOutputs(src, recipe.outputs, quality)
    LB.addHeat(sess.labId, drug.heat_per_craft or 5, src)
    TriggerClientEvent(CLPHDS.EVT.LAB_SYNC, -1, sess.labId, LB.get(sess.labId))
    B.notify(src, ('Crafting erfolgreich (Q %d)'):format(quality), 'success')
    L.write('craft', 'success', { recipe = recipe.id, quality = quality, score = score }, src)
end)

return CR

-- ============================================================
--  client/halluc.lua
--  Visuelle Halluzinations-Effekte bei LSD-Fehlschlag.
--  Nutzt vorhandene GTA Postfx-Stacks. Keine externen Assets nötig.
-- ============================================================

CLPHDS = CLPHDS or {}

local _active = false

local function applyEffect(seconds)
    if _active then return end
    _active = true
    AnimpostfxPlay('DrugsMichaelAliensFightIn', 0, true)
    SetTimecycleModifier('drug_drive_in')
    SetTimecycleModifierStrength(1.0)
    ShakeGameplayCam('DRUNK_SHAKE', 0.6)
    SetTimeout(seconds * 1000, function()
        AnimpostfxStop('DrugsMichaelAliensFightIn')
        ClearTimecycleModifier()
        ShakeGameplayCam('DRUNK_SHAKE', 0.0)
        StopGameplayCamShaking(true)
        _active = false
    end)
end

AddEventHandler('clp_hds:halluc:start', function(seconds)
    applyEffect(tonumber(seconds) or 10)
end)

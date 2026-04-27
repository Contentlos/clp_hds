-- ============================================================
--  client/heat.lua
--  Empfängt Heat-Updates für Polizei-HUD.
-- ============================================================

CLPHDS = CLPHDS or {}

local _heat = {}

RegisterNetEvent(CLPHDS.EVT.HEAT_UPDATE, function(map)
    _heat = map or {}
    SendNUIMessage({ type = 'heat:update', data = _heat })
end)

CLPHDS.heat = { state = function() return _heat end }

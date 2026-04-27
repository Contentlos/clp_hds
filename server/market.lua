-- ============================================================
--  server/market.lua
--  Dynamische Drogen-Marktpreise.
--  Aktuelle Preise stehen in CLPHDS.market.prices und werden via
--  CONFIG_PUSH (name = "market_prices") an Clients verteilt.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.market = { prices = {} }

local M = CLPHDS.market
local C = CLPHDS.config
local U = CLPHDS.util

local function updatePrices()
    local cfg = (C.get('admin_settings') or {}).market or {}
    local volatility = cfg.volatility or 0.18
    local floor = cfg.price_floor_pct  or 0.55
    local ceil  = cfg.price_ceiling_pct or 1.65

    for _, drug in ipairs((C.get('drugs') or {}).drugs or {}) do
        local base = drug.base_price or 100
        local prev = M.prices[drug.id] or base
        local drift = (math.random() - 0.5) * 2 * volatility
        local next = prev * (1.0 + drift)
        next = U.clamp(next, base * floor, base * ceil)
        M.prices[drug.id] = math.floor(next)
    end
    TriggerClientEvent(CLPHDS.EVT.CONFIG_PUSH, -1, 'market_prices', M.prices)
end

CreateThread(function()
    Wait(3000)
    updatePrices()
    while true do
        local cfg = (C.get('admin_settings') or {}).market or {}
        Wait((cfg.update_interval_sec or 300) * 1000)
        updatePrices()
    end
end)

return M

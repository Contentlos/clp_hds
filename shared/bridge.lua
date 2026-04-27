-- ============================================================
--  shared/bridge.lua
--  Dünner ESX Bridge-Layer.
--  Alle Aufrufe ins Framework laufen über CLPHDS.bridge.* damit
--  ein späterer QBCore-Port nur diese Datei austauschen muss.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.bridge = {}

local B = CLPHDS.bridge

-- ESX import (geliefert via @es_extended/imports.lua im fxmanifest)
local ESX = exports.es_extended and exports.es_extended:getSharedObject() or nil

B.framework = 'esx'

-- ---------- Player Resolution ----------
if IsDuplicityVersion() then
    -- Server
    function B.getPlayer(src)
        if not ESX then return nil end
        return ESX.GetPlayerFromId(src)
    end

    function B.getIdentifier(src)
        local p = B.getPlayer(src)
        return p and p.identifier or nil
    end

    function B.getJob(src)
        local p = B.getPlayer(src)
        return p and p.job and p.job.name or 'unemployed'
    end

    function B.isCop(src)
        local job = B.getJob(src)
        local cfg = (CLPHDS.config and CLPHDS.config.get and CLPHDS.config.get('admin_settings'))
                    or {}
        local police = cfg.police_jobs or { 'police', 'sheriff', 'sasp', 'lspd' }
        for _, j in ipairs(police) do if j == job then return true end end
        return false
    end

    function B.addItem(src, item, count, metadata)
        local p = B.getPlayer(src)
        if not p then return false end
        -- ESX legacy + ox_inventory Kompatibilität
        if exports.ox_inventory then
            return exports.ox_inventory:AddItem(src, item, count, metadata)
        end
        p.addInventoryItem(item, count)
        return true
    end

    function B.removeItem(src, item, count)
        local p = B.getPlayer(src)
        if not p then return false end
        if exports.ox_inventory then
            return exports.ox_inventory:RemoveItem(src, item, count)
        end
        local has = p.getInventoryItem(item)
        if not has or has.count < count then return false end
        p.removeInventoryItem(item, count)
        return true
    end

    function B.getItemCount(src, item)
        local p = B.getPlayer(src)
        if not p then return 0 end
        if exports.ox_inventory then
            return exports.ox_inventory:GetItemCount(src, item) or 0
        end
        local i = p.getInventoryItem(item)
        return (i and i.count) or 0
    end

    function B.notify(src, msg, kind)
        TriggerClientEvent('clp_hds:notify', src, msg, kind or 'info')
    end

    function B.getOnlinePlayers()
        if ESX and ESX.GetPlayers then return ESX.GetPlayers() end
        return GetPlayers()
    end
else
    -- Client
    function B.getPlayerData()
        return ESX and ESX.GetPlayerData() or {}
    end

    function B.notify(msg, kind)
        kind = kind or 'info'
        if ESX and ESX.ShowNotification then
            ESX.ShowNotification(msg)
        else
            BeginTextCommandThefeedPost('STRING')
            AddTextComponentSubstringPlayerName(msg)
            EndTextCommandThefeedPostTicker(false, true)
        end
    end

    function B.isCop()
        local pd = B.getPlayerData()
        local job = pd and pd.job and pd.job.name or 'unemployed'
        local cfg = (CLPHDS.config and CLPHDS.config.get and CLPHDS.config.get('admin_settings'))
                    or {}
        local police = cfg.police_jobs or { 'police', 'sheriff', 'sasp', 'lspd' }
        for _, j in ipairs(police) do if j == job then return true end end
        return false
    end
end

-- ESX-Objekt für direkten Zugriff bereitstellen (Backwards-Compat)
B.ESX = ESX

return B

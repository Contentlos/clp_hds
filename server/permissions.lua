-- ============================================================
--  server/permissions.lua
--  ACL-Management für Labore und Adminrechte.
-- ============================================================

CLPHDS = CLPHDS or {}
CLPHDS.perms = {}

local P = CLPHDS.perms
local C = CLPHDS.config
local B = CLPHDS.bridge
local U = CLPHDS.util

-- ---------- Admin-Level ----------
function P.adminLevel(src)
    if not src then return CLPHDS.ADMIN_LEVELS.NONE end
    local s = C.get('admin_settings') or {}
    -- Superadmin via Identifier
    local id = B.getIdentifier(src)
    for _, super in ipairs(s.superadmin_ids or {}) do
        if super == id then return CLPHDS.ADMIN_LEVELS.SUPERADMIN end
    end
    -- ESX/ACE Gruppe
    if IsPlayerAceAllowed(src, 'clp_hds.superadmin') then return CLPHDS.ADMIN_LEVELS.SUPERADMIN end
    if IsPlayerAceAllowed(src, 'clp_hds.admin')       then return CLPHDS.ADMIN_LEVELS.ADMIN end
    if IsPlayerAceAllowed(src, 'clp_hds.moderator')   then return CLPHDS.ADMIN_LEVELS.MODERATOR end
    -- ESX Gruppen
    local p = B.getPlayer(src)
    local group = p and p.getGroup and p:getGroup() or (p and p.group)
    if group then
        for _, g in ipairs(s.admin_groups or {}) do
            if g == group then
                if group == 'superadmin' then return CLPHDS.ADMIN_LEVELS.SUPERADMIN end
                return CLPHDS.ADMIN_LEVELS.ADMIN
            end
        end
    end
    return CLPHDS.ADMIN_LEVELS.NONE
end

function P.requireAdmin(src, minLevel)
    local lvl = P.adminLevel(src)
    return lvl >= (minLevel or CLPHDS.ADMIN_LEVELS.ADMIN)
end

-- ---------- Labor-Rollen ----------
function P.labRole(lab, identifier)
    if not lab or not identifier then return CLPHDS.LAB_ROLES.NONE end
    if lab.owner == identifier then return CLPHDS.LAB_ROLES.OWNER end
    for _, m in ipairs(lab.members or {}) do
        if m.identifier == identifier then
            if m.role == 'owner'  then return CLPHDS.LAB_ROLES.OWNER  end
            if m.role == 'member' then return CLPHDS.LAB_ROLES.MEMBER end
            if m.role == 'worker' then return CLPHDS.LAB_ROLES.WORKER end
        end
    end
    return CLPHDS.LAB_ROLES.NONE
end

function P.canUseStation(lab, identifier)
    return P.labRole(lab, identifier) >= CLPHDS.LAB_ROLES.WORKER
end

function P.canManageLab(lab, identifier)
    return P.labRole(lab, identifier) >= CLPHDS.LAB_ROLES.MEMBER
end

function P.canOwnerOnly(lab, identifier)
    return P.labRole(lab, identifier) == CLPHDS.LAB_ROLES.OWNER
end

return P

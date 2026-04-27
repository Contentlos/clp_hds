-- ============================================================
--  clp_hds - Hardcore Drugs System
--  Modulares Drogen-Crafting Framework für ESX
-- ============================================================

fx_version 'cerulean'
games { 'gta5' }

author      'Contentlos / Nico'
description 'Hardcore Drugs System (clp_hds) - modulares Crafting, Labore, Minigames, Admin Panel'
version     '0.1.0'
lua54       'yes'

-- ----------------------------------------------------------------
-- SHARED
-- ----------------------------------------------------------------
shared_scripts {
    '@es_extended/imports.lua',
    'shared/constants.lua',
    'shared/utils.lua',
    'shared/bridge.lua',
}

-- ----------------------------------------------------------------
-- SERVER
-- ----------------------------------------------------------------
server_scripts {
    'server/storage.lua',
    'server/logging.lua',
    'server/live_config.lua',
    'server/items.lua',
    'server/inventory.lua',
    'server/permissions.lua',
    'server/labs.lua',
    'server/shells.lua',
    'server/placement.lua',
    'server/crafting.lua',
    'server/gathering.lua',
    'server/heat.lua',
    'server/police.lua',
    'server/market.lua',
    'server/admin.lua',
    'server/main.lua',
}

-- ----------------------------------------------------------------
-- CLIENT
-- ----------------------------------------------------------------
client_scripts {
    'client/live_config.lua',
    'client/nui.lua',
    'client/instance.lua',
    'client/placement.lua',
    'client/labs.lua',
    'client/crafting.lua',
    'client/minigames.lua',
    'client/gathering.lua',
    'client/heat.lua',
    'client/police.lua',
    'client/halluc.lua',
    'client/admin.lua',
    'client/main.lua',
}

-- ----------------------------------------------------------------
-- NUI
-- ----------------------------------------------------------------
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/admin.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/js/minigames/*.js',
    'html/js/admin/*.js',
    'html/assets/sounds/*.ogg',
    'html/assets/img/*.png',

    -- bootstrap config + persisted data shipped with the resource
    'config/default_config.lua',
    'data/items.json',
    'data/recipes.json',
    'data/drugs.json',
    'data/labs.json',
    'data/shells.json',
    'data/zones.json',
    'data/admin_settings.json',
    'data/logs.json',
}

-- ----------------------------------------------------------------
-- DEPENDENCIES
-- ----------------------------------------------------------------
dependency 'es_extended'

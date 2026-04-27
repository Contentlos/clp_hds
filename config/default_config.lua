-- ============================================================
--  config/default_config.lua
--  BOOTSTRAP-Defaults. Wird NUR genutzt wenn die JSON-Dateien
--  unter data/*.json fehlen oder leer sind.
--  Für Live-Anpassungen das ingame Admin-Panel nutzen!
-- ============================================================

return {
    -- Globale Adminschutz-Einstellungen
    admin_settings = {
        admin_groups   = { 'admin', 'superadmin' }, -- ESX/ACE Gruppen mit Adminrechten
        superadmin_ids = { },                       -- Steam/License Identifier mit Superadmin
        require_pin    = false,
        pin_hash       = '',
        police_jobs    = { 'police', 'sheriff', 'sasp', 'lspd' },
        autosave_interval_sec = 60,
        log_retention_days    = 30,
        -- Live-Sync: alles was hier landet wird per CONFIG_PUSH an Clients gespiegelt
        broadcast_blacklist = { 'pin_hash', 'superadmin_ids' },
    },

    -- Heat / Polizei
    heat = {
        decay_per_minute   = 1.5,
        smell_radius       = 60.0,
        smell_threshold    = 35,
        raid_threshold     = 80,
        raid_chance        = 0.35,
        electricity_factor = 0.6, -- höher = stärker getriggert durch Stromverbrauch
    },

    -- Marktpreise / Dynamik
    market = {
        update_interval_sec = 300,
        volatility          = 0.18,
        price_floor_pct     = 0.55,
        price_ceiling_pct   = 1.65,
    },

    -- Crafting
    crafting = {
        perfect_batch_chance = 0.05,
        quality_min          = 25,
        quality_max          = 100,
        fail_destroys_inputs = true,
    },

    -- Sammelsystem
    gathering = {
        zone_rotation_minutes = 45,
        active_zones_max      = 4,
        npc_vendor_chance     = 0.20,
    },

    -- Labor / Placement
    labs = {
        teleport_in_offset    = vector3(0.0, 0.0, 0.5),
        ghost_grid_step       = 0.05,
        ghost_rotation_step   = 5.0,
        rapid_dismantle_sec   = 20,
        dismantle_sec         = 90,
    },
}

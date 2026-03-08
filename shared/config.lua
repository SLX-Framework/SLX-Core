SLX = SLX or {}

SLX.Config = {
    Framework    = 'SLX',
    Version      = '1.0.0',

    -- Debug mode: prints detailed spawn/load/event logs to console
    -- Set to false in production to reduce console spam
    Debug = true,

    -- Default player model (freemode male)
    DefaultModel = 'mp_m_freemode_01',

    -- Default spawn location (Legion Square area)
    -- Also used as respawn position after death
    DefaultSpawn = { x = -269.4, y = -955.3, z = 31.2, heading = 205.0 },

    -- Respawn delay in seconds after death
    RespawnDelay = 5,


    -- Starting money for new players
    StartingMoney = 500,

    -- Client-side position/health sync interval in milliseconds (2 minutes)
    ClientSyncInterval = 120000,

    -- ============================================================
    -- Gameplay Toggles
    -- ============================================================

    -- Infinite ammo: weapons never run out of total ammo but still require reloading
    EnableInfiniteAmmo = true,

    -- XP awarded per kill
    XpPerKill = 10,

    -- Money reward per kill ($)
    KillMoneyReward = 100,

    DisableHealthRegeneration = true,   -- Player will no longer regenerate health
    DisableVehicleRewards     = true,   -- Disables player receiving weapons from vehicles
    DisableNPCDrops           = true,   -- Stops NPCs from dropping weapons on death
    DisableDispatchServices   = true,   -- Disable dispatch services (police, fire, ambulance)
    DisableScenarios          = true,   -- Disable ambient scenarios (NPCs sitting, etc.)
    DisableAimAssist          = true,  -- Disables aim assist (mainly on controllers)
    DisableDisplayAmmo        = true,  -- Disable ammunition display
    EnablePVP                 = true,   -- Allow player-to-player combat
    EnableWantedLevel         = false,  -- Use normal GTA wanted level
    EnableHandsUp             = true,   -- Allow hands up animation (H key)
    EnableESXBridge           = true,   -- Provide ESX compatibility layer (es_extended bridge)
    EnableCustomDeathSync     = false,  -- When true, kills by other players (killedBy) skip built-in death handling so external sync can handle it
    MaxInventoryWeight        = 50,    -- Maximum total weight a player can carry in their inventory

    -- ============================================================
    -- Command Permissions — minimum group required per command
    -- Console (rcon) always has full access regardless of these settings.
    -- Available groups: user, mod, admin, superadmin
    -- ============================================================
    CommandPermissions = {
        givemoney    = 'admin',
        removemoney  = 'admin',
        setmoney     = 'admin',
        giveweapon   = 'admin',
        removeweapon = 'admin',
        setjob       = 'admin',
        setgroup     = 'superadmin',
        kick         = 'mod',
        ban          = 'admin',
        unban        = 'admin',
        bring        = 'mod',
        ['goto']     = 'mod',
        heal         = 'mod',
        revive       = 'mod',
        kill         = 'admin',
        tp           = 'mod',
        announce     = 'mod',
        giveitem     = 'admin',
        removeitem   = 'admin',
    },

    -- ============================================================
    -- Hardcap — Built-in player limit (replaces hardcap resource)
    -- ============================================================
    EnableHardcap = true,               -- Enforce max player limit on connect
    MaxPlayers    = 5,                 -- Fallback if sv_maxclients convar is not set
    PriorityGroups = { 'mod', 'admin', 'superadmin' },  -- Groups that bypass full server


    -- ============================================================
    -- Discord Rich Presence
    -- Requires a Discord Application with assets uploaded
    -- ============================================================
    EnableDiscordRPC = true,
    DiscordRPC = {
        appId         = '1394833727347232899',
        largeAsset    = 'server_logo',
        largeText     = 'CrimeLife',
        smallAsset    = '',
        smallText     = '',
        updateInterval = 60000,
        buttons = {
            { label = 'Beitreten', url = 'https://cfx.re/join/rz9z38' },
            { label = 'Discord',   url = 'https://discord.gg/8vUFKK9t' },
        },
    },

    -- ============================================================
    -- Job Creator — admin permission required
    -- ============================================================
    -- Table of groups that can use the job creator
    JobCreatorPermission = { 'admin', 'superadmin' },

    -- ============================================================
    -- HUD Component Removal
    -- Set to true to HIDE the component, false to keep it visible.
    -- ============================================================
    RemoveHudComponents = {
        [1]  = false,  -- WANTED_STARS
        [2]  = false,  -- WEAPON_ICON
        [3]  = true,  -- CASH
        [4]  = true,  -- MP_CASH
        [5]  = false,  -- MP_MESSAGE
        [6]  = true,   -- VEHICLE_NAME
        [7]  = true,   -- AREA_NAME
        [8]  = true,   -- VEHICLE_CLASS
        [9]  = true,   -- STREET_NAME
        [10] = false,  -- HELP_TEXT
        [11] = false,  -- FLOATING_HELP_TEXT_1
        [12] = false,  -- FLOATING_HELP_TEXT_2
        [13] = true,  -- CASH_CHANGE
        [14] = false,  -- RETICLE
        [15] = false,  -- SUBTITLE_TEXT
        [16] = false,  -- RADIO_STATIONS
        [17] = false,  -- SAVING_GAME
        [18] = false,  -- GAME_STREAM
        [19] = false,  -- WEAPON_WHEEL
        [20] = false,  -- WEAPON_WHEEL_STATS
        [21] = true,  -- HUD_COMPONENTS
        [22] = true,  -- HUD_WEAPONS
    },
}

fx_version 'cerulean'
game 'gta5'
name 'slx'
author 'SLX Team'
description 'SLX — Lightweight FiveM Crimelife framework'
version '1.0.0'
dependency 'oxmysql'
provide 'es_extended'

files {
    'loadingscreen/**/*',
    'loadingscreen/music/**/*',
}

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/core/main.lua',
    'server/core/callbacks.lua',
    'server/core/permissions.lua',
    'server/core/player.lua',
    'server/gameplay/economy.lua',
    'server/gameplay/jobs.lua',
    'server/gameplay/death.lua',
    'server/gameplay/save.lua',
    'server/gameplay/commands.lua',
    'server/gameplay/skin.lua',
    'server/gameplay/inventory.lua',
    'server/gameplay/leaderboard.lua',
    'server/gameplay/jobcreator.lua',
    'server/exports.lua',
    'bridge/esx/server.lua',
}

client_scripts {
    'client/lib/NativeUI.lua',
    'client/core/main.lua',
    'client/core/callbacks.lua',
    'client/gameplay/functions.lua',
    'client/core/spawn.lua',
    'client/gameplay/cleanup.lua',
    'client/gameplay/voice.lua',
    'client/gameplay/death.lua',
    'client/gameplay/skin.lua',
    'client/gameplay/skinpresets.lua',

    'client/gameplay/streak.lua',
    'client/gameplay/discord.lua',
    'client/gameplay/jobcreator.lua',
    'client/core/sync.lua',
    'client/exports.lua',
    'bridge/esx/client.lua',
}


loadscreen 'loadingscreen/index.html'
loadscreen_manual_shutdown 'yes'


server_exports {
    'getCoreObject',
    'GetPlayer',
    'GetPlayerByIdentifier',
    'GetAllPlayers',
    'IsPlayerLoaded',
    'GetPlayerByID',
    'GetSourceFromID',
    'GetIDFromSource',
    'GetMoney',
    'AddMoney',
    'RemoveMoney',
    'SetMoney',
    'GetJob',
    'SetJob',
    'GiveWeapon',
    'RemoveWeapon',
    'GetWeapons',
    'GetKills',
    'GetDeaths',
    'GetPlaytime',
    'GetXp',
    'AddXp',
    'SetXp',
    'GetStatus',
    'SetStatus',
    'GetGroup',
    'SetGroup',
    'HasPermission',
    'RegisterServerCallback',
    'getSharedObject',
    'GetPlayerFromId',
    'GetPlayerFromIdentifier',
    'GetExtendedPlayers',
    'GetJobs',
    'GetPlayerCount',
    'SavePlayer',
    'SavePlayers',
    'TriggerServerCallback',
    'Trace',
    'Notify',
    'GetLeaderboard',
    'GetInventory',
    'GetInventoryItem',
    'AddInventoryItem',
    'RemoveInventoryItem',
    'HasInventoryItem',
    'CanCarryItem',
    'RegisterItemUse',
    'GetItems',
    'GetUsableItems',
    'RegisterUsableItem',
    'UseItem',
}

client_exports {
    'getCoreObject',
    'getLocalPlayer',
    'getJob',
    'getMoney',
    'getGroup',
    'getStatus',
    'getKills',
    'getDeaths',
    'getXp',
    'isPlayerLoaded',
    'getPlayerId',
    'ShowNotification',
    'ShowAdvancedNotification',
    'Progressbar',
    'CancelProgressbar',
    'ShowAnnounce',
    'SpawnVehicle',
    'DeleteVehicle',
    'GetPlayers',
    'GetClosestPlayer',
    'GetVehicleInDirection',
    'GetClosestVehicle',
    'GetVehiclesInArea',
    'GetClosestPed',
    'GetWeaponLabel',
    'GetWeaponList',
    'GetPlayersInArea',
    'GetClosestObject',
    'GetObjects',
    'GetPeds',
    'SpawnObject',
    'SpawnLocalObject',
    'DeleteObject',
    'Teleport',
    'getSharedObject',
    'GetVoiceMode',
    'GetVoiceRange',
    'GetVoiceLabel',
    'IsPlayerTalking',

    'GetKillStreak',
    'GetSkinPresets',
    'SaveSkinPreset',
    'getInventory',
    'getInventoryItem',
    'hasInventoryItem',
    'UseItem',
}
SLX = SLX or {}
SLX.Callbacks = {}
SLX.ServerCallbacks = {}

SLX.LocalPlayer = {
    id         = nil,
    source     = nil,
    identifier = nil,
    group      = { name = 'user', label = 'User', priority = 0 },
    job        = { name = 'unemployed', grade = 0, label = 'Unemployed', salary = 0 },
    money      = 0,
    status     = {},
    kills      = 0,
    deaths     = 0,
    xp         = 0,
    spawned    = false,
    inventory  = {},
}

SLX.Cache = {
    ped    = 0,
    coords = nil,
}

function SLX.GetJob()
    return SLX.LocalPlayer.job
end

function SLX.GetMoney()
    return SLX.LocalPlayer.money
end

function SLX.GetGroup()
    return SLX.LocalPlayer.group
end

function SLX.GetInventory()
    return SLX.LocalPlayer.inventory
end

CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(500) end
    SLX.Debug('Network session started, requesting spawn data')
    TriggerServerEvent('slx:requestSpawnData')
    SLX.Log('INFO', 'Requested spawn data from server')
end)

RegisterNetEvent('slx:recv_money')
AddEventHandler('slx:recv_money', function(newMoney)
    SLX.LocalPlayer.money = newMoney
    TriggerEvent('slx:moneyUpdated', newMoney)
end)

RegisterNetEvent('slx:recv_job')
AddEventHandler('slx:recv_job', function(jobData)
    SLX.LocalPlayer.job = jobData
    TriggerEvent('slx:jobUpdated', jobData)
end)

RegisterNetEvent('slx:recv_group')
AddEventHandler('slx:recv_group', function(groupData)
    SLX.LocalPlayer.group = groupData
    TriggerEvent('slx:groupUpdated', groupData)
end)

RegisterNetEvent('slx:recv_xp')
AddEventHandler('slx:recv_xp', function(newXp)
    SLX.LocalPlayer.xp = newXp
    TriggerEvent('slx:xpUpdated', newXp)
end)

RegisterNetEvent('slx:recv_inventory')
AddEventHandler('slx:recv_inventory', function(inventoryData)
    SLX.LocalPlayer.inventory = inventoryData
    TriggerEvent('slx:inventoryUpdated', inventoryData)
end)

RegisterNetEvent('slx:recv_weapons')
AddEventHandler('slx:recv_weapons', function(weaponsData)
    local ped = PlayerPedId()
    RemoveAllPedWeapons(ped, true)
    for i = 1, #weaponsData do
        local w = weaponsData[i]
        GiveWeaponToPed(ped, GetHashKey(w.weapon), w.ammo, false, false)
    end
end)

RegisterNetEvent('slx:notify')
AddEventHandler('slx:notify', function(msg, notifyType, length)
    exports['slang_core']:SendNotification(msg, notifyType or 'info', length or 5000)
end)

RegisterNetEvent('slx:announce')
AddEventHandler('slx:announce', function(msg, duration)
    exports['slang_core']:ShowAnnounce(msg, duration or 8000)
end)

RegisterNetEvent('slx:recv_teleport')
AddEventHandler('slx:recv_teleport', function(coords)
    SLX.Debug(('recv_teleport: %.1f, %.1f, %.1f'):format(coords.x, coords.y, coords.z))
    DoScreenFadeOut(200)
    Wait(300)
    local ped = PlayerPedId()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    if coords.heading then SetEntityHeading(ped, coords.heading) end
    local timeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and timeout < 3000 do
        Wait(50)
        timeout = timeout + 50
    end
    SLX.Cache.ped = ped
    SLX.Cache.coords = vector3(coords.x, coords.y, coords.z)
    DoScreenFadeIn(500)
end)

RegisterNetEvent('slx:recv_heal')
AddEventHandler('slx:recv_heal', function(health, armour)
    local ped = PlayerPedId()
    SetEntityHealth(ped, health)
    SetPedArmour(ped, armour or 0)
    ClearPedBloodDamage(ped)
    ClearPedLastWeaponDamage(ped)
    SLX.Debug(('recv_heal: health=%d armour=%d'):format(health, armour or 0))
end)

RegisterNetEvent('slx:recv_kill')
AddEventHandler('slx:recv_kill', function()
    SetEntityHealth(PlayerPedId(), 0)
    SLX.Debug('recv_kill: player killed by admin')
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    if SLX.LocalPlayer.spawned then TriggerEvent('slx:playerUnloaded') end
end)

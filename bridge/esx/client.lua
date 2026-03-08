if not SLX.Config.EnableESXBridge then
    exports('getSharedObject', function() return nil end)
    return
end

ESX = {}
ESX.PlayerLoaded = false
ESX.PlayerData = {}
ESX.Game = {}

SLX.Debug('[ESX Bridge] Client-side ESX bridge initializing')

AddEventHandler('esx:getSharedObject', function(cb)
    if cb then cb(ESX) end
end)

---@return table
function ESX.GetPlayerData()
    return ESX.PlayerData
end

---@return boolean
function ESX.IsPlayerLoaded()
    return SLX.LocalPlayer.spawned
end

---@param msg string
function ESX.ShowNotification(msg)
    SLX.ShowNotification(msg)
end

---@param sender string
---@param subject string
---@param msg string
---@param textureDict string
---@param iconType? number
---@param flash? boolean
---@param saveToBrief? boolean
---@param hudColorIndex? number
function ESX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    SLX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
end

---@param name string
---@param cb function
---@param ... any
function ESX.TriggerServerCallback(name, cb, ...)
    SLX.TriggerServerCallback(name, cb, ...)
end

---@param model string|number
---@param coords vector3
---@param heading number
---@param cb? function
function ESX.Game.SpawnVehicle(model, coords, heading, cb)
    SLX.Game.SpawnVehicle(model, coords, heading, cb)
end

---@param vehicle number
function ESX.Game.DeleteVehicle(vehicle)
    SLX.Game.DeleteVehicle(vehicle)
end

---@param onlyOther? boolean
---@param keyVal? boolean
---@param peds? boolean
---@return table
function ESX.Game.GetPlayers(onlyOther, keyVal, peds)
    return SLX.Game.GetPlayers(onlyOther, keyVal, peds)
end

---@param coords? vector3
---@return number|nil, number
function ESX.Game.GetClosestPlayer(coords)
    return SLX.Game.GetClosestPlayer(coords)
end

---@return number|nil
function ESX.Game.GetVehicleInDirection()
    return SLX.Game.GetVehicleInDirection()
end

---@param coords? vector3
---@return number|nil closestVehicle
---@return number closestDist
function ESX.Game.GetClosestVehicle(coords)
    return SLX.Game.GetClosestVehicle(coords)
end

---@param coords vector3
---@param radius number
---@return table
function ESX.Game.GetVehiclesInArea(coords, radius)
    return SLX.Game.GetVehiclesInArea(coords, radius)
end

---@param coords? vector3
---@return number|nil closestPed
---@return number closestDist
function ESX.Game.GetClosestPed(coords)
    return SLX.Game.GetClosestPed(coords)
end

---@param weaponName string
---@return string
function ESX.GetWeaponLabel(weaponName)
    return SLX.GetWeaponLabel(weaponName)
end

---@return table
function ESX.GetWeaponList()
    return SLX.GetWeaponList()
end

---@param key string
---@param val any
function ESX.SetPlayerData(key, val)
    ESX.PlayerData[key] = val
end

---@param msg string
---@param thisFrame? boolean
---@param beep? boolean
---@param duration? number
function ESX.ShowHelpNotification(msg, thisFrame, beep, duration)
    if thisFrame then
        AddTextComponentSubstringPlayerName(msg)
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, beep or false, duration or -1)
    else
        BeginTextCommandDisplayHelp('STRING')
        AddTextComponentSubstringPlayerName(msg)
        EndTextCommandDisplayHelp(0, false, beep or false, duration or 5000)
    end
end

---@param msg string
---@param coords vector3
---@param thisFrame? boolean
---@param beep? boolean
---@param duration? number
function ESX.ShowFloatingHelpNotification(msg, coords, thisFrame, beep, duration)
    SetFloatingHelpTextWorldPosition(1, coords.x, coords.y, coords.z)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(2, false, beep or false, duration or -1)
end

---@param ms number
---@param cb function
---@return number
function ESX.SetTimeout(ms, cb)
    local id = nil
    id = SetTimeout(ms, cb)
    return id
end

---@param coords vector3
---@param radius number
---@return table
function ESX.Game.GetPlayersInArea(coords, radius)
    return SLX.Game.GetPlayersInArea(coords, radius)
end

---@param coords? vector3
---@return number|nil closestObject
---@return number closestDist
function ESX.Game.GetClosestObject(coords)
    return SLX.Game.GetClosestObject(coords)
end

---@return table
function ESX.Game.GetObjects()
    return SLX.Game.GetObjects()
end

---@return table
function ESX.Game.GetPeds()
    return SLX.Game.GetPeds()
end

---@param modelName string|number
---@param coords vector3
---@param heading number
---@param cb? function
function ESX.Game.SpawnObject(modelName, coords, heading, cb)
    SLX.Game.SpawnObject(modelName, coords, heading, cb, true)
end

---@param modelName string|number
---@param coords vector3
---@param heading number
---@param cb? function
function ESX.Game.SpawnLocalObject(modelName, coords, heading, cb)
    SLX.Game.SpawnLocalObject(modelName, coords, heading, cb)
end

---@param obj number
function ESX.Game.DeleteObject(obj)
    SLX.Game.DeleteObject(obj)
end

---@param entity number
---@param coords vector3
---@param cb? function
function ESX.Game.Teleport(entity, coords, cb)
    SLX.Game.Teleport(entity, coords, cb)
end

local function BuildPlayerData()
    local lp = SLX.LocalPlayer
    local groupName = type(lp.group) == 'table' and lp.group.name or lp.group
    ESX.PlayerData = {
        id = lp.id,
        identifier = lp.identifier,
        accounts = {
            { name = 'money', money = lp.money, label = 'Money' },
            { name = 'bank', money = 0, label = 'Bank' },
            { name = 'black_money', money = 0, label = 'Black Money' },
        },
        job = {
            name = lp.job.name,
            label = lp.job.label,
            grade = lp.job.grade,
            grade_name = lp.job.label,
            grade_salary = lp.job.salary or 0,
        },
        group = groupName,
        inventory = SLX.LocalPlayer.inventory or {},
        loadout = {},
        coords = SLX.Cache.coords and {
            x = SLX.Cache.coords.x,
            y = SLX.Cache.coords.y,
            z = SLX.Cache.coords.z,
        } or {},
    }
end

AddEventHandler('slx:playerLoaded', function(data)
    BuildPlayerData()
    ESX.PlayerLoaded = true
    TriggerEvent('esx:playerLoaded', ESX.PlayerData, data.isFirstJoin or false)
end)

AddEventHandler('slx:playerDied', function(killerServerId)
    TriggerEvent('esx:onPlayerDeath', { killerServerId = killerServerId })
end)

AddEventHandler('slx:jobUpdated', function(jobData)
    local lastJob = ESX.PlayerData.job or {}
    ESX.PlayerData.job = {
        name = jobData.name,
        label = jobData.label,
        grade = jobData.grade,
        grade_name = jobData.label,
        grade_salary = jobData.salary or 0,
    }
    TriggerEvent('esx:setJob', ESX.PlayerData.job, lastJob)
end)

AddEventHandler('slx:moneyUpdated', function(newMoney)
    if ESX.PlayerData.accounts then
        ESX.PlayerData.accounts[1].money = newMoney
    end
end)

AddEventHandler('slx:inventoryUpdated', function(inventoryData)
    ESX.PlayerData.inventory = inventoryData or {}
end)

AddEventHandler('slx:groupUpdated', function(groupData)
    ESX.PlayerData.group = type(groupData) == 'table' and groupData.name or groupData
end)

AddEventHandler('slx:playerUnloaded', function()
    ESX.PlayerLoaded = false
    ESX.PlayerData = {}
end)

exports('getSharedObject', function() return ESX end)

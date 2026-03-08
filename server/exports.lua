exports('getCoreObject', function() return SLX end)

exports('GetPlayer', function(src) return SLX.Players[src] or nil end)
exports('GetPlayerByIdentifier', function(identifier)
    for src, player in pairs(SLX.Players) do
        if player.identifier == identifier then return player end
    end
    return nil
end)
exports('GetAllPlayers', function() return SLX.Players end)
exports('GetPlayerByID', function(id) return SLX.GetPlayerByID(id) end)
exports('GetSourceFromID', function(id)
    local player = SLX.PlayersByID[id]
    if not player then return nil end
    return player.source
end)
exports('GetIDFromSource', function(src)
    local player = SLX.Players[src]
    if not player then return nil end
    return player.id
end)
exports('IsPlayerLoaded', function(src) return SLX.Players[src] ~= nil end)

exports('GetMoney', function(src)
    local player = SLX.Players[src]
    if not player then return 0 end
    return player.money
end)
exports('AddMoney', function(src, amount)
    local player = SLX.Players[src]
    if not player then return false end
    return player:AddMoney(amount)
end)
exports('RemoveMoney', function(src, amount)
    local player = SLX.Players[src]
    if not player then return false end
    return player:RemoveMoney(amount)
end)
exports('SetMoney', function(src, amount)
    local player = SLX.Players[src]
    if not player then return false end
    return player:SetMoney(amount)
end)

exports('GetJob', function(src)
    local player = SLX.Players[src]
    if not player then return nil end
    return player:GetJob()
end)
exports('SetJob', function(src, jobName, grade)
    local player = SLX.Players[src]
    if not player then return false end
    return player:SetJob(jobName, grade)
end)

exports('GetWeapons', function(src)
    local player = SLX.Players[src]
    if not player then return {} end
    return player.weapons
end)
exports('GiveWeapon', function(src, weapon, ammo)
    local player = SLX.Players[src]
    if not player then return false end
    return player:GiveWeapon(weapon, ammo)
end)
exports('RemoveWeapon', function(src, weapon)
    local player = SLX.Players[src]
    if not player then return false end
    return player:RemoveWeapon(weapon)
end)

exports('GetKills', function(src)
    local player = SLX.Players[src]
    if not player then return 0 end
    return player.kills
end)
exports('GetDeaths', function(src)
    local player = SLX.Players[src]
    if not player then return 0 end
    return player.deaths
end)
exports('GetPlaytime', function(src)
    local player = SLX.Players[src]
    if not player then return 0 end
    return player.playtime
end)
exports('GetXp', function(src)
    local player = SLX.Players[src]
    if not player then return 0 end
    return player.xp
end)
exports('AddXp', function(src, amount)
    local player = SLX.Players[src]
    if not player then return end
    player:AddXp(amount)
end)
exports('SetXp', function(src, amount)
    local player = SLX.Players[src]
    if not player then return false end
    return player:SetXp(amount)
end)

exports('GetStatus', function(src)
    local player = SLX.Players[src]
    if not player then return nil end
    return player.status
end)
exports('SetStatus', function(src, key, value)
    local player = SLX.Players[src]
    if not player then return false end
    return player:SetStatus(key, value)
end)

exports('GetGroup', function(src)
    local player = SLX.Players[src]
    if not player then return nil end
    return player.group
end)
exports('SetGroup', function(src, groupName)
    local player = SLX.Players[src]
    if not player then return false end
    return player:SetGroup(groupName)
end)
exports('HasPermission', function(src, requiredGroup)
    local player = SLX.Players[src]
    if not player then return false end
    return player:HasPermission(requiredGroup)
end)

exports('RegisterServerCallback', function(name, cb) SLX.RegisterServerCallback(name, cb) end)

exports('getSharedObject', function()
    if ESX then return ESX end
    return SLX
end)
exports('GetPlayerFromId', function(source)
    local player = SLX.Players[source]
    if not player then return nil end
    if ESX and ESX.GetPlayerFromId then return ESX.GetPlayerFromId(source) end
    return player
end)
exports('GetPlayerFromIdentifier', function(identifier)
    if ESX and ESX.GetPlayerFromIdentifier then return ESX.GetPlayerFromIdentifier(identifier) end
    for _, player in pairs(SLX.Players) do
        if player.identifier == identifier then return player end
    end
    return nil
end)
exports('GetExtendedPlayers', function()
    local xPlayers = {}
    for src, player in pairs(SLX.Players) do
        if ESX and ESX.GetPlayerFromId then
            xPlayers[#xPlayers + 1] = ESX.GetPlayerFromId(src)
        else
            xPlayers[#xPlayers + 1] = player
        end
    end
    return xPlayers
end)
exports('GetInventory', function(src)
    local player = SLX.Players[src]
    if not player then return {} end
    return player:GetInventory()
end)
exports('GetInventoryItem', function(src, itemName)
    local player = SLX.Players[src]
    if not player then return nil end
    return player:GetInventoryItem(itemName)
end)
exports('AddInventoryItem', function(src, itemName, count, metadata)
    local player = SLX.Players[src]
    if not player then return false end
    return player:AddInventoryItem(itemName, count, metadata)
end)
exports('RemoveInventoryItem', function(src, itemName, count)
    local player = SLX.Players[src]
    if not player then return false end
    return player:RemoveInventoryItem(itemName, count)
end)
exports('HasInventoryItem', function(src, itemName, count)
    local player = SLX.Players[src]
    if not player then return false end
    return player:HasInventoryItem(itemName, count)
end)
exports('CanCarryItem', function(src, itemName, count)
    local player = SLX.Players[src]
    if not player then return false end
    return player:CanCarryItem(itemName, count)
end)
exports('RegisterItemUse', function(itemName, callback)
    SLX.RegisterItemUse(itemName, callback)
end)
exports('GetItems', function() return SLX.Items end)
exports('GetUsableItems', function()
    local usable = {}
    for name, item in pairs(SLX.Items) do
        if item.usable and item.usable == 1 then
            usable[name] = item
        end
    end
    return usable
end)
exports('GetJobs', function() return SLX.Jobs or {} end)
exports('GetPlayerCount', function()
    local count = 0
    for _ in pairs(SLX.Players) do count = count + 1 end
    return count
end)
exports('SavePlayer', function(src)
    local player = SLX.Players[src]
    if player then player:Save() end
end)
exports('SavePlayers', function()
    for _, player in pairs(SLX.Players) do
        if player then player:Save() end
    end
end)
exports('TriggerServerCallback', function(name, cb) SLX.RegisterServerCallback(name, cb) end)
exports('Trace', function(msg) SLX.Debug(('[Trace] %s'):format(tostring(msg))) end)
exports('Notify', function(src, msg, notifyType, length) SLX.Notify(src, msg, notifyType, length) end)
exports('GetLeaderboard', function() return SLX.GetLeaderboard() end)

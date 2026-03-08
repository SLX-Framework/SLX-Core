if not SLX.Config.EnableESXBridge then
    exports('getSharedObject', function() return nil end)
    return
end

ESX = {}
SLX.Debug('[ESX Bridge] Server-side ESX bridge initializing')

AddEventHandler('esx:getSharedObject', function(cb)
    if cb then cb(ESX) end
end)

---@param player table
---@return table|nil
local function WrapPlayer(player)
    if not player then return nil end
    local xPlayer = {}
    xPlayer.id = player.id
    xPlayer.source = player.source
    xPlayer.identifier = player.identifier

    function xPlayer.getName() return GetPlayerName(player.source) or 'Unknown' end
    function xPlayer.getIdentifier() return player.identifier end
    function xPlayer.getGroup() return player.group end
    function xPlayer.setGroup(group) return player:SetGroup(group) end

    function xPlayer.getMoney() return player.money end
    function xPlayer.addMoney(amount) return player:AddMoney(amount) end
    function xPlayer.removeMoney(amount) return player:RemoveMoney(amount) end
    function xPlayer.setMoney(amount) return player:SetMoney(amount) end

    function xPlayer.getAccount(accountName)
        if accountName == 'money' then return { name = 'money', money = player.money, label = 'Money' } end
        return { name = accountName, money = 0, label = accountName }
    end
    function xPlayer.addAccountMoney(account, amount)
        if account == 'money' then return player:AddMoney(amount) end
        return false
    end
    function xPlayer.removeAccountMoney(account, amount)
        if account == 'money' then return player:RemoveMoney(amount) end
        return false
    end

    function xPlayer.getJob()
        local job = player:GetJob()
        return {
            name = job.name,
            label = job.label,
            grade = job.grade,
            grade_name = job.label,
            grade_salary = job.salary or 0,
        }
    end
    function xPlayer.setJob(jobName, grade) return player:SetJob(jobName, grade) end

    function xPlayer.getInventory()
        local inv = player:GetInventory()
        local result = {}
        for name, item in pairs(inv) do
            result[#result + 1] = { name = item.name, count = item.count, label = item.label, weight = item.weight }
        end
        return result
    end
    function xPlayer.getInventoryItem(name)
        local item = player:GetInventoryItem(name)
        if item then return { name = item.name, count = item.count, label = item.label } end
        local itemDef = SLX.Items[name]
        return { name = name, count = 0, label = itemDef and itemDef.label or name }
    end
    function xPlayer.addInventoryItem(name, count) return player:AddInventoryItem(name, count) end
    function xPlayer.removeInventoryItem(name, count) return player:RemoveInventoryItem(name, count) end
    function xPlayer.canCarryItem(name, count) return player:CanCarryItem(name, count) end

    function xPlayer.addWeapon(weapon, ammo) return player:GiveWeapon(weapon, ammo) end
    function xPlayer.removeWeapon(weapon) return player:RemoveWeapon(weapon) end
    function xPlayer.getLoadout() return player.weapons end

    function xPlayer.triggerEvent(eventName, ...) TriggerClientEvent(eventName, player.source, ...) end
    function xPlayer.showNotification(msg) TriggerClientEvent('slx:notify', player.source, msg) end
    function xPlayer.kick(reason) DropPlayer(player.source, reason or 'Kicked') end

    function xPlayer.get(key) return player[key] end
    function xPlayer.set(key, value) player[key] = value end

    return xPlayer
end

---@param source number
---@return table|nil
function ESX.GetPlayerFromId(source)
    return WrapPlayer(SLX.Players[source])
end

---@param identifier string
---@return table|nil
function ESX.GetPlayerFromIdentifier(identifier)
    for _, player in pairs(SLX.Players) do
        if player.identifier == identifier then return WrapPlayer(player) end
    end
    return nil
end

---@return number[]
function ESX.GetPlayers()
    local sources = {}
    for src in pairs(SLX.Players) do sources[#sources + 1] = src end
    return sources
end

---@param name string
---@param cb fun(source: number, respond: function, ...)
function ESX.RegisterServerCallback(name, cb)
    SLX.RegisterServerCallback(name, cb)
end

---@return table
function ESX.GetSharedObject()
    return ESX
end

---@param msg string
function ESX.Trace(msg)
    SLX.Debug(('[ESX.Trace] %s'):format(tostring(msg)))
end

---@param src number
---@param msg string
function ESX.ShowNotification(src, msg)
    TriggerClientEvent('slx:notify', src, msg)
end

---@return table
function ESX.GetExtendedPlayers()
    local xPlayers = {}
    for src, player in pairs(SLX.Players) do
        xPlayers[#xPlayers + 1] = WrapPlayer(player)
    end
    return xPlayers
end

---@return table
function ESX.GetJobs()
    return SLX.Jobs or {}
end

---@return number
function ESX.GetPlayerCount()
    local count = 0
    for _ in pairs(SLX.Players) do count = count + 1 end
    return count
end

---@return table
function ESX.GetUsableItems()
    local usable = {}
    for name, item in pairs(SLX.Items) do
        if item.usable and item.usable == 1 then
            usable[name] = item
        end
    end
    return usable
end

---@param itemName string
---@param cb fun(source: number)
function ESX.RegisterUsableItem(itemName, cb)
    SLX.RegisterItemUse(itemName, function(src, name, itemData)
        cb(src)
    end)
end

---@param src number
---@param itemName string
function ESX.UseItem(src, itemName)
    local player = SLX.Players[src]
    if not player then return end
    local itemDef = SLX.Items[itemName]
    if not itemDef then return end
    if not itemDef.usable or itemDef.usable ~= 1 then return end
    local invItem = player:GetInventoryItem(itemName)
    if not invItem or invItem.count <= 0 then return end
    local callback = SLX.ItemCallbacks[itemName]
    if not callback then return end
    callback(src, itemName, invItem)
end

---@param name string
---@param cb fun(source: number, respond: function, ...)
function ESX.TriggerServerCallback(name, cb)
    SLX.RegisterServerCallback(name, cb)
end

---@param src number
function ESX.SavePlayer(src)
    local player = SLX.Players[src]
    if player then player:Save() end
end

function ESX.SavePlayers()
    for src, player in pairs(SLX.Players) do
        if player then player:Save() end
    end
end

AddEventHandler('slx:srv_playerLoaded', function(src)
    local xPlayer = WrapPlayer(SLX.Players[src])
    if xPlayer then
        TriggerEvent('esx:playerLoaded', src, xPlayer)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    if SLX.Players[src] then
        TriggerEvent('esx:playerDropped', src, reason)
    end
end)

exports('getSharedObject', function() return ESX end)
exports('GetPlayerFromId', function(source) return WrapPlayer(SLX.Players[source]) end)
exports('GetPlayerFromIdentifier', function(identifier)
    for _, player in pairs(SLX.Players) do
        if player.identifier == identifier then return WrapPlayer(player) end
    end
    return nil
end)
exports('GetPlayers', function() return ESX.GetPlayers() end)
exports('RegisterServerCallback', function(name, cb) SLX.RegisterServerCallback(name, cb) end)
exports('GetExtendedPlayers', function() return ESX.GetExtendedPlayers() end)
exports('GetJobs', function() return ESX.GetJobs() end)
exports('GetPlayerCount', function() return ESX.GetPlayerCount() end)
exports('SavePlayer', function(src) ESX.SavePlayer(src) end)
exports('SavePlayers', function() ESX.SavePlayers() end)
exports('TriggerServerCallback', function(name, cb) ESX.TriggerServerCallback(name, cb) end)
exports('Trace', function(msg) ESX.Trace(msg) end)
exports('ShowNotification', function(src, msg) ESX.ShowNotification(src, msg) end)
exports('GetUsableItems', function() return ESX.GetUsableItems() end)
exports('RegisterUsableItem', function(itemName, cb) ESX.RegisterUsableItem(itemName, cb) end)
exports('UseItem', function(src, itemName) ESX.UseItem(src, itemName) end)

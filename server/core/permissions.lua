SLX.Groups = {}

CreateThread(function()
    while not MySQL do Wait(100) end
    local rows = MySQL.query.await('SELECT * FROM `groups` ORDER BY priority ASC')
    if rows then
        for i = 1, #rows do
            SLX.Groups[rows[i].name] = { label = rows[i].label, priority = rows[i].priority }
        end
        SLX.Log('INFO', ('Loaded %d group definitions'):format(#rows))
    else
        SLX.Log('ERROR', 'Failed to load group definitions')
    end
end)

---@param src number
---@return string[]
local function GetAllIdentifiers(src)
    local ids = {}
    local identifiers = GetPlayerIdentifiers(src)
    for i = 1, #identifiers do ids[#ids + 1] = identifiers[i] end
    return ids
end

---@param src number
---@param groupName string
function SLX.ApplyGroupPrincipal(src, groupName)
    local ids = GetAllIdentifiers(src)
    for i = 1, #ids do
        ExecuteCommand(('add_principal identifier.%s group.%s'):format(ids[i], groupName))
    end
end

---@param src number
---@param groupName string
function SLX.RemoveGroupPrincipal(src, groupName)
    local ids = GetAllIdentifiers(src)
    for i = 1, #ids do
        ExecuteCommand(('remove_principal identifier.%s group.%s'):format(ids[i], groupName))
    end
end

---@param groupName string
---@return boolean
function SLX.IsValidGroup(groupName)
    return SLX.Groups[groupName] ~= nil
end

---@param groupA string
---@param groupB string
---@return boolean
function SLX.IsGroupHigherOrEqual(groupA, groupB)
    local a = SLX.Groups[groupA]
    local b = SLX.Groups[groupB]
    if not a or not b then return false end
    return a.priority >= b.priority
end

RegisterNetEvent('slx:setGroup')
AddEventHandler('slx:setGroup', function(targetSource, groupName)
    local src = source
    local caller = SLX.Players[src]
    if not caller then return end
    if not SLX.IsValidGroup(groupName) then
        TriggerClientEvent('slx:notify', src, 'Invalid group!')
        return
    end
    local target = tonumber(targetSource) or src
    local targetPlayer = SLX.Players[target]
    if not targetPlayer then
        TriggerClientEvent('slx:notify', src, 'Player not found!')
        return
    end
    if not SLX.IsGroupHigherOrEqual(caller.group, groupName) then
        TriggerClientEvent('slx:notify', src, 'Insufficient permissions!')
        SLX.Log('WARN', ('Player %d tried to set group %s without permission'):format(src, groupName))
        return
    end
    targetPlayer:SetGroup(groupName)
    SLX.Log('INFO', ('Player %d set group of player %d to %s'):format(src, target, groupName))
end)

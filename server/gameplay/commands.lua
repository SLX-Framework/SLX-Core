CreateThread(function()
    while not MySQL do Wait(100) end
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `bans` (
            `id`         INT AUTO_INCREMENT PRIMARY KEY,
            `identifier` VARCHAR(60) NOT NULL,
            `reason`     VARCHAR(255) DEFAULT 'No reason given',
            `banned_by`  VARCHAR(60) DEFAULT 'Console',
            `ban_time`   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `expire_time` TIMESTAMP NULL DEFAULT NULL,
            INDEX `idx_ban_identifier` (`identifier`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
    SLX.Debug('Commands: bans table ready')
end)

---@param src number
---@param command string
---@return boolean
local function HasCommandPerm(src, command)
    if src == 0 then return true end
    local player = SLX.Players[src]
    if not player then return false end
    local required = SLX.Config.CommandPermissions[command]
    if not required then return false end
    return player:HasPermission(required)
end

---@param src number
---@param msg string
---@param notifyType? string
---@param length? number
local function Notify(src, msg, notifyType, length)
    if src == 0 then SLX.Debug(msg)
    else TriggerClientEvent('hud:showNotification', src, msg, notifyType or 'info', length or 5000) end
end

---@param src number
---@param msg string
---@param notifyType? string
---@param length? number
function SLX.Notify(src, msg, notifyType, length)
    Notify(src, msg, notifyType, length)
end

---@param dbId number
---@return table|nil player
---@return number|nil source
local function GetTargetByDBId(dbId)
    local player = SLX.PlayersByID[dbId]
    if not player then return nil, nil end
    return player, player.source
end

---@param src number
---@return string
local function GetName(src)
    if src == 0 then return 'Console' end
    return GetPlayerName(src) or ('Player ' .. src)
end

---@param str string|nil
---@return number|nil
local function ParseDuration(str)
    if not str then return nil end
    str = str:lower()
    if str == 'perm' or str == 'permanent' or str == '0' then return nil end
    local num, unit = str:match('^(%d+)([hdm]?)$')
    num = tonumber(num)
    if not num then return nil end
    if unit == 'h' then return num * 3600
    elseif unit == 'd' or unit == '' then return num * 86400
    elseif unit == 'm' then return num * 60 end
    return num * 86400
end

---@param seconds number|nil
---@return string
local function FormatDuration(seconds)
    if not seconds then return 'permanent' end
    if seconds >= 86400 then return ('%d day(s)'):format(math.floor(seconds / 86400))
    elseif seconds >= 3600 then return ('%d hour(s)'):format(math.floor(seconds / 3600))
    else return ('%d minute(s)'):format(math.floor(seconds / 60)) end
end

---@param identifier string|nil
---@return table|nil
function SLX.CheckBan(identifier)
    if not identifier then return nil end
    local rows = MySQL.query.await(
        'SELECT * FROM bans WHERE identifier = ? AND (expire_time IS NULL OR expire_time > NOW()) ORDER BY id DESC LIMIT 1',
        { identifier }
    )
    if rows and #rows > 0 then return rows[1] end
    return nil
end

RegisterCommand('givemoney', function(src, args)
    if not HasCommandPerm(src, 'givemoney') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetDBId or not amount or amount <= 0 then Notify(src, 'Usage: /givemoney [id] [amount]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    target:AddMoney(amount)
    Notify(src, ('Gave $%d to %s (ID %d)'):format(amount, GetPlayerName(targetSrc) or targetDBId, targetDBId))
    Notify(targetSrc, ('You received $%d from an admin'):format(amount))
    SLX.Log('INFO', ('%s gave $%d to player ID %d'):format(GetName(src), amount, targetDBId))
end, false)

RegisterCommand('removemoney', function(src, args)
    if not HasCommandPerm(src, 'removemoney') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetDBId or not amount or amount <= 0 then Notify(src, 'Usage: /removemoney [id] [amount]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    if target:RemoveMoney(amount) then
        Notify(src, ('Removed $%d from %s (ID %d)'):format(amount, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        SLX.Log('INFO', ('%s removed $%d from player ID %d'):format(GetName(src), amount, targetDBId))
    else
        Notify(src, 'Player does not have enough money!')
    end
end, false)

RegisterCommand('setmoney', function(src, args)
    if not HasCommandPerm(src, 'setmoney') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local amount = tonumber(args[2])
    if not targetDBId or not amount or amount < 0 then Notify(src, 'Usage: /setmoney [id] [amount]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    target:SetMoney(amount)
    Notify(src, ('Set money to $%d for %s (ID %d)'):format(amount, GetPlayerName(targetSrc) or targetDBId, targetDBId))
    SLX.Log('INFO', ('%s set money to $%d for player ID %d'):format(GetName(src), amount, targetDBId))
end, false)

RegisterCommand('giveweapon', function(src, args)
    if not HasCommandPerm(src, 'giveweapon') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local weapon = args[2]
    local ammo = tonumber(args[3]) or 250
    if not targetDBId or not weapon then Notify(src, 'Usage: /giveweapon [id] [weapon] [ammo]') return end
    weapon = weapon:upper()
    if not weapon:find('^WEAPON_') then weapon = 'WEAPON_' .. weapon end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    target:GiveWeapon(weapon, ammo)
    Notify(src, ('Gave %s (%d ammo) to %s (ID %d)'):format(weapon, ammo, GetPlayerName(targetSrc) or targetDBId, targetDBId))
    Notify(targetSrc, ('You received %s from an admin'):format(weapon))
    SLX.Log('INFO', ('%s gave %s to player ID %d'):format(GetName(src), weapon, targetDBId))
end, false)

RegisterCommand('removeweapon', function(src, args)
    if not HasCommandPerm(src, 'removeweapon') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local weapon = args[2]
    if not targetDBId or not weapon then Notify(src, 'Usage: /removeweapon [id] [weapon]') return end
    weapon = weapon:upper()
    if not weapon:find('^WEAPON_') then weapon = 'WEAPON_' .. weapon end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    if target:RemoveWeapon(weapon) then
        Notify(src, ('Removed %s from %s (ID %d)'):format(weapon, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        SLX.Log('INFO', ('%s removed %s from player ID %d'):format(GetName(src), weapon, targetDBId))
    else
        Notify(src, 'Player does not have that weapon!')
    end
end, false)

RegisterCommand('setjob', function(src, args)
    if not HasCommandPerm(src, 'setjob') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local jobName = args[2]
    local grade = tonumber(args[3]) or 0
    if not targetDBId or not jobName then Notify(src, 'Usage: /setjob [id] [job] [grade]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    if target:SetJob(jobName, grade) then
        Notify(src, ('Set job to %s (grade %d) for %s (ID %d)'):format(jobName, grade, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        Notify(targetSrc, ('Your job has been set to %s'):format(jobName))
        SLX.Log('INFO', ('%s set job %s (grade %d) for player ID %d'):format(GetName(src), jobName, grade, targetDBId))
    else
        Notify(src, 'Invalid job or grade!')
    end
end, false)

RegisterCommand('setgroup', function(src, args)
    if not HasCommandPerm(src, 'setgroup') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local groupName = args[2]
    if not targetDBId or not groupName then Notify(src, 'Usage: /setgroup [id] [group]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    if target:SetGroup(groupName) then
        Notify(src, ('Set group to %s for %s (ID %d)'):format(groupName, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        Notify(targetSrc, ('Your group has been set to %s'):format(groupName))
        SLX.Log('INFO', ('%s set group %s for player ID %d'):format(GetName(src), groupName, targetDBId))
    else
        Notify(src, 'Invalid group name!')
    end
end, false)

RegisterCommand('kick', function(src, args)
    if not HasCommandPerm(src, 'kick') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then Notify(src, 'Usage: /kick [id] [reason]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local reason = table.concat(args, ' ', 2)
    if reason == '' then reason = 'Kicked by admin' end
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    DropPlayer(targetSrc, reason)
    Notify(src, ('Kicked %s: %s'):format(targetName, reason))
    SLX.Log('INFO', ('%s kicked %s (ID %d): %s'):format(GetName(src), targetName, targetDBId, reason))
end, false)

RegisterCommand('ban', function(src, args)
    if not HasCommandPerm(src, 'ban') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local durationStr = args[2]
    if not targetDBId then
        Notify(src, 'Usage: /ban [id] [duration] [reason]')
        Notify(src, 'Duration: perm, 1h, 1d, 7d, 30d')
        return
    end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local durationSeconds = ParseDuration(durationStr or 'perm')
    local reason = table.concat(args, ' ', 3)
    if reason == '' then reason = 'Banned by admin' end
    local bannedBy = (src == 0) and 'Console' or (SLX.Players[src] and SLX.Players[src].identifier or 'Unknown')
    local expireTime = nil
    if durationSeconds then expireTime = os.date('!%Y-%m-%d %H:%M:%S', os.time() + durationSeconds) end
    MySQL.insert('INSERT INTO bans (identifier, reason, banned_by, expire_time) VALUES (?, ?, ?, ?)', {
        target.identifier, reason, bannedBy, expireTime,
    })
    local durationLabel = FormatDuration(durationSeconds)
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    DropPlayer(targetSrc, ('Banned: %s (Duration: %s)'):format(reason, durationLabel))
    Notify(src, ('Banned %s for %s: %s'):format(targetName, durationLabel, reason))
    SLX.Log('INFO', ('%s banned %s (%s) for %s: %s'):format(GetName(src), targetName, target.identifier, durationLabel, reason))
end, false)

RegisterCommand('unban', function(src, args)
    if not HasCommandPerm(src, 'unban') then Notify(src, 'No permission!') return end
    local identifier = args[1]
    if not identifier then Notify(src, 'Usage: /unban [steam:identifier]') return end
    if not identifier:find(':') then identifier = 'steam:' .. identifier end
    local result = MySQL.query.await('DELETE FROM bans WHERE identifier = ?', { identifier })
    if result and result.affectedRows and result.affectedRows > 0 then
        Notify(src, ('Unbanned %s (%d ban(s) removed)'):format(identifier, result.affectedRows))
        SLX.Log('INFO', ('%s unbanned %s'):format(GetName(src), identifier))
    else
        Notify(src, 'No bans found for that identifier!')
    end
end, false)

RegisterCommand('bring', function(src, args)
    if src == 0 then SLX.Debug('Cannot use /bring from console') return end
    if not HasCommandPerm(src, 'bring') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then Notify(src, 'Usage: /bring [id]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local adminCoords = GetEntityCoords(GetPlayerPed(src))
    TriggerClientEvent('slx:recv_teleport', targetSrc, { x = adminCoords.x, y = adminCoords.y, z = adminCoords.z })
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    Notify(src, ('Brought %s (ID %d) to you'):format(targetName, targetDBId))
    Notify(targetSrc, 'You have been teleported by an admin')
    SLX.Log('INFO', ('%s brought player ID %d to their position'):format(GetName(src), targetDBId))
end, false)

RegisterCommand('goto', function(src, args)
    if src == 0 then SLX.Debug('Cannot use /goto from console') return end
    if not HasCommandPerm(src, 'goto') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then Notify(src, 'Usage: /goto [id]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local targetCoords = GetEntityCoords(GetPlayerPed(targetSrc))
    TriggerClientEvent('slx:recv_teleport', src, { x = targetCoords.x, y = targetCoords.y, z = targetCoords.z })
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    Notify(src, ('Teleported to %s (ID %d)'):format(targetName, targetDBId))
    SLX.Log('INFO', ('%s teleported to player ID %d'):format(GetName(src), targetDBId))
end, false)

RegisterCommand('tp', function(src, args)
    if src == 0 then SLX.Debug('Cannot use /tp from console') return end
    if not HasCommandPerm(src, 'tp') then Notify(src, 'No permission!') return end
    local x = tonumber(args[1])
    local y = tonumber(args[2])
    local z = tonumber(args[3])
    if not x or not y or not z then Notify(src, 'Usage: /tp [x] [y] [z]') return end
    TriggerClientEvent('slx:recv_teleport', src, { x = x, y = y, z = z })
    Notify(src, ('Teleported to %.1f, %.1f, %.1f'):format(x, y, z))
    SLX.Log('INFO', ('%s teleported to %.1f, %.1f, %.1f'):format(GetName(src), x, y, z))
end, false)

RegisterCommand('heal', function(src, args)
    if not HasCommandPerm(src, 'heal') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then
        if src ~= 0 then
            local selfPlayer = SLX.Players[src]
            if selfPlayer then targetDBId = selfPlayer.id end
        end
        if not targetDBId then SLX.Debug('Usage: /heal [id]') return end
    end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    target.health = 200
    target.armour = 100
    TriggerClientEvent('slx:recv_heal', targetSrc, 200, 100)
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    Notify(src, ('Healed %s (ID %d)'):format(targetName, targetDBId))
    if targetSrc ~= src then Notify(targetSrc, 'You have been healed by an admin') end
    SLX.Log('INFO', ('%s healed player ID %d'):format(GetName(src), targetDBId))
end, false)

RegisterCommand('revive', function(src, args)
    if not HasCommandPerm(src, 'revive') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then
        if src ~= 0 then
            local selfPlayer = SLX.Players[src]
            if selfPlayer then targetDBId = selfPlayer.id end
        end
        if not targetDBId then SLX.Debug('Usage: /revive [id]') return end
    end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    target.health = 200
    target.status.is_dead = false
    MySQL.update('UPDATE players SET status = ? WHERE identifier = ?', { json.encode(target.status), target.identifier })
    TriggerClientEvent('slx:recv_revive', targetSrc, 200)
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    Notify(src, ('Revived %s (ID %d)'):format(targetName, targetDBId))
    if targetSrc ~= src then Notify(targetSrc, 'You have been revived by an admin') end
    SLX.Log('INFO', ('%s revived player ID %d'):format(GetName(src), targetDBId))
end, false)

RegisterCommand('kill', function(src, args)
    if not HasCommandPerm(src, 'kill') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    if not targetDBId then Notify(src, 'Usage: /kill [id]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    TriggerClientEvent('slx:recv_kill', targetSrc)
    local targetName = GetPlayerName(targetSrc) or ('ID ' .. targetDBId)
    Notify(src, ('Killed %s (ID %d)'):format(targetName, targetDBId))
    SLX.Log('INFO', ('%s killed player ID %d'):format(GetName(src), targetDBId))
end, false)

RegisterCommand('giveitem', function(src, args)
    if not HasCommandPerm(src, 'giveitem') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local itemName = args[2]
    local count = tonumber(args[3]) or 1
    if not targetDBId or not itemName then Notify(src, 'Usage: /giveitem [id] [item] [count]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local itemDef = SLX.Items[itemName]
    if not itemDef then Notify(src, ('Item "%s" does not exist!'):format(itemName)) return end
    if target:AddInventoryItem(itemName, count) then
        Notify(src, ('Gave %dx %s to %s (ID %d)'):format(count, itemDef.label, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        Notify(targetSrc, ('Du hast %dx %s erhalten'):format(count, itemDef.label))
        SLX.Log('INFO', ('%s gave %dx %s to player ID %d'):format(GetName(src), count, itemName, targetDBId))
    else
        Notify(src, ('Failed! Player cannot carry %dx %s (weight limit or invalid item)'):format(count, itemName))
    end
end, false)

RegisterCommand('removeitem', function(src, args)
    if not HasCommandPerm(src, 'removeitem') then Notify(src, 'No permission!') return end
    local targetDBId = tonumber(args[1])
    local itemName = args[2]
    local count = tonumber(args[3]) or 1
    if not targetDBId or not itemName then Notify(src, 'Usage: /removeitem [id] [item] [count]') return end
    local target, targetSrc = GetTargetByDBId(targetDBId)
    if not target then Notify(src, 'Player not found!') return end
    local itemDef = SLX.Items[itemName]
    if not itemDef then Notify(src, ('Item "%s" does not exist!'):format(itemName)) return end
    if target:RemoveInventoryItem(itemName, count) then
        Notify(src, ('Removed %dx %s from %s (ID %d)'):format(count, itemDef.label, GetPlayerName(targetSrc) or targetDBId, targetDBId))
        Notify(targetSrc, ('Dir wurden %dx %s entfernt'):format(count, itemDef.label))
        SLX.Log('INFO', ('%s removed %dx %s from player ID %d'):format(GetName(src), count, itemName, targetDBId))
    else
        Notify(src, ('Player does not have %dx %s!'):format(count, itemName))
    end
end, false)

RegisterCommand('announce', function(src, args)
    if not HasCommandPerm(src, 'announce') then Notify(src, 'No permission!') return end
    local message = table.concat(args, ' ')
    if message == '' then Notify(src, 'Usage: /announce [message]') return end
    TriggerClientEvent('slx:announce', -1, message)
    Notify(src, 'Announcement sent: ' .. message)
    SLX.Log('INFO', ('%s announced: %s'):format(GetName(src), message))
end, false)

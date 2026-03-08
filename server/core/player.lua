local defaultStatus = { wanted = false, jailed = false, jail_time = 0, bounty = 0, is_dead = false }

local MAX_NAME_LENGTH = 20
local MIN_NAME_LENGTH = 3

local forbiddenStrings = {
    "<script>", "</script>", "<style>", "</style>", "<img", "<iframe", "<svg",
    "<object", "<embed", "<link", "<meta", "<body", "<html", "<div", "<a ",
    "javascript:", "onerror", "onload", "onclick", "onmouseover", "onfocus",
    "http://", "https://", "://", "ftp://",
    "discord.gg", "discord.com", "is.gd", "bit.ly", "tinyurl", "goo.gl",
    ".com/", ".net/", ".org/", ".gg/", ".ru/", ".tk/",
    "SELECT ", "INSERT ", "DELETE ", "UPDATE ", "DROP ", "UNION ",
    "~r~", "~g~", "~b~", "~y~", "~p~", "~o~", "~w~", "~s~", "~h~",
    "^1", "^2", "^3", "^4", "^5", "^6", "^7", "^8", "^9", "^0",
    "\n", "\t", "\r", "\0",
}

---@param playerName string
---@return boolean valid
---@return string|nil reason
local function ValidatePlayerName(playerName)
    if not playerName or playerName == '' then return false, 'Name cannot be empty.' end
    local trimmed = playerName:match('^%s*(.-)%s*$')
    if #trimmed < MIN_NAME_LENGTH then
        return false, ('Name must be at least %d characters.'):format(MIN_NAME_LENGTH)
    end
    if #trimmed > MAX_NAME_LENGTH then
        return false, ('Name cannot exceed %d characters.'):format(MAX_NAME_LENGTH)
    end
    local lower = string.lower(playerName)
    for i = 1, #forbiddenStrings do
        if string.find(lower, string.lower(forbiddenStrings[i]), 1, true) then
            return false, 'Your name contains forbidden characters or words. Please change your Steam name.'
        end
    end
    if not playerName:match('^[%w%s%-%_%.%,%(%)%[%]\']+$') then
        return false, 'Your name contains invalid special characters. Please use only letters, numbers, spaces, and basic punctuation.'
    end
    return true, nil
end

---@param src number
---@return string|nil
local function GetSteamIdentifier(src)
    local identifiers = GetPlayerIdentifiers(src)
    for i = 1, #identifiers do
        if identifiers[i]:sub(1, 6) == 'steam:' then return identifiers[i] end
    end
    return nil
end

---@param src number
---@param data table
---@return table
local function CreatePlayerObject(src, data)
    local self = {}
    self.id         = data.id
    self.source     = src
    self.identifier = data.identifier
    self.group      = data.group or 'user'
    self.health     = (tonumber(data.health) or 200) > 0 and tonumber(data.health) or 200
    self.armour     = data.armour or 0
    self.money      = data.money or 0
    self.kills      = data.kills or 0
    self.deaths     = data.deaths or 0
    self.xp         = data.xp or 0
    self.playtime   = data.playtime or 0
    self.job        = data.job or 'unemployed'
    self.job_grade  = data.job_grade or 0
    if type(data.position) == 'string' then
        self.position = json.decode(data.position) or SLX.Config.DefaultSpawn
    else
        self.position = data.position or SLX.Config.DefaultSpawn
    end
    if type(data.weapons) == 'string' then
        self.weapons = json.decode(data.weapons) or {}
    else
        self.weapons = data.weapons or {}
    end
    if type(data.status) == 'string' then
        self.status = json.decode(data.status) or defaultStatus
    else
        self.status = data.status or defaultStatus
    end
    if type(data.skin) == 'string' then
        self.skin = json.decode(data.skin)
    else
        self.skin = data.skin
    end
    self._joinedAt = os.time()

    self.inventory = {}
    local rawInv = type(data.inventory) == 'string' and json.decode(data.inventory) or data.inventory or {}
    for i = 1, #rawInv do
        local entry = rawInv[i]
        local itemDef = SLX.Items[entry.name]
        if itemDef then
            self.inventory[entry.name] = {
                name     = entry.name,
                count    = entry.count or 0,
                label    = itemDef.label,
                weight   = itemDef.weight or 1,
                metadata = entry.metadata,
            }
        end
    end

    ---@return number
    function self:GetId() return self.id end
    ---@return string
    function self:GetIdentifier() return self.identifier end
    ---@return number
    function self:GetSource() return self.source end
    ---@param eventName string
    ---@param ... any
    function self:TriggerEvent(eventName, ...) TriggerClientEvent(eventName, self.source, ...) end

    ---@return string
    local function SerializeInventory()
        local arr = {}
        for _, inv in pairs(self.inventory) do
            arr[#arr + 1] = { name = inv.name, count = inv.count, metadata = inv.metadata }
        end
        return json.encode(arr)
    end

    function self:Save()
        local currentTime = os.time()
        local sessionMinutes = math.floor((currentTime - self._joinedAt) / 60)
        self._joinedAt = currentTime
        self.playtime = self.playtime + sessionMinutes
        MySQL.update(
            'UPDATE players SET `group` = ?, position = ?, health = ?, armour = ?, weapons = ?, money = ?, kills = ?, deaths = ?, xp = ?, playtime = ?, job = ?, job_grade = ?, status = ?, skin = ?, inventory = ?, last_seen = NOW() WHERE identifier = ?',
            { self.group, json.encode(self.position), self.health, self.armour, json.encode(self.weapons), self.money, self.kills, self.deaths, self.xp, self.playtime, self.job, self.job_grade, json.encode(self.status), self.skin and json.encode(self.skin) or nil, SerializeInventory(), self.identifier }
        )
    end

    ---@return string
    function self:GetGroup() return self.group end
    ---@param groupName string
    ---@return boolean
    function self:SetGroup(groupName)
        if not SLX.IsValidGroup(groupName) then return false end
        SLX.RemoveGroupPrincipal(self.source, self.group)
        self.group = groupName
        MySQL.update('UPDATE players SET `group` = ? WHERE identifier = ?', { groupName, self.identifier })
        SLX.ApplyGroupPrincipal(self.source, groupName)
        local groupDef = SLX.Groups[groupName] or { label = groupName, priority = 0 }
        TriggerClientEvent('slx:recv_group', self.source, { name = groupName, label = groupDef.label, priority = groupDef.priority })
        return true
    end
    ---@param requiredGroup string
    ---@return boolean
    function self:HasPermission(requiredGroup)
        return SLX.IsGroupHigherOrEqual(self.group, requiredGroup)
    end

    ---@return number
    function self:GetMoney() return self.money end
    ---@param amount number
    ---@return boolean
    function self:AddMoney(amount)
        amount = tonumber(amount)
        if not amount or amount <= 0 then return false end
        self.money = self.money + amount
        MySQL.update('UPDATE players SET money = ? WHERE identifier = ?', { self.money, self.identifier })
        TriggerClientEvent('slx:recv_money', self.source, self.money)
        return true
    end
    ---@param amount number
    ---@return boolean
    function self:RemoveMoney(amount)
        amount = tonumber(amount)
        if not amount or amount <= 0 or self.money < amount then return false end
        self.money = self.money - amount
        MySQL.update('UPDATE players SET money = ? WHERE identifier = ?', { self.money, self.identifier })
        TriggerClientEvent('slx:recv_money', self.source, self.money)
        return true
    end
    ---@param amount number
    ---@return boolean
    function self:SetMoney(amount)
        amount = tonumber(amount)
        if not amount or amount < 0 then return false end
        self.money = amount
        MySQL.update('UPDATE players SET money = ? WHERE identifier = ?', { self.money, self.identifier })
        TriggerClientEvent('slx:recv_money', self.source, self.money)
        return true
    end

    ---@return table
    function self:GetJob()
        local jobDef = SLX.Jobs[self.job]
        if not jobDef then return { name = self.job, label = self.job, grade = self.job_grade, salary = 0 } end
        local gradeInfo = jobDef.grades[self.job_grade] or { label = 'Unknown', salary = 0 }
        return { name = self.job, label = jobDef.label, grade = self.job_grade, salary = gradeInfo.salary }
    end
    ---@param jobName string
    ---@param grade number
    ---@return boolean
    function self:SetJob(jobName, grade)
        grade = tonumber(grade) or 0
        local jobDef = SLX.Jobs[jobName]
        if not jobDef then return false end
        if not jobDef.grades[grade] then return false end
        self.job = jobName
        self.job_grade = grade
        MySQL.update('UPDATE players SET job = ?, job_grade = ? WHERE identifier = ?', { jobName, grade, self.identifier })
        local gradeInfo = jobDef.grades[grade]
        TriggerClientEvent('slx:recv_job', self.source, { name = jobName, label = jobDef.label, grade = grade, salary = gradeInfo.salary })
        return true
    end

    ---@return table
    function self:GetWeapons() return self.weapons end
    ---@param weaponName string
    ---@param ammo number
    ---@return boolean
    function self:GiveWeapon(weaponName, ammo)
        ammo = tonumber(ammo) or 0
        for i = 1, #self.weapons do
            if self.weapons[i].weapon == weaponName then
                self.weapons[i].ammo = self.weapons[i].ammo + ammo
                MySQL.update('UPDATE players SET weapons = ? WHERE identifier = ?', { json.encode(self.weapons), self.identifier })
                TriggerClientEvent('slx:recv_weapons', self.source, self.weapons)
                return true
            end
        end
        self.weapons[#self.weapons + 1] = { weapon = weaponName, ammo = ammo }
        MySQL.update('UPDATE players SET weapons = ? WHERE identifier = ?', { json.encode(self.weapons), self.identifier })
        TriggerClientEvent('slx:recv_weapons', self.source, self.weapons)
        return true
    end
    ---@param weaponName string
    ---@return boolean
    function self:RemoveWeapon(weaponName)
        for i = 1, #self.weapons do
            if self.weapons[i].weapon == weaponName then
                table.remove(self.weapons, i)
                MySQL.update('UPDATE players SET weapons = ? WHERE identifier = ?', { json.encode(self.weapons), self.identifier })
                TriggerClientEvent('slx:recv_weapons', self.source, self.weapons)
                return true
            end
        end
        return false
    end
    ---@return boolean
    function self:RemoveAllWeapons()
        self.weapons = {}
        MySQL.update('UPDATE players SET weapons = ? WHERE identifier = ?', { '[]', self.identifier })
        TriggerClientEvent('slx:recv_weapons', self.source, self.weapons)
        return true
    end

    ---@return integer
    function self:GetKills() return self.kills end
    ---@return integer
    function self:GetDeaths() return self.deaths end
    ---@return integer
    function self:GetPlaytime() return self.playtime end
    function self:AddKill()
        self.kills = self.kills + 1
        MySQL.update('UPDATE players SET kills = ? WHERE identifier = ?', { self.kills, self.identifier })
    end
    function self:AddDeath()
        self.deaths = self.deaths + 1
        MySQL.update('UPDATE players SET deaths = ? WHERE identifier = ?', { self.deaths, self.identifier })
    end

    ---@return integer
    function self:GetXp() return self.xp end
    ---@param amount number
    function self:AddXp(amount)
        amount = tonumber(amount) or 0
        if amount <= 0 then return end
        self.xp = self.xp + amount
        MySQL.update('UPDATE players SET xp = ? WHERE identifier = ?', { self.xp, self.identifier })
        TriggerClientEvent('slx:recv_xp', self.source, self.xp)
    end
    ---@param amount number
    ---@return boolean
    function self:SetXp(amount)
        amount = tonumber(amount) or 0
        if amount < 0 then return false end
        self.xp = amount
        MySQL.update('UPDATE players SET xp = ? WHERE identifier = ?', { self.xp, self.identifier })
        TriggerClientEvent('slx:recv_xp', self.source, self.xp)
        return true
    end

    ---@return table
    function self:GetInventory() return self.inventory end
    ---@param itemName string
    ---@return table|nil
    function self:GetInventoryItem(itemName)
        return self.inventory[itemName]
    end
    ---@param itemName string
    ---@param count number
    ---@param metadata? table
    ---@return boolean
    function self:AddInventoryItem(itemName, count, metadata)
        count = tonumber(count) or 0
        if count <= 0 then return false end
        local itemDef = SLX.Items[itemName]
        if not itemDef then return false end
        if not self:CanCarryItem(itemName, count) then return false end
        local existing = self.inventory[itemName]
        if existing then
            existing.count = existing.count + count
            if metadata then existing.metadata = metadata end
        else
            self.inventory[itemName] = {
                name     = itemName,
                count    = count,
                label    = itemDef.label,
                weight   = itemDef.weight,
                metadata = metadata or nil,
            }
        end
        MySQL.update('UPDATE players SET inventory = ? WHERE identifier = ?', { SerializeInventory(), self.identifier })
        TriggerClientEvent('slx:recv_inventory', self.source, self.inventory)
        return true
    end
    ---@param itemName string
    ---@param count number
    ---@return boolean
    function self:RemoveInventoryItem(itemName, count)
        count = tonumber(count) or 0
        if count <= 0 then return false end
        local existing = self.inventory[itemName]
        if not existing or existing.count < count then return false end
        existing.count = existing.count - count
        if existing.count <= 0 then
            self.inventory[itemName] = nil
        end
        MySQL.update('UPDATE players SET inventory = ? WHERE identifier = ?', { SerializeInventory(), self.identifier })
        TriggerClientEvent('slx:recv_inventory', self.source, self.inventory)
        return true
    end
    ---@param itemName string
    ---@param count number
    ---@return boolean
    function self:SetInventoryItemCount(itemName, count)
        count = tonumber(count) or 0
        if count < 0 then return false end
        local itemDef = SLX.Items[itemName]
        if not itemDef then return false end
        if count == 0 then
            self.inventory[itemName] = nil
        else
            local existing = self.inventory[itemName]
            if existing then
                existing.count = count
            else
                self.inventory[itemName] = {
                    name     = itemName,
                    count    = count,
                    label    = itemDef.label,
                    weight   = itemDef.weight,
                    metadata = nil,
                }
            end
        end
        MySQL.update('UPDATE players SET inventory = ? WHERE identifier = ?', { SerializeInventory(), self.identifier })
        TriggerClientEvent('slx:recv_inventory', self.source, self.inventory)
        return true
    end
    ---@param itemName string
    ---@param count? number
    ---@return boolean
    function self:HasInventoryItem(itemName, count)
        count = tonumber(count) or 1
        local existing = self.inventory[itemName]
        if not existing then return false end
        return existing.count >= count
    end
    ---@param itemName string
    ---@param count? number
    ---@return boolean
    function self:CanCarryItem(itemName, count)
        count = tonumber(count) or 1
        local itemDef = SLX.Items[itemName]
        if not itemDef then return false end
        local totalWeight = 0
        for _, inv in pairs(self.inventory) do
            totalWeight = totalWeight + (inv.weight * inv.count)
        end
        local addedWeight = itemDef.weight * count
        return (totalWeight + addedWeight) <= (SLX.Config.MaxInventoryWeight or 50)
    end

    ---@return table
    function self:GetStatus() return self.status end
    ---@param key string
    ---@param value any
    ---@return boolean
    function self:SetStatus(key, value)
        if self.status[key] == nil then return false end
        self.status[key] = value
        MySQL.update('UPDATE players SET status = ? WHERE identifier = ?', { json.encode(self.status), self.identifier })
        return true
    end

    return self
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)
    if SLX.Config.EnableHardcap then
        local maxPlayers = GetConvarInt('sv_maxclients', SLX.Config.MaxPlayers or 48)
        local currentPlayers = GetNumPlayerIndices()
        if currentPlayers >= maxPlayers then
            local isPriority = false
            for _, group in ipairs(SLX.Config.PriorityGroups or {}) do
                if IsPlayerAceAllowed(src, ('group.%s'):format(group)) then
                    isPriority = true
                    break
                end
            end
            if not isPriority then
                deferrals.done(('Server is full (%d/%d). Please try again later.'):format(currentPlayers, maxPlayers))
                SLX.Log('INFO', ('Rejected %s (source %d) — server full (%d/%d)'):format(name, src, currentPlayers, maxPlayers))
                return
            end
            SLX.Debug(('Hardcap: priority bypass for %s'):format(name))
        end
    end
    SLX.Debug(('playerConnecting: %s (source %d)'):format(name, src))
    deferrals.update('Validating player name...')
    local nameValid, nameReason = ValidatePlayerName(name)
    if not nameValid then
        deferrals.done(('Connection rejected: %s'):format(nameReason))
        SLX.Log('WARN', ('Rejected %s (source %d) — invalid name: %s'):format(name, src, nameReason))
        return
    end
    deferrals.update('Checking Steam authentication...')
    local steamId = GetSteamIdentifier(src)
    if not steamId then
        deferrals.done('Steam is required to play on this server. Please start Steam and restart FiveX.')
        SLX.Log('WARN', ('Player %s (source %d) rejected — no Steam identifier'):format(name, src))
        return
    end
    SLX.Debug(('playerConnecting: steam found = %s'):format(steamId))
    if not SLX.Config.Debug then
        for _, existingPlayer in pairs(SLX.Players) do
            if existingPlayer.identifier == steamId then
                deferrals.done('Du bist bereits mit diesem Account verbunden.')
                SLX.Log('WARN', ('Rejected %s (source %d) — duplicate identifier %s already connected as source %d'):format(name, src, steamId, existingPlayer.source))
                return
            end
        end
    end
    deferrals.update('Checking ban status...')
    local ban = SLX.CheckBan and SLX.CheckBan(steamId)
    if ban then
        local expireText = ban.expire_time and ('Expires: ' .. ban.expire_time) or 'Permanent'
        deferrals.done(('You are banned from this server.\nReason: %s\n%s'):format(ban.reason, expireText))
        SLX.Log('WARN', ('Banned player %s (%s) tried to connect — %s'):format(name, steamId, ban.reason))
        return
    end
    deferrals.update('Loading your profile...')
    local result = MySQL.scalar.await('SELECT COUNT(*) FROM players WHERE identifier = ?', { steamId })
    SLX.Debug(('playerConnecting: DB lookup result = %s'):format(tostring(result)))
    if result == 0 then
        MySQL.insert.await('INSERT INTO players (identifier, money, last_name) VALUES (?, ?, ?)', { steamId, SLX.Config.StartingMoney, name })
        SLX.Log('INFO', ('New player registered: %s (%s)'):format(name, steamId))
    else
        MySQL.update('UPDATE players SET last_name = ? WHERE identifier = ?', { name, steamId })
    end
    deferrals.done()
    SLX.Log('INFO', ('Player connecting: %s (%s)'):format(name, steamId))
end)

RegisterNetEvent('slx:requestSpawnData')
AddEventHandler('slx:requestSpawnData', function()
    local src = source
    local steamId = GetSteamIdentifier(src)
    if not steamId then
        DropPlayer(src, 'Steam is required to play on this server.')
        return
    end
    if SLX.Players[src] then
        SLX.Log('WARN', ('Player source %d already loaded, skipping'):format(src))
        return
    end
    local rows = MySQL.query.await('SELECT * FROM players WHERE identifier = ? LIMIT 1', { steamId })
    if not rows or #rows == 0 then
        DropPlayer(src, 'Failed to load your player data. Please reconnect.')
        return
    end
    local data = rows[1]
    local player = CreatePlayerObject(src, data)
    SLX.Players[src] = player
    SLX.PlayersByID[player.id] = player
    SLX.ApplyGroupPrincipal(src, player.group)
    SLX.Log('INFO', ('Applied ACE group.%s for player %d'):format(player.group, src))
    if player.status.is_dead then
        SLX.Debug(('requestSpawnData: resetting is_dead for source %d (was dead on disconnect)'):format(src))
        player.status.is_dead = false
        player.health = 200
        player.armour = 0
        MySQL.update('UPDATE players SET status = ?, health = ?, armour = ? WHERE identifier = ?',
            { json.encode(player.status), player.health, player.armour, player.identifier })
    end
    if player.health <= 0 then
        SLX.Debug(('requestSpawnData: fixing health %d -> 200 for source %d'):format(player.health, src))
        player.health = 200
    end
    local isFirstJoin = (data.position == nil or data.position == '{"x":-269.4,"y":-955.3,"z":31.2,"heading":205.0}')
    local groupDef = SLX.Groups[player.group] or { label = player.group, priority = 0 }
    local clientData = {
        id         = player.id,
        source     = src,
        identifier = player.identifier,
        group      = { name = player.group, label = groupDef.label, priority = groupDef.priority },
        position   = player.position,
        health     = player.health,
        armour     = player.armour,
        weapons    = player.weapons,
        money      = player.money,
        job        = player:GetJob(),
        status     = player.status,
        kills      = player.kills,
        deaths     = player.deaths,
        xp         = player.xp,
        isFirstJoin = isFirstJoin,
        jobs       = SLX.Jobs,
        skin       = player.skin,
        inventory  = player.inventory,
    }
    TriggerClientEvent('slx:recv_playerData', src, clientData)
    TriggerEvent('slx:srv_playerLoaded', src)
    SLX.Log('INFO', ('Player loaded: ID %d, source %d (%s) [%s]'):format(player.id, src, steamId, player.group))
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    SLX.RemoveGroupPrincipal(src, player.group)
    player:Save()
    SLX.PlayersByID[player.id] = nil
    SLX.Players[src] = nil
    SLX.Log('INFO', ('Player dropped: source %d (%s) — %s'):format(src, player.identifier, reason))
end)

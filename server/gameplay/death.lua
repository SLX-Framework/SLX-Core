RegisterNetEvent('slx:playerDied')
AddEventHandler('slx:playerDied', function(killerServerId, weaponHash)
    local src = source
    local player = SLX.Players[src]
    if not player then
        SLX.Debug(('playerDied: player %d not loaded, ignoring'):format(src))
        return
    end

    local isArenaPlayer = false
    local arenaOk, arenaResult = pcall(function()
        return exports['slang_core']:IsPlayerInArena(src)
    end)
    if arenaOk and arenaResult then
        isArenaPlayer = true
    end

    if isArenaPlayer then
        SLX.Debug(('playerDied: player %d is in Arena, skipping framework death handling'):format(src))
        return
    end

    local ffaOk, ffaResult = pcall(function()
        return exports['slang_core']:IsPlayerInFFA(src)
    end)
    if ffaOk and ffaResult then
        SLX.Debug(('playerDied: player %d is in FFA, skipping framework death handling'):format(src))
        return
    end

    if player.status.is_dead then
        SLX.Debug(('playerDied: player %d already dead, ignoring duplicate'):format(src))
        return
    end
    player.status.is_dead = true
    player:AddDeath()
    MySQL.update('UPDATE players SET status = ? WHERE identifier = ?', { json.encode(player.status), player.identifier })
    SLX.Log('INFO', ('Player %d (%s) died'):format(src, player.identifier))
    SLX.Debug(('playerDied: deaths now = %d'):format(player.deaths))
    if killerServerId and killerServerId ~= src then
        local killer = SLX.Players[killerServerId]
        if killer then
            killer:AddKill()
            local xpReward = SLX.Config.XpPerKill or 10
            killer:AddXp(xpReward)
            local moneyReward = SLX.Config.KillMoneyReward or 100
            killer:AddMoney(moneyReward)
            SLX.Log('INFO', ('Player %d got a kill on player %d (+%d XP, +$%d)'):format(killerServerId, src, xpReward, moneyReward))
        end
    end
    SLX.Debug(('playerDied: sending respawn timer (%ds) to source %d'):format(SLX.Config.RespawnDelay, src))
    TriggerClientEvent('slx:startRespawnTimer', src, SLX.Config.RespawnDelay, killerServerId)
end)

RegisterNetEvent('slx:requestRespawn')
AddEventHandler('slx:requestRespawn', function(preferredSpawnId)
    local src = source
    local player = SLX.Players[src]
    if not player then
        SLX.Debug(('requestRespawn: player %d not loaded, ignoring'):format(src))
        return
    end
    if not player.status.is_dead then
        SLX.Debug(('requestRespawn: player %d already revived, ignoring'):format(src))
        return
    end
    SLX.Debug(('requestRespawn: processing for source %d'):format(src))
    player.status.is_dead = false
    MySQL.update('UPDATE players SET status = ? WHERE identifier = ?', { json.encode(player.status), player.identifier })
    local respawnPos = SLX.Config.DefaultSpawn
    if preferredSpawnId and type(preferredSpawnId) == 'string' then
        local ok, coords = pcall(function()
            return exports['slang_core']:GetSpawnCoordsById(preferredSpawnId)
        end)
        if ok and coords then
            respawnPos = coords
            SLX.Debug(('requestRespawn: using preferred spawn "%s"'):format(preferredSpawnId))
        end
    end
    player.health = 200
    player.armour = 100
    player.position = respawnPos
    SLX.Debug(('requestRespawn: sending respawn to %.1f, %.1f, %.1f'):format(respawnPos.x, respawnPos.y, respawnPos.z))
    TriggerClientEvent('slx:recv_respawn', src, respawnPos, player.health, player.armour)
    SLX.Log('INFO', ('Player %d respawning at %s'):format(src, preferredSpawnId or 'default spawn'))
end)

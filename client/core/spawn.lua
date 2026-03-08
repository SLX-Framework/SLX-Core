local hasSpawnedOnce = false

local function FreezePlayer(playerId, freeze)
    SetPlayerControl(playerId, not freeze, 0)
    local ped = GetPlayerPed(playerId)
    if freeze then
        if IsEntityVisible(ped) then SetEntityVisible(ped, false, false) end
        SetEntityCollision(ped, false, true)
        FreezeEntityPosition(ped, true)
        SetPlayerInvincible(playerId, true)
        if not IsPedFatallyInjured(ped) then ClearPedTasksImmediately(ped) end
    else
        if not IsEntityVisible(ped) then SetEntityVisible(ped, true, false) end
        if not IsPedInAnyVehicle(ped, false) then SetEntityCollision(ped, true, true) end
        FreezeEntityPosition(ped, false)
        SetPlayerInvincible(playerId, false)
    end
end

local function ApplyPerformanceFlags()
    local playerId = PlayerId()
    local cfg = SLX.Config
    SLX.Debug('ApplyPerformanceFlags: starting')
    if cfg.DisableDispatchServices then
        for i = 1, 15 do EnableDispatchService(i, false) end
    end
    if not cfg.EnableWantedLevel then
        SetMaxWantedLevel(0)
        ClearPlayerWantedLevel(playerId)
        SetPlayerWantedLevelNow(playerId, false)
    end
    if cfg.DisableVehicleRewards then DisablePlayerVehicleRewards(playerId) end
    if cfg.DisableHealthRegeneration then SetPlayerHealthRechargeMultiplier(playerId, 0.0) end
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
    NetworkSetFriendlyFireOption(cfg.EnablePVP)
    SetAudioFlag('PoliceScannerDisabled', true)
    DistantCopCarSirens(false)
    SetPoliceRadarBlips(false)
    SetRandomEventFlag(false)
    SLX.Debug('ApplyPerformanceFlags: done')
end

local function LoadPlayerModel(modelName)
    SLX.Debug(('LoadPlayerModel: requesting %s'):format(modelName))
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local timeout = 0
    while not HasModelLoaded(modelHash) and timeout < 5000 do
        Wait(10)
        timeout = timeout + 10
    end
    if not HasModelLoaded(modelHash) then
        SLX.Log('ERROR', ('Failed to load model after 5s: %s'):format(modelName))
        return false
    end
    SetPlayerModel(PlayerId(), modelHash)
    SetModelAsNoLongerNeeded(modelHash)
    SLX.Debug(('LoadPlayerModel: %s loaded in %dms'):format(modelName, timeout))
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)
    SLX.Debug(('LoadPlayerModel: ped %d ready'):format(ped))
    return true
end

local function RestoreWeapons(ped, weapons)
    RemoveAllPedWeapons(ped, true)
    if weapons and #weapons > 0 then
        for i = 1, #weapons do
            local w = weapons[i]
            GiveWeaponToPed(ped, GetHashKey(w.weapon), w.ammo, false, false)
        end
        SLX.Debug(('RestoreWeapons: gave %d weapon(s)'):format(#weapons))
    end
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedDeadOrDying(ped, true) then
            DisableControlAction(0, 48, true)
            SetEntityInvincible(ped, true)
            Wait(100)
        else
            Wait(500)
        end
    end
end)

RegisterNetEvent('slx:recv_playerData')
AddEventHandler('slx:recv_playerData', function(data)
    SLX.Debug('recv_playerData: received from server')
    SLX.Debug(('recv_playerData: identifier=%s source=%s firstJoin=%s'):format(
        tostring(data.identifier), tostring(data.source), tostring(data.isFirstJoin)))
    SLX.Debug(('recv_playerData: health=%s armour=%s is_dead=%s'):format(
        tostring(data.health), tostring(data.armour),
        tostring(data.status and data.status.is_dead)))
    if data.status and data.status.is_dead then
        SLX.Debug('recv_playerData: CLEARING is_dead flag (was dead on disconnect)')
        data.status.is_dead = false
    end
    local spawnHealth = (type(data.health) == 'number' and data.health > 0) and data.health or 200
    if spawnHealth < 200 then spawnHealth = 200 end
    SLX.Debug(('recv_playerData: resolved spawnHealth=%d'):format(spawnHealth))
    if data.jobs then
        SLX.Jobs = data.jobs
        SLX.Debug(('recv_playerData: received %d job(s)'):format(SLX.TableLength(data.jobs)))
    end
    SLX.LocalPlayer.id         = data.id
    SLX.LocalPlayer.source     = data.source
    SLX.LocalPlayer.identifier = data.identifier
    SLX.LocalPlayer.group      = data.group
    SLX.LocalPlayer.money      = data.money
    SLX.LocalPlayer.job        = data.job
    SLX.LocalPlayer.status     = data.status
    SLX.LocalPlayer.kills      = data.kills
    SLX.LocalPlayer.deaths     = data.deaths
    SLX.LocalPlayer.xp         = data.xp or 0
    SLX.LocalPlayer.inventory  = data.inventory or {}
    SLX.Debug('recv_playerData: LocalPlayer cache populated')
    local spawnPos
    if data.isFirstJoin then
        spawnPos = SLX.Config.DefaultSpawn
    else
        spawnPos = data.position or SLX.Config.DefaultSpawn
    end
    SLX.Debug(('recv_playerData: spawn pos = %.1f, %.1f, %.1f'):format(spawnPos.x, spawnPos.y, spawnPos.z))
    DoScreenFadeOut(0)
    ShutdownLoadingScreen()
    local ok, err = pcall(ApplyPerformanceFlags)
    if not ok then SLX.Log('WARN', ('ApplyPerformanceFlags failed: %s'):format(tostring(err))) end
    if not hasSpawnedOnce then
        local skinModel = data.skin and data.skin.model or SLX.Config.DefaultModel
        local modelOk = LoadPlayerModel(skinModel)
        SLX.Debug(('Phase 2: model load result = %s (model=%s)'):format(tostring(modelOk), skinModel))
    end
    FreezePlayer(PlayerId(), true)
    SLX.Debug(('Spawn: frozen playerId=%d ped=%d'):format(PlayerId(), PlayerPedId()))
    local oldSpawnPed = PlayerPedId()
    local ped = oldSpawnPed
    RequestCollisionAtCoord(spawnPos.x, spawnPos.y, spawnPos.z)
    SetEntityCoordsNoOffset(ped, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    SetEntityHeading(ped, spawnPos.heading or 0.0)
    NetworkResurrectLocalPlayer(spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.heading or 0.0, true, true)
    ped = PlayerPedId()
    if oldSpawnPed ~= ped and DoesEntityExist(oldSpawnPed) then
        SetEntityAsMissionEntity(oldSpawnPed, true, true)
        DeleteEntity(oldSpawnPed)
        SLX.Debug(('Spawn: deleted old ped %d, new ped %d'):format(oldSpawnPed, ped))
    end
    ClearPedTasksImmediately(ped)
    RemoveAllPedWeapons(ped, true)
    ClearPlayerWantedLevel(PlayerId())
    SLX.Debug(('Spawn: resurrected ped=%d'):format(ped))
    local collisionTimeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and collisionTimeout < 5000 do
        Wait(0)
        collisionTimeout = collisionTimeout + 1
    end
    SLX.Debug(('Spawn: collision ready (%d frames)'):format(collisionTimeout))
    SetEntityHealth(ped, spawnHealth)
    SetPedArmour(ped, data.armour or 0)
    ClearPedBloodDamage(ped)
    ClearPedLastWeaponDamage(ped)
    RestoreWeapons(ped, data.weapons)
    SetMaxWantedLevel(0)
    SetEntityInvincible(ped, false)
    SLX.Debug(('Spawn: state applied health=%d'):format(GetEntityHealth(ped)))
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
    FreezePlayer(PlayerId(), false)
    SLX.Debug(('Spawn: unfrozen ped=%d health=%d isDead=%s'):format(
        ped, GetEntityHealth(ped), tostring(IsEntityDead(ped))))
    SLX.Cache.ped = ped
    SLX.Cache.coords = vector3(spawnPos.x, spawnPos.y, spawnPos.z)
    SLX.LocalPlayer.spawned = true
    hasSpawnedOnce = true
    TriggerEvent('slx:playerLoaded', data)
    TriggerEvent('slx:playerSpawned')
    SLX.Debug('Spawn: all events fired, shutting down loading screen NUI')
    Wait(200)
    ShutdownLoadingScreenNui()
    SLX.Debug('Spawn: ShutdownLoadingScreenNui() called')
    SLX.Log('INFO', 'Player spawned and loaded successfully')
end)

RegisterNetEvent('slx:recv_respawn')
AddEventHandler('slx:recv_respawn', function(respawnPos, health, armour)
    if not SLX.LocalPlayer.status.is_dead then return end
    armour = armour or 100
    SLX.Debug(('recv_respawn: pos=%.1f,%.1f,%.1f health=%d armour=%d'):format(
        respawnPos.x, respawnPos.y, respawnPos.z, health, armour))
    DoScreenFadeOut(300)
    while not IsScreenFadedOut() do Wait(0) end
    FreezePlayer(PlayerId(), true)
    local oldPed = PlayerPedId()
    RequestCollisionAtCoord(respawnPos.x, respawnPos.y, respawnPos.z)
    NetworkResurrectLocalPlayer(respawnPos.x, respawnPos.y, respawnPos.z, respawnPos.heading or 0.0, true, true)
    local ped = PlayerPedId()
    if oldPed ~= ped and DoesEntityExist(oldPed) then
        SetEntityAsMissionEntity(oldPed, true, true)
        DeleteEntity(oldPed)
        SLX.Debug(('Respawn: deleted old ped %d, new ped %d'):format(oldPed, ped))
    end
    ClearPedTasksImmediately(ped)
    SetEntityCoordsNoOffset(ped, respawnPos.x, respawnPos.y, respawnPos.z, false, false, false)
    SetEntityHeading(ped, respawnPos.heading or 0.0)
    local collisionTimeout = 0
    while not HasCollisionLoadedAroundEntity(ped) and collisionTimeout < 5000 do
        Wait(0)
        collisionTimeout = collisionTimeout + 1
    end
    SetEntityHealth(ped, health)
    SetPedArmour(ped, armour)
    ClearPedBloodDamage(ped)
    ClearPedLastWeaponDamage(ped)
    SetEntityInvincible(ped, false)
    SLX.LocalPlayer.status.is_dead = false
    TriggerEvent('slx:respawnComplete')
    local ok, err = pcall(ApplyPerformanceFlags)
    if not ok then SLX.Log('WARN', ('ApplyPerformanceFlags failed on respawn: %s'):format(tostring(err))) end
    SLX.Cache.ped = ped
    SLX.Cache.coords = vector3(respawnPos.x, respawnPos.y, respawnPos.z)
    DoScreenFadeIn(500)
    while not IsScreenFadedIn() do Wait(0) end
    FreezePlayer(PlayerId(), false)
    TriggerEvent('slx:playerSpawned')
    SLX.Log('INFO', 'Player respawned successfully')
end)

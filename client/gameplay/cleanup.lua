local cfg = nil
local _invalidateIdleCam = InvalidateIdleCam or function() end

CreateThread(function()
    cfg = SLX.Config
    local playerId = PlayerId()
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
    SetGarbageTrucks(false)
    SetRandomBoats(false)
    SetRandomTrains(false)
    if cfg.DisableHealthRegeneration then
        SetPlayerHealthRechargeMultiplier(playerId, 0.0)
    end
    NetworkSetFriendlyFireOption(cfg.EnablePVP)
    if not cfg.EnableWantedLevel then
        SetMaxWantedLevel(0)
        ClearPlayerWantedLevel(playerId)
        SetPlayerWantedLevelNow(playerId, false)
    end
    if cfg.DisableDispatchServices then
        for i = 1, 15 do EnableDispatchService(i, false) end
    end
    if cfg.DisableVehicleRewards then
        DisablePlayerVehicleRewards(playerId)
    end
    if cfg.DisableAimAssist then
        SetPlayerLockonRangeOverride(playerId, 0.0)
    end
    SetAudioFlag('PoliceScannerDisabled', true)
    DistantCopCarSirens(false)
    SetPoliceRadarBlips(false)
    SetRandomEventFlag(false)
    if StopStaticEmitter then StopStaticEmitter('LOS_SANTOS_AMBIENCE') end
    for id, hide in pairs(cfg.RemoveHudComponents) do
        if hide then SetHudComponentPosition(id, 999999.0, 999999.0) end
    end
    SLX.Debug('Cleanup: all one-time flags applied')
end)

CreateThread(function()
    while not cfg do Wait(100) end
    if not cfg.EnableInfiniteAmmo then return end
    local unarmedHash = GetHashKey('WEAPON_UNARMED')
    local lastInfAmmoWeapon = nil
    while true do
        if SLX.LocalPlayer.spawned then
            local ped = PlayerPedId()
            local weapon = GetSelectedPedWeapon(ped)
            if weapon ~= unarmedHash and weapon ~= lastInfAmmoWeapon then
                SetPedInfiniteAmmo(ped, true, weapon)
                lastInfAmmoWeapon = weapon
            end
        end
        Wait(500)
    end
end)

CreateThread(function()
    while not cfg do Wait(100) end
    while not SLX.LocalPlayer.spawned do Wait(500) end
    SLX.Debug('Cleanup 2.5s: player spawned, starting loop')
    while true do
        Wait(2500)
        _invalidateIdleCam()
        local ped = PlayerPedId()
        local playerId = PlayerId()
        SetPedDropsWeaponsWhenDead(ped, false)
        ClearPedBloodDamage(ped)
        RestorePlayerStamina(playerId, 100.0)
        SetPedSuffersCriticalHits(ped, true)
        local coords = GetEntityCoords(ped)
        ClearAreaOfProjectiles(coords.x, coords.y, coords.z, 100.0, 0)
    end
end)

CreateThread(function()
    Wait(5000)
    local models = {-1241212535, -1574151574, 1215477734}
    while true do
        local coords = GetEntityCoords(PlayerPedId())
        for i = 1, #models do
            local obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 200.0, models[i], false, false, false)
            while obj ~= 0 do
                SetEntityAsMissionEntity(obj, true, true)
                DeleteObject(obj)
                obj = GetClosestObjectOfType(coords.x, coords.y, coords.z, 200.0, models[i], false, false, false)
            end
        end
        Wait(10000)
    end
end)

CreateThread(function()
    local removedCount = 0
    local blipHandle = GetFirstBlipInfoId(1)
    while DoesBlipExist(blipHandle) do
        local blipEntity = GetBlipInfoIdEntityIndex(blipHandle)
        if not IsPedAPlayer(blipEntity) then
            RemoveBlip(blipHandle)
            removedCount = removedCount + 1
        end
        blipHandle = GetNextBlipInfoId(1)
    end
    local blipTypes = { 3, 56, 60, 67, 68, 69, 70, 71, 72, 73, 74, 75 }
    for i = 1, #blipTypes do
        local bh = GetFirstBlipInfoId(blipTypes[i])
        while DoesBlipExist(bh) do
            RemoveBlip(bh)
            removedCount = removedCount + 1
            bh = GetNextBlipInfoId(blipTypes[i])
        end
    end
    SLX.Log('INFO', ('Vanilla blips removed (%d total)'):format(removedCount))
end)


CreateThread(function()
    while not cfg do Wait(100) end
    while true do
        Wait(30000)
        local playerId = PlayerId()
        local ped = PlayerPedId()
        if not cfg.EnableWantedLevel then
            SetMaxWantedLevel(0)
            ClearPlayerWantedLevel(playerId)
        end
        SetCreateRandomCops(false)
        SetCreateRandomCopsNotOnScenarios(false)
        SetCreateRandomCopsOnScenarios(false)
        if cfg.DisableDispatchServices then
            for i = 1, 15 do EnableDispatchService(i, false) end
        end
        if cfg.DisableHealthRegeneration then
            SetPlayerHealthRechargeMultiplier(playerId, 0.0)
        end
        ClearTimecycleModifier()
        SetForceVehicleTrails(false)
        SetForcePedFootstepsTracks(false)
        RemoveParticleFxInRange(GetEntityCoords(ped), 10.0)
        ClearAllBrokenGlass()
        ClearAllHelpMessages()
        LeaderboardsReadClearAll()
        ClearBrief()
        ClearGpsFlags()
        ClearPrints()
        ClearSmallPrints()
        ClearReplayStats()
        LeaderboardsClearCacheData()
        ClearFocus()
        ClearHdArea()
    end
end)

AddEventHandler('slx:playerSpawned', function()
    if not cfg then return end
    local playerId = PlayerId()
    if not cfg.EnableWantedLevel then
        ClearPlayerWantedLevel(playerId)
        SetPlayerWantedLevelNow(playerId, false)
        SetMaxWantedLevel(0)
    end
    if cfg.DisableVehicleRewards then DisablePlayerVehicleRewards(playerId) end
    if cfg.DisableHealthRegeneration then SetPlayerHealthRechargeMultiplier(playerId, 0.0) end
    if cfg.DisableAimAssist then SetPlayerLockonRangeOverride(playerId, 0.0) end
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
    NetworkSetFriendlyFireOption(cfg.EnablePVP)
    for id, hide in pairs(cfg.RemoveHudComponents) do
        if hide then SetHudComponentPosition(id, 999999.0, 999999.0) end
    end
end)

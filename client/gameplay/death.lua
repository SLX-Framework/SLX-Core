local isDying = false
local respawnTimer = 0
local victimCam = nil
local victimCamActive = false

local function StopDeathCam()
    if not victimCamActive then return end
    victimCamActive = false
    if victimCam then
        RenderScriptCams(false, true, 500, true, false)
        SetCamActive(victimCam, false)
        DestroyCam(victimCam, false)
        victimCam = nil
    end
end

local function StartDeathCam(killerServerId, durationMs)
    local killerPlayer = GetPlayerFromServerId(killerServerId)
    if killerPlayer == -1 then return end
    local killerPed = GetPlayerPed(killerPlayer)
    if not DoesEntityExist(killerPed) then return end

    StopDeathCam()
    victimCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local offset = GetOffsetFromEntityInWorldCoords(killerPed, 0.0, -3.0, 1.5)
    SetCamCoord(victimCam, offset.x, offset.y, offset.z)
    PointCamAtEntity(victimCam, killerPed, 0.0, 0.0, 0.0, true)
    SetCamActive(victimCam, true)
    RenderScriptCams(true, true, 500, true, false)
    victimCamActive = true

    CreateThread(function()
        local timer = durationMs or 5000
        while victimCamActive and timer > 0 do
            if not DoesEntityExist(killerPed) then
                StopDeathCam()
                return
            end
            local kOffset = GetOffsetFromEntityInWorldCoords(killerPed, 0.0, -3.0, 1.5)
            SetCamCoord(victimCam, kOffset.x, kOffset.y, kOffset.z)
            PointCamAtEntity(victimCam, killerPed, 0.0, 0.0, 0.0, true)
            timer = timer - 16
            Wait(0)
        end
        StopDeathCam()
    end)
end



---@return boolean
local function IsInFFA()
    local ffaOk, ffaActive = pcall(function() return exports['slang_core']:IsInFFA() end)
    if ffaOk and ffaActive then return true end
    return false
end

---@return boolean
local function IsInArena()
    local ok, active = pcall(function() return exports['slang_core']:IsInArena() end)
    if ok and active then return true end
    return false
end

local function HandleDeath(killerServerId, weaponHash, isNatural)
    if IsInFFA() then
        if isDying then return end
        isDying = true
        SLX.Debug('HandleDeath: FFA active — handling FFA death only')
        local playerPed = PlayerPedId()
        local deathCoords = GetEntityCoords(playerPed)
        local deathHeading = GetEntityHeading(playerPed)
        NetworkResurrectLocalPlayer(deathCoords.x, deathCoords.y, deathCoords.z, deathHeading, true, false)
        local ped = PlayerPedId()
        SetEntityHealth(ped, 1)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        ClearPedTasksImmediately(ped)
        TriggerServerEvent('slx:playerDied', killerServerId, weaponHash)
        TriggerEvent('slx:playerDied', killerServerId)
        CreateThread(function()
            while IsEntityDead(PlayerPedId()) do
                Wait(100)
            end
            isDying = false
        end)
        return
    end
    if isDying then
        SLX.Debug('HandleDeath: SKIPPED — already isDying')
        return
    end
    if not SLX.LocalPlayer.spawned then
        SLX.Debug('HandleDeath: SKIPPED — not spawned yet')
        return
    end
    if SLX.LocalPlayer.status.is_dead then
        SLX.Debug('HandleDeath: SKIPPED — is_dead already true')
        return
    end
    if SLX.Config.EnableCustomDeathSync then
        SLX.Debug(('HandleDeath: custom sync active, killed by %s — handing off to external sync'):format(tostring(killerServerId)))
        isDying = true
        SLX.LocalPlayer.status.is_dead = true
        if isNatural then
            print('Natural death detected, notifying server without weapon info')
            TriggerServerEvent('slx:playerDied', killerServerId, weaponHash)
            TriggerEvent('slx:playerDied', killerServerId)
        end
        return
    end
    isDying = true
    SLX.LocalPlayer.status.is_dead = true
    local playerPed = PlayerPedId()
    local deathCoords = GetEntityCoords(playerPed)
    local deathHeading = GetEntityHeading(playerPed)
    SLX.Debug(('HandleDeath: died at %.1f, %.1f, %.1f killer=%s'):format(
        deathCoords.x, deathCoords.y, deathCoords.z, tostring(killerServerId)))
    Wait(0)
    local oldPed = playerPed
    NetworkResurrectLocalPlayer(deathCoords.x, deathCoords.y, deathCoords.z, deathHeading, true, false)
    local ped = PlayerPedId()
    if oldPed ~= ped and DoesEntityExist(oldPed) then
        SetEntityAsMissionEntity(oldPed, true, true)
        DeleteEntity(oldPed)
        SLX.Debug(('HandleDeath: deleted old ped %d, new ped %d'):format(oldPed, ped))
    end
    SetEntityCoordsNoOffset(ped, deathCoords.x, deathCoords.y, deathCoords.z, false, false, false)
    SetEntityHeading(ped, deathHeading)
    SetEntityHealth(ped, 1)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    ClearPedTasksImmediately(ped)
    TriggerServerEvent('slx:playerDied', killerServerId, weaponHash)
    TriggerEvent('slx:playerDied', killerServerId)
    SLX.Log('INFO', 'Player died' .. (killerServerId and (' — killed by ' .. killerServerId) or ''))
end

local HEAD_BONE = 31086

AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName ~= 'CEventNetworkEntityDamage' then return end
    local victim = args[1]
    local attacker = args[2]
    local isFatal = args[4]
    local weaponHash = args[5]
    local playerPed = PlayerPedId()
    if victim ~= playerPed then return end

    local killerServerId = nil
    if attacker and attacker ~= 0 and attacker ~= playerPed and IsPedAPlayer(attacker) then
        killerServerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(attacker))
    end

    local boneHit, bone = GetPedLastDamageBone(playerPed)
    if boneHit and bone == HEAD_BONE and weaponHash ~= GetHashKey('WEAPON_UNARMED') and weaponHash ~= GetHashKey('WEAPON_ANIMAL') then
        SLX.Debug(('Headshot detected from %s — instant kill'):format(tostring(killerServerId)))
        SetEntityHealth(playerPed, 0)
        HandleDeath(killerServerId, weaponHash, false)
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if SLX.LocalPlayer.spawned and not isDying and not SLX.LocalPlayer.status.is_dead then
            if SLX.Config.EnableCustomDeathSync then
                local headshotTriggered = exports['slang_syncV2']:IsHeadshotDeathTriggered()
                if IsInArena() and headshotTriggered then
                    SLX.Debug('Headshot death in Arena zone — skipping death handling')
                elseif IsEntityDead(PlayerPedId()) then
                    SLX.Debug('Death detected via polling fallback')
                    HandleDeath(nil, nil, true)
                end
            else
                if IsEntityDead(PlayerPedId()) then
                    SLX.Debug('Death detected via polling fallback')
                    HandleDeath(nil, nil, true)
                end
            end
        end
    end
end)

RegisterNetEvent('slx:startRespawnTimer')
AddEventHandler('slx:startRespawnTimer', function(delaySeconds, killerServerId)
    if IsInArena() then
        SLX.Debug('startRespawnTimer: SKIPPED — player is in Arena zone')
        return
    end
    respawnTimer = delaySeconds
    SLX.Debug(('startRespawnTimer: %d seconds'):format(delaySeconds))
    if killerServerId then
        StartDeathCam(killerServerId, delaySeconds * 1000)
    end
    local displayText = ('~r~YOU DIED ~s~| Respawning in %ds'):format(respawnTimer)
    CreateThread(function()
        while respawnTimer > 0 do
            DisableAllControlActions(0)
            EnableControlAction(0, 1, true)
            EnableControlAction(0, 2, true)
            EnableControlAction(0, 245, true)
            SetTextFont(4)
            SetTextScale(0.0, 0.5)
            SetTextColour(255, 255, 255, 255)
            SetTextCentre(true)
            SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(displayText)
            EndTextCommandDisplayText(0.5, 0.85)
            Wait(0)
        end
    end)
    CreateThread(function()
        while respawnTimer > 0 do
            Wait(1000)
            respawnTimer = respawnTimer - 1
            displayText = ('~r~YOU DIED ~s~| Respawning in %ds'):format(respawnTimer)
        end
        if isDying then
            SLX.Debug('Respawn countdown complete, requesting respawn')
            local preferredSpawn = nil
            local spawnOk, spawnResult = pcall(function()
                return exports['slang_core']:GetPreferredSpawnId()
            end)
            if spawnOk and spawnResult then
                preferredSpawn = spawnResult
            end
            TriggerServerEvent('slx:requestRespawn', preferredSpawn)
        end
    end)
end)

AddEventHandler('slx:respawnComplete', function()
    StopDeathCam()
    isDying = false
    respawnTimer = 0
    SLX.Debug('respawnComplete: death state fully reset')
end)

RegisterNetEvent('slx:recv_revive')
AddEventHandler('slx:recv_revive', function(health)
    SLX.Debug(('recv_revive: health=%d'):format(health))
    isDying = false
    respawnTimer = 0
    StopDeathCam()
    SLX.LocalPlayer.status.is_dead = false
    local ped = PlayerPedId()
    if IsEntityDead(ped) then
        local oldPed = ped
        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
        ped = PlayerPedId()
        if oldPed ~= ped and DoesEntityExist(oldPed) then
            SetEntityAsMissionEntity(oldPed, true, true)
            DeleteEntity(oldPed)
            SLX.Debug(('recv_revive: deleted old ped %d, new ped %d'):format(oldPed, ped))
        end
    end
    SetEntityHealth(ped, health)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ClearPedLastWeaponDamage(ped)
    ClearPedTasksImmediately(ped)
    SetPlayerControl(PlayerId(), true, 0)
    if not IsEntityVisible(ped) then SetEntityVisible(ped, true, false) end
    SetEntityCollision(ped, true, true)
    FreezeEntityPosition(ped, false)
    SetPlayerInvincible(PlayerId(), false)
    SetEntityInvincible(ped, false)
    SLX.Cache.ped = ped
    SLX.Log('INFO', 'Player revived by admin')
end)

AddEventHandler('slx:playerUnloaded', function()
    StopDeathCam()
end)
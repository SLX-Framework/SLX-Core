local VoiceModes = { [1] = 3.0, [2] = 15.0, [3] = 35.0 }
local VoiceLabels = { [1] = 'Flüstern', [2] = 'Normal', [3] = 'Schreien' }
local mode = 2
local range = VoiceModes[mode]
local time = 0
local currentSize = (range * 2.0)
local targetSize = (range * 2.0)
local isTalking = false

AddEventHandler('mumbleConnected', function(address, isReconnecting)
    MumbleSetTalkerProximity(VoiceModes[mode] + 0.0)
    SLX.Debug('Mumble connected, voice initialized with proximity ' .. VoiceModes[mode])
end)

RegisterKeyMapping('cycleproximity', 'Sprachreichweite ändern', 'keyboard', 'Z')
RegisterCommand('cycleproximity', function()
    if MumbleIsConnected() then
        local newMode = mode + 1
        if newMode > #VoiceModes then
            newMode = 1
        end
        mode = newMode
        range = VoiceModes[mode]
        targetSize = (range * 2.0)
        time = 250
        MumbleSetTalkerProximity(VoiceModes[mode] + 0.0)
        SLX.ShowNotification(('~r~Voice: ~w~%s (~r~%.0fm~w~)'):format(VoiceLabels[mode], VoiceModes[mode]))
        SLX.Debug(('Voice mode changed to %s (%.0fm)'):format(VoiceLabels[mode], VoiceModes[mode]))
    else
        SLX.ShowNotification('~r~Du musst den Ingame Sprachchat aktiviert haben')
    end
end, false)

CreateThread(function()
    while true do
        if time > 0 then
            time = time - 1
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local size = currentSize + (targetSize - currentSize) * 0.1
            local zOffset = IsPedInAnyVehicle(playerPed) and -0.5 or -1.2
            DrawMarker(1, playerCoords.x, playerCoords.y, playerCoords.z + zOffset, 0.0, 0.0, 0.0, 0, 0.0, 0.0, size, size, 1.0, 207, 45, 45, 150, false, true, 2, false, false, false, false)
            currentSize = size
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    local playerId = PlayerId()
    while true do
        if MumbleIsConnected() then
            isTalking = NetworkIsPlayerTalking(playerId)
            Wait(250)
        else
            Wait(1000)
        end
    end
end)

---@return number
function SLX.GetVoiceMode()
    return mode
end

---@return number
function SLX.GetVoiceRange()
    return VoiceModes[mode]
end

---@return string
function SLX.GetVoiceLabel()
    return VoiceLabels[mode]
end

---@return boolean
function SLX.IsPlayerTalking()
    return isTalking
end

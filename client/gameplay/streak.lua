local killStreak = 0
local lastKillTime = 0
local streakTimeout = 10000

---@return integer
function SLX.GetKillStreak()
    return killStreak
end

AddEventHandler('slx:playerDied', function(killerServerId)
    killStreak = 0
end)

RegisterNetEvent('slx:recv_killConfirm')
AddEventHandler('slx:recv_killConfirm', function()
    local now = GetGameTimer()
    if (now - lastKillTime) > streakTimeout then
        killStreak = 1
    else
        killStreak = killStreak + 1
    end
    lastKillTime = now
    TriggerEvent('slx:killStreakUpdated', killStreak)
    SLX.Debug(('Kill streak: %d'):format(killStreak))
end)

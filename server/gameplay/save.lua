AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    SLX.Log('INFO', 'Resource stopping — saving all players...')
    local count = 0
    for src, player in pairs(SLX.Players) do
        if player then
            player:Save()
            count = count + 1
        end
    end
    if count > 0 then SLX.Log('INFO', ('Saved %d player(s) on stop'):format(count)) end
end)

RegisterNetEvent('slx:syncPlayerData')
AddEventHandler('slx:syncPlayerData', function(data)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if data.position then player.position = data.position end
    if data.health then player.health = data.health end
    if data.armour then player.armour = data.armour end
end)

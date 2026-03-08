RegisterNetEvent('slx:saveSkin')
AddEventHandler('slx:saveSkin', function(skinData)
    local src = source
    local player = SLX.Players[src]
    if not player then
        SLX.Debug(('saveSkin: player %d not loaded, ignoring'):format(src))
        return
    end
    if type(skinData) ~= 'table' then return end
    player.skin = skinData
    local skinJson = json.encode(skinData)
    MySQL.update('UPDATE players SET skin = ? WHERE identifier = ?', { skinJson, player.identifier })
    SLX.Log('INFO', ('Player %d (%s) saved skin'):format(src, player.identifier))
    SLX.Debug(('saveSkin: saved for %d — model=%s'):format(src, tostring(skinData.model)))
end)

SLX.RegisterServerCallback('slx:getSkin', function(src, respond)
    local player = SLX.Players[src]
    if not player then
        respond(nil)
        return
    end
    respond(player.skin)
end)

CreateThread(function()
    while not SLX.LocalPlayer.spawned do Wait(1000) end
    while true do
        Wait(SLX.Config.ClientSyncInterval)
        if not SLX.LocalPlayer.spawned then goto continue end
        local ped = PlayerPedId()
        SLX.Cache.ped = ped
        local coords = GetEntityCoords(ped)
        SLX.Cache.coords = coords
        TriggerServerEvent('slx:syncPlayerData', {
            position = { x = coords.x, y = coords.y, z = coords.z, heading = GetEntityHeading(ped) },
            health   = GetEntityHealth(ped),
            armour   = GetPedArmour(ped),
        })
        ::continue::
    end
end)

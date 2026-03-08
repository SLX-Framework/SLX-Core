RegisterNetEvent('slx:addMoney')
AddEventHandler('slx:addMoney', function(amount)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if player:AddMoney(amount) then
        SLX.Log('INFO', ('Added $%d to player %d'):format(amount, src))
    end
end)

RegisterNetEvent('slx:removeMoney')
AddEventHandler('slx:removeMoney', function(amount)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    amount = tonumber(amount)
    if not amount or amount <= 0 then return end
    if player:RemoveMoney(amount) then
        SLX.Log('INFO', ('Removed $%d from player %d'):format(amount, src))
    else
        TriggerClientEvent('slx:notify', src, 'Not enough money!')
    end
end)

RegisterNetEvent('slx:setMoney')
AddEventHandler('slx:setMoney', function(amount)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    amount = tonumber(amount)
    if not amount or amount < 0 then return end
    if player:SetMoney(amount) then
        SLX.Log('INFO', ('Set money to $%d for player %d'):format(amount, src))
    end
end)

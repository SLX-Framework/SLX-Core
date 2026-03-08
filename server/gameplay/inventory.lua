---@param itemName string
---@param callback fun(source: number, itemName: string, itemData: table)
function SLX.RegisterItemUse(itemName, callback)
    if not SLX.Items[itemName] then
        SLX.Log('WARN', ('RegisterItemUse: item "%s" does not exist'):format(itemName))
        return
    end
    SLX.ItemCallbacks[itemName] = callback
    SLX.Debug(('RegisterItemUse: registered handler for "%s"'):format(itemName))
end

RegisterNetEvent('slx:useItem')
AddEventHandler('slx:useItem', function(itemName)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if type(itemName) ~= 'string' or itemName == '' then return end
    local itemDef = SLX.Items[itemName]
    if not itemDef then return end
    if not itemDef.usable then return end
    local invItem = player:GetInventoryItem(itemName)
    if not invItem or invItem.count <= 0 then return end
    local callback = SLX.ItemCallbacks[itemName]
    if not callback then return end
    callback(src, itemName, invItem)
end)


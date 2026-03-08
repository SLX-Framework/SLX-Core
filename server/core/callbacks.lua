---@param name string
---@param cb fun(source: number, respond: function, ...)
function SLX.RegisterServerCallback(name, cb)
    SLX.Callbacks[name] = cb
end

RegisterNetEvent('slx:serverCallback')
AddEventHandler('slx:serverCallback', function(name, requestId, ...)
    local src = source
    local cb = SLX.Callbacks[name]
    if not cb then
        SLX.Log('WARN', ('No server callback registered for: %s'):format(name))
        return
    end
    cb(src, function(...)
        TriggerClientEvent('slx:serverCallbackResponse', src, requestId, ...)
    end, ...)
end)

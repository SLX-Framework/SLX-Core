local requestIdCounter = 0

---@param name string
---@param cb function
---@param ... any
function SLX.TriggerServerCallback(name, cb, ...)
    requestIdCounter = requestIdCounter + 1
    local requestId = requestIdCounter
    SLX.Callbacks[requestId] = cb
    TriggerServerEvent('slx:serverCallback', name, requestId, ...)
end

RegisterNetEvent('slx:serverCallbackResponse')
AddEventHandler('slx:serverCallbackResponse', function(requestId, ...)
    local cb = SLX.Callbacks[requestId]
    if cb then
        cb(...)
        SLX.Callbacks[requestId] = nil
    end
end)

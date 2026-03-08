---@param message string
---@param notifyType? string 'info' | 'success' | 'error' | 'warning'
---@param length? number
function SLX.ShowNotification(message, notifyType, length)
    exports['slang_core']:SendNotification(message, notifyType or 'info', length or 5000)
end

---@param sender string
---@param subject string
---@param msg string
---@param textureDict string
---@param iconType? number
---@param flash? boolean
---@param saveToBrief? boolean
---@param hudColorIndex? number
function SLX.ShowAdvancedNotification(sender, subject, msg, textureDict, iconType, flash, saveToBrief, hudColorIndex)
    if saveToBrief == nil then saveToBrief = true end
    AddTextEntry('SLX_ADV_NOTIF', msg)
    BeginTextCommandThefeedPost('SLX_ADV_NOTIF')
    if hudColorIndex then ThefeedSetNextPostBackgroundColor(hudColorIndex) end
    EndTextCommandThefeedPostMessagetext(textureDict, textureDict, flash or false, iconType or 1, sender, subject)
    EndTextCommandThefeedPostTicker(false, saveToBrief)
end

---@param message string
---@param length number
---@param options? table
---@return boolean
function SLX.Progressbar(message, length, options)
    return exports['slang_core']:Progressbar(message, length, options)
end

---@return boolean
function SLX.CancelProgressbar()
    return exports['slang_core']:CancelProgressbar()
end

---@param message string
---@param duration? number
function SLX.ShowAnnounce(message, duration)
    exports['slang_core']:ShowAnnounce(message, duration or 8000)
end

SLX.Game = {}

---@param vehicleModel string|number
---@param coords vector3
---@param heading number
---@param cb? fun(vehicle: number|nil)
---@param networked? boolean
function SLX.Game.SpawnVehicle(vehicleModel, coords, heading, cb, networked)
    if networked == nil then networked = true end
    local modelHash = type(vehicleModel) == 'string' and GetHashKey(vehicleModel) or vehicleModel
    RequestModel(modelHash)
    local timeout = 0
    CreateThread(function()
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        if not HasModelLoaded(modelHash) then
            SLX.Log('ERROR', 'SpawnVehicle: failed to load model after 5s')
            if cb then cb(nil) end
            return
        end
        local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, heading, networked, false)
        SetModelAsNoLongerNeeded(modelHash)
        if networked then
            local netTimeout = 0
            while not NetworkGetEntityIsNetworked(vehicle) and netTimeout < 2000 do
                Wait(10)
                netTimeout = netTimeout + 10
            end
            SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(vehicle), true)
            SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        end
        SLX.Debug(('SpawnVehicle: created vehicle %d'):format(vehicle))
        if cb then cb(vehicle) end
    end)
end

---@param vehicle number
function SLX.Game.DeleteVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end
    SetEntityAsMissionEntity(vehicle, true, true)
    DeleteVehicle(vehicle)
end

---@param onlyOtherPlayers? boolean
---@param returnKeyValue? boolean
---@param returnPeds? boolean
---@return table
function SLX.Game.GetPlayers(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players = {}
    local localPlayer = PlayerId()
    for _, playerId in ipairs(GetActivePlayers()) do
        if not onlyOtherPlayers or playerId ~= localPlayer then
            if returnKeyValue then
                local serverId = GetPlayerServerId(playerId)
                players[serverId] = returnPeds and GetPlayerPed(playerId) or playerId
            else
                players[#players + 1] = returnPeds and GetPlayerPed(playerId) or playerId
            end
        end
    end
    return players
end

---@param coords? vector3
---@return number|nil closestPlayer
---@return number closestDist
function SLX.Game.GetClosestPlayer(coords)
    if not coords then coords = GetEntityCoords(PlayerPedId()) end
    local closestPlayer = nil
    local closestDist = math.huge
    local localPlayer = PlayerId()
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= localPlayer then
            local dist = #(coords - GetEntityCoords(GetPlayerPed(playerId)))
            if dist < closestDist then
                closestDist = dist
                closestPlayer = playerId
            end
        end
    end
    return closestPlayer, closestDist
end

---@return number|nil
function SLX.Game.GetVehicleInDirection()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local offset = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local rayHandle = StartShapeTestRay(pedCoords.x, pedCoords.y, pedCoords.z, offset.x, offset.y, offset.z, 10, ped, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)
    if hit == 1 and DoesEntityExist(entityHit) and IsEntityAVehicle(entityHit) then return entityHit end
    return nil
end

---@param coords? vector3
---@return number|nil closestVehicle
---@return number closestDist
function SLX.Game.GetClosestVehicle(coords)
    if not coords then coords = GetEntityCoords(PlayerPedId()) end
    local closestVeh = nil
    local closestDist = math.huge
    local handle, vehicle = FindFirstVehicle()
    local success = true
    while success do
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist < closestDist then
                closestDist = dist
                closestVeh = vehicle
            end
        end
        success, vehicle = FindNextVehicle(handle)
    end
    EndFindVehicle(handle)
    return closestVeh, closestDist
end

---@param coords vector3
---@param radius number
---@return table
function SLX.Game.GetVehiclesInArea(coords, radius)
    local vehicles = {}
    local handle, vehicle = FindFirstVehicle()
    local success = true
    while success do
        if DoesEntityExist(vehicle) then
            local dist = #(coords - GetEntityCoords(vehicle))
            if dist <= radius then
                vehicles[#vehicles + 1] = vehicle
            end
        end
        success, vehicle = FindNextVehicle(handle)
    end
    EndFindVehicle(handle)
    return vehicles
end

---@param coords? vector3
---@return number|nil closestPed
---@return number closestDist
function SLX.Game.GetClosestPed(coords)
    if not coords then coords = GetEntityCoords(PlayerPedId()) end
    local closestPed = nil
    local closestDist = math.huge
    local playerPed = PlayerPedId()
    local handle, ped = FindFirstPed()
    local success = true
    while success do
        if DoesEntityExist(ped) and ped ~= playerPed and not IsPedAPlayer(ped) then
            local dist = #(coords - GetEntityCoords(ped))
            if dist < closestDist then
                closestDist = dist
                closestPed = ped
            end
        end
        success, ped = FindNextPed(handle)
    end
    EndFindPed(handle)
    return closestPed, closestDist
end

---@param coords vector3
---@param radius number
---@return table
function SLX.Game.GetPlayersInArea(coords, radius)
    local players = {}
    local localPlayer = PlayerId()
    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= localPlayer then
            local pedCoords = GetEntityCoords(GetPlayerPed(playerId))
            if #(coords - pedCoords) <= radius then
                players[#players + 1] = playerId
            end
        end
    end
    return players
end

---@param coords? vector3
---@return number|nil closestObject
---@return number closestDist
function SLX.Game.GetClosestObject(coords)
    if not coords then coords = GetEntityCoords(PlayerPedId()) end
    local closestObj = nil
    local closestDist = math.huge
    local handle, obj = FindFirstObject()
    local success = true
    while success do
        if DoesEntityExist(obj) then
            local dist = #(coords - GetEntityCoords(obj))
            if dist < closestDist then
                closestDist = dist
                closestObj = obj
            end
        end
        success, obj = FindNextObject(handle)
    end
    EndFindObject(handle)
    return closestObj, closestDist
end

---@return table
function SLX.Game.GetObjects()
    local objects = {}
    local handle, obj = FindFirstObject()
    local success = true
    while success do
        if DoesEntityExist(obj) then
            objects[#objects + 1] = obj
        end
        success, obj = FindNextObject(handle)
    end
    EndFindObject(handle)
    return objects
end

---@return table
function SLX.Game.GetPeds()
    local peds = {}
    local playerPed = PlayerPedId()
    local handle, ped = FindFirstPed()
    local success = true
    while success do
        if DoesEntityExist(ped) and ped ~= playerPed then
            peds[#peds + 1] = ped
        end
        success, ped = FindNextPed(handle)
    end
    EndFindPed(handle)
    return peds
end

---@param modelName string|number
---@param coords vector3
---@param heading number
---@param cb? fun(obj: number|nil)
---@param networked? boolean
function SLX.Game.SpawnObject(modelName, coords, heading, cb, networked)
    if networked == nil then networked = true end
    local modelHash = type(modelName) == 'string' and GetHashKey(modelName) or modelName
    RequestModel(modelHash)
    CreateThread(function()
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        if not HasModelLoaded(modelHash) then
            SLX.Log('ERROR', 'SpawnObject: failed to load model after 5s')
            if cb then cb(nil) end
            return
        end
        local obj = CreateObject(modelHash, coords.x, coords.y, coords.z, networked, false, false)
        SetEntityHeading(obj, heading)
        SetModelAsNoLongerNeeded(modelHash)
        if cb then cb(obj) end
    end)
end

---@param modelName string|number
---@param coords vector3
---@param heading number
---@param cb? fun(obj: number|nil)
function SLX.Game.SpawnLocalObject(modelName, coords, heading, cb)
    SLX.Game.SpawnObject(modelName, coords, heading, cb, false)
end

---@param obj number
function SLX.Game.DeleteObject(obj)
    if not DoesEntityExist(obj) then return end
    SetEntityAsMissionEntity(obj, true, true)
    DeleteObject(obj)
end

---@param entity number
---@param coords vector3
---@param cb? function
function SLX.Game.Teleport(entity, coords, cb)
    CreateThread(function()
        RequestCollisionAtCoord(coords.x, coords.y, coords.z)
        local timeout = 0
        while not HasCollisionLoadedAroundEntity(entity) and timeout < 3000 do
            Wait(50)
            timeout = timeout + 50
        end
        SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
        if coords.heading then SetEntityHeading(entity, coords.heading) end
        if cb then cb() end
    end)
end

local WeaponLabels = {
    ['WEAPON_KNIFE'] = 'Messer', ['WEAPON_NIGHTSTICK'] = 'Schlagstock', ['WEAPON_HAMMER'] = 'Hammer',
    ['WEAPON_BAT'] = 'Baseballschläger', ['WEAPON_CROWBAR'] = 'Brecheisen', ['WEAPON_GOLFCLUB'] = 'Golfschläger',
    ['WEAPON_BOTTLE'] = 'Flasche', ['WEAPON_DAGGER'] = 'Dolch', ['WEAPON_HATCHET'] = 'Beil',
    ['WEAPON_KNUCKLE'] = 'Schlagring', ['WEAPON_MACHETE'] = 'Machete', ['WEAPON_SWITCHBLADE'] = 'Klappmesser',
    ['WEAPON_BATTLEAXE'] = 'Streitaxt', ['WEAPON_STONE_HATCHET'] = 'Steinbeil',
    ['WEAPON_PISTOL'] = 'Pistole', ['WEAPON_PISTOL_MK2'] = 'Pistole Mk II', ['WEAPON_COMBATPISTOL'] = 'Kampfpistole',
    ['WEAPON_APPISTOL'] = 'AP-Pistole', ['WEAPON_STUNGUN'] = 'Taser', ['WEAPON_PISTOL50'] = 'Pistole .50',
    ['WEAPON_SNSPISTOL'] = 'SNS-Pistole', ['WEAPON_SNSPISTOL_MK2'] = 'SNS-Pistole Mk II',
    ['WEAPON_HEAVYPISTOL'] = 'Schwere Pistole', ['WEAPON_VINTAGEPISTOL'] = 'Vintage-Pistole',
    ['WEAPON_FLAREGUN'] = 'Leuchtpistole', ['WEAPON_MARKSMANPISTOL'] = 'Marksman-Pistole',
    ['WEAPON_REVOLVER'] = 'Revolver', ['WEAPON_REVOLVER_MK2'] = 'Revolver Mk II',
    ['WEAPON_DOUBLEACTION'] = 'Double-Action', ['WEAPON_RAYPISTOL'] = 'Up-n-Atomizer',
    ['WEAPON_CERAMICPISTOL'] = 'Keramikpistole', ['WEAPON_NAVYREVOLVER'] = 'Navy-Revolver',
    ['WEAPON_GADGETPISTOL'] = 'Perico-Pistole',
    ['WEAPON_MICROSMG'] = 'Micro-SMG', ['WEAPON_SMG'] = 'SMG', ['WEAPON_SMG_MK2'] = 'SMG Mk II',
    ['WEAPON_ASSAULTSMG'] = 'Sturm-SMG', ['WEAPON_COMBATPDW'] = 'Kampf-PDW',
    ['WEAPON_MACHINEPISTOL'] = 'Maschinenpistole', ['WEAPON_MINISMG'] = 'Mini-SMG',
    ['WEAPON_RAYCARBINE'] = 'Unholy Hellbringer',
    ['WEAPON_PUMPSHOTGUN'] = 'Pump-Shotgun', ['WEAPON_PUMPSHOTGUN_MK2'] = 'Pump-Shotgun Mk II',
    ['WEAPON_SAWNOFFSHOTGUN'] = 'Abgesägte Schrotflinte', ['WEAPON_ASSAULTSHOTGUN'] = 'Sturm-Schrotflinte',
    ['WEAPON_BULLPUPSHOTGUN'] = 'Bullpup-Shotgun', ['WEAPON_MUSKET'] = 'Muskete',
    ['WEAPON_HEAVYSHOTGUN'] = 'Schwere Schrotflinte', ['WEAPON_DBSHOTGUN'] = 'Doppelläufige Schrotflinte',
    ['WEAPON_AUTOSHOTGUN'] = 'Automatische Schrotflinte', ['WEAPON_COMBATSHOTGUN'] = 'Kampf-Schrotflinte',
    ['WEAPON_ASSAULTRIFLE'] = 'Sturmgewehr', ['WEAPON_ASSAULTRIFLE_MK2'] = 'Sturmgewehr Mk II',
    ['WEAPON_CARBINERIFLE'] = 'Karabiner', ['WEAPON_CARBINERIFLE_MK2'] = 'Karabiner Mk II',
    ['WEAPON_ADVANCEDRIFLE'] = 'Spezialgewehr', ['WEAPON_SPECIALCARBINE'] = 'Spezialkarabiner',
    ['WEAPON_SPECIALCARBINE_MK2'] = 'Spezialkarabiner Mk II', ['WEAPON_BULLPUPRIFLE'] = 'Bullpup-Gewehr',
    ['WEAPON_BULLPUPRIFLE_MK2'] = 'Bullpup-Gewehr Mk II', ['WEAPON_COMPACTRIFLE'] = 'Kompaktgewehr',
    ['WEAPON_MILITARYRIFLE'] = 'Militärgewehr', ['WEAPON_HEAVYRIFLE'] = 'Schweres Gewehr',
    ['WEAPON_TACTICALRIFLE'] = 'Taktisches Gewehr',
    ['WEAPON_MG'] = 'MG', ['WEAPON_COMBATMG'] = 'Kampf-MG', ['WEAPON_COMBATMG_MK2'] = 'Kampf-MG Mk II',
    ['WEAPON_GUSENBERG'] = 'Gusenberg',
    ['WEAPON_SNIPERRIFLE'] = 'Scharfschützengewehr', ['WEAPON_HEAVYSNIPER'] = 'Schweres Scharfschützengewehr',
    ['WEAPON_HEAVYSNIPER_MK2'] = 'Schweres Scharfschützengewehr Mk II', ['WEAPON_MARKSMANRIFLE'] = 'Marksman-Gewehr',
    ['WEAPON_MARKSMANRIFLE_MK2'] = 'Marksman-Gewehr Mk II',
    ['WEAPON_RPG'] = 'RPG', ['WEAPON_GRENADELAUNCHER'] = 'Granatwerfer',
    ['WEAPON_MINIGUN'] = 'Minigun', ['WEAPON_FIREWORK'] = 'Feuerwerkswerfer',
    ['WEAPON_RAILGUN'] = 'Railgun', ['WEAPON_HOMINGLAUNCHER'] = 'Zielsuchender Raketenwerfer',
    ['WEAPON_COMPACTLAUNCHER'] = 'Kompakt-Granatwerfer', ['WEAPON_RAYMINIGUN'] = 'Widowmaker',
    ['WEAPON_GRENADE'] = 'Granate', ['WEAPON_BZGAS'] = 'Tränengas', ['WEAPON_MOLOTOV'] = 'Molotov',
    ['WEAPON_STICKYBOMB'] = 'Haftbombe', ['WEAPON_PROXMINE'] = 'Annäherungsmine',
    ['WEAPON_SNOWBALL'] = 'Schneeball', ['WEAPON_PIPEBOMB'] = 'Rohrbombe',
    ['WEAPON_BALL'] = 'Ball', ['WEAPON_SMOKEGRENADE'] = 'Rauchgranate', ['WEAPON_FLARE'] = 'Leuchtrakete',
    ['WEAPON_PETROLCAN'] = 'Benzinkanister', ['WEAPON_FIREEXTINGUISHER'] = 'Feuerlöscher',
    ['WEAPON_PARACHUTE'] = 'Fallschirm', ['WEAPON_UNARMED'] = 'Unbewaffnet',
}

---@param weaponName string
---@return string
function SLX.GetWeaponLabel(weaponName)
    local upper = string.upper(weaponName)
    if not string.find(upper, 'WEAPON_') then upper = 'WEAPON_' .. upper end
    return WeaponLabels[upper] or upper
end

---@return table
function SLX.GetWeaponList()
    local list = {}
    for name, label in pairs(WeaponLabels) do
        list[#list + 1] = { name = name, label = label }
    end
    return list
end

local isCrouching = false
local crouchClipset = 'move_ped_crouched'
local handsUpDict = 'random@mugging3'
local radioDict = 'random@arrests'

CreateThread(function()
    RequestAnimSet(crouchClipset)
    RequestAnimDict(handsUpDict)
    RequestAnimDict(radioDict)
    while not HasAnimSetLoaded(crouchClipset) do Wait(10) end
    while not HasAnimDictLoaded(handsUpDict) do Wait(10) end
    while not HasAnimDictLoaded(radioDict) do Wait(10) end
    SLX.Debug('All animation dicts pre-loaded')
end)

---@param toggle boolean
local function SetCrouch(toggle)
    local ped = PlayerPedId()
    if toggle then
        SetPedMovementClipset(ped, crouchClipset, 0.25)
        isCrouching = true
    else
        ResetPedMovementClipset(ped, 0.25)
        isCrouching = false
    end
end

RegisterCommand('crouch', function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
    SetCrouch(not isCrouching)
end, false)
RegisterKeyMapping('crouch', 'Crouch', 'keyboard', 'q')

CreateThread(function()
    while true do
        if isCrouching then
            local ped = PlayerPedId()
            if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) or IsPedRagdoll(ped) then
                SetCrouch(false)
            end
            if IsPedReloading(ped) then
                ResetPedMovementClipset(ped, 0.0)
                while IsPedReloading(ped) do Wait(100) end
                if isCrouching then
                    SetPedMovementClipset(PlayerPedId(), crouchClipset, 0.0)
                end
            end
            Wait(200)
        else
            Wait(500)
        end
    end
end)

local handsUp = false

RegisterCommand('handsup', function()
    if not SLX.Config.EnableHandsUp then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    if handsUp then
        ClearPedTasks(ped)
        handsUp = false
    else
        TaskPlayAnim(ped, handsUpDict, 'handsup_standing_base', 8.0, 8.0, -1, 49, 0, false, false, false)
        handsUp = true
    end
end, false)
RegisterKeyMapping('handsup', 'Hands Up', 'keyboard', 'h')

CreateThread(function()
    while true do
        if handsUp then
            local ped = PlayerPedId()
            if IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                handsUp = false
            end
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

local isRadio = false

RegisterCommand('+radio', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    TaskPlayAnim(ped, radioDict, 'generic_radio_enter', 100.0, 8.0, -1, 49, 0, false, false, false)
    isRadio = true
end, false)

RegisterCommand('-radio', function()
    if isRadio then
        ClearPedTasks(PlayerPedId())
        isRadio = false
    end
end, false)
RegisterKeyMapping('+radio', 'Radio', 'keyboard', 'lmenu')

CreateThread(function()
    while true do
        if isRadio then
            local ped = PlayerPedId()
            if IsPedShooting(ped) or IsEntityDead(ped) or IsPedInAnyVehicle(ped, false) then
                ClearPedTasks(ped)
                isRadio = false
            end
            Wait(100)
        else
            Wait(500)
        end
    end
end)

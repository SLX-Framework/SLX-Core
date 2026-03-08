local _menuPool = NativeUI.CreatePool()
local skinMenuOpen = false
local currentSkin = nil
local skinCamHeading = 0.0
local skinCamActive = false

local defaultSkin = {
    model = 'mp_m_freemode_01',
    face = 0,
    skin_color = 0,
    hair = 0,
    hair_color = 0,
    hair_highlight = 0,
    beard = -1,
    beard_color = 0,
    eyebrow = -1,
    eyebrow_color = 0,
    eye_color = 0,
    blush = -1,
    blush_color = 0,
    lipstick = -1,
    lipstick_color = 0,
    age = -1,
    makeup = -1,
    makeup_color = 0,
    tshirt = 0,
    tshirt_texture = 0,
    torso = 0,
    torso_texture = 0,
    decals = 0,
    decals_texture = 0,
    arms = 0,
    arms_texture = 0,
    pants = 0,
    pants_texture = 0,
    shoes = 0,
    shoes_texture = 0,
    mask = 0,
    mask_texture = 0,
    bag = 0,
    bag_texture = 0,
    hat = -1,
    hat_texture = 0,
    glass = -1,
    glass_texture = 0,
    ear = -1,
    ear_texture = 0,
    watch = -1,
    watch_texture = 0,
    bracelet = -1,
    bracelet_texture = 0,
}

---@param ped number
---@param skin table
local function ApplySkinToPed(ped, skin)
    if not skin then return end

    local modelHash = GetHashKey(skin.model or 'mp_m_freemode_01')
    local currentModel = GetEntityModel(ped)

    if currentModel ~= modelHash then
        RequestModel(modelHash)
        local timeout = 0
        while not HasModelLoaded(modelHash) and timeout < 5000 do
            Wait(10)
            timeout = timeout + 10
        end
        if HasModelLoaded(modelHash) then
            SetPlayerModel(PlayerId(), modelHash)
            SetModelAsNoLongerNeeded(modelHash)
            ped = PlayerPedId()
        end
    end

    SetPedDefaultComponentVariation(ped)

    SetPedHeadBlendData(ped, skin.face or 0, skin.face or 0, 0, skin.skin_color or 0, skin.skin_color or 0, 0, 0.5, 0.5, 0.0, false)

    SetPedComponentVariation(ped, 2, skin.hair or 0, 0, 0)
    SetPedHairColor(ped, skin.hair_color or 0, skin.hair_highlight or 0)

    local beardVal = (skin.beard and skin.beard >= 0) and skin.beard or 255
    SetPedHeadOverlay(ped, 1, beardVal, 1.0)
    if beardVal ~= 255 then SetPedHeadOverlayColor(ped, 1, 1, skin.beard_color or 0, skin.beard_color or 0) end

    local browVal = (skin.eyebrow and skin.eyebrow >= 0) and skin.eyebrow or 255
    SetPedHeadOverlay(ped, 2, browVal, 1.0)
    if browVal ~= 255 then SetPedHeadOverlayColor(ped, 2, 1, skin.eyebrow_color or 0, skin.eyebrow_color or 0) end

    SetPedEyeColor(ped, skin.eye_color or 0)

    local blushVal = (skin.blush and skin.blush >= 0) and skin.blush or 255
    SetPedHeadOverlay(ped, 5, blushVal, 1.0)
    if blushVal ~= 255 then SetPedHeadOverlayColor(ped, 5, 2, skin.blush_color or 0, skin.blush_color or 0) end

    local lipVal = (skin.lipstick and skin.lipstick >= 0) and skin.lipstick or 255
    SetPedHeadOverlay(ped, 8, lipVal, 1.0)
    if lipVal ~= 255 then SetPedHeadOverlayColor(ped, 8, 2, skin.lipstick_color or 0, skin.lipstick_color or 0) end

    local ageVal = (skin.age and skin.age >= 0) and skin.age or 255
    SetPedHeadOverlay(ped, 3, ageVal, 1.0)

    local makeupVal = (skin.makeup and skin.makeup >= 0) and skin.makeup or 255
    SetPedHeadOverlay(ped, 4, makeupVal, 1.0)
    if makeupVal ~= 255 then SetPedHeadOverlayColor(ped, 4, 2, skin.makeup_color or 0, skin.makeup_color or 0) end

    SetPedComponentVariation(ped, 8, skin.tshirt or 0, skin.tshirt_texture or 0, 0)
    SetPedComponentVariation(ped, 11, skin.torso or 0, skin.torso_texture or 0, 0)
    SetPedComponentVariation(ped, 10, skin.decals or 0, skin.decals_texture or 0, 0)
    SetPedComponentVariation(ped, 3, skin.arms or 0, skin.arms_texture or 0, 0)
    SetPedComponentVariation(ped, 4, skin.pants or 0, skin.pants_texture or 0, 0)
    SetPedComponentVariation(ped, 6, skin.shoes or 0, skin.shoes_texture or 0, 0)
    SetPedComponentVariation(ped, 1, skin.mask or 0, skin.mask_texture or 0, 0)
    SetPedComponentVariation(ped, 5, skin.bag or 0, skin.bag_texture or 0, 0)

    if skin.hat and skin.hat >= 0 then
        SetPedPropIndex(ped, 0, skin.hat, skin.hat_texture or 0, true)
    else
        ClearPedProp(ped, 0)
    end
    if skin.glass and skin.glass >= 0 then
        SetPedPropIndex(ped, 1, skin.glass, skin.glass_texture or 0, true)
    else
        ClearPedProp(ped, 1)
    end
    if skin.ear and skin.ear >= 0 then
        SetPedPropIndex(ped, 2, skin.ear, skin.ear_texture or 0, true)
    else
        ClearPedProp(ped, 2)
    end
    if skin.watch and skin.watch >= 0 then
        SetPedPropIndex(ped, 6, skin.watch, skin.watch_texture or 0, true)
    else
        ClearPedProp(ped, 6)
    end
    if skin.bracelet and skin.bracelet >= 0 then
        SetPedPropIndex(ped, 7, skin.bracelet, skin.bracelet_texture or 0, true)
    else
        ClearPedProp(ped, 7)
    end

    SLX.Debug(('ApplySkinToPed: model=%s hair=%d face=%d torso=%d pants=%d shoes=%d hat=%d glass=%d'):format(
        skin.model or 'unknown',
        skin.hair or 0,
        skin.face or 0,
        skin.torso or 0,
        skin.pants or 0,
        skin.shoes or 0,
        skin.hat or -1,
        skin.glass or -1
    ))
end

SLX.ApplySkinToPed = ApplySkinToPed

---@param ped number
---@return table
local function GetCurrentSkinFromPed(ped)
    local skin = {}
    for k, v in pairs(defaultSkin) do
        skin[k] = v
    end

    local model = GetEntityModel(ped)
    if model == GetHashKey('mp_m_freemode_01') then
        skin.model = 'mp_m_freemode_01'
    elseif model == GetHashKey('mp_f_freemode_01') then
        skin.model = 'mp_f_freemode_01'
    end

    skin.hair = GetPedDrawableVariation(ped, 2)
    skin.hair_color = GetPedHairColor(ped)
    skin.hair_highlight = GetPedHairHighlightColor(ped)
    skin.tshirt = GetPedDrawableVariation(ped, 8)
    skin.tshirt_texture = GetPedTextureVariation(ped, 8)
    skin.torso = GetPedDrawableVariation(ped, 11)
    skin.torso_texture = GetPedTextureVariation(ped, 11)
    skin.decals = GetPedDrawableVariation(ped, 10)
    skin.decals_texture = GetPedTextureVariation(ped, 10)
    skin.arms = GetPedDrawableVariation(ped, 3)
    skin.arms_texture = GetPedTextureVariation(ped, 3)
    skin.pants = GetPedDrawableVariation(ped, 4)
    skin.pants_texture = GetPedTextureVariation(ped, 4)
    skin.shoes = GetPedDrawableVariation(ped, 6)
    skin.shoes_texture = GetPedTextureVariation(ped, 6)
    skin.mask = GetPedDrawableVariation(ped, 1)
    skin.mask_texture = GetPedTextureVariation(ped, 1)
    skin.bag = GetPedDrawableVariation(ped, 5)
    skin.bag_texture = GetPedTextureVariation(ped, 5)
    skin.hat = GetPedPropIndex(ped, 0)
    skin.hat_texture = GetPedPropTextureIndex(ped, 0)
    skin.glass = GetPedPropIndex(ped, 1)
    skin.glass_texture = GetPedPropTextureIndex(ped, 1)
    skin.ear = GetPedPropIndex(ped, 2)
    skin.ear_texture = GetPedPropTextureIndex(ped, 2)
    skin.watch = GetPedPropIndex(ped, 6)
    skin.watch_texture = GetPedPropTextureIndex(ped, 6)
    skin.bracelet = GetPedPropIndex(ped, 7)
    skin.bracelet_texture = GetPedPropTextureIndex(ped, 7)
    skin.eye_color = GetPedEyeColor(ped)

    local beardRaw = GetPedHeadOverlayValue(ped, 1)
    skin.beard = (beardRaw == 255 or beardRaw < 0) and -1 or beardRaw
    local browRaw = GetPedHeadOverlayValue(ped, 2)
    skin.eyebrow = (browRaw == 255 or browRaw < 0) and -1 or browRaw
    local ageRaw = GetPedHeadOverlayValue(ped, 3)
    skin.age = (ageRaw == 255 or ageRaw < 0) and -1 or ageRaw
    local makeupRaw = GetPedHeadOverlayValue(ped, 4)
    skin.makeup = (makeupRaw == 255 or makeupRaw < 0) and -1 or makeupRaw
    local blushRaw = GetPedHeadOverlayValue(ped, 5)
    skin.blush = (blushRaw == 255 or blushRaw < 0) and -1 or blushRaw
    local lipRaw = GetPedHeadOverlayValue(ped, 8)
    skin.lipstick = (lipRaw == 255 or lipRaw < 0) and -1 or lipRaw

    return skin
end

local skinCam = nil

local function CreateSkinCamera()
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    skinCamHeading = GetEntityHeading(ped)
    local rad = math.rad(skinCamHeading)
    local camX = pedCoords.x + math.sin(-rad) * 1.8
    local camY = pedCoords.y + math.cos(-rad) * 1.8
    local camZ = pedCoords.z + 0.3
    skinCam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(skinCam, camX, camY, camZ)
    PointCamAtEntity(skinCam, ped, 0.0, 0.0, 0.0, true)
    SetCamActive(skinCam, true)
    RenderScriptCams(true, true, 500, true, false)
    skinCamActive = true
    FreezeEntityPosition(ped, true)
    SLX.Debug('Skin camera created')
end

local function DestroySkinCamera()
    if skinCam then
        RenderScriptCams(false, true, 500, true, false)
        DestroyCam(skinCam, false)
        skinCam = nil
    end
    skinCamActive = false
    FreezeEntityPosition(PlayerPedId(), false)
    SLX.Debug('Skin camera destroyed')
end

local function UpdateSkinCamera()
    if not skinCam or not skinCamActive then return end
    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local rad = math.rad(skinCamHeading)
    local camX = pedCoords.x + math.sin(-rad) * 1.8
    local camY = pedCoords.y + math.cos(-rad) * 1.8
    local camZ = pedCoords.z + 0.3
    SetCamCoord(skinCam, camX, camY, camZ)
    PointCamAtEntity(skinCam, ped, 0.0, 0.0, 0.0, true)
end

---@param n number
---@param max number
---@return table
local function BuildNumberList(n, max)
    local items = {}
    for i = 0, max do
        items[i + 1] = tostring(i)
    end
    return items
end

---@param max number
---@return table
local function BuildOverlayList(max)
    local items = { 'Kein' }
    for i = 0, max do
        items[#items + 1] = tostring(i)
    end
    return items
end

local function OpenSkinMenu()
    if skinMenuOpen then return end
    skinMenuOpen = true
    local ped = PlayerPedId()
    currentSkin = GetCurrentSkinFromPed(ped)

    CreateSkinCamera()

    _menuPool:Clear()
    local mainMenu = NativeUI.CreateMenu('Skin Editor', 'Charakter anpassen | A/D = Drehen')
    _menuPool:Add(mainMenu)

    local modelItems = { 'Männlich', 'Weiblich' }
    local modelIdx = currentSkin.model == 'mp_f_freemode_01' and 2 or 1
    local modelList = NativeUI.CreateListItem('Geschlecht', modelItems, modelIdx, 'Wähle dein Geschlecht')
    mainMenu:AddItem(modelList)

    local faceMenu = NativeUI.CreateMenu('Gesicht', 'Gesicht bearbeiten | A/D = Drehen')
    _menuPool:Add(faceMenu)
    local faceBtn = NativeUI.CreateItem('Gesicht', 'Gesicht, Augen, Bart, Augenbrauen...')
    mainMenu:AddItem(faceBtn)
    mainMenu:BindMenuToItem(faceMenu, faceBtn)

    local faceList = NativeUI.CreateListItem('Gesichtsform', BuildNumberList(0, 45), (currentSkin.face or 0) + 1, 'Gesichtsform')
    faceMenu:AddItem(faceList)

    local skinColorList = NativeUI.CreateListItem('Hautfarbe', BuildNumberList(0, 45), (currentSkin.skin_color or 0) + 1, 'Hautfarbe')
    faceMenu:AddItem(skinColorList)

    local eyeList = NativeUI.CreateListItem('Augenfarbe', BuildNumberList(0, 31), (currentSkin.eye_color or 0) + 1, 'Augenfarbe')
    faceMenu:AddItem(eyeList)

    local beardMax = GetPedHeadOverlayNum(1) - 1
    local beardIdx = (currentSkin.beard or -1) + 2; if beardIdx < 1 then beardIdx = 1 end
    local beardList = NativeUI.CreateListItem('Bart', BuildOverlayList(beardMax), beardIdx, 'Bart')
    faceMenu:AddItem(beardList)

    local beardColorList = NativeUI.CreateListItem('Bart Farbe', BuildNumberList(0, 63), (currentSkin.beard_color or 0) + 1, 'Bart Farbe')
    faceMenu:AddItem(beardColorList)

    local browMax = GetPedHeadOverlayNum(2) - 1
    local browIdx = (currentSkin.eyebrow or -1) + 2; if browIdx < 1 then browIdx = 1 end
    local browList = NativeUI.CreateListItem('Augenbrauen', BuildOverlayList(browMax), browIdx, 'Augenbrauen')
    faceMenu:AddItem(browList)

    local browColorList = NativeUI.CreateListItem('Augenbrauen Farbe', BuildNumberList(0, 63), (currentSkin.eyebrow_color or 0) + 1, 'Farbe')
    faceMenu:AddItem(browColorList)

    local ageMax = GetPedHeadOverlayNum(3) - 1
    local ageIdx = (currentSkin.age or -1) + 2; if ageIdx < 1 then ageIdx = 1 end
    local ageList = NativeUI.CreateListItem('Alterung', BuildOverlayList(ageMax), ageIdx, 'Alterung')
    faceMenu:AddItem(ageList)

    local makeupMax = GetPedHeadOverlayNum(4) - 1
    local makeupIdx = (currentSkin.makeup or -1) + 2; if makeupIdx < 1 then makeupIdx = 1 end
    local makeupList = NativeUI.CreateListItem('Makeup', BuildOverlayList(makeupMax), makeupIdx, 'Makeup')
    faceMenu:AddItem(makeupList)

    local makeupColorList = NativeUI.CreateListItem('Makeup Farbe', BuildNumberList(0, 63), (currentSkin.makeup_color or 0) + 1, 'Farbe')
    faceMenu:AddItem(makeupColorList)

    local blushMax = GetPedHeadOverlayNum(5) - 1
    local blushIdx = (currentSkin.blush or -1) + 2; if blushIdx < 1 then blushIdx = 1 end
    local blushList = NativeUI.CreateListItem('Rouge', BuildOverlayList(blushMax), blushIdx, 'Rouge')
    faceMenu:AddItem(blushList)

    local blushColorList = NativeUI.CreateListItem('Rouge Farbe', BuildNumberList(0, 63), (currentSkin.blush_color or 0) + 1, 'Farbe')
    faceMenu:AddItem(blushColorList)

    local lipMax = GetPedHeadOverlayNum(8) - 1
    local lipIdx = (currentSkin.lipstick or -1) + 2; if lipIdx < 1 then lipIdx = 1 end
    local lipList = NativeUI.CreateListItem('Lippenstift', BuildOverlayList(lipMax), lipIdx, 'Lippenstift')
    faceMenu:AddItem(lipList)

    local lipColorList = NativeUI.CreateListItem('Lippenstift Farbe', BuildNumberList(0, 63), (currentSkin.lipstick_color or 0) + 1, 'Farbe')
    faceMenu:AddItem(lipColorList)

    faceMenu.OnListChange = function(sender, item, index)
        local key = 'unknown'
        local val = 0
        if item == faceList then val = index - 1; currentSkin.face = val; key = 'face'
        elseif item == skinColorList then val = index - 1; currentSkin.skin_color = val; key = 'skin_color'
        elseif item == eyeList then val = index - 1; currentSkin.eye_color = val; key = 'eye_color'
        elseif item == beardList then val = index - 2; if val < -1 then val = -1 end; currentSkin.beard = val; key = 'beard'
        elseif item == beardColorList then val = index - 1; currentSkin.beard_color = val; key = 'beard_color'
        elseif item == browList then val = index - 2; if val < -1 then val = -1 end; currentSkin.eyebrow = val; key = 'eyebrow'
        elseif item == browColorList then val = index - 1; currentSkin.eyebrow_color = val; key = 'eyebrow_color'
        elseif item == ageList then val = index - 2; if val < -1 then val = -1 end; currentSkin.age = val; key = 'age'
        elseif item == makeupList then val = index - 2; if val < -1 then val = -1 end; currentSkin.makeup = val; key = 'makeup'
        elseif item == makeupColorList then val = index - 1; currentSkin.makeup_color = val; key = 'makeup_color'
        elseif item == blushList then val = index - 2; if val < -1 then val = -1 end; currentSkin.blush = val; key = 'blush'
        elseif item == blushColorList then val = index - 1; currentSkin.blush_color = val; key = 'blush_color'
        elseif item == lipList then val = index - 2; if val < -1 then val = -1 end; currentSkin.lipstick = val; key = 'lipstick'
        elseif item == lipColorList then val = index - 1; currentSkin.lipstick_color = val; key = 'lipstick_color'
        end
        SLX.Debug(('[Skin] Face changed: %s = %d (NativeUI index=%d)'):format(key, val, index))
        ApplySkinToPed(PlayerPedId(), currentSkin)
    end

    local hairMenu = NativeUI.CreateMenu('Haare', 'Haare bearbeiten | A/D = Drehen')
    _menuPool:Add(hairMenu)
    local hairBtn = NativeUI.CreateItem('Haare', 'Frisur und Farbe')
    mainMenu:AddItem(hairBtn)
    mainMenu:BindMenuToItem(hairMenu, hairBtn)

    local hairMax = GetNumberOfPedDrawableVariations(ped, 2) - 1
    local hairList = NativeUI.CreateListItem('Frisur', BuildNumberList(0, hairMax), (currentSkin.hair or 0) + 1, 'Frisur')
    hairMenu:AddItem(hairList)

    local hairColorList = NativeUI.CreateListItem('Haarfarbe', BuildNumberList(0, 63), (currentSkin.hair_color or 0) + 1, 'Haarfarbe')
    hairMenu:AddItem(hairColorList)

    local hairHighList = NativeUI.CreateListItem('Strähnchen', BuildNumberList(0, 63), (currentSkin.hair_highlight or 0) + 1, 'Strähnchen')
    hairMenu:AddItem(hairHighList)

    hairMenu.OnListChange = function(sender, item, index)
        local key = 'unknown'
        if item == hairList then currentSkin.hair = index - 1; key = 'hair'
        elseif item == hairColorList then currentSkin.hair_color = index - 1; key = 'hair_color'
        elseif item == hairHighList then currentSkin.hair_highlight = index - 1; key = 'hair_highlight'
        end
        SLX.Debug(('[Skin] Hair changed: %s = %d (NativeUI index=%d)'):format(key, index - 1, index))
        ApplySkinToPed(PlayerPedId(), currentSkin)
    end

    local clothMenu = NativeUI.CreateMenu('Kleidung', 'Kleidung bearbeiten | A/D = Drehen')
    _menuPool:Add(clothMenu)
    local clothBtn = NativeUI.CreateItem('Kleidung', 'Oberteil, Hose, Schuhe...')
    mainMenu:AddItem(clothBtn)
    mainMenu:BindMenuToItem(clothMenu, clothBtn)

    local clothComponents = {
        { label = 'Unterhemd', key = 'tshirt', texKey = 'tshirt_texture', compId = 8 },
        { label = 'Oberteil', key = 'torso', texKey = 'torso_texture', compId = 11 },
        { label = 'Arme', key = 'arms', texKey = 'arms_texture', compId = 3 },
        { label = 'Hose', key = 'pants', texKey = 'pants_texture', compId = 4 },
        { label = 'Schuhe', key = 'shoes', texKey = 'shoes_texture', compId = 6 },
        { label = 'Maske', key = 'mask', texKey = 'mask_texture', compId = 1 },
        { label = 'Tasche', key = 'bag', texKey = 'bag_texture', compId = 5 },
        { label = 'Decals', key = 'decals', texKey = 'decals_texture', compId = 10 },
    }

    local clothListItems = {}
    for _, comp in ipairs(clothComponents) do
        local maxDraw = GetNumberOfPedDrawableVariations(ped, comp.compId) - 1
        if maxDraw < 0 then maxDraw = 0 end
        local drawL = NativeUI.CreateListItem(comp.label, BuildNumberList(0, maxDraw), (currentSkin[comp.key] or 0) + 1, comp.label)
        clothMenu:AddItem(drawL)

        local maxTex = GetNumberOfPedTextureVariations(ped, comp.compId, currentSkin[comp.key] or 0) - 1
        if maxTex < 0 then maxTex = 0 end
        local texL = NativeUI.CreateListItem(comp.label .. ' Textur', BuildNumberList(0, maxTex), (currentSkin[comp.texKey] or 0) + 1, comp.label .. ' Textur')
        clothMenu:AddItem(texL)

        clothListItems[#clothListItems + 1] = { drawList = drawL, texList = texL, key = comp.key, texKey = comp.texKey, compId = comp.compId }
    end

    clothMenu.OnListChange = function(sender, item, index)
        for _, entry in ipairs(clothListItems) do
            if item == entry.drawList then
                currentSkin[entry.key] = index - 1
                SLX.Debug(('[Skin] Cloth changed: %s = %d (NativeUI index=%d)'):format(entry.key, index - 1, index))
                ApplySkinToPed(PlayerPedId(), currentSkin)
                return
            elseif item == entry.texList then
                currentSkin[entry.texKey] = index - 1
                SLX.Debug(('[Skin] Cloth tex changed: %s = %d (NativeUI index=%d)'):format(entry.texKey, index - 1, index))
                ApplySkinToPed(PlayerPedId(), currentSkin)
                return
            end
        end
    end

    local accMenu = NativeUI.CreateMenu('Accessoires', 'Accessoires bearbeiten | A/D = Drehen')
    _menuPool:Add(accMenu)
    local accBtn = NativeUI.CreateItem('Accessoires', 'Hut, Brille, Ohrringe...')
    mainMenu:AddItem(accBtn)
    mainMenu:BindMenuToItem(accMenu, accBtn)

    local accProps = {
        { label = 'Hut', key = 'hat', texKey = 'hat_texture', propId = 0 },
        { label = 'Brille', key = 'glass', texKey = 'glass_texture', propId = 1 },
        { label = 'Ohrringe', key = 'ear', texKey = 'ear_texture', propId = 2 },
        { label = 'Uhr', key = 'watch', texKey = 'watch_texture', propId = 6 },
        { label = 'Armband', key = 'bracelet', texKey = 'bracelet_texture', propId = 7 },
    }

    local accListItems = {}
    for _, prop in ipairs(accProps) do
        local maxP = GetNumberOfPedPropDrawableVariations(ped, prop.propId)
        local propItems = { 'Kein' }
        for i = 0, maxP - 1 do propItems[#propItems + 1] = tostring(i) end
        local startI = (currentSkin[prop.key] or -1) + 2
        if startI < 1 then startI = 1 end
        local propL = NativeUI.CreateListItem(prop.label, propItems, startI, prop.label)
        accMenu:AddItem(propL)

        local maxPT = 0
        if currentSkin[prop.key] and currentSkin[prop.key] >= 0 then
            maxPT = GetNumberOfPedPropTextureVariations(ped, prop.propId, currentSkin[prop.key]) - 1
            if maxPT < 0 then maxPT = 0 end
        end
        local texL = NativeUI.CreateListItem(prop.label .. ' Textur', BuildNumberList(0, math.max(maxPT, 0)), (currentSkin[prop.texKey] or 0) + 1, prop.label .. ' Textur')
        accMenu:AddItem(texL)

        accListItems[#accListItems + 1] = { propList = propL, texList = texL, key = prop.key, texKey = prop.texKey }
    end

    accMenu.OnListChange = function(sender, item, index)
        for _, entry in ipairs(accListItems) do
            if item == entry.propList then
                currentSkin[entry.key] = index - 2
                if currentSkin[entry.key] < -1 then currentSkin[entry.key] = -1 end
                SLX.Debug(('[Skin] Prop changed: %s = %d (NativeUI index=%d)'):format(entry.key, currentSkin[entry.key], index))
                ApplySkinToPed(PlayerPedId(), currentSkin)
                return
            elseif item == entry.texList then
                currentSkin[entry.texKey] = index - 1
                SLX.Debug(('[Skin] Prop tex changed: %s = %d (NativeUI index=%d)'):format(entry.texKey, index - 1, index))
                ApplySkinToPed(PlayerPedId(), currentSkin)
                return
            end
        end
    end

    local saveBtn = NativeUI.CreateItem('~g~Speichern', 'Skin speichern und Menu schließen')
    mainMenu:AddItem(saveBtn)

    mainMenu.OnListChange = function(sender, item, index)
        if item == modelList then
            if index == 1 then
                currentSkin.model = 'mp_m_freemode_01'
            else
                currentSkin.model = 'mp_f_freemode_01'
            end
            SLX.Debug(('[Skin] Model changed: %s (NativeUI index=%d)'):format(currentSkin.model, index))
            ApplySkinToPed(PlayerPedId(), currentSkin)
        end
    end

    local savePresetBtn = NativeUI.CreateItem('~b~Als Vorlage speichern', 'Skin als schnelle Vorlage sichern')
    mainMenu:AddItem(savePresetBtn)

    mainMenu.OnItemSelect = function(sender, item, index)
        if item == saveBtn then
            TriggerServerEvent('slx:saveSkin', currentSkin)
            SLX.ShowNotification('~g~Skin gespeichert!')
            mainMenu:Visible(false)
            skinMenuOpen = false
            _menuPool:CloseAllMenus()
            DestroySkinCamera()
        elseif item == savePresetBtn then
            mainMenu:Visible(false)
            skinMenuOpen = false
            _menuPool:CloseAllMenus()
            DestroySkinCamera()
            TriggerServerEvent('slx:saveSkin', currentSkin)
            CreateThread(function()
                AddTextEntry('SKIN_PRESET', 'Vorlagen-Name eingeben:')
                DisplayOnscreenKeyboard(1, 'SKIN_PRESET', '', '', '', '', '', 30)
                while UpdateOnscreenKeyboard() == 0 do Wait(0) end
                local presetName = GetOnscreenKeyboardResult()
                if presetName and presetName ~= '' then
                    SLX.SaveSkinPreset(presetName, currentSkin)
                    SLX.ShowNotification(('~g~Vorlage gespeichert: %s'):format(presetName))
                else
                    SLX.ShowNotification('~g~Skin gespeichert (ohne Vorlage)')
                end
            end)
        end
    end

    mainMenu.OnMenuClosed = function()
        skinMenuOpen = false
        DestroySkinCamera()
    end

    _menuPool:MouseControlsEnabled(false)
    _menuPool:ControlDisablingEnabled(false)
    _menuPool:RefreshIndex()
    mainMenu:Visible(true)
end

RegisterCommand('skin', function()
    if not SLX.LocalPlayer.spawned then return end
    if IsEntityDead(PlayerPedId()) then return end
    OpenSkinMenu()
end, false)

CreateThread(function()
    while true do
        if skinMenuOpen or skinCamActive then
            DisableAllControlActions(0)
            _menuPool:ProcessMenus()
            EnableControlAction(0, 172, true)
            EnableControlAction(0, 173, true)
            EnableControlAction(0, 174, true)
            EnableControlAction(0, 175, true)
            EnableControlAction(0, 176, true)
            EnableControlAction(0, 177, true)
            EnableControlAction(0, 187, true)
            EnableControlAction(0, 188, true)
            EnableControlAction(0, 191, true)
            EnableControlAction(0, 192, true)
            EnableControlAction(0, 194, true)
            EnableControlAction(0, 195, true)
            EnableControlAction(0, 196, true)
            EnableControlAction(0, 197, true)
            EnableControlAction(0, 198, true)
            EnableControlAction(0, 199, true)
            EnableControlAction(0, 200, true)
            EnableControlAction(0, 201, true)
            EnableControlAction(0, 202, true)
            EnableControlAction(0, 34, true)
            EnableControlAction(0, 35, true)

            if skinCamActive then
                if IsControlPressed(0, 34) then
                    skinCamHeading = skinCamHeading - 2.0
                    UpdateSkinCamera()
                end
                if IsControlPressed(0, 35) then
                    skinCamHeading = skinCamHeading + 2.0
                    UpdateSkinCamera()
                end
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('slx:playerLoaded', function(data)
    if data.isFirstJoin then
        Wait(1000)
        OpenSkinMenu()
        SLX.Debug('First join detected, opening skin menu')
        return
    end
    if data.skin then
        currentSkin = data.skin
        Wait(500)
        ApplySkinToPed(PlayerPedId(), data.skin)
        SLX.Debug('Skin loaded and applied from server data')
    end
end)

AddEventHandler('slx:playerSpawned', function()
    if currentSkin then
        Wait(200)
        ApplySkinToPed(PlayerPedId(), currentSkin)
    end
end)

RegisterNetEvent('slx:recv_skin')
AddEventHandler('slx:recv_skin', function(skinData)
    if skinData then
        currentSkin = skinData
        ApplySkinToPed(PlayerPedId(), skinData)
    end
end)

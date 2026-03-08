local _presetPool = NativeUI.CreatePool()
local presetMenuOpen = false
local skinPresets = {}
local KVP_KEY = 'corew_skin_presets'

local function LoadPresets()
    local raw = GetResourceKvpString(KVP_KEY)
    if raw and raw ~= '' then
        skinPresets = json.decode(raw) or {}
    else
        skinPresets = {}
    end
end

local function SavePresets()
    SetResourceKvp(KVP_KEY, json.encode(skinPresets))
end

local function AddPreset(name, skinData)
    skinPresets[#skinPresets + 1] = { name = name, skin = skinData }
    SavePresets()
end

local function RemovePreset(index)
    table.remove(skinPresets, index)
    SavePresets()
end

LoadPresets()

local function ClosePresetMenu()
    _presetPool:CloseAllMenus()
    presetMenuOpen = false
end

local function OpenPresetMenu()
    if presetMenuOpen then return end
    presetMenuOpen = true

    local mainMenu = NativeUI.CreateMenu('Skin Vorlagen', 'Gespeicherte Skins')
    _presetPool:Add(mainMenu)

    if #skinPresets == 0 then
        local emptyItem = NativeUI.CreateItem('~c~Keine Vorlagen', 'Speichere Skins im Skin Editor')
        mainMenu:AddItem(emptyItem)
    else
        for i = 1, #skinPresets do
            local preset = skinPresets[i]

            local presetMenu = NativeUI.CreateMenu(preset.name, 'Vorlage: ' .. preset.name)
            _presetPool:Add(presetMenu)

            local presetBtn = NativeUI.CreateItem(preset.name, 'Skin Vorlage')
            mainMenu:AddItem(presetBtn)
            mainMenu:BindMenuToItem(presetMenu, presetBtn)

            local applyBtn = NativeUI.CreateItem('~g~Anwenden', 'Diesen Skin anwenden')
            presetMenu:AddItem(applyBtn)

            local deleteBtn = NativeUI.CreateItem('~r~Loeschen', 'Diese Vorlage loeschen')
            presetMenu:AddItem(deleteBtn)

            presetMenu.OnItemSelect = function(sender, item, index)
                if item == applyBtn then
                    local ped = PlayerPedId()
                    SLX.ApplySkinToPed(ped, preset.skin)
                    TriggerServerEvent('slx:saveSkin', preset.skin)
                    SLX.ShowNotification('~g~Skin angewendet: ' .. preset.name)
                    ClosePresetMenu()
                elseif item == deleteBtn then
                    RemovePreset(i)
                    SLX.ShowNotification('~r~Vorlage geloescht: ' .. preset.name)
                    ClosePresetMenu()
                end
            end
        end
    end

    mainMenu.OnMenuClosed = function()
        presetMenuOpen = false
    end

    _presetPool:RefreshIndex()
    mainMenu:Visible(true)
end

---@param name string
---@param skinData table
function SLX.SaveSkinPreset(name, skinData)
    AddPreset(name, skinData)
end

---@return table
function SLX.GetSkinPresets()
    return skinPresets
end

RegisterCommand('skinliste', function()
    if not SLX.LocalPlayer.spawned then return end
    if IsEntityDead(PlayerPedId()) then return end
    OpenPresetMenu()
end, false)

CreateThread(function()
    while true do
        if presetMenuOpen then
            DisableAllControlActions(0)
            _presetPool:ProcessMenus()
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
            Wait(0)
        else
            Wait(500)
        end
    end
end)

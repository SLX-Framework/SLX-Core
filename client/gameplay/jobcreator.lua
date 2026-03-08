local _jcPool = NativeUI.CreatePool()
local jcMenuOpen = false
local jcKeyboardOpen = false

local function CloseJCMenu()
    _jcPool:CloseAllMenus()
    jcMenuOpen = false
    jcKeyboardOpen = false
end

local pendingJob = {
    name = '',
    label = '',
    grades = {},
}

local function ResetPendingJob()
    pendingJob = { name = '', label = '', grades = {} }
end

---@param entryKey string
---@param defaultText string
---@param maxLength number
---@return string|nil
local function ShowKeyboardInput(entryKey, defaultText, maxLength)
    jcKeyboardOpen = true
    AddTextEntry(entryKey, defaultText)
    DisplayOnscreenKeyboard(1, entryKey, '', '', '', '', '', maxLength)
    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
    jcKeyboardOpen = false
    local result = GetOnscreenKeyboardResult()
    if result == nil or result == '' then return nil end
    return result
end

local function OpenJobCreatorMenu()
    if jcMenuOpen then return end
    jcMenuOpen = true
    ResetPendingJob()

    _jcPool:Clear()
    local mainMenu = NativeUI.CreateMenu('Job Creator', 'Jobs erstellen & verwalten')
    _jcPool:Add(mainMenu)

    local createBtn = NativeUI.CreateItem('~g~Neuen Job erstellen', 'Erstelle einen neuen Job')
    mainMenu:AddItem(createBtn)

    local listBtn = NativeUI.CreateItem('Jobs anzeigen', 'Alle vorhandenen Jobs')
    mainMenu:AddItem(listBtn)

    mainMenu.OnItemSelect = function(sender, item, index)
        if item == createBtn then
            CloseJCMenu()
            OpenCreateJobInput()
        elseif item == listBtn then
            CloseJCMenu()
            OpenJobListMenu()
        end
    end

    mainMenu.OnMenuClosed = function()
        jcMenuOpen = false
    end

    _jcPool:MouseControlsEnabled(false)
    _jcPool:ControlDisablingEnabled(false)
    _jcPool:RefreshIndex()
    mainMenu:Visible(true)
end

function OpenCreateJobInput()
    CreateThread(function()
        local jobName = ShowKeyboardInput('JC_NAME', 'Job Name (intern, z.B. mechanic):', 30)
        if not jobName then return end

        local jobLabel = ShowKeyboardInput('JC_LABEL', 'Job Label (Anzeigename, z.B. Mechaniker):', 50)
        if not jobLabel then return end

        pendingJob.name = jobName
        pendingJob.label = jobLabel
        pendingJob.grades = {}

        OpenGradeEditor()
    end)
end

function OpenGradeEditor()
    jcMenuOpen = true

    _jcPool:Clear()
    local gradeMenu = NativeUI.CreateMenu('Grades', ('Job: %s | Grades hinzufuegen'):format(pendingJob.label))
    _jcPool:Add(gradeMenu)

    local addGradeBtn = NativeUI.CreateItem('~g~Grade hinzufuegen', 'Neuen Grade hinzufuegen')
    gradeMenu:AddItem(addGradeBtn)

    local gradeCountItem = NativeUI.CreateItem(('Grades: %d'):format(#pendingJob.grades), 'Aktuelle Anzahl')
    gradeMenu:AddItem(gradeCountItem)

    local saveBtn = NativeUI.CreateItem('~b~Job speichern', 'Job mit allen Grades erstellen')
    gradeMenu:AddItem(saveBtn)

    gradeMenu.OnItemSelect = function(sender, item, idx)
        if item == addGradeBtn then
            CloseJCMenu()
            CreateThread(function()
                local gLabel = ShowKeyboardInput('JC_GLABEL', ('Grade %d Label (z.B. Lehrling):'):format(#pendingJob.grades), 50)
                if not gLabel then OpenGradeEditor() return end

                local salStr = ShowKeyboardInput('JC_GSAL', 'Gehalt (z.B. 500):', 10)
                local salary = tonumber(salStr) or 0

                pendingJob.grades[#pendingJob.grades + 1] = { label = gLabel, salary = salary }
                SLX.ShowNotification(('~g~Grade hinzugefuegt: %s ($%d)'):format(gLabel, salary))
                OpenGradeEditor()
            end)
        elseif item == saveBtn then
            if #pendingJob.grades == 0 then
                pendingJob.grades[1] = { label = 'Standard', salary = 0 }
            end
            TriggerServerEvent('slx:createJob', pendingJob)
            CloseJCMenu()
            ResetPendingJob()
        end
    end

    gradeMenu.OnMenuClosed = function()
        jcMenuOpen = false
    end

    _jcPool:MouseControlsEnabled(false)
    _jcPool:ControlDisablingEnabled(false)
    _jcPool:RefreshIndex()
    gradeMenu:Visible(true)
end

function OpenJobListMenu()
    SLX.TriggerServerCallback('slx:getJobList', function(jobs)
        if not jobs or #jobs == 0 then
            SLX.ShowNotification('~r~Keine Jobs gefunden!')
            return
        end

        jcMenuOpen = true
        _jcPool:Clear()
        local listMenu = NativeUI.CreateMenu('Jobs', ('Alle Jobs (%d)'):format(#jobs))
        _jcPool:Add(listMenu)

        local jobItems = {}
        for i = 1, #jobs do
            local j = jobs[i]
            local gradeCount = 0
            if j.grades then
                for _ in pairs(j.grades) do gradeCount = gradeCount + 1 end
            end
            local jobItem = NativeUI.CreateItem(j.label, ('Name: %s | Grades: %d'):format(j.name, gradeCount))
            listMenu:AddItem(jobItem)
            jobItems[i] = j
        end

        listMenu.OnItemSelect = function(sender, item, index)
            CloseJCMenu()
            OpenJobDetailMenu(jobItems[index])
        end

        listMenu.OnMenuClosed = function()
            jcMenuOpen = false
        end

        _jcPool:MouseControlsEnabled(false)
    _jcPool:ControlDisablingEnabled(false)
    _jcPool:RefreshIndex()
        listMenu:Visible(true)
    end)
end

---@param jobData table
function OpenJobDetailMenu(jobData)
    if not jobData then return end
    jcMenuOpen = true

    _jcPool:Clear()
    local detailMenu = NativeUI.CreateMenu(jobData.label, ('Job: %s'):format(jobData.name))
    _jcPool:Add(detailMenu)

    local sortedGrades = {}
    if jobData.grades then
        for gradeIdx, gradeInfo in pairs(jobData.grades) do
            sortedGrades[#sortedGrades + 1] = { grade = tonumber(gradeIdx), label = gradeInfo.label, salary = gradeInfo.salary or 0 }
        end
        table.sort(sortedGrades, function(a, b) return a.grade < b.grade end)
    end

    local gradeItems = {}
    for i = 1, #sortedGrades do
        local g = sortedGrades[i]
        local gradeItem = NativeUI.CreateItem(
            ('Grade %d: %s'):format(g.grade, g.label),
            ('Gehalt: $%d | Auswaehlen zum Bearbeiten'):format(g.salary)
        )
        detailMenu:AddItem(gradeItem)
        gradeItems[i] = g
    end

    local addGradeBtn = NativeUI.CreateItem('~g~Grade hinzufuegen', 'Neuen Grade zum Job hinzufuegen')
    detailMenu:AddItem(addGradeBtn)

    local isProtected = (jobData.name == 'unemployed')

    if not isProtected then
        local deleteJobBtn = NativeUI.CreateItem('~r~Job loeschen', 'Diesen Job komplett loeschen')
        detailMenu:AddItem(deleteJobBtn)

        detailMenu.OnItemSelect = function(sender, item, index)
            if item == addGradeBtn then
                CloseJCMenu()
                OpenAddGradeToExistingJob(jobData)
            elseif item == deleteJobBtn then
                TriggerServerEvent('slx:deleteJob', jobData.name)
                CloseJCMenu()
            else
                local gradeData = gradeItems[index]
                if gradeData then
                    CloseJCMenu()
                    OpenGradeDetailMenu(jobData, gradeData)
                end
            end
        end
    else
        detailMenu.OnItemSelect = function(sender, item, index)
            if item == addGradeBtn then
                CloseJCMenu()
                OpenAddGradeToExistingJob(jobData)
            else
                local gradeData = gradeItems[index]
                if gradeData then
                    CloseJCMenu()
                    OpenGradeDetailMenu(jobData, gradeData)
                end
            end
        end
    end

    detailMenu.OnMenuClosed = function()
        jcMenuOpen = false
    end

    _jcPool:MouseControlsEnabled(false)
    _jcPool:ControlDisablingEnabled(false)
    _jcPool:RefreshIndex()
    detailMenu:Visible(true)
end

---@param jobData table
---@param gradeData table
function OpenGradeDetailMenu(jobData, gradeData)
    jcMenuOpen = true

    _jcPool:Clear()
    local gradeMenu = NativeUI.CreateMenu(
        ('Grade %d'):format(gradeData.grade),
        ('%s - %s | Gehalt: $%d'):format(jobData.label, gradeData.label, gradeData.salary)
    )
    _jcPool:Add(gradeMenu)

    local editLabelBtn = NativeUI.CreateItem('Label bearbeiten', ('Aktuell: %s'):format(gradeData.label))
    gradeMenu:AddItem(editLabelBtn)

    local editSalaryBtn = NativeUI.CreateItem('Gehalt bearbeiten', ('Aktuell: $%d'):format(gradeData.salary))
    gradeMenu:AddItem(editSalaryBtn)

    local deleteGradeBtn = NativeUI.CreateItem('~r~Grade loeschen', 'Diesen Grade entfernen')
    gradeMenu:AddItem(deleteGradeBtn)

    gradeMenu.OnItemSelect = function(sender, item, index)
        if item == editLabelBtn then
            CloseJCMenu()
            CreateThread(function()
                local newLabel = ShowKeyboardInput('JC_ELABEL', ('Neues Label fuer Grade %d:'):format(gradeData.grade), 50)
                if not newLabel then
                    OpenGradeDetailMenu(jobData, gradeData)
                    return
                end
                TriggerServerEvent('slx:editJobGrade', jobData.name, gradeData.grade, newLabel, gradeData.salary)
                SLX.ShowNotification(('~g~Grade Label geaendert: %s'):format(newLabel))
                Wait(300)
                OpenJobListMenu()
            end)
        elseif item == editSalaryBtn then
            CloseJCMenu()
            CreateThread(function()
                local salStr = ShowKeyboardInput('JC_ESAL', ('Neues Gehalt fuer Grade %d:'):format(gradeData.grade), 10)
                if not salStr then
                    OpenGradeDetailMenu(jobData, gradeData)
                    return
                end
                local newSalary = tonumber(salStr) or gradeData.salary
                TriggerServerEvent('slx:editJobGrade', jobData.name, gradeData.grade, gradeData.label, newSalary)
                SLX.ShowNotification(('~g~Gehalt geaendert: $%d'):format(newSalary))
                Wait(300)
                OpenJobListMenu()
            end)
        elseif item == deleteGradeBtn then
            TriggerServerEvent('slx:deleteJobGrade', jobData.name, gradeData.grade)
            CloseJCMenu()
            Wait(300)
            OpenJobListMenu()
        end
    end

    gradeMenu.OnMenuClosed = function()
        jcMenuOpen = false
    end

    _jcPool:MouseControlsEnabled(false)
    _jcPool:ControlDisablingEnabled(false)
    _jcPool:RefreshIndex()
    gradeMenu:Visible(true)
end

---@param jobData table
function OpenAddGradeToExistingJob(jobData)
    CreateThread(function()
        local gradeCount = 0
        if jobData.grades then
            for k in pairs(jobData.grades) do
                local idx = tonumber(k) or 0
                if idx >= gradeCount then gradeCount = idx + 1 end
            end
        end

        local gLabel = ShowKeyboardInput('JC_AGLABEL', ('Grade %d Label (z.B. Lehrling):'):format(gradeCount), 50)
        if not gLabel then
            OpenJobDetailMenu(jobData)
            return
        end

        local salStr = ShowKeyboardInput('JC_AGSAL', 'Gehalt (z.B. 500):', 10)
        local salary = tonumber(salStr) or 0

        TriggerServerEvent('slx:addJobGrade', jobData.name, gradeCount, gLabel, salary)
        SLX.ShowNotification(('~g~Grade hinzugefuegt: %s ($%d)'):format(gLabel, salary))
        Wait(300)
        OpenJobListMenu()
    end)
end

RegisterCommand('jobcreator', function()
    if not SLX.LocalPlayer.spawned then return end
    local group = SLX.LocalPlayer.group
    if not group then return end
    local perms = SLX.Config.JobCreatorPermission or { 'admin' }
    if type(perms) == 'string' then perms = { perms } end
    local hasAccess = false
    for i = 1, #perms do
        if group.name == perms[i] then
            hasAccess = true
            break
        end
    end
    if not hasAccess and group.name ~= 'superadmin' then
        SLX.ShowNotification('~r~Keine Berechtigung!')
        return
    end
    OpenJobCreatorMenu()
end, false)

CreateThread(function()
    while true do
        if jcMenuOpen or jcKeyboardOpen then
            DisableAllControlActions(0)
            if jcMenuOpen then
                _jcPool:ProcessMenus()
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
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

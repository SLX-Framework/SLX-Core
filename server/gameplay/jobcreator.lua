---@param player table
---@return boolean
local function HasJobCreatorPerm(player)
    local perms = SLX.Config.JobCreatorPermission or { 'admin' }
    if type(perms) == 'string' then perms = { perms } end
    for i = 1, #perms do
        if player:HasPermission(perms[i]) then return true end
    end
    return false
end

RegisterNetEvent('slx:createJob')
AddEventHandler('slx:createJob', function(jobData)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if not HasJobCreatorPerm(player) then
        TriggerClientEvent('slx:notify', src, 'Keine Berechtigung!')
        return
    end
    if not jobData or not jobData.name or not jobData.label then
        TriggerClientEvent('slx:notify', src, 'Ungueltige Job-Daten!')
        return
    end
    local jobName = jobData.name:lower():gsub('%s+', '_')
    if SLX.Jobs[jobName] then
        TriggerClientEvent('slx:notify', src, 'Job existiert bereits!')
        return
    end
    MySQL.insert.await('INSERT INTO jobs (name, label) VALUES (?, ?)', { jobName, jobData.label })
    SLX.Jobs[jobName] = { label = jobData.label, grades = {} }
    if jobData.grades and #jobData.grades > 0 then
        for i = 1, #jobData.grades do
            local g = jobData.grades[i]
            local grade = i - 1
            local salary = tonumber(g.salary) or 0
            MySQL.insert('INSERT INTO job_grades (job_name, grade, label, salary) VALUES (?, ?, ?, ?)', { jobName, grade, g.label, salary })
            SLX.Jobs[jobName].grades[grade] = { label = g.label, salary = salary }
        end
    else
        MySQL.insert('INSERT INTO job_grades (job_name, grade, label, salary) VALUES (?, ?, ?, ?)', { jobName, 0, 'Standard', 0 })
        SLX.Jobs[jobName].grades[0] = { label = 'Standard', salary = 0 }
    end
    TriggerClientEvent('slx:notify', src, ('~g~Job erstellt: %s (%s)'):format(jobData.label, jobName))
    SLX.Log('INFO', ('Job created by %d: %s (%s) with %d grade(s)'):format(src, jobData.label, jobName, jobData.grades and #jobData.grades or 1))
end)

RegisterNetEvent('slx:deleteJob')
AddEventHandler('slx:deleteJob', function(jobName)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if not HasJobCreatorPerm(player) then
        TriggerClientEvent('slx:notify', src, 'Keine Berechtigung!')
        return
    end
    if not SLX.Jobs[jobName] then
        TriggerClientEvent('slx:notify', src, 'Job nicht gefunden!')
        return
    end
    if jobName == 'unemployed' then
        TriggerClientEvent('slx:notify', src, 'Dieser Job kann nicht geloescht werden!')
        return
    end
    MySQL.query('DELETE FROM job_grades WHERE job_name = ?', { jobName })
    MySQL.query('DELETE FROM jobs WHERE name = ?', { jobName })
    SLX.Jobs[jobName] = nil
    TriggerClientEvent('slx:notify', src, ('~r~Job geloescht: %s'):format(jobName))
    SLX.Log('INFO', ('Job deleted by %d: %s'):format(src, jobName))
end)

RegisterNetEvent('slx:addJobGrade')
AddEventHandler('slx:addJobGrade', function(jobName, grade, label, salary)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if not HasJobCreatorPerm(player) then
        TriggerClientEvent('slx:notify', src, 'Keine Berechtigung!')
        return
    end
    if not SLX.Jobs[jobName] then
        TriggerClientEvent('slx:notify', src, 'Job nicht gefunden!')
        return
    end
    grade = tonumber(grade) or 0
    salary = tonumber(salary) or 0
    if SLX.Jobs[jobName].grades[grade] then
        TriggerClientEvent('slx:notify', src, ('Grade %d existiert bereits!'):format(grade))
        return
    end
    MySQL.insert('INSERT INTO job_grades (job_name, grade, label, salary) VALUES (?, ?, ?, ?)', { jobName, grade, label, salary })
    SLX.Jobs[jobName].grades[grade] = { label = label, salary = salary }
    TriggerClientEvent('slx:notify', src, ('~g~Grade %d hinzugefuegt: %s ($%d)'):format(grade, label, salary))
    SLX.Log('INFO', ('Grade added by %d: %s grade %d (%s, $%d)'):format(src, jobName, grade, label, salary))
end)

RegisterNetEvent('slx:editJobGrade')
AddEventHandler('slx:editJobGrade', function(jobName, grade, newLabel, newSalary)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if not HasJobCreatorPerm(player) then
        TriggerClientEvent('slx:notify', src, 'Keine Berechtigung!')
        return
    end
    if not SLX.Jobs[jobName] then
        TriggerClientEvent('slx:notify', src, 'Job nicht gefunden!')
        return
    end
    grade = tonumber(grade) or 0
    newSalary = tonumber(newSalary) or 0
    if not SLX.Jobs[jobName].grades[grade] then
        TriggerClientEvent('slx:notify', src, ('Grade %d nicht gefunden!'):format(grade))
        return
    end
    MySQL.update('UPDATE job_grades SET label = ?, salary = ? WHERE job_name = ? AND grade = ?', { newLabel, newSalary, jobName, grade })
    SLX.Jobs[jobName].grades[grade] = { label = newLabel, salary = newSalary }
    TriggerClientEvent('slx:notify', src, ('~g~Grade %d aktualisiert: %s ($%d)'):format(grade, newLabel, newSalary))
    SLX.Log('INFO', ('Grade edited by %d: %s grade %d -> %s, $%d'):format(src, jobName, grade, newLabel, newSalary))
end)

RegisterNetEvent('slx:deleteJobGrade')
AddEventHandler('slx:deleteJobGrade', function(jobName, grade)
    local src = source
    local player = SLX.Players[src]
    if not player then return end
    if not HasJobCreatorPerm(player) then
        TriggerClientEvent('slx:notify', src, 'Keine Berechtigung!')
        return
    end
    if not SLX.Jobs[jobName] then
        TriggerClientEvent('slx:notify', src, 'Job nicht gefunden!')
        return
    end
    grade = tonumber(grade) or 0
    if not SLX.Jobs[jobName].grades[grade] then
        TriggerClientEvent('slx:notify', src, ('Grade %d nicht gefunden!'):format(grade))
        return
    end
    local gradeCount = 0
    for _ in pairs(SLX.Jobs[jobName].grades) do gradeCount = gradeCount + 1 end
    if gradeCount <= 1 then
        TriggerClientEvent('slx:notify', src, 'Letzter Grade kann nicht geloescht werden!')
        return
    end
    MySQL.query('DELETE FROM job_grades WHERE job_name = ? AND grade = ?', { jobName, grade })
    SLX.Jobs[jobName].grades[grade] = nil
    TriggerClientEvent('slx:notify', src, ('~r~Grade %d geloescht'):format(grade))
    SLX.Log('INFO', ('Grade deleted by %d: %s grade %d'):format(src, jobName, grade))
end)

SLX.RegisterServerCallback('slx:getJobList', function(src, respond)
    local list = {}
    for name, job in pairs(SLX.Jobs) do
        list[#list + 1] = { name = name, label = job.label, grades = job.grades }
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    respond(list)
end)
